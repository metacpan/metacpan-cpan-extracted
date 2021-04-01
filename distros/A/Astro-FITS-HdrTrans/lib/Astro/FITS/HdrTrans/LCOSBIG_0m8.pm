# -*-perl-*-

package Astro::FITS::HdrTrans::LCOSBIG_0m8;

=head1 NAME

Astro::FITS::HdrTrans::LCOSBIG_0m8 - LCO 0.8m SBIG translations

=head1 SYNOPSIS

  use Astro::FITS::HdrTrans::LCOSBIG_0m8;

  %gen = Astro::FITS::HdrTrans::LCOSBIG_0m8->translate_from_FITS( %hdr );

=head1 DESCRIPTION

This class provides a generic set of translations that are specific to
0.8m SBIG on Sedgwick at LCO.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

# Inherit from LCO base class.
use base qw/ Astro::FITS::HdrTrans::LCO /;

use vars qw/ $VERSION /;

$VERSION = "1.63";

# for a constant mapping, there is no FITS header, just a generic
# header that is constant
my %CONST_MAP = (
             );

# NULL mappings used to override base-class implementations.
my @NULL_MAP = qw/ /;

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

Returns "LCOSBIG".

=cut

sub this_instrument {
   return qr/^kb16/i;

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

=cut

=item B<to_DEC_SCALE>

Sets the declination scale in arcseconds per pixel.  The C<PIXSCALE>
is used when it's defined.  Otherwise it returns a default value of 0.280
arcsec/pixel, multiplied by second entry of C<CCDSUM> assuming this is
defined (1.0 otherwise)

=cut

sub to_DEC_SCALE {
   my $self = shift;
   my $FITS_headers = shift;
   my $decscale = 0.280;

# Assumes either x-y scales the same or the y corresponds to
# declination.
   my $ccdscale = $self->via_subheader( $FITS_headers, "PIXSCALE" );
   if ( defined $ccdscale ) {
      $decscale = $ccdscale;
   } else {
      my $ccdsum = $self->via_subheader( $FITS_headers, "CCDSUM" );
      if ( defined $ccdsum ) {
        my @binning = split( / /, $ccdsum );
        $decscale = $decscale * $binning[1];
      }
   }
   return $decscale;
}

=item B<to_DEC_TELESCOPE_OFFSET>

Sets the declination telescope offset in arcseconds.   It uses the
C<CAT-DEC> and C<DEC> keywords to derive the offset, and if either
does not exist, it returns a default of 0.0.

=cut

sub to_DEC_TELESCOPE_OFFSET {
   my $self = shift;
   my $FITS_headers = shift;
   my $decoffset = 0.0;
   if ( exists $FITS_headers->{"CAT-DEC"} && exists $FITS_headers->{DEC} ) {

# Obtain the reference and telescope declinations positions measured in degrees.
      my $refdec = $self->dms_to_degrees( $FITS_headers->{"CAT-DEC"} );
      my $dec = $self->dms_to_degrees( $FITS_headers->{DEC} );

# Find the offsets between the positions in arcseconds on the sky.
      $decoffset = 3600.0 * ( $dec - $refdec );
   }

# The sense is reversed compared with UKIRT, as these measure the
# places on the sky, not the motion of the telescope.
   return -1.0 * $decoffset;
}

=item B<to_RA_SCALE>

Sets the RA scale in arcseconds per pixel.  The C<PIXSCALE>
is used when it's defined.  Otherwise it returns a default value of 0.280
arcsec/pixel, multiplied by the first entry of C<CCDSUM> assuming this is
defined (1.0 otherwise)

=cut

sub to_RA_SCALE {
   my $self = shift;
   my $FITS_headers = shift;
   my $rascale = 0.280;

# Assumes either x-y scales the same or the x corresponds to
# ra.
   my $ccdscale = $self->via_subheader( $FITS_headers, "PIXSCALE" );
   if ( defined $ccdscale ) {
      $rascale = $ccdscale;
   } else {
      my $ccdsum = $self->via_subheader( $FITS_headers, "CCDSUM" );
      if ( defined $ccdsum ) {
        my @binning = split( / /, $ccdsum );
        $rascale = $rascale * $binning[0];
      }
   }
   return $rascale;
}


=item B<to_RA_TELESCOPE_OFFSET>

Sets the right-ascension telescope offset in arcseconds.   It uses the
C<CAT-RA>, C<RA>, C<CAT-DEC> keywords to derive the offset, and if any
of these keywords does not exist, it returns a default of 0.0.

=cut

sub to_RA_TELESCOPE_OFFSET {
   my $self = shift;
   my $FITS_headers = shift;
   my $raoffset = 0.0;

   if ( exists $FITS_headers->{"CAT-DEC"} &&
        exists $FITS_headers->{"CAT-RA"} && exists $FITS_headers->{RA} ) {

# Obtain the reference and telescope sky positions measured in degrees.
      my $refra = $self->hms_to_degrees( $FITS_headers->{"CAT-RA"} );
      my $ra = $self->hms_to_degrees( $FITS_headers->{RA} );
      my $refdec = $self->dms_to_degrees( $FITS_headers->{"CAT-DEC"} );

# Find the offset between the positions in arcseconds on the sky.
      $raoffset = 3600.0 * ( $ra - $refra ) * $self->cosdeg( $refdec );
   }

# The sense is reversed compared with UKIRT, as these measure the
# place son the sky, not the motion of the telescope.
   return -1.0 * $raoffset;
}

=item B<to_X_LOWER_BOUND>

Returns the lower bound along the X-axis of the area of the detector
as a pixel index.

=cut

sub to_X_LOWER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->getbounds( $FITS_headers );
   return $bounds[ 0 ];
}

=item B<to_X_UPPER_BOUND>

Returns the upper bound along the X-axis of the area of the detector
as a pixel index.

=cut

sub to_X_UPPER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->getbounds( $FITS_headers );
   return $bounds[ 1 ];
}

=item B<to_Y_LOWER_BOUND>

Returns the lower bound along the Y-axis of the area of the detector
as a pixel index.

=cut

sub to_Y_LOWER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->getbounds( $FITS_headers );
   return $bounds[ 2 ];
}


=item B<to_Y_UPPER_BOUND>

Returns the upper bound along the Y-axis of the area of the detector
as a pixel index.

=cut

sub to_Y_UPPER_BOUND {
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = $self->getbounds( $FITS_headers );
   return $bounds[ 3 ];
}

# Supplementary methods for the translations
# ------------------------------------------

# Obtain the detector bounds from a section in [xl:xu,yl:yu] syntax.
# If the TRIMSEC header is absent, use a default which corresponds
# to the useful part of the array (minus bias strips).
sub getbounds{
   my $self = shift;
   my $FITS_headers = shift;
   my @bounds = ( 11, 1536, 6, 1022 );
#   if ( $FITS_headers->{INSTRUME} =~ /^kb16/i ) {
#      @bounds = ( 11, 2037, 11, 2037 );
#   }
   if ( exists $FITS_headers->{CCDSUM} ) {
      my $binning = $FITS_headers->{CCDSUM};
      if ( $binning eq '1 1' ) {
         @bounds = ( 22, 3072, 12, 2044 );
      }
   }
   if ( exists $FITS_headers->{TRIMSEC} ) {
      my $section = $FITS_headers->{TRIMSEC};
      if ( $section !~ /UNKNOWN/i ) {
        $section =~ s/\[//;
        $section =~ s/\]//;
        $section =~ s/,/:/g;
        my @newbounds = split( /:/, $section );
        if (@newbounds == grep { $_ == 0 } @newbounds) {
          print "ERR: TRIMSEC all 0\n";
        } else {
          if ( $FITS_headers->{INSTRUME} !~ /^kbXX/i ) {
# Unless this is kb78 data (which has a bad TRIMSEC), update bounds array
            @bounds = @newbounds;
          }
        }
      }
   }
#   print("DBG: Bounds=@bounds\n");
   return @bounds;
}

=back

=head1 SEE ALSO

C<Astro::FITS::HdrTrans>, C<Astro::FITS::HdrTrans::LCO>.

=head1 AUTHOR

Tim Lister E<lt>tlister@lcogt.netE<gt>

=head1 COPYRIGHT

=cut

1;
