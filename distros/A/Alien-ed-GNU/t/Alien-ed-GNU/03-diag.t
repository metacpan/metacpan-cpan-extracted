use strict;
use warnings;

use Alien::ed::GNU;
use Test::Alien::Diag;
use Test::More 'tests' => 1;
use Test::NoWarnings;

# Test.
alien_diag('Alien::ed::GNU');
