#!/usr/bin/perl

use strict;
use Test::More;
use MyTest::SuperAttrs;

use strict;
plan tests => 2;

# Tests here

# Need this test because __attribute (and others) are Class::Data::Inheritable
# based and the original code didn't do the inheritance properly since it
# modified the data in-place instead of calling the accessor (which correctly
# moves the data into the subclass). I've fixed the code but this should stop
# it creeping back in.

cmp_ok(%{Class::XML->__attribute}, '==', 0, "Base class not polluted");

#die join(',',%{MyTest::SuperAttrs->__attribute});

ok(exists MyTest::SuperAttrs->__attribute->{'flavour'}, "Overload works");
