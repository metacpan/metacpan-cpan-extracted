#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 19;
use Test::MockObject::Extends;
use URI;

use Catalyst::Test 'TestApp';
use Catalyst::Request;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session::State::URI" ) }

can_ok( $m, "uri_with_sessionid" );
can_ok( $m, "uri_for" );

my $response;

ok ( $response = request('http://localhost/uri'), 'Request' );
ok ( $response->content eq "http://localhost/foo/bar" );

ok ( $response = request('http://localhost/uri/arg'), 'Request' );
ok ( $response->content eq "http://localhost/foo/bar/arg" );

ok ( $response = request('http://localhost/uri/param'), 'Request' );
ok ( $response->content eq "http://localhost/foo/bar?param=value" );

ok ( $response = request('http://localhost/uri/arg_param'), 'Request' );
ok ( $response->content eq "http://localhost/foo/bar/arg?param=value" );

ok ( $response = request('http://localhost/uri/sid'), 'Request' );
ok ( $response->content =~ qr(^http://localhost/foo/bar\?sid=[a-z0-9]+$) );

ok ( $response = request('http://localhost/uri/sid_arg'), 'Request' );
ok ( $response->content =~ qr(^http://localhost/foo/bar/arg\?sid=[a-z0-9]+$) );

ok ( $response = request('http://localhost/uri/sid_param'), 'Request' );
ok ( $response->content =~ qr(^http://localhost/foo/bar\?param=value&sid=[a-z0-9]+$) );

ok ( $response = request('http://localhost/uri/sid_arg_param'), 'Request' );
ok ( $response->content =~ qr(^http://localhost/foo/bar/arg\?param=value&sid=[a-z0-9]+$) );

