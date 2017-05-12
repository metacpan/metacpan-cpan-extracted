#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp02';
use Test::More tests => 14;

use HTTP::Request::Common;

# action driven validation
ok( my $res = request('/action1'), 'request ok' );
is( $res->content, 'NOT_BLANK', 'is NOT_BLANK error');

ok( $res = request('/action1?param1=aaa bbb'), 'request ok' );
is( $res->content, 'ASCII', 'is ASCII error');

ok( $res = request('/action1?param1=aaa'), 'request ok' );
is( $res->content, 'no errors', 'is no errors');


# forward driven validation
ok( $res = request(POST '/action2', [ param1 => '' ]), 'request ok' );
is( $res->content, 'NOT_BLANK', 'is NOT_BLANK error');

ok( $res = request(POST '/action2', [ param1 => 'aaa bbb' ]), 'request ok' );
is( $res->content, 'ASCII', 'is ASCII error');

ok( $res = request(POST '/action2', [ param1 => 'ab' ]), 'request ok' );
is( $res->content, 'no errors', 'is no errors');

ok( $res = request('/action2'), 'request ok' );
is( $res->content, 'no $c->form executed', 'is no $c->form executed');

