#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';

use_ok( $class, qw(get_name) );
ok( defined &get_name, "get_name is defined" );

is( get_name( 'H'        ), 'Hydrogen' );
is( get_name( 'Hydrogen' ), 'Hydrogen' );
is( get_name( '1'        ), 'Hydrogen' );

is( get_name( 'Si',      $Languages{'English'}  ), 'Silicon' );
is( get_name( 'Silicon', $Languages{'English'}  ), 'Silicon' );
is( get_name( '14',      $Languages{'English'}  ), 'Silicon' );

is( get_name( 'He',     $Languages{'Pig Latin'}  ), 'Eliumhai' );
is( get_name( 'Helium', $Languages{'Pig Latin'}  ), 'Eliumhai' );
is( get_name( '2',      $Languages{'Pig Latin'}  ), 'Eliumhai' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functional interface, stuff that shouldn't work
{

is( get_name( -1 ),    undef, 'Got undef for -1'           );
is( get_name( 0 ),     undef, 'Got undef for 0'            );
is( get_name(  ),      undef, 'Got undef for no args'      );
is( get_name( undef ), undef, 'Got undef for undef'        );
is( get_name( '' ),    undef, 'Got undef for empty string' );
is( get_name( 'Unh' ), undef, 'Got undef for Unh'          );
is( get_name( 'Foo' ), undef, 'Got undef for Foo'          );
is( get_name( 82.1 ),  undef, 'Got undef for 82.0'         );


}