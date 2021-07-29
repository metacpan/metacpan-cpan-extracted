use Test2::V0 -no_srand => 1;
use Test::Alien;
use Alien::GSL;

alien_ok 'Alien::GSL';

my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($module) = @_;
  is($module->thetest, 1);
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <gsl/gsl_sf_bessel.h>

int
thetest(const char *class)
{
  double x = 5.0;
  double y = gsl_sf_bessel_J0 (x);
  return 1;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int
thetest(class)
    const char *class;
  
