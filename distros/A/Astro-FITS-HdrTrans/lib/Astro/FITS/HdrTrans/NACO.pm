package Astro::FITS::HdrTrans::NACO;

=head1 NAME

Astro::FITS::HdrTrans::NACO - ESO NACO translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::NACO;

  %gen = Astro::FITS::HdrTrans::NACO->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
the NACO camera of the European Southern Observatory.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from ESO
use base qw/ Astro::FITS::HdrTrans::ESO /;

use vars qw/ $VERSION /;

$VERSION = "1.63";

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

Returns "NAOS+CONICA".

=cut

sub this_instrument {
  return "NAOS+CONICA";
}

=back

=head1 COMPLEX CONVERSIONS

=over 4

=cut

sub to_DEC_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $scale;
  my $scale_def = 0.0271;
  if ( exists ( $FITS_headers->{CDELT2} ) ) {
    $scale = $FITS_headers->{CDELT2};
  } elsif ( exists ( $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} ) ) {
    $scale = $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} / 3600.0;
  }
  $scale = defined( $scale ) ? $scale: $scale_def;
  return $scale;
}

# If the telescope ofset exists in arcsec, then use it.  Otherwise
# convert the Cartesian offsets to equatorial offsets.
sub to_DEC_TELESCOPE_OFFSET {
  my $self = shift;
  my $FITS_headers = shift;
  my $decoffset = 0.0;
  if ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETD"} ) {
    $decoffset = $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETD"};

  } elsif ( exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETX"} &&
            exists $FITS_headers->{"HIERARCH.ESO.SEQ.CUMOFFSETY"} ) {

    my $pixscale = 0.0271;
    if ( exists $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} ) {
      $pixscale = $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"};
    }

    # Sometimes the first cumulative offsets are non-zero contrary to the
    # documentation.
    my $expno = 1;
    if ( exists $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"} ) {
      $expno = $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"};
    }
    my ( $x_as, $y_as );
    if ( $expno == 1 ) {
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

  if ( $template =~ /_img_obs_AutoJitter/ ||
       $template =~ /_img_obs_GenericOffset/ ) {
    $recipe = "JITTER_SELF_FLAT";

  } elsif ( $template =~ /_img_cal_StandardStar/ ||
            $template =~ /_img_cal_StandardStarOff/ ||
            $template =~ /_img_tec_Zp/ ||
            $template =~ /_img_tec_ZpNoChop/ ||
            $seq =~ /_img_cal_StandardStar/ ||
            $seq =~ /_img_cal_StandardStarOff/ ) {
    $recipe = "JITTER_SELF_FLAT_APHOT";

  } elsif ( $template =~ /_img_obs_AutoJitterOffset/ ||
            $template =~ /_img_obs_FixedSkyOffset/ ) {
    $recipe = "CHOP_SKY_JITTER";

    # The following two perhaps should be using NOD_CHOP and a variant of
    # NOD_CHOP_APHOT to cope with the three source images (central double
    # flux) rather than four.
  } elsif ( $template =~ /_img_obs_AutoChopNod/ ||
            $seq =~ /_img_obs_AutoChopNod/ ) {
    $recipe = "NOD_SELF_FLAT_NO_MASK";

  } elsif ( $template =~ /_img_cal_ChopStandardStar/ ) {
    $recipe = "NOD_SELF_FLAT_NO_MASK_APHOT";

  } elsif ( $template =~ /_cal_Darks/ ||
            $seq =~ /_cal_Darks/ ) {
    $recipe = "REDUCE_DARK";

  } elsif ( $template =~ /_img_cal_TwFlats/ ||
            $template =~ /_img_cal_SkyFlats/ ) {
    $recipe = "SKY_FLAT_MASKED";

  } elsif ( $template =~ /_img_cal_LampFlats/ ) {
    $recipe = "LAMP_FLAT";

    # Imaging spectroscopy.  There appears to be no distinction
    # for flats from target, hence no division into POL_JITTER and
    # SKY_FLAT_POL.
  } elsif ( $template =~ /_pol_obs_GenericOffset/ ||
            $template =~ /_pol_cal_StandardStar/ ) {
    $recipe = "POL_JITTER";

  } elsif ( $template =~ /_pol_obs_AutoChopNod/ ||
            $template =~ /_pol_cal_ChopStandardStar/ ) {
    $recipe = "POL_NOD_CHOP";

  } elsif ( $template =~ /_pol_cal_LampFlats/ ) {
    $recipe = "POL_JITTER";

    # Spectroscopy.  EXTENDED_SOURCE may be more appropriate for
    # the NACO_spec_obs_GenericOffset template.
  } elsif ( $template =~ /_spec_obs_AutoNodOnSlit/ ||
            $template =~ /_spec_obs_GenericOffset/ ||
            $template =~ /_spec_obs_AutoChopNod/ ) {
    $recipe = "POINT_SOURCE";

  } elsif ( $template =~ /_spec_cal_StandardStar/ ||
            $template =~ /_spec_cal_StandardStarNod/ ||
            $template =~ /_spec_cal_AutoNodOnSlit/  ) {
    $recipe = "STANDARD_STAR";

  } elsif ( $template =~ /_spec_cal_NightCalib/ ) {
    $recipe = "REDUCE_SINGLE_FRAME";

  } elsif ( $template =~ /_spec_cal_Arcs/ ||
            $seq =~ /_spec_cal_Arcs/ ) {
    $recipe = "REDUCE_ARC";

  } elsif ( $template =~ /_spec_cal_LampFlats/ ) {
    $recipe = "LAMP_FLAT";
  }
  return $recipe;
}


# Filters appear to be in wheels 4 to 6.  It appears the filter
# in just one of the three.
sub to_FILTER {
  my $self = shift;
  my $FITS_headers = shift;
  my $filter = "empty";

  my $id = 4;
  while ( $filter eq "empty" && $id < 7 ) {
    if ( exists $FITS_headers->{"HIERARCH.ESO.INS.OPTI${id}.NAME"} ) {
      $filter = $FITS_headers->{"HIERARCH.ESO.INS.OPTI${id}.NAME"};
    }
    $id++;
  }
  return $filter;
}

# Fixed value for the gain, as that's all the documentation gives.
# the readout mode.
sub to_GAIN {
  10;
}

# Using Table 10 of the NACO USer's Guide.
sub to_GRATING_DISPERSION {
  my $self = shift;
  my $FITS_headers = shift;
  my $dispersion = 0.0;
  if ( exists $FITS_headers->{CDELT1} ) {
    $dispersion = $FITS_headers->{CDELT1};
  } else {
    if ( exists $FITS_headers->{"HIERARCH.ESO.INS.GRAT.NAME"} &&
         exists $FITS_headers->{"HIERARCH.ESO.OPTI7.NAME"} ) {
      my $order = $FITS_headers->{"HIERARCH.ESO.INS.GRAT.ORDER"};
      my $camera = $FITS_headers->{"HIERARCH.ESO.OPTI7.NAME"};

      if ( $camera eq "S54" ) {
        if ( $order == 1 ) {
          $dispersion = 1.98e-3;
        } elsif ( $order == 2 ) {
          $dispersion = 6.8e-4;
        } elsif ( $order == 3 ) {
          $dispersion = 9.7e-4;
        }

      } elsif ( $camera eq "L54" ) {
        $dispersion = 3.20e-3;

      } elsif ( $camera eq "S27" ) {
        if ( $order == 1 ) {
          $dispersion = 9.5e-4;
        } elsif ( $order == 2 ) {
          $dispersion = 5.0e-4;
        }
      }
    }
  }
  return $dispersion;
}

sub to_RA_SCALE {
  my $self = shift;
  my $FITS_headers = shift;
  my $scale;
  my $scale_def = -0.0271;
  if ( exists ( $FITS_headers->{CDELT1} ) ) {
    $scale = $FITS_headers->{CDELT1};
  } elsif ( exists ( $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} ) ) {
    $scale = - $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} / 3600.0;
  }
  $scale = defined( $scale ) ? $scale: $scale_def;
  return $scale;
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

    my $pixscale = 0.0271;
    if ( exists $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"} ) {
      $pixscale = $FITS_headers->{"HIERARCH.ESO.INS.PIXSCALE"};
    }

    # Sometimes the first cumulative offsets are non-zero contrary to the
    # documentation.
    my $expno = 1;
    if ( exists $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"} ) {
      $expno = $FITS_headers->{"HIERARCH.ESO.TPL.EXPNO"};
    }
    my ( $x_as, $y_as );
    if ( $expno == 1 ) {
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

# Just translate to shorter strings for ease and to fit within the
# night log.
sub to_SPEED_GAIN {
  my $self = shift;
  my $FITS_headers = shift;
  my $spd_gain = "HighSens";
  my $detector_mode = exists( $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} ) ?
    $FITS_headers->{"HIERARCH.ESO.DET.MODE.NAME"} : $spd_gain;
  if ( $detector_mode eq "HighSensitivity" ) {
    $spd_gain = "HighSens";
  } elsif ( $detector_mode eq "HighDynamic" ) {
    $spd_gain = "HighDyn";
  } elsif ( $detector_mode eq "HighBackground" ) {
    $spd_gain = "HighBack";
  }
  return $spd_gain;
}

# Translate to the SLALIB name for reference frame in spectroscopy.
sub to_TELESCOPE {
  my $self = shift;
  my $FITS_headers = shift;
  my $telescope = "VLT4";
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
