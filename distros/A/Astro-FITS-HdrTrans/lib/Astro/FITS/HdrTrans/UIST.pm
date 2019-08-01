package Astro::FITS::HdrTrans::UIST;

=head1 NAME

Astro::FITS::HdrTrans::UIST - UKIRT UIST translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UIST;

  %gen = Astro::FITS::HdrTrans::UIST->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the UIST camera and spectrometer of the United Kingdom Infrared
Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRTNew
use base qw/ Astro::FITS::HdrTrans::UKIRTNew /;

use vars qw/ $VERSION /;

$VERSION = "1.62";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 NSCAN_POSITIONS     => 1,
                 SCAN_INCREMENT      => 1,
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ DETECTOR_INDEX /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                RA_SCALE             => "CDELT2",

                # UIST specific
                GRATING_NAME         => "GRISM",

                # Not imaging
                GRATING_DISPERSION   => "DISPERSN",
                GRATING_NAME         => "GRISM",
                GRATING_ORDER        => "GRATORD",
                GRATING_WAVELENGTH   => "CENWAVL",
                SLIT_ANGLE           => "SLIT_PA",
                SLIT_WIDTH           => "SLITWID",

                # MICHELLE compatible
                CHOP_ANGLE           => "CHPANGLE",
                CHOP_THROW           => "CHPTHROW",
                DETECTOR_READ_TYPE   => "DET_MODE",
                NUMBER_OF_READS      => "NREADS",
                OBSERVATION_MODE     => "INSTMODE",
                POLARIMETRY          => "POLARISE",
                SLIT_NAME            => "SLITNAME",

                # CGS4 + MICHELLE + WFCAM
                CONFIGURATION_INDEX  => 'CNFINDEX',
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

Returns "UIST".

=cut

sub this_instrument {
  return "UIST";
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_DEC_SCALE>

Pixel scale in degrees.  For imaging, the declination pixel scale is
in the CDELT1 header, and for spectroscopy and IFU, it's in CDELT3.

=cut

sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( $self->to_OBSERVATION_MODE($FITS_headers) eq 'imaging' ) {
    $return = $FITS_headers->{CDELT1};
  } else {
    $return = $FITS_headers->{CDELT3};
  }
  return $return;
}

=item B<from_DEC_SCALE>

Generate the PIXLSIZE header.

=cut

sub from_DEC_SCALE {
  my $self = shift;
  my $generic_headers = shift;

  # Can calculate the pixel size...
  my $scale = abs( $generic_headers->{DEC_SCALE} );
  $scale *= 3600;
  my %result = ( PIXLSIZE => $scale );

  # and either CDELT1 or CDELT3.
  my $ckey = 'CDELT3';
  if ( $generic_headers->{OBSERVATION_MODE} eq 'imaging' ) {
    $ckey = 'CDELT1';
  }
  $result{$ckey} = $generic_headers->{DEC_SCALE};
  return %result;
}

=item B<to_ROTATION>

ROTATION comprises the rotation matrix with respect to flipped axes,
i.e. x corresponds to declination and Y to right ascension.  For other
UKIRT instruments this was not the case, the rotation being defined
in CROTA2.  Here the effective rotation is that evaluated from the
PC matrix with a 90-degree counter-clockwise rotation for the rotated
axes. If there is a PC3_2 header, we assume that we're in spectroscopy
mode and use that instead.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $rotation;
  if ( exists( $FITS_headers->{PC1_1} ) && exists( $FITS_headers->{PC2_1}) ) {
    my $pc11;
    my $pc21;
    if ( exists ($FITS_headers->{PC3_2} ) && exists( $FITS_headers->{PC2_2} ) ) {

      # We're in spectroscopy mode.
      $pc11 = $FITS_headers->{PC3_2};
      $pc21 = $FITS_headers->{PC2_2};
    } else {

      # We're in imaging mode.
      $pc11 = $FITS_headers->{PC1_1};
      $pc21 = $FITS_headers->{PC2_1};
    }
    my $rad = 57.2957795131;
    $rotation = $rad * atan2( -$pc21 / $rad, $pc11 / $rad ) + 90.0;

  } elsif ( exists $FITS_headers->{CROTA2} ) {
    $rotation =  $FITS_headers->{CROTA2} + 90.0;
  } else {
    $rotation = 90.0;
  }
  return $rotation;
}


=item B<to_X_REFERENCE_PIXEL>

Use the nominal reference pixel if correctly supplied, failing that
take the average of the bounds, and if these headers are also absent,
use a default which assumes the full array.

=cut

sub to_X_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $xref;
  if ( exists $FITS_headers->{CRPIX1} ) {
    $xref = $FITS_headers->{CRPIX1};
  } elsif ( exists $FITS_headers->{RDOUT_X1} &&
            exists $FITS_headers->{RDOUT_X2} ) {
    my $xl = $FITS_headers->{RDOUT_X1};
    my $xu = $FITS_headers->{RDOUT_X2};
    $xref = $self->nint( ( $xl + $xu ) / 2 );
  } else {
    $xref = 480;
  }
  return $xref;
}

=item B<from_X_REFERENCE_PIXEL>

Always returns the value as CRPIX1.

=cut

sub from_X_REFERENCE_PIXEL {
  my $self = shift;
  my $generic_headers = shift;
  return ( "CRPIX1", $generic_headers->{"X_REFERENCE_PIXEL"} );
}

=item B<to_Y_REFERENCE_PIXEL>

Use the nominal reference pixel if correctly supplied, failing that
take the average of the bounds, and if these headers are also absent,
use a default which assumes the full array.

=cut

sub to_Y_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $yref;
  if ( exists $FITS_headers->{CRPIX2} ) {
    $yref = $FITS_headers->{CRPIX2};
  } elsif ( exists $FITS_headers->{RDOUT_Y1} &&
            exists $FITS_headers->{RDOUT_Y2} ) {
    my $yl = $FITS_headers->{RDOUT_Y1};
    my $yu = $FITS_headers->{RDOUT_Y2};
    $yref = $self->nint( ( $yl + $yu ) / 2 );
  } else {
    $yref = 480;
  }
  return $yref;
}

=item B<from_Y_REFERENCE_PIXEL>

Always returns the value as CRPIX2.

=cut

sub from_Y_REFERENCE_PIXEL {
  my $self = shift;
  my $generic_headers = shift;
  return ( "CRPIX2", $generic_headers->{"Y_REFERENCE_PIXEL"} );
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Malcolm J. Currie E<lt>mjc@star.rl.ac.ukE<gt>
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

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
