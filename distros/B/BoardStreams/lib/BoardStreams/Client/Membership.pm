use v5.44;
use experimental 'class';

# The client's one membership of a channel, shared by every
# BoardStreams::Client::Channel that the client has handed out for that
# name. It talks to the server; the channels pass on what it receives. It
# leaves the channel when the last of them has left. For internal use; a
# port of the Membership class of the JavaScript client.
class BoardStreams::Client::Membership {
    our $VERSION = "v0.0.58";

    use Mojo::Util qw(generate_secret);
    use RxPerl::Mojo qw(rx_behavior_subject rx_replay_subject rx_subject);

    use Scalar::Util qw(refaddr);

    use BoardStreams::Client::Channel;
    use BoardStreams::Client::Error;
    use BoardStreams::Diff qw(patch);

    field $name :param :reader;
    field $link :param;    # { send => sub, forget => sub, reconnect => sub }, provided by the client

    field $state_subject  :reader = rx_replay_subject->new(1);
    field $events_subject :reader = rx_subject->new;
    field $gaps_subject   :reader = rx_subject->new;
    field $status_subject :reader = rx_behavior_subject->new('joining');
    field %channels;       # the channel objects in use, by address
    field @pending;        # unconfirmed actions and requests, oldest first: { id, owner, message, resolve, reject }
    field @held;           # responses waiting for their updates: { seq, owner, settle }
    field $has_joined :reader = 0;    # true once the first join has succeeded
    field $state :reader;
    field $seq;
    field $live = 0;       # true while joined on the current connection

    # One more user of the channel.
    method open {
        my $channel = BoardStreams::Client::Channel->new(membership => $self);
        $channels{ refaddr $channel } = $channel;
        return $channel;
    }

    # One user of the channel is done with it. Its unanswered requests are
    # rejected; its actions are still delivered. The last one to go takes
    # the client out of the channel.
    method release ($channel, $error) {
        my $owner = refaddr $channel;
        delete $channels{$owner};
        my @rejected = grep { $_->{owner} == $owner and $_->{reject} } @pending;
        @pending = grep { !($_->{owner} == $owner and $_->{reject}) } @pending;
        $_->{reject}->($error) for @rejected;
        my @mine = grep { $_->{owner} == $owner } @held;
        @held = grep { $_->{owner} != $owner } @held;
        $_->{settle}->() for @mine;
        $self->leave unless %channels;
        return;
    }

    # Leaves the channel on the server, whoever still uses it.
    method leave {
        my $status = $status_subject->get_value;
        return if $status eq 'left' or $status eq 'rejected';
        $link->{send}->({ type => 'leave', channel => $name });
        $self->_end('left', BoardStreams::Client::Error->new(reason => 'left'));
        return;
    }

    method connected {
        $link->{send}->({ type => 'join', channel => $name, (defined $seq ? (since => $seq) : ()) });
    }

    method disconnected {
        $live = 0;
        $status_subject->next('joining') if $status_subject->get_value eq 'joined';
    }

    method owns ($id) {
        return 0 unless defined $id and !ref $id;
        return scalar grep { $_->{id} eq $id } @pending;
    }

    method receive ($message) {
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
            $has_joined = 1;
            $_->_joined for values %channels;
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
            push @held, { seq => $message->{seq} // 0, owner => $answered->{owner}, settle => $settle };
            $self->_release;
        }
        return;
    }

    method submit ($channel, $type, $what, $payload, $resolve = undef, $reject = undef) {
        my $status = $status_subject->get_value;
        if ($status eq 'left' or $status eq 'rejected') {
            $reject->(BoardStreams::Client::Error->new(reason => $status)) if $reject;
            return;
        }
        my $id      = substr generate_secret() =~ tr/A-Za-z0-9//cdr, 0, 32;
        my $message = { type => $type, channel => $name, id => $id, name => $what, payload => $payload };
        push @pending, { id => $id, owner => refaddr $channel, message => $message, resolve => $resolve, reject => $reject };
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
        my @channels = values %channels;
        %channels = ();
        $_->_ended($status, $error) for @channels;
        $status_subject->next($status);
        my @unanswered = splice @pending;
        $_->{reject} && $_->{reject}->($error) for @unanswered;
        my @waiting = splice @held;
        $_->{settle}->() for @waiting;
        $_->_complete for @channels;
        $_->complete for $state_subject, $events_subject, $gaps_subject, $status_subject;
    }

}

1;
