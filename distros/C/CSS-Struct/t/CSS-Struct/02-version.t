use strict;
use warnings;

use CSS::Struct;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CSS::Struct::VERSION, 0.03, 'Version.');
