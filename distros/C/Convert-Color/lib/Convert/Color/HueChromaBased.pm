#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package # hide from CPAN
   Convert::Color::HueChromaBased;

use strict;
use warnings;
use base qw( Convert::Color );

# For converting degrees to radians
#   atan2(1,0) == PI/2
use constant PIover180 => atan2(1,0) / 90;

# No space name since we're not a complete space

use List::Util qw( max min );

# HSV and HSL are related, using some common elements.
# See also
#  http://en.wikipedia.org/wiki/HSV_color_space

sub _hue_min_max
{
   my $class = shift;
   my ( $r, $g, $b ) = @_;

   my $max = max $r, $g, $b;
   my $min = min $r, $g, $b;

   my $hue;

   if( $max == $min ) {
      $hue = 0;
   }
   elsif( $max == $r ) {
      $hue = 60 * ( $g - $b ) / ( $max - $min );
   }
   elsif( $max == $g ) {
      $hue = 60 * ( $b - $r ) / ( $max - $min ) + 120;
   }
   elsif( $max == $b ) {
      $hue = 60 * ( $r - $g ) / ( $max - $min ) + 240;
   }

   return ( $hue, $min, $max );
}

# Useful for distance calculations - calculates the square of the distance
# between two points in polar space
sub _huechroma_dst_squ
{
   my ( $col1, $col2 ) = @_;

   my $r1 = $col1->chroma;
   my $r2 = $col2->chroma;

   my $dhue = $col1->hue - $col2->hue;

   # Square of polar distance
   return $r1*$r1 + $r2*$r2 - 2*$r1*$r2*cos( $dhue * PIover180 );
}

0x55AA;
