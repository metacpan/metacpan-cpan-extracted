# NAME

AnyEvent::Plackup - Easily establish an HTTP server inside a program

# SYNOPSIS

    use AnyEvent::Plackup;

    my $server = plackup(); # port is automatically chosen
    my $req = $server->recv; # isa Plack::Request

    my $value = $req->parameters->{foo};

    $req->respond([ 200, [], [ 'OK' ] ]);

    # or specify PSGI app:

    my $server = plackup(app => \&app);

# DESCRIPTION

AnyEvent::Plackup provides functionality of establishing an HTTP server inside a program using [Twiggy](http://search.cpan.org/perldoc?Twiggy). If not specified, open port is automatically chosen.

# FUNCTIONS

- `my $server = AnyEvent::Plackup->new([ app => \&app, port => $port, %args ])`
- `my $server = plackup([ app => \&app, port => $port, %args ])`

    Creates and starts an HTTP server. Internally calls `new` and `run`.

    If _app_ is not specified, `$server->recv` is available and you should respond this manually.

- `my $req = $server->recv`

    Waits until next request comes. Returns an `AnyEvent::Plackup::Request` (isa `Plack::Request`).

- `my $origin = $server->origin`
- `my $origin = "$server"`

    Returns server's origin. e.g. `"http://0.0.0.0:8290"`.

- `$server->shutdown`

    Shuts down the server immediately.

# AUTHOR

motemen <motemen@gmail.com>

# SEE ALSO

[Twiggy](http://search.cpan.org/perldoc?Twiggy)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
