use strict;
use warnings;
use Test2::Bundle::More;
use Test::Alien 0.05;
use Acme::Alien::DontPanic;

plan 3;

alien_ok 'Acme::Alien::DontPanic';

xs_ok do { local $/; <DATA> }, with_subtest {
  my($module) = @_;
  plan 1;
  is $module->answer, 42, 'answer is 42';
};

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libdontpanic.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

int answer(class)
    const char *class;
  CODE:
    RETVAL = answer();
  OUTPUT:
    RETVAL
