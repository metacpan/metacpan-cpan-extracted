#!/usr/bin/perl

# This is a duplicate of 22_advice_around.t with all the join point functions
# changed.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 60;
use Test::NoWarnings;
use Test::Exception;
use Aspect;
use Aspect::Point::Functions;

# Lexicals to track call counts in the support class
my $new = 0;
my $foo = 0;
my $bar = 0;
my $inc = 0;

# Create the test object
my $object = My::One->new;
isa_ok( $object, 'My::One' );
is( $new, 1, '->new 1' );





######################################################################
# Basic Usage

# Do the methods act as normal
is( $object->foo, 'foo', 'foo not yet installed' );
is( $object->inc(2), 3,  'inc not yet installed' );
is( $foo, 1, '->foo is called' );
is( $inc, 1, '->inc is called' );

# Check that the null case does nothing
SCOPE: {
	my $aspect = around {
		# It's oh so quiet...
	} call 'My::One::foo';
	is( scalar($object->foo), undef, 'Scalar null case returns undef' );
	is_deeply( [ $object->foo ], [ ], 'Listwise null case returns ()' );
	is( $foo, 1, '->foo is not called' );
}

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled' );
is( $foo, 2, '->foo is called' );

# Check that the null pass-through case works properly
SCOPE: {
	my $aspect = around {
		proceed;
	} call 'My::One::foo';
	is( $object->foo, 'foo', 'Pass-through null case returns normally' );
	is( $foo, 3, '->foo is called' );
}

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled' );
is( $foo, 4, '->foo is called' );

# Check that shortcutting return_value works and does not pass through
SCOPE: {
	my $aspect = around {
		return_value('bar')
	} call "My::One::foo";
	is( $object->foo, 'bar', 'around changing return_value' );
	is( $foo, 4, '->foo is not called' );
}

# Check that return_value is changable after pass-through
SCOPE: {
	my $aspect = around {
		proceed;
		return_value( return_value . 'bar' );
	} call "My::One::foo";
	is( $object->foo, 'foobar', 'around changing return_value' );
	is( $foo, 5, '->foo is called' );
}

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled' );
is( $foo, 6, '->foo is called' );

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled ok' );
is( $foo, 7, '->foo is called' );

# Check that params works as expected and does pass through
SCOPE: {
	my $aspect = around {
		my @p = args;
		splice @p, 1, 1, $p[1] + 1;
		args(@p);
		proceed;
	} call qr/My::One::inc/;
	is( $object->inc(2), 4, 'around advice changing params' );
	is( $inc, 2, '->inc is called' );
}

# Check that we can rehook the same function.
# Check that we can run several simultaneous hooks.
SCOPE: {
	my $aspect1 = around {
		my @p = args;
		splice @p, 1, 1, $p[1] + 1;
		args(@p);
		proceed;
	} call qr/My::One::inc/;
	my $aspect2 = around {
		my @p = args;
		splice @p, 1, 1, $p[1] + 1;
		args(@p);
		proceed;
	} call qr/My::One::inc/;
	my $aspect3 = around {
		my @p = args;
		splice @p, 1, 1, $p[1] + 1;
		args(@p);
		proceed;
	} call qr/My::One::inc/;
	is( $object->inc(2), 6, 'around advice changing params' );
	is( $inc, 3, '->inc is called' );
}

# Were the hooks removed cleanly?
is( $object->inc(3), 4, 'inc uninstalled' );
is( $inc, 4, '->inc is called' );

# Check the introduction of a permanent hook
around {
	return_value('forever');
} call 'My::One::inc';
is( $object->inc, 'forever', '->inc hooked forever' );
is( $inc, 4, '->inc not called' );





######################################################################
# Usage with Cflow

# Check before hook installation
is( $object->bar, 'foo', 'bar cflow not yet installed' );
is( $object->foo, 'foo', 'foo cflow not yet installed' );
is( $bar, 1, '->bar is called' );
is( $foo, 9, '->foo is called for both ->bar and ->foo' );

SCOPE: {
	my $advice = around {
		return_value( $_->my_key->self );
	} call "My::One::foo"
	& cflow my_key => "My::One::bar";

	# ->foo is hooked when called via ->bar, but not directly
	is( $object->bar, $object, 'foo cflow installed' );
	is( $bar, 2, '->bar is called' );
	is( $foo, 9, '->foo is not called' );
	is( $object->foo, 'foo', 'foo called out of the cflow' );
	is( $foo, 10, '->foo is called' );
}

# Confirm original behaviour on uninstallation
is( $object->bar, 'foo', 'bar cflow uninstalled' );
is( $object->foo, 'foo', 'foo cflow uninstalled' );
is( $bar, 3,  '->bar is called' );
is( $foo, 12, '->foo is called for both' );





######################################################################
# Prototype Support

sub main::no_proto       { shift }
sub main::with_proto ($) { shift }

# Control case
SCOPE: {
	my $advice = around {
		return_value('wrapped')
	} call 'main::no_proto';
	is( main::no_proto('foo'), 'wrapped', 'No prototype' );
}

# Confirm correct parameter error before hooking
SCOPE: {
	local $@;
	eval 'main::with_proto(1, 2)';
	like( $@, qr/Too many arguments/, 'prototypes are obeyed' );
}

# Confirm correct parameter error during hooking
SCOPE: {
	my $advice = around {
		return_value('wrapped');
	} call 'main::with_proto';
	is( main::with_proto('foo'), 'wrapped', 'With prototype' );

	local $@;
	eval 'main::with_proto(1, 2)';
	like( $@, qr/Too many arguments/, 'prototypes are obeyed' );
}

# Confirm correct parameter error after hooking
SCOPE: {
	local $@;
	eval 'main::with_proto(1, 2)';
	like( $@, qr/Too many arguments/, 'prototypes are obeyed' );
}





######################################################################
# Caller Correctness

my @CALLER = ();
my $AROUND = 0;

SCOPE: {
	# Set up the Aspect
	my $aspect = around {
		$AROUND++;
		proceed;
	} call 'My::Three::bar';
	isa_ok( $aspect, 'Aspect::Advice' );
	isa_ok( $aspect, 'Aspect::Advice::Around' );
	is( $AROUND,         0, '$AROUND is false' );
	is( scalar(@CALLER), 0, '@CALLER is empty' );

	# Call a method above the wrapped method
	my $rv = My::Two->foo;
	is( $rv, 'value', '->foo is ok' );
	is( $AROUND,         1, '$AROUND is true' );
	is( scalar(@CALLER), 2, '@CALLER is full' );
	is( $CALLER[0]->[0], 'My::Two', 'First caller is My::Two' );
	is( $CALLER[1]->[0], 'main', 'Second caller is main' );
}

SCOPE: {
	package My::Two;

	sub foo {
		My::Three->bar;
	}

	package My::Three;

	sub bar {
		@CALLER = (
			[ caller(0) ],
			[ caller(1) ],
		);
		return 'value';
	}
}





######################################################################
# Wantarray Support

my @CONTEXT = ();

# Before the aspects
SCOPE: {
	() = Foo->around;
	my $dummy = Foo->around;
	Foo->around;
}

SCOPE: {
	my $aspect = around {
		if ( wantarray ) {
			push @CONTEXT, 'ARRAY';
		} elsif ( defined wantarray ) {
			push @CONTEXT, 'SCALAR';
		} else {
			push @CONTEXT, 'VOID';
		}
		if ( CORE::wantarray ) {
			push @CONTEXT, 'ARRAY';
		} elsif ( defined CORE::wantarray ) {
			push @CONTEXT, 'SCALAR';
		} else {
			push @CONTEXT, 'VOID';
		}
		proceed;
	} call 'Foo::around';

	# During the aspects
	() = Foo->around;
	my $dummy = Foo->around;
	Foo->around;
}

# After the aspects
SCOPE: {
	() = Foo->around;
	my $dummy = Foo->around;
	Foo->around;
}

# Check the results in aggregate
is_deeply(
	\@CONTEXT,
	[ qw{
		array
		scalar
		void
		ARRAY VOID array
		SCALAR VOID scalar
		VOID VOID void
		array
		scalar
		void
	} ],
	'All wantarray contexts worked as expected for around',
);

SCOPE: {
	package Foo;

	sub around {
		if ( CORE::wantarray ) {
			push @CONTEXT, 'array';
		} elsif ( defined CORE::wantarray ) {
			push @CONTEXT, 'scalar';
		} else {
			push @CONTEXT, 'void';
		}
	}
}





######################################################################
# Support Classes

package My::One;

sub new {
	$new++;
	bless {}, shift;
}

sub foo {
	$foo++;
	return 'foo';
}

sub bar {
	$bar++;
	return shift->foo;
}

sub inc {
	$inc++;
	return $_[1] + 1;
}

