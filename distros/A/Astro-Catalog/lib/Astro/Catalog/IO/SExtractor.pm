package Astro::Catalog::IO::SExtractor;

=head1 NAME

Astro::Catalog::IO::SExtractor - SExtractor output catalogue I/O for
Astro::Catalog.

=head1 SYNOPSIS

$cat = Astro::Catalog::IO::SExtractor->_read_catalog( \@lines );

=head1 DESCRIPTION

This class provides read and write methods for catalogues written by
SExtractor, as long as they were written in ASCII_HEAD format. The
methods are not public and should, in general, only be called from the
C<Astro::Catalog> C<read_catalog> and C<write_catalog> methods.

=cut

use 5.006;
use warnings;
use warnings::register;
use Carp;
use strict;

# Bring in the Astro:: modules.
use Astro::Catalog;
use Astro::Catalog::Item;
use Astro::Catalog::Item::Morphology;
use Astro::Coords;

use Number::Uncertainty;
use Astro::Flux;
use Astro::FluxColor;
use Astro::Fluxes;

use base qw/ Astro::Catalog::IO::ASCII /;

use vars qw/ $VERSION $DEBUG /;

$VERSION = '4.35';
$DEBUG = 0;

=begin __PRIVATE_METHODS__

=head1 PRIVATE METHODS

These methods are usually called automatically from the C<Astro::Catalog>
constructor.

=over 4

=item B<_read_catalog>

Parses the catalogue lines and returns a new C<Astro::Catalog> object
containing the catalogue entries.

$cat = Astro::Catalog::IO::SExtractor->_read_catalog( \@lines );

The catalogue lines must include column definitions as written using
the 'ASCII_HEAD' catalogue type from SExtractor. This implementation
currently only supports reading information from the following output
parameters:

  NUMBER              id
  X_IMAGE
  Y_IMAGE
  X_PIXEL
  Y_PIXEL
  ERRX2_IMAGE
  ERRY2_IMAGE
  XWIN_IMAGE
  YWIN_IMAGE
  ERRX2WIN_IMAGE
  ERRY2WIN_IMAGE
  ALPHA_J2000         coords
  DELTA_J2000         coords
  MAG_ISO
  MAGERR_ISO
  FLUX_ISO
  FLUXERR_ISO
  MAG_ISOCOR
  MAGERR_ISOCOR
  FLUX_ISOCOR
  FLUXERR_ISOCOR
  MAG_APER
  MAGERR_APER
  FLUX_APER
  FLUXERR_APER
  MAG_AUTO
  MAGERR_AUTO
  FLUX_AUTO
  FLUXERR_AUTO
  MAG_BEST
  MAGERR_BEST
  FLUX_BEST
  FLUXERR_BEST
  ELLIPTICITY         morphology ellipticity
  THETA_IMAGE         morphology position_angle_pixel
  ERRTHETA_IMAGE      morphology position_angle_pixel
  THETA_SKY           morphology position_angle_world
  ERRTHETA_SKY        morphology position_angle_world
  B_IMAGE             morphology minor_axis_pixel
  ERRB_IMAGE          morphology minor_axis_pixel
  A_IMAGE             morphology major_axis_pixel
  ERRA_IMAGE          morphology major_axis_pixel
  B_WORLD             morphology minor_axis_world
  ERRB_WORLD          morphology minor_axis_world
  A_WORLD             morphology major_axis_world
  ERRA_WORLD          morphology major_axis_world
  ISOAREA_IMAGE       morphology area
  FWHM_IMAGE          morphology fwhm_pixel
  FWHM_WORLD          morphology fwhm_world
  FLAGS               quality

The pixel coordinate values are special cases. As there are only two
available methods to hold this information in an
C<Astro::Catalog::Item> object, x() and y(), and six potential values
to use, we must make a choice as to which value gets the nod. We
preferentially use the NDF pixel coordinates (which are only available
in output from the Starlink version of EXTRACTOR), then the windowed
coordinates that were made available in SExtractor v2.4.3, then the
standard coordinates.

For the flux and magnitude values, a separate C<Astro::Flux> object is
set up for each type with the flux type() equal to the SExtractor
keyword. For example, if the MAG_AUTO keyword exists in the catalogue,
then the output C<Astro::Catalog::Item> objects will have an
C<Astro::Flux> object of the type 'MAG_AUTO' in it.

There are optional named parameters. These are case-sensitive, and are:

=item Filter - An Astro::WaveBand object denoting the waveband that
the catalogue values were measured in.

=item Quality - If set, then only objects that have an extraction flag
in the FLAGS column equal to this value will be used to generate the
output catalogue. Otherwise, all objects will be used.

=cut

sub _read_catalog {
  my $class = shift;
  my $lines = shift;
  my %args = @_;

  if( ref( $lines ) ne 'ARRAY' ) {
    croak "Must supply catalogue contents as a reference to an array";
  }

  if( defined( $args{'Filter'} ) &&
      ! UNIVERSAL::isa( $args{'Filter'}, "Astro::WaveBand" ) ) {
    croak "Filter as passed to SExtractor->_read_catalog must be an Astro::WaveBand object";
  }

  my $filter;
  if( defined( $args{'Filter'} ) ) {
    $filter = $args{'Filter'}->natural;
  } else {
    $filter = 'unknown';
  }

  my $quality = $args{'Quality'};
  if( ! defined( $quality ) ) {
    $quality = -1;
  }

  my @lines = @$lines; # Dereference, make own copy.

  # Create an Astro::Catalog object;
  my $catalog = new Astro::Catalog();

  # Set up columns.
  my $id_column = -1;
  my $x_column = -1;
  my $x_pixel_column = -1;
  my $xerr_column = -1;
  my $xwin_column = -1;
  my $xwinerr_column = -1;
  my $y_column = -1;
  my $y_pixel_column = -1;
  my $yerr_column = -1;
  my $ywin_column = -1;
  my $ywinerr_column = -1;
  my $ra_column = -1;
  my $dec_column = -1;
  my $mag_iso_column = -1;
  my $magerr_iso_column = -1;
  my $flux_iso_column = -1;
  my $fluxerr_iso_column = -1;
  my $flux_isocor_column = -1;
  my $fluxerr_isocor_column = -1;
  my $mag_isocor_column = -1;
  my $magerr_isocor_column = -1;
  my $flux_aper1_column = -1;
  my $fluxerr_aper1_column = -1;
  my $mag_aper1_column = -1;
  my $magerr_aper1_column = -1;
  my $flux_aper2_column = -1;
  my $fluxerr_aper2_column = -1;
  my $mag_aper2_column = -1;
  my $magerr_aper2_column = -1;
  my $flux_auto_column = -1;
  my $fluxerr_auto_column = -1;
  my $mag_auto_column = -1;
  my $magerr_auto_column = -1;
  my $flux_best_column = -1;
  my $fluxerr_best_column = -1;
  my $mag_best_column = -1;
  my $magerr_best_column = -1;
  my $ell_column = -1;
  my $posang_pixel_column = -1;
  my $posangerr_pixel_column = -1;
  my $posang_world_column = -1;
  my $posangerr_world_column = -1;
  my $minor_pixel_column = -1;
  my $minorerr_pixel_column = -1;
  my $major_pixel_column = -1;
  my $majorerr_pixel_column = -1;
  my $minor_world_column = -1;
  my $minorerr_world_column = -1;
  my $major_world_column = -1;
  my $majorerr_world_column = -1;
  my $area_column = -1;
  my $fwhm_pixel_column = -1;
  my $fwhm_world_column = -1;
  my $flag_column = -1;

  # Loop through the lines.
  for ( @lines ) {
    my $line = $_;

    # If we're on a column line that starts with a #, check to see
    # if it's describing where the X, Y, RA, or Dec position is in
    # the table, or the object number, or the flux, or the error in
    # flux.
    if( $line =~ /^#/ ) {
      my @column = split( /\s+/, $line );
      if( $column[2] =~ /^NUMBER/ ) {
        $id_column = $column[1] - 1;
        print "ID column is $id_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^X_IMAGE/ ) {
        $x_column = $column[1] - 1;
        print "X_IMAGE column is $x_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^Y_IMAGE/ ) {
        $y_column = $column[1] - 1;
        print "Y_IMAGE column is $y_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^X_PIXEL/ ) {
        $x_pixel_column = $column[1] - 1;
        print "X_PIXEL column is $x_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^Y_PIXEL/ ) {
        $y_pixel_column = $column[1] - 1;
        print "Y_PIXEL column is $y_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRX2_IMAGE/ ) {
        $xerr_column = $column[1] - 1;
        print "X ERROR column is $xerr_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRY2_IMAGE/ ) {
        $yerr_column = $column[1] - 1;
        print "Y ERROR column is $yerr_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^XWIN_IMAGE/ ) {
        $xwin_column = $column[1] - 1;
        print "XWIN_IMAGE column is $xwin_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRX2WIN_IMAGE/ ) {
        $xwinerr_column = $column[1] - 1;
        print "ERRX2WIN_IMAGE column is $xwinerr_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^YWIN_IMAGE/ ) {
        $ywin_column = $column[1] - 1;
        print "YWIN_IMAGE column is $ywin_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRY2WIN_IMAGE/ ) {
        $ywinerr_column = $column[1] - 1;
        print "ERRY2WIN_IMAGE column is $ywinerr_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ALPHA_J2000/ ) {
        $ra_column = $column[1] - 1;
        print "RA column is $ra_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^DELTA_J2000/ ) {
        $dec_column = $column[1] - 1;
        print "DEC column is $dec_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAG_ISO$/ ) {
        $mag_iso_column = $column[1] - 1;
        print "MAG_ISO column is $mag_iso_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAGERR_ISO$/ ) {
        $magerr_iso_column = $column[1] - 1;
        print "MAGERR_ISO column is $magerr_iso_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUX_ISO$/ ) {
        $flux_iso_column = $column[1] - 1;
        print "FLUX_ISO column is $flux_iso_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUXERR_ISO$/ ) {
        $fluxerr_iso_column = $column[1] - 1;
        print "FLUXERR_ISO column is $fluxerr_iso_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUX_ISOCOR/ ) {
        $flux_isocor_column = $column[1] - 1;
        print "FLUX_ISOCOR column is $flux_isocor_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUXERR_ISOCOR/ ) {
        $fluxerr_isocor_column = $column[1] - 1;
        print "FLUXERR_ISOCOR column is $fluxerr_isocor_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAG_ISOCOR/ ) {
        $mag_isocor_column = $column[1] - 1;
        print "MAG_ISOCOR column is $mag_isocor_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAGERR_ISOCOR/ ) {
        $magerr_isocor_column = $column[1] - 1;
        print "MAGERR_ISOCOR column is $magerr_isocor_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUX_APER/ ) {
        $flux_aper1_column = $column[1] - 1;
        print "FLUX_APER column is $flux_aper1_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUXERR_APER/ ) {
        $fluxerr_aper1_column = $column[1] - 1;
        print "FLUXERR_APER column is $fluxerr_aper1_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAG_APER/ ) {
        $mag_aper1_column = $column[1] - 1;
        print "MAG_APER column is $mag_aper1_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAGERR_APER/ ) {
        $magerr_aper1_column = $column[1] - 1;
        print "MAGERR_APER column is $magerr_aper1_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUX_AUTO/ ) {
        $flux_auto_column = $column[1] - 1;
        print "FLUX_AUTO column is $flux_auto_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUXERR_AUTO/ ) {
        $fluxerr_auto_column = $column[1] - 1;
        print "FLUXERR_AUTO column is $fluxerr_auto_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAG_AUTO/ ) {
        $mag_auto_column = $column[1] - 1;
        print "MAG_AUTO column is $mag_auto_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAGERR_AUTO/ ) {
        $magerr_auto_column = $column[1] - 1;
        print "MAGERR_AUTO column is $magerr_auto_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUX_BEST/ ) {
        $flux_best_column = $column[1] - 1;
        print "FLUX_BEST column is $flux_best_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLUXERR_BEST/ ) {
        $fluxerr_best_column = $column[1] - 1;
        print "FLUXERR_BEST column is $fluxerr_best_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAG_BEST/ ) {
        $mag_best_column = $column[1] - 1;
        print "MAG_BEST column is $mag_best_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^MAGERR_BEST/ ) {
        $magerr_best_column = $column[1] - 1;
        print "MAGERR_BEST_COLUMN is $magerr_best_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ELLIPTICITY/ ) {
        $ell_column = $column[1] - 1;
        print "ELLIPTICITY column is $ell_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^THETA_IMAGE/ ) {
        $posang_pixel_column = $column[1] - 1;
        print "THETA_IMAGE column is $posang_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRTHETA_IMAGE/ ) {
        $posangerr_pixel_column = $column[1] - 1;
        print "ERRTHETA_IMAGE column is $posangerr_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^THETA_SKY/ ) {
        $posang_world_column = $column[1] - 1;
        print "THETA_SKY column is $posang_world_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRTHETA_SKY/ ) {
        $posangerr_world_column = $column[1] - 1;
        print "ERRTHETA_SKY column is $posangerr_world_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^B_IMAGE/ ) {
        $minor_pixel_column = $column[1] - 1;
        print "B_IMAGE column is $minor_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRB_IMAGE/ ) {
        $minorerr_pixel_column = $column[1] - 1;
        print "ERRB_IMAGE column is $minorerr_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^A_IMAGE/ ) {
        $major_pixel_column = $column[1] - 1;
        print "A_IMAGE column is $major_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRA_IMAGE/ ) {
        $majorerr_pixel_column = $column[1] - 1;
        print "ERRA_IMAGE column is $majorerr_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^B_WORLD/ ) {
        $minor_world_column = $column[1] - 1;
        print "B_WORLD column is $minor_world_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRB_WORLD/ ) {
        $minorerr_world_column = $column[1] - 1;
        print "ERRB_WORLD column is $minorerr_world_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^A_WORLD/ ) {
        $major_world_column = $column[1] - 1;
        print "A_WORLD column is $major_world_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ERRA_WORLD/ ) {
        $majorerr_world_column = $column[1] - 1;
        print "ERRA_WORLD column is $majorerr_world_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^ISOAREA_IMAGE/ ) {
        $area_column = $column[1] - 1;
        print "AREA column is $area_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FWHM_IMAGE/ ) {
        $fwhm_pixel_column = $column[1] - 1;
        print "FWHM_IMAGE column is $fwhm_pixel_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FWHM_WORLD/ ) {
        $fwhm_world_column = $column[1] - 1;
        print "FWHM_WORLD column is $fwhm_world_column\n" if $DEBUG;

      } elsif( $column[2] =~ /^FLAGS/ ) {
        $flag_column = $column[1] - 1;
        print "FLAGS column is $flag_column\n" if $DEBUG;

      }
      next;
    }

    # Remove leading whitespace and go to the next line if the
    # current one is blank.
    $line =~ s/^\s+//;
    next if length( $line ) == 0;

    # Form an array of the fields in the catalogue.
    my @fields = split( /\s+/, $line );

    # Don't deal with this object if our requested quality is not -1
    # and the quality of the object is not equal to the requested
    # quality and we have a quality flag for this object.
    if( ( $quality != -1 ) &&
        ( $flag_column != -1 ) &&
        ( $fields[$flag_column] != $quality ) ) {
      next;
    }

    # Create a temporary Astro::Catalog::Item object.
    my $star = new Astro::Catalog::Item();

    # Grab the coordinates, forming an Astro::Coords object., but only
    # if the RA and Dec columns are defined.
    if( $ra_column != -1 &&
        $dec_column != -1 ) {
      my $coords = new Astro::Coords( type => 'J2000',
                                      ra => $fields[$ra_column],
                                      dec => $fields[$dec_column],
                                      name => ( $id_column != -1 ? $fields[$id_column] : undef ),
                                      units => 'degrees',
                                    );
      $star->coords( $coords );
    }

    if( $flag_column != -1 ) {
      $star->quality( $fields[$flag_column] );
    } else {
      $star->quality( 0 );
    }

    if( $id_column != -1 ) {
      $star->id( $fields[$id_column] );
    }

    # Set up the various flux and magnitude measurements.
    if( $mag_iso_column != -1 ) {
      my $num;
      if( $magerr_iso_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$mag_iso_column],
                                        Error => $fields[$magerr_iso_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$mag_iso_column] );
      }
      my $mag_iso = new Astro::Flux( $num, 'MAG_ISO', $filter );
      $star->fluxes( new Astro::Fluxes( $mag_iso ) );
    }
    if( $flux_iso_column != -1 ) {
      my $num;
      if( $fluxerr_iso_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$flux_iso_column],
                                        Error => $fields[$fluxerr_iso_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$flux_iso_column] );
      }
      my $flux_iso = new Astro::Flux( $num, 'FLUX_ISO', $filter );
      $star->fluxes( new Astro::Fluxes( $flux_iso ) );
    }

    if( $mag_isocor_column != -1 ) {
      my $num;
      if( $magerr_isocor_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$mag_isocor_column],
                                        Error => $fields[$magerr_isocor_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$mag_isocor_column] );
      }
      my $mag_isocor = new Astro::Flux( $num, 'MAG_ISOCOR', $filter );
      $star->fluxes( new Astro::Fluxes( $mag_isocor ) );
    }
    if( $flux_isocor_column != -1 ) {
      my $num;
      if( $fluxerr_isocor_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$flux_isocor_column],
                                        Error => $fields[$fluxerr_isocor_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$flux_isocor_column] );
      }
      my $flux_isocor = new Astro::Flux( $num, 'FLUX_ISOCOR', $filter );
      $star->fluxes( new Astro::Fluxes( $flux_isocor ) );
    }

    if( $mag_aper1_column != -1 ) {
      my $num;
      if( $magerr_aper1_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$mag_aper1_column],
                                        Error => $fields[$magerr_aper1_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$mag_aper1_column] );
      }
      my $mag_aper1 = new Astro::Flux( $num, 'MAG_APER1', $filter );
      $star->fluxes( new Astro::Fluxes( $mag_aper1 ) );
    }
    if( $flux_aper1_column != -1 ) {
      my $num;
      if( $fluxerr_aper1_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$flux_aper1_column],
                                        Error => $fields[$fluxerr_aper1_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$flux_aper1_column] );
      }
      my $flux_aper1 = new Astro::Flux( $num, 'FLUX_APER1', $filter );
      $star->fluxes( new Astro::Fluxes( $flux_aper1 ) );
    }

    if( $mag_auto_column != -1 ) {
      my $num;
      if( $magerr_auto_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$mag_auto_column],
                                        Error => $fields[$magerr_auto_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$mag_auto_column] );
      }
      my $mag_auto = new Astro::Flux( $num, 'MAG_AUTO', $filter );
      $star->fluxes( new Astro::Fluxes( $mag_auto ) );
    }
    if( $flux_auto_column != -1 ) {
      my $num;
      if( $fluxerr_auto_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$flux_auto_column],
                                        Error => $fields[$fluxerr_auto_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$flux_auto_column] );
      }
      my $flux_auto = new Astro::Flux( $num, 'FLUX_AUTO', $filter );
      $star->fluxes( new Astro::Fluxes( $flux_auto ) );
    }

    if( $mag_best_column != -1 ) {
      my $num;
      if( $magerr_best_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$mag_best_column],
                                        Error => $fields[$magerr_best_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$mag_best_column] );
      }
      my $mag_best = new Astro::Flux( $num, 'MAG_BEST', $filter );
      $star->fluxes( new Astro::Fluxes( $mag_best ) );
    }
    if( $flux_best_column != -1 ) {
      my $num;
      if( $fluxerr_best_column != -1 ) {
        $num = new Number::Uncertainty( Value => $fields[$flux_best_column],
                                        Error => $fields[$fluxerr_best_column] );
      } else {
        $num = new Number::Uncertainty( Value => $fields[$flux_best_column] );
      }
      my $flux_best = new Astro::Flux( $num, 'FLUX_BEST', $filter );
      $star->fluxes( new Astro::Fluxes( $flux_best ) );
    }

    # Set the x and y coordinates. Preferentially use the NDF pixel
    # coordinates, then the windowed coordinates, then the standard
    # coordinates.
    if( $x_pixel_column != -1 ) {
      $star->x( $fields[$x_pixel_column] );
    } elsif( $xwin_column != -1 ) {
      $star->x( $fields[$xwin_column] );
    } elsif( $x_column != -1 ) {
      $star->x( $fields[$x_column] );
    }
    if( $y_pixel_column != -1 ) {
      $star->y( $fields[$y_pixel_column] );
    } elsif( $ywin_column != -1 ) {
      $star->y( $fields[$ywin_column] );
    } elsif( $x_column != -1 ) {
      $star->y( $fields[$y_column] );
    }

    # Set up the star's morphology.
    my $ellipticity;
    my $position_angle_pixel;
    my $position_angle_world;
    my $major_axis_pixel;
    my $minor_axis_pixel;
    my $major_axis_world;
    my $minor_axis_world;
    my $fwhm_pixel;
    my $fwhm_world;
    my $area;
    if( $ell_column != -1 ) {
      $ellipticity = new Number::Uncertainty( Value => $fields[$ell_column] );
    }
    if( $posang_pixel_column != -1 ) {
      if( $posangerr_pixel_column != -1 ) {
        $position_angle_pixel = new Number::Uncertainty( Value => $fields[$posang_pixel_column],
                                                         Error => $fields[$posangerr_pixel_column] );
      } else {
        $position_angle_pixel = new Number::Uncertainty( Value => $fields[$posang_pixel_column] );
      }
    }
    if( $posang_world_column != -1 ) {
      if( $posangerr_world_column != -1 ) {
        $position_angle_world = new Number::Uncertainty( Value => $fields[$posang_world_column],
                                                         Error => $fields[$posangerr_world_column] );
      } else {
        $position_angle_world = new Number::Uncertainty( Value => $fields[$posang_world_column] );
      }
    }
    if( $major_pixel_column != -1 ) {
      if( $majorerr_pixel_column != -1 ) {
        $major_axis_pixel = new Number::Uncertainty( Value => $fields[$major_pixel_column],
                                                     Error => $fields[$majorerr_pixel_column] );
      } else {
        $major_axis_pixel = new Number::Uncertainty( Value => $fields[$major_pixel_column] );
      }
    }
    if( $major_world_column != -1 ) {
      if( $majorerr_world_column != -1 ) {
        $major_axis_world = new Number::Uncertainty( Value => $fields[$major_world_column],
                                                     Error => $fields[$majorerr_world_column] );
      } else {
        $major_axis_world = new Number::Uncertainty( Value => $fields[$major_world_column] );
      }
    }
    if( $minor_pixel_column != -1 ) {
      if( $minorerr_pixel_column != -1 ) {
        $minor_axis_pixel = new Number::Uncertainty( Value => $fields[$minor_pixel_column],
                                                     Error => $fields[$minorerr_pixel_column] );
      } else {
        $minor_axis_pixel = new Number::Uncertainty( Value => $fields[$minor_pixel_column] );
      }
    }
    if( $minor_world_column != -1 ) {
      if( $minorerr_world_column != -1 ) {
        $minor_axis_world = new Number::Uncertainty( Value => $fields[$minor_world_column],
                                                     Error => $fields[$minorerr_world_column] );
      } else {
        $minor_axis_world = new Number::Uncertainty( Value => $fields[$minor_world_column] );
      }
    }
    if( $area_column != -1 ) {
      $area = new Number::Uncertainty( Value => $fields[$area_column] );
    }
    if( $fwhm_pixel_column != -1 ) {
      $fwhm_pixel = new Number::Uncertainty( Value => $fields[$fwhm_pixel_column] );
    }
     if( $fwhm_world_column != -1 ) {
      $fwhm_world = new Number::Uncertainty( Value => $fields[$fwhm_world_column] );
    }
    my $morphology = new Astro::Catalog::Item::Morphology( ellipticity => $ellipticity,
                                                           position_angle_pixel => $position_angle_pixel,
                                                           position_angle_world => $position_angle_world,
                                                           major_axis_pixel => $major_axis_pixel,
                                                           minor_axis_pixel => $minor_axis_pixel,
                                                           major_axis_world => $major_axis_world,
                                                           minor_axis_world => $minor_axis_world,
                                                           area => $area,
                                                           fwhm_pixel => $fwhm_pixel,
                                                           fwhm_world => $fwhm_world,
                                                         );
    $star->morphology( $morphology );

    # Push the star onto the catalog.
    $catalog->pushstar( $star );
  }

  $catalog->origin( 'IO::SExtractor' );
  return $catalog;
}

=item B<_write_catalog>

Create an output catalogue in the SExtractor ASCII_HEAD format and
return the lines in an array.

  $ref = Astro::Catalog::IO::SExtractor->_write_catalog( $catalog );

Argument is an C<Astro::Catalog> object.

This method currently only returns the ID, X, Y, RA and Dec values in
the returned strings, in that order.

=cut

sub _write_catalog {
  croak ( 'Usage: _write_catalog( $catalog, [%opts] ') unless scalar(@_) >= 1;
  my $class = shift;
  my $catalog = shift;

  my @output;

# First, the header. What we write to the header depends on what
# values we have for our objects, so check for ID, X, Y, RA, and Dec
# values.
  my $write_id  = 0;
  my $write_x   = 0;
  my $write_y   = 0;
  my $write_ra  = 0;
  my $write_dec = 0;

  my @stars = $catalog->stars();

  if( defined( $stars[0]->id ) ) {
    $write_id = 1;
  }
  if( defined( $stars[0]->x ) ) {
    $write_x = 1;
  }
  if( defined( $stars[0]->y ) ) {
    $write_y = 1;
  }
  if( defined( $stars[0]->coords->ra ) ) {
    $write_ra = 1;
  }
  if( defined( $stars[0]->coords->dec ) ) {
    $write_dec = 1;
  }

# Now for the header.
  my $pos = 1;
  if( $write_id ) {
    push @output, "#   $pos NUMBER         Running object number";
    $pos++;
  }
  if( $write_x ) {
    push @output, "#   $pos X_IMAGE        Object position along x                     [pixel]";
    $pos++;
  }
  if( $write_y ) {
    push @output, "#   $pos Y_IMAGE        Object position along y                     [pixel]";
    $pos++;
  }
  if( $write_ra ) {
    push @output, "#   $pos ALPHA_J2000    Right ascension of barycenter (J2000)       [deg]";
    $pos++;
  }
  if( $write_dec ) {
    push @output, "#   $pos DELTA_J2000    Declination of barycenter (J2000)           [deg]";
    $pos++;
  }

# Now go through the objects.
  foreach my $star ( @stars ) {

    my $output_string = "";

    if( $write_id ) {
      $output_string .= $star->id . " ";
    }
    if( $write_x ) {
      $output_string .= $star->x . " ";
    }
    if( $write_y ) {
      $output_string .= $star->y . " ";
    }
    if( $write_ra ) {
      $output_string .= $star->coords->ra->degrees . " ";
    }
    if( $write_dec ) {
      $output_string .= $star->coords->dec->degrees . " ";
    }

    push @output, $output_string;
  }

# And return!
  return \@output;

}

=back

=head1 FORMAT

The SExtractor ASCII_HEAD format consists of a header block and a
data block. The header block is made up of comments denoted by a
# as the first character. These comments describe the column number,
output parameter name, description of the output paramter, and units
of the output parameter enclosed in square brackets. The data block
is space-delimited.

=head1 SEE ALSO

L<Astro::Catalog>

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the terms of the GNU Public License.

=head1 AUTHORS

Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=cut

1;
