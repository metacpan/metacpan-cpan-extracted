#!/usr/bin/perl -w
use strict;

# Test the non-construction-order-specific aspects of an autoloaded class. 

use FindBin;

use lib $FindBin::Bin . '/testmodules';

use TestCode::PlainObject;
use Test::More tests => 1+TestCode::PlainObject->num_tests();

BEGIN { use_ok( 'Auto' ); }

TestCode::PlainObject->test_plain('Auto');