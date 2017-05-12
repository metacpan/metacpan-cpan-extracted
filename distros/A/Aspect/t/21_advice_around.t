#!/usr/bin/perl

# Miscellaneous additional tests for around

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 28;
use Test::NoWarnings;
use Aspect;

my $around = 0;
my $foo    = 0;
my $bar    = 0;
my $baz    = 0;

CLASS: {
	package Foo;

	sub new { bless {}, $_[0] }

	sub foo {
		$foo++;
		return 'foo';
	}

	sub bar {
		$bar++;
		return 'bar';
	}

	sub baz {
		$baz++;
		return 'baz';
	}

	1;
}

# Check that a simple null case (not passing through)
# does not run the function
SCOPE: {
	my $aspect = around { $around++ } call 'Foo::foo';
	isa_ok( $aspect, 'Aspect::Advice::Around' );

	my $object = Foo->new;
	isa_ok( $object, 'Foo' );

	# Check return values in all three contexts
	my @rv = $object->foo;
	my $rv = $object->foo;
	$object->foo;
	is_deeply( \@rv, [ ], 'Listwise null around returns null list' );
	is( $rv, undef, 'Scalar null around returns undef' );
	is( $around, 3, 'Three calls were made to the advice' );
	is( $foo,  0, 'No calls were made to the underlying method' );
}

# Check that the aspect hooks are correctly removed
SCOPE: {
	my $rv = Foo->new->foo;
	is( $rv, 'foo', 'Method now returns correctly' );
	is( $around, 3, 'No additional calls made to the advice' );
	is( $foo,  1, 'Calls were correctly restored to the underlying method' );
}

# Check we can run the original method ourself.
# Check that around aspects in void context last forever.
SCOPE: {
	around {
		$around += 2;
		my $rv = $_[0]->original->();
		$_[0]->return_value($rv);
	} call 'Foo::bar';

	my $object = Foo->new;
	isa_ok( $object, 'Foo' );

	my $rv = $object->bar;
	is( $rv, 'bar', 'Got return value from the underlying call' );
	is( $bar, 1, 'Underlying method was called once' );
	is( $around, 5, 'Advice code was called once' );
}

# Check the hook remains in place
SCOPE: {
	my $rv = Foo->new->bar;
	is( $rv, 'bar', 'Method now returns correctly' );
	is( $around, 7, 'No additional calls made to the advice' );
	is( $bar,  2, 'Calls are correctly kept with the Aspect' );
}

# Check the simplest case of ->run_original method works.
# Check nesting of aspect hooks (particularly expired ones).
# Check complex nested pointcuts with the around method.
SCOPE: {
	my $pointcut = call( qr/^Foo::\w+$/) & ! call( 'Foo::new' );
	around {
		$around += 3;
		$_[0]->proceed;
	} $pointcut;

	my $object = Foo->new;
	isa_ok( $object, 'Foo' );
	is( $around, 7, 'Constructor was not hooked in constructor' );

	my $rv1 = $object->foo;
	my $rv2 = $object->bar;
	my $rv3 = $object->baz;
	is( $rv1, 'foo', 'Nested disabled around works' );
	is( $rv2, 'bar', 'Nested active around works' );
	is( $rv3, 'baz', 'Ordinary ->run_original works' );
	is( $foo, 2, '->foo was called once' );
	is( $bar, 3, '->bar was called once' );
	is( $baz, 1, '->baz was called once' );
	is( $around, 18, 'Advice code was called three times' );
}

# Regression test for RT #63781 Could not get the return value
SCOPE: {
	around {
		$_->proceed;
		is( $_->return_value, 'James Bond', '->return_value ok' );
	} call qr/query_person/;

	is(
		query_person('007'),
		'James Bond',
		'Function returns ok',
	);

	sub query_person {
		return 'James Bond';
	}
}
