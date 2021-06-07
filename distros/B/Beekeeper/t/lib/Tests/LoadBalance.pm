package Tests::LoadBalance;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;
use Time::HiRes 'sleep';

use constant DEBUG => 0;


sub start_test_workers : Test(startup => 1) {
    my $self = shift;

    if ($self->automated_testing) {
        # On smoke testers there is no broker to test for load balance quality
        $self->stop_all_workers;
        $self->SKIP_ALL("Load balance tests are not deterministic");
    }

    my $running = $self->start_workers('Tests::Service::Cache', workers_count => 5);
    is( $running, 5, "Spawned 5 workers");
};

sub test_01_load_balance_async : Test(6) {
    my $self = shift;

    my $cli = Beekeeper::Client->instance;
    my $resp;

    my $tasks = 500;
    my $workers = 5;
    my $expected = int($tasks / $workers);
    my @jobs;

    for (1..$tasks) {
        push @jobs, $cli->call_remote_async(
            method  => 'cache.bal',
            params  => { dset =>'A' },
        );
    }

    $cli->wait_async_calls;

    $resp = $cli->call_remote(
        method  => 'cache.run',
        params  => { dset =>'A' },
    );

    my $runs = $resp->result;
    my $total = 0;

    foreach my $pid (sort keys %$runs) {
        my $got = $runs->{$pid};
        my $offs = $got - $expected;
        my $dev = abs( $offs / $expected * 100 );
        $total += $got;

        DEBUG && diag "$pid: $got  $offs  $dev %";

        cmp_ok($dev,'<', 60, "expected average $expected async runs, got $got");
    }

    is($total, $tasks, "expected total $tasks async runs, got $total");
}

sub test_02_load_balance_background : Test(6) {
    my $self = shift;

    my $cli = Beekeeper::Client->instance;
    my $resp;

    my $tasks = 500;
    my $workers = 5;
    my $expected = int($tasks / $workers);

    for (1..$tasks) {
        $cli->fire_remote(
            method  => 'cache.bal',
            params  => { dset =>'B' },
        );
    }

    $self->_sleep( 1 );

    $resp = $cli->call_remote(
        method  => 'cache.run',
        params  => { dset => 'B' },
    );

    my $runs = $resp->result;
    my $total = 0;

    foreach my $pid (sort keys %$runs) {
        my $got = $runs->{$pid};
        my $offs = $got - $expected;
        my $dev = abs( $offs / $expected * 100 );
        $total += $got;

        DEBUG && diag "$pid: $got  $offs  $dev %";

        cmp_ok($dev,'<', 60, "expected average $expected background runs, got $got");
    }

    is( $total, $tasks, "expected total $tasks background runs, got $total");
}

sub test_03_slow_consumer_async : Test(7) {
    my $self = shift;

    my $cli = Beekeeper::Client->instance;
    my $resp;

    my $tasks = 500;
    my $workers = 5;
    my $slow = 2;

    my $expected_fast = int(($tasks - $slow) / ($workers - $slow));
    my $expected_slow = $slow;

    my @jobs;

    # Send a few jobs that take a lot to complete. The workers that
    # process these slower jobs should get less requests than the others

    for (1..$slow) {
        push @jobs, $cli->call_remote_async(
            method  => 'cache.bal',
            params  => { dset => 'C', sleep => 3 },
        );
    }

    for (my $i = $slow; $i < $tasks; $i++) {

        push @jobs, $cli->call_remote_async(
            method  => 'cache.bal',
            params  => { dset => 'C' },
        );
    }

    $cli->wait_async_calls;

    $resp = $cli->call_remote(
        method  => 'cache.run',
        params  => { dset => 'C' },
    );

    my $runs = $resp->result;

    my %slowed_workers;
    my $slowed_workers_count = 0;

    foreach my $pid (sort keys %$runs) {
        my $got = $runs->{$pid};
        next unless ($got < $expected_fast * 0.20);
        $slowed_workers{$pid} = 1;
        $slowed_workers_count++;
    }

    TODO: {
        local $TODO = "ToyBroker does simple round robin, ignoring backlog";
        is($slowed_workers_count, $expected_slow, "expected $expected_slow slowed workers, got $slowed_workers_count");
    }

    my $total = 0;

    foreach my $pid (sort keys %$runs) {

        my $got = $runs->{$pid};

        if ($slowed_workers{$pid}) {

            cmp_ok($got,'<', $expected_fast * 0.20, "expected average 1 slow runs, got $got");
        }
        else {
            my $offs = $got - $expected_fast;
            my $dev = abs( $offs / $expected_fast * 100 );

            DEBUG && diag "$pid: $got  $offs  $dev %";

            cmp_ok($dev,'<', 60, "expected average $expected_fast fast runs, got $got");
        }

        $total += $got;        
    }

    is($total, $tasks, "expected total $tasks async runs, got $total");
}

1;
