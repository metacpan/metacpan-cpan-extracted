#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package Convert::Color::RGB16;

use strict;
use warnings;
use base qw( Convert::Color );

__PACKAGE__->register_color_space( 'rgb16' );

use Carp;

our $VERSION = '0.11';

=head1 NAME

C<Convert::Color::RGB16> - a color value represented as red/green/blue in
16-bit integers

=head1 SYNOPSIS

Directly:

 use Convert::Color::RGB16;

 my $red = Convert::Color::RGB16->new( 65535, 0, 0 );

 # Can also parse strings
 my $pink = Convert::Color::RGB16->new( '65535,49152,49152' );

 # or
 $pink = Convert::Color::RGB16->new( 'ffffc000c000' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'rgb16:0,65535,65535' );

=head1 DESCRIPTION

Objects in this class represent a color in RGB space, as a set of three
integer values in the range 0 to 65535; i.e. as 16 bits.

For representations using floating point values, see L<Convert::Color::RGB>.
For representations using 8-bit integers, see L<Convert::Color::RGB8>.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::RGB16->new( $red, $green, $blue )

Returns a new object to represent the set of values given. These values should
be integers between 0 and 65535. Values outside of this range will be clamped.

=head2 $color = Convert::Color::RGB16->new( $string )

Parses C<$string> for values, and construct a new object similar to the above
three-argument form. The string should be in the form

 red,green,blue

containing the three integer values in decimal notation. It can also be given
in the form of a hex encoded string, such as would be returned by the
C<rgb16_hex> method:

 rrrrggggbbbb

=cut

sub new
{
   my $class = shift;

   my ( $r, $g, $b );

   if( @_ == 1 ) {
      local $_ = $_[0];
      if( m/^([[:xdigit:]]{4})([[:xdigit:]]{4})([[:xdigit:]]{4})$/ ) {
         ( $r, $g, $b ) = ( hex( $1 ), hex( $2 ), hex( $3 ) );
      }
      elsif( m/^(\d+),(\d+),(\d+)$/ ) {
         ( $r, $g, $b ) = ( $1, $2, $3 );
      }
      else {
         croak "Unrecognised RGB16 string spec '$_'";
      }
   }
   elsif( @_ == 3 ) {
      ( $r, $g, $b ) = map int, @_;
   }
   else {
      croak "usage: Convert::Color::RGB16->new( SPEC ) or ->new( R, G, B )";
   }

   # Clamp to the range [0,0xffff]
   map { $_ < 0 and $_ = 0; $_ > 0xffff and $_ = 0xffff } ( $r, $g, $b );

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

   return map { $_ / 0xffff } @{$self}[0..2];
}

sub new_rgb
{
   my $class = shift;

   return $class->new( map { $_ * 0xffff } @_ );
}

=head2 ( $red, $green, $blue ) = $color->rgb16

Returns the individual red, green and blue color components of the color
value in RGB16 space.

=cut

sub rgb16
{
   my $self = shift;
   return $self->red, $self->green, $self->blue;
}

=head2 $str = $color->hex

Returns a string representation of the color components in the RGB16 space, in
a convenient C<RRRRGGGGBBBB> hex string.

=cut

sub hex :method
{
   my $self = shift;
   sprintf "%04x%04x%04x", $self->rgb16;
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

   my ( $rA, $gA, $bA ) = $self->rgb16;
   my ( $rB, $gB, $bB ) = $other->as_rgb16->rgb16;

   # Add 0.5 for rounding
   return __PACKAGE__->new(
      $rA * $alphaP + $rB * $alpha + 0.5,
      $gA * $alphaP + $gB * $alpha + 0.5,
      $bA * $alphaP + $bB * $alpha + 0.5,
   );
}

=head2 $mix = $color->alpha16_blend( $other, [ $alpha ] )

Similar to C<alpha_blend> but works with integer arithmetic. C<$alpha> should
be an integer in the range 0 to 65535.

=cut

sub alpha16_blend
{
   my $self = shift;
   my ( $other, $alpha ) = @_;

   $alpha = 0x7fff unless defined $alpha;

   $alpha = 0 if $alpha < 0;
   $alpha = 0xffff if $alpha > 0xffff;
   $alpha = int $alpha;

   my $alphaP = 0xffff - $alpha;

   my ( $rA, $gA, $bA ) = $self->rgb16;
   my ( $rB, $gB, $bB ) = $other->as_rgb16->rgb16;

   return __PACKAGE__->new(
      ( $rA * $alphaP + $rB * $alpha ) / 0xffff,
      ( $gA * $alphaP + $gB * $alpha ) / 0xffff,
      ( $bA * $alphaP + $bB * $alpha ) / 0xffff,
   );
}

=head2 $measure = $color->dst_rgb16( $other )

Return a measure of the distance between the two colors. This is the
unweighted Euclidean distance of the three color components. Two identical
colors will have a measure of 0, pure black and pure white have a distance of
1, and all others will lie somewhere inbetween.

=cut

sub dst_rgb16
{
   my $self = shift;
   my ( $other ) = @_;

   return sqrt( $self->dst_rgb16_cheap( $other ) ) / sqrt(3*65535*65535);
}

=head2 $measure = $color->dst_rgb16_cheap( $other )

Return a measure of the distance between the two colors. This is the sum of
the squares of the differences of each of the color components. This is part
of the value used to calculate C<dst_rgb16>, but since it involves no square
root it will be cheaper to calculate, for use in cases where only the relative
values matter, such as when picking the "best match" out of a set of colors.
It ranges between 0 for identical colours and 3*(65535^2) for the distance between
pure black and pure white.

=cut

sub dst_rgb16_cheap
{
   my $self = shift;
   my ( $other ) = @_;

   my ( $rA, $gA, $bA ) = $self->rgb16;
   my ( $rB, $gB, $bB ) = $other->as_rgb16->rgb16;

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
