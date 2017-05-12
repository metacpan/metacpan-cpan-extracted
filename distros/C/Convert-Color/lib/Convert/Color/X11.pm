#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2011 -- leonerd@leonerd.org.uk

package Convert::Color::X11;

use strict;
use warnings;
use base qw( Convert::Color::RGB8 );

__PACKAGE__->register_color_space( 'x11' );

use Carp;

our $VERSION = '0.11';

# Different systems put it in different places. We'll try all of them taking
# the first we find

our @RGB_TXT = (
   '/etc/X11/rgb.txt',
   '/usr/share/X11/rgb.txt',
   '/usr/X11R6/lib/X11/rgb.txt',
);

=head1 NAME

C<Convert::Color::X11> - named lookup of colors from X11's F<rgb.txt>

=head1 SYNOPSIS

Directly:

 use Convert::Color::X11;

 my $red = Convert::Color::X11->new( 'red' );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'x11:cyan' );

=head1 DESCRIPTION

This subclass of L<Convert::Color::RGB8> provides lookup of color names
provided by X11's F<rgb.txt> file.

=cut

my @x11_color_names; # To preserve order
my $x11_colors;

sub _load_x11_colors
{
   my $rgbtxt;

   foreach ( @RGB_TXT ) {
      -f $_ or next;

      open( $rgbtxt, "<", $_ ) or die "Cannot read $_ - $!\n";
      last;
   }

   $rgbtxt or die "No rgb.txt file was found\n";

   local $_;

   while( <$rgbtxt> ) {
      s/^\s+//; # trim leading WS
      next if m/^!/; # comment

      my ( $r, $g, $b, $name ) = m/^(\d+)\s+(\d+)\s+(\d+)\s+(.*)$/ or next;

      $x11_colors->{$name} = [ $r, $g, $b ];
      push @x11_color_names, $name;
   }
}

=head1 CLASS METHODS

=cut

=head2 @colors = Convert::Color::X11->colors

Returns a list of the defined color names, in the order they were found in the
F<rgb.txt> file.

=head2 $num_colors = Convert::Color::X11->colors

When called in scalar context, this method returns the count of the number of
defined colors.

=cut

sub colors
{
   my $class = shift;

   $x11_colors or _load_x11_colors;

   return @x11_color_names;
}

__PACKAGE__->register_palette(
   enumerate => sub {
      my $class = shift;
      map { $class->new( $_ ) } $class->colors;
   },
);

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::X11->new( $name )

Returns a new object to represent the named color.

=cut

sub new
{
   my $class = shift;

   if( @_ == 1 ) {
      my $name = $_[0];

      $x11_colors or _load_x11_colors;

      my $color = $x11_colors->{$name} or
         croak "No such X11 color named '$name'";

      my $self = $class->SUPER::new( @$color );

      $self->[3] = $name;

      return $self;
   }
   else {
      croak "usage: Convert::Color::X11->new( NAME )";
   }
}

=head1 METHODS

=cut

=head2 $name = $color->name

The name of the VGA color.

=cut

sub name
{
   my $self = shift;
   return $self->[3];
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
