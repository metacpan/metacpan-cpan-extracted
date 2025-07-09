use strict;
use warnings;

use CEFACT::Unit;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CEFACT::Unit::VERSION, 0.01, 'Version.');
