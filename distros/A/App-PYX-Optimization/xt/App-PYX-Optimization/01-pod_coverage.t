use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::PYX::Optimization', 'App::PYX::Optimization is covered.');
