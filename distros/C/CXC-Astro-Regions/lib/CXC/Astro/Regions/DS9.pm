package CXC::Astro::Regions::DS9;

# ABSTRACT: DS9 Compatible Regions

use v5.20;
use warnings;
use experimental 'signatures', 'postderef', 'lexical_subs';

our $VERSION = '0.03';

package CXC::Astro::Regions::DS9::Role::Region {
    use Moo::Role;
}

use constant RegionRole => __PACKAGE__ . '::Role::Region';

use parent 'Exporter::Tiny';

use Import::Into;
use CXC::Astro::Regions::DS9::Types qw(
  Angle
  ArrayRef
  ConsumerOf
  CoordSys
  Enum
  Length
  LengthPair
  NonEmptyStr
  OneZero
  PointType
  PositiveInt
  RulerCoords
  Tuple
  Vertex
);

use CXC::Astro::Regions::DS9::Variant;
use List::Util ();

use namespace::clean;

my sub croak {
    require Carp;
    goto \&Carp::croak;
}

my sub pkgpath ( @paths ) {
    join q{::}, __PACKAGE__, map { ucfirst( $_ ) } @paths;
}

my sub args ( @args ) {
    return @args == 1 ? ( name => $args[0] ) : @args;
}

my sub format_text ( $type, $label, $values ) {
    return () unless $values->@*;
    return $type eq 'prop' && defined $label
      ? sprintf( '%s={%s}', $label, $values->@* )
      : sprintf( '{%s}', $values->@* );
}

my sub format_qstring ( $type, $label, $values ) {
    return () unless $values->@*;
    return $type eq 'prop' && defined $label
      ? sprintf( '%s="%s"', $label, $values->@* )
      : sprintf( '"%s"', $values->@* );
}

my sub format_tags ( $type, $label, $values ) {
    ( $values, my @rest ) = $values->@*;
    croak( 'too many values passed to tags' ) if @rest;
    return () unless $values->@*;
    return join q{ }, map { sprintf( '%s={%s}', $label, $_ ) } $values->@*;
}

my sub ANGLE            { { name => 'angle',  isa => Angle, args( @_ ) } }
my sub ANGLEPAIR        { { name => 'angles', isa => Tuple [ Angle, Angle ], args( @_ ) } }
my sub ARROW            { { name => 'arrow',  isa => OneZero, coerce => !!1, args( @_ ) } }
my sub ARROWS           { { name => 'arrows', isa => ArrayRef [ OneZero, 2 ], args( @_ ) } }
my sub BOOL             { { name => undef,    isa => OneZero,     coerce => !!1, args( @_ ) } }
my sub COORDS           { { name => 'coords', isa => CoordSys,    coerce => !!1, args( @_ ) } }
my sub FILL             { { name => 'fill',   isa => OneZero,     coerce => !!1, args( @_ ) } }
my sub FORMAT           { { name => 'format', isa => NonEmptyStr, args( @_ ) } }
my sub LENGTH           { { name => 'length', isa => Length,      args( @_ ) } }
my sub LENGTHPAIR       { { name => undef,    isa => LengthPair,  args( @_ ) } }
my sub LENGTHPAIR_ARRAY { { name => undef,    isa => ArrayRef [LengthPair], args( @_ ) } }
my sub LENGTH_ARRAY     { { name => undef,    isa => ArrayRef [Length],     args( @_ ) } }
my sub N                { { name => 'n',      isa => PositiveInt, args( @_ ) } }
my sub POINT { { name => 'symbol', isa => PointType, coerce => !!1, label => 'point', args( @_ ) } }
my sub POSINT  { { name => undef, isa => PositiveInt, args( @_ ) } }
my sub QSTRING { { name => undef, isa => NonEmptyStr, format => \&format_text, args( @_ ) } }
my sub RULERCOORDS {
    { name => 'coords', isa => RulerCoords, coerce => !!1, label => 'ruler', args( @_ ) };
}
my sub STRING { { name => undef, isa => NonEmptyStr, args( @_ ) } }
my sub TAGS {
    {
        name   => 'tags',
        isa    => ArrayRef [NonEmptyStr],
        format => \&format_tags,
        label  => 'tag',
        args( @_ ) };
}
my sub TEXT     { { name => 'text',     isa => NonEmptyStr, format => \&format_text, args( @_ ) } }
my sub VERTEX   { { name => undef,      isa => Vertex,      args( @_ ) } }
my sub VERTICES { { name => 'vertices', isa => ArrayRef [Vertex], args( @_ ) } }

my @CommonProps = (
    TEXT,
    ANGLE( 'textangle' ),
    STRING( 'color' ),
    { name => 'dashlist', isa => ArrayRef [PositiveInt] },
    POSINT( name => 'linewidth', label => 'width' ),
    QSTRING( 'font' ),
    BOOL( 'select' ),
    BOOL( 'highlite' ),
    BOOL( 'dash' ),
    BOOL( 'fixed' ),
    BOOL( 'edit' ),
    BOOL( 'move' ),
    BOOL( 'rotate' ),
    BOOL( 'delete' ),
    BOOL( name => 'include', default => !!1 ),
    { name => 'srctype', isa => Enum [ 'source', 'background' ], label => undef },
    TAGS,
);

use Package::Stash;
our @EXPORT_OK = ( 'mkregion' );

my $stash = Package::Stash->new( __PACKAGE__ );
my sub REGION ( $region, %spec ) {

    push( ( $spec{props} //= [] )->@*, @CommonProps );
    $spec{with} //= [RegionRole];
    my $package = pkgpath( $region );

    if ( exists $spec{name} && $spec{name} ne $region ) {
        my $parent = pkgpath( $spec{name} );
        Moo->import::into( $parent );
        $spec{extends} = [$parent];
    }

    my $variant = Variant( $region, %spec );
    Package::Stash->new( $variant )->add_symbol( q{@CARP_NOT}, [__PACKAGE__] );

    $stash->add_symbol( q{&} . $region, sub { $package->new( @_ ) } );
    push @EXPORT_OK, $region;
}



















# Annulus
# Usage: annulus x y inner outer n=#
REGION annulus_n => (
    name   => 'annulus',
    params => [ VERTEX( 'center' ), LENGTHPAIR( 'annuli' ), N( label => 'n' ) ],
);

# Annulus
# Usage: annulus x y r1 r2 r3...
REGION annulus_annuli => (
    name   => 'annulus',
    params => [ VERTEX( 'center' ), LENGTH_ARRAY( 'annuli' ) ],
);





























# Box
# Usage: box x y width height angle # fill=[0|1]
REGION box_plain => (
    name   => 'box',
    params => [ VERTEX( 'center' ), LENGTH( 'width' ), LENGTH( 'height' ), ANGLE( required => !!0 ) ],
    props  => [FILL],
);

# Box Annulus
# Usage: box x y w1 h1 w2 h2 n=# [angle]
REGION box_n => (
    name   => 'box',
    params => [
        VERTEX( 'center' ),
        LENGTHPAIR( 'inner' ),
        LENGTHPAIR( 'outer' ),
        N( label => 'n' ),
        ANGLE( required => !!0 ),
    ],
);

# Box Annulus
# Usage: box x y w1 h1 w2 h2 w3 h3 ... [angle]
REGION box_annuli => (
    name   => 'box',
    params => [ VERTEX( 'center' ), LENGTHPAIR_ARRAY( 'annuli' ), ANGLE( required => !!0 ), ],
);













# Bpanda
# Usage: bpanda x y startangle stopangle nangle inner outer nradius [angle]
REGION bpanda => (
    params => [
        VERTEX( 'center' ),
        ANGLEPAIR,
        N( 'nangles' ),
        LENGTHPAIR( 'inner' ),
        LENGTHPAIR( 'outer' ),
        N( 'nannuli' ),
        ANGLE( required => !!0 ),
    ],
);









# Circle
# Usage: circle x y radius # fill=[0|1]
REGION circle => (
    params => [ VERTEX( 'center' ), LENGTH( 'radius' ) ],
    props  => [FILL],
);






























# Compass
# Usage: compass x1 y1 length # compass=<coordinate system> <north label> <east label> [0|1] [0|1]
REGION compass => (
    params => [ VERTEX( 'base' ), LENGTH ],
    props  => [
        COORDS( label => 'compass', default => 'physical' ),
        TEXT( name => 'north', label => undef, default => 'N' ),
        TEXT( name => 'east',  label => undef, default => 'E' ),
        ARROWS( label => undef, default => sub { [ 1, 1 ] } ),
    ],
);
















# Composite
# Usage: # composite x y angle
REGION composite => (
    comment => !!1,
    with    => [],    # we're not a normal region, so don't compose with RegionRole
    params  => [
        VERTEX( 'center' ),
        ANGLE( required => !!0 ),
        {
            name   => 'regions',
            isa    => ArrayRef [ ConsumerOf [RegionRole] ],
            render => !!0,
        },
    ],
    around => [
        render => sub ( $orig, $self ) {
            return [ $self->$orig, map { $_->render } $self->regions->@* ];
        },
    ],
);





























# Ellipse
# Usage: ellipse x y radius radius angle # fill=[0|1]
REGION ellipse_plain => (
    name   => 'ellipse',
    params => [ VERTEX( 'center' ), LENGTHPAIR( 'radii' ), ANGLE( required => !!0 ) ],
    props  => [FILL],
);

# Ellipse Annulus
# Usage: ellipse x y r11 r12 r21 r22 n=# [angle]
REGION ellipse_n => (
    name   => 'ellipse',
    params => [
        VERTEX( 'center' ),
        LENGTHPAIR( 'inner' ),
        LENGTHPAIR( 'outer' ),
        N( label => 'n' ),
        ANGLE( required => !!0 ),
    ],
);

# Ellipse Annulus
# Usage: ellipse x y r11 r12 r21 r22 r31 r32 ... [angle]
REGION ellipse_annuli => (
    name   => 'ellipse',
    params => [ VERTEX( 'center' ), LENGTHPAIR_ARRAY( 'annuli' ), ANGLE( required => !!0 ), ],
);













# Epanda
# Usage: epanda x y startangle stopangle nangle inner outer nradius [angle]
REGION epanda => (
    params => [
        VERTEX( 'center' ),
        ANGLEPAIR,
        N( 'nangles' ),
        LENGTHPAIR( 'inner' ),
        LENGTHPAIR( 'outer' ),
        N( 'nannuli' ),
        ANGLE( required => !!0 ),
    ],
);











# Line
# Usage: line x1 y1 x2 y2 # line=[0|1] [0|1]
REGION line => (
    params => [ VERTEX( 'v1' ), VERTEX( 'v2' ) ],
    props  => [ ARROWS( label => 'line' ) ],
);











# Panda
# Usage: panda x y startangle stopangle nangle inner outer nradius
REGION panda => (
    params => [
        VERTEX( 'center' ),
        ANGLEPAIR,
        N( 'nangles' ),
        LENGTH( 'inner' ),
        LENGTH( 'outer' ),
        N( 'nannuli' ),
    ],
);

















# Point
# Usage: point x y # point=[circle|box|diamond|cross|x|arrow|boxcircle] [size]
#        circle point x y
REGION point => (
    params => [ VERTEX( 'center' ) ],
    props  => [ POINT, POSINT( name => 'size', label => undef ) ],
);








# Polygon
# Usage: polygon x1 y1 x2 y2 x3 y3 ...# fill=[0|1]
REGION polygon => (
    params => [VERTICES],
    props  => [FILL],
);









# Projection
# Usage: projection x1 y1 x2 y2 width
REGION projection => ( params => [ VERTEX( 'v1' ), VERTEX( 'v2' ), LENGTH( 'width' ) ], );













# Ruler
# Usage: ruler x1 y1 x2 y2 # ruler=[pixels|degrees|arcmin|arcsec] [format=<spec>]
REGION ruler => (
    params => [ VERTEX( 'v1' ), VERTEX( 'v2' ) ],
    props  => [ RULERCOORDS,    FORMAT ],
);







# Text
# Usage: text x y # text={Your Text Here}
#        text x y {Your Text Here}
REGION text => ( params => [ VERTEX( 'center' ), TEXT ], );













# Vector
# Usage: vector x1 y1 length angle # vector=[0|1]
REGION vector => (
    params => [ VERTEX( 'base' ), LENGTH, ANGLE ],
    props  => [ ARROW( label => 'vector' ) ],
);

# set up dispatch classes to handle the different types of annulus and ellipse regions

# The 'annulus' region can be
# * annuli with inner and outer radii and count
# * annuli with explicitly specified radii

# The 'ellipse' region can be
# * a simple ellipse;
# * elliptical annuli with inner and outer radii pairs and count
# * elliptical annuli with explicitly specified radii pairs

# The 'box' region can be
# * a simple box;
# * box annuli with inner and outer dims and count
# * box annuli with explicitly specified dims

my sub dispatch ( $package, %args ) {
    my $suffix
      = ( List::Util::any { exists $args{$_} } qw( inner outer n ) )
      ? 'n'
      : exists $args{annuli} ? 'annuli'
      # no such thing as annulus_plain; bounce to annulus_n and it'll
      # croak because of bad args
      : $package =~ /Annulus/ ? 'n'
      :                         'plain';

    return "${package}_${suffix}";
}

for my $region ( 'annulus', 'ellipse', 'box' ) {
    my $pkg = pkgpath( $region );
    Package::Stash->new( $pkg )->add_symbol(
        '&new',
        sub ( $, %args ) {
            my $class = dispatch( $pkg, %args );
            return $class->new( %args );
        } );
    $stash->add_symbol( q{&} . $region, sub { $pkg->new( @_ ) } );
    push @EXPORT_OK, $region;
}


# No longer need this; clean it up.
undef $stash;











sub mkregion ( $shape, @args ) {
    my $class = pkgpath( $shape );
    my $new   = $class->can( 'new' ) // croak( "unknown region: $shape" );
    $class->$new( @args );
}

1;

#
# This file is part of CXC-Astro-Regions
#
# This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory FontString PositiveInt
annuli boxcircle bpanda coords dashlist ds9 epanda highlite linewidth
mkregion num srctype textangle

=head1 NAME

CXC::Astro::Regions::DS9 - DS9 Compatible Regions

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use CXC::Astro::Regions::DS9 'circle', 'mkregion';

  $circle = circle( center => [ 4096, 4096 ],
                    radius => 200, fill => !!1 );

  # equivalent using factory subroutine
  $circle = mkregion( circle =>
                      center => [ 4096, 4096 ],
                      radius => 200, fill => !!1 );

  say $circle->render;
  # outputs "circle 4096 4096 200 # fill=1"

  $composite =
    composite( center => [4096, 4096],
               regions => [
                  circle( center => [ 0, 0], radius => 200 ),
                  circle( center => [ 10, 10], radius => 200 ),
               ]
     );

=head1 DESCRIPTION

This module provides an objected oriented interface to the region
specifications supported by the ds9 L<https://ds9.si.edu> astronomical
image display and analysis program.

Each type of region is mapped onto a class
(e.g. B<CXC::Astro::Region::DS9::Circle>) and an alternate constructor
(e.g. B<circle()>) is provided for the class.  Classes have a C<render>
method which returns a DS9 compatible string representation of the region.

=head2 Parameters vs Properties

DS9 regions have both parameters (which generally specify location,
size, number, and orientation attributes) and properties (which
generally specify display and region management attributes). This
interface hides those difference from the user.  Just forget the
difference.

=head2 Composite Regions

A composite region is a container for other regions.  The regions are
specified relative to the location of the composite region's location.
Unlike the other regions, a composite region's render method returns
an array of strings, rather than a single string.

=head2 Units

B<CXC::Astro::Regions::DS9> verifies that input values for positions
and lengths are acceptable to DS9.

=head3 Positions

  [num]                   # context-dependent (see below)
  [num]d                  # degrees
  [num]r                  # radians
  [num]p                  # physical pixels
  [num]i                  # image pixels
  [num]:[num]:[num]       # hms for 'odd' position arguments
  [num]:[num]:[num]       # dms for 'even' position arguments
  [num]h[num]m[num]s      # explicit hms
  [num]d[num]m[num]s      # explicit dms

A bare position (i.e. without units, as in I<[num]>) takes on a unit
corresponding to the current coordinate system.  See the C<DS9>
I<Regions> reference manual (available from within C<DS9>) for more
information.

=head3 Lengths

  [num]                   # context-dependent (see below)
  [num]"                  # arc sec
  [num]'                  # arc min
  [num]d                  # degrees
  [num]r                  # radians
  [num]p                  # physical pixels
  [num]i                  # image pixels

A bare length (i.e., without units, as in I<[num]>) takes on a unit
corresponding to the current coordinate system.  See the C<DS9>
I<Regions> reference manual (available from within C<DS9>) for more
information.

=head3 Coordinate Systems

  image                   # pixel coords of current file
  linear                  # linear wcs as defined in file
  fk4, b1950              # sky coordinate systems
  fk5, j2000
  galactic
  ecliptic
  icrs
  physical                # pixel coords of original file using LTM/LTV
  amplifier               # mosaic coords of original file using ATM/ATV
  detector                # mosaic coords of original file using DTM/DTV
  wcs,wcsa-wcsz           # specify which WCS system to be used for
                          # linear and sky coordinate systems

If no coordinate system is specified, I<physical> is assumed.  See the
C<DS9> I<Regions> reference manual (available from within C<DS9>) for
more information.

=head2 Common Properties

In addition to region specific properties documented with each region,
all share the following:

=over

=item *

B<text> => String

=item *

textangle => Number

=item *

color => String

=item *

dashlist => ArrayRef [PositiveInt]

=item *

linewidth => PositiveInt

=item *

font => FontString

=item *

select => Boolean

=item *

highlite => Boolean

=item *

dash => Boolean

=item *

fixed => Boolean

=item *

edit => Boolean

=item *

move => Boolean

=item *

rotate => Boolean

=item *

delete => Boolean

=item *

include => Boolean

defaults to true

=item *

srctype => Enum [ 'source', 'background' ]

=item *

tags => ArrayRef[Str]

=back

=head1 CONSTRUCTORS

The following DS9 regions are supported via both the traditional
and alternate constructors, e.g.

  $region = CXC::Astro::Regions::DS9::Circle->new( ... );
  $region = circle( ... );

In the descriptions below, optional parameters are preceded with a
C<?>, e.g.

    circle( ..., ?fill => <boolean>);

indicates that the I<fill> parameter is optional.

I<< <x> >> and I<< <y> >> are I<X> an I<Y> positions.

=head2 annulus

   $region = annulus( center => [ <x>, <y> ],
                      annuli => [ <r1>, <r2>],
                      n      => <nannuli> );

This returns an instance of B<CXC::Astro::Regions::DS9::Annulus_n>,
which extends B<CXC::Astro::Regions::DS9::Annulus>.  It represents
a series of I<n> nested annuli

   $region = annulus( center => [ <x>, <y> ],
                      annuli => [ <r1>, <r2>, ... <rn> ] );

This returns an instance of B<CXC::Astro::Regions::DS9::Annulus_annuli>,
which extends B<CXC::Astro::Regions::DS9::Annulus>.

=head2 box

  $region = box( center => [ <x>, <y> ],
                 width  => <length>, height => <length>,
                 ?angle => <angle>,
                 ?fill  => <boolean> );

This returns an instance of B<CXC::Astro::Regions::DS9::Box_plain>,
which extends B<CXC::Astro::Regions::DS9::Box>.

  $region = box( center => [ <x>, <y> ],
                 inner  => [ <width>, <height> ],
                 outer  => [ <width>, <height> ],
                 n      => <nannuli>,
                 ?angle => <angle> );

This returns an instance of B<CXC::Astro::Regions::DS9::Box_n>,
which extends B<CXC::Astro::Regions::DS9::Box>.

  $region = box( center => [ <x>, <y> ],
                 annuli => [ [ <width>, <height> ], [ <width>, <height> ], ... ],
                 ?angle => <angle> );

This returns an instance of B<CXC::Astro::Regions::DS9::Box_annuli>,
which extends B<CXC::Astro::Regions::DS9::Box>.

=head2 bpanda

  $region = bpanda( center  => [ <x>, <y> ],
                    angles  => [ <start angle>, <end angle> ],
                    nangles => <integer>,
                    inner   => [ <length>, <length> ],
                    outer   => [ <length>, <length> ],
                    nannuli => <integer>,
                    ?angle  => <float, degrees> );

=head2 circle

  $region = circle( center => [ <x>, <y> ],
                    radius => <length>,
                    ?fill  => <boolean> );

=head2 compass

  $region = compass( base  => [ <x>, <y> ],
                     length  => <length>,
                     ?coords => <coordinate system>,
                     ?north  => <string>,
                     ?east   => <string>,
                     ?arrows => [ <boolean>, <boolean> ] );

where

=over

=item I<coords>

See L</Coordinate Systems>

=item I<north> and I<east>

labels for the north and east points of the compass

=item I<arrows>

indicates if the north and east vectors are decorated with arrowheads.

=back

=head2 composite

  $region = composite( center  => [ <x>, <y> ],
                       regions => [ $region, ... ],
                       ?angle  => <angle> );

Create a composite region for the specified regions (which are
instances of other regions, but not of another composite region).  The regions are
specified relative to the composite region's reference frame.

Unlike other the regions, a composite region object's C<render> method
returns an arrayref of string specifications, not a single string.

=head2 ellipse

  $region = ellipse( center => [ <x>, <y> ],
                     radii  => [ <xradius>, <yradius>],
                     ?angle => <angle>,
                     ?fill  => <boolean> );

This returns an instance of B<CXC::Astro::Regions::DS9::Ellipse_plain>,
which extends B<CXC::Astro::Regions::DS9::Ellipse>.

  $region = ellipse( center => [ <x>, <y> ],
                     inner  => [ <xradius>, <yradius> ],
                     outer  => [ <xradius>, <yradius> ],
                     n      => <nannuli>,
                     ?angle => <angle> );

This returns an instance of B<CXC::Astro::Regions::DS9::Ellipse_n>,
which extends B<CXC::Astro::Regions::DS9::Ellipse>.

  $region = ellipse( center => [ <x>, <y> ],
                     annuli => [ [ <xradius>, <yradius> ], ... ],
                     ?angle => <angle> );

This returns an instance of B<CXC::Astro::Regions::DS9::Ellipse_annuli>,
which extends B<CXC::Astro::Regions::DS9::Ellipse>.

=head2 epanda

  $region = epanda( center  => [ <x>, <y> ],
                    angles  => [ <start angle>, <end angle> ],
                    nangles => <integer>,
                    inner   => [ <length>, <length> ],
                    outer   => [ <length>, <length> ],
                    nannuli => <integer>,
                    ?angle  => <float, degrees> );

=head2 line

  $region = line( v1      => [ <x>, <y> ],
                  v2      => [ <x>, <y> ],
                  ?arrows => [ <boolean>, <boolean> ] );

where I<arrows> determines if the start and end of the line are decorated with arrowheads.

=head2 panda

  $region = panda( center => [ <x>,           <y> ],
                   angles   => [ <start angle>, <end angle> ],
                   nangles  => <integer>,
                   inner    => <length>,
                   outer    => <length>,
                   nannuli  => <integer> );

=head2 point

  $region = point( center => [<x>, <y>],
                   ?symbol  => <symbol>,
                   ?size    => <integer> );

Draw a symbol at the specified region.

The available symbols are

  circle box diamond cross x arrow boxcircle

The default is I<boxcircle>

=head2 polygon

  $region = line( vertices => [ [<x>, <y>], ... ],
                  ?fill    => <boolean> );

=head2 projection

  $region = projection( v1    => [ <x>, <y> ],
                        v2    => [ <x>, <y> ],
                        width => <length> );

=head2 ruler

  $region = ruler( v1      => [ <x>, <y> ],
                   v2      => [ <x>, <y> ],
                   ?coords => <coords> );

where I<coords> is one of

  pixels degrees arcmin arcsec

=head2 text

  $region = text( center => [ <x>, <y> ],
                  text => <string> );

=head2 vector

  $region = vector( base   => [ <x>, <y> ],
                    length => <length>,
                    angle  => <float, degrees>
                    ?arrow => <boolean> );

where I<arrow> indicates that the head of the vector should be
decorated with an arrowhead.

=head2 mkregion

  $region = mkregion( $shape, @pars );

A generic factory routine which calls the constructor for the named
shape (e.g. C<circle>, C<annulus>, etc).

=head1 METHODS

All regions objects have the following methods:

=head3 render

   $string   = $non_composite_region->render;
   \@strings = $composite_region->render;

The B<render> method returns a string (if a non-composite region) or
an arrayref of strings (if a composite region) with B<DS9> compatible
region specifications.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-astro-regions@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Astro-Regions>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-astro-regions

and may be cloned from

  https://gitlab.com/djerius/cxc-astro-regions.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Astro::Regions|CXC::Astro::Regions>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
