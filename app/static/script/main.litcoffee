channel = Math.floor(Math.random()*1000000)

create_chat_comet = (ts = '') ->
    arg = "comet=room_online_users_count_all,room_content_all&channel=#{channel}&ts=#{ts}"
    $.getJSON "/comet?uri=#{window.uri}&#{arg}", (result) ->
        if result.type == 'room_online_users'
            room_online_users_count_all result.data
        else if result.type == 'add_content'
            room_content_all result.data
        create_chat_comet(result.ts)

create_room_comet = (ts = '') ->
    arg = "comet=room_online_users,room_content&channel=#{channel}&room_id=#{window.room_id}&ts=#{ts}"
    $.getJSON "/comet?uri=#{window.uri}&#{arg}", (result) ->
        if result.type == 'online_users'
            online_users result.data
        else if result.type == 'room_online_users'
            room_online_users result.data
        else if result.type == 'add_content'
            room_content result.data
        create_room_comet(result.ts)

room_online_users_count_all = (data) ->
    $("#room-#{data.room_id} .header span").text("(#{data.users.length}人在线)")

room_content_all = (data) ->
    $body = $("#room-#{data.room_id} .body")
    for content in data.content
        $body.find('ul').append("<li class='new' title='#{content.user} #{content.created}'>#{content.content}</li>")
    while $body.find('ul li').length > 5
        $body.find('ul li:first-child').remove()

room_online_users = (data) ->
    html = ''
    for item in data.users
        html += "<span>#{item}</span>"
    $('#room_online_user .user_list').html(html)

room_content = (data) ->
    console.log data
    for content in data.content
        $msg = $("#msg-#{content.id}")
        if not $msg.length
            html = "<tr id='msg-#{content.id}'>
                    <td>#{content.user}</td>
                    <td>#{content.content}</td>
                    <td>#{content.created}</td>
                    </tr>
                "
            $('#chat_content table tbody').append(html)
            $("#chat_content table tbody tr:last-child").get(0).scrollIntoView()
            if not window.entering_content
                if document.title.substr(0, 1) != '('
                    document.title = "(1) #{document.title}"
                else
                    current_title = document.title
                    current_count = parseInt(current_title.slice(current_title.indexOf('(')+1, current_title.indexOf(')')))
                    new_count = current_count + 1
                    document.title = current_title.replace("(#{current_count})", "(#{new_count})")

$ ->
    if $('#chat_content tbody tr').length
        $('#chat_content tbody tr:last-child').get(0).scrollIntoView()

    $('#post_content').bind 'submit', (evt) ->
        evt.preventDefault()
        data = $(this).serialize()
        if $.trim($(this).find('input[name="content"]').val()) == ''
            return false

        $.post(
            $(this).attr('action')
            data
            (result) ->
                $('#post_content input[name="content"]').val('')
                window.entering_content = true
                document.title = document.title.replace(/\([0-9]+\) /, '')
                room_content {'content': [result]}
            'json'
        )

    $('#post_content input[name="content"]').bind 'click', (evt) ->
        window.entering_content = true
        document.title = document.title.replace(/\([0-9]+\) /, '')

    $('#post_content input[name="content"]').bind 'blur', (evt) ->
        window.entering_content = false

    $('.add_room').bind 'click', (evt) ->
        $('.chat-bubble').toggle()

    $('.header .close').bind 'click', (evt) ->
        rs = confirm('do you really want to remove this room?')
        if rs
            room_info = $(this).parent().parent().attr('id').split('-')
            room_id = room_info[room_info.length-1]
            $.post(
                '/rm_room'
                {room_id: room_id}
                (result) ->
                    if result.status == 'ok'
                        window.location = result.content.url
                    else
                        alert result.content.message
                'json'
            )