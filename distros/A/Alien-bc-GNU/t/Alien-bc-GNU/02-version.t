use strict;
use warnings;

use Alien::bc::GNU;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Alien::bc::GNU::VERSION, 0.03, 'Version.');
