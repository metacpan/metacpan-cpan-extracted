#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2011 -- leonerd@leonerd.org.uk

package Convert::Color::RGB;

use strict;
use warnings;
use base qw( Convert::Color );

__PACKAGE__->register_color_space( 'rgb' );

use Carp;

our $VERSION = '0.11';

=head1 NAME

C<Convert::Color::RGB> - a color value represented as red/green/blue

=head1 SYNOPSIS

Directly:

 use Convert::Color::RGB;

 my $red = Convert::Color::RGB->new( 1, 0, 0 );

 # Can also parse strings
 my $pink = Convert::Color::RGB->new( '1,0.7,0.7' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'rgb:0,1,1' );

=head1 DESCRIPTION

Objects in this class represent a color in RGB space, as a set of three
floating-point values in the range 0 to 1.

For representations using 8- or 16-bit integers, see L<Convert::Color::RGB8>
and L<Convert::Color::RGB16>.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::RGB->new( $red, $green, $blue )

Returns a new object to represent the set of values given. These values should
be floating-point numbers between 0 and 1. Values outside of this range will
be clamped.

=head2 $color = Convert::Color::RGB->new( $string )

Parses C<$string> for values, and construct a new object similar to the above
three-argument form. The string should be in the form

 red,green,blue

containing the three floating-point values in decimal notation.

=cut

sub new
{
   my $class = shift;

   my ( $r, $g, $b );

   if( @_ == 1 ) {
      local $_ = $_[0];
      if( m/^(\d+(?:\.\d+)?),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?)$/ ) {
         ( $r, $g, $b ) = ( $1, $2, $3 );
      }
      else {
         croak "Unrecognised RGB string spec '$_'";
      }
   }
   elsif( @_ == 3 ) {
      ( $r, $g, $b ) = @_;
   }
   else {
      croak "usage: Convert::Color::RGB->new( SPEC ) or ->new( R, G, B )";
   }

   # Clamp to the range [0,1]
   map { $_ < 0 and $_ = 0; $_ > 1 and $_ = 1 } ( $r, $g, $b );

   return bless [ $r, $g, $b ], $class;
}

=head1 METHODS

=cut

=head2 $r = $color->red

=head2 $g = $color->green

=head2 $b = $color->blue

Accessors for the three components of the color.

=cut

# Simple accessors
sub red   { shift->[0] }
sub green { shift->[1] }
sub blue  { shift->[2] }

=head2 ( $red, $green, $blue ) = $color->rgb

Returns the individual red, green and blue color components of the color
value.

=cut

sub rgb
{
   my $self = shift;
   return @{$self}[0..2];
}

sub new_rgb
{
   my $class = shift;
   return $class->new( @_ );
}

=head2 $mix = $color->alpha_blend( $other, [ $alpha ] )

Return a new color which is a blended combination of the two passed into it.
The optional C<$alpha> parameter defines the mix ratio between the two colors,
defaulting to 0.5 if not defined. Values closer to 0 will blend more of
C<$color>, closer to 1 will blend more of C<$other>.

=cut

sub alpha_blend
{
   my $self = shift;
   my ( $other, $alpha ) = @_;

   $alpha = 0.5 unless defined $alpha;

   $alpha = 0 if $alpha < 0;
   $alpha = 1 if $alpha > 1;

   my $alphaP = 1 - $alpha;

   my ( $rA, $gA, $bA ) = $self->rgb;
   my ( $rB, $gB, $bB ) = $other->rgb;

   return __PACKAGE__->new(
      $rA * $alphaP + $rB * $alpha,
      $gA * $alphaP + $gB * $alpha,
      $bA * $alphaP + $bB * $alpha,
   );
}

=head2 $measure = $color->dst_rgb( $other )

Return a measure of the distance between the two colors. This is the
unweighted Euclidean distance of the three color components. Two identical
colors will have a measure of 0, pure black and pure white have a distance of
1, and all others will lie somewhere inbetween.

=cut

sub dst_rgb
{
   my $self = shift;
   my ( $other ) = @_;

   return sqrt( $self->dst_rgb_cheap( $other ) ) / sqrt(3);
}

=head2 $measure = $color->dst_rgb_cheap( $other )

Return a measure of the distance between the two colors. This is the sum of
the squares of the differences of each of the color components. This is part
of the value used to calculate C<dst_rgb>, but since it involves no square
root it will be cheaper to calculate, for use in cases where only the relative
values matter, such as when picking the "best match" out of a set of colors.
It ranges between 0 for identical colours and 3 for the distance between pure
black and pure white.

=cut

sub dst_rgb_cheap
{
   my $self = shift;
   my ( $other ) = @_;

   my ( $rA, $gA, $bA ) = $self->rgb;
   my ( $rB, $gB, $bB ) = $other->rgb;

   my $dr = $rA - $rB;
   my $dg = $gA - $gB;
   my $db = $bA - $bB;

   return $dr*$dr + $dg*$dg + $db*$db;
}

=head1 EXAMPLES

=head2 Generating Gradients

The C<alpha_blend> method can be used to generate a smooth gradient between
two colours.

 use Convert::Color;
 
 my $blue = Convert::Color->new("vga:blue");
 my $cyan = Convert::Color->new("vga:cyan");
 
 say $blue->alpha_blend( $cyan, $_/10 )->as_rgb8->hex for 0 .. 10

=head1 SEE ALSO

=over 4

=item *

L<Convert::Color> - color space conversions

=item *

L<Convert::Color::HSV> - a color value represented as hue/saturation/value

=item *

L<Convert::Color::HSL> - a color value represented as hue/saturation/lightness

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
