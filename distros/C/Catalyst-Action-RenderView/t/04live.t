#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More 0.88;
use Catalyst::Test 'TestApp';

run_tests();

done_testing;

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

    # test X-Sendfile case
    {
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/test_definedbody_skipsview' );

      ok( my $response = request($request), 'Request' );
      ok( $response->is_success, 'Response Successful 2xx' );
      is( $response->header( 'Content-Type' ), 'text/html; charset=utf-8', 'Content Type' );
      is( $response->code, 200, 'Response Code' );

      is( $response->content, '', 'Content OK' );
      is( $response->header('X-Sendfile'), '/some/file/path', 'X-Sendfile header present' );
    }

}
