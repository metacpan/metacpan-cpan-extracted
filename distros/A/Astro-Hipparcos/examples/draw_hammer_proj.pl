use strict;
use warnings;
use Astro::Hipparcos;

# An example of drawing the data in the Hipparcos catalog
# (or any subset) into a 2D plot using a Hammer projection.
#
# Have a look at draw_projection.pl instead. That's the good
# version. This is the limited, manual one.
#
# Usage: draw_hammer_proj.pl datafile.dat
# Will produce hippa.eps
#
# Note: This example requires several extra modules:
# - PostScript::Simple
# - Astro::MapProjection
# - Astro::Nova
#
# You can find the full EPS output of this program at
#   http://steffen-mueller.net/hipparcos/hipparcos.eps.bz2
# Warning: It's a 2MB archive containing a 13MB EPS

use constant PI      => atan2(1,0)*2;
use constant DEG2RAD => PI/180;
use constant RAD2DEG => 180/PI;

use PostScript::Simple;

# this will convert from equatorial coordinates to galactic coordinates
use Astro::Nova qw/get_gal_from_equ/;
# this will go from galactic longitude/latitude to 2D coords
use Astro::MapProjection qw/hammer_projection/;


# open the input file
my $catalog_file = shift;
$catalog_file = "hip_main.dat" if not defined $catalog_file;
my $catalog = Astro::Hipparcos->new($catalog_file);

# create the image
my ($xsize, $ysize) = (200, 200);
my $ps = PostScript::Simple->new(
  eps    => 1,
  units  => "mm",
  xsize  => $xsize,
  ysize  => $ysize,
  colour => 1,
  clip   => 1,
);

# background
$ps->setcolour(0, 0, 0);
$ps->box({filled=>1}, 0, 0, $xsize, $ysize);


my $min_magnitude = -1.441; # determined with a "grep" over the catalog
my $max_magnitude = 14.08;
my $i = 0;
while (defined(my $record = $catalog->get_record())) {
  #last if $i++ == 10000;
  my $mag = $record->get_Vmag();

  # fetch color from color scale (see below)
  my $color = color($mag, $min_magnitude, $max_magnitude);
  $ps->setcolour(map {255*$_} @$color);

  # convert to galactic coords
  my $equ_posn = Astro::Nova::EquPosn->new(ra => $record->get_RAdeg, dec => $record->get_DEdeg);
  my $gal_posn = get_gal_from_equ($equ_posn);
  my ($b, $l) = ($gal_posn->get_b, $gal_posn->get_l);
  $l -= 360 while $l > 180;

  #print "$b $l\n";
  
  # project to x/y for plotting
  my ($x, $y) = hammer_projection($b*DEG2RAD, $l*DEG2RAD);

  # still have to shift the origin to the lower left (ps_coord_trafo)
  $ps->circle({filled=>1}, ps_coord_trafo($x, $y), 0.1);
}

plot_axes($ps);

# draw scale
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
  $ps->setcolour(map {255*$_} @$color);
  $ps->box({filled=>1}, $x, $scale_miny, $x+$scale_step*1.1, $scale_maxy);
}

$ps->output("hippa.eps");

# plots the grey axes into the image
sub plot_axes {
  my $ps = shift;

  $ps->setcolour(100,100,100); # grey
  $ps->setlinewidth(0.05);
  # plot longitude axes
  for (my $long = -180*DEG2RAD; $long <= 180.001*DEG2RAD; $long += 45*DEG2RAD) {
    my $first = 1;
    for (my $lat = -90*DEG2RAD; $lat <= 90.001*DEG2RAD; $lat += 3.0*DEG2RAD) {
      my ($x, $y) = hammer_projection($lat, $long);
      ($x, $y) = ps_coord_trafo($x, $y);
      if ($first) {
        $ps->line($x, $y, $x, $y);
        $first = 0;
      }
      else {
        $ps->linextend($x, $y);
      }
    }
  }

  # plot lat axes
  for (my $lat = -90*DEG2RAD; $lat <= 90*DEG2RAD; $lat += 10*DEG2RAD) {
    my $first = 1;
    for (my $long = -180*DEG2RAD; $long <= 180*DEG2RAD; $long += 5.0*DEG2RAD) {
      my ($x, $y) = hammer_projection($lat, $long);
      ($x, $y) = ps_coord_trafo($x, $y);
      if ($first) {
        $ps->line($x, $y, $x, $y);
        $first = 0;
      }
      else {
        $ps->linextend($x, $y);
      }
    }
  }
}

# convert the logical x/y coordinates with origin at center to
# screen/ps coordinates with origin at lower left
sub ps_coord_trafo {
 return(
   $_[0]*$xsize/6 + $xsize/2,
   $_[1]*$ysize/6 + $ysize/2,
 );
}


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
