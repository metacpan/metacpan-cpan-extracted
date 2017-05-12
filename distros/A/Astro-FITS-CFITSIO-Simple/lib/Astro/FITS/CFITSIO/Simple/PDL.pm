package Astro::FITS::CFITSIO::Simple::PDL;

use 5.008002;
use strict;
use warnings;

use Carp;

use PDL::Core;

# workaround for A::F::C v 1.02
BEGIN {
  use Astro::FITS::CFITSIO qw/ :constants/;
  eval { LONGLONG_IMG() };

  *LONGLONG_IMG = sub { 64 }
    if $@;
}

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Astro::FITS::CFITSIO::PDL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
  pdl2cfitsio
  fits2pdl_coltype
  fits2pdl_imgtype
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.18';

our %PDL2CFITSIO =
  (
   float  => [ TDOUBLE, TFLOAT ],
   double => [ TDOUBLE, TFLOAT ],
   short  => [ TSHORT, TINT, TLONG ],
   long   => [ TSHORT, TINT, TLONG  ],
   ushort => [ TBYTE, TUSHORT, TUINT, TULONG ],
   byte   => [ TBYTE, TUSHORT, TUINT, TULONG ],
  );

sub pdl2cfitsio
{
  my ( $arg ) = @_;

  my $pdl_type;

  if (UNIVERSAL::isa($arg,'PDL')) {
    $pdl_type = $arg->type;

  } elsif (UNIVERSAL::isa($arg,'PDL::Type')) {
    $pdl_type = $arg;

  } else {
    die "argument should be a PDL object or PDL::Type token\n";
  }

  # test for real datatypes
  exists $PDL2CFITSIO{ $pdl_type } or
    die "PDL type $pdl_type not supported";


  my $pdl_size = PDL::Core::howbig($pdl_type);

  foreach ( @{$PDL2CFITSIO{ $pdl_type }} )
  {
    return $_ if $pdl_size == Astro::FITS::CFITSIO::sizeof_datatype( $_ );
  }

  die "no CFITSIO type for PDL type $pdl_type\n";
}


##########################################################################
#
# Columns




our %FITS2CFITSIO_COL =
  (
   'X' => TBIT,
   'B' => TBYTE,
   'L' => TLOGICAL,
   'A' => TSTRING,
   'I' => TSHORT,
   'J' => TLONG,
   'E' => TFLOAT,
   'D' => TDOUBLE,
   'C' => TCOMPLEX,
   'M' => TDBLCOMPLEX,
   'S' => TSBYTE,
#   'K' => TLONGLONG,
  );

our %CFITSIO2PDL_COL =
  (
   TSTRING()    => undef,   # A
   TUSHORT()    => ushort,  #
   TSHORT()     => short,   # I
   TLONG()      => long,    # J
   TINT()       => long,    # J
   TUINT()	=> long,    # incorrect, but gotta do something!
   TULONG()	=> long,    # incorrect, but gotta do something!
   TFLOAT()     => float,   # E
   TDOUBLE()    => double,  # D
   TBIT()       => byte,    # X
   TLOGICAL()   => byte,    # L
   TBYTE()      => byte,    # B
   TSBYTE()	=> byte,    # S
#   TLONGLONG()  => longlong #
  );

# we don't support these (yet?)
  #define TCOMPLEX     83  /* complex (pair of floats)   'C' */
  #define TDBLCOMPLEX 163  /* double complex (2 doubles) 'M' */
  #define TUINT        30  /* unsigned int                   */
  #define TULONG       40  /* unsigned long                  */

sub fits2pdl_coltype {

  my ( $fits_type ) = @_;

  my $nfits_type = 
    exists $FITS2CFITSIO_COL{$fits_type} ?
      $FITS2CFITSIO_COL{$fits_type} : $fits_type;

  croak( "unsupported CFITSIO/FITS type: $fits_type\n" )
    unless exists $CFITSIO2PDL_COL{$nfits_type};


  return $CFITSIO2PDL_COL{$nfits_type};
}


##########################################################################
#
# Images


our %CFITSIO2PDL_IMG =
  (
   BYTE_IMG()   => byte,
   SHORT_IMG()  => short,
   LONG_IMG()   => long,
   FLOAT_IMG()  => float,
   DOUBLE_IMG() => double
  );

# we don't support these (yet?)
#define LONGLONG_IMG  64

sub fits2pdl_imgtype {

  my ( $fits_type ) = @_;

  croak( "unsupported Image CFITSIO/FITS type: $fits_type\n" )
    unless exists $CFITSIO2PDL_IMG{$fits_type};

  $CFITSIO2PDL_IMG{$fits_type};
}




###################################################################



1;
__END__

=head1 NAME

Astro::FITS::CFITSIO::PDL - support routines for using CFITSIO and PDL

=head1 SYNOPSIS

  use Astro::FITS::CFITSIO::PDL;


=head1 DESCRIPTION

This module provides utility routines to make CFITSIO and PDL more
friendly to each other.

=head2 Functions

=over

=item pdl2cfitsio

	$cfitsio_type = pdl2fits_type($piddle);
	$cfitsio_type = pdl2fits_type(long); # or short, or float, etc.

PDL datatypes are always guaranteed to be the same size on all
architectures, whereas CFITSIO datatypes (TLONG, for example), will
vary on some architectures since they correspond to the C datatypes on
that system. This poses a problem for Perl scripts which wish to read
FITS data into piddles, and do so in a manner portable to 64-bit
architectures, for example.  This routine takes a PDL object or
B<PDL::Types> token (returned by B<float()> and friends when given no
arguments), and returns the same-sized CFITSIO datatype, suitable for
passing to routines such as C<fits_read_col()>.

It B<croak()'s> upon error.


=item fits2pdl_coltype

	$pdl_type = fits2pdl_type( TLONG );
	$pdl_type = fits2pdl_type( 'D' );


Given a supported FITS or CFITSIO column datatype, return the PDL type
which is the closest functional match (i.e. C<TDOUBLE> => C<double>).
It B<croak()'s> if the passed type is not supported.

=item fits2pdl_imgtype

	$pdl_type = fits2pdl_type( FLOAT_IMG );


Given a supported CFITSIO table datatype, return the PDL type
which is the closest functional match (i.e. C<DOUBLE_IMG> => C<double>).
It B<croak()'s> if the passed type is not supported.

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Astro::FITS::CFITSIO>, L<PDL>

=head1 AUTHOR

Pete Ratzlaff

Diab Jerius

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.
You may find a copy at L<http://www.fsf.org/copyleft/gpl.html>.

=cut
