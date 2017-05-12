#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Alien::ffmpeg
)) {
  use_ok($_);
}

done_testing;

