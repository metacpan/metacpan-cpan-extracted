#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_is_symbol';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );


ok( _is_symbol( 'Po' ), "Po is a symbol" );
ok( _is_symbol( 'Sg' ), "Sg is a symbol" );
ok( _is_symbol( 'Ha' ), "Ha is a symbol" );

ok( ! _is_symbol( '' ),    "empty string isn't a symbol" );
ok( ! _is_symbol( undef ), "undef isn't a symbol"        );
ok( ! _is_symbol( 'Foo' ), "Foo isn't a symbol"          );
ok( ! _is_symbol( '86' ),  "Po isn't a symbol"           );
