use v5.44;
use experimental 'class';

# A joined (or joining) channel. Obtain one from BoardStreams::Client->join.
# This is a port of the Channel class of the JavaScript client and is meant
# to behave identically.
class BoardStreams::Client::Channel {
    our $VERSION = "v0.0.56";

    use Mojo::Promise;
    use Mojo::Util qw(generate_secret);
    use RxPerl::Mojo qw(rx_behavior_subject rx_observable rx_replay_subject rx_subject op_filter op_map);

    use BoardStreams::Client::Error;
    use BoardStreams::Diff qw(patch);

    field $name :param :reader;
    field $link :param;    # { send => sub, forget => sub, reconnect => sub }, provided by the client

    field $state_subject  = rx_replay_subject->new(1);
    field $events_subject = rx_subject->new;
    field $gaps_subject   = rx_subject->new;
    field $status_subject = rx_behavior_subject->new('joining');
    field @pending;        # unconfirmed actions and requests, oldest first: { id, message, resolve, reject }
    field @held;           # responses waiting for their updates: { seq, settle }
    field $joined = Mojo::Promise->new;
    field $state;
    field $seq;
    field $live = 0;       # true while joined on the current connection

    ADJUST {
        # A refused join that nobody waits for is not an unhandled error.
        $joined->catch(sub { });
    }

    # The channel's state; replays the latest value and emits on every
    # change. Its first value arrives with the first join, but a later
    # rejoin that missed nothing does not emit: use status_o to follow
    # rejoins.
    method state_o { _read_only($state_subject) }

    # Every event of the channel, in order, as { name, payload, seq }.
    method events_o { _read_only($events_subject) }

    # Emits when this client was away for longer than the server keeps
    # history: the state is current again, but some events were missed.
    method gaps_o { _read_only($gaps_subject) }

    # Replays the current status: 'joining', 'joined', 'rejected' or
    # 'left'. Emits 'joined' on every join, including each automatic rejoin
    # after a reconnection, and 'joining' while disconnected.
    method status_o { _read_only($status_subject) }

    # The current state, or undef before the first join completes.
    method state { $state }

    # A promise that resolves once, when the channel is first joined, and
    # rejects with a BoardStreams::Client::Error if the server refuses.
    method joined { $joined }

    # The payloads of the events with the given name.
    method on ($event_name) {
        return $events_subject->pipe(
            op_filter(sub { $_[0]{name} eq $event_name }),
            op_map(sub { $_[0]{payload} }),
        );
    }

    # Sends an action. It is delivered once, even across reconnections.
    method action ($action_name, $payload = undef) {
        $self->_submit('action', $action_name, $payload);
        return;
    }

    # Sends a request and returns a promise of the response payload, which
    # rejects with a BoardStreams::Client::Error on failure. By the time it
    # settles, state and the events already reflect whatever the request
    # changed on this channel.
    method request ($request_name, $payload = undef) {
        my $promise = Mojo::Promise->new;
        $self->_submit('request', $request_name, $payload,
            sub ($response) { $promise->resolve($response) },
            sub ($error)    { $promise->reject($error) });
        return $promise;
    }

    # Leaves the channel. Unanswered requests are rejected.
    method leave {
        my $status = $status_subject->get_value;
        return if $status eq 'left' or $status eq 'rejected';
        $link->{send}->({ type => 'leave', channel => $name });
        $self->_end('left', BoardStreams::Client::Error->new(reason => 'left'));
        return;
    }

    # The methods below are for BoardStreams::Client.

    method _connected {
        $link->{send}->({ type => 'join', channel => $name, (defined $seq ? (since => $seq) : ()) });
    }

    method _disconnected {
        $live = 0;
        $status_subject->next('joining') if $status_subject->get_value eq 'joined';
    }

    method _owns ($id) {
        return 0 unless defined $id and !ref $id;
        return scalar grep { $_->{id} eq $id } @pending;
    }

    method _receive ($message) {
        my $type = $message->{type} // '';

        if ($type eq 'joined') {
            if ($message->{updates}) {
                $self->_apply($_) for $message->{updates}->@*;
            }
            else {
                $state = $message->{state};
                $seq   = $message->{seq};
                $state_subject->next($state);
                $gaps_subject->next(undef) if $message->{gap};
            }
            $live = 1;
            $status_subject->next('joined');
            $joined->resolve;
            # Whatever was not confirmed before is sent (again); the server
            # recognises repeats by their id.
            $link->{send}->($_->{message}) for @pending;
            $self->_release;
        }
        elsif ($type eq 'update') {
            return if !$live or !defined $seq or $message->{seq} <= $seq;
            # An update was skipped; rejoining makes the server fill the hole.
            return $link->{reconnect}->() if $message->{seq} != $seq + 1;
            $self->_apply($message);
        }
        elsif ($type eq 'rejected') {
            $self->_end('rejected',
                BoardStreams::Client::Error->new(reason => $message->{reason}, data => $message->{data}));
        }
        elsif ($type eq 'ack') {
            @pending = grep { $_->{id} ne $message->{id} } @pending;
        }
        elsif ($type eq 'response') {
            my ($answered) = grep { $_->{id} eq $message->{id} } @pending or return;
            @pending = grep { $_->{id} ne $message->{id} } @pending;
            my $settle = sub {
                return $answered->{resolve} && $answered->{resolve}->($message->{payload}) if $message->{ok};
                $answered->{reject}->(BoardStreams::Client::Error->new(
                    reason => $message->{error}{reason}, data => $message->{error}{data})) if $answered->{reject};
            };
            # Hold the response until the updates it caused have been applied.
            push @held, { seq => $message->{seq} // 0, settle => $settle };
            $self->_release;
        }
        return;
    }

    method _submit ($type, $what, $payload, $resolve = undef, $reject = undef) {
        my $status = $status_subject->get_value;
        if ($status eq 'left' or $status eq 'rejected') {
            $reject->(BoardStreams::Client::Error->new(reason => $status)) if $reject;
            return;
        }
        my $id      = substr generate_secret() =~ tr/A-Za-z0-9//cdr, 0, 32;
        my $message = { type => $type, channel => $name, id => $id, name => $what, payload => $payload };
        push @pending, { id => $id, message => $message, resolve => $resolve, reject => $reject };
        $link->{send}->($message) if $live;
    }

    method _apply ($update) {
        if ($update->{diff}) {
            $state = patch($state, $update->{diff});
            $state_subject->next($state);
        }
        $seq = $update->{seq};
        $events_subject->next({ %$_, seq => $seq }) for $update->{events}->@*;
        $self->_release;
    }

    method _release {
        my $reached = $seq // 0;
        my @ready = grep { $_->{seq} <= $reached } @held;
        @held = grep { $_->{seq} > $reached } @held;
        $_->{settle}->() for @ready;
    }

    method _end ($status, $error) {
        $live = 0;
        $link->{forget}->();
        $status_subject->next($status);
        $joined->reject($error);
        my @unanswered = splice @pending;
        $_->{reject} && $_->{reject}->($error) for @unanswered;
        my @waiting = splice @held;
        $_->{settle}->() for @waiting;
        $_->complete for $state_subject, $events_subject, $gaps_subject, $status_subject;
    }

    # An observable that passes on what a subject emits, without the
    # subject's next, error and complete methods.
    sub _read_only ($subject) {
        return rx_observable->new(sub ($subscriber) {
            $subject->subscribe($subscriber);
            return;
        });
    }
}

1;
