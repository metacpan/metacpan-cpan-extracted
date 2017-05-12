package AnyEvent::Chromi;

use strict;

use AnyEvent::Socket;
use AnyEvent::Handle;
 
use Protocol::WebSocket::Handshake::Client;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

use JSON::XS;
use URI::Escape;
use Log::Any qw($log);

our $VERSION = '1.01';

sub new
{
    my ($class, %args) = @_;
    my $self = {};
    bless $self, $class;

    $self->{mode} = $args{mode} // 'server';
    $self->{port} = $args{port} // 7441;
    $self->{on_connect} = $args{on_connect} if defined $args{on_connect};
    if($self->{mode} eq 'client') {
        $self->_start_client();
    }
    else {
        $self->_start_server();
    }

    return $self;
}

sub call
{
    my ($self, $method, $args, $cb) = @_;
    if(not $self->is_connected) {
        $log->warning("can't call $method: not connected");
        return;
    }
    my $id = int(rand(100000000));
    my $msg = "chromi $id $method";
    if($args) {
        $msg .= " " . uri_escape(encode_json($args));
    }
    my $frame = Protocol::WebSocket::Frame->new($msg);
    if($cb) {
        $self->{callbacks}{$id} = $cb;
    }
    $self->{handle}->push_write($frame->to_bytes);
}

sub is_connected
{
    my ($self) = @_;
    return $self->{connected};
}

sub _setup_connection
{
    my ($self, $fh) = @_;

    my $ws_handshake = $self->{mode} eq 'client' ? Protocol::WebSocket::Handshake::Client->new(url => 'ws://localhost') :
                                                   Protocol::WebSocket::Handshake::Server->new;
    my $ws_frame = Protocol::WebSocket::Frame->new;
    
    $self->{handle} = AnyEvent::Handle->new(fh => $fh);

    $self->{handle}->on_error(
        sub {
            my ($handle, $fatal, $message);
            if($fatal) {
                $log->error("connection fatal error: $message");
                $self->{connected} = 0;
            }
            else {
                $log->warning("connection error: $message");
            }
        }
    );

    $self->{handle}->on_eof( sub {
        $self->{connected} = 0;
        if($self->{mode} eq 'client') {
            $self->_client_schedule_reconnect();
        }
    });

    $self->{handle}->on_read( sub {
        my ($handle) = @_;
        my $chunk = $handle->{rbuf};
        $handle->{rbuf} = undef;
        
        # Handshake
        if (!$ws_handshake->is_done) {
            $ws_handshake->parse($chunk);
            if ($ws_handshake->is_done) {
                if(not $self->{mode} eq 'client') {
                    $handle->push_write($ws_handshake->to_string);
                }
                $self->{connected} = 1;
                if($self->{on_connect}) {
                    my $cb = $self->{on_connect};
                    &$cb($self);
                }
            }
        }
        
        $self->{connected} or return;

        # Post-Handshake
        $ws_frame->append($chunk);
        
        while (my $message = $ws_frame->next) {
            if($message =~ /^Chromi (\d+) (\w+) (.*)$/) {
                my ($id, $status, $reply) = ($1, $2, $3);
                if($self->{callbacks}{$id}) {
                    $reply = uri_unescape($reply);
                    if($reply =~ /^\[(.*)\]$/s) {
                        &{$self->{callbacks}{$id}}($status, decode_json($1));
                    }
                    else {
                        die "error: $reply\n";
                    }
                    delete $self->{callbacks}{$id};
                }
            }
        }
    });

    if($self->{mode} eq 'client') {
        $self->{handle}->push_write($ws_handshake->to_string);
    }
}

sub _client_schedule_reconnect
{
    my ($self) = @_;

    $log->info("connection failed. reconnecting in 1 second");

    $self->{conn_w} = AnyEvent->timer (after => 1, cb => sub {
        $self->_start_client();
    });
}

sub _start_client
{
    my ($self) = @_;

    $self->{tcp_client} = AnyEvent::Socket::tcp_connect 'localhost', $self->{port}, sub {
        my ($fh) = @_;
        if(! $fh) {
            $self->_client_schedule_reconnect();
            return;
        }

        $self->_setup_connection($fh);
    };
}

sub _start_server
{
    my ($self) = @_;
    $self->{tcp_server} = AnyEvent::Socket::tcp_server undef, $self->{port}, sub {
        my ($fh, $host, $port) = @_;
        $self->_setup_connection($fh);
    };
}

1;

=head1 NAME

AnyEvent::Chromi - Remotely control Google Chrome from Perl

=head2 SYNOPSIS

    # Start in client mode (need "chromix-server" or examples/server.pl)
    my $chromi AnyEvent::Chromi->new(mode => 'client', on_connect => sub {
        my ($chromi) = @_;
        ...
        $chromi->call(...);
    });

    # Start in server mode
    my $chromi AnyEvent::Chromi->new(mode => 'server');

=head2 DESCRIPTION

AnyEvent::Chromi allows you to remotely control Google Chrome from a Perl script.
It requires the Chromi extension L<https://github.com/smblott-github/chromi>, which
exposes all of the Chrome Extensions API via a websocket connection.

=head2 METHODS

=over 4

=item $chromi = AnyEvent::Chromi->new(mode => ..., on_connect => ...);

=over 4

=item mode => 'client|server'

If 'server' (default), it will start a websocket server on port 7441 and wait
for the connection from Chrome (initiated by the Chromi extension). This is the
most practical way to use AnyEvent::Chromi if you write a long-running script,
because it doesn't require a separate daemon.

If 'client', it will connect to port 7441 itself, expecting a websocket server, like
the one provided by chromix-server, or by the examples/server.pl script.

=item port => N

Use port N instead of 7441.

=item on_connect => sub { my ($chromi) = @_; ... }

Will be executed as soon as Chrome connects (in server mode), or as the connection
to the websocket server is done.

=back

=item $chromi->call($method, $args, $cb)

Call the Chrome extension method C<$method>, e.g. C<chrome.windows.getAll>.

C<$args> is expected to be a ARRAYREF with the arguments for the method. It will be
converted to JSON by AnyEvent::Chromi.

C<$cb> is a callback for when the reply is received. The first argument to the callback is
the status (either "done" or "error"), and the second is a ARRAYREF with the data.

Note: you need to make sure that the JSON::XS serialization is generating the proper
data types. This is particularly important for booleans, where C<Types::Serialiser::true>
and C<Types::Serialiser::false> can be used.

=item $chromi->is_connected

In server mode: returns true if Chrome is connected and awaits commands.

In client mode: returns true if connected to chromix-server.

=back

=head2 EXAMPLES

=over

=item *

List all tabs

    $chromi->call(
        'chrome.windows.getAll', [{ populate => Types::Serialiser::true }],
        sub {
            my ($status, $reply) = @_;
            $status eq 'done' or return;
            defined $reply and ref $reply eq 'ARRAY' or return;
            map { say "$_->{url}" } @{$reply->[0]{tabs}};
            $cv->send();
        }

=item * Focus a tab

    $chromi->call(
        'chrome.tabs.update', [$tab_id, { active => Types::Serialiser::true }],
    );

=back

See also the "examples" directory:

=over

=item examples/client.pl

Lists the URLs of all tabs. Requires chromix-server

=item examples/server.pl

chromix-server replacement written in Perl. Additionally to chromix-server, it
also properly supports multiple clients with one or more chrome instances.

=back

=head2 AUTHOR

David Schweikert <david@schweikert.ch>, heavily influenced by Chromi/Chromix by
Stephen Blott.

=head2 SEE ALSO

=over

=item GitHub project

L<https://github.com/open-ch/AnyEvent-Chromi>

=item Chromi (Chrome extension)

L<https://github.com/smblott-github/chromi>

=item Chromix (command-line tool)

L<https://http://chromix.smblott.org/>

=back
