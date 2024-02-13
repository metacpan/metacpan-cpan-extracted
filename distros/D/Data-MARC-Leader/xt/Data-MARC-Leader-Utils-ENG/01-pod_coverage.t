use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::MARC::Leader::Utils::ENG', 'Data::MARC::Leader::Utils::ENG is covered.');
