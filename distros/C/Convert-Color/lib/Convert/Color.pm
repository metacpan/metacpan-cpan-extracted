#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009-2013 -- leonerd@leonerd.org.uk

package Convert::Color;

use strict;
use warnings;

use Carp;

use List::UtilsBy qw( min_by );

use Module::Pluggable require => 0,
                      search_path => [ 'Convert::Color' ];
my @plugins = Convert::Color->plugins;

our $VERSION = '0.11';

=head1 NAME

C<Convert::Color> - color space conversions and named lookups

=head1 SYNOPSIS

 use Convert::Color;

 my $color = Convert::Color->new( 'hsv:76,0.43,0.89' );

 my ( $red, $green, $blue ) = $color->rgb;

 # GTK uses 16-bit values
 my $gtk_col = Gtk2::Gdk::Color->new( $color->as_rgb16->rgb16 );

 # HTML uses #rrggbb in hex
 my $html = '<td bgcolor="#' . $color->as_rgb8->hex . '">';

=head1 DESCRIPTION

This module provides conversions between commonly used ways to express colors.
It provides conversions between color spaces such as RGB and HSV, and it
provides ways to look up colors by a name.

This class provides a base for subclasses which represent particular color
values in particular spaces. The base class provides methods to represent the
color in a few convenient forms, though subclasses may provide more specific
details for the space in question.

For more detail, read the documentation on these classes; namely:

=over 4

=item *

L<Convert::Color::RGB> - red/green/blue as floats between 0 and 1

=item *

L<Convert::Color::RGB8> - red/green/blue as 8-bit integers

=item *

L<Convert::Color::RGB16> - red/green/blue as 16-bit integers

=item *

L<Convert::Color::HSV> - hue/saturation/value

=item *

L<Convert::Color::HSL> - hue/saturation/lightness

=item *

L<Convert::Color::CMY> - cyan/magenta/yellow

=item *

L<Convert::Color::CMYK> - cyan/magenta/yellow/key (blackness)

=back

The following classes are subclasses of one of the above, which provide a way
to access predefined colors by names:

=over 4

=item *

L<Convert::Color::VGA> - named lookup for the basic VGA colors

=item *

L<Convert::Color::X11> - named lookup of colors from X11's F<rgb.txt>

=back

=cut

=head1 CONSTRUCTOR

=cut

my $_space2class_cache_initialised;
my %_space2class_cache; # {$space} = $class
my %_class2space_cache; # {$class} = $space

# doc'ed later for readability...
sub register_color_space
{
   my $class = shift;
   my ( $space ) = @_;

   exists $_space2class_cache{$space} and croak "Color space $space is already defined";
   exists $_class2space_cache{$class} and croak "Class $class already declared a color space";

   $_space2class_cache{$space} = $class;
   $_class2space_cache{$class} = $space;

   no strict 'refs';
   *{"as_$space"} = sub { shift->convert_to( $space ) };
}

sub _space2class
{
   my ( $space ) = @_;

   unless( $_space2class_cache_initialised ) {
      $_space2class_cache_initialised++;
      # Initialise the space name to class cache
      foreach my $class ( @plugins ) {
         ( my $file = "$class.pm" ) =~ s{::}{/}g;
         require $file or next;

         $class->can( 'COLOR_SPACE' ) or next;
         my $thisspace = $class->COLOR_SPACE or next;

         warnings::warn( deprecated => "Discovered $class by deprecated COLOR_SPACE method" );

         $class->register_color_space( $thisspace );
      }
   }

   return $_space2class_cache{$space};
}

=head2 $color = Convert::Color->new( STRING )

Return a new value to represent the color specified by the string. This string
should be prefixed by the name of the color space to which it applies. For
example

 rgb:RED,GREEN,BLUE
 rgb8:RRGGBB
 rgb16:RRRRGGGGBBBB
 hsv:HUE,SAT,VAL
 hsl:HUE,SAT,LUM
 cmy:CYAN,MAGENTA,YELLOW
 cmyk:CYAN,MAGENTA,YELLOW,KEY

 vga:NAME
 vga:INDEX

 x11:NAME

For more detail, see the constructor of the color space subclass in question.

=cut

sub new
{
   shift;
   my ( $str ) = @_;

   $str =~ m/^(\w+):(.*)$/ or croak "Unable to parse color name $str";
   ( my $space, $str ) = ( $1, $2 );

   my $class = _space2class( $space ) or croak "Unrecognised color space name '$space'";

   return $class->new( $str );
}

=head1 METHODS

=cut

=head2 ( $red, $green, $blue ) = $color->rgb

Returns the individual red, green and blue color components of the color
value. For RGB values, this is done directly. For values in other spaces, this
is done by first converting them to an RGB value using their C<to_rgb()>
method.

=cut

sub rgb
{
   my $self = shift;
   croak "Abstract method - should be overloaded by ".ref($self);
}

=head1 COLOR SPACE CONVERSIONS

Cross-conversion between color spaces is provided by the C<convert_to()>
method, assisted by helper methods in the two color space classes involved.

When converting C<$color> from color space SRC to color space DEST, the
following operations are attemped, in this order. SRC and DEST refer to the
names of the color spaces, e.g. C<rgb>.

=over 4

=item 1.

If SRC and DEST are equal, return C<$color> as it stands.

=item 2.

If the SRC space's class provides a C<convert_to_DEST> method, use it.

=item 3.

If the DEST space's class provides a C<new_from_SRC> constructor, call it and
pass C<$color>.

=item 4.

If the DEST space's class provides a C<new_rgb> constructor, convert C<$color>
to red/green/blue components then call it.

=item 5.

If none of these operations worked, then throw an exception.

=back

These functions may be called in the following ways:

 $other = $color->convert_to_DEST()
 $other = Dest::Class->new_from_SRC( $color )
 $other = Dest::Class->new_rgb( $color->rgb )

=cut

=head2 $other = $color->convert_to( $space )

Attempt to convert the color into its representation in the given space. See
above for the various ways this may be achieved.

If the relevant subclass has already been loaded (either explicitly, or
implicitly by either the C<new> or C<convert_to> methods), then a specific
conversion method will be installed in the class.

 $other = $color->as_$space

Methods of this form are currently C<AUTOLOAD>ed if they do not yet exist, but
this feature should not be relied upon - see below.

=cut

sub convert_to
{
   my $self = shift;
   my ( $to_space ) = @_;

   my $to_class = _space2class( $to_space ) or croak "Unrecognised color space name '$to_space'";

   my $from_space = $_class2space_cache{ref $self};

   if( $from_space eq $to_space ) {
      # Identity conversion
      return $self;
   }

   my $code;
   if( $code = $self->can( "convert_to_$to_space" ) ) {
      return $code->( $self );
   }
   elsif( $code = $to_class->can( "new_from_$from_space" ) ) {
      return $code->( $to_class, $self );
   }
   elsif( $code = $to_class->can( "new_rgb" ) ) {
      # TODO: check that $self->rgb is overloaded
      return $code->( $to_class, $self->rgb );
   }
   else {
      croak "Cannot convert from space '$from_space' to space '$to_space'";
   }
}

# Fallback implementations in case subclasses don't provide anything better

sub convert_to_rgb
{
   my $self = shift;
   require Convert::Color::RGB;
   return Convert::Color::RGB->new( $self->rgb );
}

=head1 AUTOLOADED CONVERSION METHODS

This class provides C<AUTOLOAD> and C<can> behaviour which automatically
constructs conversion methods. The following method calls are identical:

 $color->convert_to('rgb')
 $color->as_rgb

The generated method will be stored in the package, so that future calls will
not have the AUTOLOAD overhead.

This feature is deprecated and should not be relied upon, due to the delicate
nature of C<AUTOLOAD>.

=cut

# Since this is AUTOLOADed, we can dynamically provide new methods for classes
# discovered at runtime.

sub can
{
   my $self = shift;
   my ( $method ) = @_;

   if( $method =~ m/^as_(.*)$/ ) {
      my $to_space = $1;
      _space2class( $to_space ) or return undef;

      return sub {
         my $self = shift;
         return $self->convert_to( $to_space );
      };
   }

   return $self->SUPER::can( $method );
}

sub AUTOLOAD
{
   my ( $method ) = our $AUTOLOAD =~ m/::([^:]+)$/;

   return if $method eq "DESTROY";

   if( ref $_[0] and my $code = $_[0]->can( $method ) ) {
      # It's possible that the lazy loading by ->can has just created this method
      warnings::warn( deprecated => "Relying on AUTOLOAD to provide $method" );
      no strict 'refs';
      unless( defined &{$method} ) {
         *{$method} = $code;
      }
      goto &$code;
   }

   my $class = ref $_[0] || $_[0];
   croak qq(Cannot locate object method "$method" via package "$class");
}

=head1 OTHER METHODS

As well as the above, it is likely the subclass will provide accessors to
directly obtain the components of its representation in the specific space.
For more detail, see the documentation for the specific subclass in question.

=cut

=head1 SUBCLASS METHODS

This base class is intended to be subclassed to provide more color spaces.

=cut

=head2 $class->register_color_space( $space )

A subclass should call this method to register itself as a named color space.

=cut

=head2 $class->register_palette( %args )

A subclass that provides a fixed set of color values should call this method,
to set up automatic conversions that look for the closest match within the
set. This conversion process is controlled by the C<%args>:

=over 8

=item enumerate => STRING or CODE

A method name or anonymous CODE reference which will be used to generate the
list of color values.

=item enumerate_once => STRING or CODE

As per C<enumerate>, but will be called only once and the results cached.

=back

This method creates a new class method on the calling package, called
C<closest_to>.

=head3 $color = $pkg->closest_to( $orig, $space )

Returns the color in the space closest to the given value. The distance is
measured in the named space; defaulting to C<rgb> if this is not provided.

In the case of a tie, where two or more colors have the same distance from the
target, the first one will be chosen.

=cut

sub register_palette
{
   my $pkg = shift;
   my %args = @_;

   my $enumerate;

   if( $args{enumerate} ) {
      $enumerate = $args{enumerate};
   }
   elsif( my $enumerate_once = $args{enumerate_once} ) {
      my @colors;
      $enumerate = sub {
         my $class = shift;
         @colors = $class->$enumerate_once unless @colors;
         return @colors;
      }
   }
   else {
      croak "Require 'enumerate' or 'enumerate_once'";
   }

   no strict 'refs';

   *{"${pkg}::closest_to"} = sub {
      my $class = shift;
      my ( $orig, $space ) = @_;

      $space ||= "rgb";

      $orig = $orig->convert_to( $space );
      my $dst = "dst_${space}_cheap";

      return min_by { $orig->$dst( $_->convert_to( $space ) ) } $class->$enumerate;
   };

   foreach my $space (qw( rgb hsv hsl )) {
      *{"${pkg}::new_from_${space}"} = sub {
         my $class = shift;
         my ( $rgb ) = @_;
         return $pkg->closest_to( $rgb, $space );
      };
   }

   *{"${pkg}::new_rgb"} = sub {
      my $class = shift;
      return $class->closest_to( Convert::Color::RGB->new( @_ ), "rgb" );
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
