#!/usr/bin/perl

# This test validates which usages of return_value are allowed when setting the
# return value, and which are not.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use Aspect;

my $CALLED = 0;

SCOPE: {
	package Foo;

	sub foo {
		$CALLED++;
		return 2;
	}

	sub bar {
		$CALLED++;
		return 3;
	}

	sub baz {
		$CALLED++;
		return 4;
	}

	1;
}

# Set the return value and don't run the function
before {
	$_->return_value(10);
	return;
} call 'Foo::foo';

is( Foo::foo(), 10, 'Foo::foo() returns hijacked return value' );
is( $CALLED, 0, 'Original function was not called' );

# Set the return value in an explicit return
before {
	return $_->return_value(20);
} call 'Foo::bar';

is( Foo::bar(), 20, 'Foo::bar() returns hijacked return value' );
is( $CALLED, 0, 'Original function was not called' );
