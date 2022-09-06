use strict;
use warnings;

use Alien::ed::GNU;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Alien::ed::GNU::VERSION, 0.02, 'Version.');
