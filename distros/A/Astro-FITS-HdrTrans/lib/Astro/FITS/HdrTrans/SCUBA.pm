package Astro::FITS::HdrTrans::SCUBA;

=head1 NAME

Astro::FITS::HdrTrans::SCUBA - JCMT SCUBA translations

=head1 DESCRIPTION

Converts information contained in SCUBA FITS headers to and from
generic headers. See Astro::FITS::HdrTrans for a list of generic
headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from Base
use base qw/ Astro::FITS::HdrTrans::JAC /;

use vars qw/ $VERSION /;

$VERSION = "1.62";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 COORDINATE_UNITS  => 'sexagesimal',
                 INSTRUMENT        => "SCUBA",
                 INST_DHS          => 'SCUBA_SCUBA',
                 NUMBER_OF_OFFSETS => 1,
                 ROTATION          => 0,
                 SLIT_ANGLE        => 0,
                 SPEED_GAIN        => 'normal',
                 TELESCOPE         => 'JCMT',
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ DETECTOR_INDEX WAVEPLATE_ANGLE /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                AIRMASS_START        => "AMSTART",
                AIRMASS_END          => "AMEND",
                BOLOMETERS           => "BOLOMS",
                CHOP_ANGLE           => "CHOP_PA",
                CHOP_THROW           => "CHOP_THR",
                DEC_BASE             => "LAT",
                DEC_TELESCOPE_OFFSET => "MAP_Y",
                DETECTOR_READ_TYPE   => "MODE",
                DR_RECIPE            => "DRRECIPE",
                FILENAME             => "SDFFILE",
                FILTER               => "FILTER",
                GAIN                 => "GAIN",
                NUMBER_OF_EXPOSURES  => "EXP_NO",
                OBJECT               => "OBJECT",
                OBSERVATION_NUMBER   => "RUN",
                POLARIMETER          => "POL_CONN",
                PROJECT              => "PROJ_ID",
                RA_TELESCOPE_OFFSET  => "MAP_X",
                SCAN_INCREMENT       => "SAM_DX",
                SEEING               => "SEEING",
                STANDARD             => "STANDARD",
                TAU                  => "TAU_225",
                X_BASE               => "LONG",
                Y_BASE               => "LAT",
                X_OFFSET             => "MAP_X",
                Y_OFFSET             => "MAP_Y"
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

Returns "SCUBA".

=cut

sub this_instrument {
  return "SCUBA";
}

=item B<can_translate>

The database tables do not include an instrument field so we need to determine
suitability by looking at other fields instead of using the base implementation.

  $cando = $class->can_translate( \%hdrs );

For SCUBA we first check for BOLOMS and SCU# headers and then use the base
implementation that will look at the INSTRUME field.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if (exists $headers->{BOLOMS} && defined $headers->{BOLOMS} &&
      exists $headers->{"SCU#"} && defined $headers->{"SCU#"}) {
    return 1;
  } else {
    return $self->SUPER::can_translate( $headers );
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

=item B<to_CHOP_COORDINATE_SYSTEM>

Uses the C<CHOP_CRD> FITS header to determine the chopper coordinate
system, and then places that coordinate type in the C<CHOP_COORDINATE_SYSTEM>
generic header.

A FITS header value of 'LO' translates to 'Tracking', 'AZ' translates to
'Alt/Az', and 'NA' translates to 'Focal Plane'. Any other values will return
undef.

=cut

sub to_CHOP_COORDINATE_SYSTEM {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if (exists($FITS_headers->{'CHOP_CRD'})) {
    my $fits_eq = $FITS_headers->{'CHOP_CRD'};
    if ( $fits_eq =~ /LO/i ) {
      $return = "Tracking";
    } elsif ( $fits_eq =~ /AZ/i ) {
      $return = "Alt/Az";
    } elsif ( $fits_eq =~ /NA/i ) {
      $return = "Focal Plane";
    }
  }
  return $return;
}

=item B<to_COORDINATE_TYPE>

Uses the C<CENT_CRD> FITS header to determine the coordinate type
(galactic, B1950, J2000) and then places that coordinate type in
the C<COORDINATE_TYPE> generic header.

=cut

sub to_COORDINATE_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{'CENT_CRD'})) {
    my $fits_eq = $FITS_headers->{'CENT_CRD'};
    if ( $fits_eq =~ /RB/i ) {
      $return = "B1950";
    } elsif ( $fits_eq =~ /RJ/i ) {
      $return = "J2000";
    } elsif ( $fits_eq =~ /AZ/i ) {
      $return = "galactic";
    } elsif ( $fits_eq =~ /planet/i ) {
      $return = "planet";
    }
  }
  return $return;
}

=item B<to_EQUINOX>

Translates EQUINOX header into valid equinox value. The following
translation is done:

=over 4

=item * RB => 1950

=item * RJ => 2000

=item * RD => current

=item * AZ => AZ/EL

=back

=cut

sub to_EQUINOX {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{'CENT_CRD'})) {
    my $fits_eq = $FITS_headers->{'CENT_CRD'};
    if ( $fits_eq =~ /RB/i ) {
      $return = "1950";
    } elsif ( $fits_eq =~ /RJ/i ) {
      $return = "2000";
    } elsif ( $fits_eq =~ /RD/i ) {
      $return = "current";
    } elsif ( $fits_eq =~ /PLANET/i ) {
      $return = "planet";
    } elsif ( $fits_eq =~ /AZ/i ) {
      $return = "AZ/EL";
    }
  }
  return $return;
}

=item B<from_EQUINOX>

Translates generic C<EQUINOX> values into SCUBA FITS
equinox values for the C<CENT_CRD> header.

=cut

sub from_EQUINOX {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  my $return;
  if (exists($generic_headers->{EQUINOX}) &&
      defined $generic_headers->{EQUINOX}) {
    my $equinox = $generic_headers->{EQUINOX};
    if ( $equinox =~ /1950/ ) {
      $return = 'RB';
    } elsif ( $equinox =~ /2000/ ) {
      $return = 'RJ';
    } elsif ( $equinox =~ /current/ ) {
      $return = 'RD';
    } elsif ( $equinox =~ /planet/ ) {
      $return = 'PLANET';
    } elsif ( $equinox =~ /AZ\/EL/ ) {
      $return = 'AZ';
    } else {
      $return = $equinox;
    }
  }
  $return_hash{'CENT_CRD'} = $return;
  return %return_hash;
}

=item B<to_OBSERVATION_MODE>

Returns C<photometry> if the FITS header value for C<MODE>
is C<PHOTOM>, otherwise returns C<imaging>.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( defined( $FITS_headers->{'MODE'} ) &&
       $FITS_headers->{'MODE'} =~ /PHOTOM/i ) {
    $return = "photometry";
  } else {
    $return = "imaging";
  }
  return $return;
}

=item B<to_OBSERVATION_TYPE>

Converts the observation type. If the FITS header is equal to
C<PHOTOM>, C<MAP>, C<POLPHOT>, or C<POLMAP>, then the generic
header value is C<OBJECT>. Else, the FITS header value is
copied directly to the generic header value.

=cut

sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  my $mode = $FITS_headers->{'MODE'};
  if ( defined( $mode ) && $mode =~ /PHOTOM|MAP|POLPHOT|POLMAP/i) {
    $return = "OBJECT";
  } else {
    $return = $mode;
  }
  return $return;
}

=item B<to_POLARIMETRY>

Sets the C<POLARIMETRY> generic header to 'true' if the
value for the FITS header C<MODE> is 'POLMAP' or 'POLPHOT',
otherwise sets it to 'false'.

=cut

sub to_POLARIMETRY {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  my $mode = $FITS_headers->{'MODE'};
  if (defined( $mode ) && $mode =~ /POLMAP|POLPHOT/i) {
    $return = 1;
  } else {
    $return = 0;
  }
  return $return;
}

=item B<to_UTDATE>

Converts either the C<UTDATE> or C<DATE> header into a C<Time::Piece> object.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{'UTDATE'} ) &&
       defined( $FITS_headers->{'UTDATE'} ) ) {
    my $utdate = $FITS_headers->{'UTDATE'};
    $return = $self->_parse_yyyymmdd_date( $utdate, ":" );
  } elsif ( exists( $FITS_headers->{'DATE'} ) &&
            defined( $FITS_headers->{'DATE'} ) ) {
    my $utdate = $FITS_headers->{'DATE'};
    $return = $self->_parse_iso_date( $utdate );
  } elsif ( exists( $FITS_headers->{'DATE-OBS'} ) &&
            defined( $FITS_headers->{'DATE-OBS'} ) ) {
    my $utdate = $FITS_headers->{'DATE-OBS'};
    $return = $self->_parse_iso_date( $utdate );
  }
  if (defined $return) {
    $return = sprintf('%04d%02d%02d',$return->year,
                      $return->mon, $return->mday);
  }
  return $return;
}

=item B<from_UTDATE>

Converts UT date in C<Time::Piece> object into C<YYYY:MM:DD> format
for C<UTDATE> header.

=cut

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTDATE}) ) {
    my $date = $generic_headers->{UTDATE};
    $return_hash{UTDATE} = join(':',
                                substr($date,0,4),
                                substr($date,4,2),
                                substr($date,6,2));
  }
  return %return_hash;
}

=item B<to_UTSTART>

Combines C<UTDATE> and C<UTSTART> into a unified C<UTSTART>
generic header. If those headers do not exist, uses C<DATE>.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{'UTDATE'} ) &&
       defined( $FITS_headers->{'UTDATE'} ) &&
       exists $FITS_headers->{UTSTART} &&
       defined $FITS_headers->{UTSTART} ) {

    # To convert to ISO replace colons with dashes
    my $utdate = $FITS_headers->{UTDATE};
    $utdate =~ s/:/\-/g;

    my $ut = $utdate . "T" . $FITS_headers->{'UTSTART'};
    $return = $self->_parse_iso_date( $ut );

  } elsif (exists $FITS_headers->{"DATE-OBS"}) {
    # reduced data
    $return = $self->_parse_iso_date( $FITS_headers->{"DATE-OBS"} );

  } elsif ( exists( $FITS_headers->{'DATE'} ) &&
            defined( $FITS_headers->{'DATE'} ) &&
            $FITS_headers->{'DATE'} =~ /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d/ ) {

    $return = $self->_parse_iso_date( $FITS_headers->{"DATE"} );

  }

  return $return;
}

=item B<from_UTSTART>

Converts the unified C<UTSTART> generic header into C<UTDATE>
and C<UTSTART> FITS headers of the form C<YYYY:MM:DD> and C<HH:MM:SS>.

=cut

sub from_UTSTART {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTSTART}) &&
      UNIVERSAL::isa( $generic_headers->{UTSTART}, "Time::Piece" ) ) {
    my $ut = $generic_headers->{UTSTART};
    $return_hash{'UTDATE'} = join ':', $ut->year, $ut->mon, $ut->mday;
    $return_hash{'UTSTART'} = join ':', $ut->hour, $ut->minute, $ut->second;
    $return_hash{'DATE'} = $ut->datetime;
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts the <UTDATE> and C<UTEND> headers into a combined
C<Time::Piece> object.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'UTDATE'} ) &&
       defined( $FITS_headers->{'UTDATE'} ) &&
       exists $FITS_headers->{UTEND} &&
       defined $FITS_headers->{UTEND} ) {

    # need to replace colons with -
    my $utdate = $FITS_headers->{"UTDATE"};
    $utdate =~ s/:/\-/g;

    my $ut = $utdate . "T" . $FITS_headers->{'UTEND'};

    $return = $self->_parse_iso_date( $ut );

  } elsif (exists $FITS_headers->{"DATE-END"}) {
    # reduced data
    $return = $self->_parse_iso_date( $FITS_headers->{"DATE-END"} );
  }
  return $return;
}

=item B<from_UTEND>

Converts the unified C<UTEND> generic header into C<UTDATE> and
C<UTEND> FITS headers of the form C<YYYY:MM:DD> and C<HH:MM:SS>.

=cut

sub from_UTEND {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists($generic_headers->{UTEND}) &&
      UNIVERSAL::isa( $generic_headers->{UTEND}, "Time::Piece" ) ) {
    my $ut = $generic_headers->{UTEND};
    $generic_headers->{UTEND} =~ /(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/;
    $return_hash{'UTDATE'} = join ':', $ut->year, $ut->mon, $ut->mday;
    $return_hash{'UTEND'} = join ':', $ut->hour, $ut->minute, $ut->second;
  }
  return %return_hash;
}

=item B<to_MSBID>

Converts the MSBID field to an MSBID. Complication is that the SCUBA
header and database store a blank MSBID as a single space rather than
an empty string and this causes difficulty in some subsystems.

This routine replaces a single space with a null string.

=cut

sub to_MSBID {
  my $self = shift;
  my $FITS_headers = shift;
  my $msbid = $FITS_headers->{MSBID};
  $msbid =~ s/\s+$// if defined $msbid;
  return $msbid;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 Science and Technology Facilities Council.
Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council.
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
