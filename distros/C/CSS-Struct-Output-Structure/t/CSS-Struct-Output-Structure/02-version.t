use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CSS::Struct::Output::Structure::VERSION, 0.02, 'Version.');
