[![Build Status](https://travis-ci.org/ufobat/p5-AnyEvent-HTTPD-Router.svg?branch=master)](https://travis-ci.org/ufobat/p5-AnyEvent-HTTPD-Router)
# NAME

AnyEvent::HTTPD::Router - Adding Routes to AnyEvent::HTTPD

# DESCRIPTION

AnyEvent::HTTPD::Router is an extension to the [AnyEvent::HTTPD](https://metacpan.org/pod/AnyEvent::HTTPD) module, from
which it is inheriting. It adds the `reg_routes()` method to it.

This module aims to add as little as possible overhead to it while still being
flexible and extendable. It requires the same little dependencies that
[AnyEvent::HTTPD](https://metacpan.org/pod/AnyEvent::HTTPD) uses.

The dispatching for the routes happens first. If no route could be found, or you
do not stop further dispatching with `stop_request()` the registered callbacks
will be executed as well; as if you would use [AnyEvent::HTTPD](https://metacpan.org/pod/AnyEvent::HTTPD). In other
words, if you plan to use routes in your project you can use this module and
upgrade from callbacks to routes step by step.

Routes support http methods, but custom methods
[https://cloud.google.com/apis/design/custom\_methods](https://cloud.google.com/apis/design/custom_methods) can also be used. You
don't need to, of course ;-)

# SYNOPSIS

    use AnyEvent::HTTPD::Router;

    my $httpd       = AnyEvent::HTTPD::Router->new( port => 1337 );
    my $all_methods = [qw/GET DELETE HEAD POST PUT PATCH/];

    $httpd->reg_routes(
        GET => '/index.txt' => sub {
            my ( $httpd, $req ) = @_;
            $httpd->stop_request;
            $req->respond([
                200, 'ok', { 'Content-Type' => 'text/plain', }, "test!" ]);
        },
        $all_methods => '/my-method' => sub {
            my ( $httpd, $req ) = @_;
            $httpd->stop_request;
            $req->respond([
                200, 'ok', { 'X-Your-Method' => $req->method }, '' ]);
        },
        GET => '/calendar/:year/:month/:day' => sub {
            my ( $httpd, $req, $param ) = @_;
            my $calendar_entries = get_cal_entries(
                $param->{year}, $param->{month}, $param->{day}
            );

            $httpd->stop_request;
            $reg->respond([
                200, 'ok', { 'Content-Type' => 'application/json'},
                to_json($calendar_entries)
            ]);
        },
        GET => '/static-files/*' => sub {
            my ( $httpd, $req, $param ) = @_;
            my $requeted_file = $param->{'*'};
            my ($content, $content_type) = black_magic($requested_file);

            $httpd->stop_request;
            $req->respond([
                200, 'ok', { 'Content-Type' => $content_type }, $content ]);
        }
    );

    $httpd->run();

# METHODS

- `new()`

    Creates a new `AnyEvent::HTTPD::Router` server. The constructor handles the
    following parameters. All further parameters are passed to `AnyEvent::HTTPD`.

    - `dispatcher`

        You can pass your own implementation of your router dispatcher into this module.
        This expects the dispatcher to be an instance not a class name.

    - `dispatcher_class`

        You can pass your own implementation of your router dispatcher into this module.
        This expects the dispatcher to be a class name.

    - `routes`

        You can add the routes at the constructor. This is an ArrayRef.

    - `known_methods`

        Whenever you register a new route this modules checks if the method is either
        customer method prefixed with ':' or a $known\_method. You would need to change
        this, if you would like to implement WebDAV, for example. This is an ArrayRef.

    - `auto_respond_404`

        If the value for this parameter is set to true a a simple `404` responder will
        be installed that responds if not route matches. You can implement your own
        handler see [EVENTS](https://metacpan.org/pod/EVENTS).

- `reg_routes( [$method, $path, $callback]* )`

    You can add further routes with this method. Multiple routes can be added at
    once. To add a route you need do add 3 parameters: &lt;method>, &lt;path>, &lt;callback>.

- `*`

    `AnyEvent::HTTPD::Router` subclasses `AnyEvent::HTTPD` so you can use all
    methods the parent class.

# EVENTS

- no\_route\_found => $request

    When the dispatcher can not find a route that matches on your request, the
    event `no_route_found` will be emitted.

    In the case that routes and callbacks (`reg_cb()`) for paths as used with
    `AnyEvent::HTTPD` are mixed, keep in mind that that `no_route_found` will
    happen before the other path callbacks are executed. So for a
    `404 not found` handler you could do

        $httpd->reg_cb('' => sub {
            my ( $httpd, $req ) = @_;
            $req->respond( [ 404, 'not found', {}, '' ] );
        });

    If you just use `reg_routes()` and don't mix with `reg_cb()` for paths you
    could implement the `404 not found` handler like this:

        $httpd->reg_cb('no_route_found' => sub {
            my ( $httpd, $req ) = @_;
            $req->respond( [ 404, 'not found', {}, '' ] );
        });

    This is exactly what you get if you specify `auto_respond_404` at the
    constructor.

- See ["EVENTS" in AnyEvent::HTTPD](https://metacpan.org/pod/AnyEvent::HTTPD#EVENTS)

# WRITING YOUR OWN ROUTE DISPATCHER

If you want to change the implementation of the dispatching you specify the
`dispatcher` or `dispatcher_class`. You need to implement the `match()`
method.

In the case you specify the `request_class` for `AnyEvent::HTTPD` you might
need to make adaptions to the `match()` method as well.

# SEE ALSO

- [AnyEvent](https://metacpan.org/pod/AnyEvent)
- [AnyEvent::HTTPD](https://metacpan.org/pod/AnyEvent::HTTPD)

There are a lot of HTTP Router modules in CPAN:

- [HTTP::Router](https://metacpan.org/pod/HTTP::Router)
- [Router::Simple](https://metacpan.org/pod/Router::Simple)
- [Router::R3](https://metacpan.org/pod/Router::R3)
- [Router::Boom](https://metacpan.org/pod/Router::Boom)

# BUILDING AND RELEASING THIS MODULE

This module uses [https://metacpan.org/pod/Minilla](https://metacpan.org/pod/Minilla).

# LICENSE

Copyright (C) Martin Barth.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# CONTRIBUTORS

- Paul Koschinski

# AUTHOR

Martin Barth (ufobat)
