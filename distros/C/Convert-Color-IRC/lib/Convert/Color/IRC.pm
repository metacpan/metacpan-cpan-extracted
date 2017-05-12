package Convert::Color::IRC;

use strict;
use base qw( Convert::Color::RGB8 );

use constant COLOR_SPACE => 'irc';

use Carp;

our $VERSION = '0.06';

=head1 NAME

C<Convert::Color::IRC> - named lookup for the basic IRC colors

=head1 SYNOPSIS

Directly:

 use Convert::Color::IRC;

 my $red = Convert::Color::IRC->new( 'red' );

 # Can also use index
 my $black = Convert::Color::IRC->new( 1 );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'irc:cyan' );

=head1 DESCRIPTION

This subclass of L<Convert::Color::RG8B> provides predefined colors for the 16
basic IRC colors. Their names are

 white
 black
 blue
 green
 red
 brown
 purple
 orange
 yellow
 light green
 cyan
 light cyan
 light blue
 pink
 gray
 light gray

They may be looked up either by name, or by numerical index within this list.

=cut

my %irc_colors = (
   white         => [ 255, 255, 255 ],
   black         => [ 0,   0,   0   ],
   blue          => [ 0,   0,   255 ],
   green         => [ 0,   255, 0   ],
   red           => [ 255, 0,   0   ],
   brown         => [ 165, 42,  42  ],
   purple        => [ 128, 0,   128 ],
   orange        => [ 255, 165, 0   ],
   yellow        => [ 255, 255, 0   ],
   'light green' => [ 144, 238, 144 ],
   cyan          => [ 0,   255, 255 ],
   'light cyan'  => [ 224, 255, 255 ],
   'light blue'  => [ 173, 216, 230 ],
   pink          => [ 255, 192, 203 ],
   gray          => [ 128, 128, 128 ],
   'light gray'  => [ 211, 211, 211 ]
);

# Also indexes
my @irc_colors = (
   'white', 'black', 'blue', 'green',
   'red', 'brown', 'purple', 'orange',
   'yellow', 'light green', 'cyan', 'light cyan',
   'light blue', 'pink', 'gray', 'light gray'
);

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::IRC->new( $name )

Returns a new object to represent the named color.

=head2 $color = Convert::Color::IRC->new( $index )

Returns a new object to represent the color at the given index.

=cut

sub new
{
   my $class = shift;
   my $name = shift;
   
   if( defined $name ) {
      if( $name =~ m/^\d{1,2}$/ ) {
         $name >= 0 and $name < @irc_colors or
            croak "No such IRC color at index $name";

         $name = $irc_colors[$name];
      }
      my $color = $irc_colors{$name} or
         croak "No such IRC color named '$name'";

      return $class->SUPER::new( @$color );
   }
   else {
      croak "usage: Convert::Color::IRC->new( NAME ) or ->new( INDEX )";
   }
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<Convert::Color> - color space conversions

=back

=head1 AUTHOR

Jason Felds E<lt>wolfman.ncsu2000@gmail.comE<gt>

=head1 ACKNOWLEDGMENTS

Paul Evans E<lt>leonerd@leonerd.org.ukE<gt> for setting up
the Convert::Color interface.
