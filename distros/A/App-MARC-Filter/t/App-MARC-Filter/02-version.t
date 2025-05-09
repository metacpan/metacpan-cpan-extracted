use strict;
use warnings;

use App::MARC::Filter;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Filter::VERSION, 0.05, 'Version.');
