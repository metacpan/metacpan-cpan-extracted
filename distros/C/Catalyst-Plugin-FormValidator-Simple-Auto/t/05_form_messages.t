#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp05';
use Test::Base;

plan tests => 8;

ok( my $res = request('/action1'), 'request ok' );
is( $res->content, 'NOT_BLANK!!!', 'is NOT_BLANK error');

ok( $res = request('/action1?as=hash'), 'request ok' );
is( $res->content, 'NOT_BLANK!!!', 'is NOT_BLANK error (test as hash)');


ok( $res = request('/action1?param1=aaa bbb'), 'request ok' );
is( $res->content, 'ASCII!!!', 'is ASCII error');

ok( $res = request('/action1?param1=aaa bbb&as=hash'), 'request ok' );
is( $res->content, 'ASCII!!!', 'is ASCII error (test as hash)');
