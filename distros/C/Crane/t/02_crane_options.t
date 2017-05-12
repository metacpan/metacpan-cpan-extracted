#!/usr/bin/env perl
# -*- coding: utf-8 -*-


use t::lib::Crane::Options;

use Test::More;


plan('tests' => 2);

can_ok('Crane::Options', qw(
    options
    args
));

subtest('Load' => \&test_load);

done_testing();
