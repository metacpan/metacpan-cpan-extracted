#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_get_symbol_by_Z';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work, default language
is( _get_symbol_by_Z( 46 ), 'Pd', "Get right symbol for 46" );
is( _get_symbol_by_Z( 32 ), 'Ge', "Get right symbol for 32" );
is( _get_symbol_by_Z( 61 ), 'Pm', "Get right symbol for 61" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that shouldn't work
ok( ! defined _get_symbol_by_Z( ''  ),   "No symbol from empty string" );
ok( ! defined _get_symbol_by_Z( undef ), "No symbol from undef" );
ok( ! defined _get_symbol_by_Z(   ),     "No symbol from no args" );
ok( ! defined _get_symbol_by_Z( 0  ),    "No symbol from 0" );
