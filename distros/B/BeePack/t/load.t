#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  BeePack
)) {
  use_ok($_);
}

done_testing;

