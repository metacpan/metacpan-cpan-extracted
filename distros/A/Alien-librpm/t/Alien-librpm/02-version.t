use strict;
use warnings;

use Alien::librpm;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Alien::librpm::VERSION, 0.01, 'Version.');
