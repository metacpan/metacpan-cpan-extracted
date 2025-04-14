use strict;
use warnings;

use App::MARC::List;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::List::VERSION, 0.06, 'Version.');
