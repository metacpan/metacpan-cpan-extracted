use strict;
use warnings;

use App::Test::DWG::LibreDWG::DwgRead;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Test::DWG::LibreDWG::DwgRead::VERSION, 0.04, 'Version.');
