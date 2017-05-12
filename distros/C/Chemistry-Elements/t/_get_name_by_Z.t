#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';

use_ok( $class );
ok( defined &{"${class}::_get_name_by_Z"}, "_get_name_by_Z defined" );

package Chemistry::Elements;

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Default language, as English
is( _get_name_by_Z(1), 'Hydrogen', 'Works of H in default language' );
is( _get_name_by_Z(6), 'Carbon',   'Works of C in default language' );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Default language, as Pig Latin
{
local $Default_language;
$Default_language = $Languages{'Pig Latin'};

is( _get_name_by_Z(1),  'Ydrogenhai', 'Works of H in changed default language'  );
is( _get_name_by_Z(90), 'Horiumtai',  'Works of Th in changed default language' );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify language, as English
is( _get_name_by_Z( 1, $Languages{'English'} ), 'Hydrogen', 'Works of H in specified language (English)' );
is( _get_name_by_Z( 6, $Languages{'English'} ), 'Carbon',   'Works of C in specified language (English)' );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify language, as Pig Latin
is( _get_name_by_Z(  1, $Languages{'Pig Latin'} ), 'Ydrogenhai', 'Works of H in specified language (Pig Latin)' );
is( _get_name_by_Z( 82, $Languages{'Pig Latin'} ), 'Eadlai',     'Works of H in specified language (Pig Latin)' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Stuff that shouldn't work
is( _get_name_by_Z(undef), undef, 'Fails for undef' );
is( _get_name_by_Z('Foo'), undef, 'Fails for Foo' );
