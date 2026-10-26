use v5.40;
use blib;
use Time::HiRes     qw[time];
use Acme::Parataxis qw[run fiber yield with_timeout await_sleep];
use Acme::Parataxis::Channel;
use Acme::Parataxis::Ticker;
use Acme::Parataxis::RateLimiter;
use Test2::V1 -ipP;
$|++;

# deterministic mock time. run( virtual => 1, ... ) runs the whole scheduler on a virtual clock a test
# drives with Parataxis->advance, and the idle path fast-forwards the clock to the earliest pending deadline instead
# of sleeping, so hour-long timeouts exercise in microseconds. Real runs are untouched.
# A) an hour-long await_sleep returns without a real second passing (the idle fast-forward does the work)
run(
    virtual => 1,
    code    => sub {
        my $t0 = time;
        await_sleep(3_600_000);
        ok( ( time - $t0 ) * 1000 < 1000, '3_600_000ms await_sleep returns without a real second passing' );
        is Acme::Parataxis->virtual_now,        3_600_000, 'the virtual clock absorbed the whole sleep';
        is Acme::Parataxis->mock_time() * 1000, 3_600_000, 'mock_time reads the same virtual clock (seconds)';
    }
);

# B) a 1h with_timeout fires under advance while the block sleeps even longer
run(
    virtual => 1,
    code    => sub {
        my $err;
        my $f = fiber {
            $err = dies {
                with_timeout( 3_600_000, sub { await_sleep( 3_600_000 * 2 ); 'ok' } );
            };
        };
        yield;
        Acme::Parataxis->advance(3_600_000);
        $f->await;    # deterministic: wait until the deadline has fired the block and the block has set $err
        ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'a 1h with_timeout fires under advance (inner 2h sleep did not beat it)';
        is Acme::Parataxis->virtual_now, 3_600_000, 'advance returned the bound in ms';
    }
);

# C) Ticker ticks on the virtual boundary (values are virtual seconds, not wall-clock epoch)
run(
    virtual => 1,
    code    => sub {
        my @ticks;
        my $t = Acme::Parataxis::Ticker->new( interval => 1000 );
        my $c = fiber {
            push @ticks, $t->wait_next for 1 .. 3;
        };
        yield;    # let the consumer park on the empty channel before the first tick is produced
        Acme::Parataxis->advance(1000);
        yield;
        Acme::Parataxis->advance(1000);
        yield;
        Acme::Parataxis->advance(1000);
        $c->await;    # deterministic: tick 3 is already sitting in the channel
        $t->stop;     # stopping the ticker is what lets the run end (it re-arms forever otherwise)
        is scalar(@ticks), 3, 'three ticks collected';
        ok abs( $ticks[0] - 1.0 ) < 1e-6, 'tick 1 landed at virtual 1s';
        ok abs( $ticks[1] - 2.0 ) < 1e-6, 'tick 2 landed at virtual 2s';
        ok abs( $ticks[2] - 3.0 ) < 1e-6, 'tick 3 landed at virtual 3s';
    }
);

# D) RateLimiter refills on the virtual clock: burst 1 allows one acquire, the second parks until advance credits one
run(
    virtual => 1,
    code    => sub {
        my $acquired2 = 0;
        subtest 'RateLimiter refills on the virtual clock' => sub {
            my $rl = Acme::Parataxis::RateLimiter->new( rate => 1000, burst => 1 );    # one token per virtual ms
            ok $rl->acquire(1), 'first acquire spends the initial token';
            is $rl->tokens, 0, 'bucket empty';
            fiber { $rl->acquire(1); $acquired2 = 1 };
            yield;
            Acme::Parataxis->advance(1);
            my $guard = 0;
            yield while !$acquired2 && ++$guard < 50;
            ok $acquired2, 'second acquire released by one virtual-millisecond refill';
            $rl->stop;
        };
    }
);

# E) a select timeout fires on advance (its own deadline returns (undef, undef), like the pool path)
run(
    virtual => 1,
    code    => sub {
        my ( $sel_ch, $sel_val );
        my $done = 0;
        subtest 'select timeout fires on advance' => sub {
            my $ch = Acme::Parataxis::Channel->new( capacity => 1 );
            fiber {
                ( $sel_ch, $sel_val ) = $ch->select( [ $ch, 'get' ], timeout => 3_600_000 );
                $done = 1;
            };
            yield;
            Acme::Parataxis->advance(3_600_000);
            my $guard = 0;
            yield while !$done && ++$guard < 50;
            ok $done,                                 'select resumed after the deadline';
            ok !defined $sel_ch && !defined $sel_val, 'select reported (undef, undef) on its own virtual timeout';
            is $ch->select_waiters, 0, 'no select waiter left behind';
        };
    }
);

# F) a Channel->new( timeout => $ms ) bound fires under advance too
run(
    virtual => 1,
    code    => sub {
        my ( $got_err, $done ) = ( undef, 0 );
        subtest 'Channel get bound fires on advance' => sub {
            my $ch = Acme::Parataxis::Channel->new( capacity => 1, timeout => 50 );
            fiber {
                $got_err = dies { $ch->get };
                $done    = 1;
            };
            yield;
            Acme::Parataxis->advance(50);    # get has been empty for its whole 50ms bound
            my $guard = 0;
            yield while !$done && ++$guard < 50;
            ok $done,                                                             'get resumed after the bound';
            ok ref($got_err) && $got_err->isa('Acme::Parataxis::Error::Timeout'), 'a 50ms channel bound fired on advance';
        };
    }
);

# G) earliest virtual deadline fires first, and an hour apart the auto fast-forward walks both
run(
    virtual => 1,
    code    => sub {
        my @order;
        subtest 'earliest virtual deadline fires first' => sub {
            my $a = fiber { await_sleep(100); push @order, 'a' };
            my $b = fiber { await_sleep(500); push @order, 'b' };
            $a->await;
            $b->await;
            is join( ',', @order ),          'a,b', '100ms deadline fired before the 500ms one';
            is Acme::Parataxis->virtual_now, 500,   'the clock only moved as far as the last deadline';
        };
    }
);

# H) a fiber that does real work still runs; only the clock is virtual (and it never moves while work is runnable)
run(
    virtual => 1,
    code    => sub {
        my @order;
        subtest 'real work still runs, only the clock is virtual' => sub {
            my $worker = fiber {
                for my $i ( 1 .. 3 ) { push @order, $i; yield }
                await_sleep(3_600_000);
                push @order, 'slept';
            };
            $worker->await;
            is join( ',', @order ), '1,2,3,slept', 'the busy fiber finished its real passes before the sleep fired';
            ok Acme::Parataxis->virtual_now > 0, 'the clock only advanced once the scheduler went idle';
        };
    }
);

# I) a normal run is untouched, and no virtual state leaks between runs
run(
    sub {
        subtest 'normal run is untouched' => sub {
            my $t0 = time;
            await_sleep(30);
            ok( ( time - $t0 ) * 1000 >= 10, 'a plain run still sleeps on the wall clock' );
        };
    }
);
ok !defined Acme::Parataxis->virtual_now, 'no virtual clock leaks out of a plain run';
my $again = run( virtual => 1, code => sub { await_sleep(10); return 'tick' } );
is $again, 'tick', 'another virtual run works after a plain one';
ok !defined Acme::Parataxis->virtual_now, 'virtual clock restored to off after a virtual run';
my $err = dies { Acme::Parataxis->advance(1) };
ok $err && $err =~ /virtual/, 'advance() outside a virtual run croaks about the mode';
done_testing;
