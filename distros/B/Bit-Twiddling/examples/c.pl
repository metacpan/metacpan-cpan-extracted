#!/usr/bin/env perl

#:TAGS:

use strict;  use warnings;  use autodie qw/:all/;

use Inline Config =>
  disable => 'clean_after_build',
  name    => 'Bit::Twiddling';

use Inline C => <<'EOC';
int count_set_bits(long v) {
    int c;
    for (c = 0; v; c++)
      v &= v - 1;
    return c;
}

long nearest_higher_power_of_2(long v) {
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    return v + 1;
}
EOC
