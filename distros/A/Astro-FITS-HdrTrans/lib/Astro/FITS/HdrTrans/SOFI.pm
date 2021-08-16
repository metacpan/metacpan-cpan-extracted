package Astro::FITS::HdrTrans::SOFI;

=head1 NAME

Astro::FITS::HdrTrans::SOFI - ESO SOFI translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::SOFI;

  %gen = Astro::FITS::HdrTrans::SOFI->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the SOFI camera of the European Southern Observatory.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from ESO
use base qw/ Astro::FITS::HdrTrans::ESO /;

use vars qw/ $VERSION /;

$VERSION = "1.64";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 POLARIMETRY => 0,
                );

# NULL mappings used to override base class implementations
my @NULL_MAP = qw/ /;

# unit mapping implies that the value propogates directly
# to the output with only a keyword name change

my %UNIT_MAP = (
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

Returns "SOFI".

=cut

sub this_instrument {
  return "SOFI";
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=cut

# If the telescope ofset exists in arcsec, then use it.  Otherwise
# convert the Cartesian offsets to equatorial offsets.
sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $decoffset = 0.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETD"} ) {
    $decoffset = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETD"};

  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} ||
            exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} ) {

    # Obtain the x-y offsets in arcsecs.
    my ($x_as, $y_as) = $self->xy_offsets( $FITS_headers );

    # Define degrees to radians conversion and obtain the rotation angle.
    my $dtor = atan2( 1, 1 ) / 45.0;

    my $rotangle = $self->rotation( $FITS_headers );
    my $cosrot = cos( $rotangle * $dtor );
    my $sinrot = sin( $rotangle * $dtor );

    # Apply the rotation matrix to obtain the equatorial pixel offset.
    $decoffset = -$x_as * $sinrot + $y_as * $cosrot;
  }

  # The sense is reversed compared with UKIRT, as these measure the
  # place on the sky, not the motion of the telescope.
  return -1.0 * $decoffset;
}

# Filter positions 1 and 2 used.
sub to_FILTER {
  my $self = shift;
  my $FITS_headers = shift;
  my $filter = "";
  my $filter1 = "open";
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"} ) {
    $filter1 = $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"};
  }

  my $filter2 = "open";
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.FILT2.ID"} ) {
    $filter2 = $FITS_headers->{"HIERARCH.ESO.INS.FILT2.ID"};
  }

  if ( $filter1 eq "open" ) {
    $filter = $filter2;
  }

  if ( $filter2 eq "open" ) {
    $filter = $filter1;
  }

  if ( ( $filter1 eq "blank" ) ||
       ( $filter2 eq "blank" ) ) {
    $filter = "blank";
  }
  return $filter;
}

=item B<to_GAIN>

Fixed values for the gain depend on the camera (SW or LW), and for LW
the readout mode. This implementation returns a single number.

=cut

sub to_GAIN {
  my $self = shift;
  my $gain = 5.4;
  return $gain;
}

# Dispersion in microns per pixel.
sub to_GRATING_DISPERSION {
  my $self = shift;
  my $FITS_headers = shift;
  my $dispersion = 0.0;
  my $order = 0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ORDER"} ) {
    $order = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ORDER"};
  }
  if ( $self->to_GRATING_NAME($FITS_headers) eq "LR" ) {
    if ( lc( $order ) eq "blue" || $self->to_FILTER($FITS_headers) eq "GBF" ) {
      $dispersion = 6.96e-4;
    } else {
      $dispersion = 1.022e-3;
    }

    # Medium dispersion
  } elsif ( $self->to_GRATING_NAME($FITS_headers) eq "MR" ) {
    if ( $order == 8 ) {
      $dispersion = 1.58e-4;
    } elsif ( $order == 7 ) {
      $dispersion = 1.87e-4;
    } elsif ( $order == 6 ) {
      $dispersion = 2.22e-5;
    } elsif ( $order == 5 ) {
      $dispersion = 2.71e-5;
    } elsif ( $order == 4 ) {
      $dispersion = 3.43e-5;
    } elsif ( $order == 3 ) {
      $dispersion = 4.62e-5;
    }
  }
  return $dispersion;
}

sub to_GRATING_NAME{
  my $self = shift;
  my $FITS_headers = shift;
  my $name = "MR";
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"} ) {
    $name = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"};

    # Name is missing for low resolution.
  } elsif ( $self->to_FILTER( $FITS_headers ) =~ /^G[BR]F/ ) {
    $name = "LR";
  }
  return $name;
}

sub to_GRATING_WAVELENGTH{
  my $self = shift;
  my $FITS_headers = shift;
  my $wavelength = 0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.WLEN"} ) {
    $wavelength = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.WLEN"};

    # Wavelength is missing for low resolution.
  } elsif ( $self->to_FILTER( $FITS_headers ) =~ /^GBF/ ) {
    $wavelength = 1.3;
  } elsif ( $self->to_FILTER( $FITS_headers ) =~ /^GRF/ ) {
    $wavelength = 2.0;
  }
  return $wavelength;
}

sub to_NUMBER_OF_READS {
  my $self = shift;
  my $FITS_headers = shift;
  my $number = 2;
  if ( exists $FITS_headers->{"HIERARCH.ESO.DET.NCORRS"} ) {
    $number = $FITS_headers->{"HIERARCH.ESO.DET.NCORRS"};
  }
  return $number;
}

# FLAT and DARK need no change.
sub to_OBSERVATION_TYPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $type = $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"};
  $type = exists( $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"} ) ? $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"} : "OBJECT";

  my $cat = $FITS_headers->{"HIERARCH.ESO.DPR.CATG"};
  $cat = exists( $FITS_headers->{"HIERARCH.ESO.DPR.CATG"} ) ? $FITS_headers->{"HIERARCH.ESO.DPR.CATG"} : "SCIENCE";

  if ( uc( $cat ) eq "TEST" ) {
    $type = "TEST";
  } elsif ( uc( $type ) eq "STD" || uc( $cat ) eq "SCIENCE" ) {
    $type = "OBJECT";
  } elsif ( uc( $type ) eq "SKY,FLAT" || uc( $type ) eq "FLAT,SKY" ||
            uc( $cat ) eq "OTHER" ) {
    $type = "SKY";
  } elsif ( uc( $type ) eq "LAMP,FLAT" || uc( $type ) eq "FLAT,LAMP" ||
            uc( $type ) eq "FLAT" ) {
    $type = "LAMP";
  } elsif ( uc( $type ) eq "LAMP" ) {
    $type = "ARC";
  } elsif ( uc( $type ) eq "OTHER" ) {
    $type = "OBJECT";
  }
  return $type;
}

# If the telescope offset exists in arcsec, then use it.  Otherwise
# convert the Cartesian offsets to equatorial offsets.
sub to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $raoffset = 0.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETA"} ) {
    $raoffset = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETA"};

  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} ||
            exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} ) {

    # Obtain the x-y offsets in arcsecs.
    my ($x_as, $y_as) = $self->xy_offsets( $FITS_headers );

    # Define degrees to radians conversion and obtain the rotation angle.
    my $dtor = atan2( 1, 1 ) / 45.0;

    my $rotangle = $self->rotation( $FITS_headers );
    my $cosrot = cos( $rotangle * $dtor );
    my $sinrot = sin( $rotangle * $dtor );

    # Apply the rotation matrix to obtain the equatorial pixel offset.
    $raoffset = -$x_as * $cosrot + $y_as * $sinrot;
  }

  # The sense is reversed compared with UKIRT, as these measure the
  # place on the sky, not the motion of the telescope.
  return -1.0 * $raoffset;
}

# Derive the translation between observing template and recipe name.
sub to_DR_RECIPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $recipe = "QUICK_LOOK";

  # Obtain the observing template.  These are equivalent
  # to the UKIRT OT science programmes and their tied DR recipes.
  # However, there are some wrinkles and variations to be tested.
  my $template = $FITS_headers->{"HIERARCH.ESO.TPL.ID"};
  my $seq = $FITS_headers->{"HIERARCH.ESO.TPL.PRESEQ"};
  my $type = $FITS_headers->{"HIERARCH.ESO.DPR.TYPE"};

  if ( $template eq "SOFI_img_obs_AutoJitter" ||
       $template eq "SOFI_img_obs_Jitter" ||
       $template eq "SOFI_img_obs_GenericOffset" ) {
    if ( $type eq "STD" ) {
      $recipe = "JITTER_SELF_FLAT_APHOT";
    } else {
      $recipe = "JITTER_SELF_FLAT";
    }

  } elsif ( $template eq "SOFI_img_cal_StandardStar" ||
            $template eq "SOFI_img_tec_Zp" ||
            $seq eq "SOFI_img_cal_StandardStar" ) {
    $recipe = "JITTER_SELF_FLAT_APHOT";

  } elsif ( $template eq "SOFI_img_obs_AutoJitterOffset" ||
            $template eq "SOFI_img_obs_JitterOffset" ) {
    $recipe = "CHOP_SKY_JITTER";

  } elsif ( $template eq "SOFI_img_cal_Darks" ||
            $seq eq "SOFI_img_cal_Darks" ) {
    $recipe = "REDUCE_DARK";

  } elsif ( $template eq "SOFI_img_cal_DomeFlats" ) {
    $recipe = "DOME_FLAT";

  } elsif ( $template eq "SOFI_img_cal_SpecialDomeFlats" ) {
    $recipe = "SPECIAL_DOME_FLAT";

    # Imaging spectroscopy.  There appears to be no distinction
    # for flats from target, hence no division into POL_JITTER and
    # SKY_FLAT_POL.
  } elsif ( $template eq "SOFI_img_obs_Polarimetry" ||
            $template eq "SOFI_img_cal_Polarimetry" ) {
    $recipe = "POL_JITTER";

    # Spectroscopy.  EXTENDED_SOURCE may be more appropriate for
    # the SOFISW_spec_obs_GenericOffset template.
  } elsif ( $template eq "SOFI_spec_obs_AutoNodOnSlit" ||
            $template eq "SOFI_spec_obs_AutoNodNonDestr" ) {
    $recipe = "POINT_SOURCE";

  } elsif ( $template eq "SOFI_spec_cal_StandardStar" ||
            $template eq "SOFI_spec_cal_AutoNodOnSlit"  ) {
    $recipe = "STANDARD_STAR";

  } elsif ( $template eq "SOFI_spec_cal_NightCalib" ) {
    $recipe = "REDUCE_SINGLE_FRAME";

  } elsif ( $template eq "SOFI_spec_cal_Arcs" ||
            $seq eq "SOFI_spec_cal_Arcs" ) {
    $recipe = "REDUCE_ARC";

  } elsif ( $template eq "SOFI_spec_cal_DomeFlats" ||
            $template eq "SOFI_spec_cal_NonDestrDomeFlats" ) {
    $recipe = "LAMP_FLAT";
  }
  return $recipe;
}

# Fixed value for the gain.
sub to_SPEED_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $spd_gain = "Normal";
  return $spd_gain;
}

# Translate to the SLALIB name for reference frame in spectroscopy.
sub to_TELESCOPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $telescope = "ESONTT";
  if ( exists $FITS_headers->{TELESCOP} ) {
    my $scope = $FITS_headers->{TELESCOP};
    if ( defined( $scope ) ) {
      $telescope = $scope;
      $telescope =~ s/-U//g;
      $telescope =~ s/-//;
    }
  }
  return $telescope;
}

# Supplementary methods for the translations
# ------------------------------------------
sub xy_offsets {
  my $self = shift;
  my $FITS_headers = shift;
  my $pixscale = 0.144;
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} ) {
    $pixscale = $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"};
  }

  # Sometimes the first imaging cumulative offsets are non-zero contrary
  # to the documentation.
  my $expno = 1;
  if ( exists $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"} ) {
    $expno = $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"};
  }
  my $x_as = 0.0;
  my $y_as = 0.0;
  my $mode = uc( $self->get_instrument_mode( $FITS_headers ) );
  if ( !( $expno == 1 && ( $mode eq "IMAGE" || $mode eq "POLARIMETRY" ) ) ) {
    if ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} ) {
      $x_as = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} * $pixscale;
    }
    if ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} ) {
      $y_as = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} * $pixscale;
    }
  }
  return ($x_as, $y_as);
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
