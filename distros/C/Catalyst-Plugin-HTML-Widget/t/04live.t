#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 24;
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

    # test nameless
    {
        my $request =
          HTTP::Request->new( GET => 'http://localhost:3000/nameless' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        ok( $response->content =~ /form/, 'Content OK' );
        ok( $response->content !~ /fields_with_errors/, 'No Error Fields OK' );
    }

    # test named
    {
        my $request =
          HTTP::Request->new( GET => 'http://localhost:3000/named' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        ok( $response->content =~ /form/, 'Content OK' );
    }

    # test nameless_result
    {
        my $request =
          HTTP::Request->new(
            GET => 'http://localhost:3000/nameless_result?foo=bar' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        ok( $response->content =~ /form/, 'Content OK' );
        ok( $response->content =~ /fields_with_errors/, 'widget_result OK' );
    }

    # test nameless_noresult
    {
        my $request =
          HTTP::Request->new(
            GET => 'http://localhost:3000/nameless_noresult' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        ok( $response->content =~ /form/, 'Content OK' );
        ok( $response->content !~ /fields_with_errors/, 'widget_noresult OK' );
    }

    # test nameless_res_nores
    {
        my $request =
          HTTP::Request->new(
            GET => 'http://localhost:3000/nameless_res_nores' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        ok( $response->content =~ /form/, 'Content OK' );
        ok( $response->content !~ /fields_with_errors/, 'widget_res_nores OK' );
    }

}
