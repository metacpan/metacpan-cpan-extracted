use strict;
use warnings;

use Class::Params;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Class::Params::VERSION, 0.06, 'Version.');
