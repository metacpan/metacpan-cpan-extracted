use strict;
use warnings;

use Data::Random::Person;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Random::Person::VERSION, 0.02, 'Version.');
