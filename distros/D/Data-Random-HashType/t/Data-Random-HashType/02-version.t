use strict;
use warnings;

use Data::Random::HashType;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Random::HashType::VERSION, 0.01, 'Version.');
