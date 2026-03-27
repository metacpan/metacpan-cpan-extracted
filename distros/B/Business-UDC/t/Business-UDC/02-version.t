use strict;
use warnings;

use Business::UDC;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Business::UDC::VERSION, 0.03, 'Version.');
