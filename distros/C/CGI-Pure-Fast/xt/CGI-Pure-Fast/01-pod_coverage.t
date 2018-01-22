use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('CGI::Pure::Fast', 'CGI::Pure::Fast is covered.');
