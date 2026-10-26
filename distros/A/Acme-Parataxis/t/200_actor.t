use v5.40;
use blib;
use Acme::Parataxis qw[async with_timeout yield];
use Acme::Parataxis::Actor;
use Test2::V1 -ipP;
$|++;

# Thin actors. `Actor->spawn(sub ($self, $msg) { ... })` runs the handler in a dedicated fiber that owns a
# bounded Channel mailbox; `ask` tags a message with a Future (the handler's return value travels back through it),
# `send` is fire-and-forget, and `stop` shuts down gracefully (draining what was already queued). Supervision is out
# of scope -- a handler die fails its own ask (or warns for a fire-and-forget) and the actor keeps running.
subtest 'ask: the handler return value comes back through the future' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) {
                return 'pong' if $msg->{cmd} eq 'ping';
                return undef;
            }
        );
        my $reply = $actor->ask( { cmd => 'ping' } );
        is $reply->await, 'pong', 'the reply arrived';
        $actor->stop;
    };
};
subtest 'fifo: messages are handled in send order' => sub {
    my @order;
    async {
        my $actor   = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg->{n} } );
        my @futures = map { $actor->ask( { n => $_ } ) } 0 .. 19;    # 20 messages > the 16-slot mailbox
        my @vals    = map { $_->await } @futures;
        is "@vals", '0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19', 'answers come back in sending order';
        $actor->stop;
    };
};
subtest 'fire-and-forget send still runs its handler' => sub {
    my $count = 0;
    async {
        my $actor = Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) {
                $count++      if $msg->{cmd} eq 'bump';
                return $count if $msg->{cmd} eq 'tally';
            }
        );
        $actor->send( { cmd => 'bump' } ) for 1 .. 5;
        is $actor->ask( { cmd => 'tally' } )->await, 5, 'all five sends were handled';
        $actor->stop;
    };
};
subtest 'a handler die fails its own ask, and the actor keeps running' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) {
                die 'handler exploded' if $msg->{cmd} eq 'boom';
                return 'ok';
            }
        );
        my $reply = $actor->ask( { cmd => 'boom' } );
        my $err   = dies { $reply->await };
        ok $err, 'the ask threw';
        like "$err", qr/handler exploded/, 'the handler message is preserved';
        is $actor->ask( { cmd => 'ok' } )->await, 'ok', 'the actor survived and still answers';
        $actor->stop;
    };
};
subtest 'a fire-and-forget handler die warns but does not kill the actor' => sub {
    my @warns;
    async {
        local $SIG{__WARN__} = sub { push @warns, $_[0] };
        my $actor = Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) {
                die 'fire in the hole' if $msg->{cmd} eq 'fail';
                return 'ok';
            }
        );
        $actor->send( { cmd => 'fail' } );
        is $actor->ask( { cmd => 'ok' } )->await, 'ok', 'the actor still answers';
        $actor->stop;
    };
    ok( ( grep {/handler died/} @warns ), 'the failure was reported as a warning' );
};
subtest 'with_timeout aborts an ask, and the actor is untouched' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) {
                Acme::Parataxis::await_sleep(300) if $msg->{cmd} eq 'slow';
                return 'fast';
            }
        );
        my $reply = $actor->ask( { cmd => 'slow' } );
        my $err   = dies {
            with_timeout( 10, sub { $reply->await } );
        };
        ok $err, 'the ask timed out';
        is $actor->ask( { cmd => 'ok' } )->await, 'fast', 'the actor never noticed the aborted ask';
        $actor->stop;
    };
};
subtest 'stop drains what was already queued, then the actor is gone' => sub {
    my $actor_ref;
    async {
        my $actor   = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg->{n} } );
        my @futures = map { $actor->ask( { n => $_ } ) } 1 .. 4;
        $actor->stop;
        my @vals = map { $_->await } @futures;
        is "@vals", '1 2 3 4', 'all pre-stop asks were still answered';
        $actor_ref = $actor;
    };
    ok !$actor_ref->is_alive, 'dead once the drain finished';
    my $err = dies { $actor_ref->send( { n => 99 } ) };
    ok $err, 'send() after death croaks';
    like "$err", qr/no longer running/, 'the message says why';
};
subtest 'spawn outside a scheduled fiber croaks' => sub {
    my $err = dies {
        Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { } );
    };
    ok $err, 'rejected';
    like "$err", qr/scheduled fiber/, 'with the reason';
};
subtest 'no fiber leaks: an actor that stops returns the live count to baseline' => sub {
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg } );
        is $actor->ask('hi')->await, 'hi', 'still works';
        $actor->stop;
    };
    is Acme::Parataxis::get_live_fiber_count(), $base, 'the actor fiber was reaped';
};
subtest 'an unreferenced stopped actor is collected (no self -> fiber -> closure ref cycle)' => sub {
    my $weak;
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg->{n} } );
        is $actor->ask( { n => 7 } )->await, 7, 'the actor answers';
        $actor->stop;
        weaken( $weak = $actor );
        undef $actor;
        yield while Acme::Parataxis::get_live_fiber_count() > 1;    # let _run finish its drain
    };
    is $weak, undef, 'the actor object is freed once the owner and the fiber are both done';
};
subtest 'an actor dropped while parked (no ->stop) is collected (DESTROY wakes the parked fiber)' => sub {
    my $weak;
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg->{n} } );
        is $actor->ask( { n => 3 } )->await, 3, 'the actor answers';
        weaken( $weak = $actor );
        undef $actor;                                               # dropped WITHOUT ->stop while the fiber is parked in ->get; DESTROY wakes it
        yield while Acme::Parataxis::get_live_fiber_count() > 1;    # let the woken fiber drain and reap itself
    };
    is $weak, undef, "the dropped-while-parked actor object was freed";
};
#
done_testing;
