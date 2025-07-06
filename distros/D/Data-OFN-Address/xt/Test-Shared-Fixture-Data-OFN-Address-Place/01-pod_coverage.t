use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Test::Shared::Fixture::Data::OFN::Address::Place', 'Test::Shared::Fixture::Data::OFN::Address::Place is covered.');
