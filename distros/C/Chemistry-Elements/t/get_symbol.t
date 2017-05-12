#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';
my $sub   = 'get_symbol';

use_ok( $class, $sub );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Object interface
{
my $element = $class->new( 'Erbium' );
isa_ok( $element, $class );

ok( ! $element->can( $sub ), "can() says $sub is not there (good)" );

eval { $element->get_Z };
ok( defined $@, "Calling $sub as object method fails (good)" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functional interface
{
ok( defined &get_symbol, "$sub is in the current namespace" );

is( get_symbol( 'Plutonium' ),   'Pu', 'Got the right symbol for Plutonium (English)'     );
is( get_symbol( 'Lutoniumpai' ), 'Pu', 'Got the right symbol for Lutoniumpai (Pig Latin)' );
is( get_symbol( 18 ),            'Ar', 'Got the right symbol for 18'                      );
is( get_symbol( 'Rh' ),          'Rh', 'Got the right symbol for Rh'                      );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functional interface, stuff that shouldn't work
{

is( get_symbol( -1 ),    undef, 'Got undef for -1'           );
is( get_symbol( 0 ),     undef, 'Got undef for 0'            );
is( get_symbol(  ),      undef, 'Got undef for no args'      );
is( get_symbol( undef ), undef, 'Got undef for undef'        );
is( get_symbol( '' ),    undef, 'Got undef for empty string' );
is( get_symbol( 'Unh' ), undef, 'Got undef for Unh'          );
is( get_symbol( 'Foo' ), undef, 'Got undef for Foo'          );
is( get_symbol( 82.1 ),  undef, 'Got undef for 82.0'         );


}