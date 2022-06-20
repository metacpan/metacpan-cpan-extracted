package Astro::FITS::HdrTrans::FITS;

=head1 NAME

Astro::FITS::HdrTrans::FITS - Standard FITS header translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::FITS;

  %gen = Astro::FITS::HdrTrans::FITS->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific
to the (few) headers that are commonly standardised across most
FITS files.

Mainly deals with World Coordinate Systems and headers defined
in the FITS standards papers.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use base qw/ Astro::FITS::HdrTrans::Base /;

use vars qw/ $VERSION /;

$VERSION = "1.65";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                );

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                DATA_UNITS           => 'BUNIT',
                DEC_SCALE            => "CDELT2",
                INSTRUMENT           => 'INSTRUME',
                RA_SCALE             => "CDELT1",
                TELESCOPE            => 'TELESCOP',
                X_BASE               => "CRPIX1",
                X_REFERENCE_PIXEL    => "CRPIX1",
                Y_BASE               => "CRPIX2",
                Y_REFERENCE_PIXEL    => "CRPIX2",
               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping. We have to
provide both from- and to-FITS conversions All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping) The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many).

=over 4


=item B<to_ROTATION>

This determines the angle, in decimal degrees, of the declination or
latitude axis with respect to the second axis of the data array, measured
in the anticlockwise direction.

It first looks for the linear-transformation CD matrix, widely used
including by IRAF and the precursor to the PC matrix.  If this is
absent, the routine attempts to find the standard transformation
matrix PC defined in the FITS WCS Standard.  Either matrix is
converted into a single rotation angle.

In the absence of a PC matrix it looks for the CROTA2 keyword from the
AIPS convention.

The evaluation from the CD matrix is based upon Micah Johnson's
cdelrot.pl script supplied for use with XIMAGE, extended to average
the two estimates using FITS-WCS Paper II Section 6.2 prescription.

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $rotation;
  my $rtod = 45 / atan2( 1, 1 );

  # Try the IRAF-style headers.  Use the defaults prescribed in WCS Paper I,
  # Section 2.1.2.
  if ( defined( $FITS_headers->{CD1_1} ) || defined( $FITS_headers->{CD1_2} ) ||
       defined( $FITS_headers->{CD2_1} ) || defined( $FITS_headers->{CD2_2} ) ) {
    my $cd11 = defined( $FITS_headers->{CD1_1} ) ? $FITS_headers->{CD1_1} : 0.0;
    my $cd21 = defined( $FITS_headers->{CD2_1} ) ? $FITS_headers->{CD2_1} : 0.0;
    my $cd12 = defined( $FITS_headers->{CD1_2} ) ? $FITS_headers->{CD1_2} : 0.0;
    my $cd22 = defined( $FITS_headers->{CD2_2} ) ? $FITS_headers->{CD2_2} : 0.0;

    # Determine the sense of the scales.
    my $sgn1;
    if ( $cd12 < 0 ) {
      $sgn1 = -1;
    } else {
      $sgn1 = 1;
    }

    my $sgn2;
    if ( $cd21 < 0 ) {
      $sgn2 = -1;
    } else {
      $sgn2 = 1;
    }

    # Average the estimates of the rotation converting from radians to
    # degrees (rtod).
    $rotation = $rtod * 0.5 * ( atan2( $sgn1 * $cd21 / $rtod,  $sgn1 * $cd11 / $rtod ) +
                                atan2( $sgn2 * $cd12 / $rtod, -$sgn2 * $cd22 / $rtod ) );

    # Now try the FITS WCS PC matrix.    Use the defaults prescribed in WCS Paper I,
    # Section 2.1.2.
  } elsif ( defined( $FITS_headers->{PC1_1} ) || defined( $FITS_headers->{PC1_2} ) ||
            defined( $FITS_headers->{PC2_1} ) || defined( $FITS_headers->{PC2_2} ) ) {
    my $pc11 = defined( $FITS_headers->{PC1_1} ) ? $FITS_headers->{PC1_1} : 1.0;
    my $pc21 = defined( $FITS_headers->{PC2_1} ) ? $FITS_headers->{PC2_1} : 0.0;
    my $pc12 = defined( $FITS_headers->{PC1_2} ) ? $FITS_headers->{PC1_2} : 0.0;
    my $pc22 = defined( $FITS_headers->{PC2_2} ) ? $FITS_headers->{PC2_2} : 1.0;

    # Average the estimates of the rotation converting from radians to
    # degrees (rtod) as the matrix may not represent a pure rotation.
    $rotation = $rtod * 0.5 * ( atan2( -$pc21 / $rtod, $pc11 / $rtod ) +
                                atan2(  $pc12 / $rtod, $pc22 / $rtod ) );

  } elsif ( defined( $FITS_headers->{CROTA2} ) ) {
    $rotation = $FITS_headers->{CROTA2};

  }
  return $rotation;
}


=item B<to_UTDATE>

Converts the DATE-OBS keyword into a number of form YYYYMMDD.

There is no corresponding C<from_UTDATE> method since there is
no corresponding FITS keyword.

=cut

sub to_UTDATE {
  my $class = shift;
  my $FITS_headers = shift;
  my $utstart = $class->to_UTSTART( $FITS_headers );
  if (defined $utstart) {
    return $utstart->strftime( '%Y%m%d' );
  }
  return;
}


=item B<to_UTEND>

Converts UT date in C<DATE-END> header into C<Time::Piece> object.

=cut

sub to_UTEND {
  my $class = shift;
  my $FITS_headers = shift;
  my $utend;
  if ( exists( $FITS_headers->{'DATE-END'} ) ) {
    $utend = $FITS_headers->{'DATE-END'};
  } else {
    # try subheaders
    my @end = $class->via_subheader( $FITS_headers, "DATE-END" );
    $utend = $end[-1];
  }
  my $return;
  $return = $class->_parse_iso_date( $utend ) if defined $utend;
  return $return;
}

=item B<from_UTEND>

Returns the ending observation time in FITS restricted ISO8601 format:
YYYY-MM-DDThh:mm:ss.

=cut

sub from_UTEND {
  my $class = shift;
  my $generic_headers = shift;
  my %return_hash;
  if ( exists( $generic_headers->{UTEND} ) ) {
    my $date = $generic_headers->{UTEND};
    $return_hash{'DATE-END'} = $date->datetime;
  }
  return %return_hash;
}


=item B<to_UTSTART>

Converts UT date in C<DATE-OBS> header into date object.

=cut

sub to_UTSTART {
  my $class = shift;
  my $FITS_headers = shift;

  my $utstart;
  if ( exists( $FITS_headers->{'DATE-OBS'} ) ) {
    $utstart = $FITS_headers->{"DATE-OBS"};
  } else {
    # try subheaders
    $utstart = $class->via_subheader( $FITS_headers, "DATE-OBS" );
  }
  my $return;
  $return = $class->_parse_iso_date( $utstart ) if defined $utstart;
  return $return;
}

=item B<from_UTSTART>

Returns the starting observation time in FITS restricted ISO8601
format: YYYY-MM-DDThh:mm:ss.

=cut

sub from_UTSTART {
  my $class = shift;
  my $generic_headers = shift;
  my %return_hash;
  if ( exists( $generic_headers->{UTSTART} ) ) {
    my $date = $generic_headers->{UTSTART};
    $return_hash{'DATE-OBS'} = $date->datetime;
  }
  return %return_hash;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::Base>.

=head1 AUTHOR

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>,
Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.
Malcolm J. Currie E<lt>mjc@star.rl.ac.ukE<gt>

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
