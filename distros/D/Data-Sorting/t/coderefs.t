#!perl
use strict;
use Test::More tests => 4;
BEGIN { use_ok('Data::Sorting'); }
require 't/sort_tests.pl';

test_sort_cases (
  {
    values => [ 
      sub { 'Alpha' },
      sub { 'Beta' },
      sub { 'Gamma' },
      sub { 'Omega' },
    ],
    sorted => [ sub { &{ $_[0] } } ],
  },
  {
    values => [ 
      sub { 'Alpha' },
      sub { 'Beta' },
      sub { 'Gamma' },
      sub { 'Omega' },
    ],
    sorted => [ -extract => 'self_code' ],
  },
  {
    values => [ 
      sub { 'Omega' },
      sub { 'Gamma' },
      sub { 'Beta' },
      sub { 'Alpha' },
    ],
    sorted => [ -extract => 'self_code', -order => 'reverse' ],
  },
);
