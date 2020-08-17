use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('CSS::Struct::Output', 'CSS::Struct::Output is covered.');
