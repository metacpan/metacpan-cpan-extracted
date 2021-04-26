package Tests::LoadBalancing;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;
use Time::HiRes 'sleep';


sub start_test_workers : Test(startup => 1) {
    my $self = shift;

    my $running = $self->start_workers('Tests::Service::Cache', workers_count => 5);
    is( $running, 5, "Spawned 5 workers");
};

sub test_01_load_balancing_async : Test(6) {
    my $self = shift;

    if ($ENV{'AUTOMATED_TESTING'} || $ENV{'PERL_BATCH'}) {
        # Broker may fail to load balance evenly when running low of CPU resources
        return "Load balancing tests are not deterministic";
    }

    my $cli = Beekeeper::Client->instance;
    my $resp;

    my $tasks = 500;
    my $workers = 5;
    my $expected = int($tasks / $workers);
    my @jobs;

    for (1..$tasks) {
        push @jobs, $cli->do_async_job(
            method  => 'cache.bal',
            params  => { dset =>'A' },
        );
    }

    $cli->wait_all_jobs;

    $resp = $cli->do_job(
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

        # diag "$pid: $got  $offs  $dev %";

        cmp_ok($dev,'<', 60, "expected $expected async runs, got $got");
    }

    is($total, $tasks, "expected total $tasks async runs, got $total");
}

sub test_02_load_balancing_background : Test(6) {
    my $self = shift;

    if ($ENV{'AUTOMATED_TESTING'} || $ENV{'PERL_BATCH'}) {
        # Broker may fail to load balance evenly when running low of CPU resources
        return "Load balancing tests are not deterministic";
    }

    my $cli = Beekeeper::Client->instance;
    my $resp;

    my $tasks = 500;
    my $workers = 5;
    my $expected = int($tasks / $workers);

    for (1..$tasks) {
        $cli->do_background_job(
            method  => 'cache.bal',
            params  => { dset =>'B' },
        );
    }

    sleep 1.5;

    $resp = $cli->do_job(
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

        # diag "$pid: $got  $offs  $dev %";

        cmp_ok($dev,'<', 60, "expected $expected background runs, got $got");
    }

    is( $total, $tasks, "expected total $tasks background runs, got $total");
}

sub test_03_slow_consumer_async : Test(6) {
    my $self = shift;

    if ($ENV{'AUTOMATED_TESTING'} || $ENV{'PERL_BATCH'}) {
        # Broker may fail to load balance evenly when running low of CPU resources
        return "Load balancing tests are not deterministic";
    }

    my $cli = Beekeeper::Client->instance;
    my $resp;

    my $tasks = 500;
    my $workers = 5;
    my $slow = 2;

    my $expected_fast = int(($tasks - $slow) / ($workers - $slow));
    my $expected_slow = 1;

    my @jobs;

    for (1..$slow) {
        push @jobs, $cli->do_async_job(
            method  => 'cache.bal',
            params  => { dset => 'C', sleep => 1.5 },
        );
    }

    for (my $i = $slow; $i < $tasks; $i++) {

        push @jobs, $cli->do_async_job(
            method  => 'cache.bal',
            params  => { dset => 'C' },
        );
    }

    $cli->wait_all_jobs;

    $resp = $cli->do_job(
        method  => 'cache.run',
        params  => { dset => 'C' },
    );

    my $runs = $resp->result;
    my $total = 0;

    foreach my $pid (sort keys %$runs) {
        my $got = $runs->{$pid};
        next unless ($got < $expected_fast / 10);
        delete $runs->{$pid};
        $total += $got;

        is($got, $expected_slow, "expected $expected_slow slow runs, got $got");
    }

    foreach my $pid (sort keys %$runs) {
        my $got = $runs->{$pid};
        my $offs = $got - $expected_fast;
        my $dev = abs( $offs / $expected_fast * 100 );
        $total += $got;

        # diag "$pid: $got  $offs  $dev %";

        cmp_ok($dev,'<', 60, "expected $expected_fast runs, got $got");
    }

    is($total, $tasks, "expected total $tasks async runs, got $total");
}


1;
