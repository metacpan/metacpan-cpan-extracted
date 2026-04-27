use strict;
use warnings;

use Alien::cmake4;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Alien::cmake4::VERSION, 0.02, 'Version.');
