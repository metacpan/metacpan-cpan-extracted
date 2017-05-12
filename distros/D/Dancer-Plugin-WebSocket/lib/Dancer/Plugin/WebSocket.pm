package Dancer::Plugin::WebSocket;
use Carp;
use Dancer ':syntax';

our $VERSION = 0.0100;# VERSION

use AnyMQ;
use Dancer::Plugin;
use Plack;
use Web::Hippie;
use Carp;

my $bus;
sub _bus {
    return $bus if $bus;
    return $bus = AnyMQ->new;
}

my $topic;
sub _topic {
    return $topic if $topic;
    return $topic = _bus->topic('dancer-plugin-websocket');
}

my $triggers = {};

set plack_middlewares_map => {
    '/_hippie' => [
        [ '+Web::Hippie' ],
        [ '+Web::Hippie::Pipe', bus => _bus ],
    ]
};

# /new_listener and /message are routes needed by Web::Hippie

get '/new_listener' => sub {

    if (defined $triggers->{on_new_listener}) {
        $triggers->{on_new_listener}->();
    }

    request->env->{'hippie.listener'}->subscribe(_topic);
};

get '/message' => sub {
    my $msg = request->env->{'hippie.message'};

    if ( defined $triggers->{on_message} ) {
        $msg = $triggers->{on_message}->($msg);
    }
    _topic->publish($msg);
};

my $ws_send = sub {
    my $msg = shift;
    _topic->publish({ msg => $msg });
};

register ws_on_message => sub {
    $triggers->{on_message} = shift;
};

register ws_on_new_listener => sub {
    $triggers->{on_new_listener} = shift;
};

register ws_send => sub {
    $ws_send->(@_);
};

register websocket_send => sub {
    carp "'websocket_send' is deprecated. You should use 'ws_send' instead.";
    $ws_send->(@_);
};

register_plugin;

# ABSTRACT: A Dancer plugin for easily creating WebSocket apps


1;

__END__
=pod

=head1 NAME

Dancer::Plugin::WebSocket - A Dancer plugin for easily creating WebSocket apps

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

    # ./bin/app.pl
    use Dancer;
    use Dancer::Plugin::WebSocket;

    get '/' => sub {q[
        <html>
        <head>
        <script>
        var ws_path = "ws://localhost:5000/_hippie/ws";
        var socket = new WebSocket(ws_path);
        socket.onopen = function() {
            document.getElementById('conn-status').innerHTML = 'Connected';
        };
        socket.onmessage = function(e) {
            var data = JSON.parse(e.data);
            if (data.msg)
                alert (data.msg);
        };
        function send_msg(message) {
            socket.send(JSON.stringify({ msg: message }));
        }
        </script>
        </head>
        <body>
        Connection Status: <span id="conn-status"> Disconnected </span>
        <input value="Send Message" type=button onclick="send_msg('hello')" />
        </body>
        </html>
    ]};

    dance;

    # Run app with Twiggy
    twiggy --listen :5000 bin/app.pl

    # Now you can visit http://localhost:5000 with a browser that supports
    # WebSockets, such as Chrome.

=head1 DESCRIPTION

This goal of this plugin is to make it as easy as possible to create WebSocket
enabled apps with L<Dancer>.
It is built on top of L<Web::Hippie>, but it abstracts that out as much as
possible.
You should be aware that it registers 2 routes that Web::Hippie needs:
get('/new_listener') and get('/message').
Be careful to not define those routes in your app.

This plugin currently requires that you run your app via L<Twiggy>.
For example:

    twiggy --listen :5000 bin/app.pl

=head1 METHODS

These methods allow you to interact with WebSockets from the server side.
If you are only going to interact with WebSockets from javascript,
as shown in the L</SYNOPSIS>, then these are not necessary.

=head2 ws_on_message (\&handler)

Registers a handler that gets triggered when a new message arrives.
The handler gets passed 1 argument, a data structure containing the message.
Note that if you register a handler in this way, the onmessage callback
of the WebSocket object in your javascript will not get triggered.

    ws_on_message sub {
        my $data = shift;
        debug $data->{msg};
    };

=head2 ws_on_new_listener (\&handler)

Registers a handler that gets triggered when a new listener is created.
The handler gets passed no arguments.

    ws_on_new_listener sub {
        # do something when a new listener is created
    };

=head2 ws_send ($message)

Allows you to send a WebSocket message from within a Dancer route.

    any '/send_msg' => sub {
        my $msg = params->{msg};
        ws_send $msg;
    };

    # Now you can send a message to your application via curl:
    curl http://localhost:5000/send_msg?msg=hello

=head1 AUTHORS

=over 4

=item *

Naveed Massjouni <naveedm9@gmail.com>

=item *

Franck Cuny <franck@lumberjaph.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

