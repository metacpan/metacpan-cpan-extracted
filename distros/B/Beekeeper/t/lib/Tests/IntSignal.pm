package Tests::IntSignal;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;
use Time::HiRes 'sleep';

use constant DEBUG => 0;


sub test_01_int_signal : Test(21) {
    my $self = shift;

    ## Test that broker resend requests when workers are killed with INT

    if ($self->automated_testing) {
        # It is hard to make this test run reliably on smoke testers platforms
        return "This test may fail when not enough system resources are available";
    }

    my $cli = Beekeeper::Client->instance;
    my @req;

    my @worker_pids = $self->start_workers('Tests::Service::Worker', workers_count => 4);

    for (1..20) {

        for (1..8) {
            # Give them more work than they can do, to ensure that the task queue is full
            push @req, $cli->call_remote_async(
                method  => 'test.sleep',
                params  => .5,
                timeout => 30,
            );
        }

        # When workers are killed they are probably processing a request that must be resent by the broker
        my $old = shift @worker_pids;
        DEBUG && diag "Killing INT worker $old";
        kill('INT', $old);

        my ($new) = $self->start_workers('Tests::Service::Worker', workers_count => 1, no_wait => 1);
        push @worker_pids, $new;

        sleep 1;
        ok(1);
    }

    DEBUG && diag "Waiting for backlog";
    $cli->wait_async_calls;

    my @ok = grep { $_->success } @req;
    is( scalar(@ok), scalar(@req), "All calls executed " . scalar(@ok). "/". scalar(@req));
}

1;
