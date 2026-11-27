use v5.44;
use experimental 'class';

# A connection to a BoardStreams server, kept alive by reconnecting: the
# Perl counterpart of the JavaScript client, ported from it and meant to
# behave identically. See the POD at the end of this file.
class BoardStreams::Client {
    our $VERSION = "v0.0.58";

    use Mojo::UserAgent;
    use RxPerl::Mojo qw(rx_behavior_subject rx_interval rx_observable rx_timer);
    use Scalar::Util qw(refaddr);
    use Time::HiRes qw(time);

    use BoardStreams ();
    use BoardStreams::Client::Channel;
    use BoardStreams::Client::Membership;
    use BoardStreams::Client::Error;

    field $url :param;
    field $min_delay :param = 0.5;    # seconds before the first reconnection attempt; doubles per attempt
    field $max_delay :param = 30;     # upper limit for that delay, in seconds
    field $idle_delay :param = 30;   # seconds the connection is kept with no channel joined; undef for ever
    field $ua :param = undef;         # a Mojo::UserAgent to connect with

    field $status_subject = rx_behavior_subject->new('connecting');
    field %channels;                   # memberships by channel name
    field $socket;                    # the current connection attempt: { tx => ... } once established
    field $open = 0;                  # true once the server has greeted with the same protocol version
    field $attempt = 0;
    field $timer;                     # subscription of the pending reconnection
    field $watchdog;                  # subscription of the periodic silence check
    field $silence_limit = 0;
    field $last_seen = 0;
    field $fatal;
    field $idle_timer;               # subscription of the wait before going idle
    field $idle = 0;                 # true while the connection is closed for lack of channels

    ADJUST {
        # The server's heartbeats and this client's own check decide when a
        # connection is dead, whatever the heartbeat interval is.
        $ua //= Mojo::UserAgent->new->inactivity_timeout(0);
        $self->_connect;
        $self->_rest;
    }

    # The state of the connection: 'connecting', 'connected',
    # 'disconnected', 'idle' or 'closed'. Replays the current value.
    method status_o {
        return rx_observable->new(sub ($subscriber) {
            $status_subject->subscribe($subscriber);
            return;
        });
    }

    # Joins a channel. Every call returns a channel object of its own, and
    # the ones for the same name share one membership on the server, which
    # lasts until each of them has left.
    method join ($name) {
        $idle_timer->unsubscribe if $idle_timer;
        undef $idle_timer;
        return $channels{$name}->open if $channels{$name};
        my $membership = $channels{$name} = BoardStreams::Client::Membership->new(
            name => $name,
            link => {
                send      => sub ($message) { $self->_send($message) },
                forget    => sub { delete $channels{$name}; $self->_rest },
                reconnect => sub { $self->_lost($socket) },
            },
        );
        my $channel = $membership->open;
        if    ($fatal) { $membership->receive({ type => 'rejected', reason => $fatal->reason, data => $fatal->data }) }
        elsif ($idle)  { $self->_wake }
        elsif ($open)  { $membership->connected }
        return $channel;
    }

    # Closes the connection for good and leaves all channels.
    method close {
        return if $status_subject->get_value eq 'closed';
        $_->leave for values %channels;
        $self->_shutdown;
        return;
    }

    method _connect {
        my $mine = $socket = {};
        $ua->websocket($url => sub ($ua, $tx) {
            my $current = $socket && refaddr $socket == refaddr $mine;
            unless ($tx->is_websocket) {
                $self->_lost($mine) if $current;
                return;
            }
            return $tx->finish unless $current;    # given up on while it was connecting
            $mine->{tx} = $tx;

            # Nothing is sent when the socket opens: the connection counts
            # as established only once the server's first heartbeat has
            # shown that it speaks the same protocol version as this client.
            $tx->on(json => sub ($tx, $message) {
                return unless $socket and refaddr $socket == refaddr $mine and ref $message eq 'HASH';
                $attempt   = 0;
                $last_seen = time;
                my $type = $message->{type} // '';
                unless ($open) {
                    return unless $type eq 'heartbeat';
                    return $self->_protocol_mismatch($message->{protocol})
                        unless ($message->{protocol} // '') eq BoardStreams::PROTOCOL_VERSION;
                    $open = 1;
                    $status_subject->next('connected');
                    $_->connected for values %channels;
                }
                return $self->_watch($message->{interval}) if $type eq 'heartbeat';
                # The server is closing this connection on purpose; coming
                # back uninvited would defeat that.
                return $self->_fail(BoardStreams::Client::Error->new(
                    reason => $message->{reason}, data => $message->{data})) if $type eq 'disconnect';
                my ($channel) = defined $message->{channel} && !ref $message->{channel}
                    ? grep { defined } $channels{ $message->{channel} }
                    : grep { $_->owns($message->{id}) } values %channels;
                $channel->receive($message) if $channel;
            });
            $tx->on(finish => sub {
                $mine->{finished} = 1;
                $self->_lost($mine);
            });
        });
    }

    # The server speaks another version of the protocol; reconnecting would
    # not help.
    method _protocol_mismatch ($server_protocol) {
        warn sprintf "BoardStreams: this client speaks protocol version %s but the server speaks %s; "
            . "the two must be the same, so no connection is made.\n",
            BoardStreams::PROTOCOL_VERSION, $server_protocol // 'an unknown (older) one';
        $self->_fail(BoardStreams::Client::Error->new(
            reason => 'protocol_mismatch',
            data   => { client => BoardStreams::PROTOCOL_VERSION, server => $server_protocol }));
    }

    # Stops for good, without reconnecting. Every channel, current or
    # future, is refused with the given error.
    method _fail ($error) {
        $fatal = $error;
        $_->receive({ type => 'rejected', reason => $error->reason, data => $error->data }) for values %channels;
        $self->_shutdown;
    }

    method _shutdown {
        $status_subject->next('closed');
        $timer->unsubscribe if $timer;
        undef $timer;
        $idle_timer->unsubscribe if $idle_timer;
        undef $idle_timer;
        $idle = 0;
        $self->_lost($socket);
        $status_subject->complete;
    }

    # The server says how often it sends heartbeats; from then on, silence
    # for two and a half intervals means the connection is dead even if
    # the socket has not noticed.
    method _watch ($interval) {
        my $limit = $interval * 2.5;
        return if $watchdog and $limit == $silence_limit;
        $silence_limit = $limit;
        $watchdog->unsubscribe if $watchdog;
        $watchdog = rx_interval($interval / 2)->subscribe(sub {
            $self->_lost($socket) if $watchdog and time - $last_seen > $silence_limit;
        });
    }

    # Gives up on a connection, whether it closed or just went silent, and
    # schedules a new one. A silent connection is abandoned without
    # waiting for it to close, which may take very long.
    method _lost ($lost) {
        return unless $lost and $socket and refaddr $socket == refaddr $lost;
        $open = 0;
        undef $socket;
        $watchdog->unsubscribe if $watchdog;
        undef $watchdog;
        $lost->{tx}->finish if $lost->{tx} and !$lost->{finished};
        $_->disconnected for values %channels;
        return if $idle or $status_subject->get_value eq 'closed';
        $status_subject->next('disconnected');
        my $nominal = $min_delay * 2**$attempt++;
        $nominal = $max_delay if $nominal > $max_delay;
        $timer = rx_timer($nominal * $self->_jitter)->subscribe(sub {
            $status_subject->next('connecting');
            $self->_connect;
        });
    }

    # Between half and all of the nominal delay, at random, so that the
    # clients a server lets go of at once do not all come back at once.
    method _jitter { 0.5 + rand() / 2 }

    # With no channel joined there is nothing to receive, so after a while
    # the connection is closed, until the next join opens one again.
    method _rest {
        return if !defined $idle_delay or %channels or $idle or $idle_timer;
        return if $status_subject->get_value eq 'closed';
        $idle_timer = rx_timer($idle_delay)->subscribe(sub {
            undef $idle_timer;
            $idle = 1;
            $timer->unsubscribe if $timer;
            undef $timer;
            $self->_lost($socket);
            $status_subject->next('idle');
        });
    }

    method _wake {
        $idle    = 0;
        $attempt = 0;
        $status_subject->next('connecting');
        $self->_connect;
    }

    method _send ($message) {
        $socket->{tx}->send({ json => $message }) if $open and $socket and $socket->{tx};
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

BoardStreams::Client - Connect to a BoardStreams server from Perl

=head1 SYNOPSIS

    use Mojo::Base -strict, -signatures;
    use BoardStreams::Client;
    use Mojo::IOLoop;

    my $bs   = BoardStreams::Client->new(url => 'wss://example.com/boardstreams');
    my $chat = $bs->join('chat:lobby');

    # Runs with the current state as soon as it is known, then on every change.
    $chat->state_o->subscribe(sub ($state) { say scalar $state->{messages}->@*, ' messages' });

    # Payloads of the events named "typing".
    $chat->on('typing')->subscribe(sub ($payload) { say "$payload->{name} is typing" });

    # Fire and forget.
    $chat->action(typing => { name => 'alice' });

    # A promise of the response payload.
    $chat->request(say => { name => 'alice', text => 'hello' })->then(
        sub ($response) { say "$response->{count} messages so far" },
        sub ($error)    { say 'failed: ', $error->reason },
    );

    Mojo::IOLoop->start;

=head1 DESCRIPTION

The Perl counterpart of the C<boardstreams> JavaScript client: it joins
channels of a BoardStreams server over one WebSocket, keeps a copy of each
channel's state up to date, delivers the channel's events in order, and
sends actions and requests. It is a port of the JavaScript client and
behaves the same way:

=over

=item *

After a disconnection it reconnects by itself, with a growing delay, and
rejoins its channels. It is sent what it missed, and actions and requests
made meanwhile are delivered once the connection is back, exactly once.

=item *

It gives up on a connection that has gone silent, judging by the server's
heartbeats.

=item *

It only works with a server that speaks the same version of the protocol
(C<BoardStreams::PROTOCOL_VERSION>), whatever the versions of the two
libraries. With any other it warns, refuses every join and request with
the reason C<protocol_mismatch>, whose data holds the two numbers as
C<client> and C<server>, and does not reconnect.

=item *

It does not reconnect after the server has disconnected it on purpose.

=back

It runs on the L<Mojo::IOLoop> event loop and connects with
L<Mojo::UserAgent>. Its streams are L<RxPerl> observables, where the
JavaScript client has RxJS ones; their names end in C<_o> where the
JavaScript names end in C<$>. Promises are L<Mojo::Promise> objects.

=head1 THE CLIENT

=head2 new

    my $bs = BoardStreams::Client->new(url => 'ws://localhost:3000/boardstreams');

Connects at once. Options:

=over

=item url

Required. The address of the server's WebSocket route.

=item min_delay

Seconds before the first reconnection attempt. Defaults to 0.5. The delay
doubles with every failed attempt, and each actual delay is shortened at
random by up to half.

=item max_delay

Upper limit for that delay, in seconds. Defaults to 30.

=item idle_delay

Seconds that the connection is kept open while no channel is joined.
Defaults to 30. After that the connection is closed and the status becomes
C<idle>; the next L</join> opens it again. Pass C<undef> to keep it open
regardless.

=item ua

A L<Mojo::UserAgent> to connect with, for example one with TLS options or
cookies set. By default the client makes its own.

=back

Note that the JavaScript client takes these three delays in milliseconds.

=head2 join

    my $channel = $bs->join('chat:lobby');

Joins a channel and returns a channel object. It can be used straight
away: actions and requests are held until the server confirms the join.

Every call returns an object of its own, and the objects for one name
share a single membership on the server: the channel is joined once and
each event is received once. So separate parts of a program can each join
a channel and each L</leave> it when done. An object obtained while the
channel is already joined is joined at once. A refused join, a kick, a
deletion and L</close> end all the objects of a channel together.

=head2 status_o

Observable of the connection's status: C<connecting>, C<connected>,
C<disconnected>, C<idle> or C<closed>. Replays the current value. C<idle>
means that the connection was closed because no channel was joined; see
C<idle_delay>.

=head2 close

Closes the connection for good and leaves all channels.

=head1 CHANNELS

=head2 name

The channel's name.

=head2 state_o

Observable of the channel's state. It replays the latest value to new
subscribers and emits on every change. Each value is a new structure that
shares the parts that did not change with the previous one; treat them as
read-only.

=head2 state

The current state, or C<undef> before the first join completes.

=head2 events_o

Observable of every event of the channel, in order, each a hash with
C<name>, C<payload> and C<seq>.

=head2 on

    $channel->on('typing')->subscribe(sub ($payload) { ... });

Observable of the payloads of the events with the given name.

=head2 action

    $channel->action($name, $payload);

Sends an action.

=head2 request

    my $promise = $channel->request($name, $payload);

Sends a request and returns a promise of the response payload. When it
resolves, C<state> already includes whatever the request changed on this
channel. It rejects with a L</ERRORS> object if the request fails, the join
is refused, or the channel is left.

=head2 joined

A promise that resolves once, when the channel is first joined, and rejects
with an error object if the server refuses.

=head2 status_o

Observable of the channel's status: C<joining>, C<joined>, C<rejected> or
C<left>. Replays the current value. It emits C<joined> on every join,
including each automatic rejoin after a reconnection, and C<joining> while
disconnected.

=head2 gaps_o

Emits when the client was away for longer than the server keeps history:
the state is current again, but some events were missed.

=head2 leave

Ends this use of the channel: the object's observables complete, its
status becomes C<left>, and its unanswered requests are rejected with the
reason C<left>. Actions it has already sent are still delivered. Calling it
again does nothing.

The client leaves the channel on the server when every object that
L</join> returned for it has left. An object that is dropped without
calling C<leave> keeps the channel joined.

=head1 ERRORS

Promises reject with a C<BoardStreams::Client::Error> object. Its C<reason>
is a short string chosen by the server, such as C<forbidden>, and its
C<data> is whatever the server attached to it. In a string it reads as
C<BoardStreams: $reason>.

A channel that the server removes this client from, or deletes, ends with
the status C<rejected> and the server's reason (C<kicked> or C<deleted>
unless it gave another).

=head1 SEE ALSO

L<BoardStreams>, and F<TUTORIAL.md> in this distribution.

=cut
