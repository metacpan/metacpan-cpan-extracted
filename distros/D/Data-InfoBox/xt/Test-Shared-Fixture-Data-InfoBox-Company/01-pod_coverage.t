use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Test::Shared::Fixture::Data::InfoBox::Company', 'Test::Shared::Fixture::Data::InfoBox::Company is covered.');
