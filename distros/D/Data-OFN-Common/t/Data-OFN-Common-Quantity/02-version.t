use strict;
use warnings;

use Data::OFN::Common::Quantity;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::OFN::Common::Quantity::VERSION, 0.02, 'Version.');
