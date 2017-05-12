# -*- CPerl -*-

use lib 'lib/';
use strict;

use Test::More tests=>294;
use Barcode::Code128 qw(FNC1);


 SKIP: {
     eval { require GD; };

     skip "GD not installed - skipping test", 294 if ($@);
     skip "GD version >= 1.20 and < 2.18 - use png", 294
         unless ($GD::VERSION < 1.20 or $GD::VERSION >= 2.18);

     my $code = new Barcode::Code128;

     my $test = $code->gif("CODE 128");

     my $good = GD::Image->newFromGif('t/code128.gif');
     my $image = GD::Image->newFromGifData($test);

     for (my $x=0; $x< $image->width; $x++) {

         my $y = int($image->height()/2);

         my ($r, $g, $b) = $image->rgb($image->getPixel($x, $y));
         my ($R, $G, $B) = $good->rgb($good->getPixel($x, $y));

         ok($r == $R && $g == $G && $b == $B, "color test $x");


     }
}
