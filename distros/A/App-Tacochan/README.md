# NAME

App::Tacochan - Skype message delivery by HTTP

# SYNOPSIS

    tacochan

# OPTIONS

- \-o, --host

    The interface a TCP based server daemon binds to. Defauts to undef,
    which lets most server backends bind the any (\*) interface. This
    option doesn't mean anything if the server does not support TCP
    socket.

- \-p, --port (default: 4969)

    The port number a TCP based server daemon listens on. Defaults to
    4969\. This option doesn't mean anything if the server does not support
    TCP socket.

- \-r, --reverse-proxy

    treat X-Forwarded-For as REMOTE\_ADDR if REMOTE\_ADDR match this argument.

    see [Plack::Middleware::ReverseProxy](http://search.cpan.org/perldoc?Plack::Middleware::ReverseProxy).

- \-h, --help

    Show help for this command.

- \-v, --version

    Show version.

# SEE ALSO

[App::Ikachan](http://search.cpan.org/perldoc?App::Ikachan), [Skype::Any](http://search.cpan.org/perldoc?Skype::Any), [Twiggy](http://search.cpan.org/perldoc?Twiggy)

# AUTHOR

Takumi Akiyama <t.akiym at gmail.com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
