#!/usr/bin/perl

package Chemistry::Elements;
use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_is_Z';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );



ok( _is_Z( $_ ), "$_ is a Z"   ) for 1 .. 106;

ok( ! _is_Z( $_ + 0.1 ), "$_.1 is not a Z"   ) for 10 .. 20;

ok( ! _is_Z( '' ),    "empty string isn't a Z" );
ok( ! _is_Z( undef ), "undef isn't a Z"        );
ok( ! _is_Z( 'Foo' ), "Foo isn't a Z"          );
ok( ! _is_Z( 'Po' ),  "Po isn't a Z"           );
ok( ! _is_Z( 0 ),     "0 isn't a Z"           );
