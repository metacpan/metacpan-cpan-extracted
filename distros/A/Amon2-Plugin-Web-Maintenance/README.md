# NAME

Amon2::Plugin::Web::Maintenance - Simple maintenance announcement page plugin for Amon2.

# SYNOPSIS

    package MyApp::Web;

    __PACKAGE__->load_plugins('Web::Maintenance');

# DESCRIPTION

Amon2::Plugin::Web::Maintenance is simple maintenance announcement page plugin for Amon2.

# CONFIGURE

You can configure in config file. This plugin use `$c->config->{MAINTENANCE}`.

    +{
        'MAINTENANCE' => +{
            enable => 1,
            except => +{
                addr => ['127.0.0.1'],
                path => ['/info']
            }
        },
    };

If 'enable' is 1, your application response maintenance announcement page always.

You can except some request by using 'expect' value. 'addr' and 'path' express exceptional conditions like [Plack::Builder::Conditionals](https://metacpan.org/pod/Plack::Builder::Conditionals).

# CUSTOM MAINTENANCE PAGE

You can customize the maintenance page. You can define the special named method 'res\_maintenance'.

    package MyApp::Web;

    sub res_maintenance {
        my ($c)  =  @_;
        return $c->create_response(
            503,
            [   'Content-Type'   => 'text/plain',
                'Content-Length' => 29,
            ],
            ['Service down for maintenance.']
        );
    }

# LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

zoncoen <zoncoen@gmail.com>
