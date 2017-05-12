#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_get_name_by_symbol';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work, default language
is( _get_name_by_symbol( 'F' ),  'Fluorine',  "Get right name for F (Default)" );
is( _get_name_by_symbol( 'Ar' ), 'Argon',     "Get right name for Ar (Default)" );
is( _get_name_by_symbol( 'Xe' ), 'Xenon',     "Get right name for Xe (Default)" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work, English
is( _get_name_by_symbol(  'F', $Languages{'English'} ), 'Fluorine',  "Get right name for F (English)" );
is( _get_name_by_symbol( 'Ar', $Languages{'English'} ), 'Argon',     "Get right name for Ar (English)" );
is( _get_name_by_symbol( 'Xe', $Languages{'English'} ), 'Xenon',     "Get right name for Xe (English)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that should work, Pig Latin
is( _get_name_by_symbol(  'F', $Languages{'Pig Latin'} ), 'Luorinefai',  "Get right name for F (Pig Latin)" );
is( _get_name_by_symbol( 'Ar', $Languages{'Pig Latin'} ), 'Rgonaai',     "Get right name for Ar (Pig Latin)" );
is( _get_name_by_symbol( 'Xe', $Languages{'Pig Latin'} ), 'Enonxai',     "Get right name for Xe (Pig Latin)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that shouldn't work
ok( ! defined _get_name_by_symbol( ''  ),   "No symbol from empty string" );
ok( ! defined _get_name_by_symbol( undef ), "No name from undef" );
ok( ! defined _get_name_by_symbol(   ),     "No name from no args" );
ok( ! defined _get_name_by_symbol( 0  ),    "No name from 0" );
