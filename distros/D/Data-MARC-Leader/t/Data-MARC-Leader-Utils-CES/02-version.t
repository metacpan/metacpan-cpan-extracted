use strict;
use warnings;

use Data::MARC::Leader::Utils::CES;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Leader::Utils::CES::VERSION, 0.07, 'Version.');
