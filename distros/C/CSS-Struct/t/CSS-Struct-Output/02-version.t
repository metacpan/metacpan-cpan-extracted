use strict;
use warnings;

use CSS::Struct::Output;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CSS::Struct::Output::VERSION, 0.05, 'Version.');
