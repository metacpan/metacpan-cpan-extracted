#! perl

use Test2::V0;
use Test::Alien;
use Alien::CFITSIO;
use Package::Stash;

alien_ok 'Alien::CFITSIO';
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my ( $module ) = @_;
    my $stash      = Package::Stash->new( $module );
    my $version    = $stash->get_symbol( '&fits_get_version' )->();
    $version = int( $version * 10000 ) / 10000;
    my $expected = Alien::CFITSIO::CFITSIO_VERSION;

    ok( $version >= $expected, "Version >= $expected" )
      or note( "Got Version = $version" );
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "fitsio.h"

MODULE = TA_MODULE PACKAGE = TA_MODULE

float
fits_get_version( )
  PREINIT:
  float version = 0;
  double dversion;
  CODE:
    RETVAL = fits_get_version( &version );
  OUTPUT:
    RETVAL
