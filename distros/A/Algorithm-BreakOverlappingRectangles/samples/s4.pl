#!/usr/bin/perl

use warnings;
use strict;

$| = 1;

use Algorithm::BreakOverlappingRectangles;

my $a = Algorithm::BreakOverlappingRectangles->new;

while(<>) {
    next if /^\s*$/;
    chomp;
    $a->add_rectangle(split/\s+/);
}

$a->dump;

use GD;

my $im = GD::Image->new(1000, 1000);

my $white =  $im->colorAllocate(255,255,255);
my @colors = map $im->colorAllocate(256 * rand, 256 * rand, 256 * rand), 0..127;

$im->rectangle(0,0,999,999, $white);

for ($a->get_rectangles) {
    my ($x0, $y0, $x1, $y1, @ids) = @{$_};
    my $color = $colors[128 * rand];
    $im->rectangle($x0, $y0, $x1 - 1, $y1 - 1, $color);
    $im->string(gdSmallFont, $x0, ($y0+$y1)/2, "[@ids]", $color);
}

open my $file, '>', 'image.png';

print $file $im->png;

close $file;



