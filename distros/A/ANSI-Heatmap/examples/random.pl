#!/usr/bin/perl
use strict;
use warnings;

use ANSI::Heatmap;

my $map = ANSI::Heatmap->new;

binmode STDOUT, ':utf8';

# Randomness
for (1..2000) {
    my $x = int(rand(50));
    my $y = int(rand(21));
    $map->inc($x, $y);
}
print $map;

$map->half(1);
print "\n";
print $map;
