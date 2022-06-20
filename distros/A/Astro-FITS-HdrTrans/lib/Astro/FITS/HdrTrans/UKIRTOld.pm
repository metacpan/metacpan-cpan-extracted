package Astro::FITS::HdrTrans::UKIRTOld;

=head1 NAME

Astro::FITS::HdrTrans::UKIRTOld - Base class for translation of old UKIRT instruments

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UKIRTOld;

=head1 DESCRIPTION

This class provides a generic set of translations that are common to
CGS4 and IRCAM from the United Kingdom Infrared Telescope. It should
not be used directly for translation of instrument FITS headers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRT
use base qw/ Astro::FITS::HdrTrans::UKIRT /;

use vars qw/ $VERSION /;

$VERSION = "1.65";

# For a constant mapping, there is no FITS header, just a generic
# header that is constant.
my %CONST_MAP = (

                );

# Unit mapping implies that the value propogates directly
# to the output with only a keyword name change.
my %UNIT_MAP = (
                DETECTOR_READ_TYPE   => "MODE", # Also UFTI
                DR_RECIPE            => "DRRECIPE",
                EXPOSURE_TIME        => "DEXPTIME",
                GAIN                 => "DEPERDN",
               );

# Create the translation methods.
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping.  We have to
provide both from- and to-FITS conversions.  All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping).  The from_ methods take
a reference to a generic hash and return a translated hash (sometimes
these are many-to-many).

=over 4

=item B<to_UTDATE>

Converts IDATE into UTDATE without any modification.  Flattens
duplicate headers into a single header.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  my $utdate = ( exists $FITS_headers->{IDATE} ? $FITS_headers->{IDATE} : undef );
  if ( defined( $utdate ) && ref( $utdate ) eq 'ARRAY' ) {
    $return = $utdate->[0];
  } else {
    $return = $utdate;
  }
  return $return;
}

=item B<from_UTDATE>

Converts UTDATE into IDATE without any modification.

=cut

sub from_UTDATE {
  return ( "IDATE", $_[1]->{'UTDATE'} );
}

=item B<to_UTSTART>

Converts FITS header UT date/time values for the start of the observation
into a C<Time::Piece> object.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;

  my $utdate = $self->to_UTDATE( $FITS_headers );
  my @rutstart = sort {$a<=>$b} $self->via_subheader( $FITS_headers, "RUTSTART" );
  my $utdechour = $rutstart[0];

  # We do not have a DATE-OBS.
  return $self->_parse_date_info( undef, $utdate, $utdechour );
}

=item B<from_UTSTART>

Converts a C<Time::Piece> object into two FITS headers for IRCAM: IDATE
(in the format YYYYMMDD) and RUTSTART (decimal hours).

=cut

sub from_UTSTART {
  my $class = shift;
  my $generic_headers = shift;
  my %return_hash;
  if ( exists($generic_headers->{UTSTART} ) ) {
    my $date = $generic_headers->{UTSTART};
    if ( ! UNIVERSAL::isa( $date, "Time::Piece" ) ) {
      return;
    }
    $return_hash{IDATE} = sprintf( "%4d%02d%02d", $date->year, $date->mon, $date->mday );
    $return_hash{RUTSTART} = $date->hour + ( $date->minute / 60 ) + ( $date->second / 3600 );
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts FITS header UT date/time values for the end of the observation into
a C<Time::Piece> object.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  my $utdate = $self->to_UTDATE( $FITS_headers );
  my @rutend = sort {$a<=>$b} $self->via_subheader( $FITS_headers, "RUTEND" );
  my $utdechour = $rutend[-1];

  # We do not have a DATE-END.
  return $self->_parse_date_info( undef, $utdate, $utdechour );
}

=item B<from_UTEND>

Converts a C<Time::Piece> object into two FITS headers for IRCAM: IDATE
(in the format YYYYMMDD) and RUTEND (decimal hours).

=cut

sub from_UTEND {
  my $class = shift;
  my $generic_headers = shift;
  my %return_hash;
  if ( exists($generic_headers->{UTEND} ) ) {
    my $date = $generic_headers->{UTEND};
    if ( ! UNIVERSAL::isa( $date, "Time::Piece" ) ) {
      return;
    }
    $return_hash{IDATE} = sprintf( "%4d%02d%02d", $date->year, $date->mon, $date->mday );
    $return_hash{RUTEND} = $date->hour + ( $date->minute / 60 ) + ( $date->second / 3600 );
  }
  return %return_hash;
}

=item B<to_INST_DHS>

Sets the instrument data handling system header. Note that for old
instruments there is no DHSVER header so this simply returns
the name of the instrument and a UKDHS suffix.

=cut

sub to_INST_DHS {
  my $self = shift;
  my $FITS_headers = shift;
  my $inst = $self->to_INSTRUMENT( $FITS_headers );
  return $inst . '_UKDHS';
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::UKIRT>

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=head1 COPYRIGHT

Copyright (C) 2007-2008 Science and Technology Facilities Council.
Copyright (C) 2003-2007 Particle Physics and Astronomy Research Council.
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
