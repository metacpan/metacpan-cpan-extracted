package Astro::FITS::HdrTrans::UFTI;

=head1 NAME

Astro::FITS::HdrTrans::UFTI - UKIRT UFTI translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::UFTI;

  %gen = Astro::FITS::HdrTrans::UFTI->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the UFTI camera of the United Kingdom Infrared Telescope.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from UKIRTNew
use base qw/ Astro::FITS::HdrTrans::UKIRTNew /;

use vars qw/ $VERSION /;

$VERSION = "1.65";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (

                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ DETECTOR_INDEX /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
                # CGS4 + IRCAM
                DETECTOR_READ_TYPE   => "MODE",

                # MICHELLE + IRCAM compatible
                SPEED_GAIN           => "SPD_GAIN",
               );


# Create the translation methods
__PACKAGE__->_generate_lookup_methods( \%CONST_MAP, \%UNIT_MAP, \@NULL_MAP );

=head1 METHODS

=over 4

=item B<this_instrument>

The name of the instrument required to match (case insensitively)
against the INSTRUME/INSTRUMENT keyword to allow this class to
translate the specified headers. Called by the default
C<can_translate> method.

  $inst = $class->this_instrument();

Returns "UFTI".

=cut

sub this_instrument {
  return "UFTI";
}

=back

=head1 COMPLEX CONVERSIONS

These methods are more complicated than a simple mapping.  We have to
provide both from- and to-FITS conversions.  All these routines are
methods and the to_ routines all take a reference to a hash and return
the translated value (a many-to-one mapping).  The from_ methods take a
reference to a generic hash and return a translated hash (sometimes
these are many-to-many).

=over 4

=item B<to_DEC_SCALE>

Sets the declination scale in arcseconds per pixel derived
from keyword C<CDELT2>.  The default is time dependent, as tabulated
in the UFTI web page.
L<http://www.jach.hawaii.edu/UKIRT/instruments/ufti/PARAMETERS.html#1>
The default scale assumes north is to the top.

The actual C<CDELT2> value is scaled if its unit is degree/pixel,
as suggested by its size, and the presence of header C<CTYPE2> set
to 'DEC--TAN' indicating that the WCS follows the AIPS convention.

=cut

sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;

  # Default from 20011115.
  my $scale = 0.09085;

  # Note in the raw data these are in arcseconds, not degrees.
  if ( defined( $FITS_headers->{CDELT2} ) ) {
    $scale = $FITS_headers->{CDELT2};

    # Allow for missing values using measured scales.
  } else {
    my $date = $self->to_UTDATE( $FITS_headers );
    if ( defined( $date ) ) {
      if ( $date < 19990701 ) {
        $scale = 0.09075;
      } elsif ( $date < 20010401 ) {
        $scale = 0.09088;
      } elsif ( $date < 20011115 ) {
        $scale = 0.09060;
      }
    }
  }

  # Allow for D notation, which is not recognised by Perl, so that
  # supplied strings are valid numbers.
  $scale =~ s/D/E/;

  # The CDELTn headers are either part of a WCS in expressed in the
  # AIPS-convention, or the values we require.  Angles for the former
  # are measured in degrees.  The sign of the scale may be negative.
  if ( defined $FITS_headers->{CTYPE2} &&
       $FITS_headers->{CTYPE2} eq "DEC--TAN" &&
       abs( $scale ) < 1.0E-3 ) {
    $scale *= 3600.0;
  }
  return $scale;
}

=item B<to_FILE_FORMAT>

Determines the file format being used.  It is either C<"HDS"> (meaning
an HDS container file of NDFs) or C<"FITS"> and is determined by the
presence of the DHSVER header.

=cut

sub to_FILE_FORMAT {
  my $self = shift;
  my $FITS_headers = shift;
  my $format = "HDS";
  if ( ! exists( $FITS_headers->{DHSVER} ) ) {
    $format = "FITS";
  }
  return $format;
}

=item B<to_POLARIMETRY>

Checks the filter name.

=cut

sub to_POLARIMETRY {
  my $self = shift;
  my $FITS_headers = shift;
  if ( exists( $FITS_headers->{FILTER} ) &&
       $FITS_headers->{FILTER} =~ /pol/i ) {
    return 1;
  } else {
    return 0;
  }
}

=item B<to_RA_BASE>

Converts the decimal hours in the FITS header C<RABASE> into
decimal degrees for the generic header C<RA_BASE>.

Note that this is different from the original translation within
ORAC-DR where it was to decimal hours.

There was a period from 2000-05-07 to 2000-07-19 inclusive, where
degrees, not hours, were written whenever the data were stored as NDF
format.  However, there wasn't a clean changover during ORAC-DR
commissioning.  So use the FILE_FORMAT to discriminate between the two
formats.

=cut

sub to_RA_BASE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists($FITS_headers->{RABASE} ) ) {
    my $date = $self->to_UTDATE( $FITS_headers );
    my $format = $self->to_FILE_FORMAT( $FITS_headers );

    if ( defined( $format ) && $format eq "HDS" &&
         defined( $date ) && $date > 20000507 && $date < 20000720 ) {
      $return = $FITS_headers->{RABASE};
    } else {
      $return = $FITS_headers->{RABASE} * 15;
    }
  }
  return $return;
}

=item B<from_RA_BASE>

Converts the decimal degrees in the generic header C<RA_BASE>
into decimal hours for the FITS header C<RABASE>.

  %fits = $class->from_RA_BASE( \%generic );

There was a period from 2000-05-07 to 2000-07-19 inclusive, where
degrees, not hours, were written whenever the data were stored as NDF
format.  However, there was not a clean changover during ORAC-DR
commissioning.  So use the generic header FILE_FORMAT to discriminate
between the two formats.  For symmetry and consistency, retain these
units during the problem period.

=cut

sub from_RA_BASE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if ( defined( $generic_headers->{RA_BASE} ) ) {
    my $date = $self->to_UTDATE( $generic_headers );

    if ( defined( $generic_headers->{FILE_FORMAT} ) &&
         $generic_headers->{FILE_FORMAT} eq "HDS" &&
         defined( $date ) && $date > 20000507 && $date < 20000720 ) {
      $return_hash{'RABASE'} = $generic_headers->{RA_BASE};
    } else {
      $return_hash{'RABASE'} = $generic_headers->{RA_BASE} / 15;
    }
  }
  return %return_hash;
}

=item B<to_RA_SCALE>

Sets the right-ascension scale in arcseconds per pixel derived
from keyword C<CDELT1>.  The default is time dependent, as tabulated
in the UFTI web page.
L<http://www.jach.hawaii.edu/UKIRT/instruments/ufti/PARAMETERS.html#1>
The default scale assumes east is to the left.

It corrects for an erroneous sign in early data.

The actual C<CDELT1> value is scaled if its unit is degree/pixel,
as suggested by its size, and the presence of header C<CTYPE1> set
to 'RA---TAN' indicating that the WCS follows the AIPS convention.

=cut

sub to_RA_SCALE {
  my $self = shift;
  my $FITS_headers = shift;

  # Default from 20011115.
  my $scale = -0.09085;

  # Note in the raw data these are in arcseconds, not degrees.
  if ( defined( $FITS_headers->{CDELT1} ) ) {
    $scale = $FITS_headers->{CDELT1};

    # Allow for missing values using measured scales.
  } else {
    my $date = $self->to_UTDATE( $FITS_headers );
    if ( defined( $date ) ) {
      if ( $date < 19990701 ) {
        $scale = -0.09075;
      } elsif ( $date < 20010401 ) {
        $scale = -0.09088;
      } elsif ( $date < 20011115 ) {
        $scale = -0.09060;
      }
    }
  }

  # Allow for D notation, which is not recognised by Perl, so that
  # supplied strings are valid numbers.
  $scale =~ s/D/E/;

  # Correct the RA scale.  The RA scale originates from the erroneous
  # positive CDELT1.  Reverse the sign to give the correct increment
  # per pixel.
  if ( $scale > 0.0 ) {
    $scale *= -1.0;
  }

  # The CDELTn headers are either part of a WCS in expressed in the
  # AIPS-convention, or the values we require.  Angles for the former
  # are measured in degrees.  The sign of the scale may be negative.
  if ( defined $FITS_headers->{CTYPE1} &&
       $FITS_headers->{CTYPE1} eq "RA---TAN" &&
       abs( $scale ) < 1.0E-3 ) {
    $scale *= 3600.0;
  }

  return $scale;
}

=item B<from_RA_SCALE>

Converts the generic header C<RA_SCALE> to the FITS header C<CDELT1>
by ensuring it has a positive sign as in the input data.  This
sign is wrong because the right ascension increases with decreasing
pixel index, however this conversion permits a cycle from FITS to
generic and back to FITS to retain the original value.

  %fits = $class->from_RA_SCALE( \%generic );

=cut

sub from_RA_SCALE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if ( defined( $generic_headers->{RA_SCALE} ) ) {
    $return_hash{'CDELT1'} = -1.0 * $generic_headers->{RA_SCALE};
  }
  return %return_hash;
}

=item B<to_UTDATE>

Converts FITS header values into C<Time::Piece> object.  This differs
from the base class in the use of the C<DATE> rather than C<UTDATE>
header item and the formatting of the DATE keyword is not an integer.

=cut

sub to_UTDATE {
  my $self = shift;
  my $FITS_headers = shift;
  my $return;
  if ( exists( $FITS_headers->{DATE} ) ) {
    my $utdate = $FITS_headers->{DATE};

    # This is a kludge to work with old data which has multiple values of
    # the DATE keyword with the last value being blank (these were early
    # UFTI data).  Return the first value, since the last value can be
    # blank.
    if ( ref( $utdate ) eq 'ARRAY' ) {
      $utdate = $utdate->[0];
    }
    $return = $self->_parse_yyyymmdd_date( $utdate, "-" );
    $return = $return->strftime( '%Y%m%d' );
  }

  return $return;
}

=item B<from_UTDATE>

Converts UT date in C<Time::Piece> object into C<YYYY-MM-DD> format
for DATE header.  This differs from the base class in the use of the
C<DATE> rather than C<UTDATE> header item.

=cut

sub from_UTDATE {
  my $self = shift;
  my $generic_headers = shift;
  my %return_hash;
  if ( exists( $generic_headers->{UTDATE} ) ) {
    my $date = $generic_headers->{UTDATE};
    $date = $self->_parse_yyyymmdd_date( $date, '' );
    return () unless defined $date;
    $return_hash{DATE} = sprintf( "%04d-%02d-%02d",
                                  $date->year, $date->mon, $date->mday );
  }
  return %return_hash;
}

=item B<to_UTEND>

Converts UT date in C<DATE-END> header into C<Time::Piece> object.
Allows for blank C<DATE-END> string present in early UFTI data.

=cut

sub to_UTEND {
  my $self = shift;
  my $FITS_headers = shift;
  my $dateend = ( exists $FITS_headers->{"DATE-END"} ?
                  $FITS_headers->{"DATE-END"} : undef );

  # Some early data had blank DATE-OBS strings.
  if ( defined( $dateend ) && $dateend !~ /\d/ ) {
    $dateend = undef;
  }

  my @rutend = sort {$a<=>$b} $self->via_subheader( $FITS_headers, "UTEND" );
  my $utend = $rutend[-1];
  return $self->_parse_date_info( $dateend,
                                  $self->to_UTDATE( $FITS_headers ),
                                  $utend );
}

=item B<to_UTSTART>

Converts UT date in C<DATE-OBS> header into C<Time::Piece> object.
Allows for blank C<DATE-OBS> string present in early UFTI data.

=cut

sub to_UTSTART {
  my $self = shift;
  my $FITS_headers = shift;
  my $dateobs = ( exists $FITS_headers->{"DATE-OBS"} ?
                  $FITS_headers->{"DATE-OBS"} : undef );

  # Some early data had blank DATE-OBS strings.
  if ( defined( $dateobs ) && $dateobs !~ /\d/ ) {
    $dateobs = undef;
  }

  my @rutstart = sort {$a<=>$b} $self->via_subheader( $FITS_headers, "UTSTART" );
  my $utstart = $rutstart[0];
  return $self->_parse_date_info( $dateobs,
                                  $self->to_UTDATE( $FITS_headers ),
                                  $utstart );
}


=item B<to_X_REFERENCE_PIXEL>

Specify the reference pixel, which is normally near the frame centre.
There may be small displacements to avoid detector joins or for
polarimetry using a Wollaston prism.

=cut

sub to_X_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $xref;

  # Use the average of the bounds to define the centre and dimension.
  if ( exists $FITS_headers->{RDOUT_X1} && exists $FITS_headers->{RDOUT_X2} ) {
    my $xl = $FITS_headers->{RDOUT_X1};
    my $xu = $FITS_headers->{RDOUT_X2};
    my $xdim = $xu - $xl + 1;
    my $xmid = $self->nint( ( $xl + $xu ) / 2 );

    # UFTI is at the centre for a sub-array along an axis but offset slightly
    # for a sub-array to avoid the joins between the four sub-array sections
    # of the frame.  Ideally these should come through the headers...
    if ( $xdim == 1024 ) {
      $xref = $xmid + 20;
    } else {
      $xref = $xmid;
    }

    # Correct for IRPOL beam splitting with a 6" E offset.
    if ( $FITS_headers->{FILTER} =~ m/pol/ ) {
      $xref -= 65.5;
    }

    # Use a default which assumes the full array (slightly offset from the
    # centre).
  } else {
    $xref = 533;
  }
  return $xref;
}

=item B<from_X_REFERENCE_PIXEL>

Always returns CRPIX1 of "0.5".

=cut

sub from_X_REFERENCE_PIXEL {
  return ( "CRPIX1" => 0.5 );
}

=item B<to_Y_REFERENCE_PIXEL>

Specify the reference pixel, which is normally near the frame centre.
There may be small displacements to avoid detector joins or for
polarimetry using a Wollaston prism.

=cut

sub to_Y_REFERENCE_PIXEL{
  my $self = shift;
  my $FITS_headers = shift;
  my $yref;

  # Use the average of the bounds to define the centre and dimension.
  if ( exists $FITS_headers->{RDOUT_Y1} && exists $FITS_headers->{RDOUT_Y2} ) {
    my $yl = $FITS_headers->{RDOUT_Y1};
    my $yu = $FITS_headers->{RDOUT_Y2};
    my $ydim = $yu - $yl + 1;
    my $ymid = $self->nint( ( $yl + $yu ) / 2 );

    # UFTI is at the centre for a sub-array along an axis but offset slightly
    # for a sub-array to avoid the joins between the four sub-array sections
    # of the frame.  Ideally these should come through the headers...
    if ( $ydim == 1024 ) {
      $yref = $ymid - 25;
    } else {
      $yref = $ymid;
    }

    # Correct for IRPOL beam splitting with a " N offset.
    if ( $FITS_headers->{FILTER} =~ m/pol/ ) {
      $yref += 253;
    }

    # Use a default which assumes the full array (slightly offset from the
    # centre).
  } else {
    $yref = 488;
  }
  return $yref;
}

=item B<from_X_REFERENCE_PIXEL>

Always returns CRPIX2 of "0.5".

=cut

sub from_Y_REFERENCE_PIXEL {
  return ( "CRPIX2" => 0.5 );
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
