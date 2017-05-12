package Astro::FITS::HdrTrans::ESO;

=head1 NAME

Astro::FITS::HdrTrans::ESO - Base class for translation of ESO instruments

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::ESO;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
instrumentation from the European Southern Observatory. It should not be used
directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from the Base translation class and not HdrTrans itself
# (which is just a class-less wrapper).

use base qw/ Astro::FITS::HdrTrans::FITS /;

use Astro::FITS::HdrTrans::FITS;

use vars qw/ $VERSION /;

$VERSION = "1.59";

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (
                 SCAN_INCREMENT      => 1,
                 NSCAN_POSITIONS     => 1,
                );

# Unit mapping implies that the value propagates directly
# to the output with only a keyword name change.

my %UNIT_MAP = (
                DEC_SCALE            => "CDELT1",
                RA_SCALE             => "CDELT2",

                # then the spectroscopy...
                SLIT_NAME            => "HIERARCH.ESO.INS.OPTI1.ID",
                X_DIM                => "HIERARCH.ESO.DET.WIN.NX",
                Y_DIM                => "HIERARCH.ESO.DET.WIN.NY",

                # then the general.
                CHOP_ANGLE           => "HIERARCH.ESO.SEQ.CHOP.POSANGLE",
                CHOP_THROW           => "HIERARCH.ESO.SEQ.CHOP.THROW",
                EXPOSURE_TIME        => "EXPTIME",
                NUMBER_OF_EXPOSURES  => "HIERARCH.ESO.DET.NDIT",
                NUMBER_OF_READS      => "HIERARCH.ESO.DET.NCORRS",
                OBSERVATION_NUMBER   => "OBSNUM",
               );

# Create the translation methods.
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=cut

sub to_AIRMASS_END {
  my $self = shift;
  my $FITS_headers = shift;
  my $end_airmass = 1.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.TEL.AIRM.END"} ) {
    $end_airmass = $FITS_headers->{"HIERARCH.ESO.TEL.AIRM.END"};
  } elsif ( exists $FITS_headers->{AIRMASS} ) {
    $end_airmass = $FITS_headers->{AIRMASS};
  }
  return $end_airmass;
}

sub from_AIRMASS_END {
  my $self = shift;
  my $generic_headers = shift;
  "HIERARCH.ESO.TEL.AIRM.END", $generic_headers->{ "AIRMASS_END" };
}

sub to_AIRMASS_START {
  my $self = shift;
  my $FITS_headers = shift;
  my $start_airmass = 1.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.TEL.AIRM.START"} ) {
    $start_airmass = $FITS_headers->{"HIERARCH.ESO.TEL.AIRM.START"};
  } elsif ( exists $FITS_headers->{AIRMASS} ) {
    $start_airmass = $FITS_headers->{AIRMASS};
  }
  return $start_airmass;
}

sub from_AIRMASS_START {
  my $self = shift;
  my $generic_headers = shift;
  "HIERARCH.ESO.TEL.AIRM.START", $generic_headers->{ "AIRMASS_START" };
}

sub to_CONFIGURATION_INDEX {
  my $self = shift;
  my $FITS_headers = shift;
  my $instindex = 0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ENC"} ) {
    $instindex = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ENC"};
  }
  return $instindex;
}

sub to_DEC_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $dec = 0.0;
  if ( exists ( $FITS_headers->{DEC} ) ) {
    $dec = $FITS_headers->{DEC};
  }
  $dec = defined( $dec ) ? $dec: 0.0;
  return $dec;
}

# This is guesswork at present.  It's rather tied to the UKIRT names
# and we need generic names or use instrument-specific values in
# instrument-specific primitives, and pass the actual value for the
# night log.  Could do with separate CHOPPING, BIAS booleans
# to indicate whether or not chopping is enabled and whether or not the
# detector mode needs a bias removed, like UKIRT's STARE mode.
sub to_DETECTOR_READ_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $read_type;
  my $chop = $FITS_headers->{"HIERARCH.ESO.TEL.CHOP.ST"};
  $chop = defined( $chop ) ? $chop : 0;
  my $detector_mode = exists( $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} ) ?
    $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} : "NDSTARE";
  if ( $detector_mode =~ /Uncorr/ ) {
    if ( $chop ) {
      $read_type = "CHOP";
    } else {
      $read_type = "STARE";
    }
  } else {
    if ( $chop ) {
      $read_type = "NDCHOP";
    } else {
      $read_type = "NDSTARE";
    }
  }
  return $read_type;
}

# Equinox may be absent for calibrations such as darks.
sub to_EQUINOX {
  my $self = shift;
  my $FITS_headers = shift;
  my $equinox = 0;
  if ( exists $FITS_headers->{EQUINOX} ) {
    $equinox = $FITS_headers->{EQUINOX};
  }
  return $equinox;
}

sub to_GRATING_NAME{
  my $self = shift;
  my $FITS_headers = shift;
  my $name = "UNKNOWN";
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"} ) {
    $name = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"};
  }
  return $name;
}

sub to_GRATING_ORDER{
  my $self = shift;
  my $FITS_headers = shift;
  my $order = 1;
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ORDER"} ) {
    $order = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ORDER"};
  }
  return $order;
}

sub to_GRATING_WAVELENGTH{
  my $self = shift;
  my $FITS_headers = shift;
  my $wavelength = 0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.WLEN"} ) {
    $wavelength = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.WLEN"};
  }
  return $wavelength;
}

sub to_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $FITS_headers = shift;
  return $FITS_headers->{"HIERARCH.ESO.TPL.NEXP"} + 1;
}

sub from_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $generic_headers = shift;
  "HIERARCH.ESO.TPL.NEXP",  $generic_headers->{ "NUMBER_OF_OFFSETS" } - 1;
}

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->get_instrument_mode($FITS_headers);
}

sub from_OBSERVATION_MODE {
  my $self = shift;
  my $generic_headers = shift;
  "HIERARCH.ESO.DPR.TECH",  $generic_headers->{ "OBSERVATION_MODE" };
}

# OBJECT, SKY, and DARK need no change.
sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $type = $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"};
  $type = exists( $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"} ) ? uc( $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"} ) : "OBJECT";
  if ( $type eq "STD" ) {
    $type = "OBJECT";
  } elsif ( $type eq "SKY,FLAT" || $type eq "FLAT,SKY" ) {
    $type = "SKY";
  } elsif ( $type eq "LAMP,FLAT" || $type eq "FLAT,LAMP" ) {
    $type = "LAMP";
  } elsif ( $type eq "LAMP" || $type eq "WAVE,LAMP" ) {
    $type = "ARC";
  }
  return $type;
}

sub from_OBSERVATION_TYPE {
  my $self = shift;
  my $generic_headers = shift;
  "HIERARCH.ESO.DPR.TYPE",  $generic_headers->{ "OBSERVATION_TYPE" };
}

# Cater for OBJECT keyword with unhelpful value.
sub to_OBJECT {
  my $self = shift;
  my $FITS_headers = shift;
  my $object = undef;

  # The object name should be in OBJECT...
  if ( exists $FITS_headers->{OBJECT} ) {
    $object = $FITS_headers->{OBJECT};

    # Sometimes it's the generic STD for standard.
    if ( $object =~ /STD/ ) {
      if ( exists $FITS_headers->{"HIERARCH.ESO.OBS.TARG.NAME"} ) {
        $object = $FITS_headers->{"HIERARCH.ESO.OBS.TARG.NAME"};
      } else {
        $object = undef;
      }
    }
  }
  return $object;
}

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $ra = 0.0;
  if ( exists ( $FITS_headers->{RA} ) ) {
    $ra = $FITS_headers->{RA};
  }
  $ra = defined( $ra ) ? $ra: 0.0;
  return $ra;
}

=item B<to_ROTATION>

Derives the rotation angle from the rotation matrix.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->rotation( $FITS_headers );
}

sub to_SLIT_ANGLE {
  my $self = shift;
  my $FITS_headers = shift;
  my $slitangle = 0.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.ADA.POSANG"} ) {
    $slitangle =  $FITS_headers->{"HIERARCH.ESO.ADA.POSANG"};
  }
  return $slitangle;
}

sub from_SLIT_ANGLE {
  my $self = shift;
  my $generic_headers = shift;
  "HIERARCH.ESO.ADA.POSANG",  $generic_headers->{ "SLIT_ANGLE" };
}

sub to_STANDARD {
  my $self = shift;
  my $FITS_headers = shift;
  my $standard = 0;
  my $type = $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"};
  if ( uc( $type ) =~ /STD/ ) {
    $standard = 1;
  }
  return $standard;
}

sub from_STANDARD {
  my $self = shift;
  my $generic_headers = shift;
  "STANDARD",  $generic_headers->{ "STANDARD" };
}

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->get_UT_date( $FITS_headers );
}

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;

  # Obtain the start time.
  my $start = $self->to_UTSTART( $FITS_headers );

  # Approximate end time.
  return $self->_add_seconds( $start, $FITS_headers->{EXPTIME} );
}

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists $FITS_headers->{'DATE-OBS'} ) {
    $return = $self->_parse_iso_date( $FITS_headers->{'DATE-OBS'} );
  } elsif (exists $FITS_headers->{UTC}) {

    # Converts the UT date in YYYYMMDD format obytained from the headers to a
    # date object at midnight.  Then add the seconds past midnight to the
    # object.
    my $base = $self->to_UTDATE( $FITS_headers );
    my $basedate = $self->_utdate_to_object( $base );
    $return = $self->_add_seconds( $basedate, $FITS_headers->{UTC} );

  } elsif ( exists( $FITS_headers->{"HIERARCH.ESO.OBS.START"} ) ) {

    # Use the backup of the observation start header, which is encoded in
    # FITS data format, i.e. yyyy-mm-ddThh:mm:ss.
    $return = $self->_parse_iso_date( $FITS_headers->{"HIERARCH.ESO.OBS.START"});
  }
  return $return;
}

sub to_WAVEPLATE_ANGLE {
  my $self = shift;
  my $FITS_headers = shift;
  my $polangle = 0.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.ADA.POSANG"} ) {
    $polangle = $FITS_headers->{"HIERARCH.ESO.ADA.POSANG"};
  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.ROT.OFFANGLE"} ) {
    $polangle = $FITS_headers->{"HIERARCH.ESO.SEQ.ROT.OFFANGLE"};
  } elsif ( exists $FITS_headers->{CROTA1} ) {
    $polangle = abs( $FITS_headers->{CROTA1} );
  }
  return $polangle;
}

sub from_WAVEPLATE_ANGLE {
  my $self = shift;
  my $generic_headers = shift;
  "HIERARCH.ESO.ADA.POSANG",  $generic_headers->{ "WAVEPLATE_ANGLE" };
}

# Use the nominal reference pixel if correctly supplied, failing that
# take the average of the bounds, and if these headers are also absent,
# use a default which assumes the full array.
sub to_X_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $xref;
  if ( exists $FITS_headers->{CRPIX1} ) {
    $xref = $FITS_headers->{CRPIX1};
  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTX"} && exists $FITS_headers->{"HIERARCH.ESO.DET.WIN.NX"} ) {
    my $xl = $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTX"};
    my $xu = $FITS_headers->{"HIERARCH.ESO.DET.WIN.NX"};
    $xref = $self->nint( ( $xl + $xu ) / 2 );
  } else {
    $xref = 504;
  }
  return $xref;
}

sub to_X_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->nint( $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTX"} );
}

sub from_X_REFERENCE_PIXEL {
  my $self = shift;
  my $generic_headers = shift;
  "CRPIX1", $generic_headers->{"X_REFERENCE_PIXEL"};
}

sub to_X_UPPER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  return $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTX"} - 1 + $FITS_headers->{"HIERARCH.ESO.DET.WIN.NX"};
}

sub to_Y_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->nint( $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTY"} );
}

# Use the nominal reference pixel if correctly supplied, failing that
# take the average of the bounds, and if these headers are also absent,
# use a default which assumes the full array.
sub to_Y_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $yref;
  if ( exists $FITS_headers->{CRPIX2} ) {
    $yref = $FITS_headers->{CRPIX2};
  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTY"} && exists $FITS_headers->{"HIERARCH.ESO.DET.WIN.NY"} ) {
    my $yl = $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTY"};
    my $yu = $FITS_headers->{"HIERARCH.ESO.DET.WIN.NY"};
    $yref = $self->nint( ( $yl + $yu ) / 2 );
  } else {
    $yref = 491;
  }
  return $yref;
}

sub from_Y_REFERENCE_PIXEL {
  my $self = shift;
  my $generic_headers = shift;
  "CRPIX2", $generic_headers->{"Y_REFERENCE_PIXEL"};
}

sub to_Y_UPPER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  return $FITS_headers->{"HIERARCH.ESO.DET.WIN.STARTY"} - 1 + $FITS_headers->{"HIERARCH.ESO.DET.WIN.NY"};
}

# Supplementary methods for the translations
# ------------------------------------------

# Get the observation mode.
sub get_instrument_mode {
  my $self = shift;
  my $FITS_headers = shift;
  my $mode = uc( $FITS_headers->{"HIERARCH.ESO.DPR.TECH"} );
  if ( $mode eq "IMAGE" || $mode eq "POLARIMETRY" ) {
    $mode = "imaging";
  } elsif ( $mode =~ /SPECTRUM/ ) {
    $mode = "spectroscopy";
  }
  return $mode;
}

# Returns the UT date in YYYYMMDD format.
sub get_UT_date {
  my $self = shift;
  my $FITS_headers = shift;

  # This is UT start and time.
  my $dateobs = $FITS_headers->{"DATE-OBS"};

  # Extract out the data in yyyymmdd format.
  return substr( $dateobs, 0, 4 ) . substr( $dateobs, 5, 2 ) . substr( $dateobs, 8, 2 )
}

# Returns the UT time of start of observation in decimal hours.
sub get_UT_hours {
  my $self = shift;
  my $FITS_headers = shift;

  # This is approximate.  UTC is time in seconds.
  my $startsec = 0.0;
  if ( exists ( $FITS_headers->{UTC} ) ) {
    $startsec  = $FITS_headers->{UTC};

    # Use the backup of the observation start header, which is encoded in
    # FITS data format, i.e. yyyy-mm-ddThh:mm:ss.  So convert ot seconds.
  } elsif ( exists( $FITS_headers->{"HIERARCH.ESO.OBS.START"} ) ) {
    my $t = $FITS_headers->{"HIERARCH.ESO.OBS.START"};
    $startsec = substr( $t, 11, 2 ) * 3600.0 +
      substr( $t, 14, 2 ) * 60.0 + substr( $t, 17, 2  );
  }

  # Convert from seconds to decimal hours.
  return $startsec / 3600.0;
}

sub rotation {
  my $self = shift;
  my $FITS_headers = shift;
  my $rotangle;

  # Define degrees-to-radians conversion.
  my $dtor = atan2( 1, 1 ) / 45.0;

  # The PC matrix first.
  if ( exists $FITS_headers->{PC001001} ) {
    my $pc11 = $FITS_headers->{PC001001};
    my $pc21 = $FITS_headers->{PC002001};
    $rotangle = $dtor * atan2( -$pc21 / $dtor, $pc11 / $dtor );

    # Instead try CD matrix.  Testing for existence of first column should
    # be adequate.
  } elsif ( exists $FITS_headers->{CD1_1} && exists $FITS_headers->{CD2_1}) {

    my $cd11 = $FITS_headers->{CD1_1};
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd21 = $FITS_headers->{CD2_1};
    my $cd22 = $FITS_headers->{CD2_2};
    my $sgn;
    if ( ( $cd11 * $cd22 - $cd12 * $cd21 ) < 0 ) {
      $sgn = -1;
    } else {
      $sgn = 1;
    }
    my $cdelt1 = $sgn * sqrt( $cd11**2 + $cd21**2 );
    my $sgn2;
    if ( $cdelt1 < 0 ) {
      $sgn2 = -1;
    } else {
      $sgn2 = 1;
    }
    $rotangle = atan2( -$cd21 * $dtor, $sgn2 * $cd11 * $dtor ) / $dtor;

    # Orientation may be encapsulated in the slit position angle for
    # spectroscopy.
  } else {
    if ( uc( $self->get_instrument_mode($FITS_headers) ) eq "SPECTROSCOPY" &&
         exists $FITS_headers->{"HIERARCH.ESO.ADA.POSANG"} ) {
      $rotangle = $FITS_headers->{"HIERARCH.ESO.ADA.POSANG"};
    } else {
      $rotangle = 180.0;
    }
  }
  return $rotangle;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Malcolm J. Currie E<lt>mjc@star.rl.ac.ukE<gt>
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2007-2008 Science and Technology Facilities Council.
Copyright (C) 2006-2007 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either Version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307,
USA.

=cut

1;
