use strict;
use warnings;

use Alien::libpopt;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Alien::libpopt::VERSION, 0.01, 'Version.');
