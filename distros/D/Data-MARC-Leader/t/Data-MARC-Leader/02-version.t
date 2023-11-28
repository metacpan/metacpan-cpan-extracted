use strict;
use warnings;

use Data::MARC::Leader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::MARC::Leader::VERSION, 0.03, 'Version.');
