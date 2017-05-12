########################################################################
# Verifies load is okay
# Also verifies that system uses 64bit NV:
#   if it's not an IEEE 64bit double, all bets are off
########################################################################
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Config;

BEGIN {
    use_ok( 'Data::IEEE754::Tools' ) or diag "Couldn't even load Data::IEEE754::Tools";
}

cmp_ok( $Config{nvsize}*8 , '>=', 8*8 , "Requires Perl NV with at least 64bit double" )
    or diag(
        sprintf "\n\nYour system uses a native floating-point with %d bits;\nData::IEEE754::Tools requires >= %d bits\n\n",
            $Config{nvsize}*8, 8*8
    );
