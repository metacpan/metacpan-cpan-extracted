#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  App::codefork
)) {
  use_ok($_);
}

done_testing;

