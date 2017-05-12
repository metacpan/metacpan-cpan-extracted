#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 12;
use Catalyst::Test 'TestApp';

BEGIN {
    no warnings 'redefine';

    *Catalyst::Test::local_request = sub {
        my ( $class, $request ) = @_;

        require HTTP::Request::AsCGI;
        my $cgi = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

        $class->handle_request;

        return $cgi->restore->response;
    };
}

run_tests();

sub run_tests {

    # test normal execution
    {
        my $expected = "A\nB\nC\n";
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/runtest' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test normal execution w/ args
    {
        my $expected = "AX\nBX\nCX\n";
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/runtest_args' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test reverse execution
    {
        my $expected = "C\nB\nA\n";
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/runtest_reverse' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }
}
