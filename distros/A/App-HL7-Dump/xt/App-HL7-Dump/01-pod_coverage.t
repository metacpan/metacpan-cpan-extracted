use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::HL7::Dump', 'App::HL7::Dump is covered.');
