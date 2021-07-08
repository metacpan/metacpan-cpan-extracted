package Tests::TermSignal;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;
use Time::HiRes 'sleep';

my $VERBOSE = $ENV{'HARNESS_IS_VERBOSE'};


sub test_01_term_signal : Test(21) {
    my $self = shift;

    ## Test that broker complete all requests before quitting when workers are stopped with TERM

    if ($self->automated_testing) {
        return "This test does not run reliably on constrained platforms";
    }

    my $cli = Beekeeper::Client->instance;
    my @req;

    my @worker_pids = $self->start_workers('Tests::Service::Worker', worker_count => 4);

    for (1..20) {

        for (1..8) {
            # Give them more work than they can do, to ensure that the task queue is full
            push @req, $cli->call_remote_async(
                method  => 'test.sleep',
                params  => .5,
                timeout => 30,
            );
        }

        # When workers are stopped they are probably processing a request that must be completed before quitting
        my $old = shift @worker_pids;
        $VERBOSE && diag "Stopping TERM worker $old";
        kill('TERM', $old);

        my ($new) = $self->start_workers('Tests::Service::Worker', worker_count => 1, no_wait => 1);
        push @worker_pids, $new;

        sleep 1;
        ok(1);
    }

    $VERBOSE && diag "Waiting for backlog";
    $cli->wait_async_calls;

    my @ok = grep { $_->success } @req;
    is( scalar(@ok), scalar(@req), "All calls executed " . scalar(@ok). "/". scalar(@req));
}

1;
