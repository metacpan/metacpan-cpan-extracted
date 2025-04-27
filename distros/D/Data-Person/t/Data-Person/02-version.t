use strict;
use warnings;

use Data::Person;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Person::VERSION, 0.05, 'Version.');
