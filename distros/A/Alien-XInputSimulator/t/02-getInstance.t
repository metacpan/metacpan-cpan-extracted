use Test::More;
use Test::Alien::CPP;
use Alien::XInputSimulator;

alien_ok 'Alien::XInputSimulator';
my $xs = do { local $/; <DATA> };
xs_ok $xs, with_subtest {
  my($module) = @_;
  ok $module->getInstance;
};

done_testing;

__DATA__
#include <xinputsimulator.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = TA_MODULE PACKAGE = TA_MODULE

void
getInstance(klass)
    const char *klass
  PPCODE:
    (void)XInputSimulator::getInstance();
    XSRETURN(1);

