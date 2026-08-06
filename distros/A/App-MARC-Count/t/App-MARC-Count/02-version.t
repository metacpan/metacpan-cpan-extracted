use strict;
use warnings;

use App::MARC::Count;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Count::VERSION, 0.05, 'Version.');
