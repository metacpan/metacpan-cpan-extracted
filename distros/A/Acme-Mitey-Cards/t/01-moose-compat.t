use strict;
use warnings;
use Test::More;
use Test::Requires { Moose => 2 };

use Acme::Mitey::Cards;
use Acme::Mitey::Cards::MOP;

{
	package My::Hand;
	use Moose;
	
	extends 'Acme::Mitey::Cards::Hand';
	
	has foobar => ( is => 'rw' );
	
	__PACKAGE__->meta->make_immutable;
}

my $obj = 'My::Hand'->new(
	owner  => 'Alice',
	foobar => 456,
	cards  => [],
);

is( $obj->owner,  'Alice' );
is( $obj->foobar, 456 );

my $owner_attr = $obj->meta->find_attribute_by_name('owner');

is( $owner_attr->{is}, 'rw' );
is( $owner_attr->definition_context->{toolkit}, 'Mite' );
ok( $owner_attr->type_constraint->isa( 'Type::Tiny::Union' ) );
is( $owner_attr->type_constraint->display_name, 'Str|Object' );

done_testing;
