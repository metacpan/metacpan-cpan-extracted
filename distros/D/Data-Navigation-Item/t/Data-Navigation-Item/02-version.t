use strict;
use warnings;

use Data::Navigation::Item;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::Navigation::Item::VERSION, 0.02, 'Version.');
