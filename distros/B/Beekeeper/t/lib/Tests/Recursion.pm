package Tests::Recursion;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;
use Time::HiRes 'sleep';


sub start_test_workers : Test(startup => 1) {
    my $self = shift;

    my $running = $self->start_workers('Tests::Service::Worker', workers_count => 3);
    is( $running, 3, "Spawned 4 workers");
};

sub test_01_recursion : Test(3) {

    my $cli = Beekeeper::Client->instance;
    my $resp;

    my @factorial = ( 1, 1, 2, 6, 24, 120, 720, 5040, 40320, 362880, 3628800 ); 

    # No recursion

    $resp = $cli->call_remote(
        method  => 'test.fact',
        params  => 2,
        timeout => 10,
    );

    is( $resp->result, 2, "factorial(2)");

    # 1 level of recursion

    $resp = $cli->call_remote(
        method  => 'test.fact',
        params  => 3,
        timeout => 10,
    );

    is( $resp->result, 6, "factorial(3)");

    # 2+ levels of recursion

    for (my $i = 4; $i <= 4; $i++) {

        $resp = $cli->call_remote(
            method  => 'test.fact',
            params  => $i,
            timeout => 10,
        );

        is( $resp->result, $factorial[$i], "factorial($i)");
    }
}

sub test_02_recursion : Test(4) {
    my $self = shift;

    my $cli = Beekeeper::Client->instance;
    my $resp;

    # No recursion

    $resp = $cli->call_remote(
        method  => 'test.fib1',
        params  => 1,
        timeout => 10,
    );

    is( $resp->result, 1, "fib(1)");

    $resp = $cli->call_remote(
        method  => 'test.fib2',
        params  => 1,
        timeout => 10,
    );

    is( $resp->result, 1, "fib(1)");

    # 1 level of recursion

    $resp = $cli->call_remote(
        method  => 'test.fib1',
        params  => 2,
        timeout => 10,
    );

    is( $resp->result, 1, "fib(2)");

    $resp = $cli->call_remote(
        method  => 'test.fib2',
        params  => 2,
        timeout => 10,
    );

    is( $resp->result, 1, "fib(2)");
}

sub test_03_recursion : Test(5) {
    my $self = shift;

    ## This test shows how effective is the broker doing load balance

    if ($self->automated_testing) {
        # It is hard to make this test run reliably on some smoke testers platforms
        return "This test may fail when not enough system resources are available";
    }

    my $running = $self->start_workers('Tests::Service::Worker', workers_count => 8);
    is( $running, 8, "Spawned 8 additional workers");

    my $cli = Beekeeper::Client->instance;

    my @fib = (0,1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144);

    #TODO: 11 workers should handle up to fib1(10) with proper load balance
    for (my $i = 3; $i <= 4; $i++) {

        my $resp = $cli->call_remote(
            method  => 'test.fib1',
            params  => $i,
            timeout => 10,
        );

        is( $resp->result, $fib[$i], "fib($i)");
    }

    #TODO: 11 workers should handle up to fib2(5) with proper load balance
    for (my $i = 3; $i <= 4; $i++) {

        my $resp = $cli->call_remote(
            method  => 'test.fib2',
            params  => $i,
            timeout => 10,
        );

        is( $resp->result, $fib[$i], "fib($i)");
    }
}

sub test_04_client_api : Test(7) {
    my $self = shift;

    use_ok('Tests::Service::Client');

    my $svc = 'Tests::Service::Client';
    my $resp;

    $resp = $svc->fibonacci_1( 2 );

    isa_ok($resp, 'Beekeeper::JSONRPC::Response');
    is( $resp->success, 1 );
    is( $resp->result, 1, "fib(2)");


    $resp = $svc->fibonacci_2( 2 );

    isa_ok($resp, 'Beekeeper::JSONRPC::Response');
    is( $resp->success, 1 );
    is( $resp->result, 1, "fib(2)");
}

1;
