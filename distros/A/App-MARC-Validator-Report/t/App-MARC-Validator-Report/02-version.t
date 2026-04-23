use strict;
use warnings;

use App::MARC::Validator::Report;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Validator::Report::VERSION, 0.04, 'Version.');
