use strict;
use warnings;

use Check::Fork;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Check::Fork::VERSION, 0.01, 'Version.');
