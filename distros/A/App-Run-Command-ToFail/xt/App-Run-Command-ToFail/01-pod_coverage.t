use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::Run::Command::ToFail', 'App::Run::Command::ToFail is covered.');
