#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 29;
use Catalyst::Test 'TestApp';
use HTTP::Request::Common;

ok( my $res = request('https://localhost/root_ssl'), 'request ok' );
is( $res->code, 200, 'SSL request to SSL' );

my $ctx;
ok( ($res, $ctx) = ctx_request('https://localhost/root_plain'), 'request ok' );
is($ctx->request->uri->scheme, 'https');
is( $res->code, 302, 'SSL request to Plain redirected' );
is( $res->header('location'), 'http://localhost/root_plain', 'Correct URI' );

#chained tests

ok( ($res, $ctx) = ctx_request('http://localhost/ssl/ssl'), 'request ok' );
is($ctx->request->uri->scheme, 'http');
is( $res->header('location'), 'https://localhost/ssl/ssl', 'Redirected to SSL' );
is( $res->content, 'Unsecured', "Correctly detached and didn't run action");

ok( $res = request('http://localhost/ssl/ssl?a=1&b=2&c=3'), 'request ok' );
is( $res->header('location'), 'https://localhost/ssl/ssl?a=1&b=2&c=3', 'SSL with GET' );

my $request = POST( 'http://localhost/ssl/ssl', 
    'Content'      => '',
    'Content-Type' => 'application/x-www-form-urlencoded'
);
ok( $res = request($request), 'request ok' );
is( $res->code, 500, 'POST causes death' );

ok( $res = request('https://localhost/ssl/plain'), 'request ok' );
is( $res->code, 302, 'SSL request to Plain redirected' );
is( $res->header('location'), 'http://localhost/ssl/plain', 'Correct URI' );

ok( $res = request('http://localhost/plain/ssl'), 'request ok' );
is( $res->code, 302, 'redirected to SSL' );
is( $res->header('location'), 'https://localhost/plain/ssl', 'Correct URI' );

ok( $res = request('https://localhost/plain/plain'), 'request ok' );
is( $res->code, 302, 'redirected to Plain' );
is( $res->header('location'), 'http://localhost/plain/plain', 'Correct URI' );

ok( $res = request('http://localhost/ssl/plain_chained/ssl'), 'request ok' );
is( $res->code, 302, 'redirected to SSL' );
is( $res->header('location'), 
  'https://localhost/ssl/plain_chained/ssl', 'Correct URI' );

ok( $res = request('https://localhost/ssl/plain_chained/plain'), 'request ok' );
is( $res->code, 302, 'redirected to Plain' );
is( $res->header('location'), 
  'http://localhost/ssl/plain_chained/plain', 'Correct URI' );
