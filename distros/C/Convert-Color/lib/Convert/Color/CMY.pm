#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk

package Convert::Color::CMY;

use strict;
use warnings;
use base qw( Convert::Color );

__PACKAGE__->register_color_space( 'cmy' );

use Carp;

our $VERSION = '0.11';

=head1 NAME

C<Convert::Color::CMY> - a color value represented as cyan/magenta/yellow

=head1 SYNOPSIS

Directly:

 use Convert::Color::CMY;

 my $red = Convert::Color::CMY->new( 0, 1, 1 );

 # Can also parse strings
 my $pink = Convert::Color::CMY->new( '0,0.3,0.3' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'cmy:1,0,0' );

=head1 DESCRIPTION

Objects in this class represent a color in CMY space, as a set of three
floating-point values in the range 0 to 1.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::CMY->new( $cyan, $magenta, $yellow )

Returns a new object to represent the set of values given. These values should
be floating-point numbers between 0 and 1. Values outside of this range will
be clamped.

=head2 $color = Convert::Color::CMY->new( $string )

Parses C<$string> for values, and construct a new object similar to the above
three-argument form. The string should be in the form

 cyan,magenta,yellow

containing the three floating-point values in decimal notation.

=cut

sub new
{
   my $class = shift;

   my ( $c, $m, $y );

   if( @_ == 1 ) {
      local $_ = $_[0];
      if( m/^(\d+(?:\.\d+)?),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?)$/ ) {
         ( $c, $m, $y ) = ( $1, $2, $3 );
      }
      else {
         croak "Unrecognised CMY string spec '$_'";
      }
   }
   elsif( @_ == 3 ) {
      ( $c, $m, $y ) = @_;
   }
   else {
      croak "usage: Convert::Color::CMY->new( SPEC ) or ->new( C, M, Y )";
   }

   # Clamp
   map { $_ < 0 and $_ = 0; $_ > 1 and $_ = 1 } ( $c, $m, $y );

   return bless [ $c, $m, $y ], $class;
}

=head1 METHODS

=cut

=head2 $c = $color->cyan

=head2 $m = $color->magenta

=head2 $y = $color->yellow

Accessors for the three components of the color.

=cut

# Simple accessors
sub cyan    { shift->[0] }
sub magenta { shift->[1] }
sub yellow  { shift->[2] }

=head2 ( $cyan, $magenta, $yellow ) = $color->cmy

Returns the individual cyan, magenta and yellow color components of the color
value.

=cut

sub cmy
{
   my $self = shift;
   return @$self;
}

# Conversions
sub rgb
{
   my $self = shift;

   return 1 - $self->cyan, 1 - $self->magenta, 1 - $self->yellow;
}

sub new_rgb
{
   my $class = shift;
   my ( $r, $g, $b ) = @_;

   $class->new( 1 - $r, 1 - $g, 1 - $b );
}

=head1 SEE ALSO

=over 4

=item *

L<Convert::Color> - color space conversions

=item *

L<Convert::Color::RGB> - a color value represented as red/green/blue

=item *

L<Convert::Color::CMYK> - a color value represented as cyan/magenta/yellow/key

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
