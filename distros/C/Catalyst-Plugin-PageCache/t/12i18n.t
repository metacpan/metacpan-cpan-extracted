#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;


BEGIN {
    my $reason;
    eval "use Catalyst::Plugin::I18N";
    $reason .= 'Needs Catalyst::Plugin::I18N for this test. ' if $@;

    eval "use Catalyst::Plugin::Cache";
    $reason .= 'Needs Catalyst::Plugin::Cache for testing' if $@;

    plan $reason
        ? ( skip_all => $reason )
        : ( tests => 25 );
}

use Catalyst::Test 'TestAppI18N';

run_tests();

sub run_tests {
# cache a page localized for a language
    {
        my $expected = 'hello 1';
        my $request  =
            HTTP::Request->new( GET => 'http://localhost:3000/cache/count' );

        $request->header( 'Accept-Language' => 'en' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'content is "hello 1"' );

    }
    
# request the same page with same language
    {
        my $expected = 'hello 1';
        my $request  =
            HTTP::Request->new( GET => 'http://localhost:3000/cache/count' );

        $request->header( 'Accept-Language' => 'en' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content still "hello 1" from cache' );

    }

# request same page, different language.
    {
        my $expected = 'hola 2';
        my $request  =
            HTTP::Request->new( GET => 'http://localhost:3000/cache/count' );

        $request->header( 'Accept-Language' => 'es' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content is "hola 2"' );

    }

# request the same page with same language different from first...
    {
        my $expected = 'hola 2';
        my $request  =
            HTTP::Request->new( GET => 'http://localhost:3000/cache/count' );

        $request->header( 'Accept-Language' => 'es' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'Content still "hola 2" from cache' );

    }

# clearing the cached page should affect *both* languages
    {
        my $request = 
            HTTP::Request->new( GET => 'http://localhost:3000/cache/clear_cache' );
        ok( my $response = request($request), 'request ok' );
    }

# the previous request to clear_cache also incremented the counter so we skip that one.

# first ask for a fresh copy for 'en'
    {
        my $expected = 'hello 4';
        my $request  =
            HTTP::Request->new( GET => 'http://localhost:3000/cache/count' );

        $request->header( 'Accept-Language' => 'en' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'content is "hello 4"' );

    }

# next ask for a fresh copy for 'es'
    {
        my $expected = 'hola 5';
        my $request  =
            HTTP::Request->new( GET => 'http://localhost:3000/cache/count' );

        $request->header( 'Accept-Language' => 'es' );

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->code, 200, 'Response Code' );

        is( $response->content, $expected, 'content is "hola 5"' );

    }
}
