#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 36;
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

    # test Lexicon
    {
        my $expected = 'Bonjour';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/maketext/Hello' );

        $request->header( 'Accept-Language' => 'fr' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test .po
    {
        my $expected = 'Hallo';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/maketext/Hello' );

        $request->header( 'Accept-Language' => 'de' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test language()
    {
        my $expected = 'fr';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/current_language' );

        $request->header( 'Accept-Language' => 'fr' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test language()/language_tag()
    {
        my $expected = 'en_us';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/current_language' );

        $request->header( 'Accept-Language' => 'en-us' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }
    {
        my $expected = 'en-us';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/current_language_tag' );

        $request->header( 'Accept-Language' => 'en-us' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test fallback (i.e. fr-ca => fr)
    {
        my $expected = 'fr';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/current_language' );

        $request->header( 'Accept-Language' => 'fr-ca' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # Test languages_list
    {
        my $expected = "de=German, en_us=US English, fr=French";
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/current_languages_list' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }
       
    # test fallback to i_default
    {
        my $expected = 'Hello - default';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/maketext/messages.hello' );

        $request->header( 'Accept-Language' => 'fr-ca' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }

    # test AUTO in i_default
    {
        my $expected = 'no.key';
        my $request  =
          HTTP::Request->new( GET => 'http://localhost:3000/maketext/no.key' );

        $request->header( 'Accept-Language' => 'fr-ca' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content OK' );
    }
}
