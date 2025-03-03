use strict;
use warnings;

use Data::InfoBox;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Data::InfoBox::VERSION, 0.06, 'Version.');
