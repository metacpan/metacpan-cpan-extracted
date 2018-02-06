package Astro::FITS::HdrTrans::GEMINI;

=head1 NAME

Astro::FITS::HdrTrans::GEMINI - Base class for translation of Gemini instruments

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::GEMINI;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
instrumentation from the Gemini Observatory. It should not be used
directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from the Base translation class and not HdrTrans itself
# (which is just a class-less wrapper).

use base qw/ Astro::FITS::HdrTrans::FITS /;

use Scalar::Util qw/ looks_like_number /;
use Astro::FITS::HdrTrans::FITS;

use vars qw/ $VERSION /;

$VERSION = "1.60";

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                AIRMASS_END         => "AMEND",
                AIRMASS_START       => "AMSTART",
                DEC_BASE            => "CRVAL2",
                EXPOSURE_TIME       => "EXPTIME",
                EQUINOX             => "EQUINOX",
                INSTRUMENT          => "INSTRUME",
                NUMBER_OF_EXPOSURES => "NSUBEXP",
                NUMBER_OF_EXPOSURES => "COADDS",
                OBJECT              => "OBJECT",
                X_REFERENCE_PIXEL   => "CRPIX1",
                Y_REFERENCE_PIXEL   => "CRPIX2"
               );

# Create the translation methods
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

# Note use list context as there are multiple CD matrices in
# the header.  We want scalar context.
sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $cd11 = $FITS_headers->{"CD1_1"};
  my $cd12 = $FITS_headers->{"CD1_2"};
  my $cd21 = $FITS_headers->{"CD2_1"};
  my $cd22 = $FITS_headers->{"CD2_2"};
  my $sgn;
  if ( ( $cd11 * $cd22 - $cd12 * $cd21 ) < 0 ) {
    $sgn = -1;
  } else {
    $sgn = 1;
  }
  abs( sqrt( $cd11**2 + $cd21**2 ) );
}

sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;

  # It's simple when there's a header.
  my $offset = $FITS_headers->{ "DECOFFSE" };

  # Otherwise for older data have to derive an offset from the source
  # position and the frame position.  This does assume that the
  # reference pixel is unchanged in the group.  The other headers
  # are measured in degrees, but the offsets are in arceseconds.
  if ( !defined( $offset ) ) {
    my $decbase = $FITS_headers->{ "CRVAL2" } ;
    my $dec = $FITS_headers->{ "DEC" };
    if ( defined( $decbase ) && defined( $dec ) ) {
      $offset = 3600.0 * ( $dec - $decbase );
    } else {
      $offset = 0.0;
    }
  }
  return $offset;
}

sub from_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $generic_headers = shift;
  "DECOFFSE",  $generic_headers->{ "DEC_TELESCOPE_OFFSET" };
}

sub to_FILTER {
  my $self = shift;
  my $FITS_headers = shift;
  my $filter = "";
  my $filter1 = $FITS_headers->{ "FILTER1" };
  my $filter2 = $FITS_headers->{ "FILTER2" };
  my $filter3 = $FITS_headers->{ "FILTER3" };

  if ( $filter1 =~ "open" ) {
    $filter = $filter2;
  }

  if ( $filter2 =~ "open" ) {
    $filter = $filter1;
  }

  if ( ( $filter1 =~ "blank" ) ||
       ( $filter2 =~ "blank" ) ||
       ( $filter3 =~ "blank" ) ) {
    $filter = "blank";
  }
  return $filter;
}

sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $type = $FITS_headers->{ "OBSTYPE" };
  if ( $type eq "SCI" || $type eq "OBJECT-OBS" ) {
    $type = "OBJECT";
  }
  return $type;
}

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $ra = 0.0;
  if ( exists ( $FITS_headers->{CRVAL1} ) ) {
    $ra = $FITS_headers->{CRVAL1};
  }
  $ra = defined( $ra ) ? $ra: 0.0;
  return $ra;
}

sub to_RA_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $cd12 = $FITS_headers->{"CD1_2"};
  my $cd22 = $FITS_headers->{"CD2_2"};
  sqrt( $cd12**2 + $cd22**2 );
}
 
sub to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;

  # It's simple when there's a header.
  my $offset = $FITS_headers->{ "RAOFFSET" };

  # Otherwise for older data have to derive an offset from the source
  # position and the frame position.  This does assume that the
  # reference pixel is unchanged in the group.  The other headers
  # are measured in degrees, but the offsets are in arceseconds.
  if ( !defined( $offset ) ) {
    my $rabase = $FITS_headers->{ "CRVAL1" };
    my $ra = $FITS_headers->{ "RA" };
    my $dec = $FITS_headers->{ "DEC" };
    if ( defined( $rabase ) && defined( $ra ) && defined( $dec ) ) {
      $offset = 3600* ( $ra - $rabase ) * cosdeg( $dec );
    } else {
      $offset = 0.0;
    }
  }
  return $offset;
}

sub from_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $generic_headers = shift;
  "RAOFFSE",  $generic_headers->{ "RA_TELESCOPE_OFFSET" };
}

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists $FITS_headers->{'DATE-OBS'}) {
    my $iso;
    if ( $FITS_headers->{'DATE-OBS'} =~ /T/ ) {
      # standard format
      $iso = $FITS_headers->{'DATE-OBS'};
    } elsif ( exists $FITS_headers->{UTSTART} ) {
      $iso = $FITS_headers->{'DATE-OBS'}. "T" . $FITS_headers->{UTSTART};
    } elsif ( exists $FITS_headers->{UT} ) {
      $iso = $FITS_headers->{'DATE-OBS'}. "T" . $FITS_headers->{UT};
    }
    $return = $self->_parse_iso_date( $iso ) if $iso;
  }
  return $return;
}

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists $FITS_headers->{'DATE-END'} ) {
    $return = $self->_parse_iso_date( $FITS_headers->{'DATE-END'} );
  } elsif (exists $FITS_headers->{'DATE-OBS'}) {
    my $iso;
    my $ut;
    if ( $FITS_headers->{'DATE-OBS'} =~ /T/ ) {
      $ut = $FITS_headers->{'DATE-OBS'};
      $ut =~ s/T.*$//;
    } else {
      $ut = $FITS_headers->{'DATE-OBS'};
    }
    if (exists $FITS_headers->{UTEND}) {
      $iso = $ut. "T" . $FITS_headers->{UTEND};
    }
    $return = $self->_parse_iso_date( $iso ) if $iso;
  }
  return $return;
}


sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->get_UT_date( $FITS_headers );
}

sub from_UTEND {
  my $self = shift;
  my $generic_headers = shift;
  my $utend = $generic_headers->{UTEND}->strptime( '%T' );
  return ( "UTEND"=> $utend );
}

sub from_UTSTART {
  my $self = shift;
  my $generic_headers = shift;
  my $utstart = $generic_headers->{UTSTART}->strptime('%T');
  return ( "UTSTART"=> $utstart );
}

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my $ymd = $generic_headers->{UTDATE};
  my $dobs = substr( $ymd, 0, 4 ) . "-" . substr( $ymd, 4, 2 ) ."-" . substr( $ymd, 6, 2 );
  return ( "DATE-OBS"=>$dobs );
}

# Supplementary methods for the translations
# ------------------------------------------

# Returns the UT date in YYYYMMDD format.
sub get_UT_date {
  my $self = shift;
  my $FITS_headers = shift;

  # This is UT start and time.
  my $dateobs = $FITS_headers->{"DATE-OBS"};

  # Extract out the data in yyyymmdd format.
  return substr( $dateobs, 0, 4 ) . substr( $dateobs, 5, 2 ) . substr( $dateobs, 8, 2 );
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Paul Hirst <p.hirst@jach.hawaii.edu>
Malcolm J. Currie <mjc@star.rl.ac.uk>
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
