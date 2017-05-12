#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 20;
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

    # test maketext
    {
        my $expected = 'search';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/maketext/PATH_delocalize_recherche' );

        $request->header( 'Accept-Language' => 'fr' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test delocalized parameter name
    {
        my $expected = 'search';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/current_parameter_name?recherche=foo' );

        $request->header( 'Accept-Language' => 'fr' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test delocalized path name
    {
        my $expected = 'current_request_path/search';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/current_request_path/recherche' );

        $request->header( 'Accept-Language' => 'fr' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test localized uri_for
    {
        my $expected = 'http://localhost:3000/recherche?recherche=search';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/localized_uri_for/search/search' );

        $request->header( 'Accept-Language' => 'fr' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test localized uri_with
    {
        my $expected = 'http://localhost:3000/localized_uri_with/recherche?recherche=search';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/localized_uri_with/search' );

        $request->header( 'Accept-Language' => 'fr' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

}
