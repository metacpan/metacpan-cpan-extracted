# -*-perl-*-

package Astro::FITS::HdrTrans::LCO;

=head1 NAME

Astro::FITS::HdrTrans::LCO - Base class for translation of LCO instruments

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::LCO;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
instrumentation from LCO. It should not be use directly for translation of
instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from the Base translation class and not HdrTrans itself
# (which is just a class-less wrapper).

use base qw/ Astro::FITS::HdrTrans::FITS /;

use vars qw/ $VERSION /;

$VERSION = "1.65";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 DETECTOR_READ_TYPE    => "STARE",
                 OBSERVATION_MODE    => "imaging",
                 NUMBER_OF_EXPOSURES   => 1,
                 POLARIMETRY => 0,
                 SPEED_GAIN => "NORMAL"
                );

my %UNIT_MAP = (
                EXPOSURE_TIME       => "EXPTIME",
                GAIN          => "GAIN",
                READNOISE     => "RDNOISE",
                INSTRUMENT    => "INSTRUME",
                OBJECT        => "OBJECT",
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

=item B<to_AIRMASS_END>

Set's the airmass at the end of the exposure. The C<AMEND> is used if it exists,
otherwise C<AIRMASS> is used. In the case of neither existing, it is set to 1.0.

=cut

sub to_AIRMASS_END {
  my $self = shift;
  my $FITS_headers = shift;
  my $end_airmass = 1.0;
  if ( exists $FITS_headers->{"AMEND"} && $FITS_headers->{"AMEND"} !~ /^UNKNOWN/ ) {
    $end_airmass = $FITS_headers->{"AMEND"};
  } elsif ( exists $FITS_headers->{"AIRMASS"} && $FITS_headers->{"AIRMASS"} !~ /^UNKNOWN/  ) {
    $end_airmass = $FITS_headers->{"AIRMASS"};
  }
  return $end_airmass;
}

=item B<to_AIRMASS_START>

Set's the airmass at the start of the exposure. The C<AMSTART> is used if it
exists, otherwise C<AIRMASS> is used. In the case of neither existing, it is set
to 1.0.

=cut

sub to_AIRMASS_START {
  my $self = shift;
  my $FITS_headers = shift;
  my $start_airmass = 1.0;
  if ( exists $FITS_headers->{"AMSTART"} && $FITS_headers->{"AMSTART"} !~ /^UNKNOWN/ ) {
    $start_airmass = $FITS_headers->{"AMSTART"};
  } elsif ( exists $FITS_headers->{"AIRMASS"} && $FITS_headers->{"AIRMASS"} !~ /^UNKNOWN/ ) {
    $start_airmass = $FITS_headers->{"AIRMASS"};
  }
  return $start_airmass;
}

=item B<to_DEC_BASE>

Converts the base declination from sexagesimal d:m:s to decimal
degrees using the C<DEC> keyword, defaulting to 0.0.

=cut

sub to_DEC_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $dec = 0.0;
  my $sexa = $FITS_headers->{"DEC"};
  if ( defined( $sexa ) ) {
    $dec = $self->dms_to_degrees( $sexa );
  }
  return $dec;
}


=item B<to_DR_RECIPE>

Returns the data-reduction recipe name.  The selection depends on the
values of the C<OBJECT> and C<OBSTYPE> keywords.  The default is
"QUICK_LOOK".  A dark returns "REDUCE_DARK", and an object's recipe is
"JITTER_SELF_FLAT".

=cut

sub to_DR_RECIPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $recipe = "QUICK_LOOK";

  if ( exists $FITS_headers->{OBSTYPE} ) {
    if ( $FITS_headers->{OBSTYPE} =~ /BIAS/i ) {
      $recipe = "REDUCE_BIAS";
    } elsif ( $FITS_headers->{OBSTYPE} =~ /DARK/i ) {
      $recipe = "REDUCE_DARK";
    } elsif ( $FITS_headers->{OBSTYPE} =~ /FLAT/i ) {
      $recipe = "SKY_FLAT";
    } elsif ( $FITS_headers->{OBSTYPE} =~ /EXPOSE/i ) {
      #     $recipe = "JITTER_SELF_FLAT";
      $recipe = "OFFLINE_REDUCTION";
    } elsif ( $FITS_headers->{OBSTYPE} =~ /STANDARD/i ) {
      #    $recipe = "BRIGHT_POINT_SOURCE_NCOLOUR_APHOT";
      $recipe = "OFFLINE_REDUCTION";
    }
  }

  return $recipe;
}

# Equinox may be absent...
sub to_EQUINOX {
  my $self = shift;
  my $FITS_headers = shift;
  my $equinox = 2000.0;
  if ( exists $FITS_headers->{EQUINOX} ) {
    $equinox = $FITS_headers->{EQUINOX};
  }
  return $equinox;
}

=item B<to_FILTER>

Look for C<FILTER> keyword first and if not found, concatenate the individual
C<FILTERx> keywords together, minus any that say "air"
=cut

sub to_FILTER {
  my $self = shift;
  my $FITS_headers = shift;
  my $filter = "";
  if (exists $FITS_headers->{"FILTER"} ) {
   $filter = $FITS_headers->{"FILTER"};
  } else {
    my $filter1 = $FITS_headers->{ "FILTER1" };
    my $filter2 = $FITS_headers->{ "FILTER2" };
    my $filter3 = $FITS_headers->{ "FILTER3" };

    if ( $filter1 =~ "air" ) {
       $filter = $filter2;
    }

    if ( $filter2 =~ "air" ) {
       $filter = $filter1;
    }

    if ( $filter1 =~ "air" && $filter2 =~ "air" ) {
       $filter = $filter3;
    }

    if ( ( $filter1 =~ "air" ) &&
         ( $filter2 =~ "air" ) &&
         ( $filter3 =~ "air" ) ) {
       $filter = "air";
    }
  }
  return $filter;
}

sub from_FILTER {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  $return_hash{'FILTER'} = $generic_headers->{FILTER};

  return %return_hash;
}


=item B<to_NUMBER_OF_OFFSETS>

Return the number of offsets. (dithers)

=cut

sub to_NUMBER_OF_OFFSETS {
  my $self = shift;
  my $FITS_headers = shift;
  my $ndither = ( defined( $FITS_headers->{FRMTOTAL} ) ? $FITS_headers->{FRMTOTAL} : 1 );

  return $ndither + 1;

}

=item B<_to_OBSERVATION_NUMBER>

Converts to the observation number. This uses the C<FRAMENUM> keyword if it
exists, otherwise it is obtained from the filename

=cut

sub to_OBSERVATION_NUMBER {
  my $self = shift;
  my $FITS_headers = shift;
  my $obsnum = 0;
  if ( exists ( $FITS_headers->{FRAMENUM} ) ) {
    $obsnum = $FITS_headers->{FRAMENUM};
  }

  return $obsnum;
}

=item B<to_OBSERVATION_TYPE>

Determines the observation type from the C<OBSTYPE> keyword. Almost a direct
mapping except "EXPOSE" which needs mapping to OBJECT. Lambert may need extra
handling in future

=cut

sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $obstype = uc( $FITS_headers->{OBSTYPE} );
  if ( $obstype eq "EXPOSE" || $obstype eq "STANDARD" ) {
    $obstype = "OBJECT";
  }
  return $obstype;
}

=item B<to_RA_BASE>

Converts the base right ascension from sexagesimal h:m:s to decimal degrees
using the C<RA> keyword, defaulting to 0.0.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $ra = 0.0;
  my $sexa = $FITS_headers->{"RA"};
  if ( defined( $sexa ) ) {
    $ra = $self->hms_to_degrees( $sexa );
  }
  return $ra;
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

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  #   use Data::Dumper;
  #   print Dumper $FITS_headers;
  return $self->_get_UT_date( $FITS_headers );
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
  my $ymd = $generic_headers->{DATE};
  my $dobs = substr( $ymd, 0, 4 ) . "-" . substr( $ymd, 4, 2 ) ."-" . substr( $ymd, 6, 2 );
  return ( "DATE-OBS"=>$dobs );
}

=item B<to_XBINNING>

Determines the binning in the X direction of the frame. We look for C<XBINNING>
if it exists, otherwise we look for the C<CCDSUM> keyword and extract the first
part.

=cut

sub to_XBINNING {
  my $self = shift;
  my $FITS_headers = shift;
  my $xbinning = 2;
  if ( exists ( $FITS_headers->{XBINNING} ) ) {
    $xbinning = $FITS_headers->{XBINNING};
  } elsif ( exists ( $FITS_headers->{CCDSUM} ) ) {
    my $ccdsum = $FITS_headers->{CCDSUM};
    my @pos = split( / /, $ccdsum );
    $xbinning = $pos[ 0 ];
  }
  return $xbinning;
}

=item B<to_YBINNING>

Determines the binning in the Y direction of the frame. We look for C<YBINNING>
if it exists, otherwise we look for the C<CCDSUM> keyword and extract the second
part.

=cut

sub to_YBINNING {
  my $self = shift;
  my $FITS_headers = shift;
  my $ybinning = 2;
  if ( exists ( $FITS_headers->{YBINNING} ) ) {
    $ybinning = $FITS_headers->{YBINNING};
  } elsif ( exists ( $FITS_headers->{CCDSUM} ) ) {
    my $ccdsum = $FITS_headers->{CCDSUM};
    my @pos = split( / /, $ccdsum );
    $ybinning = $pos[ 1 ];
  }
  return $ybinning;
}

# Supplementary methods for the translations
# ------------------------------------------

=item B<dms_to_degrees>

Converts a sky angle specified in d m s format into decimal degrees.
The argument is the sexagesimal-format angle.

=cut

sub dms_to_degrees {
  my $self = shift;
  my $sexa = shift;
  my $dms;
  if ( defined( $sexa ) ) {
    if ($sexa =~ /UNKNOWN/i or $sexa eq "N/A" or $sexa eq "NaN" ) {
      $dms = 0.0;
    } else {
      my @pos = split( /:/, $sexa );
      $dms = abs($pos[ 0 ]) + $pos[ 1 ] / 60.0 + $pos [ 2 ] / 3600.0;
      if ( $pos[ 0 ] =~ /-/ ) {
        $dms = -$dms;
      }
    }
  }
  return $dms;
}

=item B<hms_to_degrees>

Converts a sky angle specified in h m s format into decimal degrees.
It takes no account of latitude.  The argument is the sexagesimal
format angle.

=cut

sub hms_to_degrees {
  my $self = shift;
  my $sexa = shift;
  my $hms;
  if ( defined( $sexa ) ) {
    if ($sexa =~ /UNKNOWN/i or $sexa eq "N/A" or $sexa eq "NaN" ) {
      $hms = 0.0;
    } else {
      my @pos = split( /:/, $sexa );
      $hms = 15.0 * ( $pos[ 0 ] + $pos[ 1 ] / 60.0 + $pos [ 2 ] / 3600.0 );
    }
  }
  return $hms;
}

# Returns the UT date in YYYYMMDD format.
sub _get_UT_date {
  my $self = shift;
  my $FITS_headers = shift;

  #  use Data::Dumper;print Dumper $FITS_headers;die;
  # This is UT start and time.
  my $dateobs = $FITS_headers->{"DATE-OBS"};
  #    print "DATE-OBS=$dateobs\n";
  my $utdate =  substr( $dateobs, 0, 4 ) . substr( $dateobs, 5, 2 ) . substr( $dateobs, 8, 2 );
  #    print "UTDATE=$utdate\n";
  # Extract out the data in yyyymmdd format.
  return $utdate;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Tim Lister E<lt>tlister@lcogt.netE<gt>

=head1 COPYRIGHT

=cut

1;
