use strict;
use warnings;

use App::MARC::Leader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Leader::VERSION, 0.07, 'Version.');
