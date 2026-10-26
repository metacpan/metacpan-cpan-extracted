use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield run await_sleep];
use Acme::Parataxis::Channel;
use Test2::V1 -ipP;
$|++;
#
sub wait_for_drain { yield while Acme::Parataxis::get_live_fiber_count() > 1 }
subtest 'get-ready vs put-ready: a ready case commits immediately' => sub {
    async {
        # A) get-ready wins: metrics has an item, jobs is full (so put is NOT ready)
        my $metrics = Acme::Parataxis::Channel->new;
        my $jobs    = Acme::Parataxis::Channel->new( capacity => 1 );
        $metrics->put('m1');
        $jobs->put('busy');    # fills capacity, so a put case is NOT ready
        my ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $metrics => 'get' ], [ $jobs => 'put', 'j1' ], );
        is $chosen,        $metrics, 'get-ready case won';
        is $val,           'm1',     'value delivered';
        is $metrics->size, 0,        'get case drained the item';
        is $jobs->size,    1,        'put case untouched';

        # B) put-ready wins: get side empty (get NOT ready), put side has room
        my $emptychan = Acme::Parataxis::Channel->new;
        my $roomy     = Acme::Parataxis::Channel->new( capacity => 2 );    # nothing buffered, room for a put
        my ( $c2, $v2 ) = Acme::Parataxis::Channel->select( [ $emptychan => 'get' ], [ $roomy => 'put', 'jum' ], );
        is $c2,                    $roomy, 'put-ready case won';
        is $v2,                    'jum',  'put value accepted';
        is $roomy->size,           1,      'put case buffered the item';
        is $roomy->select_waiters, 0,      'put selector left no waiter behind';

        # C) both ready: either may win (shuffle breaks ordering), but it must commit one of them, no deadlock
        my $both_a = Acme::Parataxis::Channel->new;
        my $both_b = Acme::Parataxis::Channel->new( capacity => 2 );
        $both_a->put('x');
        my ( $c3, $v3 ) = Acme::Parataxis::Channel->select( [ $both_a => 'get' ], [ $both_b => 'put', 'y' ], );
        ok $c3 == $both_a || $c3 == $both_b, 'a both-ready select commits';
        is $c3->select_waiters, 0, 'no waiter left by a both-ready commit';
    };
};
subtest 'random choice prevents starvation under repeated contention' => sub {

    # Always both-ready: channel A holds a value (get-ready), channel B has room (put-ready, capacity large
    # enough that 60 puts never fill it so the put case stays ready round after round).
    my $a = Acme::Parataxis::Channel->new;
    my $b = Acme::Parataxis::Channel->new( capacity => 1000 );
    my ( $get_wins, $put_wins ) = ( 0, 0 );
    async {
        for ( 1 .. 60 ) {
            $a->put($_);
            my ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $a => 'get' ], [ $b => 'put', "p$_" ], );
            $get_wins++ if $chosen == $a;
            $put_wins++ if $chosen == $b;
            yield;
        }
    };
    ok $get_wins > 0, 'get case chosen at least once';
    ok $put_wins > 0, 'put case chosen at least once';
    is $get_wins + $put_wins, 60, 'every round committed';
    wait_for_drain();
};
subtest 'waiting get: woken by a producer put' => sub {
    my $ch = Acme::Parataxis::Channel->new;
    my ( $chosen, $val, $t0, $elapsed ) = ( undef, undef, undef, undef );
    async {
        fiber { yield; $ch->put('late') };    # producer: yield first so the selector registers, then deliver
        $t0 = Time::HiRes::time();
        ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], timeout => 500, );
        $elapsed = ( Time::HiRes::time() - $t0 ) * 1000;
    };
    is $chosen, $ch,    'select woke on the put';
    is $val,    'late', 'got the produced value';
    ok $elapsed < 400, "returned before the 500ms deadline (elapsed=${\(int $elapsed)}ms)";
};
subtest 'waiting put: woken by a consumer get' => sub {
    my $ch = Acme::Parataxis::Channel->new( capacity => 1 );
    $ch->put('full');
    my $took;
    async {
        fiber {
            yield;    # give select() a chance to register for put first
            $took = $ch->get;
        };
        my ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'put', 'p' ], timeout => 500, );
        is $chosen, $ch, 'put case woke on the get';
        is $val,    'p', 'put value delivered';
    };
    wait_for_drain();
    is $took, 'full', 'consumer drained the original item';
};
subtest 'timeout returns (undef, undef)' => sub {
    async {
        my $ch = Acme::Parataxis::Channel->new;
        my ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], timeout => 30, );
        is $chosen,             undef, 'no channel chosen on timeout';
        is $val,                undef, 'no value on timeout';
        is $ch->select_waiters, 0,     'no select waiter leaked after timeout';
    };
};
subtest 'default runs only when nothing is ready (and never parks)' => sub {
    async {
        my $empty = Acme::Parataxis::Channel->new;
        my ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $empty => 'get' ], default => sub {'fallback'}, );
        is $chosen,                undef,      'default path: channel undef';
        is $val,                   'fallback', 'default value returned';
        is $empty->select_waiters, 0,          'no select waiter leaked via default';
        my $full = Acme::Parataxis::Channel->new( capacity => 1 );
        $full->put('x');
        my ( $c2, $v2 ) = Acme::Parataxis::Channel->select( [ $full => 'get' ], default => sub {'fallback'}, );
        is $c2, $full, 'ready case wins over default';
        is $v2, 'x',   'ready value returned';
    };
};
subtest 'shutdown unblocks selectors with remaining items' => sub {
    my $ch = Acme::Parataxis::Channel->new;
    $ch->put($_) for 1 .. 3;
    $ch->shutdown;
    my @got;
    async {
        while (1) {
            my ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], );
            last if !defined $chosen;    # unreachable: shutdown always yields a get (value or undef)
            push @got, $val;
            last if $val == 3;
        }
    };
    wait_for_drain();
    is join( q{,}, @got ),  '1,2,3', 'all buffered items drained after shutdown';
    is $ch->select_waiters, 0,       'no select waiter leaked after shutdown';
};
subtest 'waiter lists are empty after every return' => sub {
    my $ch = Acme::Parataxis::Channel->new;
    async {
        my ( $a, $b ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], timeout => 5, );
        is $a,                  undef, 'timeout channel is undef';
        is $b,                  undef, 'timeout value is undef';
        is $ch->select_waiters, 0,     'waiter registration fully removed';
        $ch->put('x');
        my ( $c, $v ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ] );
        is $c,                  $ch, 'ready get committed';
        is $v,                  'x', 'value delivered';
        is $ch->select_waiters, 0,   'no leftover registration after commit';
    };
    wait_for_drain();
};
subtest 'deadlock detects an idle no-option select' => sub {
    my $ch = Acme::Parataxis::Channel->new;
    my $err;
    my $code = sub { Acme::Parataxis::Channel->select( [ $ch => 'get' ] ) };
    $err = dies { run($code) };
    like "$err", qr/deadlock/i, 'all-idle select with no timeout/default deadlock-detects';
};
subtest 'two selectors on one channel both get serviced' => sub {
    my $ch = Acme::Parataxis::Channel->new;
    my ( @got, $done ) = ( 0, 0 );
    async {
        fiber {
            $got[0] = ( Acme::Parataxis::Channel->select( [ $ch => 'get' ] ) )[1];
            $done++;
        };
        fiber {
            $got[1] = ( Acme::Parataxis::Channel->select( [ $ch => 'get' ] ) )[1];
            $done++;
        };
        $ch->put('a');
        $ch->put('b');
        yield, yield;
    };
    wait_for_drain();
    is $done,                   2,     'both selectors resolved';
    is join( q{,}, sort @got ), 'a,b', 'both values delivered, none lost';
    is $ch->select_waiters,     0,     'no leaked waiters on a serviced channel';
};
subtest 'an armed timeout is recalled when a case commits first (no stray sleep job)' => sub {
    my $ch        = Acme::Parataxis::Channel->new;
    my $base_jobs = Acme::Parataxis::get_outstanding_jobs();
    async {
        my $reader = fiber {
            my ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], timeout => 30000, );
            is $chosen, $ch,    'select committed the message';
            is $val,    'ping', 'message delivered';
        };
        $ch->put('ping');
        $reader->await;
    };
    my $guard = 0;
    yield while Acme::Parataxis::get_live_fiber_count() > 1 && ++$guard < 1000;
    is Acme::Parataxis::get_live_fiber_count(), 1,          'the armed timer helper was recalled, not left asleep for the full 30s';
    is Acme::Parataxis::get_outstanding_jobs(), $base_jobs, 'no outstanding sleep job remains after the early commit';
    is $ch->select_waiters,                     0,          'no select waiter leaked';
};
subtest 'argument validation' => sub {
    my $ch = Acme::Parataxis::Channel->new;
    like dies { Acme::Parataxis::Channel->select( [ $ch => 'bogus' ] ) }, qr/op must be "get" or "put"/,                   'bad op croaks';
    like dies { Acme::Parataxis::Channel->select( [ undef => 'get' ] ) }, qr/channel must be an Acme::Parataxis::Channel/, 'bad channel croaks';
    like dies { Acme::Parataxis::Channel->select( [ $ch => 'put' ] ) },   qr/requires a value/,                            'put without value croaks';
    like dies { Acme::Parataxis::Channel->select( [ $ch => 'get' ], timeout => -1 ) },     qr/non-negative/,               'negative timeout croaks';
    like dies { Acme::Parataxis::Channel->select( [ $ch => 'get' ], default => 'nope' ) }, qr/default must be a CODE/,     'non-code default croaks';
    like dies { Acme::Parataxis::Channel->select() },                                      qr/at least one case/,          'no cases croaks';
};
subtest 'select honors a channel default when no option is given' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 30 );
    my ( $chosen, $val, $t0, $elapsed );
    async {
        $t0 = Time::HiRes::time();
        ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], );
        $elapsed = ( Time::HiRes::time() - $t0 ) * 1000;
    };
    is $chosen, undef, 'no channel chosen when the channel default fired';
    is $val,    undef, 'no value';
    ok $elapsed < 200, "fired around the channel's 30ms bound (elapsed=${\(int $elapsed)}ms)";
    is $ch->select_waiters, 0, 'no select waiter leaked after the default fired';
    wait_for_drain();
};
subtest 'an explicit select timeout wins over the channel default' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 30000 );
    my ( $chosen, $val, $t0, $elapsed );
    async {
        $t0 = Time::HiRes::time();
        ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], timeout => 20, );
        $elapsed = ( Time::HiRes::time() - $t0 ) * 1000;
    };
    is $chosen, undef, 'the option deadline dominated the channel default';
    ok $elapsed < 200, "fired at the 20ms option bound (elapsed=${\(int $elapsed)}ms)";
    is $ch->select_waiters, 0, 'no select waiter leaked';
    wait_for_drain();

    # The reverse holds too: a long explicit option dominates a short channel default.
    # The channel's 50ms default would otherwise fire select empty around 50ms; the 30000ms
    # option must instead hold until the producer lands at ~150ms and deliver the value.
    my $ch2 = Acme::Parataxis::Channel->new( timeout => 50 );
    my ( $a, $b, $t1, $el2 );
    async {
        fiber { yield; await_sleep(150); $ch2->put('value') };
        $t1 = Time::HiRes::time();
        ( $a, $b ) = Acme::Parataxis::Channel->select( [ $ch2 => 'get' ], timeout => 30000, );
        $el2 = ( Time::HiRes::time() - $t1 ) * 1000;
    };
    wait_for_drain();
    ok $a == $ch2, 'the explicit option held past the channel default and took the value';
    is $b, 'value', 'delivered, not timed out empty at 50ms';
    ok $el2 >= 100, "select waited out the channel default (elapsed=${\(int $el2)}ms)";
    is $ch2->select_waiters, 0, 'and cleaned up after itself';
};
subtest 'when cases disagree, the earliest channel default wins' => sub {
    my $fast = Acme::Parataxis::Channel->new( timeout => 40 );
    my $slow = Acme::Parataxis::Channel->new( timeout => 4000 );
    my ( $chosen, $val, $t0, $elapsed );
    async {
        $t0 = Time::HiRes::time();
        ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $fast => 'get' ], [ $slow => 'get' ], );
        $elapsed = ( Time::HiRes::time() - $t0 ) * 1000;
    };
    is $chosen, undef, 'the earliest default (40ms) fired the select';
    is $val,    undef, 'no value';
    ok $elapsed < 250, "fired near the shortest bound (elapsed=${\(int $elapsed)}ms)";
    is $fast->select_waiters, 0, 'fast case cleaned up';
    is $slow->select_waiters, 0, 'slow case cleaned up';
    wait_for_drain();
};
subtest 'a confirming case beats a channel default (no spurious timeout)' => sub {
    my $ch = Acme::Parataxis::Channel->new( timeout => 5000 );
    my ( $chosen, $val );
    async {
        fiber { yield; $ch->put('late') };    # arrives well within the bound
        ( $chosen, $val ) = Acme::Parataxis::Channel->select( [ $ch => 'get' ], );
    };
    wait_for_drain();
    is $chosen,             $ch,    'the default deadline did not preempt a real message';
    is $val,                'late', 'the produced value arrived';
    is $ch->select_waiters, 0,      'no select waiter leaked';
};
#
done_testing();
