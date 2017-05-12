#!/usr/bin/env perl
# FILENAME: runbench.pl
# CREATED: 09/13/14 02:18:27 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Run benchmarks

use strict;
use warnings;
use utf8;

$ENV{KEY_SIZE}   = 256;
$ENV{VALUE_SIZE} = 256;
$ENV{TEST_MAX}   = 100;
for my $test ( 0 .. 8 ) {
  for ( 0 .. 50 ) {
    $ENV{TEST_ID} = $test;
    system( $^X, 'bench/id_bench.pl' ) == 0 or die;
  }
}
