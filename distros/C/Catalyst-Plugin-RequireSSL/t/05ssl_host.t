#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

TestApp->config->{require_ssl} = {
    https => 'secure.mydomain.com',
    http => 'www.mydomain.com',
};

# test an SSL redirect
ok( my $res = request('http://localhost/ssl/secured'), 'request ok' );
is( $res->code, 302, 'redirect code ok' );
is( $res->header('location'), 'https://secure.mydomain.com/ssl/secured', 'other domain redirect uri ok' );
isnt( $res->content, 'Secured', 'no content displayed on secure page, ok' );

# test redirect back to HTTP
SKIP:
{
    if ( Catalyst->VERSION < 5.5 ) {
        skip "These tests require Catalyst >= 5.5", 2;
    }
    ok( $res = request('https://secure.mydomain.com/ssl/unsecured'), 'request ok' );
    is( $res->header('location'), 'http://www.mydomain.com/ssl/unsecured', 'other domain redirect uri ok' );
}

