package Astro::FITS::HdrTrans::ACSIS;

=head1 NAME

Astro::FITS::HdrTrans::ACSIS - class for translation of JCMT ACSIS headers

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::ACSIS;

=head1 DESCRIPTION

This class provides a set of translations for ACSIS at JCMT.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use Astro::Coords;
use Astro::Telescope;
use DateTime;
use DateTime::TimeZone;

# inherit from the Base translation class and not HdrTrans
# itself (which is just a class-less wrapper)
use base qw/ Astro::FITS::HdrTrans::JCMT /;

# Use the FITS standard DATE-OBS handling
#use Astro::FITS::HdrTrans::FITS;

# Speed of light in km/s.
use constant CLIGHT => 2.99792458e5;

use vars qw/ $VERSION /;

$VERSION = "1.64";

# Cache UTC definition
our $UTC = DateTime::TimeZone->new( name => 'UTC' );

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 INST_DHS          => 'ACSIS',
                );

# unit mapping implies that the value propagates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                AIRMASS_END        => 'AMEND',
                AMBIENT_TEMPERATURE=> 'ATSTART',
                AZIMUTH_END        => 'AZEND',
                BACKEND            => 'BACKEND',
                BANDWIDTH_MODE     => 'BWMODE',
                CHOP_ANGLE         => 'CHOP_PA',
                CHOP_COORDINATE_SYSTEM => 'CHOP_CRD',
                CHOP_FREQUENCY     => 'CHOP_FRQ',
                CHOP_THROW         => 'CHOP_THR',
                ELEVATION_END      => 'ELEND',
                FRONTEND           => 'INSTRUME',
                NUMBER_OF_CYCLES   => 'NUM_CYC',
                SWITCH_MODE        => 'SW_MODE',
                SPECIES            => 'MOLECULE',
                VELOCITY_TYPE      => 'DOPPLER',
               );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

For this class, the method will return true if the B<BACKEND> header exists
and matches 'ACSIS'.

Can also match translated GSD files.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if ( exists $headers->{BACKEND} &&
       defined $headers->{BACKEND} &&
       $headers->{BACKEND} =~ /^ACSIS/i
     ) {
    return 1;

  # BACKEND will discriminate between DAS files converted to ACSIS format
  # from GSD format directly (handled by Astro::FITS::HdrTrans::JCMT_GSD).
  } elsif ( exists $headers->{BACKEND} &&
            defined $headers->{BACKEND} &&
            $headers->{BACKEND} =~ /^DAS/i &&
            ! (exists $headers->{'GSDFILE'} && exists $headers->{'SCA#'})) {
    # Do not want to confuse with reverse conversion
    # of JCMT_GSD data headers which will have a defined
    # BACKEND header of DAS.
    return 1;
  } elsif ( exists $headers->{INST_DHS} &&
            defined $headers->{INST_DHS} &&
            $headers->{INST_DHS} eq 'ACSIS') {
    # This is for the reverse conversion of DAS data
    return 1;
  } else {
    return 0;
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

=item B<to_DR_RECIPE>

Usually simply copies the RECIPE header. If the header is undefined,
initially set the recipe to REDUCE_SCIENCE. If the observation type
is skydip and the RECIPE header is "REDUCE_SCIENCE", actually use
REDUCE_SKYDIP. If a skydip is not being done and the STANDARD header
is true, then the recipe is set to REDUCE_STANDARD. If the INBEAM
header is "POL", the recipe name has "_POL" appended if it is a
science observation. "REDUCE_SCIENCE" is translated to
"REDUCE_SCIENCE_GRADIENT".

=cut

sub to_DR_RECIPE {
  my $class = shift;
  my $FITS_headers = shift;

  my $dr = $FITS_headers->{RECIPE};
  if ( defined( $dr ) ) {
     $dr = uc( $dr );
  } else {
     $dr = 'REDUCE_SCIENCE';
  }

  my $obstype = lc( $class->to_OBSERVATION_TYPE( $FITS_headers ) );
  my $pol = $class->to_POLARIMETER( $FITS_headers );
  my $standard = $class->to_STANDARD( $FITS_headers );
  my $utdate = $class->to_UTDATE( $FITS_headers );
  my $freq_sw = $class->_is_FSW( $FITS_headers );

  if ($utdate < 20080701) {
    if ($obstype eq 'skydip' && $dr eq 'REDUCE_SCIENCE') {
      $dr = "REDUCE_SKYDIP";
    }
  }

  my $is_sci = ( $obstype =~ /science|raster|scan|grid|jiggle/ );

  if ( $standard && $is_sci ) {
    $dr = "REDUCE_STANDARD";
  }

  # Append unless we have already appended
  if ( $utdate > 20081115 && $pol && $is_sci ) {
    $dr .= "_POL" unless $dr =~ /_POL$/;
  }

  if ( $dr eq 'REDUCE_SCIENCE' ) {
    $dr .= '_' . ($freq_sw ? 'FSW' : 'GRADIENT');
  }

  return $dr;
}

=item B<from_DR_RECIPE>

Returns DR_RECIPE unless we have a skydip.

=cut

sub from_DR_RECIPE {
  my $class = shift;
  my $generic_headers = shift;
  my $dr = $generic_headers->{DR_RECIPE};
  my $ut = $generic_headers->{UTDATE};
  if (defined $ut && $ut < 20080615) {
    if (defined $dr && $dr eq 'REDUCE_SKYDIP') {
      $dr = 'REDUCE_SCIENCE';
    }
  }
  return ("RECIPE" => $dr);
}

=item B<to_POLARIMETER>

If the polarimeter is in the beam, as denoted by the INBEAM header
containing "POL", then this returns true. Otherwise, return false.

=cut

sub to_POLARIMETER {
  my $class = shift;
  my $FITS_headers = shift;

  my $inbeam = $FITS_headers->{INBEAM};
  my $utdate = $class->to_UTDATE( $FITS_headers );

  if ( $utdate > 20081115 &&
       defined( $inbeam ) &&
       $inbeam =~ /pol/i ) {
    return 1;
  }
  return 0;
}

=item B<from_POLARIMETER>

If the POLARIMETER header is true, then return "POL" for the INBEAM
header. Otherwise, return undef.

=cut

sub from_POLARIMETER {
  my $class = shift;
  my $generic_headers = shift;

  my $pol = $generic_headers->{POLARIMETER};

  if ( $pol ) {
    return ( "INBEAM" => "POL" );
  }

  return ( "INBEAM" => undef );
}

=item B<to_REFERENCE_LOCATION>

Creates a string representing the location of the reference spectrum
to the nearest hundredth of a degree.  It takes the form
system_longitude_latitude where system will normally be J2000 or GAL.
If the string cannot be evaluated (such as missing headers), the
returned value is undefined.

=cut

sub to_REFERENCE_LOCATION {
  my $self = shift;
  my $FITS_headers = shift;

# Set the returned value in case something goes awry.
  my $ref_location = undef;

# Assume that the co-ordinate system is the same for the BASE
# co-ordinates as the offset to the reference spectrum.
  my ( $system, $base_lon, $base_lat );

  $system = defined( $FITS_headers->{'TRACKSYS'} ) ?
                     $FITS_headers->{'TRACKSYS'}   :
                     undef;
  $system =~ s/\s+$// if defined( $system );

# Obtain the base location's longitude in decimal degrees.
  $base_lon = defined( $FITS_headers->{'BASEC1'} ) ?
                       $FITS_headers->{'BASEC1'}   :
                       undef;

# Obtain the base location's latitude in decimal degrees.
  $base_lat = defined( $FITS_headers->{'BASEC2'} ) ?
                       $FITS_headers->{'BASEC2'}   :
                       undef;

# Derive the reference position's longitude.
  my $ref_lon = undef;
  if ( defined( $system ) && defined( $base_lon ) ) {

# The value of SKYREFX has the form
#    [OFFSET] <longitude_offset_in_arcsec> [<co-ordinate system>]
#
# Assume for now that the TRACKSYS and co-ordinate system are the
# same.
     if ( defined( $FITS_headers->{'SKYREFX'} ) ) {
        my $ref_x = $FITS_headers->{'SKYREFX'};
        my @comps = split( /\s+/, $ref_x );
        my $offset_lon = $comps[1] / 3600.0;

# Two decimal places should permit sufficient fuzziness.
        $ref_lon = sprintf( "%.2f", $base_lon + $offset_lon );
     }
  }

# Derive the reference position's latitude.
  my $ref_lat = undef;
  if ( defined( $system ) && defined( $base_lat ) ) {

# The value of SKYREFY has the form
#    [OFFSET] <latitude_offset_in_arcsec> [<co-ordinate system>]
#
# Assume for now that the TRACKSYS and co-ordinate system are the
# same.
     if ( defined( $FITS_headers->{'SKYREFY'} ) ) {
        my $ref_y = $FITS_headers->{'SKYREFY'};
        my @comps = split( /\s+/, $ref_y );
        my $offset_lat = $comps[1] / 3600.0;
        $ref_lat = sprintf( "%.2f", $base_lat + $offset_lat );
     }
  }

# Form the string comprising the three elements.
  if ( defined( $ref_lon ) && defined( $ref_lat ) ) {
     $ref_location = $system . "_" . $ref_lon . "_" . $ref_lat;
  }

  return $ref_location;
}


=item B<to_SAMPLE_MODE>

If the SAM_MODE value is either 'raster' or 'scan', return
'scan'. Otherwise, return the value in lowercase.

=cut

sub to_SAMPLE_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $sam_mode;
  if( defined( $FITS_headers->{'SAM_MODE'} ) &&
      uc( $FITS_headers->{'SAM_MODE'} ) eq 'RASTER' ) {
    $sam_mode = 'scan';
  } else {
    $sam_mode = lc( $FITS_headers->{'SAM_MODE'} );
  }
  return $sam_mode;
}

=item B<to_SURVEY>

Checks the value of the SURVEY header and uses that. If it's
undefined, then use the PROJECT header to determine an appropriate
survey.

=cut

sub to_SURVEY {
  my $self = shift;
  my $FITS_headers = shift;

  my $survey;

  if( defined( $FITS_headers->{'SURVEY'} ) ) {
    $survey = $FITS_headers->{'SURVEY'};
  } else {

    my $project = $FITS_headers->{'PROJECT'};
    if( defined( $project ) ) {
      if( $project =~ /JLS([GNS])/ ) {
        if( $1 eq 'G' ) {
          $survey = 'GBS';
        } elsif( $1 eq 'N' ) {
          $survey = 'NGS';
        } elsif( $1 eq 'S' ) {
          $survey = 'SLS';
        }
      }
    }
  }

  return $survey;

}

=item B<to_EXPOSURE_TIME>

Uses the to_UTSTART and to_UTEND functions to calculate the exposure
time. Returns the exposure time as a scalar, not as a Time::Seconds
object.

=cut

sub to_EXPOSURE_TIME {
  my $self = shift;
  my $FITS_headers = shift;

  # force date headers to be standardized
  $self->_fix_dates( $FITS_headers );

  my $return;
  if ( exists( $FITS_headers->{'DATE-OBS'} ) &&
       exists( $FITS_headers->{'DATE-END'} ) ) {
    my $start = $self->to_UTSTART( $FITS_headers );
    my $end = $self->to_UTEND( $FITS_headers );
    my $duration = $end - $start;
    $return = $duration->seconds;
  }
  return $return;
}

=item B<to_INSTRUMENT>

Converts the C<INSTRUME> header into the C<INSTRUMENT> header. If the
C<INSTRUME> header begins with "HARP" or "FE_HARP", then the
C<INSTRUMENT> header will be set to "HARP".

=cut

sub to_INSTRUMENT {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{'INSTRUME'} ) ) {
    if ( $FITS_headers->{'INSTRUME'} =~ /^HARP/ ||
         $FITS_headers->{'INSTRUME'} =~ /^FE_HARP/ ) {
      $return = "HARP";
    } else {
      $return = $FITS_headers->{'INSTRUME'};
    }
  }
  return $return;
}

=item B<to_OBSERVATION_ID>

Converts the C<OBSID> header directly into the C<OBSERVATION_ID>
generic header, or if that header does not exist, converts the
C<BACKEND>, C<OBSNUM>, and C<DATE-OBS> headers into C<OBSERVATION_ID>.

=cut

sub to_OBSERVATION_ID {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{'OBSID'} ) &&
       defined( $FITS_headers->{'OBSID'} ) ) {
    $return = $FITS_headers->{'OBSID'};
  } else {
    $self->_fix_dates( $FITS_headers );

    my $backend = lc( $self->to_BACKEND( $FITS_headers ) );
    my $obsnum = $self->to_OBSERVATION_NUMBER( $FITS_headers );
    my $dateobs = $self->to_UTSTART( $FITS_headers );

    if ( defined( $backend ) &&
         defined( $obsnum ) &&
         defined( $dateobs ) ) {
      my $datetime = $dateobs->datetime;
      $datetime =~ s/-//g;
      $datetime =~ s/://g;

      $return = join '_', $backend, $obsnum, $datetime;
    }
  }

  return $return;
}

=item B<to_OBSERVATION_MODE>

Concatenates the SAM_MODE, SW_MODE, and OBS_TYPE header keywords into
the OBSERVATION_MODE generic header, with spaces removed and joined
with underscores. For example, if SAM_MODE is 'jiggle ', SW_MODE is
'chop ', and OBS_TYPE is 'science ', then the OBSERVATION_MODE generic
header will be 'jiggle_chop_science'.

=cut

sub to_OBSERVATION_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if ( exists( $FITS_headers->{'SAM_MODE'} ) &&
       exists( $FITS_headers->{'SW_MODE'} ) &&
       exists( $FITS_headers->{'OBS_TYPE'} ) ) {
    my $sam_mode = $FITS_headers->{'SAM_MODE'};
    $sam_mode =~ s/\s//g;
    $sam_mode = "raster" if $sam_mode eq "scan";
    my $sw_mode = $FITS_headers->{'SW_MODE'};
    $sw_mode =~ s/\s//g;

    # handle OBS_TYPE missing
    my $obs_type = $FITS_headers->{'OBS_TYPE'};
    $obs_type = "science" unless $obs_type;
    $obs_type =~ s/\s//g;

    $return = ( ( $obs_type =~ /science/i )
                ? join '_', $sam_mode, $sw_mode
                : join '_', $sam_mode, $sw_mode, $obs_type );
  }
  return $return;
}

=item B<to_OBSERVATION_TYPE>

Returns the type of observation that was done. If the OBS_TYPE header
matches /science/, the SAM_MODE header is used: if SAM_MODE matches
/raster/, then return 'raster'. If SAM_MODE matches /grid/, then
return 'grid'. If SAM_MODE matches /jiggle/, then return 'jiggle'.

If the OBS_TYPE header matches /focus/, then return 'focus'. If the
OBS_TYPE header matches /pointing/, then return 'pointing'.

If none of the above options hold, then return undef.

=cut

sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  my $ot = $FITS_headers->{OBS_TYPE};

  # Sometimes we lack OBS_TYPE. In that case we have to assume SCIENCE
  # even though the headers are broken. (eg 20080509#18 RxWD)
  $ot = "science" unless $ot;

  if ( $ot ) {
    my $obs_type = lc( $ot );

    if ( $obs_type =~ /science/ ) {

      if ( defined( $FITS_headers->{'SAM_MODE'} ) ) {

        my $sam_mode = $FITS_headers->{'SAM_MODE'};

        if ( $sam_mode =~ /raster|scan/ ) {
          $return = "raster";
        } elsif ( $sam_mode =~ /grid/ ) {
          $return = "grid";
        } elsif ( $sam_mode =~ /jiggle/ ) {
          $return = "jiggle";
        } else {
          croak "Unexpected sample mode: '$sam_mode'";
        }
      }
    } elsif ( $obs_type =~ /focus/ ) {
      $return = "focus";
    } elsif ( $obs_type =~ /pointing/ ) {
      $return = "pointing";
    } elsif ( $obs_type =~ /skydip/) {
      $return = "skydip";
    } else {
      croak "Unexpected OBS_TYPE of '$obs_type'\n";
    }
  }

  return $return;
}


=item B<to_REST_FREQUENCY>

Uses an C<Starlink::AST::FrameSet> object to determine the
frequency. If such an object is not passed in, then the rest frequency
is set to zero.

Returns the rest frequency in Hz.

=cut

sub to_REST_FREQUENCY {
  my $self = shift;
  my $FITS_headers = shift;
  my $frameset = shift;

  my $return;

  if ( defined( $frameset ) &&
       UNIVERSAL::isa( $frameset, "Starlink::AST::FrameSet" ) ) {
    # in some rare cases restfreq is not set in the frameset
    eval {
       my $frequency = $frameset->Get( "restfreq" );
       $return = $frequency * 1_000_000_000;
    };
  } elsif ( exists( $FITS_headers->{'RESTFREQ'} ) ||
            ( exists( $FITS_headers->{'SUBHEADERS'} ) &&
              exists( $FITS_headers->{'SUBHEADERS'}->[0]->{'RESTFREQ'} ) ) ) {

    $return = exists( $FITS_headers->{'RESTFREQ'} ) ?
      $FITS_headers->{'RESTFREQ'}           :
        $FITS_headers->{'SUBHEADERS'}->[0]->{'RESTFREQ'};
    $return *= 1_000_000_000;
  }

  return $return;
}

=item B<to_SYSTEM_VELOCITY>

Converts the DOPPLER and SPECSYS headers into one combined
SYSTEM_VELOCITY header. The first three characters of each specific
header are used and concatenated. For example, if DOPPLER is 'radio'
and SPECSYS is 'LSR', then the resulting SYSTEM_VELOCITY generic
header will be 'RADLSR'. The results are always returned in capital
letters.

=cut

sub to_SYSTEM_VELOCITY {
  my $self = shift;
  my $FITS_headers = shift;
  my $frameset = shift;

  my $return;
  if ( exists( $FITS_headers->{'DOPPLER'} ) && defined $FITS_headers->{DOPPLER} ) {
    my $doppler = uc( $FITS_headers->{'DOPPLER'} );

    if ( defined( $frameset ) &&
         UNIVERSAL::isa( $frameset, "Starlink::AST::FrameSet" ) ) {
      # Sometimes we have frequency axis (rare)
      eval {
        my $sourcevrf = uc( $frameset->Get( "sourcevrf" ) );
        $return = substr( $doppler, 0, 3 ) . substr( $sourcevrf, 0, 3 );
      };
    }
    if (!defined $return) {
      if ( exists( $FITS_headers->{'SPECSYS'} ) ) {
        my $specsys = uc( $FITS_headers->{'SPECSYS'} );
        $return = substr( $doppler, 0, 3 ) . substr( $specsys, 0, 3 );
      } else {
        my $specsys = '';
        if ( $doppler eq 'RADIO' ) {
          $specsys = 'LSRK';
        } elsif ( $doppler eq 'OPTICAL' ) {
          $specsys = 'HELIOCENTRIC';
        }
        $return = substr( $doppler, 0, 3 ) . substr( $specsys, 0, 3 );
      }
    }
  }
  return $return;
}

=item B<to_TRANSITION>

Converts the TRANSITI header to the TRANSITION generic header.

This would be a unit mapping except that we would like to tidy up
some whitespace issues.

=cut

sub to_TRANSITION {
    my $self = shift;
    my $FITS_headers = shift;

    my $transition = $FITS_headers->{'TRANSITI'};

    return undef unless defined $transition;

    # Remove leading and trailing spaces.
    $transition =~ s/^ *//;
    $transition =~ s/ *$//;
    # Remove duplicated spaces.
    $transition =~ s/  +/ /g;

    return $transition;
}

=item B<from_TRANSITION>

Converts TRANSITION back to TRANSITI.

=cut

sub from_TRANSITION {
    my $self = shift;
    my $generic_headers = shift;

    my $transition = $generic_headers->{'TRANSITION'};

    if (defined $transition) {
        # Restore whitespace issue to allow comparison of untranslated header.
        $transition =~ s/ - /  - /;
    }

    return (TRANSITI => $transition);
}

=item B<to_VELOCITY>

Converts the ZSOURCE header into an appropriate system velocity,
depending on the value of the DOPPLER header. If the DOPPLER header is
'redshift', then the VELOCITY generic header will be returned
as a redshift. If the DOPPLER header is 'optical', then the
VELOCITY generic header will be returned as an optical
velocity. If the DOPPLER header is 'radio', then the VELOCITY
generic header will be returned as a radio velocity. Note that
calculating the radio velocity from the zeropoint (which is the
ZSOURCE header) gives accurates results only if the radio velocity is
a small fraction (~0.01) of the speed of light.

=cut

sub to_VELOCITY {
  my $self = shift;
  my $FITS_headers = shift;
  my $frameset = shift;

  my $velocity = 0;
  if ( defined( $frameset ) &&
       UNIVERSAL::isa( $frameset, "Starlink::AST::FrameSet" ) ) {

    my $sourcesys = "VRAD";
    if ( defined( $FITS_headers->{'DOPPLER'} ) ) {
      if ( $FITS_headers->{'DOPPLER'} =~ /rad/i ) {
        $sourcesys = "VRAD";
      } elsif ( $FITS_headers->{'DOPPLER'} =~ /opt/i ) {
        $sourcesys = "VOPT";
      } elsif ( $FITS_headers->{'DOPPLER'} =~ /red/i ) {
        $sourcesys = "REDSHIFT";
      }
    }
    # Sometimes we do not have a spec frame (broken files)
    eval {
      $frameset->Set( sourcesys => $sourcesys );
      $velocity = $frameset->Get( "sourcevel" );
    };
  } else {

    # We weren't passed a frameset, so try using other headers.
    if ( exists( $FITS_headers->{'DOPPLER'} ) &&
         ( exists( $FITS_headers->{'ZSOURCE'} ) ||
           exists( $FITS_headers->{'SUBHEADERS'}->[0]->{'ZSOURCE'} ) ) ) {
      my $doppler = uc( $FITS_headers->{'DOPPLER'} );
      my $zsource = exists( $FITS_headers->{'ZSOURCE'} ) ?
        $FITS_headers->{'ZSOURCE'}           :
          $FITS_headers->{'SUBHEADERS'}->[0]->{'ZSOURCE'};

      if ( $doppler eq 'REDSHIFT' ) {
        $velocity = $zsource;
      } elsif ( $doppler eq 'OPTICAL' ) {
        $velocity = $zsource * CLIGHT;
      } elsif ( $doppler eq 'RADIO' ) {
        $velocity = ( CLIGHT * $zsource ) / ( 1 + $zsource );
      }
    }
  }

  return $velocity;
}

=item B<to_SUBSYSTEM_IDKEY>

=cut

sub to_SUBSYSTEM_IDKEY {
  my $self = shift;
  my $FITS_headers = shift;

  # Try the general headers first
  my $general = $self->SUPER::to_SUBSYSTEM_IDKEY( $FITS_headers );
  return ( defined $general ? $general : "SUBSYSNR" );
}


=item B<_is_FSW>

Helper function to determine if we are doing frequency switch.

=cut

sub _is_FSW {
  my $class = shift;
  my $FITS_headers = shift;

  my $fsw = $FITS_headers->{SW_MODE};

  if ( defined( $fsw ) &&
       $fsw =~ /freqsw/i ) {
    return 1;
  }
  return 0;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2016 East Asian Observatory.
Copyright (C) 2007-2013, 2016 Science and Technology Facilities Council.
Copyright (C) 2005-2007 Particle Physics and Astronomy Research Council.
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
