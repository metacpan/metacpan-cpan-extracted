use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::Test::DWG::LibreDWG::JSON', 'App::Test::DWG::LibreDWG::JSON is covered.');
