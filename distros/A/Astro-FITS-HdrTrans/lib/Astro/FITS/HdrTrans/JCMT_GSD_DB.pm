package Astro::FITS::HdrTrans::JCMT_GSD_DB;

=head1 NAME

Astro::FITS::HdrTrans::JCMT_GSD_DB - JCMT GSD Database header translations

=head1 DESCRIPTION

Converts information contained in JCMT heterodyne database headers
to and from generic headers. See Astro::FITS::HdrTrans for a list of
generic headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use Time::Piece;

# Inherit from Base
use base qw/ Astro::FITS::HdrTrans::Base /;

use vars qw/ $VERSION /;

$VERSION = "1.59";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 INST_DHS         => 'HET_GSD',
                 COORDINATE_UNITS => 'decimal',
                 EQUINOX          => 'current',
                 TELESCOPE        => 'JCMT',
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = ();

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                AMBIENT_TEMPERATURE => "TAMB",
                APERTURE => "APERTURE",
                AZIMUTH_START => "AZ",
                BACKEND => "BACKEND",
                BACKEND_SECTIONS => "NORSECT",
                CHOP_FREQUENCY => "CHOPFREQ",
                CHOP_THROW => "CHOPTHRW",
                COORDINATE_SYSTEM => "COORDCD",
                #        COORDINATE_TYPE => "C4LSC",
                CYCLE_LENGTH => "CYCLLEN",
                #        DEC_BASE => "",
                ELEVATION_START => "EL",
                FILENAME => "GSDFILE",
                FILTER => "FILTER",
                FREQUENCY_RESOLUTION => "FREQRES",
                FRONTEND => "FRONTEND",
                HUMIDITY => "HUMIDITY",
                NUMBER_OF_CYCLES => "NOCYCLES",
                NUMBER_OF_SUBSCANS => "NOSCANS",
                OBJECT => "OBJECT",
                OBSERVATION_MODE => "OBSMODE",
                OBSERVATION_NUMBER => "SCAN",
                PROJECT => "PROJID",
                #        RA_BASE => "C4RADATE",
                RECEIVER_TEMPERATURE => "TRX",
                ROTATION => "YPOSANG",
                REST_FREQUENCY => "RESTFRQ1",
                SEEING => "PHA",
                SWITCH_MODE => "SWMODE",
                SYSTEM_TEMPERATURE => "STSYS",
                TAU => "TAU",
                USER_AZ_CORRECTION => "UXPNT",
                USER_EL_CORRECTION => "UYPNT",
                VELOCITY => "VELOCITY",
                VELOCITY_REFERENCE_FRAME => "VREF",
                VELOCITY_TYPE => "VDEF",
                X_BASE => "XREF",
                Y_BASE => "YREF",
                X_DIM => "NOXPTS",
                Y_DIM => "NOYPTS",
                X_REQUESTED => "XSOURCE",
                Y_REQUESTED => "YSOURCE",
                X_SCALE => "DELTAX",
                Y_SCALE => "DELTAY",
               );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

For this class, the method will return true if the "GSDFILE" header
exists and the "SCA#" header exist.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if (exists $headers->{GSDFILE} && exists $headers->{"SCA#"}) {
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

=item B<to_INSTRUMENT>

Sets the C<INSTRUMENT> generic header. For RxA3i, sets the value
to RXA3. For RxB, sets the value to RXB3.

=cut

sub to_INSTRUMENT {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'FRONTEND'} ) ) {
    $return = $FITS_headers->{'FRONTEND'};
    if ( $return =~ /^rxa3/i ) {
      $return = "RXA3";
    } elsif ( $return =~ /^rxb/i ) {
      $return = "RXB3";
    }
  }
  return $return;
}

=item B<to_OBSERVATION_ID>

Calculate a unique Observation ID.

=cut

# Note this routine is generic for JCMT heterodyne instrumentation.
# Would be completely generic if BACKEND was not used in preference to instrument.

sub to_OBSERVATION_ID {
  my $self = shift;
  my $FITS_headers = shift;
  my $backend = lc( $self->to_BACKEND( $FITS_headers ) );
  my $obsnum = $self->to_OBSERVATION_NUMBER( $FITS_headers );
  my $dateobs = $self->to_UTSTART( $FITS_headers );
  my $datetime = $dateobs->datetime;
  $datetime =~ s/-//g;
  $datetime =~ s/://g;

  my $obsid = join('_', $backend, $obsnum, $datetime);
  return $obsid;
}

=item B<to_UTDATE>

Translates the C<DATE_OBS> or C<LONGDATEOBS> header into a
YYYYMMDD integer.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $date = _sybase_convert_date( _date_header( $FITS_headers ), 1);
  return $date->strftime('%Y%m%d');
}

=item B<to_UTSTART>

Translates the DB date header into a C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  return _sybase_convert_date( _date_header( $FITS_headers ));
}

=item B<to_UTEND>

Translates the database date header into a C<Time::Piece> object and adds 
on the exposure time.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;

  my $return = _sybase_convert_date( _date_header( $FITS_headers ) );
  return undef unless defined $return;
  my $expt = $self->to_EXPOSURE_TIME( $FITS_headers );

  $return += $expt;
  return $return;
}

=item B<to_BANDWIDTH_MODE>

Uses the NORSECT (number of backend sections), NOFCHAN (number of
frontend output channels) and NOBCHAN (number of channels) to form a
string that is of the format 250MHzx2048. To obtain this, the
bandwidth (250MHz in this example) is calculated as 125MHz * NORSECT /
NOFCHAN. The number of channels is taken directly and not manipulated
in any way.

If appropriate, the bandwidth may be given in GHz.

=cut

sub to_BANDWIDTH_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;

  if ( exists( $FITS_headers->{'NORSECT'} ) && defined( $FITS_headers->{'NORSECT'} ) &&
       exists( $FITS_headers->{'NOFCHAN'} ) && defined( $FITS_headers->{'NOFCHAN'} ) &&
       exists( $FITS_headers->{'NOBCHAN'} ) && defined( $FITS_headers->{'NOBCHAN'} ) ) {

    my $bandwidth = 125 * $FITS_headers->{'NORSECT'} / $FITS_headers->{'NOFCHAN'};

    if ( $bandwidth >= 1000 ) {
      $bandwidth /= 1000;
      $return = sprintf( "%dGHzx%d", $bandwidth, $FITS_headers->{'NOBCHAN'} );
    } else {
      $return = sprintf( "%dMHzx%d", $bandwidth, $FITS_headers->{'NOBCHAN'} );
    }
  }

  return $return;

}


=item B<to_EXPOSURE_TIME>

=cut

sub to_EXPOSURE_TIME {
  my $self = shift;
  my $FITS_headers = shift;
  my $expt = 0;

  if ( exists( $FITS_headers->{'OBSMODE'} ) && defined( $FITS_headers->{'OBSMODE'} ) ) {

    my $obsmode = uc( $FITS_headers->{'OBSMODE'} );

    if ( $obsmode eq 'RASTER' ) {

      if ( exists( $FITS_headers->{'NSCAN'} ) && defined( $FITS_headers->{'NSCAN'} ) &&
           exists( $FITS_headers->{'CYCLLEN'} ) && defined( $FITS_headers->{'CYCLLEN'} ) &&
           exists( $FITS_headers->{'NOCYCPTS'} ) && defined( $FITS_headers->{'NOCYCPTS'} ) ) {

        my $nscan = $FITS_headers->{'NSCAN'};
        my $cycllen = $FITS_headers->{'CYCLLEN'};
        my $nocycpts = $FITS_headers->{'NOCYCPTS'};

        # raster.
        $expt = 15 + $nscan * $cycllen * ( 1 + 1 / sqrt( $nocycpts ) ) * 1.4;
      }
    } elsif ( $obsmode eq 'PATTERN' or $obsmode eq 'GRID' ) {

      my $swmode = '';

      if ( exists( $FITS_headers->{'SWMODE'} ) && defined( $FITS_headers->{'SWMODE'} ) ) {
        $swmode = $FITS_headers->{'SWMODE'};
      } else {
        $swmode = 'BEAMSWITCH';
      }

      if ( exists( $FITS_headers->{'NSCAN'} ) && defined( $FITS_headers->{'NSCAN'} ) &&
           exists( $FITS_headers->{'NCYCLE'} ) && defined( $FITS_headers->{'NCYCLE'} ) &&
           exists( $FITS_headers->{'CYCLLEN'} ) && defined( $FITS_headers->{'CYCLLEN'} ) ) {

        my $nscan = $FITS_headers->{'NSCAN'};
        my $ncycle = $FITS_headers->{'NCYCLE'};
        my $cycllen = $FITS_headers->{'CYCLLEN'};

        if ( $swmode eq 'POSITION_SWITCH' ) {

          # position switch pattern/grid.
          $expt = 6 + $nscan * $ncycle * $cycllen * 1.35;

        } elsif ( $swmode eq 'BEAMSWITCH' ) {

          # beam switch pattern/grid.
          $expt = 6 + $nscan * $ncycle * $cycllen * 1.35;

        } elsif ( $swmode eq 'CHOPPING' ) {
          if ( exists( $FITS_headers->{'FRONTEND'} ) && defined( $FITS_headers->{'FRONTEND'} ) ) {
            my $frontend = uc( $FITS_headers->{'FRONTEND'} );
            if ( $frontend eq 'RXA3I' ) {

              # fast frequency switch pattern/grid, receiver A.
              $expt = 15 + $nscan * $ncycle * $cycllen * 1.20;

            } elsif ( $frontend eq 'RXB' ) {

              # slow frequency switch pattern/grid, receiver B.
              $expt = 18 + $nscan * $ncycle * $cycllen * 1.60;

            }
          }
        }
      }
    } else {

      my $swmode;
      if ( exists( $FITS_headers->{'SWMODE'} ) && defined( $FITS_headers->{'SWMODE'} ) ) {
        $swmode = uc( $FITS_headers->{'SWMODE'} );
      } else {
        $swmode = 'BEAMSWITCH';
      }

      if ( exists( $FITS_headers->{'NSCAN'} ) && defined( $FITS_headers->{'NSCAN'} ) &&
           exists( $FITS_headers->{'NCYCLE'} ) && defined( $FITS_headers->{'NCYCLE'} ) &&
           exists( $FITS_headers->{'CYCLLEN'} ) && defined( $FITS_headers->{'CYCLLEN'} ) ) {

        my $nscan = $FITS_headers->{'NSCAN'};
        my $ncycle = $FITS_headers->{'NCYCLE'};
        my $cycllen = $FITS_headers->{'CYCLLEN'};

        if ( $swmode eq 'POSITION_SWITCH' ) {

          # position switch sample.
          $expt = 4.8 + $nscan * $ncycle * $cycllen * 1.10;

        } elsif ( $swmode eq 'BEAMSWITCH' ) {

          # beam switch sample.
          $expt = 4.8 + $nscan * $ncycle * $cycllen * 1.25;

        } elsif ( $swmode eq 'CHOPPING' ) {
          if ( exists( $FITS_headers->{'FRONTEND'} ) && defined( $FITS_headers->{'FRONTEND'} ) ) {
            my $frontend = uc( $FITS_headers->{'FRONTEND'} );
            if ( $frontend eq 'RXA3I' ) {

              # fast frequency switch sample, receiver A.
              $expt = 3 + $nscan * $ncycle * $cycllen * 1.10;

            } elsif ( $frontend eq 'RXB' ) {

              # slow frequency switch sample, receiver B.
              $expt = 3 + $nscan * $ncycle * $cycllen * 1.40;
            }
          }
        }
      }
    }
  }

  return $expt;
}

=item B<to_SYSTEM_VELOCITY>

Translate the C<VREF> and C<C12VDEF> headers into one combined header.

=cut

sub to_SYSTEM_VELOCITY {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{'VREF'} ) && defined( $FITS_headers->{'VREF'} ) &&
       exists( $FITS_headers->{'VDEF'} ) && defined( $FITS_headers->{'VDEF'} ) ) {
    $return = uc( substr( $FITS_headers->{'VDEF'}, 0, 3 ) . substr( $FITS_headers->{'VREF'}, 0, 3 ) );
  }
  return $return;
}

=back

=begin __PRIVATE

=over 4

=item B<_date_header>

Works out which header corresponds to the date field in sybase format and returns the value.

  $value = _date_header( $FITS_headers );

Returns undef if none found.

=cut

sub _date_header {
  my $FITS_headers = shift;
  for my $key (qw/ LONGDATEOBS DATE_OBS LONGDATE/ ) {
    if (exists $FITS_headers->{$key} && defined $FITS_headers->{$key}) {
      return $FITS_headers->{$key};
    }
  }
  return;
}

=item B<_sybase_convert_date>

Converts a sybase long date to Time::Piece object.

  $date = _sybase_convert_date( $string );

Optional flag can be set to true to drop Hours, minutes and seconds from parse.

  $utday = _sybase_convert_date( $string, 1);

Returns undef if no string is supplied.

=cut

sub _sybase_convert_date {
  my $longdate = shift;
  my $drophms = shift;
  return undef unless $longdate;

  # The UT header is in Sybase format, which is something like
  # "Mar 15 2002  7:04:35:234AM   ". We first need to remove the number
  # of milliseconds, then the whitespace at the end, then use the
  # "%b%t%d%t%Y%t%I:%M:%S%p" format.

  # General cleanup
  $longdate =~ s/:\d\d\d//;
  $longdate =~ s/\s*$//;

  my $return;
  if ($drophms) {
    $longdate =~ s/\s*\d\d?:\d\d:\d\d[A|P]M$//;
    $return = Time::Piece->strptime( $longdate,
                                     "%b %e %Y" );
  } else {
    $return = Time::Piece->strptime( $longdate,
                                     "%b %e %Y %l:%M:%S%p" );
  }
  return $return;
}

=back

=end __PRIVATE

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2008 Science and Technology Facilities Council.
Copyright (C) 2003-2007 Particle Physics and Astronomy Research Council.
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
