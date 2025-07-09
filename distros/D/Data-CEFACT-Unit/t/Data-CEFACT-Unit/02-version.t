use strict;
use warnings;

use Data::CEFACT::Unit;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::CEFACT::Unit::VERSION, 0.01, 'Version.');
