package Astro::FITS::HdrTrans::MICHELLE;

=head1 NAME

Astro::FITS::HdrTrans::MICHELLE - UKIRT Michelle translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::MICHELLE;

  %gen = Astro::FITS::HdrTrans::MICHELLE->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the MICHELLE camera and spectrometer of the United Kingdom Infrared
Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRT
# UKIRTNew must come first because of DATE-OBS handling
use base qw/ Astro::FITS::HdrTrans::UKIRTNew /;

our $VERSION = "1.66";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                # Michelle Specific
                CHOP_ANGLE           => "CHPANGLE",
                CHOP_THROW           => "CHPTHROW",
                GRATING_DISPERSION   => "GRATDISP",
                GRATING_NAME         => "GRATNAME",
                GRATING_ORDER        => "GRATORD",
                GRATING_WAVELENGTH   => "GRATPOS",
                SAMPLING             => "SAMPLING",
                SLIT_ANGLE           => "SLITANG",

                # CGS4 compatible
                NSCAN_POSITIONS      => "DETNINCR",
                SCAN_INCREMENT       => "DETINCR",

                # UIST compatible
                NUMBER_OF_READS      => "NREADS",
                POLARIMETRY          => "POLARISE",
                SLIT_NAME            => "SLITNAME",

                # UIST + WFCAM compatible
                EXPOSURE_TIME        => "EXP_TIME",

                # UFTI + IRCAM compatible
                SPEED_GAIN           => "SPD_GAIN",

                # CGS4 + UIST + WFCAM
                CONFIGURATION_INDEX  => 'CNFINDEX',
               );

# Derived from end entry in subheader
my %ENDOBS_MAP = (
                  DETECTOR_INDEX => 'DINDEX',
                 );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, undef, \%ENDOBS_MAP );

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "MICHELLE".

=cut

sub this_instrument {
  return "MICHELLE";
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_DEC_TELESCOPE_OFFSET>

Declination offsets need to be handled differently for spectroscopy
mode because of the new nod iterator.

=cut

sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $decoff;

  # Determine the observation mode, e.g. spectroscopy or imaging.
  my $mode = $self->to_OBSERVATION_MODE($FITS_headers);
  if ( $mode eq 'spectroscopy' ) {

    # If the nod iterator is used, then telescope offsets always come out
    # as 0,0.  We need to check if we're in the B beam (the nodded
    # position) to figure out what the offset is using the chop angle
    # and throw.
    if ( exists( $FITS_headers->{CHOPBEAM} ) &&
         $FITS_headers->{CHOPBEAM} =~ /^B/ &&
         exists( $FITS_headers->{CHPANGLE} ) &&
         exists( $FITS_headers->{CHPTHROW} ) ) {

      my $pi = 4 * atan2( 1, 1 );
      my $throw = $FITS_headers->{CHPTHROW};
      my $angle = $FITS_headers->{CHPANGLE} * $pi / 180.0;
      $decoff = $throw * cos( $angle );
    } else {
      $decoff = $FITS_headers->{TDECOFF};
    }

    # Imaging.
  } else {
    $decoff = $FITS_headers->{TDECOFF};
  }

  return $decoff;
}

=item B<from_DEC_TELESCOPE_OFFSET>

If we are nodding TDECOFF always comes out as 0.0. We always return
zero for spectroscopy and TDECOFF otherwise. It's possible that this
is incorrect and should only occur for the specific case of a B
chop beam. The chopbeam is not stored in the generic headers.

=cut

sub from_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $generic_headers = shift;
  my $tdecoff;
  if ($generic_headers->{OBSERVATION_MODE} eq 'spectroscopy') {
    $tdecoff = 0.0;
  } else {
    $tdecoff = $generic_headers->{DEC_TELESCOPE_OFFSET};
  }
  return ("TDECOFF",$tdecoff);
}

=item B<to_DETECTOR_READ_TYPE>

Usually DET_MODE but in some older data it can be DETMODE.

=cut

sub to_DETECTOR_READ_TYPE {
  my $self = shift;
  my $FITS_headers = shift;

  # cut off date is 20040206
  my $read_type;
  for my $k (qw/ DET_MODE DETMODE /) {
    if (exists $FITS_headers->{$k}) {
      $read_type = $FITS_headers->{$k};
      last;
    }
  }
  return $read_type;
}

=item B<to_NUMBER_OF_OFFSETS>

Cater for early data with missing headers. Normally the NOFFSETS
header is available.

=cut

sub to_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $FITS_headers = shift;

  # It's normally a ABBA pattern.  Add one for the final offset to 0,0.
  my $noffsets = 5;

  # Look for a defined header containing integers.
  if ( exists $FITS_headers->{NOFFSETS} ) {
    my $noff = $FITS_headers->{NOFFSETS};
    if ( defined $noff && $noff =~ /\d+/ ) {
      $noffsets = $noff;
    }
  }
  return $noffsets;
}

=item B<to_OBSERVATION_MODE>

Normally use INSTMODE header but for older data use CAMERA.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $mode;
  # 20040206
  for my $k (qw/ INSTMODE CAMERA /) {
    if (exists $FITS_headers->{$k}) {
      $mode = $FITS_headers->{$k};
      last;
    }
  }
  return $mode;
}

=item B<to_RA_TELESCOPE_OFFSET>

Right-ascension offsets need to be handled differently for spectroscopy
mode because of the new nod iterator.

=cut

sub _to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $raoff;

  # Determine the observation mode, e.g. spectroscopy or imaging.
  my $mode = $self->to_OBSERVATION_MODE($FITS_headers);
  if ( $mode eq 'spectroscopy' ) {

    # If the nod iterator is used, then telescope offsets always come out
    # as 0,0.  We need to check if we're in the B beam (the nodded
    # position) to figure out what the offset is using the chop angle
    # and throw.
    if ( exists( $FITS_headers->{CHOPBEAM} ) &&
         $FITS_headers->{CHOPBEAM} =~ /^B/ &&
         exists( $FITS_headers->{CHPANGLE} ) &&
         exists( $FITS_headers->{CHPTHROW} ) ) {
      my $pi = 4 * atan2( 1, 1 );
      my $throw = $FITS_headers->{CHPTHROW};
      my $angle = $FITS_headers->{CHPANGLE} * $pi / 180.0;
      $raoff = $throw * sin( $angle );

    } else {
      $raoff = $FITS_headers->{TRAOFF};
    }

    # Imaging.
  } else {
    $raoff = $FITS_headers->{TRAOFF};
  }
  return $raoff;
}

=item B<from_TELESCOPE>

For data taken before 20010906, return 'UKATC'. For data taken on and
after 20010906, return 'UKIRT'. Returned header is C<TELESCOP>.

=cut

sub from_TELESCOPE {
  my $self = shift;
  my $generic_headers = shift;
  my $utdate = $generic_headers->{'UTDATE'};
  if ( $utdate < 20010906 ) {
    return( "TELESCOP", "UKATC" );
  } else {
    return( "TELESCOP", "UKIRT" );
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
    $xref = 161;
  }
  return $xref;
}

=item B<from_X_REFERENCE_PIXEL>

Always returns the value '1' as CRPIX1.

=cut

sub from_X_REFERENCE_PIXEL {
  my $self = shift;
  return ("CRPIX1", 1.0);
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
    $yref = 121;
  }
  return $yref;
}

=item B<from_Y_REFERENCE_PIXEL>

Always returns the value '1' as CRPIX2.

=cut

sub from_Y_REFERENCE_PIXEL {
  my $self = shift;
  return ("CRPIX2", 1.0);
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
Copyright (C) 2006-2007 Particle Physics and Astronomy Research Council.
ACopyright (C) 2003-2005 Particle Physics and Astronomy Research Council.
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
