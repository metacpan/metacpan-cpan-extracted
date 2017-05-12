#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';

use_ok( $class );
ok( defined &{"${class}::can"}, "$class defines its own can" );

my $element = $class->new( 'U' );
isa_ok( $element, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# try something that should return true
ok( $element->can('name'), 'Object can call the name method' );

is( $element->Z,       92, "Got right Z for U" );
is( $element->symbol, 'U', "Got right symbol for U" );
is( $element->name, 'Uranium', "Got right name for U (Default)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Change the name to something that will work
is( $element->name('Plutonium'),  'Plutonium', "Got right name for Pu after U decay" );
is( $element->symbol, 'Pu', "Got right symbol for Pu" );
is( $element->Z,  94, "Got right Z for Pu (Default)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Change the name to something that won't work
ok( ! $element->name(''),    "Can't change name to empty string" );
ok( ! $element->name(undef), "Can't change name to undef"        );
ok( ! $element->name(0),     "Can't change name to 0"            );
ok( ! $element->name(-1),    "Can't change name to -1"           );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# This should still be the same element
is( $element->name,  'Plutonium', "Got right name for Pu after U decay" );
is( $element->symbol, 'Pu', "Got right symbol for Pu" );
is( $element->Z,  94, "Got right Z for Pu (Default)" );
