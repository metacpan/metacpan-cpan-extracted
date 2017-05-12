#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2013 -- leonerd@leonerd.org.uk

package Convert::Color::HSL;

use strict;
use warnings;
use base qw( Convert::Color::HueChromaBased );

__PACKAGE__->register_color_space( 'hsl' );

use Carp;

our $VERSION = '0.11';

=head1 NAME

C<Convert::Color::HSL> - a color value represented as hue/saturation/lightness

=head1 SYNOPSIS

Directly:

 use Convert::Color::HSL;

 my $red = Convert::Color::HSL->new( 0, 1, 0.5 );

 # Can also parse strings
 my $pink = Convert::Color::HSL->new( '0,1,0.8' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'hsl:300,1,0.5' );

=head1 DESCRIPTION

Objects in this class represent a color in HSL space, as a set of three
floating-point values. Hue is stored as a value in degrees, in the range
0 to 360 (exclusive). Saturation and lightness are in the range 0 to 1.

This color space may be considered as a cylinder, of height and radius 1. Hue
represents the position of the color as the angle around the axis, the
saturation as the distance from the axis, and the lightness the height above
the base. In this shape, the entire base of the cylinder is pure black, the
axis through the centre represents the range of greys, and the entire top of
the cylinder is pure white. The circumference of the circular cross-section
midway along the axis contains the pure-saturated color wheel.

Because both surfaces of this cylinder contain pure black or white discs, a
closely-related color space can be created by reshaping the cylinder into a
bi-cone such that the top and bottom of the cylinder become single points. The
radius from the axis of this shape is called the chroma (though this is a
different definition of "chroma" than that used by CIE).

While the components of this space are called Hue-Chroma-Lightness, it should
not be confused with the similarly-named Hue-Chroma-Luminance (HCL) space.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::HSL->new( $hue, $saturation, $lightness )

Returns a new object to represent the set of values given. The hue should be
in the range 0 to 360 (exclusive), and saturation and lightness should be
between 0 and 1. Values outside of these ranges will be clamped.

=head2 $color = Convert::Color::HSL->new( $string )

Parses C<$string> for values, and construct a new object similar to the above
three-argument form. The string should be in the form

 hue,saturation,lightnes

containing the three floating-point values in decimal notation.

=cut

sub new
{
   my $class = shift;

   my ( $h, $s, $l );

   if( @_ == 1 ) {
      local $_ = $_[0];
      if( m/^(\d+(?:\.\d+)?),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?)$/ ) {
         ( $h, $s, $l ) = ( $1, $2, $3 );
      }
      else {
         croak "Unrecognised HSL string spec '$_'";
      }
   }
   elsif( @_ == 3 ) {
      ( $h, $s, $l ) = @_;
   }
   else {
      croak "usage: Convert::Color::HSL->new( SPEC ) or ->new( H, S, L )";
   }

   # Clamp
   map { $_ < 0 and $_ = 0; $_ > 1 and $_ = 1 } ( $s, $l );

   # Fit to range [0,360)
   $h += 360 while $h < 0;
   $h -= 360 while $h >= 360;

   return bless [ $h, $s, $l ], $class;
}

=head1 METHODS

=cut

=head2 $h = $color->hue

=head2 $s = $color->saturation

=head2 $v = $color->lightness

Accessors for the three components of the color.

=cut

# Simple accessors
sub hue        { shift->[0] }
sub saturation { shift->[1] }
sub lightness  { shift->[2] }

=head2 $c = $color->chroma

Returns the derived property of "chroma", which maps the color space onto a
bicone instead of a cylinder. This more closely measures the intuitive concept
of how "colorful" the color is than the saturation value and is useful for
distance calculations.

=cut

sub chroma
{
   my $self = shift;
   my ( undef, $s, $l ) = $self->hsl;

   if( $l > 0.5 ) {
      # upper bicone
      return 2 * $s * ( $l - 1 );
   }
   else {
      # lower bicone
      return 2 * $s * $l;
   }
}

=head2 ( $hue, $saturation, $lightness ) = $color->hsl

Returns the individual hue, saturation and lightness components of the color
value.

=cut

sub hsl
{
   my $self = shift;
   return @$self;
}

# Conversions
sub rgb
{
   my $self = shift;

   # See also
   #  http://en.wikipedia.org/wiki/HSV_color_space

   my ( $h, $s, $l ) = $self->hsl;

   my $q = $l < 0.5 ? $l * ( 1 + $s )
                    : $l + $s - ( $l * $s );

   my $p = 2 * $l - $q;

   # Modify the algorithm slightly, so we scale this up by 6
   my $hk = $h / 60;

   my $tr = $hk + 2;
   my $tg = $hk;
   my $tb = $hk - 2;

   map {
      $_ += 6 while $_ < 0;
      $_ -= 6 while $_ > 6;
   } ( $tr, $tg, $tb );

   return map {
      $_ < 1 ? $p + ( ( $q - $p ) * $_ ) :
      $_ < 3 ? $q :
      $_ < 4 ? $p + ( ( $q - $p ) * ( 4 - $_ ) ) :
                 $p
   } ( $tr, $tg, $tb );
}

sub new_rgb
{
   my $class = shift;
   my ( $r, $g, $b ) = @_;

   my ( $hue, $min, $max ) = $class->_hue_min_max( $r, $g, $b );

   my $l = ( $max + $min ) / 2;

   my $s = $min == $max ? 0 :
           $l <= 1/2    ? ( $max - $min ) / ( 2 * $l ) :
                          ( $max - $min ) / ( 2 - 2 * $l );

   return $class->new( $hue, $s, $l );
}

=head2 $measure = $color->dst_hsl( $other )

Returns a measure of the distance between the two colors. This is the
Euclidean distance between the two colors as points in the chroma-adjusted
cone space.

=cut

sub dst_hsl
{
   my $self = shift;
   my ( $other ) = @_;

   # ... / sqrt(4)
   return sqrt( $self->dst_hsl_cheap( $other ) ) / 2;
}

=head2 $measure = $color->dst_hsl_cheap( $other )

Returns a measure of the distance between the two colors. This is used in the
calculation of C<dst_hsl> but since it omits the final square-root and scaling
it is cheaper to calculate, for use in cases where only the relative values
matter, such as when picking the "best match" out of a set of colors. It
ranges between 0 for identical colors and 4 for the distance between
complementary pure-saturated colors.

=cut

sub dst_hsl_cheap
{
   my $self = shift;
   my ( $other ) = @_;

   my $dl = $self->lightness - $other->lightness;

   return $self->_huechroma_dst_squ( $other ) + $dl*$dl;
}

=head1 SEE ALSO

=over 4

=item *

L<Convert::Color> - color space conversions

=item *

L<Convert::Color::RGB> - a color value represented as red/green/blue

=item *

L<http://en.wikipedia.org/wiki/HSL_and_HSV> - HSL and HSV on Wikipedia

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
