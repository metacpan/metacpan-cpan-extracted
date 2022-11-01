use strict;
use warnings;

use App::Schema::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Schema::Data::VERSION, 0.05, 'Version.');
