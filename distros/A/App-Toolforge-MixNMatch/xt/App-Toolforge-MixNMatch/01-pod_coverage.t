use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::Toolforge::MixNMatch', 'App::Toolforge::MixNMatch is covered.');
