package Astro::FITS::HdrTrans::SPEX;

=head1 NAME

Astro::FITS::HdrTrans::SPEX - IRTF SPEX translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::SPEX;

  %gen = Astro::FITS::HdrTrans::SPEX->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the SPEX camera of the IRTF.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from ESO
use base qw/ Astro::FITS::HdrTrans::FITS /;

use vars qw/ $VERSION /;

$VERSION = "1.61";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 # Value in headers is too imprecise
                 DEC_SCALE           => (-0.1182/3600.0),
                 DETECTOR_READ_TYPE  => 'NDSTARE',
                 GAIN                => 13.0,
                 OBSERVATION_MODE    => 'imaging',
                 NSCAN_POSITIONS     => 1,
                 # Value in headers is too imprecise
                 RA_SCALE            => (-0.116/3600.0),
                 ROTATION            => -1.03,
                 SPEED_GAIN => 'Normal',
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                EXPOSURE_TIME        => "ITIME",
                FILTER               => "GFLT",
                OBJECT               => 'OBJECT',
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

Returns "INGRID".

=cut

sub this_instrument {
  return qr/^SPEX/i;
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=cut

sub to_AIRMASS_START {
  my $self = shift;
  my $FITS_headers = shift;
  my $airmass = 1.0;
  if ( defined( $FITS_headers->{AIRMASS} ) ) {
    $airmass = $FITS_headers->{AIRMASS};
  }
  return $airmass;
}

sub to_AIRMASS_END {
  my $self = shift;
  my $FITS_headers = shift;
  my $airmass = 1.0;
  if ( defined( $FITS_headers->{AIRMASS} ) ) {
    $airmass = $FITS_headers->{AIRMASS};
  }
  return $airmass;
}

sub from_AIRMASS_END {
  my $self = shift;
  my $generic_headers = shift;
  "AMEND",  $generic_headers->{ "AIRMASS_END" };
}

# Convert from sexagesimal d:m:s to decimal degrees.
sub to_DEC_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $dec = 0.0;
  my $sexa = $FITS_headers->{"DECBASE"};
  if ( defined( $sexa ) ) {
    $dec = $self->dms_to_degrees( $sexa );
  }
  return $dec;
}

# Assume that the initial offset is 0.0, i.e. the base is the
# source position.  This also assumes that the reference pixel
# is unchanged in the group, as is created in the conversion
# script.  The other headers are measured in sexagesimal, but
# the offsets are in arcseconds.
sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $offset;
  my $base = $self->to_DEC_BASE($FITS_headers);

  # Convert from sexagesimal d:m:s to decimal degrees.
  my $sexadec = $FITS_headers->{DEC};
  if ( defined( $sexadec ) ) {
    my $dec = $self->dms_to_degrees( $sexadec );

    # The offset is arcseconds with respect to the base position.
    $offset = 3600.0 * ( $dec - $base );
  } else {
    $offset = 0.0;
  }
  return $offset;
}

sub to_DR_RECIPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $recipe = "JITTER_SELF_FLAT";
  if ( $self->to_OBSERVATION_TYPE($FITS_headers) eq "DARK" ) {
    $recipe = "REDUCE_DARK";
  } elsif (  $self->to_STANDARD($FITS_headers) ) {
    $recipe = "JITTER_SELF_FLAT_APHOT";
  }
  return $recipe;
}


sub to_NUMBER_OF_EXPOSURES {
  my $self = shift;
  my $FITS_headers = shift;
  my $coadds = 1;
  if ( defined $FITS_headers->{CO_ADDS} ) {
    $coadds = $FITS_headers->{CO_ADDS};
  }

}

sub to_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $FITS_headers = shift;

  # Allow for the UKIRT convention of the final offset to 0,0, and a
  # default dither pattern of 5.
  my $noffsets = 6;

  # The number of gripu members appears to be given by keyword LOOP.
  if ( defined $FITS_headers->{NOFFSETS} ) {
    $noffsets = $FITS_headers->{NOFFSETS};
  }

  return $noffsets;
}

sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $type = "OBJECT";
  if ( defined $FITS_headers->{OBJECT} && defined $FITS_headers->{GFLT}) {
    my $object = uc( $FITS_headers->{OBJECT} );
    my $filter = uc( $FITS_headers->{GFLT} );
    if ( $filter =~ /blank/i ) {
      $type = "DARK";
    } elsif ( $object =~ /flat/i ) {
      $type = "FLAT";
    }
  }
  return $type;
}

# Convert from sexagesimal h:m:s to decimal degrees then to decimal
# hours.
sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $ra = 0.0;
  my $sexa = $FITS_headers->{"RABASE"};
  if ( defined( $sexa ) ) {
    $ra = $self->hms_to_degrees( $sexa );
  }
  return $ra;
}

# Assume that the initial offset is 0.0, i.e. the base is the
# source position.  This also assumes that the reference pixel
# is unchanged in the group, as is created in the conversion
# script.  The other headers are measured in sexagesimal, but
# the offsets are in arcseconds.
sub to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $offset;

  # Base RA is in degrees.
  my $base = $self->to_RA_BASE($FITS_headers);

  # Convert from sexagesimal right ascension h:m:s and declination
  # d:m:s to decimal degrees.
  my $sexara = $FITS_headers->{RA};
  my $sexadec = $FITS_headers->{DEC};
  if ( defined( $base ) && defined( $sexara ) && defined( $sexadec ) ) {
    my $dec = $self->dms_to_degrees( $sexadec );
    my $ra = $self->hms_to_degrees( $sexara );

    # The offset is arcseconds with respect to the base position.
    $offset = 3600.0 * ( $ra - $base ) * $self->cosdeg( $dec );
  } else {
    $offset = 0.0;
  }
  return $offset;
}

# Take a pragmatic way of defining a standard.  Not perfect, but
# should suffice unitl we know all the names.
sub to_STANDARD {
  my $self = shift;
  my $FITS_headers = shift;
  my $standard = 0;
  my $object = $FITS_headers->{"OBJECT"};
  if ( defined( $object ) && $object =~ /^FS/ ) {
    $standard = 1;
  }
  return $standard;
}

# Allow for multiple occurences of the date, the first being valid and
# the second is blank.
sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $utdate;
  if ( exists $FITS_headers->{"DATE-OBS"} ) {
    $utdate = $FITS_headers->{"DATE-OBS"};

    # This is a kludge to work with old data which has multiple values of
    # the DATE keyword with the last value being blank (these were early
    # SPEX data).  Return the first value, since the last value can be
    # blank.
    if ( ref( $utdate ) eq 'ARRAY' ) {
      $utdate = $utdate->[0];
    }
  } elsif (exists $FITS_headers->{'DATE_OBS'}) {
    $utdate = $FITS_headers->{'DATE_OBS'};
  }
  $utdate =~ s/-//g if $utdate;
  return $utdate;
}

# Derive from the start time, plus the exposure time and some
# allowance for the read time taken from
# http://irtfweb.ifa.hawaii.edu/~spex
# http://irtfweb.ifa.hawaii.edu/Facility/spex/work/array_params/array_params.html
sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $utend = $self->to_UTSTART($FITS_headers);
  if ( defined $FITS_headers->{ITIME} && defined $FITS_headers->{NDR} ) {
    $utend += ( $FITS_headers->{ITIME} * $FITS_headers->{NDR}) ;
  }
  return $utend;
}

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $base = $self->to_UTDATE( $FITS_headers );
  return unless defined $base;
  if (exists $FITS_headers->{TIME_OBS}) {
    my $ymd = substr($base,0,4). "-". substr($base,4,2)."-". substr($base,6,2);
    my $iso = $ymd. "T" . $FITS_headers->{TIME_OBS};
    return $self->_parse_iso_date( $iso );
  }
  return;
}

sub to_X_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = $self->get_bounds($FITS_headers);
  return $bounds[ 0 ];
}

# Specify the reference pixel, which is normally near the frame centre.
sub to_X_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $xref;

  # Use the average of the bounds to define the centre and dimension.
  my @bounds = $self->get_bounds($FITS_headers);
  my $xdim = $bounds[ 2 ] - $bounds[ 0 ] + 1;
  my $xmid = $self->nint( ( $bounds[ 2 ] + $bounds[ 0 ] ) / 2 );

  # SPEX is at the centre for a sub-array along an axis but offset slightly
  # for a sub-array to avoid the joins between the four sub-array sections
  # of the frame.  Ideally these should come through the headers...
  if ( $xdim == 512 ) {
    $xref = $xmid - 36;
  } else {
    $xref = $xmid;
  }
  return $xref;
}

sub from_X_REFERENCE_PIXEL {
  my $self = shift;
  my $generic_headers = shift;
  "CRPIX1", $generic_headers->{"X_REFERENCE_PIXEL"};
}

sub to_X_UPPER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = $self->get_bounds( $FITS_headers );
  return $bounds[ 2 ];
}

sub to_Y_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = $self->get_bounds( $FITS_headers );
  return $bounds[ 1 ];
}

# Specify the reference pixel, which is normally near the frame centre.
sub to_Y_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $yref;

  # Use the average of the bounds to define the centre and dimension.
  my @bounds = $self->get_bounds($FITS_headers);
  my $ydim = $bounds[ 3 ] - $bounds[ 1 ] + 1;
  my $ymid = $self->nint( ( $bounds[ 3 ] + $bounds[ 1 ] ) / 2 );

  # SPEX is at the centre for a sub-array along an axis but offset slightly
  # for a sub-array to avoid the joins between the four sub-array sections
  # of the frame.  Ideally these should come through the headers...
  if ( $ydim == 512 ) {
    $yref = $ymid - 40;
  } else {
    $yref = $ymid;
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
  my @bounds = $self->get_bounds( $FITS_headers );
  return $bounds[ 3 ];
}

# Supplementary methods for the translations
# ------------------------------------------

# Converts a sky angle specified in d:m:s format into decimal degrees.
# Argument is the sexagesimal format angle.
sub dms_to_degrees {
  my $self = shift;
  my $sexa = shift;
  my $dms;
  if ( defined( $sexa ) ) {
    my @pos = split( /:/, $sexa );
    $dms = $pos[ 0 ] + $pos[ 1 ] / 60.0 + $pos [ 2 ] / 3600.;
  }
  return $dms;
}

sub get_bounds {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = ( 1, 1, 512, 512 );
  if ( exists $FITS_headers->{ARRAY0} ) {
    my $boundlist = $FITS_headers->{ARRAY0};
    @bounds = split( ",", $boundlist );

    # Bounds count from zero.
    $bounds[ 0 ]++;
    $bounds[ 1 ]++;
  }
  return @bounds;
}

# Returns the UT date in yyyyMMdd format.
sub get_UT_date {
  my $self = shift;
  my $FITS_headers = shift;
  my $date = $FITS_headers->{"DATE-OBS"};
  $date =~ s/-//g;
  return $date;
}

# Returns the UT time of observation in decimal hours.
sub get_UT_hours {
  my $self = shift;
  my $FITS_headers = shift;
  if ( exists $FITS_headers->{"TIME-OBS"} && $FITS_headers->{"TIME-OBS"} =~ /:/ ) {
    my ($hour, $minute, $second) = split( /:/, $FITS_headers->{"TIME-OBS"} );
    return $hour + ($minute / 60) + ($second / 3600);
  } else {
    return $FITS_headers->{"TIME-OBS"};
  }
}

# Converts a sky angle specified in h:m:s format into decimal degrees.
# It takes no account of latitude.  Argument is the sexagesimal format angle.
sub hms_to_degrees {
  my $self = shift;
  my $sexa = shift;
  my $hms;
  if ( defined( $sexa ) ) {
    my @pos = split( /:/, $sexa );
    $hms = 15.0 * ( $pos[ 0 ] + $pos[ 1 ] / 60.0 + $pos [ 2 ] / 3600. );
  }
  return $hms;
}


=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Malcolm J. Currie E<lt>mjc@star.rl.ac.ukE<gt>,
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
Place, Suite 330, Boston, MA 02111-1307, USA.

=cut

1;
