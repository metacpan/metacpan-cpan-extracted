use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::NKC2ISBD', 'App::NKC2ISBD is covered.');
