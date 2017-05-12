#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 19;
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;

# test an SSL redirect
ok( my $res = request('http://localhost/ssl/secured'), 'request ok' );
is( $res->code, 302, 'redirect code ok' );
is( $res->header('location'), 'https://localhost/ssl/secured', 'redirect uri ok' );
isnt( $res->content, 'Secured', 'no content displayed on secure page, ok' );

# test redirection params
ok( $res = request('http://localhost/ssl/secured?a=1&a=2&b=3&c=4'), 'request ok' );
is( $res->header('location'), 'https://localhost/ssl/secured?a=1&a=2&b=3&c=4', 'redirect with params ok' );

# test that it does not redirect for actions where SSL mode is optional
ok( $res = request('http://localhost/ssl/maybe_secured'), 'request ok' );
is( $res->code, 200, 'no redirect for optional SSL action' );

# test that it doesn't redirect on POST
my $request = POST( 'http://localhost/ssl/secured', 
    'Content'      => '',
    'Content-Type' => 'application/x-www-form-urlencoded'
);
ok( $res = request($request), 'request ok' );
is( $res->code, 200, 'POST ok' );

# test that it doesn't redirect if already in SSL mode
SKIP:
{
    if ( Catalyst->VERSION < 5.5 ) {
        skip "These tests require Catalyst >= 5.5", 7;
    }
    ok( $res = request('https://localhost/ssl/secured'), 'request ok' );
    is( $res->code, 200, 'SSL request, ok' );
    
    # test redirect back to http mode
    ok( $res = request('https://localhost/ssl/unsecured'), 'request ok' );
    is( $res->code, 302, 'redirect back to http ok' );
    is( $res->header('location'), 'http://localhost/ssl/unsecured', 'redirect uri ok' );
    
    # test redirection params
    ok( $res = request('https://localhost/ssl/unsecured?a=1&a=2&b=3&c=4'), 'request ok' );
    is( $res->header('location'), 'http://localhost/ssl/unsecured?a=1&a=2&b=3&c=4', 'redirect with params ok' );

    # test that it does not redirect for actions where SSL mode is optional
    ok( $res = request('https://localhost/ssl/maybe_secured'), 'request ok' );
    is( $res->code, 200, 'no redirect for optional SSL action' );
}

