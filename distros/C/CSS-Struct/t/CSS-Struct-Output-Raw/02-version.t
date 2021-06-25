use strict;
use warnings;

use CSS::Struct::Output::Raw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($CSS::Struct::Output::Raw::VERSION, 0.05, 'Version.');
