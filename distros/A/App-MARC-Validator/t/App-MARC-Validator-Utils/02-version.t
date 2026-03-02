use strict;
use warnings;

use App::MARC::Validator::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Validator::Utils::VERSION, 0.06, 'Version.');
