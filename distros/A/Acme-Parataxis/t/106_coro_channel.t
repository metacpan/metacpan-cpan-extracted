use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield with_timeout];
use Acme::Parataxis::Channel;
use Acme::Parataxis::Semaphore;
use Test2::V1 -ipP;
$|++;
#
sub wait_for_drain { yield while Acme::Parataxis::get_live_fiber_count() > 1 }
subtest 'Single producer, single consumer (capacity 1, rendezvous)' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 1 );
    my @got;
    async {
        fiber { $q->put($_) for 1 .. 9 };    # producer
        push @got, $q->get for 1 .. 9;       # consumer
    };
    is join( q{,}, @got ), '1,2,3,4,5,6,7,8,9', 'items arrive in order';
    is $q->size,           0,                   'channel fully drained';
};
subtest 'Capacity limit blocks the producer' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 3 );
    my @got;
    my $producer_done = 0;
    async {
        my $p = fiber { $q->put($_) for 1 .. 10; $producer_done = 1 };
        is $producer_done, F(), 'producer blocked on a full channel before the consumer ran';
        push @got, $q->get for 1 .. 10;
    };
    ok $producer_done, 'producer finished once the consumer drained the channel';
    is join( q{,}, @got ), '1,2,3,4,5,6,7,8,9,10', 'all items delivered';
};
subtest 'Multiple producers, one consumer (like eg/prodcons)' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 4 );
    my @got;
    async {
        fiber { $q->put("p1-$_") for 1 .. 5 };
        fiber { $q->put("p2-$_") for 1 .. 5 };
        push @got, $q->get for 1 .. 10;
    };
    is scalar @got,             10,                                                  'consumer received everything';
    is join( q{,}, sort @got ), 'p1-1,p1-2,p1-3,p1-4,p1-5,p2-1,p2-2,p2-3,p2-4,p2-5', 'all messages present, none lost or duplicated';
};
subtest 'Shutdown wakes blocked consumers' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 2 );
    $q->put(1);
    my @got;
    async {
        fiber {
            while ( defined( my $x = $q->get ) ) {
                push @got, $x;
            }
        };
        $q->shutdown;
        yield for 1 .. 10;
        is join( q{,}, @got ), '1', 'buffered item consumed, then EOF signalled';
    };
};
subtest 'Prodcons stress (4 producers x 500, 4 consumers x 500, cap 2)' => sub {
    my $q = Acme::Parataxis::Channel->new( capacity => 2 );
    my @got;
    async {
        fiber { $q->put("$_") for 1 .. 500 };
        fiber { $q->put("$_") for 501 .. 1000 };
        fiber { $q->put("$_") for 1001 .. 1500 };
        fiber { $q->put("$_") for 1501 .. 2000 };
        fiber { push @got, $q->get for 1 .. 500 };
        fiber { push @got, $q->get for 1 .. 500 };
        fiber { push @got, $q->get for 1 .. 500 };
        fiber { push @got, $q->get for 1 .. 500 };
        wait_for_drain();
    };
    is scalar @got,                           2000,                    'all items consumed';
    is join( q{,}, sort { $a <=> $b } @got ), join( q{,}, 1 .. 2000 ), 'no items lost or duplicated';
};
subtest 'a channel get times out at the default bound' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 30 );
    my ( $err, $t0, $elapsed );
    async {
        $t0      = Time::HiRes::time();
        $err     = dies { $ch->get };
        $elapsed = ( Time::HiRes::time() - $t0 ) * 1000;
    };
    ok $err,                                         'get() threw instead of parking forever';
    ok $err->isa('Acme::Parataxis::Error::Timeout'), 'the error is Error::Timeout';
    ok $elapsed < 2000,                              "the timed-out get fired without hanging (elapsed=${\(int $elapsed)}ms)";
    wait_for_drain();
};
subtest 'a channel put times out at the default bound' => sub {
    my $ch = Acme::Parataxis::Channel->new( capacity => 1, timeout => 30 );
    $ch->put('full');
    my $err;
    async {
        $err = dies { $ch->put('nope') };
    };
    ok $err,                                         'put() threw on a channel that stayed full';
    ok $err->isa('Acme::Parataxis::Error::Timeout'), 'the error is Error::Timeout';
    wait_for_drain();
    is $ch->size, 1, 'the buffered item is untouched';
};
subtest 'with_timeout and cancellation still interrupt an unexpired channel wait' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 10000 );    # far beyond the test hull, so only the outer interrupt can fire
    my $err;
    async {
        $err = dies {
            with_timeout( 30, sub { $ch->get } );
        };
    };
    ok $err,                                         'an enclosing with_timeout fires before the channel bound';
    ok $err->isa('Acme::Parataxis::Error::Timeout'), 'as Error::Timeout';
    wait_for_drain();
    my $tok = Acme::Parataxis::CancellationToken->new;
    my $ch2 = Acme::Parataxis::Channel->new( timeout => 10000 );
    my $err2;
    async {
        $tok->register;
        fiber { yield; $tok->cancel };
        $err2 = dies { $ch2->get };
    };
    ok $err2,                                           'a cancellation token interrupts a channel wait too';
    ok $err2->isa('Acme::Parataxis::Error::Cancelled'), 'as Error::Cancelled';
    wait_for_drain();
};
subtest 'the value is delivered when the producer beats the bound' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 300 );
    my ( $got, $err );
    async {
        fiber { yield; $ch->put('ping') };
        $err = lives { $got = $ch->get };
    };
    ok $err, 'no timeout when the message arrives in time';
    is $got,      'ping', 'the value came through';
    is $ch->size, 0,      'channel drained';
    wait_for_drain();
};
subtest 'timeout => 0 disables the default bound' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 0 );
    my ( $got, $err );
    async {
        fiber { yield; $ch->put('unbounded') };
        $err = lives { $got = $ch->get };
    };
    ok $err, 'no timeout fired';
    is $got, 'unbounded', 'the value came through';
    wait_for_drain();
};
subtest 'try_get / try_put stay non-blocking regardless of the timeout' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 10 );
    async {
        my ( $ok, $v ) = $ch->try_get;
        is $ok, 0,     'try_get on an empty channel reports non-ready';
        is $v,  undef, 'and no value';
    };
    wait_for_drain();
    my $full = Acme::Parataxis::Channel->new( capacity => 1, timeout => 10 );
    $full->put(1);
    async {
        is $full->try_put('x'), 0, 'try_put on a full channel reports non-ready';
    };
    wait_for_drain();
};
subtest 'a wait that ends leaves no waiter behind and no stray sleep job' => sub {
    my $base = Acme::Parataxis::get_outstanding_jobs();

    # A timed-out wait: the channel's own timer fired, so nothing is left parked.
    my $ch = Acme::Parataxis::Channel->new( timeout => 20 );
    async {
        eval { $ch->get; 1 };
        yield;
    };
    wait_for_drain();
    is Acme::Parataxis::get_outstanding_jobs(), $base, 'the fired timer left no sleep job behind';

    # A wait that completes before the bound: teardown recalls the armed timer, so no job lingers either.
    my $ch2   = Acme::Parataxis::Channel->new( timeout => 30000 );
    my $base2 = Acme::Parataxis::get_outstanding_jobs();
    async {
        fiber { yield; $ch2->put('early') };
        is lives { $ch2->get }, 1, 'a get that beats the bound still works';
        yield;
    };
    wait_for_drain();
    is Acme::Parataxis::get_outstanding_jobs(), $base2, 'the recalled timer left no sleep job behind';
    $ch->put('after');
    async {
        is lives { $ch->get }, 1, 'a fresh get still works after the timed-out one';
    };
    wait_for_drain();
};
subtest 'a negative or undef timeout is rejected / means no bound' => sub {
    my $err = dies { Acme::Parataxis::Channel->new( timeout => -1 ) };
    ok $err, 'a negative timeout dies at construction';
    like "$err", qr/non-negative/, 'with the reason';
    my $ch = Acme::Parataxis::Channel->new( timeout => undef );
    is $ch->timeout, 0, 'timeout => undef normalizes to 0 (no bound)';
};
subtest 'a falsey value survives a parking get under a channel timeout' => sub {

    # The parked path runs the get body under an error guard. That guard used to treat the body's
    # *return value* as its own success flag, so a channel holding 0 or '' came back as a bare
    # "Died" instead of the value. Each case below parks (the channel starts empty) and is filled
    # by a writer while the reader waits, so the guard is genuinely on the hot path.
    my @cases = ( [ 0, 'zero' ], [ '', 'empty string' ], [ do { my $t = 0; \$t }, 'a ref to zero' ] );
    my @got;
    async {
        for my $case (@cases) {
            my ( $value, $label ) = @$case;
            my $ch     = Acme::Parataxis::Channel->new( timeout => 1000 );
            my $writer = fiber {
                yield;
                $ch->put($value);
            };
            my $got;
            my $err = dies { $got = $ch->get };
            push @got, [ $label, $err, $got ];
            $writer->await;
        }
    };
    wait_for_drain();
    for my $r (@got) {
        my ( $label, $err, $got ) = @$r;
        ok !$err, "a parked get on a channel holding $label does not die";
    }
    is $got[0][2], 0,            'a channel holding 0 comes back as 0';
    is $got[1][2], '',           'a channel holding the empty string comes back as the empty string';
    is $got[2][2], $cases[2][0], 'a channel holding a ref to zero comes back as that ref';
};
#
done_testing();
