package Astro::FITS::HdrTrans::UKIRTDB;

=head1 NAME

Astro::FITS::HdrTrans::UKIRTDB - UKIRT Database Table translations

=head1 SYNOPSIS

  %generic_headers = translate_from_FITS(\%FITS_headers, \@header_array);

  %FITS_headers = transate_to_FITS(\%generic_headers, \@header_array);

=head1 DESCRIPTION

Converts information contained in UKIRTDB FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use Time::Piece;

# Inherit from Base
use base qw/ Astro::FITS::HdrTrans::JAC /;

use vars qw/ $VERSION /;

# Note that we use %02 not %03 because of historical reasons
$VERSION = "1.63";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 COORDINATE_UNITS => 'degrees',
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = ();

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                AIRMASS_START        => "AMSTART",
                AIRMASS_END          => "AMEND",
                CAMERA               => "CAMLENS",
                CAMERA_NUMBER        => "CAMNUM",
                CONFIGURATION_INDEX  => "CNFINDEX",
                DEC_BASE             => "DECBASE",
                DEC_SCALE            => "PIXELSIZ",
                DEC_TELESCOPE_OFFSET => "DECOFF",
                DETECTOR_READ_TYPE   => "MODE",
                DR_GROUP             => "GRPNUM",
                DR_RECIPE            => "RECIPE",
                EQUINOX              => "EQUINOX",
                FILTER               => "FILTER",
                FILENAME             => "FILENAME",
                GAIN                 => "DEPERDN",
                GRATING_DISPERSION   => "GDISP",
                GRATING_ORDER        => "GORDER",
                INSTRUMENT           => "INSTRUME",
                NUMBER_OF_COADDS => 'NEXP',
                NUMBER_OF_EXPOSURES  => "NEXP",
                OBJECT               => "OBJECT",
                OBSERVATION_MODE     => "INSTMODE",
                OBSERVATION_NUMBER   => "RUN",
                OBSERVATION_TYPE     => "OBSTYPE",
                PROJECT              => "PROJECT",
                RA_SCALE             => "PIXELSIZ",
                RA_TELESCOPE_OFFSET  => "RAOFF",
                TELESCOPE            => "TELESCOP",
                WAVEPLATE_ANGLE      => "WPLANGLE",
                Y_BASE               => "DECBASE",
                X_DIM                => "DCOLUMNS",
                Y_DIM                => "DROWS",
                X_OFFSET             => "RAOFF",
                Y_OFFSET             => "DECOFF",
                X_SCALE              => "PIXELSIZ",
                Y_SCALE              => "PIXELSIZ",
                X_LOWER_BOUND        => "RDOUT_X1",
                X_UPPER_BOUND        => "RDOUT_X2",
                Y_LOWER_BOUND        => "RDOUT_Y1",
                Y_UPPER_BOUND        => "RDOUT_Y2"
               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );


=head1 METHODS

=over 4

=item B<can_translate>

Determine if this class can handle the translation. Returns true
if the TELESCOP is "UKIRT" and there is a "FILENAME" key and
a "RAJ2000" key. These keywords allow the DB results to be disambiguated
from the actual file headers.

  $cando = $class->can_translate( \%hdrs );

=cut

sub can_translate {
  my $self = shift;
  my $FITS_headers = shift;
  if (exists $FITS_headers->{TELESCOP}
      && $FITS_headers->{TELESCOP} =~ /UKIRT/
      && exists $FITS_headers->{FILENAME}
      && exists $FITS_headers->{RAJ2000}) {
    return 1;
  }
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

=item B<to_INST_DHS>

Sets the INST_DHS header.

=cut

sub to_INST_DHS {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{DHSVER} ) ) {
    $FITS_headers->{DHSVER} =~ /^(\w+)/;
    my $dhs = uc($1);
    $return = $FITS_headers->{INSTRUME} . "_$dhs";
  } else {
    my $dhs = "UKDHS";
    $return = $FITS_headers->{INSTRUME} . "_$dhs";
  }

  return $return;

}

=item B<to_EXPOSURE_TIME>

Converts either the C<EXPOSED> or C<DEXPTIME> FITS header into
the C<EXPOSURE_TIME> generic header.

=cut

sub to_EXPOSURE_TIME {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'EXPOSED'} ) && defined( $FITS_headers->{'EXPOSED'} ) ) {
    $return = $FITS_headers->{'EXPOSED'};
  } elsif ( exists( $FITS_headers->{'DEXPTIME'} ) && defined( $FITS_headers->{'DEXPTIME'} ) ) {
    $return = $FITS_headers->{'DEXPTIME'};
  } elsif ( exists( $FITS_headers->{'EXP_TIME'} ) && defined( $FITS_headers->{'EXP_TIME'} ) ) {
    $return = $FITS_headers->{'EXP_TIME'};
  }
  return $return;
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

=item B<to_GRATING_NAME>

=cut

sub to_GRATING_NAME {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{GRATING})) {
    $return = $FITS_headers->{GRATING};
  } elsif (exists($FITS_headers->{GRISM})) {
    $return = $FITS_headers->{GRISM};
  }
  return $return;
}

=item B<to_GRATING_WAVELENGTH>

=cut

sub to_GRATING_WAVELENGTH {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{GLAMBDA})) {
    $return = $FITS_headers->{GLAMBDA};
  } elsif (exists($FITS_headers->{CENWAVL})) {
    $return = $FITS_headers->{CENWAVL};
  }
  return $return;
}

=item B<to_SLIT_ANGLE>

Converts either the C<SANGLE> or the C<SLIT_PA> header into the C<SLIT_ANGLE>
generic header.

=cut

sub to_SLIT_ANGLE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{'SANGLE'})) {
    $return = $FITS_headers->{'SANGLE'};
  } elsif (exists($FITS_headers->{'SLIT_PA'} )) {
    $return = $FITS_headers->{'SLIT_PA'};
  }
  return $return;

}

=item B<to_SLIT_NAME>

Converts either the C<SLIT> or the C<SLITNAME> header into the C<SLIT_NAME>
generic header.

=cut

sub to_SLIT_NAME {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{'SLIT'})) {
    $return = $FITS_headers->{'SLIT'};
  } elsif (exists($FITS_headers->{'SLITNAME'} )) {
    $return = $FITS_headers->{'SLITNAME'};
  }
  return $return;

}

=item B<to_SPEED_GAIN>

=cut

sub to_SPEED_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'SPD_GAIN'} ) ) {
    $return = $FITS_headers->{'SPD_GAIN'};
  } elsif ( exists( $FITS_headers->{'WAVEFORM'} ) ) {
    if ( $FITS_headers->{'WAVEFORM'} =~ /thermal/i ) {
      $return = 'thermal';
    } else {
      $return = 'normal';
    }
  }
  return $return;
}

=item B<to_STANDARD>

Converts either the C<STANDARD> header (if it exists) or uses the
C<OBJECT> or C<RECIPE> headers to determine if an observation is of a
standard.  If the C<OBJECT> header starts with either B<BS> or B<FS>,
I<or> the DR recipe contains the word STANDARD, it is assumed to be a
standard.

=cut

sub to_STANDARD {
  my $self = shift;
  my $FITS_headers = shift;

  # Set false as default so we do not have to repeat this in the logic
  # below (could just use undef == false)
  my $return = 0;               # default false

  if ( exists( $FITS_headers->{'STANDARD'} ) &&
       length( $FITS_headers->{'STANDARD'} . "") > 0 ) {

    if ($FITS_headers->{'STANDARD'} =~ /^[tf]$/i) {
      # Raw header read from FITS header
      $return = (uc($FITS_headers->{'STANDARD'}) eq 'T');
    } elsif ($FITS_headers->{'STANDARD'} =~ /^[01]$/) {
      # Translated header either so a true logical
      $return = $FITS_headers->{'STANDARD'};
    }

  } elsif ( ( exists $FITS_headers->{OBJECT} &&
              $FITS_headers->{'OBJECT'} =~ /^[bf]s/i ) ||
            ( exists( $FITS_headers->{'RECIPE'} ) &&
              $FITS_headers->{'RECIPE'} =~ /^standard/i
            )) {
    # Either we have an object with name prefix of BS or FS or
    # our recipe looks suspiciously like a standard.
    $return = 1;

  }

  return $return;

}

=item B<to_UTDATE>

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'UT_DATE'} ) ) {
    my $datestr = $FITS_headers->{'UT_DATE'};
    $return = _parse_date($datestr);
    die "Error parsing date \"$datestr\"" unless defined $return;
    $return = $return->strftime('%Y%m%d');
  }

  return $return;

}

=item B<to_UTSTART>

Strips the optional 'Z' from the C<DATE-OBS> header, or if that header does
not exist, combines the C<UT_DATE> and C<RUTSTART> headers into a unified
C<UTSTART> header.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'DATE_OBS'} ) ) {
    my $dateobs = $FITS_headers->{'DATE_OBS'};
    $return = $self->_parse_iso_date( $dateobs );
  } elsif (exists($FITS_headers->{'UT_DATE'}) && defined($FITS_headers->{'UT_DATE'}) &&
           exists($FITS_headers->{'RUTSTART'}) && defined( $FITS_headers->{'RUTSTART'} ) ) {
    # Use the default UTDATE translation but insert "-" for ISO parsing
    my $ut = $self->to_UTDATE($FITS_headers);
    $ut = join("-", substr($ut,0,4), substr($ut,4,2), substr($ut,6,2));
    my $hour = int($FITS_headers->{'RUTSTART'});
    my $minute = int( ( $FITS_headers->{'RUTSTART'} - $hour ) * 60 );
    my $second = int( ( ( ( $FITS_headers->{'RUTSTART'} - $hour ) * 60) - $minute ) * 60 );
    $return = $self->_parse_iso_date( $ut . "T$hour:$minute:$second" );
  }

  return $return;
}

=item B<from_UTSTART>

Converts the C<UTSTART> generic header into C<UT_DATE>, C<RUTSTART>,
and C<DATE-OBS> database headers.

=cut

sub from_UTSTART {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTSTART})) {
    my $t = _parse_date( $generic_headers->{'UTSTART'} );
    my $month = $t->month;
    $month =~ /^(.{3})/;
    $month = $1;
    $return_hash{'UT_DATE'} = $month . " " . $t->mday . " " . $t->year;
    $return_hash{'RUTSTART'} = $t->hour + ($t->min / 60) + ($t->sec / 3600);
    $return_hash{'DATE_OBS'} = $generic_headers->{'UTSTART'};
  }
  return %return_hash;
}

=item B<to_UTEND>

Strips the optional 'Z' from the C<DATE-END> header, or if that header does
not exist, combines the C<UT_DATE> and C<RUTEND> headers into a unified
C<UTEND> header.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'DATE_END'} ) ) {
    my $dateend = $FITS_headers->{'DATE_END'};
    $return = $self->_parse_iso_date( $dateend );
  } elsif (exists($FITS_headers->{'UT_DATE'}) && defined($FITS_headers->{'UT_DATE'}) &&
           exists($FITS_headers->{'RUTEND'}) && defined( $FITS_headers->{'RUTEND'} ) ) {
    # Use the default UTDATE translation but insert "-" for ISO parsing
    my $ut = $self->to_UTDATE($FITS_headers);
    $ut = join("-", substr($ut,0,4), substr($ut,4,2), substr($ut,6,2));
    my $hour = int($FITS_headers->{'RUTEND'});
    my $minute = int( ( $FITS_headers->{'RUTEND'} - $hour ) * 60 );
    my $second = int( ( ( ( $FITS_headers->{'RUTEND'} - $hour ) * 60) - $minute ) * 60 );
    $return = $self->_parse_iso_date( $ut . "T$hour:$minute:$second" );
  }

  return $return;
}

=item B<from_UTEND>

Converts the C<UTEND> generic header into C<UT_DATE>, C<RUTEND>
and C<DATE-END> database headers.

=cut

sub from_UTEND {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTEND})) {
    my $t = _parse_date( $generic_headers->{'UTEND'} );
    my $month = $t->month;
    $month =~ /^(.{3})/;
    $month = $1;
    $return_hash{'UT_DATE'} = $month . " " . $t->mday . " " . $t->year;
    $return_hash{'RUTEND'} = $t->hour + ($t->min / 60) + ($t->sec / 3600);
    $return_hash{'DATE_END'} = $generic_headers->{'UTEND'};
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

=item B<to_RA_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<RA_BASE>.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{RABASE})) {
    $return = $FITS_headers->{RABASE} * 15;
  }
  return $return;
}

=item B<from_RA_BASE>

Converts the decimal degrees in the generic header C<RA_BASE>
into decimal hours for the FITS header C<RABASE>.

=cut

sub from_RA_BASE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{RA_BASE})) {
    $return_hash{'RABASE'} = $generic_headers->{RA_BASE} / 15;
  }
  return %return_hash;
}

=back

=head1 INTERNAL METHODS

=over 4

=item B<_fix_dates>

Handle the case where DATE_OBS and/or DATE_END are given, and convert
them into DATE-OBS and/or DATE-END.

=cut

sub _fix_dates {
  my ( $class, $FITS_headers ) = @_;

  if( defined( $FITS_headers->{'DATE_OBS'} ) ) {
    $FITS_headers->{'DATE-OBS'} = $class->_parse_iso_date( $FITS_headers->{'DATE_OBS'} );
  }
  if( defined( $FITS_headers->{'DATE_END'} ) ) {
    $FITS_headers->{'DATE-END'} = $class->_parse_iso_date( $FITS_headers->{'DATE_END'} );
  }

}

=item B<_parse_date>

Parses a string as a date. Returns a C<Time::Piece> object.

  $time = _parse_date( $date );

Returns C<undef> if the time could not be parsed.
Returns the object unchanged if the argument is already a C<Time::Piece>.

It will also recognize a MySQL style date: '2002-03-15 07:04:00'
and a simple YYYYMMDD.

The date is assumed to be in UT.

=cut

sub _parse_date {
  my $date = shift;

  # If we already have a Time::Piece return
  return bless $date, "Time::Piece"
    if UNIVERSAL::isa( $date, "Time::Piece");

  # We can use Time::Piece->strptime but it requires an exact
  # format rather than working it out from context (and we don't
  # want an additional requirement on Date::Manip or something
  # since Time::Piece is exactly what we want for Astro::Coords)
  # Need to fudge a little

  my $format;

  # Need to disambiguate ISO date from MySQL date
  if ($date =~ /\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/) {
    # MySQL
    $format = '%Y-%m-%d %T';

  } elsif ($date =~ /\d\d\d\d-\d\d-\d\d/) {
    # ISO

    # All arguments should have a day, month and year
    $format = "%Y-%m-%d";

    # Now check for time
    if ($date =~ /T/) {
      # Date and time
      # Now format depends on the number of colons
      my $n = ( $date =~ tr/:/:/ );
      $format .= "T" . ($n == 2 ? "%T" : "%R");
    }
  } elsif ($date =~ /^\d\d\d\d\d\d\d\d\b/) {
    # YYYYMMDD format
    $format = "%Y%m%d";
  } else {
    # Allow Sybase date for compatability.
    # Mar 15 2002  7:04AM
    $format = "%b %d %Y %I:%M%p";

  }

  # Now parse
  # Note that this time is treated as "local" rather than "gm"
  my $time = eval { Time::Piece->strptime( $date, $format ); };
  if ($@) {
    return undef;
  } else {
    # Note that the above constructor actually assumes the date
    # to be parsed is a local time not UTC. To switch to UTC
    # simply get the epoch seconds and the timezone offset
    # and run gmtime
    # Sometime around v1.07 of Time::Piece the behaviour changed
    # to return UTC rather than localtime from strptime!
    # The joys of backwards compatibility.
    if ($time->[Time::Piece::c_islocal]) {
      my $tzoffset = $time->tzoffset;
      my $epoch = $time->epoch;
      $time = gmtime( $epoch + $tzoffset->seconds );
    }

  }

  return $time;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>,
C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2007-2008 Science and Technology Facilities Council.
Copyright (C) 2002-2005 Particle Physics and Astronomy Research Council.
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
