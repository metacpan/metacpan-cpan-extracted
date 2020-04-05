#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Test::More tests => 1;
use App::WRT::Sort qw(sort_entries);

my @unsorted = (
  'abc',
  'chapbook',
  'c',
  'c/frobnicate',
  'frobnicate',
  '2012/1/2',
  '2019/6/21',
  '2019/6/2',
  '2014/3/1/a',
  '2014/3/1/frobnicate',
  '2014/3/1/b',
  '1999/12/1',
  'a/index',
  'a/ind',
  'a',
  '2019/6/11',
  '2019/6/1',
  'b',
  'supercalifragilisticexpialidociousceteradisestamblishmentarianism'
);

my $sorted = [
  '1999/12/1',
  '2012/1/2',
  '2014/3/1/a',
  '2014/3/1/b',
  '2014/3/1/frobnicate',
  '2019/6/1',
  '2019/6/2',
  '2019/6/11',
  '2019/6/21',
  'a',
  'abc',
  'a/ind',
  'a/index',
  'b',
  'c',
  'c/frobnicate',
  'chapbook',
  'frobnicate',
  'supercalifragilisticexpialidociousceteradisestamblishmentarianism'
];

my (@result) = sort_entries(@unsorted);

unless (is_deeply($sorted, \@result, "sort_entries() works, more or less")) {
  for (@result) {
    diag($_);
  }
}
