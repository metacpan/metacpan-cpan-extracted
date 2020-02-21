#! perl

use Test2::V0;
use Test::Alien;
use Alien::LibCIAORegion;

alien_ok 'Alien::LibCIAORegion';
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($module) = @_;
  ok $module->check();
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <cxcregion.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

int check( class )
  const char* class;
  CODE:
  regCreateEmptyRegion();
  RETVAL=1;
