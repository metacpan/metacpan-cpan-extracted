#! perl

use v5.10;
use Test2::V0;
use Test::Alien;
use Package::Stash;
use Alien::CXC::param;

alien_ok 'Alien::CXC::param';
my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my ( $module ) = @_;
    my $stash      = Package::Stash->new( $module );
    my $error      = $stash->get_symbol( '&paramerrstr' )->();
    is( $error, 'parameter error?' );
    pass;
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <cxcparam/parameter.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char*
paramerrstr()
