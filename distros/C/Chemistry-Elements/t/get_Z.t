#!/usr/bin/perl

use Test::More 'no_plan';

my $class = 'Chemistry::Elements';

use_ok( $class, qw( get_Z ) );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Object interface shouldn't work
{
my $element = $class->new( 'Erbium' );
isa_ok( $element, $class );

ok( ! $element->can( 'get_Z' ), 'can() says get_Z is not there (good)' );

eval { $element->get_Z };
ok( defined $@, "Calling get_Z as object method fails (good)" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functional interface, stuff that works
{
ok( defined &get_Z, "get_Z is in the current namespace" );

is( get_Z( 'Erbium' ), 68, 'Got the right Z for Erbium' );
is( get_Z( 72 ),       72, 'Got the right Z for 72'     );
is( get_Z( 'Po' ),     84, 'Got the right Z for Po'     );

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Functional interface, stuff that shouldn't work
{

is( get_Z( -1 ),    undef, 'Got undef for -1'           );
is( get_Z( 0 ),     undef, 'Got undef for 0'            );
is( get_Z(  ),      undef, 'Got undef for no args'      );
is( get_Z( undef ), undef, 'Got undef for undef'        );
is( get_Z( '' ),    undef, 'Got undef for empty string' );
is( get_Z( 'Unh' ), undef, 'Got undef for Unh'          );
is( get_Z( 'Foo' ), undef, 'Got undef for Foo'          );
is( get_Z( 82.1 ),  undef, 'Got undef for 82.0'         );


}