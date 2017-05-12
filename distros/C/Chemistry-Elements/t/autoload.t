#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = 'get_symbol';

use_ok( $class, $sub );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Object interface with something that works
{
my $element = $class->new( 'Erbium' );
isa_ok( $element, $class );

is( $element->Z,       68      );
is( $element->name,   'Erbium' );
is( $element->symbol, 'Er'     );

ok( $element->molar_mass( 167.26 ), 'Set molar mass for Er' );

ok( $element->can( 'molar_mass' ), "Now I can call molar_mass" );
	
is( $element->molar_mass, 167.26, 'Got back same value for molar mass' );
}

