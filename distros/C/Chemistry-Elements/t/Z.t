#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';

use_ok( $class );
ok( defined &{"${class}::can"}, "$class defines its own can" );

my $element = $class->new( 'U' );
isa_ok( $element, $class );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# try something that should return true
ok( $element->can('Z'), 'Object can call the Z method' );

is( $element->Z,       92, "Got right Z for U" );
is( $element->symbol, 'U', "Got right symbol for U" );
is( $element->name, 'Uranium', "Got right name for U (Default)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Change the Z
is( $element->Z(94),   94, "Got right Z for Pu after U decay" );
is( $element->symbol, 'Pu', "Got right symbol for Pu" );
is( $element->name,   'Plutonium', "Got right name for Pu (Default)" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Change the Z to nonsense
ok( ! $element->Z('Pa'),          "Could not change Z to symbol"       );
ok( ! $element->Z('Technetium'),  "Could not change Z to symbol"       );
ok( ! $element->Z(''),            "Could not change Z to empty string" );
ok( ! $element->Z(undef),         "Could not change Z to undef"        );
ok( ! $element->Z(0),             "Could not change Z to 0"            );
ok( ! $element->Z(200),           "Could not change Z to 200"          );
