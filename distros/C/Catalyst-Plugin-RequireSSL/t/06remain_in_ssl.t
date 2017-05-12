#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

TestApp->config->{require_ssl} = {
    remain_in_ssl => 1,
};

# test an SSL redirect
ok( my $res = request('http://localhost/ssl/secured'), 'request ok' );
is( $res->code, 302, 'redirect code ok' );
is( $res->header('location'), 'https://localhost/ssl/secured', 'redirect uri ok' );
isnt( $res->content, 'Secured', 'no content displayed on secure page, ok' );

# test redirect back to HTTP, should not redirect
SKIP:
{
    if ( Catalyst->VERSION < 5.5 ) {
        skip "These tests require Catalyst >= 5.5", 2;
    }
    ok( $res = request('https://localhost/ssl/unsecured'), 'request ok' );
    is( $res->code, 200, 'remain in SSL ok' );
}

