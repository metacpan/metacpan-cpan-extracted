#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp06';
use Test::Base;

plan tests => '6';

is( get('/action_a?input=123'), 'a', 'check a, normal validation');
is( get('/action_a?input=abc'), 'b', 'check b, nest level 1');
is( get('/action_a?input='), 'c', 'check c, nest level 2');

is( get('/action_a?input=&restore=a'), 'error a', 'check restored form objects');
is( get('/action_a?input=&restore=b'), 'error b', 'check restored form objects');

is( get('/no_validate_action'), 'error a', 'check stored first form object' );
