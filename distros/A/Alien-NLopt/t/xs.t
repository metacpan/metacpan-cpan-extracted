#! perl

use Test2::V0;
use Test::Alien;

use constant PACKAGE_NAME => 'Alien::NLopt';
use Alien::NLopt;
use Package::Stash;
use version 0.77;

alien_ok PACKAGE_NAME;
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my ( $module ) = @_;
    my $stash = Package::Stash->new( $module );
    my ( $major, $minor, $bugfix )
      = $stash->get_symbol( '&nlopt_version' )->();
    my $version = version->declare( sprintf( 'v%d.%d.%d', $major, $minor, $bugfix ) );
    ( my $expected = PACKAGE_NAME->VERSION ) =~ s/[.]\d+$//;
    ok( $version == $expected, "Version == $expected" )
      or note( "Got Version == $version" );
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <nlopt.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

void
nlopt_version( OUTLIST major, OUTLIST minor, OUTLIST bugfix)
  int major;
  int minor;
  int bugfix;
