use strict;
use warnings;

use Alien::cmake4;
use Test::Alien::Diag;
use Test::More 'tests' => 1;
use Test::NoWarnings;

# Test.
alien_diag('Alien::cmake4');
