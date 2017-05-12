#!/usr/bin/perl

use warnings;
use strict;

use Math::Random qw(random_normal random_uniform_integer);
use List::Util qw(max min);
use GD::Image;

use Algorithm::ClusterPoints;

select STDERR; $|=1; select STDOUT;

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

my ($n, $pixels, $frames, $out) = @ARGV;


$n ||= 100000;
$pixels ||= 480;
$frames ||= 50;
$out ||= 'image.gif';


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

print STDERR "generating data...\n";

my @x = random_normal($n, $dx/2, 0.805771);
my @y = random_normal($n, $dy/2, 0.974835);
my @t = random_uniform_integer($n, 0, $frames);

print STDERR "clustering...\n";

my $clp = Algorithm::ClusterPoints->new( #dimension => 3,
                                         dimensional_groups => [[0,1],[2]],
                                         scales => [ 1/0.1, 1/0.1, 1/10 ] );

$clp->add_point($x[$_], $y[$_], $t[$_]) for (0..$#x);
my @clusters = $clp->clusters_ix;

print STDERR "drawing...\n";

my @ccs = map [ map int(256 * rand), 0..2 ], 0..128;

my $im = GD::Image->new($idx, $idy);
$im->colorAllocate(255, 255, 255);
$im->colorAllocate(@$_) for @ccs;
print $fh $im->gifanimbegin(1, 1);
# print $fh $im->gifanimadd;
for my $now (0..$frames) {
    print STDERR "\r$now";
    my $frame = GD::Image->new($idx, $idy);
    my $white = $frame->colorAllocate(255, 255, 255);
    $frame->rectangle(0, 0, $idx, $idy, $white);
    my @colors = map $frame->colorAllocate(@$_), @ccs;

    for (0..$#clusters) {
        my $color = $colors[$_ % @colors];
        for (@{$clusters[$_]}) {
            my ($x, $y, $t) = $clp->point_coords($_);
            # print STDERR "t: $t, now: $now\n";
            if ($t == $now) {
                # printf STDERR "set color: $color, x: %d, y: %d\n", $x * $scale, $y * $scale;
                $frame->setPixel($x * $scale, $y * $scale, $color)
            }

        }
    }
    print $fh $frame->gifanimadd(1, 0, 0, 20);
}

print $fh $im->gifanimend;

print STDERR "\ndone!\n";
