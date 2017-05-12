#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 73;
use Test::NoWarnings;
use Test::Exception;
use Aspect ':deprecated';

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
is( $foo,  1, '->foo is called'  );
is( $inc,  1, '->inc is called'  );
is( $boom, 1, '->boom is called' );

# Check that the null case does nothing with exceptions
SCOPE: {
	my $aspect = Aspect::after_throwing {
		# It's oh so quiet...
	} call qr/^My::One::(?:foo|boom)$/;
	is( $object->foo, 'foo', 'Null case does not change anything' );
	throws_ok(
		sub { $object->boom },
		$qrerror,
		'Null case does not trap exceptions',
	);
	is( $foo, 2,  '->foo is called'  );
	is( $boom, 2, '->boom is called' );
}

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled' );
throws_ok( sub { $object->boom }, $qrerror, 'boom uninstalled' );
is( $foo,  3, '->foo is called'  );
is( $boom, 3, '->boom is called' );

# Check that return_value works as expected and does not pass through
SCOPE: {
	my $aspect = Aspect::after_throwing {
		$_->return_value('bar')
	} call qr/^My::One::(?:foo|boom)$/;
	is(
		$object->foo => 'foo',
		'after_throwing does not change return_value',
	);
	is(
		$object->boom => 'bar',
		'after_throwing changes return_value for exception',
	);
	is( $foo,  4, '->foo is called'  );
	is( $boom, 4, '->boom is called' );
}

# ... and uninstalls properly
is( $object->foo, 'foo', 'foo uninstalled' );
throws_ok( sub { $object->boom }, $qrerror, 'boom uninstalled' );
is( $foo,  5, '->foo is called'  );
is( $boom, 5, '->boom is called' );

# Check that proceed fails as expected (reading)
SCOPE: {
	my $aspect = Aspect::after_throwing {
		$_->proceed;
	} call "My::One::boom";
	throws_ok(
		sub { $object->boom },
		qr/Cannot call proceed in after advice/,
		'Throws correct error when process is read from',
	);
	is( $boom, 6, '->boom is called' );
}

# Check that proceed fails as expected (writing)
SCOPE: {
	my $aspect = Aspect::after_throwing {
		$_->proceed(0);
	} call "My::One::boom";
	throws_ok(
		sub { $object->boom },
		qr/Cannot call proceed in after advice/,
		'Throws correct error when process is written to',
	);
	is( $boom, 7, '->boom is called' );
}

# ... and uninstalls properly
throws_ok( sub { $object->boom }, $qrerror, 'boom uninstalled' );
is( $boom, 8, '->boom is called' );

# Check that we can rehook the same function.
# Check that we can run several simultaneous hooks.
SCOPE: {
	my $aspect1 = Aspect::after_throwing {
		$_->exception( 'one ' . $_->exception );
	} call qr/My::One::boom/;
	my $aspect2 = Aspect::after_throwing {
		$_->exception( 'two ' . $_->exception );
	} call qr/My::One::boom/;
	my $aspect3 = Aspect::after_throwing {
		$_->exception( 'three ' . $_->exception );
	} call qr/My::One::boom/;
	throws_ok(
		sub { $object->boom },
		qr/^three two one $qerror$/,
		'boom multi-wrapped',
	);
	is( $boom, 9, '->boom is called' );
}

# ... and uninstalls properly
throws_ok( sub { $object->boom }, $qrerror, 'boom uninstalled' );
is( $boom, 10, '->boom is called' );

# Check the introduction of a permanent hook.
# Check alteration of the exception.
SCOPE: {
	Aspect::after_throwing {
		$_->exception('blah');
	} call 'My::One::boom';
}
throws_ok( sub { $object->boom }, qr/blah/, 'boom permanently hooked' );
is( $boom, 11, '->boom is called' );





######################################################################
# Usage with Cflow

# Check before hook installation
throws_ok( sub { $object->boom }, qr/blah/, 'boom cflow is not installed' );
throws_ok( sub { $object->bang }, qr/blah/, 'bang cflow is not installed' );
is( $bang, 1,  '->bang is called' );
is( $boom, 13, '->boom is called for both' );

SCOPE: {
	my $advice = Aspect::after_throwing {
		my $c = shift;
		$c->return_value($c->my_key->self);
	} call "My::One::boom"
	& cflow my_key => "My::One::bang";

	# ->boom is hooked when called via ->bang, but not directly
	is( $object->bang, $object, 'boom cflow installed' );
	is( $bang, 2,  '->bang is called' );
	is( $boom, 14, '->boom is called' );
	throws_ok(
		sub { $object->boom },
		qr/blah/,
		'boom called out of the cflow',
	);
	is( $boom, 15, '->boom is called' );
}

# Confirm original behaviour on uninstallation
throws_ok( sub { $object->boom }, qr/blah/, 'boom cflow is not installed' );
throws_ok( sub { $object->bang }, qr/blah/, 'bang cflow is not installed' );
is( $bang, 3,  '->bang is called' );
is( $boom, 17, '->boom is called for both' );





######################################################################
# Prototype Support

sub main::no_proto       { die shift }
sub main::with_proto ($) { die shift }

# Control case
SCOPE: {
	my $advice = Aspect::after_throwing {
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
	my $advice = Aspect::after_throwing {
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
	my $aspect = Aspect::after_throwing { $AFTER++ } call 'My::Three::bar';
	isa_ok( $aspect, 'Aspect::Advice' );
	isa_ok( $aspect, 'Aspect::Advice::After' );
	is( $AFTER,          0, '$AFTER is false' );
	is( scalar(@CALLER), 0, '@CALLER is empty' );

	# Call a method above the wrapped method
	throws_ok( sub { My::Two->foo }, qr/value/, '->foo is ok' );
	is( $AFTER,          1, '$AFTER is true' );
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
		die 'value';
	}
}





######################################################################
# Wantarray Support

my @CONTEXT = ();

# Before the aspects
SCOPE: {
	throws_ok(
		sub { () = Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
	throws_ok(
		sub { my $dummy = Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
	throws_ok(
		sub { Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
}

SCOPE: {
	my $aspect = Aspect::after_throwing {
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
	} call 'Foo::after_throwing';

	# During the aspects
	throws_ok(
		sub { () = Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
	throws_ok(
		sub { my $dummy = Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
	throws_ok(
		sub { Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
}

# After the aspects
SCOPE: {
	throws_ok(
		sub { () = Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
	throws_ok(
		sub { my $dummy = Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
	throws_ok(
		sub { Foo->after_throwing },
		qr/bang/,
		'after_throwing before throws ok',
	);
}

# Check the results in aggregate
is_deeply(
	\@CONTEXT,
	[ qw{
		array
		scalar
		void
		array ARRAY VOID
		scalar SCALAR VOID
		void VOID VOID
		array
		scalar
		void
	} ],
	'All wantarray contexts worked as expected for after_throwing',
);

SCOPE: {
	package Foo;

	sub after_throwing {
		if ( wantarray ) {
			push @CONTEXT, 'array';
		} elsif ( defined wantarray ) {
			push @CONTEXT, 'scalar';
		} else {
			push @CONTEXT, 'void';
		}
		die 'bang';
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
