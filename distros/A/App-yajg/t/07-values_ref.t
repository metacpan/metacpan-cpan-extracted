#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

use_ok('App::yajg');

# input scalar wantarray
my @tests = (
    [[], 0, []],
    [{}, 0, []],
    [[1, 2, 3], 3, [1, 2, 3]],
    [{ 1 => 2, 3 => 4 }, 2, [2, 4]],
    [undef,    0, []],
    ['scalar', 0, []],
    [sub { }, 0, []],
);

for (@tests) {
    is scalar App::yajg::values_ref($_->[0]), $_->[1];
    is_deeply [sort { $a <=> $b } App::yajg::values_ref($_->[0])], $_->[2];
}

done_testing();
