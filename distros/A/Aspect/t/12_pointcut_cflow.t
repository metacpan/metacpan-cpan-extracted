#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use Aspect;

SCOPE: {
	package My::Foo;

	sub parent1 {
		$_[0]->child;
	}

	sub parent2 {
		$_[0]->child;
	}

	sub child {
		return 1;
	}
}

my $MATCHES = 0;

# Set up the cflow hook
around {
	$MATCHES += 1;
	isa_ok( $_->{foo}, 'Aspect::Point::Static' );
	isa_ok( $_->foo, 'Aspect::Point::Static' );
	$_->proceed;
	$_->return_value(2);
} call 'My::Foo::child'
& cflow foo => 'My::Foo::parent2';

is( My::Foo->child,   1, '->child ok'   );
is( My::Foo->parent1, 1, '->parent1 ok' );
is( My::Foo->parent2, 2, '->parent2 ok' );
is( $MATCHES, 1, 'Got one match total' );

# Set up a second single-param cflow hook
around {
	$MATCHES += 10;
	isa_ok( $_->{enclosing}, 'Aspect::Point::Static' );
	isa_ok( $_->enclosing, 'Aspect::Point::Static' );
	$_->proceed;
	$_->return_value(3);
} call 'My::Foo::child'
& cflow 'My::Foo::parent1';

is( My::Foo->child,   1, '->child ok'   );
is( My::Foo->parent1, 3, '->parent1 ok' );
is( My::Foo->parent2, 2, '->parent2 ok' );
is( $MATCHES, 12, 'Got expected matches' );
