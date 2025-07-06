use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::Place;

# Test.
is($Test::Shared::Fixture::Data::OFN::Address::Place::VERSION, 0.01, 'Version.');
