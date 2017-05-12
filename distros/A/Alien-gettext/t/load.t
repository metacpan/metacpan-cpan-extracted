#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Alien::gettext
)) {
  use_ok($_);
}

done_testing;

