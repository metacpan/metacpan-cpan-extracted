#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

# Black-box unit tests for App::Test::Generator::Model::Method.
# Tests each public function according to its POD API specification.
# No mocking required — Model::Method has no external dependencies.

BEGIN { use_ok('App::Test::Generator::Model::Method') }

# --------------------------------------------------
# Helper: build a minimal valid Method object
# --------------------------------------------------
sub _method {
	my (%args) = @_;
	return App::Test::Generator::Model::Method->new(
		name   => $args{name}   // 'test_method',
		source => $args{source} // 'sub test_method { return 1; }',
	);
}

# ==================================================================
# new()
#
# POD spec:
#   Required: name, source
#   Returns:  blessed object
#   Croaks:   when name or source is missing
# ==================================================================

subtest 'new() returns a blessed Method object' => sub {
	my $m = _method();
	isa_ok($m, 'App::Test::Generator::Model::Method');
};

subtest 'new() croaks when name is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::Model::Method->new(
			source => 'sub foo {}' )
		},
		qr/name required/,
		'missing name croaks',
	);
};

subtest 'new() croaks when source is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::Model::Method->new(
			name => 'foo' )
		},
		qr/source required/,
		'missing source croaks',
	);
};

subtest 'new() initialises return_type, classification, confidence to undef' => sub {
	my $m = _method();
	is($m->return_type,    undef, 'return_type initially undef');
	is($m->classification, undef, 'classification initially undef');
	is($m->confidence,     undef, 'confidence initially undef');
};

subtest 'new() initialises evidence to empty' => sub {
	my $m = _method();
	is(scalar($m->evidence), 0, 'evidence initially empty');
};

subtest 'new() each call produces a distinct object' => sub {
	my $m1 = _method();
	my $m2 = _method();
	isnt($m1, $m2, 'distinct objects returned');
};

# ==================================================================
# name()
#
# POD spec:
#   Returns the method name string. Read-only.
# ==================================================================

subtest 'name() returns the stored name' => sub {
	my $m = _method(name => 'my_func');
	is($m->name, 'my_func', 'name returned correctly');
};

subtest 'name() is read-only — value unchanged after write attempt' => sub {
	my $m    = _method(name => 'original');
	my $orig = $m->name;
	eval { $m->name('changed') };
	is($m->name, $orig, 'name unchanged after write attempt');
};

# ==================================================================
# source()
#
# POD spec:
#   Returns the source string. Read-only.
# ==================================================================

subtest 'source() returns the stored source' => sub {
	my $src = 'sub foo { return 42; }';
	my $m   = _method(source => $src);
	is($m->source, $src, 'source returned correctly');
};

subtest 'source() is read-only — value unchanged after write attempt' => sub {
	my $m    = _method(source => 'sub foo { 1 }');
	my $orig = $m->source;
	eval { $m->source('sub other { 0 }') };
	is($m->source, $orig, 'source unchanged after write attempt');
};

# ==================================================================
# return_type()
#
# POD spec:
#   Read/write accessor. Initially undef.
# ==================================================================

subtest 'return_type() getter returns undef initially' => sub {
	my $m = _method();
	is($m->return_type, undef, 'return_type initially undef');
};

subtest 'return_type() setter stores and retrieves value' => sub {
	my $m = _method();
	$m->return_type('string');
	is($m->return_type, 'string', 'return_type set to string');
};

subtest 'return_type() can be overwritten' => sub {
	my $m = _method();
	$m->return_type('string');
	$m->return_type('object');
	is($m->return_type, 'object', 'return_type overwritten to object');
};

subtest 'return_type() can be set to undef' => sub {
	my $m = _method();
	$m->return_type('string');
	$m->return_type(undef);
	is($m->return_type, undef, 'return_type set back to undef');
};

# ==================================================================
# classification()
#
# POD spec:
#   Read/write accessor. Initially undef.
# ==================================================================

subtest 'classification() getter returns undef initially' => sub {
	my $m = _method();
	is($m->classification, undef, 'classification initially undef');
};

subtest 'classification() setter stores and retrieves value' => sub {
	my $m = _method();
	$m->classification('getter');
	is($m->classification, 'getter', 'classification set to getter');
};

subtest 'classification() can be overwritten' => sub {
	my $m = _method();
	$m->classification('getter');
	$m->classification('chainable');
	is($m->classification, 'chainable', 'classification overwritten');
};

# ==================================================================
# confidence()
#
# POD spec:
#   Read/write accessor. Initially undef.
# ==================================================================

subtest 'confidence() getter returns undef initially' => sub {
	my $m = _method();
	is($m->confidence, undef, 'confidence initially undef');
};

subtest 'confidence() setter stores and retrieves hashref' => sub {
	my $m    = _method();
	my $conf = { score => 42, level => 'high' };
	$m->confidence($conf);
	is_deeply($m->confidence, $conf, 'confidence hashref stored correctly');
};

subtest 'confidence() can be overwritten' => sub {
	my $m = _method();
	$m->confidence({ score => 10, level => 'low' });
	$m->confidence({ score => 80, level => 'high' });
	is($m->confidence->{level}, 'high', 'confidence overwritten correctly');
};

# ==================================================================
# add_evidence()
#
# POD spec:
#   Required: category (return|input|effect), signal (valid signal name)
#   Optional: weight (default 1), value
#   Croaks:   on invalid category or signal
# ==================================================================

subtest 'add_evidence() croaks for invalid category' => sub {
	my $m = _method();
	throws_ok(
		sub { $m->add_evidence(category => 'invalid', signal => 'returns_property') },
		qr/Invalid evidence category/,
		'invalid category croaks',
	);
};

subtest 'add_evidence() croaks for missing category' => sub {
	my $m = _method();
	throws_ok(
		sub { $m->add_evidence(signal => 'returns_property') },
		qr/Invalid evidence category/,
		'missing category croaks',
	);
};

subtest 'add_evidence() croaks for invalid signal' => sub {
	my $m = _method();
	throws_ok(
		sub { $m->add_evidence(category => 'return', signal => 'banana') },
		qr/Invalid evidence signal/,
		'invalid signal croaks',
	);
};

subtest 'add_evidence() croaks for missing signal' => sub {
	my $m = _method();
	throws_ok(
		sub { $m->add_evidence(category => 'return') },
		qr/Invalid evidence signal/,
		'missing signal croaks',
	);
};

subtest 'add_evidence() accepts valid return category signals' => sub {
	my $m = _method();
	for my $sig (qw(returns_property returns_self returns_constant
	                legacy_type context_aware error_pattern)) {
		lives_ok(
			sub { $m->add_evidence(category => 'return', signal => $sig) },
			"return/$sig accepted",
		);
	}
};

subtest 'add_evidence() accepts valid input category' => sub {
	my $m = _method();
	lives_ok(
		sub { $m->add_evidence(category => 'input', signal => 'input_validated') },
		'input/input_validated accepted',
	);
};

subtest 'add_evidence() accepts valid effect category' => sub {
	my $m = _method();
	lives_ok(
		sub { $m->add_evidence(category => 'effect', signal => 'has_side_effect') },
		'effect/has_side_effect accepted',
	);
};

subtest 'add_evidence() defaults weight to 1' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property');
	my @ev = $m->evidence;
	is($ev[0]{weight}, 1, 'default weight is 1');
};

subtest 'add_evidence() stores explicit weight' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 25);
	my @ev = $m->evidence;
	is($ev[0]{weight}, 25, 'explicit weight stored');
};

subtest 'add_evidence() stores optional value field' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property',
		value => 'name', weight => 20);
	my @ev = $m->evidence;
	is($ev[0]{value}, 'name', 'value field stored');
};

subtest 'add_evidence() accumulates multiple entries' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property');
	$m->add_evidence(category => 'return', signal => 'returns_self');
	$m->add_evidence(category => 'input',  signal => 'input_validated');
	is(scalar($m->evidence), 3, 'three entries accumulated');
};

# ==================================================================
# evidence()
#
# POD spec:
#   Returns a list of evidence hashrefs.
# ==================================================================

subtest 'evidence() returns empty list initially' => sub {
	my $m  = _method();
	my @ev = $m->evidence;
	is(scalar @ev, 0, 'empty list initially');
};

subtest 'evidence() returns list of hashrefs after add_evidence' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 10);
	my @ev = $m->evidence;
	is(scalar @ev, 1, 'one entry returned');
	is(ref($ev[0]), 'HASH', 'entry is a hashref');
	is($ev[0]{signal}, 'returns_constant', 'signal correct');
};

# ==================================================================
# evidence_ref()
#
# POD spec:
#   Returns an arrayref of evidence hashrefs.
# ==================================================================

subtest 'evidence_ref() returns an arrayref' => sub {
	my $m   = _method();
	my $ref = $m->evidence_ref;
	is(ref($ref), 'ARRAY', 'returns arrayref');
};

subtest 'evidence_ref() and evidence() return consistent data' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 15);
	my @ev  = $m->evidence;
	my $ref = $m->evidence_ref;
	is(scalar @{$ref},       scalar @ev,       'same count');
	is($ref->[0]{signal},    $ev[0]{signal},   'same signal');
	is($ref->[0]{weight},    $ev[0]{weight},   'same weight');
};

# ==================================================================
# resolve_return_type()
#
# POD spec:
#   Derives return type from evidence weights.
#   Sets and returns return_type.
#   returns_self     -> 'object'
#   returns_property -> 'property'
#   returns_constant -> 'constant'
#   Highest weight wins. Alphabetical tie-break.
# ==================================================================

subtest 'resolve_return_type() returns a defined value' => sub {
	my $m = _method();
	ok(defined $m->resolve_return_type, 'returns defined value even with no evidence');
};

subtest 'resolve_return_type() sets return_type as side effect' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	$m->resolve_return_type;
	ok(defined $m->return_type, 'return_type set after resolution');
};

subtest 'resolve_return_type() returns_self evidence -> object' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 20);
	is($m->resolve_return_type, 'object', 'returns_self -> object');
};

subtest 'resolve_return_type() returns_property evidence -> property' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	is($m->resolve_return_type, 'property', 'returns_property -> property');
};

subtest 'resolve_return_type() returns_constant evidence -> constant' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 20);
	is($m->resolve_return_type, 'constant', 'returns_constant -> constant');
};

subtest 'resolve_return_type() highest weight wins' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 30);
	is($m->resolve_return_type, 'object', 'highest weight wins');
};

subtest 'resolve_return_type() non-return evidence is ignored' => sub {
	my $m = _method();
	$m->add_evidence(category => 'input',  signal => 'input_validated',  weight => 100);
	$m->add_evidence(category => 'effect', signal => 'has_side_effect',  weight => 100);
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 5);
	is($m->resolve_return_type, 'constant',
		'only return evidence considered');
};

# ==================================================================
# resolve_classification()
#
# POD spec:
#   Derives classification from return type.
#   object   -> chainable
#   property -> getter
#   constant -> constant
#   other    -> unknown
#   Sets and returns classification.
#   Calls resolve_return_type if return_type not yet set.
# ==================================================================

subtest 'resolve_classification() returns a defined value' => sub {
	my $m = _method();
	ok(defined $m->resolve_classification, 'returns defined value');
};

subtest 'resolve_classification() sets classification as side effect' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 20);
	$m->resolve_classification;
	ok(defined $m->classification, 'classification set after resolution');
};

subtest 'resolve_classification() object return_type -> chainable' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 20);
	is($m->resolve_classification, 'chainable', 'object -> chainable');
};

subtest 'resolve_classification() property return_type -> getter' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	is($m->resolve_classification, 'getter', 'property -> getter');
};

subtest 'resolve_classification() constant return_type -> constant' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 20);
	is($m->resolve_classification, 'constant', 'constant -> constant');
};

subtest 'resolve_classification() unrecognised return_type -> unknown' => sub {
	my $m = _method();
	$m->return_type('something_else');
	is($m->resolve_classification, 'unknown', 'unrecognised type -> unknown');
};

subtest 'resolve_classification() triggers resolve_return_type when needed' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 20);
	is($m->return_type, undef, 'return_type not yet set');
	$m->resolve_classification;
	ok(defined $m->return_type, 'return_type set as side effect of resolve_classification');
};

# ==================================================================
# resolve_confidence()
#
# POD spec:
#   Derives confidence from total evidence weight.
#   Returns hashref with score and level keys.
#   Sets confidence as side effect.
#   score == 0       -> low
#   score >= medium  -> medium
#   score >= high    -> high
# ==================================================================

subtest 'resolve_confidence() returns a hashref' => sub {
	my $m    = _method();
	my $conf = $m->resolve_confidence;
	is(ref($conf), 'HASH', 'returns hashref');
};

subtest 'resolve_confidence() returns score and level keys' => sub {
	my $m    = _method();
	my $conf = $m->resolve_confidence;
	ok(exists $conf->{score}, 'score key present');
	ok(exists $conf->{level}, 'level key present');
};

subtest 'resolve_confidence() score 0 produces level low' => sub {
	my $m    = _method();
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 0,     'no evidence: score is 0');
	is($conf->{level}, 'low', 'no evidence: level is low');
};

subtest 'resolve_confidence() score accumulates all evidence weights' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 25);
	my $conf = $m->resolve_confidence;
	is($conf->{score}, 45, 'weights summed: 20 + 25 = 45');
};

subtest 'resolve_confidence() high score produces level high' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 50);
	my $conf = $m->resolve_confidence;
	is($conf->{level}, 'high', 'high score -> high level');
};

subtest 'resolve_confidence() sets confidence as side effect' => sub {
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 50);
	$m->resolve_confidence;
	is(ref($m->confidence), 'HASH', 'confidence set as side effect');
};

# ==================================================================
# absorb_legacy_output()
#
# POD spec:
#   Converts legacy schema output hashref into evidence entries.
#   undef or non-hashref input is silently ignored.
#   type field        -> legacy_type evidence, weight 20
#   _returns_self     -> returns_self evidence, weight 25
#   _context_aware    -> context_aware evidence, weight 15
#   _error_return     -> error_pattern evidence, weight 15
# ==================================================================

subtest 'absorb_legacy_output() silently ignores undef' => sub {
	my $m = _method();
	lives_ok(sub { $m->absorb_legacy_output(undef) }, 'undef silently ignored');
	is(scalar($m->evidence), 0, 'no evidence added for undef');
};

subtest 'absorb_legacy_output() silently ignores non-hashref' => sub {
	my $m = _method();
	lives_ok(sub { $m->absorb_legacy_output('string') }, 'string silently ignored');
	is(scalar($m->evidence), 0, 'no evidence added for string');
};

subtest 'absorb_legacy_output() empty hashref adds no evidence' => sub {
	my $m = _method();
	$m->absorb_legacy_output({});
	is(scalar($m->evidence), 0, 'empty hashref adds no evidence');
};

subtest 'absorb_legacy_output() type field adds legacy_type evidence' => sub {
	my $m = _method();
	$m->absorb_legacy_output({ type => 'object' });
	my @ev = $m->evidence;
	is(scalar @ev,       1,            'one evidence entry added');
	is($ev[0]{signal},   'legacy_type', 'signal is legacy_type');
	is($ev[0]{value},    'object',      'value is the type string');
	is($ev[0]{weight},   20,            'weight is 20');
	is($ev[0]{category}, 'return',      'category is return');
};

subtest 'absorb_legacy_output() _returns_self adds returns_self evidence' => sub {
	my $m = _method();
	$m->absorb_legacy_output({ _returns_self => 1 });
	my @ev = $m->evidence;
	is(scalar @ev,      1,             'one evidence entry');
	is($ev[0]{signal},  'returns_self', 'signal is returns_self');
	is($ev[0]{weight},  25,             'weight is 25');
};

subtest 'absorb_legacy_output() falsy _returns_self adds no evidence' => sub {
	my $m = _method();
	$m->absorb_legacy_output({ _returns_self => 0 });
	is(scalar($m->evidence), 0, 'falsy _returns_self adds no evidence');
};

subtest 'absorb_legacy_output() _context_aware adds context_aware evidence' => sub {
	my $m = _method();
	$m->absorb_legacy_output({ _context_aware => 1 });
	my @ev = $m->evidence;
	is($ev[0]{signal}, 'context_aware', 'signal is context_aware');
	is($ev[0]{weight}, 15,              'weight is 15');
};

subtest 'absorb_legacy_output() _error_return adds error_pattern evidence' => sub {
	my $m = _method();
	$m->absorb_legacy_output({ _error_return => 'undef' });
	my @ev = $m->evidence;
	is($ev[0]{signal}, 'error_pattern', 'signal is error_pattern');
	is($ev[0]{value},  'undef',         'value is the error return string');
	is($ev[0]{weight}, 15,              'weight is 15');
};

subtest 'absorb_legacy_output() all four fields add four evidence entries' => sub {
	my $m = _method();
	$m->absorb_legacy_output({
		type           => 'string',
		_returns_self  => 1,
		_context_aware => 1,
		_error_return  => 'undef',
	});
	is(scalar($m->evidence), 4, 'four fields produce four evidence entries');
};

done_testing();
