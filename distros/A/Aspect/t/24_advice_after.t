#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 103;
use Test::NoWarnings;
use Test::Exception;
use Aspect;

# Lexicals to track call counts in the support class
my $new  = 0;
my $foo  = 0;
my $bar  = 0;
my $inc  = 0;
my $boom = 0;
my $bang = 0;

# Create the test object
my $object = My::One->new;
isa_ok( $object, 'My::One' );
is( $new, 1, '->new 1' );





######################################################################
# Basic Usage

# Do the methods act as normal
is( $object->foo, 'foo', 'foo not yet installed' );
is( $object->inc(2), 3,  'inc not yet installed' );
eval { $object->boom };
my $error   = $@;
my $qerror  = quotemeta $error;
my $qrerror = qr/^$qerror\z/;
is( $foo,  1, '->foo is called' );
is( $inc,  1, '->inc is called' );
is( $boom, 1, '->boom is called' );

# Check that the null case does nothing
SCOPE: {
	my $aspect = after {
		# It's oh so quiet...
	} call 'My::One::foo';
	is( $object->foo, 'foo', 'Null case does not change anything' );
	is( $foo, 2, '->foo is called' );
}

# Check that the null case does nothing with exceptions
my $null = 0;
SCOPE: {
	my $aspect = after {
		# It's oh so quiet...
		$null++;
	} call qr/^My::One::(?:foo|boom)$/;
	is( $object->foo, 'foo', 'Null case does not change anything' );
	throws_ok(
		sub { $object->boom },
		$qrerror,
		'Null case does not trap exceptions',
	);
	is( $null, 2, 'null advice called twice' );
	is( $foo,  3, '->foo is called'         );
	is( $boom, 2, '->boom is called'        );
}

# ... and uninstalls properly
is( $null, 2, 'null advice not called' );
is( $object->foo, 'foo', 'foo uninstalled' );
is( $foo, 4, '->foo is called' );

# Check that return_value works as expected with and without exceptions
SCOPE: {
	my $aspect = after {
		$_->return_value('bar')
	} call qr/^My::One::(?:foo|boom)$/;
	is(
		$object->foo => 'bar',
		'after changes return_value for non-exception',
	);
	is(
		$object->boom => 'bar',
		'after changes return_value for exception',
	);
	is( $foo,  5, '->foo is called'  );
	is( $boom, 3, '->boom is called' );
}

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled' );
throws_ok(
	sub { $object->boom },
	$qrerror,
	'Null case does not trap exceptions',
);
is( $foo,  6, '->foo is called'  );
is( $boom, 4, '->boom is called' );

# Check that proceed fails as expected (reading)
SCOPE: {
	my $aspect = after {
		$_->proceed;
	} call qr/^My::One::(?:foo|boom)$/;
	throws_ok(
		sub { $object->foo },
		qr/Cannot call proceed in after advice/,
		'Throws correct error when process is read from',
	);
	throws_ok(
		sub { $object->boom },
		qr/Cannot call proceed in after advice/,
		'Throws correct error when process is read from during exception',
	);
	is( $foo, 7,  '->foo is called'  );
	is( $boom, 5, '->boom is called' );
}

# Check that proceed fails as expected (writing)
SCOPE: {
	my $aspect = after {
		$_->proceed(0);
	} call qr/^My::One::(?:foo|boom)$/;
	throws_ok(
		sub { $object->foo },
		qr/Cannot call proceed in after advice/,
		'Throws correct error when process is written to',
	);
	throws_ok(
		sub { $object->boom },
		qr/Cannot call proceed in after advice/,
		'Throws correct error when process is read from during exception',
	);
	is( $foo,  8, '->foo is called'  );
	is( $boom, 6, '->boom is called' );
}

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled' );
is( $foo, 9, '->foo is called' );

# Check that params works as expected and does pass through
SCOPE: {
	my $aspect = after {
		my @p = $_->args;
		splice @p, 1, 1, $p[1] + 1;
		$_->args(@p);
	} call qr/My::One::inc/;
	is( $object->inc(2), 3, 'after advice changing params does nothing' );
	is( $inc, 2, '->inc is called' );
}

# Check that we can rehook the same function.
# Check that we can run several simultaneous hooks.
SCOPE: {
	my $aspect1 = after {
		$_->return_value( $_->return_value + 2 );
	} call qr/My::One::inc/;
	my $aspect2 = after {
		$_->exception( $_->return_value + 3 );
	} call qr/My::One::inc/;
	my $aspect3 = after {
		my $e = $_->exception;
		$e =~ s/\D.+//;
		$_->return_value( $e + 4 );
	} call qr/My::One::inc/;
	is( $object->inc(2), 12, 'after advice changing params' );
	is( $inc, 3, '->inc is called' );
}

# Were the hooks removed cleanly?
is( $object->inc(3), 4, 'inc uninstalled' );
is( $inc, 4, '->inc is called' );

# Check the introduction of a permanent hook
SCOPE: {
	after {
		$_->exception('forever');
	} call qr/^My::One::(?:inc|boom)$/;
}
throws_ok(
	sub { $object->inc(1) },
	qr/forever/,
	'->inc hooked forever',
);
throws_ok(
	sub { $object->boom },
	qr/forever/,
	'->boom hooked forever',
);
is( $inc,  5, '->inc is called'  );
is( $boom, 7, '->boom is called' );





######################################################################
# Usage with Cflow

# Check before hook installation
is( $object->bar, 'foo', 'bar cflow not yet installed' );
is( $object->foo, 'foo', 'foo cflow not yet installed' );
throws_ok(
	sub { $object->boom },
	qr/forever/,
	'boom cflow is not installed',
);
throws_ok(
	sub { $object->bang },
	qr/forever/,
	'bang cflow is not installed',
);
is( $bar, 1,  '->bar is called' );
is( $foo, 11, '->foo is called for both ->bar and ->foo' );
is( $bang, 1,  '->bang is called' );
is( $boom, 9, '->boom is called for both' );

SCOPE: {
	my $advice = after {
		my $c = shift;
		$c->return_value( $c->my_key->self );
	} call qr/^My::One::(?:foo|boom)$/
	& cflow my_key => qr/^My::One::(?:bar|bang)$/;

	# ->foo is hooked when called via ->bar, but not directly
	is( $object->bar, $object, 'foo cflow installed' );
	is( $bar, 2,  '->bar is called' );
	is( $foo, 12, '->foo is called' );
	is( $object->foo, 'foo', 'foo called out of the cflow' );
	is( $foo, 13, '->foo is called' );

	# ->boom is hooked when called via ->bang, but not directly
	is( $object->bang, $object, 'boom cflow installed' );
	is( $bang, 2,  '->bang is called' );
	is( $boom, 10, '->boom is called' );
	throws_ok(
		sub { $object->boom },
		qr/forever/,
		'boom called out of the cflow',
	);
	is( $boom, 11, '->boom is called' );
}

# Confirm original behaviour on uninstallation
is( $object->bar, 'foo', 'bar cflow uninstalled' );
is( $object->foo, 'foo', 'foo cflow uninstalled' );
throws_ok(
	sub { $object->boom },
	qr/forever/,
	'boom cflow is not installed',
);
throws_ok(
	sub { $object->bang },
	qr/forever/,
	'bang cflow is not installed',
);
is( $bar, 3,  '->bar is called' );
is( $foo, 15, '->foo is called for both' );
is( $bang, 3,  '->bang is called' );
is( $boom, 13, '->boom is called for both' );





######################################################################
# Prototype Support

sub main::no_proto       { shift }
sub main::with_proto ($) { shift }

# Control case
SCOPE: {
	my $advice = after {
		$_->return_value('wrapped')
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
	my $advice = after {
		$_->return_value('wrapped');
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
my $AFTER  = 0;

SCOPE: {
	# Set up the Aspect
	my $aspect = after { $AFTER++ } call qr/^My::Three::d?bar$/;
	isa_ok( $aspect, 'Aspect::Advice' );
	isa_ok( $aspect, 'Aspect::Advice::After' );
	is( $AFTER,          0, '$AFTER is false' );
	is( scalar(@CALLER), 0, '@CALLER is empty' );

	# Call a method above the wrapped method
	my $rv = My::Two->foo;
	is( $rv, 'value', '->foo is ok' );
	is( $AFTER,          1, '$AFTER is true' );
	is( scalar(@CALLER), 2, '@CALLER is full' );
	is( $CALLER[0]->[0], 'My::Two', 'First caller is My::Two' );
	is( $CALLER[1]->[0], 'main', 'Second caller is main' );

	# Call a method above the wrapped method
	throws_ok( sub { My::Two->dfoo }, qr/value/, '->foo is ok' );
	is( $AFTER,          2, '$AFTER is true' );
	is( scalar(@CALLER), 2, '@CALLER is full' );
	is( $CALLER[0]->[0], 'My::Two', 'First caller is My::Two' );
	is( $CALLER[1]->[0], 'main', 'Second caller is main' );
}

SCOPE: {
	package My::Two;

	sub foo {
		My::Three->bar;
	}

	sub dfoo {
		My::Three->dbar;
	}

	package My::Three;

	sub bar {
		@CALLER = (
			[ caller(0) ],
			[ caller(1) ],
		);
		return 'value';
	}

	sub dbar {
		@CALLER = (
			[ caller(0) ],
			[ caller(1) ],
		);
		die 'value';
	}
}





######################################################################
# Wantarray Support

our $THROW   = 0;
my @CONTEXT = ();

# Before the aspects
SCOPE: {
	() = Foo->after;
	my $dummy = Foo->after;
	Foo->after;

	local $THROW = 1;

	throws_ok(
		sub { () = Foo->after },
		qr/bang/,
		'after before throws ok',
	);
	throws_ok(
		sub { my $dummy = Foo->after },
		qr/bang/,
		'after before throws ok',
	);
	throws_ok(
		sub { Foo->after },
		qr/bang/,
		'after before throws ok',
	);
}

SCOPE: {
	my $aspect = after {
		if ( $_[0]->wantarray ) {
			push @CONTEXT, 'ARRAY';
		} elsif ( defined $_[0]->wantarray ) {
			push @CONTEXT, 'SCALAR';
		} else {
			push @CONTEXT, 'VOID';
		}
		if ( wantarray ) {
			push @CONTEXT, 'ARRAY';
		} elsif ( defined wantarray ) {
			push @CONTEXT, 'SCALAR';
		} else {
			push @CONTEXT, 'VOID';
		}
	} call 'Foo::after';

	# During the aspects
	() = Foo->after;
	my $dummy = Foo->after;
	Foo->after;

	local $THROW = 1;

	throws_ok(
		sub { () = Foo->after },
		qr/bang/,
		'after before throws ok',
	);
	throws_ok(
		sub { my $dummy = Foo->after },
		qr/bang/,
		'after before throws ok',
	);
	throws_ok(
		sub { Foo->after },
		qr/bang/,
		'after before throws ok',
	);
}

# After the aspects
SCOPE: {
	() = Foo->after;
	my $dummy = Foo->after;
	Foo->after;

	local $THROW = 1;

	throws_ok(
		sub { () = Foo->after },
		qr/bang/,
		'after before throws ok',
	);
	throws_ok(
		sub { my $dummy = Foo->after },
		qr/bang/,
		'after before throws ok',
	);
	throws_ok(
		sub { Foo->after },
		qr/bang/,
		'after before throws ok',
	);
}

# Check the results in aggregate
is_deeply(
	\@CONTEXT,
	[ qw{
		array
		scalar
		void
		array
		scalar
		void
		array ARRAY VOID
		scalar SCALAR VOID
		void VOID VOID
		array ARRAY VOID
		scalar SCALAR VOID
		void VOID VOID
		array
		scalar
		void
		array
		scalar
		void
	} ],
	'All wantarray contexts worked as expected for after',
);

SCOPE: {
	package Foo;

	sub after {
		if ( wantarray ) {
			push @CONTEXT, 'array';
		} elsif ( defined wantarray ) {
			push @CONTEXT, 'scalar';
		} else {
			push @CONTEXT, 'void';
		}
		die 'bang' if $THROW;
	}
}

# Regression test for RT #63781 Could not get the return value
SCOPE: {
	after {
		is( $_->return_value, 'James Bond', '->return_value ok' );
	} call qr/query_person/;

	is(
		query_person(),
		'James Bond',
		'Function returns ok',
	);

	sub query_person {
		return 'James Bond';
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

sub boom {
	$boom++;
	die $_[1] || 'explosion';
}

sub bang {
	$bang++;
	return shift->boom;
}
