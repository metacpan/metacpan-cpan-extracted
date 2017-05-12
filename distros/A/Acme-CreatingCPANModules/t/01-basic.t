#!perl -T

use Test::More 'no_plan';#tests => 1;

BEGIN {
	use_ok( 'Acme::CreatingCPANModules' );
}

my $object = Acme::CreatingCPANModules->new();

isa_ok( $object, 'Acme::CreatingCPANModules' );

$object->set( 5 );

is( $object->get(), 5 );
