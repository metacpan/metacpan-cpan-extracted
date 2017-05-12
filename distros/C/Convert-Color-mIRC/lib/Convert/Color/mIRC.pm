#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Convert::Color::mIRC;

use strict;
use warnings;
use base qw( Convert::Color::RGB8 );

use Carp;

__PACKAGE__->register_color_space( 'mirc' );

our $VERSION = '0.01';

=head1 NAME

C<Convert::Color::XTerm> - indexed colors used by mIRC

=head1 SYNOPSIS

Directly:

 use Convert::Color::mIRC;

 my $red = Convert::Color::mIRC->new( 3 );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'mirc:11' )

=head1 DESCRIPTION

This subclass of L<Convert::Color::RGB8> provides lookup of the colours that
F<mIRC> uses by default. Note that of course the module is not intelligent
enough to be able to parse mIRC config, or know what palettes users are
actually using, and thus it provides only an approximation of the likely
behaviour of clients.

The palette implemented consists of 16 colours, described as:

 0      1           2    3     4          5     6      7
 white  black       blue green red        brown purple orange

 8      9           10   11    12         13    14     15
 yellow light-green teal cyan  light-blue pink  grey   silver

=cut

my @color;

sub _init_colors
{
   my $idx = 0;
   while( <DATA> ) {
      chomp;
      my $c = __PACKAGE__->SUPER::new( $_ );
      $c->[3] = $idx++;

      push @color, $c;
   }
}

__PACKAGE__->register_palette(
   enumerate_once => sub {
      @color or _init_colors;
      @color
   },
);

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::mIRC->new( $index )

Returns a new object to represent the color at that index.

=cut

# TODO: Surely we can move this logic into Convert::Color base somehow...
sub new
{
   my $class = shift;
   croak "usage: Convert::Color::mIRC->new( INDEX )" unless @_ == 1;
   my ( $index ) = @_;

   @color or _init_colors;

   $index >= 0 and $index < @color or
      croak "No such mIRC color at index '$index'";

   return $color[$index];
}

=head1 METHODS

=cut

=head2 $index = $color->index

The index of the mIRC color.

=cut

sub index
{
   my $self = shift;
   return $self->[3];
}

=head1 TODO

=over 4

=item *

Find out if the embedded colour palette really is the default mIRC one, or
update it if not. Patches welcome ;)

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

# This palette taken from
#   http://www.mish-script.de/help/mircini/colors.htm

__DATA__
ffffff
000000
00007f
009300
ff0000
7f0000
9c009c
fc7f00
ffff00
00fc00
009393
00ffff
0000fc
ff00ff
7f7f7f
d2d2d2
