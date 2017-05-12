#!/usr/bin/perl -w
use strict;

# Test the non-construction-order-specific aspects of a class inherited from a class inherited from a class inherited from Auto

use FindBin;

use lib $FindBin::Bin . '/testmodules';

use TestCode::PlainObject;
use Test::More tests => 1+TestCode::PlainObject->num_tests();

BEGIN { use_ok( 'Auto::Inherit::Inherit' ); }

TestCode::PlainObject->test_plain('Auto::Inherit::Inherit', 'Auto');
