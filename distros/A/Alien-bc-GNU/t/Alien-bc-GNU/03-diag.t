use strict;
use warnings;

use Alien::bc::GNU;
use Test::Alien::Diag;
use Test::More 'tests' => 1;
use Test::NoWarnings;

# Test.
alien_diag('Alien::bc::GNU');
