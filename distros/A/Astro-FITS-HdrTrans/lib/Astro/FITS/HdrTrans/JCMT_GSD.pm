package Astro::FITS::HdrTrans::JCMT_GSD;

=head1 NAME

Astro::FITS::HdrTrans::JCMT_GSD - JCMT GSD Header translations

=head1 DESCRIPTION

Converts information contained in JCMT heterodyne instrument headers
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

$VERSION = "1.63";

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
                AMBIENT_TEMPERATURE => "C5AT",
                APERTURE => "C7AP",
                AZIMUTH_START => "C4AZ",
                BACKEND => "C1BKE",
                BACKEND_SECTIONS => "C3NRS",
                CHOP_FREQUENCY => "C4FRQ",
                CHOP_THROW => "C4THROW",
                COORDINATE_SYSTEM => "C4CSC",
                COORDINATE_TYPE => "C4LSC",
                CYCLE_LENGTH => "C3CL",
                #        DEC_BASE => "",
                ELEVATION_START => "C4EL",
                #        FILENAME => "GSDFILE",
                FILTER => "C7FIL",
                FREQUENCY_RESOLUTION => "C12FR",
                FRONTEND => "C1RCV",
                HUMIDITY => "C5RH",
                NUMBER_OF_CYCLES => "C3NCI",
                NUMBER_OF_SUBSCANS => "C3NIS",
                OBJECT => "C1SNA1",
                OBSERVATION_MODE => "C6ST",
                OBSERVATION_NUMBER => "C1SNO",
                PROJECT => "C1PID",
                RA_BASE => "C4RADATE",
                RECEIVER_TEMPERATURE => "C12RT",
                ROTATION => "CELL_V2Y",
                REST_FREQUENCY => "C12RF",
                SEEING => "C7SEEING",
                SWITCH_MODE => "C6MODE",
                SYSTEM_TEMPERATURE => "C12SST",
                TAU => "C7TAU225",
                USER_AZ_CORRECTION => "UAZ",
                USER_EL_CORRECTION => "UEL",
                VELOCITY => "C7VR",
                VELOCITY_REFERENCE_FRAME => "C12VREF",
                VELOCITY_TYPE => "C12VDEF",
                X_BASE => "C4RX",
                Y_BASE => "C4RY",
                X_DIM => "C6XNP",
                Y_DIM => "C6YNP",
                X_REQUESTED => "C4SX",
                Y_REQUESTED => "C4SY",
                X_SCALE => "C6DX",
                Y_SCALE => "C6DY",
               );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

For this class, the method will return true if the B<C1RCV> header exists
and matches the regular expression C</^rx(a|b|w)/i>.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if ( exists( $headers->{'C1RCV'} ) &&
       defined( $headers->{'C1RCV'} ) &&
       ( $headers->{'C1RCV'} =~ /^rx(a|b|w)/i ||
         $headers->{'C1RCV'} =~ /^fts/i ) ) {
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

=item B<to_INSTRUMENT>

Sets the C<INSTRUMENT> generic header. For RxA3i, sets the value
to RXA3. For RxB, sets the value to RXB3.

=cut

sub to_INSTRUMENT {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'C1RCV'} ) ) {
    $return = $FITS_headers->{'C1RCV'};
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

Translates the C<C3DAT> header into a YYYYMMDD integer.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;

  if ( exists( $FITS_headers->{'C3DAT'} ) ) {
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    my $ut = "$1-$2-$day";
    $return = sprintf("%04d%02d%02d", $1, $2, $3);
  }
  return $return;
}

=item B<from_UTDATE>

Translates YYYYMMDD integer to C3DAT header.

=cut

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if (exists $generic_headers->{UTDATE}) {
    my $date = $generic_headers->{UTDATE};
    return () unless defined $date;
    $return_hash{UTDATE} = sprintf("%04d.%02d%02d",
                                   substr($date,0,4),
                                   substr($date,4,2),
                                   substr($date,6,2));
  }
  return %return_hash;
}

=item B<to_UTSTART>

Translates the C<C3DAT> and C<C3UT> headers into a C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if ( exists( $FITS_headers->{'C3DAT'} ) && defined( $FITS_headers->{'C3DAT'} ) &&
       exists( $FITS_headers->{'C3UT'} ) && defined( $FITS_headers->{'C3UT'} ) ) {
    my $hour = int( $FITS_headers->{'C3UT'} );
    my $minute = int ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 );
    my $second = int ( ( ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 ) - $minute ) * 60 );
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    $return = Time::Piece->strptime(sprintf("%4u-%02u-%02uT%02u:%02u:%02u", $1, $2, $day, $hour, $minute, $second ),
                                    "%Y-%m-%dT%T");
  }
  return $return;
}

=item B<to_UTEND>

Translates the C<C3DAT>, C<C3UT>, C<C3NIS>, C<C3CL>, C<C3NCP>, and C<C3NCI> headers
into a C<Time::Piece> object.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my ($t, $expt);
  if ( exists( $FITS_headers->{'C3DAT'} ) && defined( $FITS_headers->{'C3DAT'} ) &&
       exists( $FITS_headers->{'C3UT'} ) && defined( $FITS_headers->{'C3UT'} ) ) {
    my $hour = int( $FITS_headers->{'C3UT'} );
    my $minute = int ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 );
    my $second = int ( ( ( ( $FITS_headers->{'C3UT'} - $hour ) * 60 ) - $minute ) * 60 );
    $FITS_headers->{'C3DAT'} =~ /(\d{4})\.(\d\d)(\d{1,2})/;
    my $day = (length($3) == 2) ? $3 : $3 . "0";
    $t = Time::Piece->strptime(sprintf("%4u-%02u-%02uT%02u:%02u:%02u", $1, $2, $day, $hour, $minute, $second ),
                               "%Y-%m-%dT%T");
  }

  $expt = $self->to_EXPOSURE_TIME( $FITS_headers );

  $t += $expt;

  return $t;

}

=item B<to_BANDWIDTH_MODE>

Uses the C3NRS (number of backend sections), C3NFOC (number of
frontend output channels) and C3NCH (number of channels) to form a
string that is of the format 250MHzx2048. To obtain this, the
bandwidth (250MHz in this example) is calculated as 125MHz * C3NRS /
C3NFOC. The number of channels is taken directly and not manipulated
in any way.

If appropriate, the bandwidth may be given in GHz.

=cut

sub to_BANDWIDTH_MODE {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;

  if ( exists( $FITS_headers->{'C3NRS'} ) && defined( $FITS_headers->{'C3NRS'} ) &&
       exists( $FITS_headers->{'C3NFOC'} ) && defined( $FITS_headers->{'C3NFOC'} ) &&
       exists( $FITS_headers->{'C3NCH'} ) && defined( $FITS_headers->{'C3NCH'} ) ) {

    my $bandwidth = 125 * $FITS_headers->{'C3NRS'} / $FITS_headers->{'C3NFOC'};

    if ( $bandwidth >= 1000 ) {
      $bandwidth /= 1000;
      $return = sprintf( "%dGHzx%d", $bandwidth, $FITS_headers->{'C3NCH'} );
    } else {
      $return = sprintf( "%dMHzx%d", $bandwidth, $FITS_headers->{'C3NCH'} );
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

  if ( exists( $FITS_headers->{'C6ST'} ) && defined( $FITS_headers->{'C6ST'} ) ) {

    my $c6st = uc( $FITS_headers->{'C6ST'} );

    if ( $c6st eq 'RASTER' ) {

      if ( exists( $FITS_headers->{'C3NSAMPL'} ) && defined( $FITS_headers->{'C3NSAMPL'} ) &&
           exists( $FITS_headers->{'C3CL'} ) && defined( $FITS_headers->{'C3CL'} ) &&
           exists( $FITS_headers->{'C3NPP'} ) && defined( $FITS_headers->{'C3NPP'} ) ) {

        my $c3nsampl = $FITS_headers->{'C3NSAMPL'};
        my $c3cl = $FITS_headers->{'C3CL'};
        my $c3npp = $FITS_headers->{'C3NPP'};

        # raster.
        $expt = 15 + $c3nsampl * $c3cl * ( 1 + 1 / sqrt( $c3npp ) ) * 1.4;
      }
    } elsif ( $c6st eq 'PATTERN' or $c6st eq 'GRID' ) {

      my $c6mode = '';

      if ( exists( $FITS_headers->{'C6MODE'} ) && defined( $FITS_headers->{'C6MODE'} ) ) {
        $c6mode = $FITS_headers->{'C6MODE'};
      } else {
        $c6mode = 'BEAMSWITCH';
      }

      if ( exists( $FITS_headers->{'C3NSAMPL'} ) && defined( $FITS_headers->{'C3NSAMPL'} ) &&
           exists( $FITS_headers->{'C3NCYCLE'} ) && defined( $FITS_headers->{'C3NCYCLE'} ) &&
           exists( $FITS_headers->{'C3CL'} ) && defined( $FITS_headers->{'C3CL'} ) ) {

        my $c3nsampl = $FITS_headers->{'C3NSAMPL'};
        my $c3ncycle = $FITS_headers->{'C3NCYCLE'};
        my $c3cl = $FITS_headers->{'C3CL'};

        if ( $c6mode eq 'POSITION_SWITCH' ) {

          # position switch pattern/grid.
          $expt = 6 + $c3nsampl * $c3ncycle * $c3cl * 1.35;

        } elsif ( $c6mode eq 'BEAMSWITCH' ) {

          # beam switch pattern/grid.
          $expt = 6 + $c3nsampl * $c3ncycle * $c3cl * 1.35;

        } elsif ( $c6mode eq 'CHOPPING' ) {
          if ( exists( $FITS_headers->{'C1RCV'} ) && defined( $FITS_headers->{'C1RCV'} ) ) {
            my $c1rcv = uc( $FITS_headers->{'C1RCV'} );
            if ( $c1rcv eq 'RXA3I' ) {

              # fast frequency switch pattern/grid, receiver A.
              $expt = 15 + $c3nsampl * $c3ncycle * $c3cl * 1.20;

            } elsif ( $c1rcv eq 'RXB' ) {

              # slow frequency switch pattern/grid, receiver B.
              $expt = 18 + $c3nsampl * $c3ncycle * $c3cl * 1.60;

            }
          }
        }
      }
    } else {

      my $c6mode;
      if ( exists( $FITS_headers->{'C6MODE'} ) && defined( $FITS_headers->{'C6MODE'} ) ) {
        $c6mode = $FITS_headers->{'C6MODE'};
      } else {
        $c6mode = 'BEAMSWITCH';
      }

      if ( exists( $FITS_headers->{'C3NSAMPL'} ) && defined( $FITS_headers->{'C3NSAMPL'} ) &&
           exists( $FITS_headers->{'C3NCYCLE'} ) && defined( $FITS_headers->{'C3NCYCLE'} ) &&
           exists( $FITS_headers->{'C3CL'} ) && defined( $FITS_headers->{'C3CL'} ) ) {

        my $c3nsampl = $FITS_headers->{'C3NSAMPL'};
        my $c3ncycle = $FITS_headers->{'C3NCYCLE'};
        my $c3cl = $FITS_headers->{'C3CL'};

        if ( $c6mode eq 'POSITION_SWITCH' ) {

          # position switch sample.
          $expt = 4.8 + $c3nsampl * $c3ncycle * $c3cl * 1.10;

        } elsif ( $c6mode eq 'BEAMSWITCH' ) {

          # beam switch sample.
          $expt = 4.8 + $c3nsampl * $c3ncycle * $c3cl * 1.25;

        } elsif ( $c6mode eq 'CHOPPING' ) {
          if ( exists( $FITS_headers->{'C1RCV'} ) && defined( $FITS_headers->{'C1RCV'} ) ) {
            my $c1rcv = uc( $FITS_headers->{'C1RCV'} );
            if ( $c1rcv eq 'RXA3I' ) {

              # fast frequency switch sample, receiver A.
              $expt = 3 + $c3nsampl * $c3ncycle * $c3cl * 1.10;

            } elsif ( $c1rcv eq 'RXB' ) {

              # slow frequency switch sample, receiver B.
              $expt = 3 + $c3nsampl * $c3ncycle * $c3cl * 1.40;
            }
          }
        }
      }
    }
  }

  return $expt;
}

=item B<to_SYSTEM_VELOCITY>

Translate the C<C12VREF> and C<C12VDEF> headers into one combined header.

=cut

sub to_SYSTEM_VELOCITY {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{'C12VREF'} ) && defined( $FITS_headers->{'C12VREF'} ) &&
       exists( $FITS_headers->{'C12VDEF'} ) && defined( $FITS_headers->{'C12VDEF'} ) ) {
    $return = substr( $FITS_headers->{'C12VDEF'}, 0, 3 ) . substr( $FITS_headers->{'C12VREF'}, 0, 3 );
  }
  return $return;
}

=back

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
