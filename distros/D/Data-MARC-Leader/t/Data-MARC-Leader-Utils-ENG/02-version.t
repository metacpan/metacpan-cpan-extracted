use strict;
use warnings;

use Data::MARC::Leader::Utils::ENG;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Leader::Utils::ENG::VERSION, 0.06, 'Version.');
