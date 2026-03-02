use strict;
use warnings;

use App::MARC::Validator;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Validator::VERSION, 0.06, 'Version.');
