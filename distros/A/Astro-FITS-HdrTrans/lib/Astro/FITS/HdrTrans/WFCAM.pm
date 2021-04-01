package Astro::FITS::HdrTrans::WFCAM;

=head1 NAME

Astro::FITS::HdrTrans::WFCAM - UKIRT WFCAM translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::WFCAM;

  %gen = Astro::FITS::HdrTrans::WFCAM->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the WFCAM camera of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRTNew.
use base qw/ Astro::FITS::HdrTrans::UKIRTNew /;

# We want the FITS standard versions of DATE-OBS/DATE-END parsing
# Not the UKIRT-specific versions that have Z problems.
use Astro::FITS::HdrTrans::FITS qw/ UTSTART UTEND /;

use vars qw/ $VERSION /;

$VERSION = "1.63";

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (
                 POLARIMETRY => 0,
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ DETECTOR_INDEX WAVEPLATE_ANGLE /;

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.

my %UNIT_MAP = (
                # WFCAM specific
                CAMERA_NUMBER        => "CAMNUM",
                DETECTOR_READ_TYPE   => "READMODE",
                NUMBER_OF_COADDS     => "NEXP",
                NUMBER_OF_JITTER_POSITIONS    => "NJITTER",
                NUMBER_OF_MICROSTEP_POSITIONS => "NUSTEP",
                TILE_NUMBER          => "TILENUM",

                # CGS4 + MICHELLE + WFCAM
                CONFIGURATION_INDEX  => 'CNFINDEX',
               );


# Create the translation methods.
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "WFCAM".

=cut

sub this_instrument {
  return "WFCAM";
}

=back

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping.  We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping).  The from_ methods take
a reference to a generic hash and return a translated hash (sometimes
these are many-to-many).

=over 4

=item B<to_DATA_UNITS>

Returns the data units.  This uses the C<BUNIT> header, with a default
of "counts/exp" (unless the observations was with a ND read type
between 2006-10-23 and 2006-12-20 when the default was "counts/sec").

=cut

sub to_DATA_UNITS {
  my $self = shift;
  my $FITS_headers = shift;
  my $data_units = 'counts/exp';

  if ( defined( $FITS_headers->{BUNIT} ) ) {
    $data_units = $FITS_headers->{BUNIT};
  } else {
    my $date = $self->to_UTDATE( $FITS_headers );

    if ( $date > 20061023 && $date < 20061220 ) {

      my $read_type = $self->to_DETECTOR_READ_TYPE( $FITS_headers );
      if ( substr( $read_type, 0, 2 ) eq 'ND' ) {

        $data_units = 'counts/sec';
      }
    }
  }

  return $data_units;

}

=item B<to_DEC_SCALE>

Returns the declination pixel scale in in arcseconds per pixel.  For
Cameras 1 and 3, it scales the C<CD2_1> keyword to the C<DEC_SCALE>
generic header.  For Cameras 2 and 4, it scales the C<CD2_2> keyword
instead.

=cut

sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;

  my $scale;
  my $camnum = $self->to_CAMERA_NUMBER( $FITS_headers );
  if ( defined( $camnum ) ) {
    if ( defined( $FITS_headers->{CD2_1} ) &&
         defined( $FITS_headers->{CD1_2} ) &&
         defined( $FITS_headers->{CD2_2} ) ) {

      if ( $camnum == 1 ) {
        $scale = $FITS_headers->{CD2_1} * 3600;
      } elsif ( $camnum == 3 ) {
        $scale = $FITS_headers->{CD2_1} * 3600;
      } elsif ( $camnum == 2 || $camnum == 4 ) {
        $scale = $FITS_headers->{CD2_2} * 3600;
      }
    }
  }
  return $scale;
}

=item B<from_DEC_SCALE>

For Cameras 1 and 3, it scales the C<DEC_SCALE> generic header to the
C<CD2_1> header.  For Cameras 2 and 4, it scales C<DEC_SCALE> to the
C<CD2_2> header.  The returned units are degrees per pixel.

=cut

sub from_DEC_SCALE {
  my $self = shift;
  my $generic_headers = shift;

  my %return_hash;

  my $dec_scale = $generic_headers->{'DEC_SCALE'};
  my $camnum = $generic_headers->{'CAMERA_NUMBER'};

  if ( defined( $dec_scale ) &&
       defined( $camnum ) ) {

    if ( $camnum == 1 || $camnum == 3 ) {
      $return_hash{'CD2_1'} = $dec_scale / 3600;
    } elsif ( $camnum == 2 || $camnum == 4 ) {
      $return_hash{'CD2_2'} = $dec_scale / 3600;
    }
  }

  return %return_hash;
}

=item B<to_GAIN>

Determines the gain entirely from camera number.

The GAIN FITS header is not used.

=cut

sub to_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $gain;
  if ( defined( $FITS_headers->{CAMNUM} ) ) {
    my $camnum = $FITS_headers->{CAMNUM};
    if ( $camnum == 1 || $camnum == 2 || $camnum == 3 ) {
      $gain = 4.6;
    } elsif ( $camnum == 4 ) {
      $gain = 5.6;
    } else {
      $gain = 1.0;
    }
  } else {
    $gain = 1.0;
  }
  return $gain;
}

=item B<from_GAIN>

This is a null operation.  The C<GAIN> FITS header in WFCAM data is
always incorrect.

=cut

sub from_GAIN {
  return ();
}

=item B<to_NUMBER_OF_OFFSETS>

Return the number of offsets (jitters and micro steps).

=cut

sub to_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $FITS_headers = shift;
  my $njitter = ( defined( $FITS_headers->{NJITTER} ) ? $FITS_headers->{NJITTER} : 1 );
  my $nustep = ( defined( $FITS_headers->{NUSTEP} ) ? $FITS_headers->{NUSTEP} : 1 );

  return $njitter * $nustep + 1;

}

=item B<to_RA_BASE>

Returns the C<RABASE> header converted to degrees.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  return ($FITS_headers->{RABASE} * 15.0);
}

=item B<to_RA_SCALE>

Returns the right-ascension pixel scale in arcseconds per pixel. For
Cameras 1 and 3, it scales the C<CD1_2> keyword to the C<RA_SCALE>
generic header.  For Cameras 2 and 4, it scales the C<CD1_1> keyword
instead.

=cut

sub to_RA_SCALE {
  my $self = shift;
  my $FITS_headers = shift;

  my $scale;
  my $camnum = $self->to_CAMERA_NUMBER( $FITS_headers );
  if ( defined( $camnum ) ) {
    if ( defined( $FITS_headers->{CD1_1} ) &&
         defined( $FITS_headers->{CD1_2} ) ) {

      if ( $camnum == 1 || $camnum == 3 ) {
        $scale = $FITS_headers->{CD1_2} * 3600;
      } elsif ( $camnum == 2 || $camnum == 4 ) {
        $scale = $FITS_headers->{CD1_1} * 3600;
      }
    }
  }
  return $scale;
}

=item B<from_RA_SCALE>

For Cameras 1 and 3, it scales the C<RA_SCALE> generic header to the
C<CD1_2> keyword.  For Cameras 2 and 4, scales C<RA_SCALE> to the
C<CD1_1> keyword.  Returned units are degrees per pixel.

=cut

sub from_RA_SCALE {
  my $self = shift;
  my $generic_headers = shift;

  my %return_hash;

  my $ra_scale = $generic_headers->{'RA_SCALE'};
  my $camnum = $generic_headers->{'CAMERA_NUMBER'};

  if ( defined( $ra_scale ) &&
       defined( $camnum ) ) {

    if ( $camnum == 1 || $camnum == 3 ) {
      $return_hash{'CD1_2'} = $ra_scale / 3600;
    } elsif ( $camnum == 2 || $camnum == 4 ) {
      $return_hash{'CD1_1'} = $ra_scale / 3600;
    }
  }

  return %return_hash;
}

=item B<to_ROTATION>

Determines the rotation of the array in world co-ordinates.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $cd11 = $FITS_headers->{CD1_1};
  my $cd12 = $FITS_headers->{CD1_2};
  my $cd21 = $FITS_headers->{CD2_1};
  my $cd22 = $FITS_headers->{CD2_2};

  my $rad = 45 / atan2( 1, 1 );

  my $rho_a = $rad * atan2( -$cd12 / $rad, $cd22 / $rad );
  my $rho_b = $rad * atan2(  $cd21 / $rad, $cd11 / $rad );
  my $rotation = -0.5 * ( $rho_a + $rho_b );

  return $rotation;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.
Malcolm J. Currie E<lt>mjc@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council.
Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council.
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
