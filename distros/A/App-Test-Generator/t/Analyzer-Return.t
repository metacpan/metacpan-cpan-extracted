#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird 0.08;
use Readonly;

BEGIN { use_ok('App::Test::Generator::Analyzer::Return') }

# --------------------------------------------------
# Constants matching the weights declared in the
# module under test -- kept here so a weight change
# in the source causes a deliberate test failure
# rather than silently passing with wrong values
# --------------------------------------------------
Readonly my $WEIGHT_RETURNS_PROPERTY => 20;
Readonly my $WEIGHT_RETURNS_SELF     => 15;
Readonly my $WEIGHT_RETURNS_CONSTANT => 10;

# --------------------------------------------------
# Helper: build a mock method object whose source
# returns the given string and whose add_evidence
# calls are captured into an arrayref.
# Uses Test::Mockingbird to avoid depending on
# Model::Method's internal API at this test level.
# --------------------------------------------------
sub _mock_method {
	my ($source) = @_;

	# Captured evidence calls accumulate here
	my @evidence;

	# Build a plain object in a throw-away package
	my $obj = bless {
		source   => $source // '',
		evidence => \@evidence,
	}, 'MockMethod';

	# Install source() and add_evidence() via Mockingbird
	# so the analyser can call them without depending on
	# the real Model::Method API
	mock 'MockMethod::source' => sub { $_[0]->{source} };
	mock 'MockMethod::add_evidence' => sub {
		my ($self, %args) = @_;
		push @{ $self->{evidence} }, \%args;
	};

	return ($obj, \@evidence);
}

# --------------------------------------------------
# Helper: run analyze against a mock method object
# and return the captured evidence arrayref.
# Restores all mocks after each call so subtests
# do not interfere with each other.
# --------------------------------------------------
sub _evidence_after {
	my ($source) = @_;
	my ($mock, $evidence) = _mock_method($source);
	my $analyser = App::Test::Generator::Analyzer::Return->new();
	$analyser->analyze($mock);
	restore_all();
	return $evidence;
}

# ==================================================================
# new
# --------------------------------------------------
# Tests for the constructor
# ==================================================================
subtest 'new' => sub {
	# Constructor returns a defined blessed object
	my $analyser = App::Test::Generator::Analyzer::Return->new();
	ok(defined $analyser, 'new() returns defined value');
	isa_ok($analyser, 'App::Test::Generator::Analyzer::Return');

	# Object is a plain blessed hashref in the correct class
	is(ref($analyser), 'App::Test::Generator::Analyzer::Return',
		'object is blessed into correct class');

	# A second call produces a distinct object of the same class
	my $analyser2 = App::Test::Generator::Analyzer::Return->new();
	isa_ok($analyser2, 'App::Test::Generator::Analyzer::Return',
		'second new() returns correct class');
	isnt($analyser, $analyser2, 'each call produces a distinct object');

	done_testing();
};

# ==================================================================
# analyze -- return value
# --------------------------------------------------
# analyze() must return undef -- all results are
# communicated via side effects on the method object
# ==================================================================
subtest 'analyze returns undef' => sub {
	my ($mock, $evidence) = _mock_method('sub foo { return 1; }');
	my $analyser = App::Test::Generator::Analyzer::Return->new();

	# The return value must be undef regardless of what is detected
	my $result = $analyser->analyze($mock);
	is($result, undef, 'analyze() returns undef');

	restore_all();
	done_testing();
};

# ==================================================================
# analyze -- returns_property signal
# --------------------------------------------------
# Pattern: return $self->{property}
# ==================================================================
subtest 'analyze detects returns_property' => sub {
	# Basic property return captures the property name
	my $ev = _evidence_after(
		'sub name { my $self = shift; return $self->{name}; }'
	);
	my @prop = grep { $_->{signal} eq 'returns_property' } @{$ev};
	is(scalar @prop, 1,                       'one returns_property signal detected');
	is($prop[0]{category}, 'return',          'category is return');
	is($prop[0]{weight},   $WEIGHT_RETURNS_PROPERTY, 'weight matches constant');
	is($prop[0]{value},    'name',            'property name captured');

	# Different property name is captured correctly
	$ev = _evidence_after(
		'sub get_count { my $self = shift; return $self->{count}; }'
	);
	@prop = grep { $_->{signal} eq 'returns_property' } @{$ev};
	is(scalar @prop, 1,           'one returns_property signal for count');
	is($prop[0]{value}, 'count',  'property name count captured');

	# Underscore-prefixed internal property name is captured
	$ev = _evidence_after('sub foo { return $self->{_internal}; }');
	@prop = grep { $_->{signal} eq 'returns_property' } @{$ev};
	is(scalar @prop, 1,                '_internal property detected');
	is($prop[0]{value}, '_internal',   '_internal property name captured');

	done_testing();
};

# ==================================================================
# analyze -- returns_property is NOT triggered by
# plain return $self (negative lookahead guard)
# ==================================================================
subtest 'analyze: returns_property not triggered by plain $self' => sub {
	# Plain "return $self" must not trigger returns_property
	my $ev = _evidence_after(
		'sub foo { my $self = shift; return $self; }'
	);
	my @prop = grep { $_->{signal} eq 'returns_property' } @{$ev};
	is(scalar @prop, 0, 'returns_property not triggered by plain return $self');

	done_testing();
};

# ==================================================================
# analyze -- returns_self signal
# --------------------------------------------------
# Pattern: return $self (not followed by ->)
# ==================================================================
subtest 'analyze detects returns_self' => sub {
	# Plain return $self for method chaining
	my $source = 'sub set_name { my ($self, $n) = @_; $self->{name} = $n; return $self; }';
	my $ev = _evidence_after($source);
	my @self_ev = grep { $_->{signal} eq 'returns_self' } @{$ev};
	is(scalar @self_ev, 1,                        'one returns_self signal detected');
	is($self_ev[0]{category}, 'return',           'category is return');
	is($self_ev[0]{weight},   $WEIGHT_RETURNS_SELF, 'weight matches constant');

	# return $self across multiple lines
	$ev = _evidence_after("sub chain {\n\tmy \$self = shift;\n\treturn \$self;\n}");
	@self_ev = grep { $_->{signal} eq 'returns_self' } @{$ev};
	is(scalar @self_ev, 1, 'returns_self detected across newlines');

	done_testing();
};

# ==================================================================
# analyze -- returns_self is NOT triggered by
# return $self->{property}
# ==================================================================
subtest 'analyze: returns_self not triggered by $self->{prop}' => sub {
	# return $self->{property} must not add a returns_self signal
	my $ev = _evidence_after('sub name { return $self->{name}; }');
	my @self_ev = grep { $_->{signal} eq 'returns_self' } @{$ev};
	is(scalar @self_ev, 0, 'returns_self not triggered by $self->{prop}');

	done_testing();
};

# ==================================================================
# analyze -- returns_constant signal
# --------------------------------------------------
# Pattern: return of quoted string, numeric literal,
# or the bare word undef
# ==================================================================
subtest 'analyze detects returns_constant' => sub {
	# Numeric literal 1 (common boolean success indicator)
	my $ev = _evidence_after('sub ok { return 1; }');
	my @const = grep { $_->{signal} eq 'returns_constant' } @{$ev};
	is(scalar @const, 1,                        'returns_constant detected for return 1');
	is($const[0]{category}, 'return',           'category is return');
	is($const[0]{weight},   $WEIGHT_RETURNS_CONSTANT, 'weight matches constant');

	# Numeric literal 0
	$ev = _evidence_after('sub fail { return 0; }');
	@const = grep { $_->{signal} eq 'returns_constant' } @{$ev};
	is(scalar @const, 1, 'returns_constant detected for return 0');

	# Single-quoted string literal
	$ev = _evidence_after("sub label { return 'hello'; }");
	@const = grep { $_->{signal} eq 'returns_constant' } @{$ev};
	is(scalar @const, 1, 'returns_constant detected for single-quoted string');

	# Double-quoted string literal
	$ev = _evidence_after('sub greeting { return "hello"; }');
	@const = grep { $_->{signal} eq 'returns_constant' } @{$ev};
	is(scalar @const, 1, 'returns_constant detected for double-quoted string');

	# Bare undef return
	$ev = _evidence_after('sub nothing { return undef; }');
	@const = grep { $_->{signal} eq 'returns_constant' } @{$ev};
	is(scalar @const, 1, 'returns_constant detected for return undef');

	# Multi-digit integer
	$ev = _evidence_after('sub port { return 8080; }');
	@const = grep { $_->{signal} eq 'returns_constant' } @{$ev};
	is(scalar @const, 1, 'returns_constant detected for multi-digit integer');

	done_testing();
};

# ==================================================================
# analyze -- no signals for empty or signal-free source
# ==================================================================
subtest 'analyze: no signals for empty or signal-free source' => sub {
	# Empty source string produces no evidence at all
	my $ev = _evidence_after('');
	is(scalar @{$ev}, 0, 'empty source produces no evidence');

	# Source with no return statement produces no evidence
	$ev = _evidence_after('sub foo { my $x = 1; }');
	is(scalar @{$ev}, 0, 'source with no return produces no evidence');

	# Plain variable return matches none of the three patterns
	$ev = _evidence_after('sub foo { my ($self, $x) = @_; return $x; }');
	is(scalar @{$ev}, 0, 'plain variable return produces no evidence');

	done_testing();
};

# ==================================================================
# analyze -- multiple signals in one method
# ==================================================================
subtest 'analyze: multiple signals in one method' => sub {
	# A method with both returns_constant and returns_property paths,
	# e.g. early return of undef then property return
	my $source = <<'CODE';
sub get_value {
	my ($self) = @_;
	return undef unless defined $self->{value};
	return $self->{value};
}
CODE

	my $ev = _evidence_after($source);

	# Both signals should be present since both patterns appear in source
	my @const = grep { $_->{signal} eq 'returns_constant'  } @{$ev};
	my @prop  = grep { $_->{signal} eq 'returns_property'  } @{$ev};
	ok(scalar @const > 0, 'returns_constant detected in multi-signal method');
	ok(scalar @prop  > 0, 'returns_property detected in multi-signal method');

	done_testing();
};

# ==================================================================
# analyze -- add_evidence is called with correct named args
# --------------------------------------------------
# Uses a spy to verify the exact call signature rather than
# relying on side effects collected via the mock object
# ==================================================================
subtest 'analyze calls add_evidence with correct named arguments' => sub {
	my ($mock, $evidence) = _mock_method(
		'sub name { my $self = shift; return $self->{name}; }'
	);

	# Spy on add_evidence to capture the exact arguments passed
	my $spy = spy 'MockMethod::add_evidence';

	my $analyser = App::Test::Generator::Analyzer::Return->new();
	$analyser->analyze($mock);

	# Retrieve the captured calls from the spy
	my @calls = $spy->();
	ok(scalar @calls > 0, 'add_evidence was called at least once');

	# Find the call that produced the returns_property signal
	my ($prop_call) = grep {
		my %args = @{$_}[2..$#{$_}];
		exists $args{signal} && ($args{signal} // '') eq 'returns_property'
	} @calls;
	ok(defined $prop_call, 'returns_property call captured by spy');

	if(defined $prop_call) {
		# Index 0 is method name, index 1 is $self, 2.. are named arg pairs
		my %args = @{$prop_call}[2..$#{$prop_call}];
		is($args{category}, 'return',                'category arg is return');
		is($args{signal},   'returns_property',       'signal arg is returns_property');
		is($args{value},    'name',                   'value arg is property name');
		is($args{weight},   $WEIGHT_RETURNS_PROPERTY, 'weight arg is correct');
	}

	restore_all();
	done_testing();
};

# ==================================================================
# analyze -- weight ordering
# --------------------------------------------------
# Verifies that the declared weight ordering is correct:
# returns_property > returns_self > returns_constant.
# A weight change in the source will cause these to fail.
# ==================================================================
subtest 'evidence weights match declared constants' => sub {
	# returns_property weight is 20
	my $ev = _evidence_after('sub foo { return $self->{x}; }');
	my ($prop) = grep { $_->{signal} eq 'returns_property' } @{$ev};
	is($prop->{weight}, $WEIGHT_RETURNS_PROPERTY,  'returns_property weight is 20');

	# returns_self weight is 15
	$ev = _evidence_after('sub foo { return $self; }');
	my ($self_ev) = grep { $_->{signal} eq 'returns_self' } @{$ev};
	is($self_ev->{weight}, $WEIGHT_RETURNS_SELF,    'returns_self weight is 15');

	# returns_constant weight is 10
	$ev = _evidence_after('sub foo { return 1; }');
	my ($const) = grep { $_->{signal} eq 'returns_constant' } @{$ev};
	is($const->{weight}, $WEIGHT_RETURNS_CONSTANT,  'returns_constant weight is 10');

	# Ordering assertions -- property is the strongest signal
	ok($WEIGHT_RETURNS_PROPERTY > $WEIGHT_RETURNS_SELF,
		'property weight > self weight');
	ok($WEIGHT_RETURNS_SELF > $WEIGHT_RETURNS_CONSTANT,
		'self weight > constant weight');

	done_testing();
};

done_testing();
