package Astro::FITS::HdrTrans::CGS4Old;

=head1 NAME

Astro::FITS::HdrTrans::CGS4 - UKIRT CGS4 translations for "old" style
CGS4 headers.

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::CGS4Old;

  %gen = Astro::FITS::HdrTrans::CGS4Old->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific
to the CGS4 spectrometer of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRT "Old"
use base qw/ Astro::FITS::HdrTrans::UKIRTOld /;

use vars qw/ $VERSION /;

$VERSION = "1.65";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                # CGS4 Specific
                GRATING_DISPERSION   => "GDISP",
                GRATING_NAME         => "GRATING",
                GRATING_ORDER        => "GORDER",
                GRATING_WAVELENGTH   => "GLAMBDA",
                SLIT_ANGLE           => "SANGLE",
                SLIT_NAME            => "SLIT",
                SLIT_WIDTH           => "SWIDTH",
                # MICHELLE compatible
                NSCAN_POSITIONS      => "DETNINCR",
                SCAN_INCREMENT       => "DETINCR",
                # MICHELLE + UIST + WFCAM
                CONFIGURATION_INDEX  => 'CNFINDEX',
               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

# Im

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

This method returns true if the INSTRUME header exists and is equal to
'CGS4', and if the IDATE header exists, matches the regular
expression '\d{8}', and is less than 20081115.

It also handles the reverse (to FITS) case where the INSTRUMENT header
replaces INSTRUME, and UTDATE replaces IDATE in the above tests.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if ( exists $headers->{IDATE} &&
       defined $headers->{IDATE} &&
       $headers->{IDATE} =~ /\d{8}/ &&
       $headers->{IDATE} < 20081115 &&
       exists $headers->{INSTRUME} &&
       defined $headers->{INSTRUME} &&
       ! exists $headers->{RAJ2000} &&
       uc( $headers->{INSTRUME} ) eq 'CGS4' ) {
    return 1;
  }

  # Need to handle the reverse case as well. This module can translate
  # CGS4 headers older than 20081115.  Note that the translations mean
  # different header names are tested.
  if ( exists $headers->{UTDATE} &&
       defined $headers->{UTDATE} &&
       $headers->{UTDATE} =~ /\d{8}/ &&
       $headers->{UTDATE} < 20081115 &&
       exists $headers->{INSTRUMENT} &&
       defined $headers->{INSTRUMENT} &&
       uc( $headers->{INSTRUMENT} ) eq 'CGS4' ) {
    return 1;
  }

  return 0;
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

=item B<to_POLARIMETRY>

Checks the C<FILTER> FITS header keyword for the existance of
'prism'. If 'prism' is found, then the C<POLARIMETRY> generic
header is set to 1, otherwise 0.

=cut

sub to_POLARIMETRY {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{FILTER})) {
    $return = ( $FITS_headers->{FILTER} =~ /prism/i ? 1 : 0);
  }
  return $return;
}

=item B<to_DEC_TELESCOPE_OFFSET>

The header keyword for the Dec telescope offset changed from DECOFF to
TDECOFF on 20050315, so switch on this date to use the proper header.

=cut

sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{IDATE} ) && defined( $FITS_headers->{IDATE} ) ) {
    if ( $FITS_headers->{IDATE} < 20050315 ) {
      $return = $FITS_headers->{DECOFF};
    } else {
      $return = $FITS_headers->{TDECOFF};
    }
  }
  return $return;
}

=item B<from_DEC_TELESCOPE_OFFSET>

The header keyword for the Dec telescope offset changed from DECOFF to
TDECOFF on 20050315, so return the proper keyword depending on observation
date.

=cut

sub from_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $generic_headers = shift;
  my %return;
  if ( exists( $generic_headers->{UTDATE} ) &&
       defined( $generic_headers->{UTDATE} ) ) {
    my $ut = $generic_headers->{UTDATE};
    if ( exists( $generic_headers->{DEC_TELESCOPE_OFFSET} ) &&
         defined( $generic_headers->{DEC_TELESCOPE_OFFSET} ) ) {
      if ( $ut < 20050315 ) {
        $return{'DECOFF'} = $generic_headers->{DEC_TELESCOPE_OFFSET};
      } else {
        $return{'TDECOFF'} = $generic_headers->{DEC_TELESCOPE_OFFSET};
      }
    }
  } else {
    if ( exists( $generic_headers->{DEC_TELESCOPE_OFFSET} ) &&
         defined( $generic_headers->{DEC_TELESCOPE_OFFSET} ) ) {
      $return{'TDECOFF'} = $generic_headers->{DEC_TELESCOPE_OFFSET};
    }
  }
  return %return;
}

=item B<to_RA_TELESCOPE_OFFSET>

The header keyword for the RA telescope offset changed from RAOFF to
TRAOFF on 20050315, so switch on this date to use the proper header.

=cut

sub to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{IDATE} ) && defined( $FITS_headers->{IDATE} ) ) {
    if ( $FITS_headers->{IDATE} < 20050315 ) {
      $return = $FITS_headers->{RAOFF};
    } else {
      $return = $FITS_headers->{TRAOFF};
    }
  }
  return $return;
}

=item B<from_RA_TELESCOPE_OFFSET>

The header keyword for the RA telescope offset changed from RAOFF to
TRAOFF on 20050315, so return the proper keyword depending on observation
date.

=cut

sub from_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $generic_headers = shift;
  my %return;
  if ( exists( $generic_headers->{UTDATE} ) &&
       defined( $generic_headers->{UTDATE} ) ) {
    my $ut = $generic_headers->{UTDATE};
    if ( exists( $generic_headers->{RA_TELESCOPE_OFFSET} ) &&
         defined( $generic_headers->{RA_TELESCOPE_OFFSET} ) ) {
      if ( $ut < 20050315 ) {
        $return{'RAOFF'} = $generic_headers->{RA_TELESCOPE_OFFSET};
      } else {
        $return{'TRAOFF'} = $generic_headers->{RA_TELESCOPE_OFFSET};
      }
    }
  } else {
    if ( exists( $generic_headers->{RA_TELESCOPE_OFFSET} ) &&
         defined( $generic_headers->{RA_TELESCOPE_OFFSET} ) ) {
      $return{'TRAOFF'} = $generic_headers->{RA_TELESCOPE_OFFSET};
    }
  }
  return %return;
}

=item B<to_DETECTOR_READ_TYPE>

Should be the "MODE" header but if this is missing we can look
at INTTYPE instead.

=cut

sub to_DETECTOR_READ_TYPE {
  my $self = shift;
  my $FITS_headers = shift;

  my %mode = (
    CHOP        => 'CHOP',
    'STARE+NDR' => 'ND_STARE',
    STARE       => 'STARE',
  );

  if (exists $FITS_headers->{'MODE'}) {
    return $FITS_headers->{'MODE'};
  }
  elsif (exists $FITS_headers->{'INTTYPE'}) {
    my $inttype = $FITS_headers->{'INTTYPE'};
    if (exists $mode{$inttype}) {
      return $mode{$inttype};
    }
  }

  return undef;
}

=item B<to_SAMPLING>

Converts FITS header values in C<DETINCR> and C<DETNINCR> to a single
descriptive string.

=cut

sub to_SAMPLING {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if (exists($FITS_headers->{DETINCR}) && exists($FITS_headers->{DETNINCR})) {
    my $detincr = $FITS_headers->{DETINCR} || 1;
    my $detnincr = $FITS_headers->{DETNINCR} || 1;
    $return = int ( 1 / $detincr ) . 'x' . int ( $detincr * $detnincr );
  }
  return $return;
}

=item B<from_TELESCOPE>

Returns 'UKIRT, Mauna Kea, HI' for the C<TELESCOP> FITS header.

=cut

sub from_TELESCOPE {
  my %return = ( "TELESCOP", "UKIRT, Mauna Kea, HI" );
  return %return;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

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
