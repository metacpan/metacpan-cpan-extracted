use v5.40;
use Test2::V0;
use blib;
use Acme::Parataxis qw[async fiber yield];
use Acme::Parataxis::Signal;
my $sig = Acme::Parataxis::Signal->new;
my @done;
async {
    # send remembers the signal when nobody is waiting; wait consumes it.
    $sig->send;
    is $sig->count, 1, 'send remembers the signal when nobody is waiting';
    fiber {
        my $g = $sig->wait;
        note 'wait consumed the remembered signal';
    };
    is $sig->count,   F(), 'wait consumes a remembered signal without parking';
    is $sig->awaited, 0,   'no waiters after a remembered signal is consumed';

    # send wakes exactly one waiter.
    fiber {
        my $g = $sig->wait;
        push @done, 'a';
    };
    fiber {
        my $g = $sig->wait;
        push @done, 'b';
    };
    yield;    # both parked on wait
    $sig->send;
    yield;
    is scalar @done,  1, 'send wakes exactly one waiter';
    is $sig->awaited, 1, 'the other waiter is still parked';
    $sig->send;
    yield;
    is scalar @done,  2, 'a second send wakes the remaining waiter';
    is $sig->awaited, 0, 'nobody left waiting';

    # broadcast wakes all waiters (and never remembers).
    fiber {
        my $g = $sig->wait;
        push @done, 'c';
    };
    fiber {
        my $g = $sig->wait;
        push @done, 'd';
    };
    fiber {
        my $g = $sig->wait;
        push @done, 'e';
    };
    yield;    # all three parked
    $sig->broadcast;
    is $sig->count, F(), 'broadcast never remembers the signal';
    yield;
    is scalar @done,  5, 'broadcast woke every waiter';
    is $sig->awaited, 0, 'nobody left waiting after broadcast';

    # callback form: deferred, fired by send, fired immediately when pending.
    my $cb_ran = 0;
    $sig->wait( sub { $cb_ran++ } );        # no pending signal: just registers
    is $cb_ran,       0, 'wait($cb) with no pending signal defers the callback';
    is $sig->awaited, 1, 'a callback waiter counts as awaited';
    $sig->send;                             # fires the callback in the sending context
    is $cb_ran,       1, 'send invoked the registered callback';
    is $sig->awaited, 0, 'callback consumed by send';
    $sig->send;                             # remember again
    is $sig->count, 1, 'send remembered again';
    $sig->wait( sub { $cb_ran += 10 } );    # pending signal: fires before wait returns
    is $cb_ran,     11,  'wait($cb) with a pending signal fires immediately';
    is $sig->count, F(), 'pending signal consumed by wait($cb)';

    # stress: 20 workers x 50 waits ping-ponged with 1000 sends.
    my $total   = 0;
    my @workers = map {
        fiber { $sig->wait for 1 .. 50; $total++ }
    } 1 .. 20;
    fiber {
        $sig->send, yield for 1 .. 1000;
    };
    yield while $total < 20;
    is $total,        20, 'stress: 20 workers x 50 waits satisfied by 1000 sends';
    is $sig->awaited, 0,  'no waiters left after stress';
};
#
done_testing;
