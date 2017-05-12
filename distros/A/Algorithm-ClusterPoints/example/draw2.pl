#!/usr/bin/perl

use warnings;
use strict;

use Math::Random qw(random_normal);
use List::Util qw(max min);
use GD::Image;

use Algorithm::ClusterPoints;


# Latitude stats:
# Minimum: 10.318842
# Maximum: 14.124424
# Mean: 11.24719
# Standard Deviation: 0.805771


# Longitude stats:
# Minimum: 21.097507
# Maximum: 24.912207
# Mean: 22.474358
# Standard Deviation: 0.974835

my ($n, $pixels, $out) = @ARGV;


$pixels ||= 1024;
$n ||= 100000;
$out ||= 'image2.png';

open my $fh, '>', $out
    or die "unable to open $out: $!";


my $xmin = 21.097507;
my $xmax = 24.912207;
my $ymin = 10.318842;
my $ymax = 14.124424;
my $dx = $xmax - $xmin;
my $dy = $ymax - $ymin;
my ($idx, $idy) = ($dx > $dy ? ($pixels, $pixels * $dy / $dx) : ($pixels * $dx / $dy, $pixels));
my $scale = $idx / $dx;

my $sx = 0.805771/4;
my $sy = 0.974835/4;

my (@x, @y);
for (1..$n) {
    if (@x and rand > .2) {
        my $i = $_ * rand;
        push @x, random_normal(1, $x[$i], $sx);
        push @y, random_normal(1, $y[$i], $sy);
    }
    else {
        push @x, $dx * rand;
        push @y, $dy * rand;
    }
}

my $clp = Algorithm::ClusterPoints->new(radius => 0.01);
$clp->add_point($x[$_], $y[$_]) for (0..$#x);
my @clusters = $clp->clusters_ix;

my $im = GD::Image->new($idx, $idy);

my $white = $im->colorAllocate(255, 255, 255);
$im->rectangle(0, 0, $idx, $idy, $white);

my @colors = map { $im->colorAllocate(map int(256 * rand), 0..2) } 0..128;

for (@clusters) {
    my $color = $colors[@colors*rand];
    for (@$_) {
        my ($x, $y) = $clp->point_coords($_);
        $im->setPixel($x * $scale, $y * $scale, $color);
    }
}

print $fh $im->png;
