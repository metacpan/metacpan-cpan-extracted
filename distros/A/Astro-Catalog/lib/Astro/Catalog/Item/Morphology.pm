package Astro::Catalog::Item::Morphology;

=head1 NAME

Astro::Catalog::Item::Morphology - Information about a star's morphology.

=head1 SYNOPSIS

  $morphology = new Astro::Catalog::Item::Morphology( );

=head1 DESCRIPTION

Stores information about an astronomical object's morphology.

=cut

use 5.006;
use strict;
use warnings;
use vars qw/ $VERSION /;
use Carp;

use Number::Uncertainty;

use warnings::register;

$VERSION = "4.33";

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new instance of an C<Astro::Catalog::Item::Morphology> object.

$morphology = new Astro::Catalog::Item::Morphology( );

This method returns a reference to an C<Astro::Catalog::Item::Morphology>
object.

=cut

sub new {
  my $proto = shift;
  my $class = ref( $proto ) || $proto;

  # Retrieve the arguments.
  my %args = @_;

  # Create the object.
  my $obj = bless {}, $class;

  # Configure the object.
  $obj->_configure( %args );

  # And return it.
  return $obj;
}

=back

=head2 Accessor Methods

=over 4

=item B<ellipticity>

The ellipticity of the object.

=cut

sub ellipticity {
  my $self = shift;
  if( @_ ) {
    my $ell = shift;
    if( defined( $ell ) &&
        ! UNIVERSAL::isa( $ell, "Number::Uncertainty" ) ) {
      $ell = new Number::Uncertainty( Value => $ell );
    }
    $self->{ELLIPTICITY} = $ell;
  }
  return $self->{ELLIPTICITY};
}

=item B<position_angle_pixel>

Position angle using the pixel frame as a reference. Measured counter-
clockwise from the positive x axis.

=cut

sub position_angle_pixel {
  my $self = shift;
  if( @_ ) {
    my $ang = shift;
    if( defined( $ang ) &&
        ! UNIVERSAL::isa( $ang, "Number::Uncertainty" ) ) {
      $ang = new Number::Uncertainty( Value => $ang );
    }
    $self->{POSITION_ANGLE_PIXEL} = $ang;
  }
  return $self->{POSITION_ANGLE_PIXEL};
}

=item B<position_angle_world>

Position angle using the world coordinate system as a reference. Measured
east of north.

=cut

sub position_angle_world {
  my $self = shift;
  if( @_ ) {
    my $ang = shift;
    if( defined( $ang ) &&
        ! UNIVERSAL::isa( $ang, "Number::Uncertainty" ) ) {
      $ang = new Number::Uncertainty( Value => $ang );
    }
    $self->{POSITION_ANGLE_WORLD} = $ang;
  }
  return $self->{POSITION_ANGLE_WORLD};
}

=item B<major_axis_pixel>

Length of the semi-major axis in units of pixels.

=cut

sub major_axis_pixel {
  my $self = shift;
  if( @_ ) {
    my $axis = shift;
    if( defined( $axis ) &&
        ! UNIVERSAL::isa( $axis, "Number::Uncertainty" ) ) {
      $axis = new Number::Uncertainty( Value => $axis );
    }
    $self->{MAJOR_AXIS_PIXEL} = $axis;
  }
  return $self->{MAJOR_AXIS_PIXEL};
}

=item B<minor_axis_pixel>

Length of the semi-minor axis in units of pixels.

=cut

sub minor_axis_pixel {
  my $self = shift;
  if( @_ ) {
    my $axis = shift;
    if( defined( $axis ) &&
        ! UNIVERSAL::isa( $axis, "Number::Uncertainty" ) ) {
      $axis = new Number::Uncertainty( Value => $axis );
    }
    $self->{MINOR_AXIS_PIXEL} = $axis;
  }
  return $self->{MINOR_AXIS_PIXEL};
}

=item B<major_axis_world>

Length of the semi-major axis in units of degrees.

=cut

sub major_axis_world {
  my $self = shift;
  if( @_ ) {
    my $axis = shift;
    if( defined( $axis ) &&
        ! UNIVERSAL::isa( $axis, "Number::Uncertainty" ) ) {
      $axis = new Number::Uncertainty( Value => $axis );
    }
    $self->{MAJOR_AXIS_WORLD} = $axis;
  }
  return $self->{MAJOR_AXIS_WORLD};
}

=item B<minor_axis_world>

Length of the semi-minor axis in units of degrees.

=cut

sub minor_axis_world {
  my $self = shift;
  if( @_ ) {
    my $axis = shift;
    if( defined( $axis ) &&
        ! UNIVERSAL::isa( $axis, "Number::Uncertainty" ) ) {
      $axis = new Number::Uncertainty( Value => $axis );
    }
    $self->{MINOR_AXIS_WORLD} = $axis;
  }
  return $self->{MINOR_AXIS_WORLD};
}

=item B<area>

Area of the object, usually by using isophotal techniques, in square
pixels.

=cut

sub area {
  my $self = shift;
  if( @_ ) {
    my $area = shift;
    if( defined( $area ) &&
        ! UNIVERSAL::isa( $area, "Number::Uncertainty" ) ) {
      $area = new Number::Uncertainty( Value => $area );
    }
    $self->{AREA} = $area;
  }
  return $self->{AREA};
}

=item B<fwhm_pixel>

FWHM of the object in pixels.

=cut

sub fwhm_pixel {
  my $self = shift;
  if( @_ ) {
    my $fwhm = shift;
    if( defined( $fwhm ) &&
        ! UNIVERSAL::isa( $fwhm, "Number::Uncertainty" ) ) {
      $fwhm = new Number::Uncertainty( Value => $fwhm );
    }
    $self->{FWHM_PIXEL} = $fwhm;
  }
  return $self->{FWHM_PIXEL};
}

=item B<fwhm_world>

FWHM of the object in arcseconds.

=cut

sub fwhm_world {
  my $self = shift;
  if( @_ ) {
    my $fwhm = shift;
    if( defined( $fwhm ) &&
        ! UNIVERSAL::isa( $fwhm, "Number::Uncertainty" ) ) {
      $fwhm = new Number::Uncertainty( Value => $fwhm );
    }
    $self->{FWHM_WORLD} = $fwhm;
  }
  return $self->{FWHM_WORLD};
}

=back

=head1 PRIVATE METHODS

=over 4

=item B<_configure>

Configure the object.

=cut

sub _configure {
  my $self = shift;

  my %args = @_;
  foreach my $key ( keys %args ) {
    if( $self->can( lc( $key ) ) ) {
      my $method = lc $key;
      $self->$method( $args{$key} );
    }
  }
}

=back

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research
Council.  All Rights Reserved.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
