#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package Convert::Color::CMYK;

use strict;
use warnings;
use base qw( Convert::Color );

__PACKAGE__->register_color_space( 'cmyk' );

use List::Util qw( min );

use Carp;

our $VERSION = '0.11';

=head1 NAME

C<Convert::Color::CMYK> - a color value represented as cyan/magenta/yellow/key

=head1 SYNOPSIS

Directly:

 use Convert::Color::CMYK;

 my $red = Convert::Color::CMYK->new( 0, 1, 1, 0 );

 # Can also parse strings
 my $pink = Convert::Color::CMYK->new( '0,0.3,0.3,0' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'cmyk:1,0,0,0' );

=head1 DESCRIPTION

Objects in this class represent a color in CMYK space, as a set of four
floating-point values in the range 0 to 1.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::CMYK->new( $cyan, $magenta, $yellow, $key )

Returns a new object to represent the set of values given. These values should
be floating-point numbers between 0 and 1. Values outside of this range will
be clamped.

=head2 $color = Convert::Color::CMYK->new( $string )

Parses C<$string> for values, and construct a new object similar to the above
three-argument form. The string should be in the form

 cyan,magenta,yellow,key

containing the three floating-point values in decimal notation.

=cut

sub new
{
   my $class = shift;

   my ( $c, $m, $y, $k );

   if( @_ == 1 ) {
      local $_ = $_[0];
      if( m/^(\d+(?:\.\d+)?),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?)$/ ) {
         ( $c, $m, $y, $k ) = ( $1, $2, $3, $4 );
      }
      else {
         croak "Unrecognised CMYK string spec '$_'";
      }
   }
   elsif( @_ == 4 ) {
      ( $c, $m, $y, $k ) = @_;
   }
   else {
      croak "usage: Convert::Color::CMYK->new( SPEC ) or ->new( C, M, Y, K )";
   }

   # Clamp
   map { $_ < 0 and $_ = 0; $_ > 1 and $_ = 1 } ( $c, $m, $y, $k );

   return bless [ $c, $m, $y, $k ], $class;
}

=head1 METHODS

=cut

=head2 $c = $color->cyan

=head2 $m = $color->magenta

=head2 $y = $color->yellow

=head2 $k = $color->key

Accessors for the four components of the color.

=cut

# Simple accessors
sub cyan    { shift->[0] }
sub magenta { shift->[1] }
sub yellow  { shift->[2] }
sub key     { shift->[3] }

=head2 $k = $color->black

An alias to C<key>

=cut

*black = \&key; # alias

=head2 ( $cyan, $magenta, $yellow, $key ) = $color->cmyk

Returns the individual cyan, magenta, yellow and key components of the color
value.

=cut

sub cmyk
{
   my $self = shift;
   return @$self;
}

# Conversions

sub cmy
{
   my $self = shift;

   if( $self->key == 1 ) {
      # Pure black
      return ( 1, 1, 1 );
   }

   my $k = $self->key;
   my $w = 1 - $k;

   return ( ($self->cyan * $w) + $k, ($self->magenta * $w) + $k, ($self->yellow * $w) + $k );
}

sub rgb
{
   my $self = shift;
   my ( $c, $m, $y ) = $self->cmy;
   return ( 1 - $c, 1 - $m, 1 - $y );
}

sub new_cmy
{
   my $class = shift;
   my ( $c, $m, $y ) = @_;

   my $k = min( $c, $m, $y );

   if( $k == 1 ) {
      # Pure black
      return $class->new( 0, 0, 0, 1 );
   }
   else {
      # Rescale other components around key
      my $w = 1 - $k; # whiteness
      return $class->new( ($c - $k) / $w, ($m - $k) / $w, ($y - $k) / $w, $k );
   }
}

sub new_rgb
{
   my $class = shift;
   my ( $r, $g, $b ) = @_;

   return $class->new_cmy( 1-$r, 1-$g, 1-$b );
}

sub convert_to_cmy
{
   my $self = shift;
   require Convert::Color::CMY;
   return Convert::Color::CMY->new( $self->cmy );
}

sub new_from_cmy
{
   my $class = shift;
   my ( $cmy ) = @_;
   return $class->new_cmy( $cmy->cyan, $cmy->magenta, $cmy->yellow );
}

=head1 SEE ALSO

=over 4

=item *

L<Convert::Color> - color space conversions

=item *

L<Convert::Color::CMY> - a color value represented as cyan/magenta/yellow

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
