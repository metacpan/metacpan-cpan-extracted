package CXC::Astro::Regions::CIAO;

# ABSTRACT: CIAO Compatible Regions

use v5.20;
use warnings;
use experimental 'signatures', 'postderef', 'lexical_subs';

our $VERSION = '0.03';

use CXC::Astro::Regions::CIAO::Types qw(
  Angle
  Tuple
  Length
  NonEmptyStr
  Vertex
  ArrayRef
  XPosition
  YPosition
);

use CXC::Astro::Regions::CIAO::Variant;

package CXC::Astro::Regions::CIAO::Role::Region {
    use Moo::Role;
}

use constant RegionRole => __PACKAGE__ . '::Role::Region';

use namespace::clean;

use parent 'Exporter::Tiny';

my sub pkgpath ( @paths ) {
    join q{::}, __PACKAGE__, map { ucfirst( $_ ) } @paths;
}

my sub args ( @args ) {
    return @args == 1 ? ( name => $args[0] ) : @args;
}

my sub ANGLE      { { name => 'angle',    isa => Angle, args( @_ ) } }
my sub ANGLEPAIR  { { name => 'angles',   isa => Tuple [ Angle, Angle ], args( @_ ) } }
my sub LENGTH     { { name => 'length',   isa => Length, args( @_ ) } }
my sub LENGTHPAIR { { name => undef,      isa => Tuple [ Length, Length ], args( @_ ) } }
my sub STRING     { { name => undef,      isa => NonEmptyStr, args( @_ ) } }
my sub VERTEX     { { name => undef,      isa => Vertex,      args( @_ ) } }
my sub VERTICES   { { name => 'vertices', isa => ArrayRef [Vertex], args( @_ ) } }
my sub XPOS       { { name => undef,      isa => XPosition, args( @_ ) } }
my sub YPOS       { { name => undef,      isa => YPosition, args( @_ ) } }

use Package::Stash;
our @EXPORT_OK = ( 'mkregion' );

# my sub REGION ( $name, $params ) { $Region{$name} = $params }
my $stash = Package::Stash->new( __PACKAGE__ );

my sub REGION ( $region, %spec ) {

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











# |-----------|-----------------------------------------------------|
# | ANNULUS   | (xcenter,ycenter,iradius,oradius)                   |
# |-----------|-----------------------------------------------------|
REGION annulus => (
    name   => 'annulus',
    params => [ VERTEX( 'center' ), LENGTHPAIR( 'radii' ) ],
);











# |-----------|-----------------------------------------------------|
# | BOX       | (xcenter,ycenter,width,height)                      |
# | BOX       | (xcenter,ycenter,width,height,angle)                |
# |-----------|-----------------------------------------------------|
REGION box => (
    name   => 'box',
    params => [ VERTEX( 'center' ), LENGTH( 'width' ), LENGTH( 'height' ), ANGLE( required => !!0 ) ],
);







# |-----------|-----------------------------------------------------|
# | CIRcle    | (xcenter,ycenter,radius)                            |
# |-----------|-----------------------------------------------------|
REGION circle => ( params => [ VERTEX( 'center' ), LENGTH( 'radius' ) ], );











# |-----------|-----------------------------------------------------|
# | ELLipse   | (xcenter,ycenter,xradius,yradius,angle)             |
# |-----------|-----------------------------------------------------|
REGION ellipse =>
  ( params => [ VERTEX( 'center' ), LENGTHPAIR( 'radii' ), ANGLE( default => 0 ) ], );









# |-----------|-----------------------------------------------------|
# | FIELD     | ()                                                  |
# -------------------------------------------------------------------
REGION field => ( params => [], );











# |-----------|-----------------------------------------------------|
# | PIE       | (xcenter,ycenter,iradius,oradius,minangle,maxangle) |
# |-----------|-----------------------------------------------------|
REGION pie => ( params => [ VERTEX( 'center' ), LENGTHPAIR( 'radii' ), ANGLEPAIR, ], );









# |-----------|-----------------------------------------------------|
# | POInt     | (xcenter,ycenter)                                   |
# |-----------|-----------------------------------------------------|
REGION point => ( params => [ VERTEX( 'center' ) ], );









# |-----------|-----------------------------------------------------|
# | POLYgon   | (x1,y1,x2,y2,x3,y3,...)                             |
# |-----------|-----------------------------------------------------|
REGION polygon => ( params => [VERTICES], );










# |-----------|-----------------------------------------------------|
# | RECTangle | (xmin,ymin,xmax,ymax)                               |
# |-----------|-----------------------------------------------------|
REGION rectangle =>
  ( params => [ XPOS( 'xmin' ), YPOS( 'ymin' ), XPOS( 'xmax' ), YPOS( 'ymax' ) ], );









# |-----------|-----------------------------------------------------|
# | REGION    | (file)                                              |
# |-----------|-----------------------------------------------------|
REGION region => ( params => [ STRING( 'file' ) ], );











# |-----------|-----------------------------------------------------|
# | ROTBOX    | (xcenter,ycenter,width,height,angle)                |
# |-----------|-----------------------------------------------------|
REGION rotbox => (
    name   => 'rotbox',
    params => [ VERTEX( 'center' ), LENGTH( 'width' ), LENGTH( 'height' ), ANGLE ],
);











# |-----------|-----------------------------------------------------|
# | SECTor    | (xcenter,ycenter,minangle,maxangle)                 |
# |-----------|-----------------------------------------------------|
REGION sector => ( params => [ VERTEX( 'center' ), ANGLEPAIR, ], );

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory mkregion rotbox

=head1 NAME

CXC::Astro::Regions::CIAO - CIAO Compatible Regions

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use CXC::Astro::Regions::CIAO 'circle', 'region';

  $circle = circle( center => [ 4096, 4096 ],
                    radius => 200 );

  # equivalent using factory subroutine
  $circle = region( circle =>
                    center => [ 4096, 4096 ],
                    radius => 200 );

  say $circle->render;
  # outputs "circle(4096,4096,200)"

=head1 DESCRIPTION

This module provides an objected oriented interface to the region
specifications supported by the CIAO L<https://cxc.harvard.edu/ciao>
X-ray astronomy data reduction software suite.

Each type of region is mapped onto a class
(e.g. B<CXC::Astro::Region::CIAO::Circle>) and an alternate constructor
(e.g. B<circle()>) is provided for the class.  Classes have a C<render>
method which returns a CIAO compatible string representation of the region.

There is no support for algebraic manipulation of regions.

=head2 Units

B<CXC::Astro::Regions::CIAO> verifies that input values for positions
and lengths are acceptable to CIAO.

=head3 Positions

Positions must have the following forms

  [num]                   # physical
  [num]d                  # degrees
  [num]:[num]:[num]       # hms for RA, or dms for Declination

=head3 Lengths

Lengths must have the following forms

  [num]                   # physical
  [num]"                  # arc sec
  [num]''                 # arc sec (double apostrophye)
  [num]'                  # arc min
  [num]d                  # degrees

=head1 CONSTRUCTORS

The following CIAO regions are supported via both the traditional
and alternate constructors, e.g.

  $region = CXC::Astro::Regions::CIAO::Circle->new( ... );
  $region = circle( ... );

In the descriptions below, optional parameters are preceded with a
C<?>, e.g.

    box( ..., ?angle => <angle>);

indicates that the I<angle> parameter is optional.

I<< <x> >> and I<< <y> >> are I<X> an I<Y> positions.

=head2 annulus

   $region = annulus( center => [ <x>, <y> ],
                      radii => [ <r1>, <r2>] );

This returns an instance of B<CXC::Astro::Regions::CIAO::Annulus>. It
represents a single annulus.

=head2 box

  $region = box( center => [ <x>, <y> ],
                 width  => <length>, height => <length>,
                 ?angle => <angle> );

This returns an instance of B<CXC::Astro::Regions::CIAO::Box>.

=head2 circle

  $region = circle( center => [ <x>, <y> ], radius => <length> );

=head2 ellipse

  $region = ellipse( center => [ <x>, <y> ],
                     radii  => [ <xradius>, <yradius>],
                     ??angle => <angle> );

This returns an instance of B<CXC::Astro::Regions::CIAO::Ellipse>.

=head2 field

  $region = field();

This returns an instance of B<CXC::Astro::Regions::CIAO::Field>.

=head2 pie

  $region = pie( center => [ <x>, <y> ],
                 radii => [ <inner>, <outer> ],
                 angles => [ <min>, <max> ] );

This returns an instance of B<CXC::Astro::Regions::CIAO::Pie>.

=head2 point

  $region = point( center => [ <x>, <y> ] );

This returns an instance of B<CXC::Astro::Regions::CIAO::Point>.

=head2 polygon

  $region = line( vertices => [ [<x>, <y>], ... ] );

This returns an instance of B<CXC::Astro::Regions::CIAO::Polygon>.

=head2 rectangle

  $region = rectangle( xmin => <xmin>, ymin => <ymin>,
                       xmax => <xmax>, ymax => <ymax> );

This returns an instance of B<CXC::Astro::Regions::CIAO::Rectangle>.

=head2 region

  $region = region ( file => <file> );

This returns an instance of B<CXC::Astro::Regions::CIAO::Region>.

=head2 rotbox

  $region = rotbox( center => [ <x>, <y> ],
                    width  => <length>, height => <length>,
                    angle => <angle> );

This returns an instance of B<CXC::Astro::Regions::CIAO::Rotbox>.

=head2 sector

  $region = sector( center => [ <x>, <y> ],
                    angles => [ <min>, <max> ] );

This returns an instance of B<CXC::Astro::Regions::CIAO::Sector>.

=head2 mkregion

  $region = mkregion( $shape, @pars );

A generic factory routine which calls the constructor for the named
shape (e.g. C<circle>, C<annulus>, etc).

=head1 METHODS

All regions objects have the following methods:

=head3 render

   $string   = $region->render;

The B<render> method returns a string with a B<CIAO> compatible
region specification.

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

=item *

L<https://cxc.harvard.edu/ciao/ahelp/dmregions.html>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
