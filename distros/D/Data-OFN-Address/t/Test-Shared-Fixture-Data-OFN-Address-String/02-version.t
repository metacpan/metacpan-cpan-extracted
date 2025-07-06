use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::String;

# Test.
is($Test::Shared::Fixture::Data::OFN::Address::String::VERSION, 0.01, 'Version.');
