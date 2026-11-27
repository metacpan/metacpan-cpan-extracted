use v5.44;
use experimental 'class';

# A joined (or joining) channel. Obtain one from BoardStreams::Client->join.
#
# Every call of join returns a channel object of its own, and the ones for
# the same name share a single membership on the server. So separate parts
# of a program can each join a channel and each leave it when done: the
# client only leaves when the last of them has.
#
# This is a port of the Channel class of the JavaScript client and is meant
# to behave identically.
class BoardStreams::Client::Channel {
    our $VERSION = "v0.0.58";

    use Mojo::Promise;
    use RxPerl::Mojo qw(rx_behavior_subject rx_observable rx_replay_subject rx_subject op_filter op_map);

    use BoardStreams::Client::Error;

    field $membership :param;    # the BoardStreams::Client::Membership behind this object

    field $state_subject  = rx_replay_subject->new(1);
    field $events_subject = rx_subject->new;
    field $gaps_subject   = rx_subject->new;
    field $status_subject;
    field @feed;                 # subscriptions to the membership
    field $joined = Mojo::Promise->new;
    field $done   = 0;           # true once this object has left or the membership is over
    field $last_state;

    ADJUST {
        # A refused join that nobody waits for is not an unhandled error.
        $joined->catch(sub { });
        $joined->resolve if $membership->has_joined;
        $status_subject = rx_behavior_subject->new($membership->status_subject->get_value);
        push @feed,
            $membership->state_subject->subscribe(sub ($state) { $state_subject->next($state) }),
            $membership->events_subject->subscribe(sub ($event) { $events_subject->next($event) }),
            $membership->gaps_subject->subscribe(sub { $gaps_subject->next(undef) }),
            $membership->status_subject->subscribe(sub ($status) {
                $status_subject->next($status) if $status ne $status_subject->get_value;
            });
    }

    method name { $membership->name }

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
    method state { $done ? $last_state : $membership->state }

    # A promise that resolves once, when the channel is first joined (at
    # once if another part of the program has joined it already), and
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
        $membership->submit($self, 'action', $action_name, $payload) unless $done;
        return;
    }

    # Sends a request and returns a promise of the response payload, which
    # rejects with a BoardStreams::Client::Error on failure. By the time it
    # settles, state and the events already reflect whatever the request
    # changed on this channel.
    method request ($request_name, $payload = undef) {
        my $promise = Mojo::Promise->new;
        return $promise->reject(BoardStreams::Client::Error->new(reason => $status_subject->get_value)) if $done;
        $membership->submit($self, 'request', $request_name, $payload,
            sub ($response) { $promise->resolve($response) },
            sub ($error)    { $promise->reject($error) });
        return $promise;
    }

    # Ends this use of the channel: its observables complete and its
    # unanswered requests are rejected. The client leaves the channel on
    # the server when every object that join returned for it has left.
    # Calling it again does nothing.
    method leave {
        return if $done;
        my $error = BoardStreams::Client::Error->new(reason => 'left');
        $self->_finish('left', $error);
        $membership->release($self, $error);
        $self->_complete;
        return;
    }

    # The methods below are for BoardStreams::Client::Membership.

    method _joined { $joined->resolve }

    # The membership itself is over: left by the client's close, or refused.
    method _ended ($status, $error) {
        $self->_finish($status, $error) unless $done;
    }

    method _finish ($status, $error) {
        $done       = 1;
        $last_state = $membership->state;
        $_->unsubscribe for splice @feed;
        $status_subject->next($status);
        $joined->reject($error);
    }

    method _complete {
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
