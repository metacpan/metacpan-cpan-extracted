package Astro::FITS::HdrTrans::NIRI;

=head1 NAME

Astro::FITS::HdrTrans::NIRI - Gemini NIRI translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::NIRI;

  %gen = Astro::FITS::HdrTrans::NIRI->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
NIRI on the Gemini Observatory.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from GEMINI
use base qw/ Astro::FITS::HdrTrans::GEMINI /;

use vars qw/ $VERSION /;

$VERSION = "1.60";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 GAIN                 => 12.3, # hardwire for now
                 OBSERVATION_MODE     => 'imaging',
                 SPEED_GAIN           => "NA",
                 STANDARD             => 0, # hardwire for now as all objects not a standard.
                 WAVEPLATE_ANGLE      => 0, # hardwire for now
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                DETECTOR_READ_TYPE   => "MODE",
               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "NIRI".

=cut

sub this_instrument {
  return qr/^NIRI/;
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=cut

sub to_EXPOSURE_TIME {
  my $self = shift;
  my $FITS_headers = shift;
  my $et = $FITS_headers->{EXPTIME};
  my $co = $FITS_headers->{COADDS};
  return $et *= $co;
}

sub to_OBSERVATION_NUMBER {
  my $self = shift;
  my $FITS_headers = shift;
  my $obsnum = 0;
  if ( exists ( $FITS_headers->{FRMNAME} ) ) {
    my $fname = $FITS_headers->{FRMNAME};
    $obsnum = substr( $fname, index( $fname, ":" ) - 4, 4 );
  }
  return $obsnum;
}

=item B<to_ROTATION>

Converts a linear transformation CD matrix into a single rotation angle.
This angle is measured counter-clockwise from the positive x-axis.
It uses the SLALIB routine slaDcmpf obtain the rotation angle without
assuming perpendicular axes.

This routine also copes with errors in the matrix that can generate angles
+/-90 degrees instead of near 0 that they should be.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $rotation = 0.0;
  if ( exists( $FITS_headers->{CD1_1} ) ) {

    # Access the CD matrix.
    my $cd11 = $FITS_headers->{"CD1_1"};
    my $cd12 = $FITS_headers->{"CD1_2"};
    my $cd21 = $FITS_headers->{"CD2_1"};
    my $cd22 = $FITS_headers->{"CD2_2"};

    # Determine the orientation using SLALIB routine.  This has the
    # advantage of not assuming perpendicular axes (i.e. allows for
    # shear).
    my ( $xz, $yz, $xs, $ys, $perp, $orient );
    my @coeffs = ( 0.0, $cd11, $cd21, 0.0, $cd12, $cd22 );
    eval {
      require Astro::SLA;
      Astro::SLA::slaDcmpf( @coeffs, $xz, $yz, $xs, $ys, $perp, $rotation );
    };
    if (!defined $perp) {
      croak "NIRI translations require Astro::SLA. Please contact the authors";
    }

    # Convert from radians to degrees.
    my $rtod = 45 / atan2( 1, 1 );
    $rotation *= $rtod;

    # The actual WCS matrix has errors and sometimes the angle which
    # should be near 0 degrees, can be out by 90 degrees.  So for this
    # case we hardwire the main rotation and merely apply the small
    # deviation from the cardinal orientations.
    if ( abs( abs( $rotation ) - 90 ) < 2 ) {
      my $delta_rho = 0.0;
         
      $delta_rho = $rotation - ( 90 * int( $rotation / 90 ) );
      $delta_rho -= 90 if ( $delta_rho > 45 );
      $delta_rho += 90 if ( $delta_rho < -45 );

      # Setting to near 180 is a fudge because the CD matrix appears is wrong
      # occasionally by 90 degrees, judging by the telescope offsets, CTYPEn, and
      # the support astronomer.
      $rotation = 180.0 + $delta_rho;
    }
         
  }
  return $rotation;
}

# Shift the bounds to GRID co-ordinates.
sub to_X_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my $bound = 1;
  if ( exists( $FITS_headers->{LOWCOL} ) ) {
    $bound = $self->nint( $FITS_headers->{LOWCOL} + 1 );
  }
  return $bound;
}

sub to_Y_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my $bound = 1;
  if ( exists( $FITS_headers->{LOWROW} ) ) {
    $bound = $self->nint( $FITS_headers->{LOWROW} + 1 );
  }
  return $bound;
}

sub to_X_UPPER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my $bound = 1024;
  if ( exists( $FITS_headers->{HICOL} ) ) {
    $bound = $self->nint( $FITS_headers->{HICOL} + 1 );
  }
  return $bound;
}

sub to_Y_UPPER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my $bound = 1024;
  if ( exists( $FITS_headers->{HIROW} ) ) {
    $bound = $self->nint( $FITS_headers->{HIROW} + 1 );
  }
  return $bound;
}


=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Malcolm J. Currie E<lt>mjc@star.rl.ac.ukE<gt>
Paul Hirst E<lt>p.hirst@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council
Copyright (C) 1998-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either Version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA  02111-1307, USA.

=cut

1;
