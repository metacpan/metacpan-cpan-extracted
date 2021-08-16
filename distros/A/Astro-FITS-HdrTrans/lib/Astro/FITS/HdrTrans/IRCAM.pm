package Astro::FITS::HdrTrans::IRCAM;

=head1 NAME

Astro::FITS::HdrTrans::IRCAM - UKIRT IRCAM translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::IRCAM;

  %gen = Astro::FITS::HdrTrans::IRCAM->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific
to the IRCAM camera of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRT "Old"
use base qw/ Astro::FITS::HdrTrans::UKIRTOld /;

use vars qw/ $VERSION /;

$VERSION = "1.64";

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (

                );

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.

# Note that header merging fails with IRCAM in some cases because
# some items are duplicated in the .HEADER and .I1 but using different
# comment strings so the merging routine does not realise they are the
# same header. It is arguably an error that Astro::FITS::Header looks
# at comments.

my %UNIT_MAP = (
                AIRMASS_START        => 'AMSTART',
                # IRCAM Specific
                OBSERVATION_NUMBER   => 'RUN', # cf. OBSNUM
                DEC_TELESCOPE_OFFSET => 'DECOFF',
                DETECTOR_BIAS        => 'DET_BIAS',
                RA_TELESCOPE_OFFSET  => 'RAOFF',
               );

# END observation unit maps
my %ENDOBS_MAP = (
                  AIRMASS_END         => 'AMEND',
                  NUMBER_OF_EXPOSURES => 'NEXP', # need it from the last subheader
                 );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, undef, \%ENDOBS_MAP );

# Im

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns a pattern match for /^IRCAM\d?/".

=cut

sub this_instrument {
  return qr/^IRCAM\d?/i;
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_DEC_SCALE>

Pixel scale along the Declination axis in arcseconds.  If the pixel
scale is not defined in the PIXELSIZ or CDELT2 headers, then default
to 0.08144 arcseconds for data taken after 19990901, or 0.286
arcseconds for older data.  The value will always be positive.

=cut

sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $scale;
  my $pixelsiz = $FITS_headers->{PIXELSIZ};
  my $ctype2 = $FITS_headers->{CTYPE2};
  my $cdelt2 = $FITS_headers->{CDELT2};
  my $utdate = $self->to_UTDATE( $FITS_headers );

  # The CDELTn headers may be part of a WCS in expressed in the AIPS-convention
  # measured in degrees (but protect against cases where it may have been in
  # arcsec).
  if ( defined( $cdelt2 ) && defined( $ctype2 ) && $ctype2 eq "DEC--TAN" ) {
    $scale = $cdelt2;
    if ( abs( $scale ) < 1.0E-3 ) {
      $scale *= 3600.0;
    }
  } else {
    $scale = $pixelsiz;
  }

  # Use the default scales.  The first IRCAM scale did vary with time,
  # but the information is no longer on the UKIRT web site.
  if ( ! defined( $scale ) ) {
    if ( $utdate > 19990901 ) {
      $scale = 0.08144;
    } else {
      $scale = 0.286;
    }
  }

  # Headers may be in scientific notation, but with a 'D' instead of
  # an 'E'.  Translate to an 'E' so Perl doesn't fall over.
  $scale =~ s/D/E/;

  return abs( $scale );
}

=item B<from_DEC_SCALE>

Generate the PIXELSIZ or CDELT2 header for IRCAM2 or IRCAM3 data
respectively.  The header will be returned in arcseconds, and will
always be positive.

=cut

sub from_DEC_SCALE {
  my $self = shift;
  my $generic_headers = shift;
  my $scale = abs( $generic_headers->{DEC_SCALE} );

  # Need to find way to allow for new and old headers with differing units.
  return ( "PIXELSIZ", $scale );
}

=item B<to_POLARIMETRY>

Checks the filter name.

=cut

sub to_POLARIMETRY {
  my $self = shift;
  my $FITS_headers = shift;
  if ( exists( $FITS_headers->{FILTER} ) &&
       $FITS_headers->{FILTER} =~ /pol/i ) {
    return 1;
  } else {
    return 0;
  }
}

=item B<to_RA_SCALE>

Returns the pixel scale along the RA axis in arcseconds.  If the pixel
scale is not defined in the PIXELSIZ or CDELT1 headers, then default
to -0.08144 arcseconds for data taken after 19990901, or -0.286
arcseconds for older data.  The value will always be negative.

=cut

sub to_RA_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $scale;
  my $pixelsiz = $FITS_headers->{PIXELSIZ};
  my $ctype1 = $FITS_headers->{CTYPE1};
  my $cdelt1 = $FITS_headers->{CDELT1};
  my $utdate = $self->to_UTDATE( $FITS_headers );

  # The CDELTn headers may be part of a WCS in expressed in the AIPS-convention
  # measured in degrees (but protect against cases where it may have been in
  # arcsec).
  if ( defined( $cdelt1 ) && defined( $ctype1 ) && $ctype1 eq "RA---TAN" ) {
    $scale = $cdelt1;
    if ( abs( $scale ) < 1.0E-3 ) {
      $scale *= 3600.0;
    }
  } else {
    $scale = $pixelsiz;
  }

  # Use the default scales.  The first IRCAM scale did vary with time,
  # but the information is no longer on the UKIRT web site.
  if ( ! defined( $scale ) ) {
    if ( $utdate > 19990901 ) {
      $scale = -0.08144;
    } else {
      $scale = -0.286;
    }
  }

  # Headers may be in scientific notation, but with a 'D' instead of
  # an 'E'.  Translate to an 'E' so Perl doesn't fall over.
  $scale =~ s/D/E/;

  # Correct erroneous positive RA scale in some headers.
  if ( $scale > 0.0 ) {
    $scale *= -1.0;
  }

  return $scale;
}

=item B<from_RA_SCALE>

Generates the PIXELSIZ or CDELT1 header for IRCAM2 or IRCAM3 data
respectively.  The header will be returned in arcseconds, and will
always be negative.

=cut

sub from_RA_SCALE {
  my $self = shift;
  my $generic_headers = shift;
  my $scale = abs( $generic_headers->{RA_SCALE} );

  # Need to find way to allow for new and old headers with differing units.
  return ( "PIXELSIZ", $scale );
}


=item B<to_SPEED_GAIN>

For data taken before 22 November 2000, the SPD_GAIN header was not
written.  Obtain the SPEED_GAIN from the detector bias if the SPD_GAIN
header is not defined.  If the detector bias is between 0.61 and 0.63,
then the SPEED_GAIN is Standard.  Otherwise, it is Deepwell.

=cut

sub to_SPEED_GAIN {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if ( defined( $FITS_headers->{SPD_GAIN} ) ) {
    $return = $FITS_headers->{SPD_GAIN};
  } else {
    my $detector_bias = $self->to_DETECTOR_BIAS( $FITS_headers );
    if ( $detector_bias > 0.61 && $detector_bias < 0.63 ) {
      $return = "Standard";
    } else {
      $return = "Deepwell";
    }
  }
  return $return;
}

=item B<from_SPEED_GAIN>

Translates the SPEED_GAIN generic header into the SPD_GAIN
IRCAM-specific header.  Note that this will break bi-directional tests
as the SPD_GAIN header did not exist in data taken before 2000
November 22.

=cut

sub from_SPEED_GAIN {
  my $self = shift;
  my $generic_headers = shift;
  return( "SPD_GAIN", $generic_headers->{"SPEED_GAIN"} )
}

=item B<from_TELESCOPE>

For data taken before 20000607, return 'UKIRT, Mauna Kea, HI'. For
data taken on and after 20000607, return
'UKIRT,Mauna_Kea,HI'. Returned header is C<TELESCOP>.

=cut

sub from_TELESCOPE {
  my $self = shift;
  my $generic_headers = shift;
  my $utdate = $generic_headers->{'UTDATE'};
  if ( $utdate < 20000607 ) {
    return( "TELESCOP", "UKIRT, Mauna Kea, HI" );
  } else {
    return( "TELESCOP", "UKIRT,Mauna_Kea,HI" );
  }
}

=item B<to_X_REFERENCE_PIXEL>

Specify the reference pixel, which is normally near the frame centre.
Note that offsets for polarimetry are undefined.

=cut

sub to_X_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $xref;

  # Use the average of the bounds to define the centre.
  if ( exists $FITS_headers->{RDOUT_X1} && exists $FITS_headers->{RDOUT_X2} ) {
    my $xl = $FITS_headers->{RDOUT_X1};
    my $xu = $FITS_headers->{RDOUT_X2};
    $xref = $self->nint( ( $xl + $xu ) / 2 );

    # Use a default of the centre of the full array.
  } else {
    $xref = 129;
  }
  return $xref;
}

=item B<from_X_REFERENCE_PIXEL>

Returns CRPIX1.

=cut

sub from_X_REFERENCE_PIXEL {
  my $self = shift;
  my $generic_headers = shift;
  return ( "CRPIX1", $generic_headers->{"X_REFERENCE_PIXEL"} );
}

=item B<to_Y_REFERENCE_PIXEL>

Specify the reference pixel, which is normally near the frame centre.
Note that offsets for polarimetry are undefined.

=cut

sub to_Y_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $yref;

  # Use the average of the bounds to define the centre.
  if ( exists $FITS_headers->{RDOUT_Y1} && exists $FITS_headers->{RDOUT_Y2} ) {
    my $yl = $FITS_headers->{RDOUT_Y1};
    my $yu = $FITS_headers->{RDOUT_Y2};
    $yref = $self->nint( ( $yl + $yu ) / 2 );

    # Use a default of the centre of the full array.
  } else {
    $yref = 129;
  }
  return $yref;
}

=item B<from_X_REFERENCE_PIXEL>

Returns CRPIX2.

=cut

sub from_Y_REFERENCE_PIXEL {
  my $self = shift;
  my $generic_headers = shift;
  return ( "CRPIX2", $generic_headers->{"Y_REFERENCE_PIXEL"} );
}

=item B<to_ROTATION>

Returns fixed rotation values based on the UT date.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $utdate = $self->to_UTDATE($FITS_headers);

  if ($utdate < 19990901) {
    return 1.5;
  }

  # TODO: determine correct sense for later rotations given on the
  # IRCAM website http://www.jach.hawaii.edu/UKIRT/instruments/ircam/scale.html
  # Sept 99: -89.04
  # June 01: -88.84

  return 0.0;
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
