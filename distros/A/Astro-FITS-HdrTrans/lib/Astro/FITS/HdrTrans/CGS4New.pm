package Astro::FITS::HdrTrans::CGS4New;

=head1 NAME

Astro::FITS::HdrTrans::CGS4New - UKIRT CGS4 translations for "new"
style CGS4 headers.

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::CGS4New;

  %gen = Astro::FITS::HdrTrans::CGS4New->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the CGS4 spectrometer of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UIST
use base qw/ Astro::FITS::HdrTrans::UIST /;

use vars qw/ $VERSION /;

$VERSION = "1.65";

my %CONST_MAP = ( OBSERVATION_MODE => 'spectroscopy',
                );

my %UNIT_MAP = ( DEC_BASE => "DECBASE",
                 DEC_SCALE => "CDELT3",
                 EXPOSURE_TIME => "DEXPTIME",
                 GRATING_DISPERSION => "GDISP",
                 GRATING_NAME => "GRATING",
                 GRATING_ORDER => "GORDER",
                 GRATING_WAVELENGTH => "GLAMBDA",
                 NSCAN_POSITIONS => "DETNINCR",
                 RA_BASE => "RABASE",
                 RA_SCALE =>  "CDELT2",
                 SCAN_INCREMENT => "DETINCR",
                 SLIT_ANGLE => "SANGLE",
                 SLIT_NAME => "SLIT",
                 SLIT_WIDTH => "SWIDTH",
                 X_BASE => "CRVAL2",
                 X_REFERENCE_PIXEL => "CRPIX2",
                 Y_BASE => "CRVAL3",
                 Y_REFERENCE_PIXEL => "CRPIX3",
               );

# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP );

=head1 METHODS

=over 4

=item B<can_translate>

Returns true if the supplied headers can be handled by this class.

  $cando = $class->can_translate( \%hdrs );

This method returns tru if the INSTRUME header exists and is equal to
'CGS4', and if the DHSVER header exists and is equal to 'UKDHS 2008
Dec. 1'.

=cut

sub can_translate {
  my $self = shift;
  my $headers = shift;

  if ( exists( $headers->{INSTRUME} ) &&
       uc( $headers->{INSTRUME} ) eq 'CGS4' &&
       exists( $headers->{DHSVER} ) &&
       uc( $headers->{DHSVER} ) eq 'UKDHS 2008 DEC. 1' ) {
    return 1;
  }

  # Handle the reverse case as well. This module can translate CGS4
  # headers newer than 20081115.
  if ( exists $headers->{INSTRUMENT} &&
       uc( $headers->{INSTRUMENT} ) eq 'CGS4' &&
       exists $headers->{UTDATE} &&
       $headers->{UTDATE} >= 20081115 ) {
    return 1;
  }

  return 0;
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_ROTATION>

This determines the angle, in decimal degrees, of the rotation of the
sky component of the WCS. It uses the standard transformation matrix
PCi_j as defined in the FITS WCS Standard. In the absence of a PCi_j
matrix, it looks for the CROTA2 keyword.

For CGS4 the PCi_j matrix is obtained from i=[2,3] and j=[2,3].

=cut

sub to_ROTATION {
  my $self = shift;
  my $FITS_headers = shift;
  my $rotation;

  my $rtod = 45 / atan2( 1, 1 );

  if ( defined( $FITS_headers->{PC2_2} ) || defined( $FITS_headers->{PC2_3} ) ||
       defined( $FITS_headers->{PC3_2} ) || defined( $FITS_headers->{PC3_3} ) ) {
    my $pc22 = defined( $FITS_headers->{PC2_2} ) ? $FITS_headers->{PC2_2} : 1.0;
    my $pc32 = defined( $FITS_headers->{PC3_2} ) ? $FITS_headers->{PC3_2} : 0.0;
    my $pc23 = defined( $FITS_headers->{PC2_3} ) ? $FITS_headers->{PC2_3} : 0.0;
    my $pc33 = defined( $FITS_headers->{PC3_3} ) ? $FITS_headers->{PC3_3} : 1.0;

    # Average the estimates of the rotation converting from radians to
    # degrees (rtod) as the matrix may not represent a pure rotation.
    $rotation = $rtod * 0.5 * ( atan2( -$pc32 / $rtod, $pc22 / $rtod ) +
                                atan2(  $pc23 / $rtod, $pc33 / $rtod ) );

  } elsif ( exists $FITS_headers->{CROTA2} ) {
    $rotation =  $FITS_headers->{CROTA2} + 90.0;
  } else {
    $rotation = 90.0;
  }
  return $rotation;
}

=item B<to_UTDATE>

Sets the YYYYMMDD-style UTDATE generic header based on the DATE-OBS
header.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $utdate;

  my $dateobs = $FITS_headers->{'DATE-OBS'};
  $dateobs =~ /^(\d{4}-\d\d-\d\d)/;
  $utdate = $1;
  $utdate =~ s/-//g;

  return $utdate;
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
