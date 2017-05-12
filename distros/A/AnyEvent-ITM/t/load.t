#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  AnyEvent::ITM
)) {
  use_ok($_);
}

done_testing;

