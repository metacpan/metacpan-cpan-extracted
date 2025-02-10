use strict;
use warnings;

use Data::Icon;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Icon::VERSION, 0.02, 'Version.');
