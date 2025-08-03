use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Person;

# Test.
is($Test::Shared::Fixture::Data::InfoBox::Person::VERSION, 0.07, 'Version.');
