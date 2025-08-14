use strict;
use warnings;

use CAD::Format::DWG::Version;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CAD::Format::DWG::Version::VERSION, 0.01, 'Version.');
