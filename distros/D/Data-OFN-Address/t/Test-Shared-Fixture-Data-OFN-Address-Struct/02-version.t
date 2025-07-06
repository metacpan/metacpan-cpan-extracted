use strict;
use warnings;

use Test::More 'tests' => 2;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::OFN::Address::Struct;

# Test.
is($Test::Shared::Fixture::Data::OFN::Address::Struct::VERSION, 0.01, 'Version.');
