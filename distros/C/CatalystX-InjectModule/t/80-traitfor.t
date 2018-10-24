#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib "t/lib";

$ENV{CATALYST_CONFIG} = 't/conf/traitfor.yml';

use_ok( 'Catalyst::Test', 'MyApp' );

ok(my(undef, $c) = ctx_request('/a'), 'controller tt use TT View');
is($c->res->body, "traitfor_beforeindex=1\n", 'inject method modifiers in a controller');
