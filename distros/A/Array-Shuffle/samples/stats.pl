#!/usr/bin/perl

use strict;
use warnings;

use Array::Shuffle qw(shuffle_array);

my @a = (0..100);
my @t = map 0, @a;
for (1..1000000) {
    shuffle_array @a;
    $t[$_] += $a[$_] for (0..$#a);
}

for (@t) {
    printf "%d ", 0.00001 * $_;
}
print "\n"


