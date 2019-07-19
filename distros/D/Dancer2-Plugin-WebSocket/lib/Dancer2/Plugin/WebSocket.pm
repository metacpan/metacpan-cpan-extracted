package Dancer2::Plugin::WebSocket;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: add a websocket interface to your Dancers app
$Dancer2::Plugin::WebSocket::VERSION = '0.2.0';

use v5.12.0;

use Plack::App::WebSocket;

use Dancer2::Plugin;

has serializer => (
    is => 'ro',
    from_config => 1,
    coerce => sub {
        my $serializer = shift or return undef;
        require JSON::MaybeXS;
        JSON::MaybeXS->new( ref $serializer ? %$serializer : () );
    },
);

has mount_path => (
    is => 'ro',
    from_config => sub { '/ws' },
);


has 'on_'.$_ => (
    is => 'rw',
    plugin_keyword => 'websocket_on_'.$_,
    default => sub { sub { } },
) for qw/
    open
    message
    close
/;

has 'on_error' => (
    is => 'rw',
    plugin_keyword => 'websocket_on_error',
    default => sub { sub {
            my $env = shift;
            return [500,
                    ["Content-Type" => "text/plain"],
                    ["Error: " . $env->{"plack.app.websocket.error"}]];
        }
    },
);

has connections => (
    is => 'ro',
    default => sub{ {} },
);


sub websocket_connections :PluginKeyword {
    my $self = shift;
    return values %{ $self->connections };
}


sub websocket_url :PluginKeyword {
    my $self = shift;
    my $request = $self->app->request;
    my $proto = $request->secure ? 'wss://' : 'ws://';
    my $address = $proto . $request->host . $self->mount_path;

    return $address;
}


sub websocket_mount :PluginKeyword {
    my $self = shift;

    return
        $self->mount_path => Plack::App::WebSocket->new(
        on_error => sub { $self->on_error->(@_) },
        on_establish => sub {
            my $conn = shift; ## Plack::App::WebSocket::Connection object
            my $env = shift;  ## PSGI env

            require Moo::Role;

            Moo::Role->apply_roles_to_object(
                $conn, 'Dancer2::Plugin::WebSocket::Connection'
            );
            $conn->manager($self);
            $conn->serializer($self->serializer);
            $self->connections->{$conn->id} = $conn;

            $self->on_open->( $conn, $env, @_ );

            $conn->on(
                message => sub {
                    my( $conn, $message ) = @_;
                    if( my $s = $conn->serializer ) {
                        $message = $s->decode($message);
                    }
                    use Try::Tiny;
                    try {
                        $self->on_message->( $conn, $message );
                    }
                    catch {
                        warn $_;
                        die $_;
                    };
                },
                finish => sub {
                    $self->on_close->($conn);
                    delete $self->connections->{$conn->id};
                    $conn = undef;
                },
            );
        }
    )->to_app;

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::WebSocket - add a websocket interface to your Dancers app

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

F<bin/app.psgi>:

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use FindBin;
    use lib "$FindBin::Bin/../lib";

    use Plack::Builder;

    use MyApp;

    builder {
        mount( MyApp->websocket_mount );
        mount '/' => MyApp->to_app;
    }

F<config.yml>:

    plugins:
        WebSocket:
            # default values
            serializer: 0
            mount_path: /ws

F<MyApp.pm>:

  package MyApp;

  use Dancer2;
  use Dancer2::Plugin::WebSocket;

  websocket_on_message sub {
    my( $conn, $message ) = @_;
    $conn->send( $message . ' world!' );
  };

  get '/' => sub {
    my $ws_url = websocket_url;
    return <<"END";
      <html>
        <head><script>
            var urlMySocket = "$ws_url";

            var mySocket = new WebSocket(urlMySocket);

            mySocket.onmessage = function (evt) {
              console.log( "Got message " + evt.data );
            };

            mySocket.onopen = function(evt) {
              console.log("opening");
              setTimeout( function() {
                mySocket.send('hello'); }, 2000 );
            };

      </script></head>
      <body><h1>WebSocket client</h1></body>
    </html>
  END
  };

  get '/say_hi' => sub {
    $_->send([ "Hello!" ]) for websocket_connections;
  };

  true;

=head1 DESCRIPTION

C<Dancer2::Plugin::WebSocket> provides an interface to L<Plack::App::WebSocket>
and allows to interact with the webSocket connections within the Dancer app.

L<Plack::App::WebSocket>, and thus this plugin, requires a plack server that
supports the psgi I<streaming>, I<nonblocking> and I<io>. L<Twiggy>
is the most popular server fitting the bill.

=head1 CONFIGURATION

=over

=item serializer

If serializer is set to a C<true> value, messages will be assumed to be JSON
objects and will be automatically encoded/decoded using a L<JSON::MaybeXS>
serializer.  If the value of C<serializer> is a hash, it'll be passed as
arguments to the L<JSON::MaybeXS> constructor.

    plugins:
        WebSocket:
            serializer:
                utf8:         1
                allow_nonref: 1

By the way, if you want the connection to automatically serialize data
structures to JSON on the client side, you can do something like

    var mySocket = new WebSocket(urlMySocket);
    mySocket.sendJSON = function(message) {
        return this.send(JSON.stringify(message))
    };

    // then later...
    mySocket.sendJSON({ whoa: "auto-serialization ftw!" });

=item mount_path

Path for the websocket mountpoint. Defaults to C</ws>.

=back

=head1 PLUGIN KEYWORDS

In the various callbacks, the connection object C<$conn>
is a L<Plack::App::WebSocket::Connection> object
augmented with the L<Dancer2::Plugin::WebSocket::Connection> role.

=head2 websocket_on_open sub { ... }

    websocket_on_open sub {
        my( $conn, $env ) = @_;
        ...;
    };

Code invoked when a new socket is opened. Gets the new
connection
object and the Plack
C<$env> hash as arguments.

=head2 websocket_on_close sub { ... }

    websocket_on_close sub {
        my( $conn ) = @_;
        ...;
    };

Code invoked when a new socket is opened. Gets the
connection object as argument.

=head2 websocket_on_error sub { ... }

    websocket_on_error sub {
        my( $env ) = @_;
        ...;
    };

Code invoked when an error  is detected. Gets the Plack
C<$env> hash as argument and is expected to return a
Plack triplet.

If not explicitly set, defaults to

    websocket_on_error sub {
        my $env = shift;
        return [
            500,
            ["Content-Type" => "text/plain"],
            ["Error: " . $env->{"plack.app.websocket.error"}]
        ];
    };

=head2 websocket_on_message sub { ... }

    websocket_on_message sub {
        my( $conn, $message ) = @_;
        ...;
    };

Code invoked when a message is received. Gets the connection
object and the message as arguments.

Note that while C<websocket_on_message> fires for all messages receives, you can
also be a little more selective. Indeed, each connection, being a L<Plack::App::WebSocket::Connection>
object, can have its own (multiple) handlers. So you can do things like

  websocket_on_open sub {
    my( $conn, $env ) = @_;
    $conn->on( message => sub {
      my( $conn, $message ) = @_;
      warn "I'm only being executed for messages sent via this connection";
    });
  };

=head2 websocket_connections

Returns the list of currently open websocket connections.

=head2 websocket_url

Returns the full url of the websocket mountpoint.

    # assuming host is 'localhost:5000'
    # and the mountpoint is '/ws'
    print websocket_url;  # => ws://localhost:5000/ws

=head2 websocket_mount

Returns the mountpoint and the Plack app coderef to be
used for C<mount> in F<app.psgi>. See the SYNOPSIS.

=head1 GOTCHAS

It seems that the closing the socket causes Google's chrome to burp the
following to the console:

    WebSocket connection to 'ws://...' failed: Received a broken close frame containing a reserved status code.

Firefox seems to be happy, though. The issue is probably somewhere deep in
L<AnyEvent::WebSocket::Server>. Since the socket is being closed anyway, I am
not overly worried about it.

=head1 SEE ALSO

This plugin is nothing much than a sugar topping atop
L<Plack::App::WebSocket>, which is itself L<AnyEvent::WebSocket::Server>
wrapped in Plackstic.

Mojolicious also has nice WebSocket-related offerings. See
L<Mojolicious::Plugin::MountPSGI> or
L<http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Web-server-embedding>.
(hi Joel!)

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
