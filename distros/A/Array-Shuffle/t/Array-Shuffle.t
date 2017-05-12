#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2000;
use Array::Shuffle qw(shuffle_array shuffle_huge_array);

my (@a, @b);
for my $n (1..1000) {
    push @a, $n;
    push @b, $n;
    shuffle_array @b;
    is("@a", join(" ", sort { $a <=> $b } @b));
    shuffle_huge_array @b;
    is("@a", join(" ", sort { $a <=> $b } @b));
}
