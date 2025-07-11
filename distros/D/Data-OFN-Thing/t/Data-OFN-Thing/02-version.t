use strict;
use warnings;

use Data::OFN::Thing;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::OFN::Thing::VERSION, 0.01, 'Version.');
