use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Alien::bc::GNU', 'Alien::bc::GNU is covered.');
