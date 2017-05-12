#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_get_symbol_by_name';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work
is( _get_symbol_by_name( 'Calcium'   ), 'Ca', "Get right name for F (English)" );
is( _get_symbol_by_name( 'Magnesium' ), 'Mg', "Get right name for Ar (English)" );
is( _get_symbol_by_name( 'Chlorine'  ), 'Cl', "Get right name for Xe (English)" );

is( _get_symbol_by_name( 'Alciumcai'   ), 'Ca', "Get right name for F (Pig Latin)" );
is( _get_symbol_by_name( 'Agnesiummai' ), 'Mg', "Get right name for Ar (Pig Latin)" );
is( _get_symbol_by_name( 'Hlorinecai'  ), 'Cl', "Get right name for Xe (Pig Latin)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that shouldn't work
ok( ! defined _get_symbol_by_name( ''  ),   "No symbol from empty string" );
ok( ! defined _get_symbol_by_name( undef ), "No name from undef" );
ok( ! defined _get_symbol_by_name(   ),     "No name from no args" );
ok( ! defined _get_symbol_by_name( 0  ),    "No name from 0" );
