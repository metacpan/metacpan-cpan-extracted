package Astro::FITS::HdrTrans::INGRID;

=head1 NAME

Astro::FITS::HdrTrans::INGRID - WHT INGRID translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::INGRID;

  %gen = Astro::FITS::HdrTrans::INGRID->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the INGRID camera of the William Herschel Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from FITS.
use base qw/ Astro::FITS::HdrTrans::FITS /;

use vars qw/ $VERSION /;

$VERSION = "1.64";

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (
                 POLARIMETRY         => 0,
                 OBSERVATION_MODE    => 'imaging',
                 WAVEPLATE_ANGLE     => 0,
                );

# NULL mappings used to override base-class implementations.
my @NULL_MAP = qw/ /;

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.

my %UNIT_MAP = (
                AIRMASS_END          => "AIRMASS",
                AIRMASS_START        => "AIRMASS",
                EXPOSURE_TIME        => "EXPTIME",
                FILTER               => "INGF1NAM",
                INSTRUMENT           => "DETECTOR",
                NUMBER_OF_EXPOSURES  => "COAVERAG",
                NUMBER_OF_READS      => "NUMREADS",
                OBSERVATION_NUMBER   => "RUN"
               );


# Create the translation methods.
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
  return qr/^INGRID/;
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_DEC_BASE>

Converts the base declination from sexagesimal d:m:s to decimal
degrees using the C<CAT-DEC> keyword, defaulting to 0.0.

=cut

sub to_DEC_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $dec = 0.0;
  my $sexa = $FITS_headers->{"CAT-DEC"};
  if ( defined( $sexa ) ) {
    $dec = $self->dms_to_degrees( $sexa );
  }
  return $dec;
}

=item B<to_DEC_SCALE>

Sets the declination scale in arcseconds per pixel.  The C<CCDYPIXE>
and C<INGPSCAL> headers are used when both are defined.  Otherwise it
returns a default value of 0.2387 arcsec/pixel, assuming north is up.

=cut

sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $decscale = 0.2387;

  # Assumes either x-y scales the same or the y corresponds to
  # declination.
  my $ccdypixe = $self->via_subheader( $FITS_headers, "CCDYPIXE" );
  my $ingpscal = $self->via_subheader( $FITS_headers, "INGPSCAL" );
  if ( defined $ccdypixe && defined $ingpscal ) {
    $decscale = $ccdypixe * 1000.0 * $ingpscal;
  }
  return $decscale;
}

=item B<to_DEC_TELESCOPE_OFFSET>

Sets the declination telescope offset in arcseconds.   It uses the
C<CAT-DEC> and C<DEC> keywords to derive the offset, and if either
does not exist, it returns a default of 0.0.

=cut

sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $decoffset = 0.0;
  if ( exists $FITS_headers->{"CAT-DEC"} && exists $FITS_headers->{DEC} ) {

    # Obtain the reference and telescope declinations positions measured in degrees.
    my $refdec = $self->dms_to_degrees( $FITS_headers->{"CAT-DEC"} );
    my $dec = $self->dms_to_degrees( $FITS_headers->{DEC} );

    # Find the offsets between the positions in arcseconds on the sky.
    $decoffset = 3600.0 * ( $dec - $refdec );
  }

  # The sense is reversed compared with UKIRT, as these measure the
  # place son the sky, not the motion of the telescope.
  return -1.0 * $decoffset
}

=item B<to_DETECTOR_READ_TYPE>

Returns the UKIRT-like detector type "STARE" or "NDSTARE" from the
FITS C<REDMODE> and C<NUMREADS> keywords.

This is guesswork at present.

=cut

sub to_DETECTOR_READ_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $read_type;
  my $readout_mode = $FITS_headers->{READMODE};
  my $nreads = $FITS_headers->{NUMREADS};
  if ( $readout_mode =~ /^mndr/i ||
       ( $readout_mode =~ /^cds/i && $nreads == 1 ) ) {
    $read_type = "STARE";
  } elsif ( $readout_mode =~ /^cds/i ) {
    $read_type = "NDSTARE";
  }
  return $read_type;
}

=item B<to_DR_RECIPE>

Returns the data-reduction recipe name.  The selection depends on the
values of the C<OBJECT> and C<OBSTYPE> keywords.  The default is
"QUICK_LOOK".  A dark returns "REDUCE_DARK", and an object's recipe is
"JITTER_SELF_FLAT".

=cut

# No clue what the recipe is apart for a dark and assume a dither
# pattern means JITTER_SELF_FLAT.
sub to_DR_RECIPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $recipe = "QUICK_LOOK";

  # Look for a dither pattern.  These begin D-<n>/<m>: where
  # <m> represents the number of jitter positions in the group
  # and <n> is the number within the group.
  my $object = $FITS_headers->{OBJECT};
  if ( $object =~ /D-\d+\/\d+/ ) {
    $recipe = "JITTER_SELF_FLAT";
  } elsif ( $FITS_headers->{OBSTYPE} =~ /DARK/i ) {
    $recipe = "REDUCE_DARK";
  }

  return $recipe;
}

=item B<to_EQUINOX>

Returns the equinox in decimal years.  It's taken from the C<CAT-EQUI>
keyword, if it exists, defaulting to 2000.0 otherwise.

=cut

sub to_EQUINOX {
  my $self = shift;
  my $FITS_headers = shift;
  my $equinox = 2000.0;
  if ( exists $FITS_headers->{"CAT-EQUI"} ) {
    $equinox = $FITS_headers->{"CAT-EQUI"};
    $equinox =~ s/[BJ]//;
  }
  return $equinox;
}

=item B<to_GAIN>

Returns the gain in electrons per data number.  This is taken from
the C<GAIN> keyword, with a default of 4.1.

=cut

sub to_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $gain = 4.1;
  my $subval = $self->via_subheader( $FITS_headers, "GAIN" );
  $gain = $subval if defined $subval;
  return $gain;
}

=item B<to_NUMBER_OF_OFFSETS>

Returns the number of offsets.  It uses the UKIRT convention so
it is equivalent to the number of dither positions plus one.
The value is derived from the C<OBJECT> keyword, with a default of 6.

=cut

sub to_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $FITS_headers = shift;
  my $noffsets = 5;

  # Look for a dither pattern.  These begin D-<n>/<m>: where
  # <m> represents the number of jitter positions in the group
  # and <n> is the number within the group.
  my $object = $FITS_headers->{OBJECT};
  if ( $object =~ /D-\d+\/\d+/ ) {

    # Extract the string between the solidus and the colon.  Add one
    # to match the UKIRT convention.
    $noffsets = substr( $object, index( $object, "/" ) + 1 );
    $noffsets = substr( $noffsets, 0, index( $noffsets, ":" ) );
  }
  return $noffsets + 1;
}

=item B<to_OBJECT>

Reeturns the object name.  It is extracted from the C<OBJECT> keyword.

=cut

sub to_OBJECT {
  my $self = shift;
  my $FITS_headers = shift;
  my $object = $FITS_headers->{OBJECT};

  # Look for a dither pattern.  These begin D-<n>/<m>: where
  # <m> represents the number of jitter positions in the group
  # and <n> is the number within the group.  We want to extract
  # the actual object name.
  if ( $object =~ /D-\d+\/\d+/ ) {
    $object = substr( $object, index( $object, ":" ) + 2 );
  }
  return $object;
}

=item B<to_OBSERVATION_TYPE>

Determines the observation type from the C<OBSTYPE> keyword provided it is
"TARGET" for an object dark frame.

=cut

sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $obstype = uc( $FITS_headers->{OBSTYPE} );
  if ( $obstype eq "TARGET" ) {
    $obstype = "OBJECT";
  }
  return $obstype;
}

=item B<to_RA_BASE>

Converts the base right ascension from sexagesimal h:m:s to decimal degrees
using the C<CAT-RA> keyword, defaulting to 0.0.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $ra = 0.0;
  my $sexa = $FITS_headers->{"CAT-RA"};
  if ( defined( $sexa ) ) {
    $ra = $self->hms_to_degrees( $sexa );
  }
  return $ra;
}

=item B<to_RA_SCALE>

Sets the right-ascension scale in arcseconds per pixel.  The C<CCDXPIXE>
and C<INGPSCAL> headers are used when both are defined.  Otherwise it
returns a default value of 0.2387 arcsec/pixel, assuming east is to
the left.

=cut

sub to_RA_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $rascale = -0.2387;

  # Assumes either x-y scales the same or the x corresponds to right
  # ascension, and right ascension decrements with increasing x.
  my $ccdxpixe = $self->via_subheader( $FITS_headers, "CCDXPIXE" );
  my $ingpscal = $self->via_subheader( $FITS_headers, "INGPSCAL" );
  if ( defined $ccdxpixe && defined $ingpscal ) {
    $rascale = $ccdxpixe * -1000.0 * $ingpscal;
  }
  return $rascale;
}

=item B<to_RA_TELESCOPE_OFFSET>

Sets the right-ascension telescope offset in arcseconds.   It uses the
C<CAT-RA>, C<RA>, C<CAT-DEC> keywords to derive the offset, and if any
of these keywords does not exist, it returns a default of 0.0.

=cut

sub to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $raoffset = 0.0;

  if ( exists $FITS_headers->{"CAT-DEC"} &&
       exists $FITS_headers->{"CAT-RA"} && exists $FITS_headers->{RA} ) {

    # Obtain the reference and telescope sky positions measured in degrees.
    my $refra = $self->hms_to_degrees( $FITS_headers->{"CAT-RA"} );
    my $ra = $self->hms_to_degrees( $FITS_headers->{RA} );
    my $refdec = $self->dms_to_degrees( $FITS_headers->{"CAT-DEC"} );

    # Find the offset between the positions in arcseconds on the sky.
    $raoffset = 3600.0 * ( $ra - $refra ) * $self->cosdeg( $refdec );
  }

  # The sense is reversed compared with UKIRT, as these measure the
  # place son the sky, not the motion of the telescope.
  return -1.0 * $raoffset;
}

=item B<to_ROTATION>

Returns the orientation of the detector in degrees anticlockwise
from north via east.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->rotation( $FITS_headers );
}

=item B<to_SPEED_GAIN>

Returns the speed gain.  This is either "Normal" or "HiGain", the
selection depending on the value of the C<CCDSPEED> keyword.

=cut

# Fixed values for the gain depend on the camera (SW or LW), and for LW
# the readout mode.
sub to_SPEED_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $spd_gain;
  my $speed = $FITS_headers->{CCDSPEED};
  if ( $speed =~ /SLOW/ ) {
    $spd_gain = "Normal";
  } else {
    $spd_gain = "HiGain";
  }
  return $spd_gain;
}

=item B<to_STANDARD>

Returns whether or not the observation is of a standard source.  It is
deemed to be a standard when the C<OBSTYPE> keyword is "STANDARD".

=cut

sub to_STANDARD {
  my $self = shift;
  my $FITS_headers = shift;
  my $standard = 0;
  my $type = $FITS_headers->{OBSTYPE};
  if ( uc( $type ) eq "STANDARD" ) {
    $standard = 1;
  }
  return $standard;
}

=item B<to_UTDATE>

Returns the UT date as C<Time::Piece> object.  It copes with non-standard
format in C<DATE-OBS>.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  return $self->get_UT_date( $FITS_headers );
}

=item B<to_UTEND>

Returns the UT time of the end of the observation as a C<Time::Piece> object.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;

  # This is the approximate end UT.
  my $start = $self->to_UTSTART( $FITS_headers );
  return $self->_add_seconds( $start, $FITS_headers->{EXPTIME} );
}

=item B<to_UTSTART>

Returns an estimated UT time of the start of the observation as a
C<Time::Piece> object.  The start time is derived from the C<DATE-OBS>
keyword and if C<DATE-OBS> only supplies a date, the time from the
C<UTSTART> keyword is appended before conversaion to a C<Time::Piece>
object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists $FITS_headers->{'DATE-OBS'} ) {
    my $iso;
    if ( $FITS_headers->{'DATE-OBS'} =~ /T/ ) {
      # standard format
      $iso = $FITS_headers->{'DATE-OBS'};
    } elsif ( exists $FITS_headers->{UTSTART} ) {
      $iso = $FITS_headers->{'DATE-OBS'}. "T" . $FITS_headers->{UTSTART};
    }
    $return = $self->_parse_iso_date( $iso ) if $iso;
  }
  return $return;
}

=item B<to_X_LOWER_BOUND>

Returns the lower bound along the X-axis of the area of the detector
as a pixel index.

=cut

sub to_X_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = $self->getbounds( $FITS_headers );
  return $bounds[ 0 ];
}

=item B<to_X_REFERENCE_PIXEL>

Specifies the X-axis reference pixel near the frame centre.  It uses
the nominal reference pixel if that is correctly supplied, failing
that it takes the average of the bounds, and if these headers are also
absent, it uses a default which assumes the full array.

=cut

sub to_X_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $xref;
  my @bounds = $self->getbounds( $FITS_headers );
  if ( $bounds[ 0 ] > 1 || $bounds[ 1 ] < 1024 ) {
    $xref = nint( ( $bounds[ 0 ] + $bounds[ 1 ] ) / 2 );
  } else {
    $xref = 512;
  }
  return $xref;
}

=item B<to_X_UPPER_BOUND>

Returns the upper bound along the X-axis of the area of the detector
as a pixel index.

=cut

sub to_X_UPPER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = $self->getbounds( $FITS_headers );
  return $bounds[ 1 ];
}

=item B<to_Y_LOWER_BOUND>

Returns the lower bound along the Y-axis of the area of the detector
as a pixel index.

=cut

sub to_Y_LOWER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = $self->getbounds( $FITS_headers );
  return $bounds[ 2 ];
}

=item B<to_Y_REFERENCE_PIXEL>

Specifies the Y-axis reference pixel near the frame centre.  It uses
the nominal reference pixel if that is correctly supplied, failing
that it takes the average of the bounds, and if these headers are also
absent, it uses a default which assumes the full array.

=cut

sub to_Y_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $yref;
  my @bounds = $self->getbounds( $FITS_headers );
  if ( $bounds[ 2 ] > 1 || $bounds[ 3 ] < 1024 ) {
    $yref = nint( ( $bounds[ 2 ] + $bounds[ 3 ] ) / 2 );
  } else {
    $yref = 512;
  }
  return $yref;
}

=item B<to_Y_UPPER_BOUND>

Returns the upper bound along the Y-axis of the area of the detector
as a pixel index.

=cut

sub to_Y_UPPER_BOUND {
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = $self->getbounds( $FITS_headers );
  return $bounds[ 3 ];
}

=back

# Supplementary methods for the translations
# ------------------------------------------

=head1 HELPER ROUTINES

These are INGRID-specific helper routines.

=over 4

=item B<dms_to_degrees>

Converts a sky angle specified in d:m:s format into decimal degrees.
The argument is the sexagesimal-format angle.

=cut

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

# Obtain the detector bounds from a section in [xl:xu,yl:yu] syntax.
# If the RTDATSEC header is absent, use a default which corresponds
# to the full array.
sub getbounds{
  my $self = shift;
  my $FITS_headers = shift;
  my @bounds = ( 1, 1024, 1, 1024 );
  if ( exists $FITS_headers->{RTDATSEC} ) {
    my $section = $FITS_headers->{RTDATSEC};
    $section =~ s/\[//;
    $section =~ s/\]//;
    $section =~ s/,/:/g;
    @bounds = split( /:/, $section );
  }
  return @bounds;
}

=item B<get_UT_date>

Returns the UT date in YYYYMMDD format.  It parses the non-standard
ddMmmyy C<DATE-OBS> keyword.

=cut

sub get_UT_date {
  my $self = shift;
  my $FITS_headers = shift;

  # This is UT start and time.
  my $dateobs = $FITS_headers->{"DATE-OBS"};

  # Extract out the data in yyyymmdd format.
  return substr( $dateobs, 0, 4 ) . substr( $dateobs, 5, 2 ) . substr( $dateobs, 8, 2 )
}

=item B<hms_to_degrees>

Converts a sky angle specified in h:m:s format into decimal degrees.
It takes no account of latitude.  The argument is the sexagesimal
format angle.

=cut

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

=item B<rotation>

Derives the rotation angle in degrees from the C<ROTSKYPA> keyword, with a
default of 0.0.

=cut

sub rotation{
  my $self = shift;
  my $FITS_headers = shift;
  my $rotangle = 0.0;

  if ( exists $FITS_headers->{ROTSKYPA} ) {
    $rotangle = $FITS_headers->{ROTSKYPA};
  }
  return $rotangle;
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
