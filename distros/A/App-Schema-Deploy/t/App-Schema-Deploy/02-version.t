use strict;
use warnings;

use App::Schema::Deploy;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($App::Schema::Deploy::VERSION, 0.05, 'Version.');
