#!perl
use strict;
use Test::More tests => 6;
BEGIN { use_ok('Data::Sorting'); }
require 't/sort_tests.pl';

test_sort_cases (
  {
    values => [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ) ],
    sorted => [ -compare=>'numeric' ],
  },
  {
    values => [ qw( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 ) ],
    sorted => [ -compare=>'natural' ],
  },
  {
    values => [ qw( 1 10 11 12 13 14 15 16 17 18 19 2 20 3 4 5 6 7 8 9 ) ],
    sorted => [ -compare => 'bytewise' ],
  },
  {
    values => [ qw( 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 ) ],
    sorted => [ -compare=>'natural', -order => 'reverse' ],
  },
  {
    values => [ qw( 16 1 17 2 3 4 5 6 7 8 9 10 11 12 13 14 15 ) ],
    sorted => [ -compare=>'numeric', sub { $_[0] % 16 } ],
    'okidxs' => [ [ 1, 3, 2, 4 .. 17 ], [ 1, 2, 3, 4 .. 17 ] ],
  },
);
