use strict;
use warnings;

use Data::MARC::Leader::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Leader::Utils::VERSION, 0.03, 'Version.');
