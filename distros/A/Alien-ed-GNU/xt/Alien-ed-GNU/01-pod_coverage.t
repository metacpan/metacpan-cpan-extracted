use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Alien::ed::GNU', 'Alien::ed::GNU is covered.');
