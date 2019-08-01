package Astro::FITS::HdrTrans::JAC;

=head1 NAME

Astro::FITS::HdrTrans::JAC - Base class for translation of Joint
Astronomy Centre instruments.

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::JAC;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
instrumentation from the Joint Astronomy Centre. It should not be used
directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use DateTime;
use DateTime::TimeZone;
# Cache UTC definition
our $UTC = DateTime::TimeZone->new( name => 'UTC' );

# Inherit from the Base translation class and not HdrTrans itself
# (which is just a class-less wrapper).

use base qw/ Astro::FITS::HdrTrans::FITS /;

use vars qw/ $VERSION /;

$VERSION = "1.62";

# in each class we have three sets of data.
#   - constant mappings
#   - unit mappings
#   - complex mappings

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (
                );

# Unit mapping implies that the value propagates directly
# to the output with only a keyword name change.

my %UNIT_MAP = (
                MSBID              => 'MSBID',
                MSB_TRANSACTION_ID => 'MSBTID',
                SHIFT_TYPE         => "OPER_SFT",
               );

# Create the translation methods.
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 METHODS

=over 4

=item B<translate_from_FITS>

This routine overrides the base class implementation to enable the
caches to be cleared and for the location of the DATE-OBS/DATE-END field to
be found so that base class implementations will work correctly.

This means that some conversion methods (in particular those using time in
a base class) may not work properly outside the context of a full translation
unless they have been subclassed locally.

=cut

sub translate_from_FITS {
  my $class = shift;
  my $headers = shift;

  # sort out DATE-OBS and DATE-END
  $class->_fix_dates( $headers );

  # Go to the base class
  return $class->SUPER::translate_from_FITS( $headers, @_ );
}

=back

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping.  We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping).  The from_ methods take
a reference to a generic hash and return a translated hash (sometimes
these are many-to-many).

=over 4

=item B<to_OBSERVATION_ID>

Converts the C<OBSID> header directly into the C<OBSERVATION_ID>
generic header, or if that header does not exist, converts the
C<INSTRUME>, C<RUNNR>, and C<DATE-OBS> headers into C<OBSERVATION_ID>.

The form of the observation ID string is documented in
JSA/ANA/001 (http://docs.jach.hawaii.edu/JCMT/JSA/ANA/001/jsa_ana_001.pdf).

=cut

sub to_OBSERVATION_ID {
  my $self = shift;
  my $FITS_headers = shift;

  my $return;
  if ( exists( $FITS_headers->{'OBSID'} ) &&
       defined( $FITS_headers->{'OBSID'} ) ) {
    $return = $FITS_headers->{'OBSID'};
  } else {

    my $instrume = lc( $self->to_INSTRUMENT( $FITS_headers ) );
    my $obsnum = $self->to_OBSERVATION_NUMBER( $FITS_headers );
    my $dateobs = $self->to_UTSTART( $FITS_headers );

    my $datetime;
    if ( defined $dateobs && defined $obsnum ) {
      $datetime = $dateobs->datetime;
      $datetime =~ s/-//g;
      $datetime =~ s/://g;

      $return = join '_', $instrume, $obsnum, $datetime;
    }
  }

  return $return;

}

=item B<_fix_dates>

Sort out DATE-OBS and DATE-END in cases where they are not available directly.
This is mainly an issue with database retrievals where the date format is not
FITS compliant.

  Astro::FITS::HdrTrans::JAC->_fix_dates( \%headers );

=cut

sub _fix_dates {
  my ( $class, $FITS_headers ) = @_;

  # DATE-OBS can be from DATE_OBS
  # For compatability with Sybase database, also accept LONGDATEOBS LONGDATE
  __PACKAGE__->_try_dates( $FITS_headers, 'DATE-OBS', qw/ DATE_OBS LONGDATEOBS LONGDATE / );

  # DATE-END can be from DATE_END
  # For compatability with Sybase database, also accept LONGDATEEND
  __PACKAGE__->_try_dates( $FITS_headers, 'DATE-END', qw/ DATE_END LONGDATEEND / );

  return;
}

# helper routine for _fix_dates
sub _try_dates {
  my ( $class, $FITS_headers, $outkey, @tests ) = @_;

  if (!exists $FITS_headers->{$outkey}) {
    for my $key (@tests) {
      if ( exists( $FITS_headers->{$key} ) ) {
        my $date = _convert_mysql_date( $FITS_headers->{$key} );
        if( defined( $date ) ) {
          $FITS_headers->{$outkey} = $date->datetime;
          last;
        }
      }
    }
  }
  return;
}

# Convert MySQL date string to DateTime object.
# For compatability, also accepts Sybase date strings.
sub _convert_mysql_date {
  my $date = shift;

  $date =~ s/\s*$//;

  if ($date =~ /\s*(\d\d\d\d)-(\d\d)-(\d\d)\s+(\d{1,2}):(\d\d):(\d\d)/) {

    my $return = DateTime->new( year => $1,
                                month => $2,
                                day => $3,
                                hour => $4,
                                minute => $5,
                                second => $6,
                                time_zone => $UTC,
                              );
    return $return;

  } elsif ($date =~ /\s*(\w+)\s+(\d{1,2})\s+(\d{4})\s+(\d{1,2}):(\d\d):(\d\d)(?::\d\d\d)?(AM|PM)/) {

    my $hour = $4;
    if (uc($7) eq 'AM' && $hour == 12) {
      $hour = 0;
    } elsif ( uc($7) eq 'PM' && $hour < 12 ) {
      $hour += 12;
    }

    my %mon_lookup = ( 'Jan' => 1,
                       'Feb' => 2,
                       'Mar' => 3,
                       'Apr' => 4,
                       'May' => 5,
                       'Jun' => 6,
                       'Jul' => 7,
                       'Aug' => 8,
                       'Sep' => 9,
                       'Oct' => 10,
                       'Nov' => 11,
                       'Dec' => 12 );
    my $month = $mon_lookup{$1};

    my $return = DateTime->new( year => $3,
                                month => $month,
                                day => $2,
                                hour => $hour,
                                minute => $5,
                                second => $6,
                                time_zone => $UTC,
                              );
    return $return;

  } else {
    return undef;
  }
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2007 Science and Technology Facilities Council.
Copyright (C) 2006 Particle Physics and Astronomy Research Council.
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
