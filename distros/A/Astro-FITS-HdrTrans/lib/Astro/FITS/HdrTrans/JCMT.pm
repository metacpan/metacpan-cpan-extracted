=head1 NAME

Astro::FITS::HdrTrans::JCMT - class combining common behaviour for modern JCMT instruments

=cut

package Astro::FITS::HdrTrans::JCMT;

use strict;
use warnings;

use Astro::Coords;
use Astro::Telescope;
use DateTime;
use DateTime::TimeZone;

our $VERSION = '1.63';

use base qw/ Astro::FITS::HdrTrans::JAC /;

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.
my %UNIT_MAP =
  (
    AIRMASS_START        => 'AMSTART',
    AZIMUTH_START        => 'AZSTART',
    ELEVATION_START      => 'ELSTART',
    FILENAME             => 'FILE_ID',
    DR_RECIPE            => "RECIPE",
    HUMIDITY             => 'HUMSTART',
    LATITUDE             => 'LAT-OBS',
    LONGITUDE            => 'LONG-OBS',
    OBJECT               => 'OBJECT',
    OBSERVATION_NUMBER   => 'OBSNUM',
    PROJECT              => 'PROJECT',
    SCAN_PATTERN         => 'SCAN_PAT',
    STANDARD             => 'STANDARD',
    TAI_UTC_CORRECTION   => 'DTAI',
    UT1_UTC_CORRECTION   => 'DUT1',
    WIND_BLIND           => 'WND_BLND',
    X_APERTURE           => 'INSTAP_X',
    Y_APERTURE           => 'INSTAP_Y',
  );

my %CONST_MAP = ();

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

our $COORDS;

=head1 METHODS

=over 4

=item B<translate_from_FITS>

This routine overrides the base class implementation to enable the
caches to be cleared for target location.

This means that some conversion methods (in particular those using time in
a base class) may not work properly outside the context of a full translation
unless they have been subclassed locally.

Date fixups are handled in a super class.

=cut

sub translate_from_FITS {
  my $class = shift;
  my $headers = shift;

  # clear cache
  $COORDS = undef;

  # Go to the base class
  return $class->SUPER::translate_from_FITS( $headers, @_ );
}

=item B<to_UTDATE>

Converts the date in a date-obs header into a number of form YYYYMMDD.

=cut

sub to_UTDATE {
  my $class = shift;
  my $FITS_headers = shift;

  $class->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTDATE( $FITS_headers, @_ );
}

=item B<to_UTEND>

Converts UT date in a date-end header into C<Time::Piece> object

=cut

sub to_UTEND {
  my $class = shift;
  my $FITS_headers = shift;

  $class->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTEND( $FITS_headers, @_ );
}

=item B<to_UTSTART>

Converts UT date in a date-obs header into C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $class = shift;
  my $FITS_headers = shift;

  $class->_fix_dates( $FITS_headers );
  return $class->SUPER::to_UTSTART( $FITS_headers, @_ );
}

=item B<to_RA_BASE>

Uses the elevation, azimuth, telescope name, and observation start
time headers (ELSTART, AZSTART, TELESCOP, and DATE-OBS headers,
respectively) to calculate the base RA.

Returns the RA in degrees.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;

  my $coords = $self->_calc_coords( $FITS_headers );
  return undef unless defined $coords;
  return $coords->ra( format => 'deg' );
}

=item B<to_DEC_BASE>

Uses the elevation, azimuth, telescope name, and observation start
time headers (ELSTART, AZSTART, TELESCOP, and DATE-OBS headers,
respectively) to calculate the base declination.

Returns the declination in degrees.

=cut

sub to_DEC_BASE {
  my $self = shift;
  my $FITS_headers = shift;

  my $coords = $self->_calc_coords( $FITS_headers );

  return undef unless defined $coords;
  return $coords->dec( format => 'deg' );
}

=item B<to_TAU>

Use the average WVM tau measurements.

=cut

sub to_TAU {
  my $self = shift;
  my $FITS_headers = shift;

  my $tau = 0.0;
  for my $src (qw/ TAU225 WVMTAU /) {
    my $st = $src . "ST";
    my $en = $src . "EN";

    my @startvals = $self->via_subheader_undef_check( $FITS_headers, $st );
    my @endvals   = $self->via_subheader_undef_check( $FITS_headers, $en );
    my $startval = $startvals[0];
    my $endval = $endvals[-1];

    if (defined $startval && defined $endval) {
      $tau = ($startval + $endval) / 2;
      last;
    } elsif (defined $startval) {
      $tau = $startval;
    } elsif (defined $endval) {
      $tau = $endval;
    }
  }
  return $tau;
}

=item B<to_SEEING>

Use the average seeing measurements.

=cut

sub to_SEEING {
  my $self = shift;
  my $FITS_headers = shift;

  my $seeing = 0.0;


  my @startvals = $self->via_subheader_undef_check( $FITS_headers, "SEEINGST" );
  my @endvals   = $self->via_subheader_undef_check( $FITS_headers, "SEEINGEN" );
  my $startval = $startvals[0];
  my $endval = $endvals[-1];

  if (defined $startval && defined $endval) {
      $seeing = ($startval + $endval) / 2;
  } elsif (defined $startval) {
      $seeing = $startval;
  } elsif (defined $endval) {
      $seeing = $endval;
  }

  return $seeing;
}




=item B<to_OBSERVATION_ID_SUBSYSTEM>

Returns the subsystem observation IDs associated with the header.
Returns a reference to an array. Will be empty if the OBSIDSS header
is missing.

=cut

sub to_OBSERVATION_ID_SUBSYSTEM {
  my $self = shift;
  my $FITS_headers = shift;
  # Try multiple headers since the database is different to the file
  my @obsidss;
  for my $h (qw/ OBSIDSS OBSID_SUBSYSNR /) {
    my @found = $self->via_subheader( $FITS_headers, $h );
    if (@found) {
      @obsidss = @found;
      last;
    }
  }
  my @all;
  if (@obsidss) {
    # Remove duplicates
    my %seen;
    @all = grep { ! $seen{$_}++ } @obsidss;
  }
  return \@all;
}

=item B<to_SUBSYSTEM_IDKEY>

=cut

sub to_SUBSYSTEM_IDKEY {
  my $self = shift;
  my $FITS_headers = shift;

  for my $try ( qw/ OBSIDSS OBSID_SUBSYSNR / ) {
    my @results = $self->via_subheader( $FITS_headers, $try );
    return $try if @results;
  }
  return;
}

=item B<to_DOME_OPEN>

Uses the roof and door status at start and end of observation headers
to generate a combined value which, if true, confirms that the dome
was fully open throughout.  (Unless it closed and reopened during
the observation.)

=cut

sub to_DOME_OPEN {
  my $self = shift;
  my $FITS_headers = shift;

  my ($n_open, $n_closed, $n_other) = (0, 0, 0);

  foreach my $header (qw/DOORSTST DOORSTEN ROOFSTST ROOFSTEN/) {
    foreach my $value ($self->via_subheader($FITS_headers, $header)) {
      if ($value =~ /^open$/i) {
        $n_open ++;
      }
      elsif ($value =~ /^closed$/i) {
        $n_closed ++;
      }
      else {
        $n_other ++;
      }
    }
  }

  if ($n_open and not ($n_closed or $n_other)) {
    return 1;
  }

  if ($n_closed and not ($n_open or $n_other)) {
    return 0;
  }

  return undef;
}

=item B<from_DOME_OPEN>

Converts the DOME_OPEN value back to individual roof and door
status headers.

=cut

sub from_DOME_OPEN {
  my $self = shift;
  my $generic_headers = shift;

  my $value = undef;

  if (exists $generic_headers->{'DOME_OPEN'}) {
    my $dome = $generic_headers->{'DOME_OPEN'};
    if (defined $dome) {
      $value = $dome ? 'Open' : 'Closed';
    }
  }

  return map {$_ => $value} qw/DOORSTST DOORSTEN ROOFSTST ROOFSTEN/;
}

=item B<to_REMOTE>

Convert between the JCMT's OPER_LOC header and a standardised 'REMOTE value'.

REMOTE = 1
LOCAL = 0

If not defined or has a different value, return 'undef'
=cut

sub to_REMOTE {
  my $self = shift;
  my $FITS_headers = shift;
  my $remote;
  if (exists( $FITS_headers->{'REMOTE'})) {
      $remote = $FITS_headers->{'REMOTE'};
  } else {
      $remote = ''
  }
  if (uc($remote) =~ /REMOTE/) {
      $remote = 1;
  } elsif (uc($remote) =~ /LOCAL/) {
      $remote = 0;
  } else {
      $remote = undef;
  }

  return $remote;
}


=item B<from_REMOTE>

Converts the REMOTE value back to the OPER_LOC header
if REMOTE=1, oper_loc='REMOTE'
if REMOTE=0, oper_loc='LOCAL'
if REMOTE is anything else, return undef;

=cut

sub from_REMOTE {
  my $self = shift;
  my $generic_headers = shift;

  my $value = undef;

  if (exists $generic_headers->{'REMOTE'}) {
    my $remote = $generic_headers->{'REMOTE'};
    if (defined $remote) {
      $value = $remote ? 'REMOTE' : 'LOCAL';
    }
  }

  return (OPER_LOC => $value);
}



=back

=head1 PRIVATE METHODS

=over 4

=item B<_calc_coords>

Function to calculate the coordinates at the start of the observation by using
the elevation, azimuth, telescope, and observation start time. Caches
the result if it's already been calculated.

Returns an Astro::Coords object.

=cut

sub _calc_coords {
  my $self = shift;
  my $FITS_headers = shift;

  # Force dates to be standardized
  $self->_fix_dates( $FITS_headers );

  # Here be dragons. Possibility that cache will not be cleared properly
  # if a user comes in outside of the translate_from_FITS() method.
  if ( defined( $COORDS ) &&
       UNIVERSAL::isa( $COORDS, "Astro::Coords" ) ) {
    return $COORDS;
  }

  my $telescope = $FITS_headers->{'TELESCOP'};

  # We can try DATE-OBS and AZEL START or DATE-END and AZEL END
  my ($dateobs, $az, $el);

  my @keys = ( { date => "DATE-OBS", az => "AZSTART", el => "ELSTART" },
               { date => "DATE-END", az => "AZEND", el => "ELEND" } );

  for my $keys_to_try ( @keys ) {

    # We might have subheaders, especially for the AZEL
    # values so we read into arrays and check them.

    my @dateobs = $self->via_subheader( $FITS_headers, $keys_to_try->{date} );
    my @azref = $self->via_subheader( $FITS_headers, $keys_to_try->{az} );
    my @elref = $self->via_subheader( $FITS_headers, $keys_to_try->{el} );

    # try to ensure that we use the same index everywhere
    my $idx;
    ($idx, $dateobs) = _middle_value(\@dateobs, $idx);
    ($idx, $az) = _middle_value(\@azref, $idx);
    ($idx, $el) = _middle_value(\@elref, $idx);

    # if we have a set of values we can stop looking
    last if (defined $dateobs && defined $az && defined $el);
  }

  # only proceed if we have a defined value
  if (defined $dateobs && defined $telescope
      && defined $az && defined $el ) {
    my $coords = new Astro::Coords( az => $az,
                                    el => $el,
                                    units => 'degrees',
                                  );
    $coords->telescope( new Astro::Telescope( $telescope ) );

    # convert ISO date to object
    my $dt = Astro::FITS::HdrTrans::Base->_parse_iso_date( $dateobs );
    return unless defined $dt;

    $coords->datetime( $dt );

    $COORDS = $coords;
    return $COORDS;
  }

  return undef;
}

=item B<_middle_value>

Returns the value from the middle of an array reference. If that is
not defined we start from the beginning until we find a defined
value. Return undef if we can not find anything.

=cut

sub _middle_value {
  my $arr = shift;
  my $idx = shift;

  $idx = int ((scalar @$arr) / 2) unless defined $idx;

  return ($idx, $arr->[$idx]) if (defined $arr->[$idx]);

  # No luck scan them all
  for my $idx (0..$#$arr) {
    my $val = $arr->[$idx];
    return ($idx, $val) if defined $val;
  }
  return (undef, undef);
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>,
C<Astro::FITS::HdrTrans::Base>,
C<Astro::FITS::HdrTrans::JAC>.

=head1 AUTHORS

Anubhav E<lt>a.agarwal@jach.hawawii.eduE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2009, 2011, 2012, 2014 Science and Technology Facilities Council.
Copyright (C) 2016 East Asian Observatory.
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
