package Astro::FITS::HdrTrans::ISAAC;

=head1 NAME

Astro::FITS::HdrTrans::ISAAC - ESO ISAAC translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::ISAAC;

  %gen = Astro::FITS::HdrTrans::ISAAC->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the ISAAC camera of the European Southern Observatory.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from ESO
use base qw/ Astro::FITS::HdrTrans::ESO /;

use vars qw/ $VERSION /;

$VERSION = "1.61";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
                 POLARIMETRY   => 0,
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

Returns "ISAAC".

=cut

sub this_instrument {
  return "ISAAC";
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=item B<to_DEC_TELESCOPE_OFFSET>

If the telescope ofset exists in arcsec, then use it.  Otherwise
convert the Cartesian offsets to equatorial offsets.

=cut

sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $decoffset = 0.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETD"} ) {
    $decoffset = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETD"};

  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} &&
            exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} ) {

    my $pixscale = 0.148;
    if ( exists $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} ) {
      $pixscale = $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"};
    }

    # Sometimes the first imaging cumulative offsets are non-zero contrary
    # to the documentation.
    my $expno = 1;
    if ( exists $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"} ) {
      $expno = $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"};
    }
    my ( $x_as, $y_as );
    my $mode = uc( $self->get_instrument_mode($FITS_headers) );
    if ( $expno == 1 && ( $mode eq "IMAGE" || $mode eq "POLARIMETRY" ) ) {
      $x_as = 0.0;
      $y_as = 0.0;
    } else {
      $x_as = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} * $pixscale;
      $y_as = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} * $pixscale;
    }

    # Define degrees to radians conversion and obtain the rotation angle.
    my $dtor = atan2( 1, 1 ) / 45.0;

    my $rotangle = $self->rotation($FITS_headers);
    my $cosrot = cos( $rotangle * $dtor );
    my $sinrot = sin( $rotangle * $dtor );

    # Apply the rotation matrix to obtain the equatorial pixel offset.
    $decoffset = -$x_as * $sinrot + $y_as * $cosrot;
  }

  # The sense is reversed compared with UKIRT, as these measure the
  # place on the sky, not the motion of the telescope.
  return -1.0 * $decoffset;
}

# Filter positions 1 and 2 used for SW and 3 & 4 for LW.
sub to_FILTER {
  my $self = shift;
  my $FITS_headers = shift;
  my $filter = "Ks";
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"} ) {
    $filter = $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"};
  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.INS.FILT3.ID"} ) {
    $filter = $FITS_headers->{"HIERARCH.ESO.INS.FILT3.ID"};
  }
  return $filter;
}

# Fixed values for the gain depend on the camera (SW or LW), and for LW
# the readout mode.
sub to_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $gain = 4.6;
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.MODE"} ) {
    if ( $FITS_headers->{"HIERARCH.ESO.INS.MODE"} =~ /SW/ ) {
      $gain = 4.6;
    } else {
      if ( exists $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} ) {
        if ( $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} =~ /LowBias/ ) {
          $gain = 8.7;
        } else {
          $gain = 7.8;
        }
      }
    }
  }
  return $gain;
}

sub to_GRATING_DISPERSION {
  my $self = shift;
  my $FITS_headers = shift;
  my $dispersion = 0.0;
  #   if ( exists $FITS_headers->{CDELT1} ) {
  #      $dispersion = $FITS_headers->{CDELT1};
  #   } else {
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"} &&
       exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ORDER"} ) {
    my $order = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ORDER"};
    if ( $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"} eq "LR" ) {
      if ( $order == 6 ) {
        $dispersion = 2.36e-4;
      } elsif ( $order == 5 ) {
        $dispersion = 2.83e-4;
      } elsif ( $order == 4 ) {
        $dispersion = 3.54e-4;
      } elsif ( $order == 3 ) {
        $dispersion = 4.72e-4;
      } elsif ( $order == 2 ) {
        $dispersion = 7.09e-4;
      } elsif ( $order == 1 ) {
        if ( exists $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"} ) {
          my $filter = $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"};
          if ( $filter =~/SL/ ) {
            $dispersion = 1.412e-3;
          } else {
            $dispersion = 1.45e-3;
          }
        } else {
          $dispersion = 1.41e-3;
        }
      }

      # Medium dispersion
    } elsif ( $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"} eq "MR" ) {
      if ( $order == 6 ) {
        $dispersion = 3.7e-5;
      } elsif ( $order == 5 ) {
        $dispersion = 4.6e-5;
      } elsif ( $order == 4 ) {
        $dispersion = 5.9e-5;
      } elsif ( $order == 3 ) {
        $dispersion = 7.8e-5;
      } elsif ( $order == 2 ) {
        $dispersion = 1.21e-4;
      } elsif ( $order == 1 ) {
        if ( exists $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"} ) {
          my $filter = $FITS_headers->{"HIERARCH.ESO.INS.FILT1.ID"};
          if ( $filter =~/SL/ ) {
            $dispersion = 2.52e-4;
          } else {
            $dispersion = 2.39e-4;
          }
        } else {
          $dispersion = 2.46e-4;
        }
      }
    }
  }
  #   }
  return $dispersion;
}

# If the telescope offset exists in arcsec, then use it.  Otherwise
# convert the Cartesian offsets to equatorial offsets.
sub to_RA_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $raoffset = 0.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETA"} ) {
    $raoffset = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETA"};

  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} &&
            exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} ) {

    my $pixscale = 0.148;
    if ( exists $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} ) {
      $pixscale = $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"};
    }

    # Sometimes the first imaging cumulative offsets are non-zero contrary
    # to the documentation.
    my $expno = 1;
    if ( exists $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"} ) {
      $expno = $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"};
    }
    my ( $x_as, $y_as );
    my $mode = uc( $self->get_instrument_mode($FITS_headers) );
    if ( $expno == 1 && ( $mode eq "IMAGE" || $mode eq "POLARIMETRY" ) ) {
      $x_as = 0.0;
      $y_as = 0.0;
    } else {
      $x_as = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} * $pixscale;
      $y_as = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} * $pixscale;
    }

    # Define degrees to radians conversion and obtain the rotation angle.
    my $dtor = atan2( 1, 1 ) / 45.0;

    my $rotangle = $self->rotation($FITS_headers);
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

  if ( $template =~ /ISAAC[SL]W_img_obs_AutoJitter/ ||
       $template =~ /ISAAC[SL]W_img_obs_GenericOffset/ ) {
    $recipe = "JITTER_SELF_FLAT";

  } elsif ( $template eq "ISAACSW_img_cal_StandardStar" ||
            $template eq "ISAACLW_img_cal_StandardStarOff" ||
            $template eq "ISAACSW_img_tec_Zp" ||
            $template eq "ISAACLW_img_tec_ZpNoChop" ||
            $seq eq "ISAAC_img_cal_StandardStar" ||
            $seq eq "ISAACLW_img_cal_StandardStarOff" ) {
    $recipe = "JITTER_SELF_FLAT_APHOT";

  } elsif ( $template =~ /ISAAC[SL]W_img_obs_AutoJitterOffset/ ) {
    $recipe = "CHOP_SKY_JITTER";

    # The following two perhaps should be using NOD_CHOP and a variant of
    # NOD_CHOP_APHOT to cope with the three source images (central double
    # flux) rather than four.
  } elsif ( $template eq "ISAACLW_img_obs_AutoChopNod" ||
            $seq eq "ISAACLW_img_obs_AutoChopNod" ) {
    $recipe = "NOD_SELF_FLAT_NO_MASK";

  } elsif ( $template eq "ISAACLW_img_cal_StandardStar" ||
            $template =~ /^ISAACLW_img_tec_Zp/ ||
            $seq eq "ISAACLW_img_cal_StandardStar" ) {
    $recipe = "NOD_SELF_FLAT_NO_MASK_APHOT";

  } elsif ( $template =~ /ISAAC[SL]W_img_cal_Darks/ ||
            $seq eq "ISAAC_img_cal_Darks" ) {
    $recipe = "REDUCE_DARK";

  } elsif ( $template =~ /ISAAC[SL]W_img_cal_TwFlats/ ) {
    $recipe = "SKY_FLAT_MASKED";

    # Imaging spectroscopy.  There appears to be no distinction
    # for flats from target, hence no division into POL_JITTER and
    # SKY_FLAT_POL.
  } elsif ( $template eq "ISAACSW_img_obs_Polarimetry" ||
            $template eq "ISAACSW_img_cal_Polarimetry" ) {
    $recipe = "POL_JITTER";

    # Spectroscopy.  EXTENDED_SOURCE may be more appropriate for
    # the ISAACSW_spec_obs_GenericOffset template.
  } elsif ( $template =~ /ISAAC[SL]W_spec_obs_AutoNodOnSlit/ ||
            $template =~ /ISAAC[SL]W_spec_obs_GenericOffset/ ||
            $template eq "ISAACLW_spec_obs_AutoChopNod" ) {
    $recipe = "POINT_SOURCE";

  } elsif ( $template =~ /ISAAC[SL]W_spec_cal_StandardStar/ ||
            $template eq "ISAACLW_spec_cal_StandardStarNod" ||
            $template =~ /ISAAC[SL]W_spec_cal_AutoNodOnSlit/  ) {
    $recipe = "STANDARD_STAR";

  } elsif ( $template =~ /ISAAC[SL]W_spec_cal_NightCalib/ ) {
    if ( $self->_to_OBSERVATION_TYPE() eq "LAMP" ) {
      $recipe = "LAMP_FLAT";
    } elsif ( $self->_to_OBSERVATION_TYPE() eq "ARC" ) {
      $recipe = "REDUCE_ARC";
    } else {
      $recipe = "REDUCE_SINGLE_FRAME";
    }

  } elsif ( $template =~ /ISAAC[SL]W_spec_cal_Arcs/ ||
            $seq eq "ISAAC_spec_cal_Arcs" ) {
    $recipe = "REDUCE_ARC";

  } elsif ( $template =~ /ISAAC[SL]W_spec_cal_Flats/ ) {
    $recipe = "LAMP_FLAT";
  }
  return $recipe;
}

# Fixed values for the gain depend on the camera (SW or LW), and for LW
# the readout mode.
sub to_SPEED_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $spd_gain = "Normal";
  if ( exists $FITS_headers->{"HIERARCH.ESO.INS.MODE"} ) {
    if ( $FITS_headers->{"HIERARCH.ESO.INS.MODE"} =~ /SW/ ) {
      $spd_gain = "Normal";
    } else {
      if ( exists $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} ) {
        if ( $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} =~ /LowBias/ ) {
          $spd_gain = "HiGain";
        } else {
          $spd_gain = "Normal";
        }
      }
    }
  }
  return $spd_gain;
}

# Translate to the SLALIB name for reference frame in spectroscopy.
sub to_TELESCOPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $telescope = "VLT1";
  if ( exists $FITS_headers->{TELESCOP} ) {
    my $scope = $FITS_headers->{TELESCOP};
    if ( defined( $scope ) ) {
      $telescope = $scope;
      $telescope =~ s/ESO-//;
      $telescope =~ s/-U//g;
    }
  }
  return $telescope;
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
