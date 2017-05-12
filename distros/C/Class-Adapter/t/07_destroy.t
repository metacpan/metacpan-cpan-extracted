#!/usr/bin/perl

BEGIN {
	$DB::single = $DB::single = 1;
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

SCOPE: {
	package Foo;

	sub new {
		my $class = shift;
		bless { @_ }, $class;
	}

	1;
}

SCOPE: {
	package Bar;

	use Class::Adapter::Builder
		ISA      => 'Foo',
		AUTOLOAD => 1;

	sub new {
		my $class = shift;
		return $class->SUPER::new(
			Foo->new(@_),
		);
	}
}

# Create an object
SCOPE: {
	my $object = Bar->new;
	isa_ok( $object, 'Bar' );
	$object->DESTROY;
}

my $foo = Foo->new;
isa_ok( $foo, 'Foo' );
my $bar = Bar->new;
isa_ok( $bar, 'Foo' );
isa_ok( $bar, 'Bar' );
