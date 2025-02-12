use strict;
use warnings;

use Data::InfoBox::Item;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::InfoBox::Item::VERSION, 0.04, 'Version.');
