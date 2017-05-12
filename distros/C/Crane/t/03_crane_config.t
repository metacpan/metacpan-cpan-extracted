#!/usr/bin/env perl
# -*- coding: utf-8 -*-


use t::lib::Crane::Config;

use Test::More;


plan('tests' => 3);

can_ok('Crane::Config', qw(
    config
));

subtest('Merge' => \&test_merge);
subtest('Read & Write' => \&test_read_write);

done_testing();
