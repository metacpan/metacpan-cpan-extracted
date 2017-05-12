#!/usr/bin/perl

package Chemistry::Elements;

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = '_is_name';

use_ok( $class );
ok( defined &{"${class}::$sub"}, "$sub defined" );


ok( _is_name( 'Oxygen'   ), "Oxygen is a name"   );
ok( _is_name( 'Xygenoai' ), "Xygenoai is a name" );

ok( ! _is_name( '' ),    "empty string isn't a name" );
ok( ! _is_name( undef ), "undef isn't a name"        );
ok( ! _is_name( 'Foo' ), "Foo isn't a name"          );
ok( ! _is_name( 'Po' ),  "Po isn't a name"           );
