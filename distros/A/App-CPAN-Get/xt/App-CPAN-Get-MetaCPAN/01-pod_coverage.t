use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('App::CPAN::Get::MetaCPAN', 'App::CPAN::Get::MetaCPAN is covered.');
