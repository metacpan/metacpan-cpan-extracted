#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  App::pmdir
)) {
  use_ok($_);
}

done_testing;

