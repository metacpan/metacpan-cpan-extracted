# -*- perl -*-

# t/00.load.t - check module loading

use Test::More tests => 2;


BEGIN { use_ok( 'Data::Random' ); }

isnt $INC[0], '..', 'no longer corrupting @INC';


done_testing;
