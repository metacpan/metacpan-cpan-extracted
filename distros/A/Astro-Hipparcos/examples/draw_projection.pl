use strict;
use warnings;
use Astro::Hipparcos;

# An example of drawing the data in the Hipparcos catalog
# (or any subset) into a 2D plot using Astro::SkyPlot
# and a Hammer, Sinusoidal or Miller projection.
# 
# This is virtually the same as the draw_hammer_proj.pl example,
# except it uses Astro::SkyPlot to do the actual drawing and thus
# supports multiple projections.
#
# Usage: draw_projection.pl datafile.dat [hammer|sinusoidal|miller]
# Will produce proj.eps
#
# Note: This example requires several extra modules:
# - Astro::SkyPlot
# - PostScript::Simple
# - Astro::MapProjection
# - Astro::Nova (version 0.06 and up)
#
# You can find the full EPS output of this program at
#   http://steffen-mueller.net/hipparcos/hipparcos.eps.bz2
# Warning: It's a 2MB archive containing a 13MB EPS

use constant PI      => atan2(1,0)*2;
use constant DEG2RAD => PI/180;

# this will convert from equatorial coordinates to galactic coordinates
use Astro::Nova;
# this handles the actual plotting
use Astro::SkyPlot qw/:all/;


# open the input file
my $catalog_file = shift;
$catalog_file = "hip_main.dat" if not defined $catalog_file;
my $catalog = Astro::Hipparcos->new($catalog_file);

# create the plot object
my $proj = shift;
$proj = 'hammer' if not defined $proj;

my $size = 200; # in mm
my $xsize = $size;
my $ysize = $size; # let's stay symmetric
my $sp = Astro::SkyPlot->new(
  projection => $proj,
  xsize => $xsize,
  ysize => $ysize,
);
$sp->marker(MARK_CIRCLE_FILLED);


my $min_magnitude = -1.441; # determined with a "grep" over the catalog
my $max_magnitude = 14.08;
my $i = 0;
while (defined(my $record = $catalog->get_record())) {
  #last if $i++ == 10000;
  my $mag = $record->get_Vmag();

  # fetch color from color scale (see below)
  my $color = color($mag, $min_magnitude, $max_magnitude);
  $sp->setcolor(map {255*$_} @$color);

  # convert to galactic coords
  my $equ_posn = Astro::Nova::EquPosn->new(ra => $record->get_RAdeg, dec => $record->get_DEdeg);
  my $gal_posn = $equ_posn->to_galactic_J2000();
  my ($b, $l) = ($gal_posn->get_b, $gal_posn->get_l);
  $l -= 360 while $l > 180;

  $sp->plot_lat_long($b*DEG2RAD, $l*DEG2RAD);
}

# draw scale
# => This should be part of Astro::SkyPlot?
my $scale_miny    = $ysize*0.85;
my $scale_maxy    = $ysize*0.92;
my $scale_minx    = $xsize*0.05;
my $scale_maxx    = $xsize*0.95;
my $scale_steps   = 200;
my $scale_step    = ($scale_maxx-$scale_minx) / $scale_steps;
my $scale_magstep = ($max_magnitude-$min_magnitude) / $scale_steps;

foreach my $i (0..$scale_steps-1) {
  my $x = $scale_minx + $scale_step*$i;
  my $mag = $min_magnitude+$scale_magstep*$i;
  my $color = color($mag, $min_magnitude, $max_magnitude);
  $sp->setcolor(map {255*$_} @$color);
  $sp->ps->box({filled=>1}, $x, $scale_miny, $x+$scale_step*1.1, $scale_maxy);
}

$sp->write(file => "proj.eps");


# all that's following is for the color scales. Should be done
# in a module...

sub linear_interpolate {
  my ($x, $x1, $x2, $y1, $y2) = @_;
  return $y1 + ($x-$x1)*($y2-$y1)/($x2-$x1);
}

use vars qw/$Colors/;
BEGIN {
  #$Colors = [
  #  [-1.e-9,   0.5, 0.3, 0.3],
  #  [0.3,      0.6, 0.1, 0.1],
  #  [0.7,        1,   0,   0],
  #  [1+1.e-9,    1, 0.8, 0.1],
  #];
  $Colors = [
    [-1.e-9,   0.1, 0.0, 0.0],
    [0.5,        1,   0,   0],
    [0.7,        1, 0.8, 0.1],
    [1+1.e-9,    1,   1,   1],
  ];
}

# calculate a color scale value
sub color {
  my $value = shift;
  my $min = shift;
  my $max = shift;

  my $x = ($value-$min)/($max-$min);
  my $upper;
  my $lower;
  foreach my $icol (0..$#{$Colors}) {
    if ($Colors->[$icol][0] >= $x) {
      $upper = $Colors->[$icol];
      $lower = $Colors->[$icol-1];
      last;
    }
  }
  die "Out of range"
    if not defined $lower or not defined $upper;
 
  my @rgb = map {linear_interpolate($x, $lower->[0], $upper->[0], $lower->[$_], $upper->[$_])} (1,2,3); 
  return \@rgb;
}
