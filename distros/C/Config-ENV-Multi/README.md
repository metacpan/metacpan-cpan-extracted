# NAME

Config::ENV::Multi - Config::ENV supported Multi ENV

# SYNOPSIS

    package Config;
    use Config::ENV::Multi [qw/ENV REGION/], any => ':any:', unset => ':unset:';

    common {
        # alias of [qw/:any: :any:/]
        # alias of [any, any]
        cnf => 'my.cnf',
    };

    config [qw/dev :any:/] => sub {
        debug => 1,
        db    => 'localhost',
    };

    config [qw/prod jp/] => sub {
        db    => 'jp.localhost',
    };

    config [qw/prod us/] => sub {
        db    => 'us.localhost',
    };

    Config->current;
    # $ENV{ENV}=dev, $ENV{REGION}=jp
    # {
    #   cnf    => 'my.cnf',
    #   debug  => 1,
    #   db     => 'localhost',
    # }

# DESCRIPTION

supported multi environment [Config::ENV](https://metacpan.org/pod/Config::ENV).

# SEE ALSO

[Config::ENV](https://metacpan.org/pod/Config::ENV)

# LICENSE

Copyright (C) Hiroyoshi Houchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroyoshi Houchi <git@hixi-hyi.com>
