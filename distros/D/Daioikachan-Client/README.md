[![Build Status](https://travis-ci.org/ryopeko/Daioikachan-Client.svg?branch=master)](https://travis-ci.org/ryopeko/Daioikachan-Client)
# NAME

Daioikachan::Client - Client for Daioikachan

# SYNOPSIS

    use Daioikachan::Client;

    my $client = Daioikachan::Client->new({
        endpoint => 'http://daioikachan_endpoint.example.com/',
    });

    # Send message to Daioikachan.
    $client->notice({ message => 'foo' });

# DESCRIPTION

Daioikachan::Client is a client for Daioikachan.

# INTERFACE

## Class Method

### `Daioikachan::Client->new($args) :Daioikachan::Client`

Create and returns a new Daioikachan::Client instance.

_$args_:

- endpoint :Str

    Endpoint of Daioikachan server.
    You must specify a this parameter.

- default\_channel :Str = #notify
- headers :ArrayRef

    This parameter is used by Furl::HTTP request.

- ua\_options :Hash or HashRef

    Options for Furl::HTTP->new.

## Instance Method

### `$client->notice($args) :Furl::Response`

Send message to Daioikachan as notice.

_$args_

- message :Str

    This parameter is used by send to Daioikachan.
    You must specify a this parameter.

### `$client->privmsg($args) :Furl::Response`

Send message to Daioikachan as privmsg.

_$args_

- message :Str

    This parameter is used by send to Daioikachan.
    You must specify a this parameter.

# SEE ALSO

https://github.com/sonots/daioikachan

# LICENSE

Copyright (C) ryopeko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ryopeko <ryopeko@gmail.com>
