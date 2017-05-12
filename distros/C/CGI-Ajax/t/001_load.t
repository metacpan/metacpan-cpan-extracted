# -*- perl -*-

# t/001_load.t - check to see if Class::Acceccor module is avail

use Test::More tests => 1;

BEGIN { use_ok( 'Class::Accessor' ); }

