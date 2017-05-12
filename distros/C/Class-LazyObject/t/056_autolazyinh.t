#!/usr/bin/perl -w
use strict;

use FindBin;

use lib $FindBin::Bin . '/testmodules';

use TestCode::PlainObject;
use Test::More skip_all => 'Inheriting from a class that inherits from Class::LazyObject is not yet supported.';
#use Test::More tests => 1+TestCode::PlainObject->num_tests();

BEGIN { use_ok( 'Auto::Lazy::Inherit' ); }

TestCode::PlainObject->test_plain('Auto::Lazy::Inherit', 'Auto');
