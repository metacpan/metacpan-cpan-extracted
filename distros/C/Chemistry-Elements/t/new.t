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
}

{
my $element = $class->new( 'Er' );
isa_ok( $element, $class );

is( $element->Z,       68      );
is( $element->name,   'Erbium' );
is( $element->symbol, 'Er'     );
}

{
my $element = $class->new( 68 );
isa_ok( $element, $class );

is( $element->Z,       68      );
is( $element->name,   'Erbium' );
is( $element->symbol, 'Er'     );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Object interface with something that doesn't work
{
my $element = $class->new( 'Administrativium' );
ok( ! defined $element, "Can't make a fake element" );
}

{
my $element = $class->new( );
ok( ! defined $element, "Can't make a fake element" );
}

{
my $element = $class->new( undef );
ok( ! defined $element, "Can't make a fake element" );
}

{
my $element = $class->new( '' );
ok( ! defined $element, "Can't make a fake element" );
}

{
my $element = $class->new( 0 );
ok( ! defined $element, "Can't make a fake element" );
}

{
my $element = $class->new( -1 );
ok( ! defined $element, "Can't make a fake element" );
}
