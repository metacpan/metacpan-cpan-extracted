#! perl

use v5.10;

use Test2::V0;
use Test::Alien;
use Alien::Qhull;
use Package::Stash;
use version;

alien_ok 'Alien::Qhull';
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my ( $module ) = @_;
    my $stash = Package::Stash->new( $module );

    my ( undef, $got ) = split( qr/ /, $stash->get_symbol( '&version' )->() );
    $got = version->declare( $got );
    # need to strip last component off of Alien::Qhull's version
    ( my $expected = version->parse( version->declare( Alien::Qhull->VERSION )->numify ) )
      =~ s/\d{3}$//;
    ok( $got >= $expected, "$got >= $expected" )
      or note( "Got Version = $got" );
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "libqhull_r/libqhull_r.h"

MODULE = TA_MODULE PACKAGE = TA_MODULE

char *
version( )
  CODE:
    QHULL_LIB_CHECK;
    RETVAL = qh_version2;
  OUTPUT:
    RETVAL
