use strict;
use warnings;

use Alien::DjVuLibre;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Alien::DjVuLibre::VERSION, 0.03, 'Version.');
