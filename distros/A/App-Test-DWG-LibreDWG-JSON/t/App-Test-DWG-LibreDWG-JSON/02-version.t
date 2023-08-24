use strict;
use warnings;

use App::Test::DWG::LibreDWG::JSON;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Test::DWG::LibreDWG::JSON::VERSION, 0.04, 'Version.');
