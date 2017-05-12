#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Data::Coloured
  DDC
)) {
  use_ok($_);
}

done_testing;

