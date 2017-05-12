#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 35;
use Test::NoWarnings;
use Aspect;

my $good = 'SomePackage::some_method';
my $bad  = 'SomePackage::no_method';

pointcut_ok( string => 'SomePackage::some_method' );
pointcut_ok( re     => qr/some_method/            );
pointcut_ok( code   => sub { shift eq $good }     );

sub pointcut_ok {
	my $type      = shift;
	my $subject   = Aspect::Pointcut::Call->new(shift);

	# Do we get a compiled match function?
	my $compiled1 = $subject->compiled_weave;
	is( ref($compiled1), 'CODE', '->compiled_weave returns a CODE reference' );

	# Does it match the expected functions?
	my $good_matches = do { local $_ = $good; $compiled1->() };
	my $bad_matches  = do { local $_ = $bad;  $compiled1->() };
	ok(   $good_matches, "$type match"    );
	ok( ! $bad_matches,  "$type no match" );

	# Does it curry away to nothing?
	my $curried = $subject->curry_runtime;
	is( $curried, undef, 'Simple call curries away to nothing' );

	# Do we produce an appropriate compiled run-time function
	my $compiled2 = $subject->compiled_runtime;
	is( ref($compiled2), 'CODE', '->compiled_runtime returns a CODE reference' );

	# Does the compiled code work properly?
	my $good_match = do {
		local $Aspect::POINT = { sub_name => $good };
		$compiled2->();
	};
	my $bad_match = do {
		local $Aspect::POINT = { sub_name => $bad };
		$compiled2->();
	};
	ok(   $good_match, "$type match"    );
	ok( ! $bad_match,  "$type no match" );
}





######################################################################
# Overloading Tests

# Pointcut currying code will need to do boolean context checks on
# pointcuts, as will some user code.
# Validate we can actually be used in boolean context (and provide an
# entry point to examine where this overloads to in the debugger).
my $pointcut = call 'Foo::bar';
isa_ok( $pointcut, 'Aspect::Pointcut::Call' );
ok( $pointcut, 'Pointcut is usable in boolean context' );

# Test that negation creates a not pointcut
isa_ok( ! $pointcut, 'Aspect::Pointcut::Not' );





######################################################################
# Regression: Validate that the "not call and call" pattern works.

# The following package has two methods.
# A pointcut that defines "Not one and any method" should match two but
# not match one. And this rule should apply BOTH to the match_all
# define-time rule AND for the runtime rule.
SCOPE: {
	package One;

	sub one { }

	sub two { }
}

my $not_call_and_call = ! call('One::one') & call(qr/^One::/);
isa_ok( $not_call_and_call, 'Aspect::Pointcut::And' );

# Does match_all find only the second method?
is_deeply(
	[ $not_call_and_call->match_all ],
	[ 'One::two' ],
	'->match_all works as expected',
);

# Create the runtime-curried pointcut
my $curried = $not_call_and_call->curry_runtime;
is( $curried, undef, 'A call-only pointcut curries away to nothing' );





######################################################################
# Regression: Nested logic and nested call and run-time

# Combining nested logic with a mix of call and non-call pointcuts
# results in a situation where call pointcuts need to be retained
# at run-time so that we can limit calls to run-time pointcuts to the
# correct subset of cases to apply the run-time tests to.
SCOPE: {
	package Two;

	sub one { 1 }

	sub two { 2 }
}

my $complex = call qr/^Two::/ & (
	call qr/::one\z/
	| (
		wantscalar & call qr/::two\z/
	)
);
isa_ok( $complex, 'Aspect::Pointcut' );

ok(
	scalar $complex->match_contains('Aspect::Pointcut::Wantarray'),
	'Pointcut contains the Wantarray pointcut',
);

# We should match_all both functions
is_deeply(
	[ sort $complex->match_all ], #sort for new hash randomization
	[ 'Two::one', 'Two::two' ],
	'->match_all works as expected',
);

# Bind the aspect
before {
	$_[0]->return_value(0);
} $complex;

# Both functions should match in scalar context
is( scalar(Two::one()), 0, 'Scalar one matches' );
is( scalar(Two::two()), 0, 'Scalar two matches' );

# Only one should match in list context
is_deeply( [ Two::one() ], [ 0 ], 'List one matches' );
is_deeply( [ Two::two() ], [ 2 ], 'List two does not match' );
