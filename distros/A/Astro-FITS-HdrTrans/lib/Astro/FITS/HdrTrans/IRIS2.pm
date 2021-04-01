package Astro::FITS::HdrTrans::IRIS2;

=head1 NAME

Astro::FITS::HdrTrans::IRIS2 - IRIS-2 Header translations

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

  %FITS_headers = transate_to_FITS(\%generic_headers, \@header_array);

=head1 DESCRIPTION

Converts information contained in AAO IRIS2 FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use Math::Trig qw/ acos deg2rad rad2deg /;

# Inherit from Base
use base qw/ Astro::FITS::HdrTrans::Base /;

use vars qw/ $VERSION /;

# Note that we use %02 not %03 because of historical reasons
$VERSION = "1.63";


# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 COORDINATE_UNITS    => 'degrees',
                 GAIN                => 5.2,
                 NSCAN_POSITIONS     => 1,
                 SCAN_INCREMENT      => 1,
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = ();

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                DEC_BASE             => "CRVAL2",
                DEC_TELESCOPE_OFFSET => "TDECOFF",
                DETECTOR_INDEX       => "DINDEX",
                DETECTOR_READ_TYPE   => "METHOD",
                DR_GROUP             => "GRPNUM",
                DR_RECIPE            => "RECIPE",
                EQUINOX              => "EQUINOX",
                EXPOSURE_TIME        => "EXPOSED",
                INSTRUMENT           => "INSTRUME",
                NUMBER_OF_EXPOSURES  => "CYCLES",
                NUMBER_OF_OFFSETS    => "NOFFSETS",
                NUMBER_OF_READS      => "READS",
                OBJECT               => "OBJECT",
                OBSERVATION_NUMBER   => "RUN",
                OBSERVATION_TYPE     => "OBSTYPE",
                RA_BASE              => "CRVAL1",
                RA_TELESCOPE_OFFSET  => "TRAOFF",
                SLIT_ANGLE           => "TEL_PA",
                SLIT_NAME            => "SLIT",
                SPEED_GAIN           => "SPEED",
                STANDARD             => "STANDARD",
                TELESCOPE            => "TELESCOP",
                WAVEPLATE_ANGLE      => "WPLANGLE",
                X_DIM                => "NAXIS1",
                X_LOWER_BOUND        => "DETECXS",
                X_OFFSET             => "RAOFF",
                X_REFERENCE_PIXEL    => "CRPIX1",
                X_UPPER_BOUND        => "DETECXE",
                Y_BASE               => "DECBASE",
                Y_DIM                => "NAXIS2",
                Y_LOWER_BOUND        => "DETECYS",
                Y_OFFSET             => "DECOFF",
                Y_REFERENCE_PIXEL    => "CRPIX2",
                Y_UPPER_BOUND        => "DETECYE",
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

Returns "IRIS2".

=cut

sub this_instrument {
  return "IRIS2";
}

=back

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many)

=over 4

=item B<to_AIRMASS_END>

Converts FITS header value of zenith distance into airmass value.

=cut

sub to_AIRMASS_END {
  my $self = shift;
  my $FITS_headers = shift;
  my $pi = atan2( 1, 1 ) * 4;
  my $return;
  if (exists($FITS_headers->{ZDEND})) {
    $return = 1 /  cos( deg2rad($FITS_headers->{ZDEND}) );
  }

  return $return;

}

=item B<from_AIRMASS_END>

Converts airmass into zenith distance.

=cut

sub from_AIRMASS_END {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{AIRMASS_END})) {
    $return_hash{ZDEND} = rad2deg(acos($generic_headers->{AIRMASS_END}));
  }
  return %return_hash;
}

=item B<to_AIRMASS_START>

Converts FITS header value of zenith distance into airmass value.

=cut

sub to_AIRMASS_START {
  my $self = shift;
  my $FITS_headers = shift;
  my $pi = atan2( 1, 1 ) * 4;
  my $return;
  if (exists($FITS_headers->{ZDSTART})) {
    $return = 1 /  cos( deg2rad($FITS_headers->{ZDSTART}) );
  }

  return $return;

}

=item B<from_AIRMASS_START>

Converts airmass into zenith distance.

=cut

sub from_AIRMASS_START {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{AIRMASS_START})) {
    $return_hash{ZDSTART} = rad2deg(acos($generic_headers->{AIRMASS_START}));
  }
  return %return_hash;
}

=item B<to_COORDINATE_TYPE>

Converts the C<EQUINOX> FITS header into B1950 or J2000, depending
on equinox value, and sets the C<COORDINATE_TYPE> generic header.

=cut

sub to_COORDINATE_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{EQUINOX})) {
    if ($FITS_headers->{EQUINOX} =~ /1950/) {
      $return = "B1950";
    } elsif ($FITS_headers->{EQUINOX} =~ /2000/) {
      $return = "J2000";
    }
  }
  return $return;
}

=item B<to_DEC_SCALE>

Calculate the Declination pixel scale from the CD matrix.

=cut

sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
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
  return abs( sqrt( $cd11**2 + $cd21**2 ) );
}

=item B<to_FILTER>

Determine the filter name. Depends on the value of IR2_FILT.

=cut

sub to_FILTER {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( $FITS_headers->{IR2_FILT} =~ /^OPEN$/i ) {
    $return = $FITS_headers->{IR2_COLD};
  } else {
    $return = $FITS_headers->{IR2_FILT};
  }
  $return =~ s/ //g;
  return $return;
}

=item B<to_GRATING_DISPERSION>

Calculate grating dispersion.

Dispersion is only a function of grism and blocking filter used, but
need to allow for various choices of blocking filter

=cut

sub to_GRATING_DISPERSION {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  my $obsmode = $self->to_OBSERVATION_MODE( $FITS_headers );
  my $filter = $self->to_FILTER( $FITS_headers );

  if ( $obsmode eq 'spectroscopy' ) {
    if ( uc($filter) eq 'K' || uc($filter) eq 'KS' ) {
      $return = 0.0004423;
    } elsif ( uc($filter) eq 'JS' ) {
      $return = 0.0002322;
    } elsif ( uc($filter) eq 'J' || uc($filter) eq 'JL' ) {
      $return = 0.0002251;
    } elsif ( uc($filter) eq 'H' || uc($filter) eq 'HS' || uc($filter) eq 'HL' ) {
      $return = 0.0003413;
    }
  }
  return $return;
}

=item B<to_GRATING_DISPERSION>

Calculate grating wavelength.

Central wavelength is a function of grism + blocking filter + slit
used. Assume offset slit used for H/Hs and Jl, otherwise centre slit
is used. Central wavelengths computed for pixel 513, to match
calculation used in ORAC-DR.

=cut

sub to_GRATING_WAVELENGTH {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  my $obsmode = $self->to_OBSERVATION_MODE( $FITS_headers );
  my $filter = $self->to_FILTER( $FITS_headers );

  if ( $obsmode eq 'spectroscopy' ) {
    if ( uc( $filter ) eq 'K' || uc( $filter ) eq 'KS' ) {
      $return = 2.249388;
    } elsif ( uc($filter) eq 'JS' ) {
      $return = 1.157610;
    } elsif ( uc($filter) eq 'J' || uc($filter) eq 'JL' ) {
      $return = 1.219538;
    } elsif ( uc($filter) eq 'H' || uc($filter) eq 'HS' || uc($filter) eq 'HL' ) {
      $return = 1.636566;
    }
  }
  return $return;
}

=item B<to_OBSERVATION_MODE>

Determines the observation mode from the IR2_SLIT or IR2_GRSM FITS header values. If
IR2_SLIT value is equal to "OPEN1", then the observation mode is imaging.
Otherwise, the observation mode is spectroscopy. If IR2_GRSM is matches SAP or SIL then
it is spectroscopy. IR2_GRSM is used in preference to IR2_SLIT.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{IR2_GRSM})) {
    $return = ($FITS_headers->{IR2_GRSM} =~ /^(SAP|SIL)/i) ? "spectroscopy" : "imaging";
  } elsif (exists($FITS_headers->{IR2_SLIT})) {
    $return = ($FITS_headers->{IR2_SLIT} eq "OPEN1") ? "imaging" : "spectroscopy";
  }
  return $return;
}

=item B<to_RA_SCALE>

Calculate the right-ascension pixel scale from the CD matrix.

=cut

sub to_RA_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $cd12 = $FITS_headers->{CD1_2};
  my $cd22 = $FITS_headers->{CD2_2};
  return sqrt( $cd12**2 + $cd22**2 );
}

=item B<to_UTDATE>

Converts FITS header values into standard UT date value of the form
YYYYMMDD.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{UTDATE})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/://g;
    $return = $utdate;
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in the form C<yyyymmdd> to C<yyyy:mm:dd>.

=cut

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTDATE})) {
    my $date = $generic_headers->{UTDATE};
    return () unless defined $date;
    $return_hash{UTDATE} = substr($date,0,4).":".
      substr($date,4,2).":".substr($date,6,2);
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts FITS header UT date/time values for the end of the observation into
a C<Time::Piece> object.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{UTDATE}) && exists($FITS_headers->{UTEND})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/g;
    $return = $utdate . "T" . $FITS_headers->{UTEND};
    $return = $self->_parse_iso_date( $return );
  }
  return $return;
}

=item B<from_UTEND>

Converts end date into two FITS headers for IRIS2: UTDATE
(in the format YYYYMMDD) and UTEND (HH:MM:SS).

=cut

sub from_UTEND {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTEND})) {
    my $date = $generic_headers->{UTEND};
    $return_hash{UTDATE} = sprintf("%04d:%02d:%02d",
                                   $date->year, $date->mon, $date->mday);
    $return_hash{UTEND} = sprintf("%02d:%02d:%02d",
                                  $date->hour, $date->minute, $date->second);
  }
  return %return_hash;
}

=item B<to_UTSTART>

Converts FITS header UT date/time values for the start of the observation
into a C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{UTDATE}) && exists($FITS_headers->{UTSTART})) {
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/-/g;
    $return = $utdate . "T" . $FITS_headers->{UTSTART} . "";
    $return = $self->_parse_iso_date( $return );
  }
  return $return;
}

=item B<from_UTSTART>

Converts the date into two FITS headers for IRIS2: UTDATE
(in the format YYYYMMDD) and UTSTART (HH:MM:SS).

=cut

sub from_UTSTART {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTSTART})) {
    my $date = $generic_headers->{UTSTART};
    $return_hash{UTDATE} = sprintf("%04d:%02d:%02d",
                                   $date->year, $date->mon, $date->mday);
    $return_hash{UTSTART} = sprintf("%02d:%02d:%02d",
                                    $date->hour, $date->minute, $date->second);
  }
  return %return_hash;
}

=item B<to_X_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<X_BASE>.

=cut

sub to_X_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{RABASE})) {
    $return = $FITS_headers->{RABASE} * 15;
  }
  return $return;
}

=item B<from_X_BASE>

Converts the decimal degrees in the generic header C<X_BASE>
into decimal hours for the FITS header C<RABASE>.

=cut

sub from_X_BASE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{X_BASE})) {
    $return_hash{'RABASE'} = $generic_headers->{X_BASE} / 15;
  }
  return %return_hash;
}

=item B<to_X_SCALE>

Converts a linear transformation matrix into a pixel scale in the right
ascension axis.  Results are in arcseconds per pixel.

=cut

# X_SCALE conversion courtesy Micah Johnson, from the cdelrot.pl script
# supplied for use with XIMAGE.

sub to_X_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{CD1_2}) &&
      exists($FITS_headers->{CD2_2}) ) {
    my $cd12 = $FITS_headers->{CD1_2};
    my $cd22 = $FITS_headers->{CD2_2};
    $return = sqrt( $cd12**2 + $cd22**2 ) * 3600;
  }
  return $return;
}

=item B<to_Y_SCALE>

Converts a linear transformation matrix into a pixel scale in the declination
axis. Results are in arcseconds per pixel.

=cut

# Y_SCALE conversion courtesy Micah Johnson, from the cdelrot.pl script
# supplied for use with XIMAGE.

sub to_Y_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{CD1_1}) &&
      exists($FITS_headers->{CD1_2}) &&
      exists($FITS_headers->{CD2_1}) &&
      exists($FITS_headers->{CD2_2}) ) {
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
    $return = $sgn * sqrt( $cd11**2 + $cd21**2 ) * 3600;
  }
  return $return;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council.
Copyright (C) 2002-2007 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
