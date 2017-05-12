# -*- CPerl -*-
#
#  test script for generating png files from Barcode::Code128
#
#  Make sure the module loads correctly - if GD is less than 1.20, skip tests
#
#  Lukas Mueller <lam87@cornell.edu>, June 2012

use strict;

use Test::More tests=>294;
use Barcode::Code128 qw(FNC1);

SKIP:
{


     eval { require GD; };

     skip "GD not installed - skipping test", 294 if ($@);

     skip "GD version < 1.20 - no png support", 294 unless $GD::VERSION > 1.20;

     my $code = new Barcode::Code128;

     my $test = $code->png("CODE 128");

     my $good = GD::Image->newFromPng('t/code128.png');
     my $image = GD::Image->newFromPngData($test);

     for (my $x=0; $x< $image->width; $x++)
     {


          my $y = int($image->height()/2);

           my ($r, $g, $b) = $image->rgb($image->getPixel($x, $y));
           my ($R, $G, $B) = $good->rgb($good->getPixel($x, $y));

           ok($r == $R && $g == $G && $b == $B, "color test $x");
      }

 }





#
