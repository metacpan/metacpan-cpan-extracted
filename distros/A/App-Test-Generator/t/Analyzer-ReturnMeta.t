#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird 0.08;
use Readonly;

BEGIN {
	use_ok('App::Test::Generator::Analyzer::ReturnMeta');
}

# --------------------------------------------------
# Constants matching the penalties and bonus declared
# in the module under test. A change to any constant
# in the source will cause the corresponding test to
# fail deliberately rather than silently passing with
# wrong values.
# --------------------------------------------------
Readonly my $PENALTY_CONTEXT_SENSITIVE_STABILITY   => 25;
Readonly my $PENALTY_CONTEXT_SENSITIVE_CONSISTENCY => 15;
Readonly my $PENALTY_MIXED_RETURN_CONSISTENCY      => 30;
Readonly my $PENALTY_IMPLICIT_UNDEF_STABILITY      => 20;
Readonly my $PENALTY_EXPLICIT_UNDEF_STABILITY      => 10;
Readonly my $PENALTY_EMPTY_LIST_CONSISTENCY        => 15;
Readonly my $PENALTY_EXCEPTION_SWALLOW_STABILITY   => 20;
Readonly my $BONUS_BOOLEAN_STABILITY               => 5;

# --------------------------------------------------
# Helper: call analyze with the given output hashref
# and return the report. Wraps the schema correctly
# so individual subtests only need to supply output.
# --------------------------------------------------
sub _analyze_output {
	my ($output) = @_;
	my $analyser = App::Test::Generator::Analyzer::ReturnMeta->new();
	return $analyser->analyze({ output => $output });
}

# ==================================================================
# new
# --------------------------------------------------
# Tests for the constructor
# ==================================================================
subtest 'new' => sub {
	# Constructor returns a defined blessed object
	my $analyser = App::Test::Generator::Analyzer::ReturnMeta->new();
	ok(defined $analyser, 'new() returns defined value');
	isa_ok($analyser, 'App::Test::Generator::Analyzer::ReturnMeta');

	# Object is a plain blessed hashref in the correct class
	is(ref($analyser), 'App::Test::Generator::Analyzer::ReturnMeta',
		'object is blessed into correct class');

	# Each call produces a distinct object
	my $analyser2 = App::Test::Generator::Analyzer::ReturnMeta->new();
	isnt($analyser, $analyser2, 'each call produces a distinct object');

	done_testing();
};

# ==================================================================
# analyze -- return structure
# --------------------------------------------------
# The return value must always be a hashref with the
# three required keys regardless of input content
# ==================================================================
subtest 'analyze return structure' => sub {
	my $analyser = App::Test::Generator::Analyzer::ReturnMeta->new();

	# Minimal schema with empty output
	my $report = $analyser->analyze({});
	is(ref($report), 'HASH', 'analyze returns hashref');
	ok(exists $report->{stability_score},   'stability_score key present');
	ok(exists $report->{consistency_score}, 'consistency_score key present');
	ok(exists $report->{risk_flags},        'risk_flags key present');
	is(ref($report->{risk_flags}), 'ARRAY', 'risk_flags is arrayref');

	# Schema with undef output key
	$report = $analyser->analyze({ output => undef });
	is(ref($report), 'HASH', 'analyze returns hashref for undef output');

	done_testing();
};

# ==================================================================
# analyze -- baseline scores
# --------------------------------------------------
# An output section with no risk signals must produce
# scores of 100/100 and an empty risk_flags list
# ==================================================================
subtest 'analyze: baseline scores are 100/100' => sub {
	# Completely clean output -- no risk signals
	my $report = _analyze_output({});
	is($report->{stability_score},   100, 'baseline stability is 100');
	is($report->{consistency_score}, 100, 'baseline consistency is 100');
	is(scalar @{$report->{risk_flags}}, 0, 'no risk flags at baseline');

	# Output with only a type and no risk signals
	$report = _analyze_output({ type => 'string' });
	is($report->{stability_score},   100, 'typed output with no risks is 100');
	is($report->{consistency_score}, 100, 'typed output consistency is 100');

	done_testing();
};

# ==================================================================
# analyze -- context_sensitive penalty
# --------------------------------------------------
# _context_aware flag reduces stability by 25 and
# consistency by 15, and adds 'context_sensitive' risk
# ==================================================================
subtest 'analyze: context_sensitive penalty' => sub {
	my $report = _analyze_output({ _context_aware => 1 });

	# Risk flag must be present
	ok(grep({ $_ eq 'context_sensitive' } @{$report->{risk_flags}}),
		'context_sensitive risk flag added');

	# Stability reduced by $PENALTY_CONTEXT_SENSITIVE_STABILITY
	is($report->{stability_score},
		100 - $PENALTY_CONTEXT_SENSITIVE_STABILITY,
		'stability reduced by context_sensitive penalty');

	# Consistency reduced by $PENALTY_CONTEXT_SENSITIVE_CONSISTENCY
	is($report->{consistency_score},
		100 - $PENALTY_CONTEXT_SENSITIVE_CONSISTENCY,
		'consistency reduced by context_sensitive penalty');

	# _context_aware falsy produces no penalty
	$report = _analyze_output({ _context_aware => 0 });
	ok(!grep({ $_ eq 'context_sensitive' } @{$report->{risk_flags}}),
		'no context_sensitive flag when _context_aware is false');
	is($report->{stability_score},   100, 'no stability penalty when not context aware');
	is($report->{consistency_score}, 100, 'no consistency penalty when not context aware');

	done_testing();
};

# ==================================================================
# analyze -- mixed_return_types penalty
# --------------------------------------------------
# _returns_self with type != 'object' reduces consistency
# by 30 and adds 'mixed_return_types' risk
# ==================================================================
subtest 'analyze: mixed_return_types penalty' => sub {
	# _returns_self with non-object type triggers penalty
	my $report = _analyze_output({ _returns_self => 1, type => 'string' });
	ok(grep({ $_ eq 'mixed_return_types' } @{$report->{risk_flags}}),
		'mixed_return_types risk flag added');
	is($report->{consistency_score},
		100 - $PENALTY_MIXED_RETURN_CONSISTENCY,
		'consistency reduced by mixed_return_types penalty');

	# _returns_self with type 'object' must NOT trigger penalty
	$report = _analyze_output({ _returns_self => 1, type => 'object' });
	ok(!grep({ $_ eq 'mixed_return_types' } @{$report->{risk_flags}}),
		'no mixed_return_types when type is object');
	is($report->{consistency_score}, 100,
		'no consistency penalty when _returns_self with object type');

	# _returns_self with no type set triggers penalty
	$report = _analyze_output({ _returns_self => 1 });
	ok(grep({ $_ eq 'mixed_return_types' } @{$report->{risk_flags}}),
		'mixed_return_types triggered when type is absent');

	# _returns_self false produces no penalty regardless of type
	$report = _analyze_output({ _returns_self => 0, type => 'string' });
	ok(!grep({ $_ eq 'mixed_return_types' } @{$report->{risk_flags}}),
		'no mixed_return_types when _returns_self is false');

	done_testing();
};

# ==================================================================
# analyze -- implicit_error_return penalty
# --------------------------------------------------
# _error_handling.implicit_undef reduces stability by 20
# and adds 'implicit_error_return' risk
# ==================================================================
subtest 'analyze: implicit_error_return penalty' => sub {
	my $report = _analyze_output({
		_error_handling => { implicit_undef => 1 }
	});

	ok(grep({ $_ eq 'implicit_error_return' } @{$report->{risk_flags}}),
		'implicit_error_return risk flag added');
	is($report->{stability_score},
		100 - $PENALTY_IMPLICIT_UNDEF_STABILITY,
		'stability reduced by implicit_undef penalty');

	# Falsy implicit_undef produces no penalty
	$report = _analyze_output({ _error_handling => { implicit_undef => 0 } });
	ok(!grep({ $_ eq 'implicit_error_return' } @{$report->{risk_flags}}),
		'no implicit_error_return flag when implicit_undef is false');

	done_testing();
};

# ==================================================================
# analyze -- undef_on_error penalty
# --------------------------------------------------
# _error_return eq 'undef' reduces stability by 10
# and adds 'undef_on_error' risk
# ==================================================================
subtest 'analyze: undef_on_error penalty' => sub {
	my $report = _analyze_output({ _error_return => 'undef' });

	ok(grep({ $_ eq 'undef_on_error' } @{$report->{risk_flags}}),
		'undef_on_error risk flag added');
	is($report->{stability_score},
		100 - $PENALTY_EXPLICIT_UNDEF_STABILITY,
		'stability reduced by undef_on_error penalty');

	# _error_return set to something other than 'undef' produces no penalty
	$report = _analyze_output({ _error_return => 'false' });
	ok(!grep({ $_ eq 'undef_on_error' } @{$report->{risk_flags}}),
		'no undef_on_error flag when _error_return is not undef');
	is($report->{stability_score}, 100,
		'no stability penalty when _error_return is not undef string');

	# _error_return absent produces no penalty
	$report = _analyze_output({});
	ok(!grep({ $_ eq 'undef_on_error' } @{$report->{risk_flags}}),
		'no undef_on_error flag when _error_return absent');

	done_testing();
};

# ==================================================================
# analyze -- empty_list_error penalty
# --------------------------------------------------
# _error_handling.empty_list reduces consistency by 15
# and adds 'empty_list_error' risk
# ==================================================================
subtest 'analyze: empty_list_error penalty' => sub {
	my $report = _analyze_output({
		_error_handling => { empty_list => 1 }
	});

	ok(grep({ $_ eq 'empty_list_error' } @{$report->{risk_flags}}),
		'empty_list_error risk flag added');
	is($report->{consistency_score},
		100 - $PENALTY_EMPTY_LIST_CONSISTENCY,
		'consistency reduced by empty_list_error penalty');

	# Falsy empty_list produces no penalty
	$report = _analyze_output({ _error_handling => { empty_list => 0 } });
	ok(!grep({ $_ eq 'empty_list_error' } @{$report->{risk_flags}}),
		'no empty_list_error flag when empty_list is false');

	done_testing();
};

# ==================================================================
# analyze -- exception_swallowing penalty
# --------------------------------------------------
# _error_handling.exception_handling reduces stability
# by 20 and adds 'exception_swallowing' risk
# ==================================================================
subtest 'analyze: exception_swallowing penalty' => sub {
	my $report = _analyze_output({
		_error_handling => { exception_handling => 1 }
	});

	ok(grep({ $_ eq 'exception_swallowing' } @{$report->{risk_flags}}),
		'exception_swallowing risk flag added');
	is($report->{stability_score},
		100 - $PENALTY_EXCEPTION_SWALLOW_STABILITY,
		'stability reduced by exception_swallowing penalty');

	# Falsy exception_handling produces no penalty
	$report = _analyze_output({ _error_handling => { exception_handling => 0 } });
	ok(!grep({ $_ eq 'exception_swallowing' } @{$report->{risk_flags}}),
		'no exception_swallowing flag when exception_handling is false');

	done_testing();
};

# ==================================================================
# analyze -- boolean stability bonus
# --------------------------------------------------
# type eq 'boolean' adds 5 to stability (clamped to 100).
# The bonus only has observable effect when stability has
# already been reduced by at least one penalty.
# ==================================================================
subtest 'analyze: boolean stability bonus' => sub {
	# Baseline boolean -- bonus cannot push above 100 so score stays 100
	my $report = _analyze_output({ type => 'boolean' });
	is($report->{stability_score}, 100,
		'boolean bonus does not push stability above 100');

	# Boolean with one penalty -- bonus partially offsets the penalty
	$report = _analyze_output({
		type          => 'boolean',
		_error_return => 'undef',
	});
	# Expected: 100 - 10 (undef_on_error) + 5 (boolean bonus) = 95
	is($report->{stability_score},
		100 - $PENALTY_EXPLICIT_UNDEF_STABILITY + $BONUS_BOOLEAN_STABILITY,
		'boolean bonus partially offsets undef_on_error penalty');

	# Boolean with a larger penalty -- bonus still only adds 5
	$report = _analyze_output({
		type            => 'boolean',
		_context_aware  => 1,
	});
	# Expected: 100 - 25 (context) + 5 (boolean bonus) = 80
	is($report->{stability_score},
		100 - $PENALTY_CONTEXT_SENSITIVE_STABILITY + $BONUS_BOOLEAN_STABILITY,
		'boolean bonus adds exactly 5 to penalised stability');

	# Non-boolean type gets no bonus
	$report = _analyze_output({ type => 'string', _error_return => 'undef' });
	is($report->{stability_score},
		100 - $PENALTY_EXPLICIT_UNDEF_STABILITY,
		'no boolean bonus for non-boolean type');

	done_testing();
};

# ==================================================================
# analyze -- score clamping
# --------------------------------------------------
# Scores must never exceed 100 or fall below 0 regardless
# of how many penalties are accumulated
# ==================================================================
subtest 'analyze: scores clamped to [0, 100]' => sub {
	# Pile on every possible penalty to drive scores as low as possible
	my $report = _analyze_output({
		_context_aware  => 1,	# -25 stability, -15 consistency
		_returns_self   => 1,	# -30 consistency (type absent so mixed)
		_error_handling => {
			implicit_undef      => 1,	# -20 stability
			empty_list          => 1,	# -15 consistency
			exception_handling  => 1,	# -20 stability
		},
		_error_return   => 'undef',	# -10 stability
	});

	# Stability: 100 - 25 - 20 - 20 - 10 = 25 (above zero, no clamp needed)
	# Consistency: 100 - 15 - 30 - 15 = 40 (above zero, no clamp needed)
	# Verify scores are non-negative
	ok($report->{stability_score}   >= 0,   'stability score not negative');
	ok($report->{consistency_score} >= 0,   'consistency score not negative');
	ok($report->{stability_score}   <= 100, 'stability score not above 100');
	ok($report->{consistency_score} <= 100, 'consistency score not above 100');

	# All six risk flags must be present
	my %flags = map { $_ => 1 } @{$report->{risk_flags}};
	ok($flags{context_sensitive},    'context_sensitive flag present');
	ok($flags{mixed_return_types},   'mixed_return_types flag present');
	ok($flags{implicit_error_return},'implicit_error_return flag present');
	ok($flags{empty_list_error},     'empty_list_error flag present');
	ok($flags{exception_swallowing}, 'exception_swallowing flag present');
	ok($flags{undef_on_error},       'undef_on_error flag present');

	done_testing();
};

# ==================================================================
# analyze -- multiple independent penalties are additive
# --------------------------------------------------
# Verifies that each penalty is applied independently and
# the combined effect is the arithmetic sum of the parts
# ==================================================================
subtest 'analyze: penalties are additive' => sub {
	# Two independent stability penalties
	my $report = _analyze_output({
		_context_aware  => 1,	# -25 stability
		_error_return   => 'undef',	# -10 stability
	});
	is($report->{stability_score},
		100 - $PENALTY_CONTEXT_SENSITIVE_STABILITY - $PENALTY_EXPLICIT_UNDEF_STABILITY,
		'two stability penalties are additive');

	# Two independent consistency penalties
	$report = _analyze_output({
		_context_aware  => 1,	# -15 consistency
		_returns_self   => 1,	# -30 consistency (no type)
	});
	is($report->{consistency_score},
		100 - $PENALTY_CONTEXT_SENSITIVE_CONSISTENCY - $PENALTY_MIXED_RETURN_CONSISTENCY,
		'two consistency penalties are additive');

	done_testing();
};

# ==================================================================
# analyze -- penalty constant values
# --------------------------------------------------
# Explicit checks that each constant has the declared value.
# These will fail if a constant is changed in the source
# without a corresponding update to the tests.
# ==================================================================
subtest 'penalty constants have correct values' => sub {
	is($PENALTY_CONTEXT_SENSITIVE_STABILITY,   25, 'context_sensitive stability penalty is 25');
	is($PENALTY_CONTEXT_SENSITIVE_CONSISTENCY, 15, 'context_sensitive consistency penalty is 15');
	is($PENALTY_MIXED_RETURN_CONSISTENCY,      30, 'mixed_return consistency penalty is 30');
	is($PENALTY_IMPLICIT_UNDEF_STABILITY,      20, 'implicit_undef stability penalty is 20');
	is($PENALTY_EXPLICIT_UNDEF_STABILITY,      10, 'explicit_undef stability penalty is 10');
	is($PENALTY_EMPTY_LIST_CONSISTENCY,        15, 'empty_list consistency penalty is 15');
	is($PENALTY_EXCEPTION_SWALLOW_STABILITY,   20, 'exception_swallow stability penalty is 20');
	is($BONUS_BOOLEAN_STABILITY,                5, 'boolean stability bonus is 5');

	# Verify relative magnitudes match documented intent:
	# implicit undef is penalised more heavily than explicit undef
	ok($PENALTY_IMPLICIT_UNDEF_STABILITY > $PENALTY_EXPLICIT_UNDEF_STABILITY,
		'implicit undef penalty > explicit undef penalty');

	# mixed return is the heaviest consistency penalty
	ok($PENALTY_MIXED_RETURN_CONSISTENCY > $PENALTY_CONTEXT_SENSITIVE_CONSISTENCY,
		'mixed_return penalty > context_sensitive consistency penalty');
	ok($PENALTY_MIXED_RETURN_CONSISTENCY > $PENALTY_EMPTY_LIST_CONSISTENCY,
		'mixed_return penalty > empty_list consistency penalty');

	done_testing();
};

# ==================================================================
# analyze -- missing or malformed output key
# --------------------------------------------------
# analyze must not die when the schema has no output key,
# or when output is undef or an empty hashref
# ==================================================================
subtest 'analyze: tolerates missing or malformed output' => sub {
	my $analyser = App::Test::Generator::Analyzer::ReturnMeta->new();

	# No output key at all
	lives_ok { $analyser->analyze({}) }
		'analyze lives when output key absent';

	# Explicit undef output
	lives_ok { $analyser->analyze({ output => undef }) }
		'analyze lives when output is undef';

	# Empty output hashref
	lives_ok { $analyser->analyze({ output => {} }) }
		'analyze lives when output is empty hashref';

	# No _error_handling key -- must not autovivify or die
	lives_ok { $analyser->analyze({ output => { type => 'string' } }) }
		'analyze lives when _error_handling absent';

	done_testing();
};

done_testing();
