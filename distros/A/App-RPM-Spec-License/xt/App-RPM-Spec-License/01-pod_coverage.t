use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::RPM::Spec::License', 'App::RPM::Spec::License is covered.');
