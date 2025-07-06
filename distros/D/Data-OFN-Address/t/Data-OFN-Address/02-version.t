use strict;
use warnings;

use Data::OFN::Address;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::OFN::Address::VERSION, 0.01, 'Version.');
