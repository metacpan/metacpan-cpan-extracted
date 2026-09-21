use v5.40;
use blib;
use Acme::Parataxis qw[async fiber yield];
use Acme::Parataxis::Semaphore;
use Test2::V1 -ipP;
$|++;
#
sub wait_for_drain { yield while Acme::Parataxis::get_live_fiber_count() > 1 }
subtest 'Counting semaphore (capacity 2, 15 fibers)' => sub {
    my $sem  = Acme::Parataxis::Semaphore->new( count => 2 );
    my $gate = Acme::Parataxis::Semaphore->new( count => 0 );
    my ( $conc, $max_conc ) = ( 0, 0 );
    async {
        for ( 1 .. 15 ) {
            fiber {
                my $guard = $sem->guard;    # parks on $sem once permits run out
                $conc++;
                $max_conc = $conc if $conc > $max_conc;
                $gate->down;                # hold the permit while parked on the gate
                $conc--;
            };
        }
        yield for 1 .. 5;         # let every fiber spawn and park
        is $max_conc,     2,  'at most 2 permits handed out at once (capacity respected)';
        is $sem->count,   0,  'both permits are held by parked fibers';
        is $sem->waiters, 13, '13 fibers blocked waiting for a permit';
        $gate->up for 1 .. 15;    # release everyone, cascading through $sem
        wait_for_drain;
    };
    is $conc,         0, 'all guards released';
    is $sem->count,   2, 'semaphore count restored to capacity';
    is $sem->waiters, 0, 'no fibers left blocked';
};
subtest 'Semaphore blocks until released (single fiber)' => sub {
    my $sem  = Acme::Parataxis::Semaphore->new( count => 0 );
    my $done = 0;
    async {
        my $t = fiber { $sem->down; $done++ };
        ok $done == 0, 'fiber parked: no permits yet';
        is $sem->waiters, 1, 'exactly one fiber blocked';
        $sem->up;    # release a permit
        yield;       # let the waiter run
        is $done, 1, 'fiber resumed once a permit was released';
    };
};
subtest 'try never blocks' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 1 );
    ok $sem->try,  'try succeeds while a permit is available';
    ok !$sem->try, 'try fails once no permit remains';
    is $sem->count, 0, 'count reflects the try';
};
subtest 'adjust wakes one waiter per permit' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 0 );
    my @done;
    async {
        fiber { $sem->down; push @done, 'a' };
        fiber { $sem->down; push @done, 'b' };
        fiber { $sem->down; push @done, 'c' };
        yield for 1 .. 3;
        is @done, 0, 'all three parked';
        $sem->adjust(2);    # two permits
        yield for 1 .. 5;
        is @done, 2, 'exactly two woken by adjust';
        $sem->up;
        yield for 1 .. 5;
        is join( q{}, sort @done ), 'abc', 'last waiter woken by up';
    };
};
subtest 'wait returns without consuming a permit' => sub {
    my $sem = Acme::Parataxis::Semaphore->new( count => 1 );
    my $result;
    async {
        fiber {
            $sem->wait;
            $result = "waited, count=${\$sem->count}";
            $sem->down;    # must now succeed without blocking
            $result .= ", then downed";
        };
        yield for 1 .. 3;
        is $result, 'waited, count=1, then downed', 'wait leaves the count untouched';
    };
};
#
done_testing();
