#! perl

use Test2::V0;
use Test::Alien;
use Alien::PGPLOT;
use Package::Stash;

alien_ok 'Alien::PGPLOT';
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my ( $module ) = @_;
    my $stash      = Package::Stash->new( $module );
    ok ( lives
         { $stash->get_symbol( '&cpgopen' )->('/null') },
         'found cpgopen' )
      or note $@;
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "cpgplot.h"

MODULE = TA_MODULE PACKAGE = TA_MODULE

void
cpgopen( device )
  char *device

