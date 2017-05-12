#!/usr/bin/perl
use strict;
use warnings;
use Compass::Bearing;

=head1 NAME

Compass-Bearing-example.pl - Example for Compass::Bearing

=cut

my $cb=Compass::Bearing->new;

foreach my $type (1,2,3) {
  printf "Bearing Type: %s digit.\n\n", $cb->set($type);
  foreach (-5..40) {
    my $a=$_*10;
    printf "Angle: %s => %s\n", $a => $cb->bearing($a);
  }
  print "\n";
}

__END__

=head1 Sample Output

  Bearing Type: 1 digit.

  Angle: -50 => W
  Angle: -40 => N
  Angle: -30 => N
  Angle: -20 => N
  Angle: -10 => N
  Angle: 0 => N
  Angle: 10 => N
  Angle: 20 => N
  Angle: 30 => N
  Angle: 40 => N
  Angle: 50 => E
  Angle: 60 => E
  Angle: 70 => E
  Angle: 80 => E
  Angle: 90 => E
  Angle: 100 => E
  Angle: 110 => E
  Angle: 120 => E
  Angle: 130 => E
  Angle: 140 => S
  Angle: 150 => S
  Angle: 160 => S
  Angle: 170 => S
  Angle: 180 => S
  Angle: 190 => S
  Angle: 200 => S
  Angle: 210 => S
  Angle: 220 => S
  Angle: 230 => W
  Angle: 240 => W
  Angle: 250 => W
  Angle: 260 => W
  Angle: 270 => W
  Angle: 280 => W
  Angle: 290 => W
  Angle: 300 => W
  Angle: 310 => W
  Angle: 320 => N
  Angle: 330 => N
  Angle: 340 => N
  Angle: 350 => N
  Angle: 360 => N
  Angle: 370 => N
  Angle: 380 => N
  Angle: 390 => N
  Angle: 400 => N

  Bearing Type: 2 digit.

  Angle: -50 => NW
  Angle: -40 => NW
  Angle: -30 => NW
  Angle: -20 => N
  Angle: -10 => N
  Angle: 0 => N
  Angle: 10 => N
  Angle: 20 => N
  Angle: 30 => NE
  Angle: 40 => NE
  Angle: 50 => NE
  Angle: 60 => NE
  Angle: 70 => E
  Angle: 80 => E
  Angle: 90 => E
  Angle: 100 => E
  Angle: 110 => E
  Angle: 120 => SE
  Angle: 130 => SE
  Angle: 140 => SE
  Angle: 150 => SE
  Angle: 160 => S
  Angle: 170 => S
  Angle: 180 => S
  Angle: 190 => S
  Angle: 200 => S
  Angle: 210 => SW
  Angle: 220 => SW
  Angle: 230 => SW
  Angle: 240 => SW
  Angle: 250 => W
  Angle: 260 => W
  Angle: 270 => W
  Angle: 280 => W
  Angle: 290 => W
  Angle: 300 => NW
  Angle: 310 => NW
  Angle: 320 => NW
  Angle: 330 => NW
  Angle: 340 => N
  Angle: 350 => N
  Angle: 360 => N
  Angle: 370 => N
  Angle: 380 => N
  Angle: 390 => NE
  Angle: 400 => NE

  Bearing Type: 3 digit.

  Angle: -50 => NW
  Angle: -40 => NW
  Angle: -30 => NNW
  Angle: -20 => NNW
  Angle: -10 => N
  Angle: 0 => N
  Angle: 10 => N
  Angle: 20 => NNE
  Angle: 30 => NNE
  Angle: 40 => NE
  Angle: 50 => NE
  Angle: 60 => ENE
  Angle: 70 => ENE
  Angle: 80 => E
  Angle: 90 => E
  Angle: 100 => E
  Angle: 110 => ESE
  Angle: 120 => ESE
  Angle: 130 => SE
  Angle: 140 => SE
  Angle: 150 => SSE
  Angle: 160 => SSE
  Angle: 170 => S
  Angle: 180 => S
  Angle: 190 => S
  Angle: 200 => SSW
  Angle: 210 => SSW
  Angle: 220 => SW
  Angle: 230 => SW
  Angle: 240 => WSW
  Angle: 250 => WSW
  Angle: 260 => W
  Angle: 270 => W
  Angle: 280 => W
  Angle: 290 => WNW
  Angle: 300 => WNW
  Angle: 310 => NW
  Angle: 320 => NW
  Angle: 330 => NNW
  Angle: 340 => NNW
  Angle: 350 => N
  Angle: 360 => N
  Angle: 370 => N
  Angle: 380 => NNE
  Angle: 390 => NNE
  Angle: 400 => NE

=cut
