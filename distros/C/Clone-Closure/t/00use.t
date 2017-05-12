#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $tests;

BEGIN { $tests += 3 }
use_ok 'Clone::Closure';
can_ok 'Clone::Closure', 'clone';
ok !main->can('clone'), 'clone not exported by default';

BEGIN { $tests += 2 }
use_ok 'Clone::Closure', 'clone';
can_ok 'main', 'clone';

BEGIN { plan tests => $tests }

BAIL_OUT('module will not load')
    if grep !$_, Test::More->builder->summary;
