use v5.40;
use blib;
use Acme::Parataxis qw[async yield];
use Acme::Parataxis::Actor;
use builtin qw[weaken];
use Test2::V1 -ipP;
$|++;
#
subtest 'actor() finds a registered actor; the name is released on stop' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg }, 16, name => 'worker-1' );
        is Acme::Parataxis->actor('worker-1'),   $actor,     'the handle comes back by name';
        is Acme::Parataxis::actor('worker-1'),   $actor,     'plain-call form works too';
        is Acme::Parataxis->whereis('worker-1'), $actor,     'whereis is an alias';
        is Acme::Parataxis->actor('nobody'),     undef,      'unknown names answer undef';
        is $actor->name,                         'worker-1', 'name() reports the registration';
        $actor->stop;
        yield while $actor->is_alive;
        is Acme::Parataxis->actor('worker-1'), undef, 'a stopped actor never answers a lookup';
    };
};
subtest 'a supervised crash also releases the name' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) { $msg eq 'boom' ? die "handler-boom\n" : 'ok' }, 16,
            supervised => 1,
            name       => 'flaky'
        );
        my $reply = $actor->ask('boom');
        ok( dies { $reply->await }, 'the ask failed' );
        while ( $actor->is_alive ) {yield}
        is Acme::Parataxis->actor('flaky'), undef, 'the crashed actor released its name';
    };
};
subtest 'spawn name collision croaks like Erlang register' => sub {
    async {
        my $a = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg }, 16, name => 'dup' );
        like dies {
            Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg }, 16, name => 'dup' );
        }, qr[already registered], 'a second registration under the same name is rejected';
        is Acme::Parataxis->actor('dup'), $a, 'the first actor still owns the name';
        $a->stop;
        yield while $a->is_alive;
        my $b = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg }, 16, name => 'dup' );
        is Acme::Parataxis->actor('dup'), $b, 'the name is reusable once the holder is gone';
        $b->stop;
    };
};
subtest 'bad names are rejected; undef means unnamed' => sub {
    async {
        for my $bad ( '', {}, [] ) {
            my $died = dies {
                Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { }, 4, name => $bad );
            };
            ok $died, 'a non-string name croaks';
            like "$died", qr/non-empty string/, 'with the reason';
        }
        my $u = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return $msg }, 4, name => undef );
        is $u->name, undef, 'name => undef leaves the actor unnamed';
        $u->stop;
        yield while $u->is_alive;
    };
};
subtest 'swap: the in-flight message keeps the old code, later ones get the new' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn(
            sub ( $self, $msg ) {
                if ( $msg eq 'slow' ) { Acme::Parataxis::await_sleep(300); return 'old-slow' }
                return 'old';
            },
            16,
        );
        my $inflight = $actor->ask('slow');
        yield;    # let the actor pick 'slow' up and park inside the OLD handler
        $actor->swap( sub ( $self, $msg ) { return 'new' } );
        is $actor->ask('x')->await, 'new',      'a message dispatched after swap() runs the new code';
        is $inflight->await,        'old-slow', 'the message that was in flight finished with the old code';
        $actor->stop;
    };
};
subtest 'double swap: the last handler wins' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return 'one' }, 4 );
        $actor->swap( sub ( $self, $msg ) { return 'two' } );
        $actor->swap( sub ( $self, $msg ) { return 'three' } );
        is $actor->ask('x')->await, 'three', 'the second swap replaced the first';
        $actor->stop;
    };
};
subtest 'swap validates its argument and refuses a dead actor' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return 1 }, 4 );
        like dies { $actor->swap(42) }, qr[CODE], 'swap() rejects a non-CODE';
        $actor->stop;
        yield while $actor->is_alive;
        like dies {
            $actor->swap( sub {1} )
        }, qr[no longer running], 'swap() on a dead actor croaks';
    };
};
subtest 'a supervisor-style respawn inherits the registered name' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { die "boom\n" }, 4, supervised => 1, name => 'svc' );
        my $reply = $actor->ask('anything');
        eval { $reply->await; 1 };
        while ( $actor->is_alive ) {yield}
        is Acme::Parataxis->actor('svc'), undef, 'the crashed actor released the name';
        my $fresh = $actor->respawn;
        is $fresh->name,                  'svc',  'the restarted actor keeps the name';
        is Acme::Parataxis->actor('svc'), $fresh, 'and answers the lookup, so the registry key survives restarts';
        $fresh->stop;
        yield while $fresh->is_alive;
        is Acme::Parataxis->actor('svc'), undef, 'released again at stop';
    };
};
subtest 'the registration is a strong handle: a named actor outlives dropped callers' => sub {
    async {
        my $actor = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return 'alive' }, 4, name => 'keep' );
        weaken( my $w = $actor );
        undef $actor;                                           # every caller drops the handle...
        ok defined $w, 'the registry keeps the actor alive';    # ...but the name still holds it
        my $h = Acme::Parataxis->actor('keep');
        ok defined $h && $h->is_alive, 'still reachable and running';
        is $h->ask('x')->await, 'alive', 'and still answering';
        $h->stop;
        yield while $h->is_alive;
        is Acme::Parataxis->actor('keep'), undef, 'the name is released at stop';
        $h = undef;
        yield;
        is $w, undef, 'the actor is collected once the name is gone';
    };
};
subtest 'no leaks: the registry is empty and the actor fiber is reaped' => sub {
    is keys %{$Acme::Parataxis::ACTOR_REGISTRY}, 0, 'no registered names remain at the top level';
    my $base = Acme::Parataxis::get_live_fiber_count();
    async {
        my $a = Acme::Parataxis::Actor->spawn( sub ( $self, $msg ) { return 1 }, 4, name => 'z' );
        $a->stop;
        yield while $a->is_alive;
    };
    is Acme::Parataxis::get_live_fiber_count(),  $base, 'the actor fiber was reaped';
    is keys %{$Acme::Parataxis::ACTOR_REGISTRY}, 0,     'its name is gone too';
};
#
done_testing;
