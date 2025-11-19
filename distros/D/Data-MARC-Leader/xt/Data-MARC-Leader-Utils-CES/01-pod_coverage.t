use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Data::MARC::Leader::Utils::CES', 'Data::MARC::Leader::Utils::CES is covered.');
