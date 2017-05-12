#!/usr/bin/perl

# Replication test for https://rt.cpan.org/Ticket/Display.html?id=57417

# When ->proceed is used in list context, the return list is
# accidentally stuffed inside a second ARRAY reference on return.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use Test::NoWarnings;
use Aspect;

around {
	shift->proceed;
} call qr/^Foo::*/
| call qr/^Bar::*/;

sub get_foo {
	return Foo->new;
}

# Raw constructors
SCOPE: {
	my $foo = Foo->new;
	my $bar = Bar->new;
	isa_ok( $foo, 'Foo' );
	isa_ok( $bar, 'Bar' );
}

# Scalar context recursive call
SCOPE: {
	my $bar = Bar->new;
	my $foo = &get_foo;
	isa_ok( $bar, 'Bar' );
	isa_ok( $foo, 'Foo' );
	$bar->foo_hello($foo);
}

# List context recursive call
SCOPE: {
	my $bar = Bar->new;
	my @foo = &get_foo;
	isa_ok( $bar, 'Bar' );
	is( scalar(@foo), 1, 'Got 1 element' );
	isa_ok( $foo[0], 'Foo' );
	$bar->foo_hello(@foo);
}

# Void context recursive call
SCOPE: {
	my $bar = Bar->new;
	isa_ok( $bar, 'Bar' );
	$bar->foo_hello(&get_foo);
}





######################################################################
# Support Packages

package Foo;

sub new {
	return bless {}, shift;
}

sub hello {
	Test::More::pass( 'Got to ->hello method' );
}

package Bar;

sub new {
	return bless {}, shift;
}

sub foo_hello {
	my $self = shift;
	my $foo  = shift;
	$foo->hello;
}
