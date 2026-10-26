use v5.40;
use blib;
use Acme::Parataxis qw[async fiber await_sleep with_timeout];
use Acme::Parataxis::Sync::WaitGroup;
use Test2::V1 -ipP;
$|++;
subtest 'wait blocks until the counter drains' => sub {
    my $wg = Acme::Parataxis::Sync::WaitGroup->new;
    async {
        $wg->add(3);
        my @fs = map {
            fiber {
                await_sleep(3);
                $wg->done;
            }
        } 1 .. 3;
        $wg->wait;
        is $wg->remaining, 0, 'wait returned only once every done() landed';
        $_->await for @fs;
    };
};
subtest 'wait returns immediately when the counter is already zero' => sub {
    my $wg = Acme::Parataxis::Sync::WaitGroup->new;
    async {
        $wg->wait;
        pass 'wait on a zero counter does not park';
    };
};
subtest 'a group shared across pool-spawned async jobs' => sub {
    my $wg  = Acme::Parataxis::Sync::WaitGroup->new;
    my $in  = 0;
    my $log = '';
    async {
        $wg->add(2);    # one unit per pool job
        my @jobs = map {
            my $i = $_;
            fiber {     # a pool job
                $in++;
                await_sleep( ( $i % 2 ) ? 2 : 6 );
                $log .= $i;
                $wg->done;
            }
        } 1 .. 2;
        my $waiter = fiber { $wg->wait };
        $waiter->await;
        is $in, 2, 'every job started before the wait lifted';
        $_->await for @jobs;
        is join( '', sort split //, $log ), '12', 'both jobs finished';
    };
};
subtest 'the counter can be topped up before waiting again' => sub {
    my $wg = Acme::Parataxis::Sync::WaitGroup->new;
    async {
        $wg->add(2);
        fiber { $wg->done }->await;
        fiber { $wg->done }->await;
        $wg->add(1);
        is $wg->remaining, 1, 'a fresh add() is counted';
        $wg->done;
        $wg->wait;
        pass 'wait lifted after the top-up drained too';
    };
};
subtest 'abuse: over-done and non-integer adds croak' => sub {
    my $wg = Acme::Parataxis::Sync::WaitGroup->new;
    async {
        like dies { $wg->done }, qr/negative/, 'done() with nothing outstanding croaks';
        $wg->add(1);
        like dies { $wg->add('two') }, qr/integer/, 'a non-integer add croaks';
        like dies { $wg->add(1.5) },   qr/integer/, 'a fractional add croaks';
    };
};
subtest 'an interrupted wait() unregisters and later waits still work' => sub {
    my $wg = Acme::Parataxis::Sync::WaitGroup->new;
    my $err;
    async {
        $wg->add(1);    # a unit that will never be done within the timeout
        $err = dies {
            with_timeout( 10, sub { $wg->wait } );
        };
        is $wg->waiters, 0, 'the timed-out waiter removed itself';
        $wg->done;      # drain the stuck unit; nothing stale to wake
        my $f = fiber { $wg->wait };
        is $f->await, 1, 'a fresh wait lifts normally after the group drained';
    };
    ok ref($err) && $err->isa('Acme::Parataxis::Error::Timeout'), 'the stuck wait timed out';
};
subtest 'waits must occur inside a scheduled fiber' => sub {
    my $wg = Acme::Parataxis::Sync::WaitGroup->new;
    like dies { $wg->wait }, qr/scheduled fiber/, 'wait() croaks outside the scheduler';
};
#
done_testing;
