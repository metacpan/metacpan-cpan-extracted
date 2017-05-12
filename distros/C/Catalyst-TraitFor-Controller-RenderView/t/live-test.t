#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 15;
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

    # test first available view
    {
        my $expected = 'View';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/test_firstview' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->header( 'Content-Type' ), 'text/html; charset=utf-8', 'Content Type' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test view
    {
        my $expected = 'View';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/test_view' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->header( 'Content-Type' ), 'text/html; charset=utf-8', 'Content Type' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test skip view
    {
        my $expected = 'Skipped View';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/test_skipview' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->header( 'Content-Type' ), 'text/html; charset=utf-8', 'Content Type' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

}
