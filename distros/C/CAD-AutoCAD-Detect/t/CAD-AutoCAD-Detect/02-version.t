use strict;
use warnings;

use CAD::AutoCAD::Detect;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CAD::AutoCAD::Detect::VERSION, 0.01, 'Version.');
