use strict;
use warnings;

use App::MARC::Field008;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Field008::VERSION, 0.01, 'Version.');
