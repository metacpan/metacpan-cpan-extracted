#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib "t/lib";

$ENV{CATALYST_CONFIG} = 't/conf/mylib.yml';

use_ok( 'Catalyst::Test', 'MyApp' );

ok(my(undef, $c) = ctx_request('/a'), 'controller A can use MyLib');
is($c->res->body, 'pong', 'MyLib::ping return pong');
