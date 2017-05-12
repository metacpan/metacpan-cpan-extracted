# NAME

App::MadEye::Plugin::Notify::HipChat - send message to HipChat

# SCHEMA

    type: map
    mapping:
        url:
            type: str
            required: no (defalut: https://api.hipchat.com/v1/rooms/message)
        auth_token:
            type: str
            required: yes
        room_id:
            type: str
            required: yes
        message:
            type: str
            required: no
        from:
            type: str
            required: no (defalut: ikachan)
        message_format:
            type: str
            required: no (defalut: html)
        notify:
            type: int
            required: no (defalut: 0)
        color:
            type: str
            required: no (defalut: yellow)
        format:
            type: str
            required: no (defalut: json)

# SEE ALSO

[App::MadEye](https://metacpan.org/pod/App::MadEye), [HipChat API](https://www.hipchat.com/docs/api/method/rooms/message)

# LICENSE

Copyright (C) Kazuhiro Homma.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazuhiro Homma <kazu.homma@gmail.com>
