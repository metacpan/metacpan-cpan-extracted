#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib "t/lib";

$ENV{CATALYST_CONFIG} = 't/conf/template.yml';

use_ok( 'Catalyst::Test', 'MyApp' );

ok(my(undef, $c) = ctx_request('/tt'), 'controller tt use TT View');
is($c->res->body, "template tt/index.tt\n", 'can use Template Toolkit');
