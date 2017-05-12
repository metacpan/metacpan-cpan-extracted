#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp03';
use Test::More tests => 5;

use HTTP::Request::Common;

ok( my $res = request('/action1'), 'request ok' );
is( $res->content, 'action1', 'store profile ok (action based)');

ok( $res = request(POST '/action2'), 'request ok' );
is( $res->content, 'action1', 'store profile ok (forward based)');

is( get('/action3'), 'action1', 'first profile is also stored after forwarding' );
