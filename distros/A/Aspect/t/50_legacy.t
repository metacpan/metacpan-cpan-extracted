#!/usr/bin/perl

# Does the legacy compatibility interface Aspect::Legacy work as expected

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Test::NoWarnings;
use Aspect::Legacy;





######################################################################
# Before 

SCOPE: {
	package Person;

	use Test::More;

	sub get_foo {
		my $self = shift;
		is_deeply( [ @_ ], [ 'bar', 1, 2, 3 ], 'Params modified' );
		return 'foo';
	}

	package Tester;

	use Test::More;

	sub run_tests {
		my $person = bless { }, 'Person';
		my $foo    = $person->get_foo('bar');
		is( $foo, 'foo', 'Got the correct value' );
	}

	1;
}

my $CALLED = 0;
before {
	$CALLED++;
	my $context = shift;
	is(     $context->type,        'before', '->type ok' );
	isa_ok( $context->self,        'Person' );
	is(     $context->params->[1], 'bar', '->params ok' );
	is( ref($context->original), 'CODE', '->original ok' );
	$context->append_param(1);
	$context->append_params(2, 3);
} call qr/^Person::get_/
& cflow tester => 'Tester::run_tests';

Tester::run_tests();
is( $CALLED, 1, 'Hook fired' );
