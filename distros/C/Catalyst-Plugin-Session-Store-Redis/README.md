# NAME

Catalyst::Plugin::Session::Store::Redis - Redis Session store for Catalyst

# VERSION

version 0.901

# SYNOPSIS

    use Catalyst qw/
        Session
        Session::Store::Redis
        Session::State::Foo
    /;
    
    MyApp->config->{Plugin::Session} = {
        expires => 3600,
        redis_server => '127.0.0.1:6379',
        redis_debug => 0, # or 1!
        redis_reconnect => 0, # or 1
        redis_db => 5, # or 0 by default
        redis_ssl => 1, # or 0
        redis_name => 'name',
        redis_username => 'username', # or default user
        redis_password => 'password',
        redis_ssl_verify_mode => SSL_VERIFY_PEER, # IO::Socket::SSL
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

# DESCRIPTION

`Catalyst::Plugin::Session::Store::Redis` is a session storage plugin for
Catalyst that uses the Redis ([http://redis.io/](http://redis.io/)) key-value
database.

## CONFIGURATION

### redis\_server

The IP address and port where your Redis is running. Default: 127.0.0.1:6379

### redis\_debug

Boolean flag to turn Redis debug messages on/off. Default: 0, i.e. off

Turing this on will cause the Redis Perl bindings to output debug
messages to STDOUT. This setting does not influence the logging this
module does via `$c->log`

### redis\_reconnect

Boolean flag. Default: 0, i.e. off.

It is highly recommended that you enable this setting. If set to `0`,
your app might not be able to reconnect to `Redis` if the `Redis`
server was restarted.

I leave the default of setting at `0` for now because changing it
might break existing apps.

Do not use this setting with authentication.

### redis\_conservative\_reconnect

Boolean flag. Default: 0, i.e. off.

Use this setting for reconnect with authentication.

### redis\_ssl

Boolean flag. Default: 0, i.e. off.

You can connect to Redis over SSL/TLS by setting this flag if the
target Redis server or cluster has been setup to support SSL/TLS.
This requires [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL) to be installed on the client. It's off by default.

### redis\_ssl\_verify\_mode

This parameter will be applied when `redis_ssl` flag is set. It sets
the verification mode for the peer certificate. It's compatible with
the parameter with the same name in [IO::Socket::SSL](https://metacpan.org/pod/IO%3A%3ASocket%3A%3ASSL).

### redis\_name

Setting a different name for the connection.

### redis\_username

The username for the authentication

### redis\_password

The password, if your Redis server requires authentication.

# NOTES

- **Expired Sessions**

    This store does **not** automatically expires sessions.  There is no need to
    call `delete_expired_sessions` to clear any expired sessions.

    domm: No idea what this means.

- **session expiry**

    Currently this module does not use `Redis` Expiry to clean out old
    session. I might look into this in the future. But patches are welcome!

# AUTHORS

Cory G Watson, `<gphat at cpan.org>`

## Current Maintainer

Thomas Klausner `domm@cpan.org`

## Contributors

- Andreas Granig [https://github.com/agranig](https://github.com/agranig)
- Mohammad S Anwar [https://github.com/manwar](https://github.com/manwar)
- Torsten Raudssus [https://github.com/Getty](https://github.com/Getty)

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
