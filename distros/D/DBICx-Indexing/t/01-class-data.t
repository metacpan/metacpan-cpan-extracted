#!perl

package main;

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;

use My::Test::T1;
use My::Test::T2;

for my $class ('My::Test::T1', 'My::Test::T2') {
  cmp_deeply($class->indices, {
    idx1 => ['a'],
    idx2 => ['a', 'c'],
    idx3 => ['d', 'a'],
    idx4 => ['e', 'f'],
  });
}

done_testing();