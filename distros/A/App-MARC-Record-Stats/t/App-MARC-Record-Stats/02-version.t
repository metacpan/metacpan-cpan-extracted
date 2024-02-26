use strict;
use warnings;

use App::MARC::Record::Stats;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::MARC::Record::Stats::VERSION, 0.01, 'Version.');
