#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package Convert::Color::RGB8;

use strict;
use warnings;
use base qw( Convert::Color );

__PACKAGE__->register_color_space( 'rgb8' );

use Carp;

our $VERSION = '0.11';

=head1 NAME

C<Convert::Color::RGB8> - a color value represented as red/green/blue in 8-bit
integers

=head1 SYNOPSIS

Directly:

 use Convert::Color::RGB8;

 my $red = Convert::Color::RGB8->new( 255, 0, 0 );

 # Can also parse strings
 my $pink = Convert::Color::RGB8->new( '255,192,192' );

 # or
 $pink = Convert::Color::RGB8->new( 'ffc0c0' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'rgb8:0,255,255' );

=head1 DESCRIPTION

Objects in this class represent a color in RGB space, as a set of three
integer values in the range 0 to 255; i.e. as 8 bits.

For representations using floating point values, see L<Convert::Color::RGB>.
For representations using 16-bit integers, see L<Convert::Color::RGB16>.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::RGB8->new( $red, $green, $blue )

Returns a new object to represent the set of values given. These values should
be integers between 0 and 255. Values outside of this range will be clamped.

=head2 $color = Convert::Color::RGB8->new( $string )

Parses C<$string> for values, and construct a new object similar to the above
three-argument form. The string should be in the form

 red,green,blue

containing the three integer values in decimal notation. It can also be given
in the form of a hex encoded string, such as would be returned by the
C<rgb8_hex> method:

 rrggbb

=cut

sub new
{
   my $class = shift;

   my ( $r, $g, $b );

   if( @_ == 1 ) {
      local $_ = $_[0];
      if( m/^([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})$/ ) {
         ( $r, $g, $b ) = ( hex( $1 ), hex( $2 ), hex( $3 ) );
      }
      elsif( m/^(\d+),(\d+),(\d+)$/ ) {
         ( $r, $g, $b ) = ( $1, $2, $3 );
      }
      else {
         croak "Unrecognised RGB8 string spec '$_'";
      }
   }
   elsif( @_ == 3 ) {
      ( $r, $g, $b ) = map int, @_;
   }
   else {
      croak "usage: Convert::Color::RGB8->new( SPEC ) or ->new( R, G, B )";
   }

   # Clamp to the range [0,255]
   map { $_ < 0 and $_ = 0; $_ > 255 and $_ = 255 } ( $r, $g, $b );

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

# Conversions
sub rgb
{
   my $self = shift;

   return map { $_ / 255 } @{$self}[0..2];
}

sub new_rgb
{
   my $class = shift;

   return $class->new( map { $_ * 255 } @_ );
}

=head2 ( $red, $green, $blue ) = $color->rgb8

Returns the individual red, green and blue color components of the color
value in RGB8 space.

=cut

sub rgb8
{
   my $self = shift;
   return $self->red, $self->green, $self->blue;
}

=head2 $str = $color->hex

Returns a string representation of the color components in the RGB8 space, in
a convenient C<RRGGBB> hex string, likely to be useful HTML, or other similar
places.

=cut

sub hex :method
{
   my $self = shift;
   sprintf "%02x%02x%02x", $self->rgb8;
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

   my ( $rA, $gA, $bA ) = $self->rgb8;
   my ( $rB, $gB, $bB ) = $other->as_rgb8->rgb8;

   # Add 0.5 for rounding
   return __PACKAGE__->new(
      $rA * $alphaP + $rB * $alpha + 0.5,
      $gA * $alphaP + $gB * $alpha + 0.5,
      $bA * $alphaP + $bB * $alpha + 0.5,
   );
}

=head2 $mix = $color->alpha8_blend( $other, [ $alpha ] )

Similar to C<alpha_blend> but works with integer arithmetic. C<$alpha> should
be an integer in the range 0 to 255.

=cut

sub alpha8_blend
{
   my $self = shift;
   my ( $other, $alpha ) = @_;

   $alpha = 127 unless defined $alpha;

   $alpha = 0 if $alpha < 0;
   $alpha = 255 if $alpha > 255;
   $alpha = int $alpha;

   my $alphaP = 255 - $alpha;

   my ( $rA, $gA, $bA ) = $self->rgb8;
   my ( $rB, $gB, $bB ) = $other->as_rgb8->rgb8;

   return __PACKAGE__->new(
      ( $rA * $alphaP + $rB * $alpha ) / 255,
      ( $gA * $alphaP + $gB * $alpha ) / 255,
      ( $bA * $alphaP + $bB * $alpha ) / 255,
   );
}

=head2 $measure = $color->dst_rgb8( $other )

Return a measure of the distance between the two colors. This is the
unweighted Euclidean distance of the three color components. Two identical
colors will have a measure of 0, pure black and pure white have a distance of
1, and all others will lie somewhere inbetween.

=cut

sub dst_rgb8
{
   my $self = shift;
   my ( $other ) = @_;

   return sqrt( $self->dst_rgb8_cheap( $other ) ) / sqrt(3*255*255);
}

=head2 $measure = $color->dst_rgb8_cheap( $other )

Return a measure of the distance between the two colors. This is the sum of
the squares of the differences of each of the color components. This is part
of the value used to calculate C<dst_rgb8>, but since it involves no square
root it will be cheaper to calculate, for use in cases where only the relative
values matter, such as when picking the "best match" out of a set of colors.
It ranges between 0 for identical colours and 3*(255^2) for the distance between
pure black and pure white.

=cut

sub dst_rgb8_cheap
{
   my $self = shift;
   my ( $other ) = @_;

   my ( $rA, $gA, $bA ) = $self->rgb8;
   my ( $rB, $gB, $bB ) = $other->as_rgb8->rgb8;

   my $dr = $rA - $rB;
   my $dg = $gA - $gB;
   my $db = $bA - $bB;

   return $dr*$dr + $dg*$dg + $db*$db;
}

=head1 SEE ALSO

=over 4

=item *

L<Convert::Color> - color space conversions

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
