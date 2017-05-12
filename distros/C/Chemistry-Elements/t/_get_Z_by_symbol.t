#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_get_Z_by_symbol';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );

is( _get_Z_by_symbol('Po'), 84, "Got right Z for Po" );
is( _get_Z_by_symbol('Pb'), 82, "Got right Z for Pb" );
is( _get_Z_by_symbol('Ne'), 10, "Got right Z for Ne" );
is( _get_Z_by_symbol('La'), 57, "Got right Z for La" );
is( _get_Z_by_symbol('H'),   1, "Got right Z for H" );


ok( ! _get_Z_by_symbol( '' ),    "empty string isn't a symbol" );
ok( ! _get_Z_by_symbol( undef ), "undef isn't a symbol"        );
ok( ! _get_Z_by_symbol( 'Foo' ), "Foo isn't a symbol"          );
ok( ! _get_Z_by_symbol( '86' ),  "86 isn't a symbol"           );
