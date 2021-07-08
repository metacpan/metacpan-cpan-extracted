package Tests::Basic;

use strict;
use warnings;

use base 'Tests::Service::Base';

use Test::More;
use Time::HiRes 'sleep';


sub start_test_workers : Test(startup => 1) {
    my $self = shift;

    my $running = $self->start_workers('Tests::Service::Worker');
    is( $running, 2, "Spawned 2 workers");
};

sub test_01_notifications : Test(2) {
    my $self = shift;

    my $cli = Beekeeper::Client->instance;
    my $var = 74;

    $SIG{'USR1'} = sub { $var++ };

    $cli->send_notification(
        method => "test.signal",
        params => { signal => 'USR1', pid => $$ },
    );

    my $expected = 76;
    my $max_wait = 10; while ($max_wait--) { sleep 0.5; last if $var == $expected }
    is( $var, $expected, "Notifications received by 2 workers");

    $var = 58;

    $cli->send_notification(
        method => "test.try_catchall",
        params => { signal => 'USR1', pid => $$ },
    );

    $expected = 60;
    $max_wait = 10; while ($max_wait--) { sleep 0.5; last if $var == $expected }
    is( $var, $expected, "Catchall notifications received by 2 workers");
}

sub test_02_sync_calls : Test(20) {
    my $self = shift;
    
    my $cli = Beekeeper::Client->instance;

    my $resp = $cli->call_remote(
        method => 'test.echo',
        params => "foo",
    );

    isa_ok($resp, 'Beekeeper::JSONRPC::Response');
    is( $resp->success, 1 );
    is( $resp->result, 'foo');

    $resp = $cli->call_remote(
        method => 'test.echo',
        params => [ 1, { a => 2 }, "" ],
    );

    is( $resp->success, 1 );
    is_deeply( $resp->result, [ 1, { a => 2 }, "" ]);

    # Unhandled exception with no raise_error
    $resp = $cli->call_remote(
        method => 'test.fail',
        params => { 'die' => "error message 123" },
        raise_error => 0,
    );

    isa_ok($resp, 'Beekeeper::JSONRPC::Error');
    is( $resp->success, 0 );
    is( $resp->code, -32000);
    is( $resp->message, "Server error"); # hidden error
    is( $resp->data, undef);

    # Unhandled exception dies
    $resp = eval {
        $cli->call_remote(
            method => 'test.fail',
            params => { 'die' => "error message 456" },
        );
    };

    is( $resp, undef );
    like( $@, qr/Call to 'test.fail' failed: -32000 Server error at /); # hidden error

    # Handled exception
    $resp = eval {
        $cli->call_remote(
            method => 'test.fail',
            params => { 'error' => "error message 678" },
        );
    };

    is( $resp, undef );
    like( $@, qr/Call to 'test.fail' failed: -32000 error message 678 at /); # explicit error

    # Invalid method
    $resp = eval {
        $cli->call_remote(
            method  => 'test.#',
        );
    };

    is( $resp, undef );
    like( $@, qr/Invalid method 'test.#' at /); # local error, the remote call was not made

    # Invalid method
    $resp = eval {
        $cli->call_remote(
            method  => 'test.notfound',
        );
    };

    is( $resp, undef );
    like( $@, qr/Call to 'test.notfound' failed: -32601 Method not found at /);

    # Timeout
    $resp = eval {
        $cli->call_remote(
            method  => 'test.sleep',
            params  => '0.1',
            timeout => '0.01',
        );
    };

    is( $resp, undef );
    like( $@, qr/Call to 'test.sleep' failed: -31600 Request timeout at /);
}

sub test_03_fire_and_forget_calls : Test(1) {
    my $self = shift;

    my $cli = Beekeeper::Client->instance;
    my $var = 594;

    $SIG{'USR1'} = sub { $var++ };

    foreach my $n (1..3) {

        $cli->fire_remote(
            method => "test.signal",
            params => { signal => 'USR1', pid => $$, after => $n/2 },
        );
    }

    my $expected = 597;
    my $max_wait = 10; while ($max_wait--) { sleep 0.5; last if $var == $expected }
    is( $var, $expected, "Fire and forget method executed 3 times");
}

sub test_04_async_calls : Test(25) {
    my $self = shift;

    my $cli = Beekeeper::Client->instance;

    my $req = $cli->call_remote_async(
        method => 'test.echo',
        params => "baz",
    );

    isa_ok($req, 'Beekeeper::JSONRPC::Request');
    is( $req->response, undef );
    is( $req->success, undef );
    is( $req->result, undef );

    $cli->wait_async_calls;

    isa_ok( $req->response, 'Beekeeper::JSONRPC::Response' );
    is( $req->success, 1 );
    is( $req->result, "baz" );

    my @reqs;
    my $count = 10;
    my $var = 239;

    foreach my $n (1..$count) {
        my $req = $cli->call_remote_async(
            method => 'test.echo',
            params => $var + $n,
        );
        push @reqs, $req;
    }

    $cli->wait_async_calls;

    foreach my $n (1..$count) {
        is( $reqs[$n-1]->result, $var + $n );
    }

    # on_success callback
    my $cb = AnyEvent->condvar;
    my $resp;

    $cli->call_remote_async(
        method => 'test.echo',
        params => 749,
        on_success => sub {
            $resp = shift;
            $cb->send;
        }
    );

    $cb->recv;
    isa_ok( $resp, 'Beekeeper::JSONRPC::Response' );
    is( $resp->success, 1 );
    is( $resp->result, 749 );

    # on_error callback
    $cb = AnyEvent->condvar;
    undef $resp;

    $cli->call_remote_async(
        method => 'test.fail',
        params => { error => "error message 821" },
        on_error => sub {
            $resp = shift;
            $cb->send;
        }
    );

    $cb->recv;
    isa_ok( $resp, 'Beekeeper::JSONRPC::Error' );
    is( $resp->success, 0 );
    is( $resp->code, -32000);
    is( $resp->message, "error message 821");

    # Timeout
    eval {
        my $req = $cli->call_remote(
            method  => 'test.sleep',
            params  => '0.2',
            timeout => '0.01',
        );

        $cli->wait_async_calls;
    };

    like( $@, qr/Call to 'test.sleep' failed: -31600 Request timeout /);
}

sub test_05_utf8_serialization : Test(10) {
    my $self = shift;

    my $utf8_string = "\x{263A}";

    my $binary_blob = $utf8_string;
    utf8::encode($binary_blob);

    is( length($utf8_string), 1, 'String length is 1 char' );
    is( length($binary_blob), 3, 'Blob length is 3 bytes' );

    my $cli = Beekeeper::Client->instance;

    my $resp = $cli->call_remote(
        method => 'test.echo',
        params => {
            'utf8_string' => $utf8_string,
            'binary_blob' => $binary_blob,
        },
    );

    isa_ok($resp, 'Beekeeper::JSONRPC::Response');
    is( $resp->success, 1 );

    my $result = $resp->result;

    ok( $result->{utf8_string}, 'Received string' );
    ok( $result->{binary_blob}, 'Received blob' );

    is( length($result->{utf8_string}), 1, 'Received string length is 1 char' );
    is( length($result->{binary_blob}), 3, 'Received blob length is 3 bytes' );

    is( $result->{utf8_string}, $utf8_string, "Got correct utf8 string");
    is( $result->{binary_blob}, $binary_blob, "Got correct binary blob");
}

sub test_06_client_api : Test(8) {
    my $self = shift;

    use_ok('Tests::Service::Client');

    my $svc = 'Tests::Service::Client';
    my $var = 52;

    $SIG{'USR1'} = sub { $var++ };

    $svc->signal( 'USR1' => $$ );

    my $expected = 54;
    my $max_wait = 10; while ($max_wait--) { sleep 0.5; last if $var == $expected; }
    is( $var, $expected, "Notifications received by 2 workers");


    my $resp = $svc->echo( "foo" );

    isa_ok($resp, 'Beekeeper::JSONRPC::Response');
    is( $resp->success, 1 );
    is( $resp->result, 'foo');


    $resp = $svc->fibonacci( 2 );

    isa_ok($resp, 'Beekeeper::JSONRPC::Response');
    is( $resp->success, 1 );
    is( $resp->result, 1 );
}

1;
