#!/usr/bin/perl -w
use strict;

#A lazy object inside of a lazy object

use FindBin;

use lib $FindBin::Bin . '/testmodules';

use TestCode::PlainObject;
use Test::More tests => 1+TestCode::PlainObject->num_tests();

BEGIN { use_ok( 'Simple::Lazy::Double' ); }

TestCode::PlainObject->test_plain('Simple::Lazy::Double', 'Simple');