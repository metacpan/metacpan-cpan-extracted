#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Readonly;

BEGIN {
	use_ok('App::Test::Generator::Model::Method');
}

# --------------------------------------------------
# Constants matching the thresholds declared in the
# module under test. Changes in the source will
# cause deliberate test failures.
# --------------------------------------------------
Readonly my $HIGH_CONFIDENCE_THRESHOLD   => 40;
Readonly my $MEDIUM_CONFIDENCE_THRESHOLD => 20;

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
# new
# ==================================================================
subtest 'new' => sub {
	# Missing name croaks
	throws_ok {
		App::Test::Generator::Model::Method->new(source => 'sub foo {}')
	} qr/name required/, 'missing name croaks';

	# Missing source croaks
	throws_ok {
		App::Test::Generator::Model::Method->new(name => 'foo')
	} qr/source required/, 'missing source croaks';

	# Valid construction returns blessed object
	my $m = _method();
	ok(defined $m, 'new() returns defined value');
	isa_ok($m, 'App::Test::Generator::Model::Method');

	# Initial state is correct
	is($m->name,           'test_method',            'name accessor works');
	is($m->source,         'sub test_method { return 1; }', 'source accessor works');
	is($m->return_type,    undef,                    'return_type initially undef');
	is($m->classification, undef,                    'classification initially undef');
	is($m->confidence,     undef,                    'confidence initially undef');
	is(scalar($m->evidence), 0,                      'evidence initially empty');
};

# ==================================================================
# name and source accessors -- read-only
# ==================================================================
subtest 'name and source are read-only accessors' => sub {
	my $m = _method(name => 'my_func', source => 'sub my_func { 1 }');

	is($m->name,   'my_func',          'name returns correct value');
	is($m->source, 'sub my_func { 1 }', 'source returns correct value');

	# Calling with an argument has no effect (no setter)
	my $orig = $m->name();
	eval { $m->name('other') };
	is($m->name, $orig, 'name ignores argument -- read-only');

	$orig = $m->source;
	eval { $m->source('sub other { 0 }') };
	is($m->source, $orig, 'source ignores argument -- read-only');
};

# ==================================================================
# return_type accessor -- read/write
# ==================================================================
subtest 'return_type accessor' => sub {
	my $m = _method();

	# Initially undef
	is($m->return_type, undef, 'return_type initially undef');

	# Setter works
	$m->return_type('string');
	is($m->return_type, 'string', 'return_type set to string');

	# Overwrite works
	$m->return_type('object');
	is($m->return_type, 'object', 'return_type overwritten');

	# Set to undef
	$m->return_type(undef);
	is($m->return_type, undef, 'return_type set to undef');
};

# ==================================================================
# classification accessor -- read/write
# ==================================================================
subtest 'classification accessor' => sub {
	my $m = _method();

	is($m->classification, undef, 'classification initially undef');

	$m->classification('getter');
	is($m->classification, 'getter', 'classification set to getter');

	$m->classification('chainable');
	is($m->classification, 'chainable', 'classification overwritten');
};

# ==================================================================
# confidence accessor -- read/write
# ==================================================================
subtest 'confidence accessor' => sub {
	my $m = _method();

	is($m->confidence, undef, 'confidence initially undef');

	my $conf = { score => 42, level => 'high' };
	$m->confidence($conf);
	is_deeply($m->confidence, $conf, 'confidence set to hashref');
};

# ==================================================================
# add_evidence -- validation
# ==================================================================
subtest 'add_evidence: validation' => sub {
	my $m = _method();

	# Invalid category croaks
	throws_ok {
		$m->add_evidence(category => 'invalid', signal => 'returns_property')
	} qr/Invalid evidence category/, 'invalid category croaks';

	# Missing category croaks
	throws_ok {
		$m->add_evidence(signal => 'returns_property')
	} qr/Invalid evidence category/, 'missing category croaks';

	# Invalid signal croaks
	throws_ok {
		$m->add_evidence(category => 'return', signal => 'not_a_signal')
	} qr/Invalid evidence signal/, 'invalid signal croaks';

	# Missing signal croaks
	throws_ok {
		$m->add_evidence(category => 'return')
	} qr/Invalid evidence signal/, 'missing signal croaks';
};

# ==================================================================
# add_evidence -- valid categories and signals
# ==================================================================
subtest 'add_evidence: valid entries' => sub {
	my $m = _method();

	# All three valid categories
	lives_ok {
		$m->add_evidence(category => 'return', signal => 'returns_property')
	} 'return category accepted';

	lives_ok {
		$m->add_evidence(category => 'input', signal => 'input_validated')
	} 'input category accepted';

	lives_ok {
		$m->add_evidence(category => 'effect', signal => 'has_side_effect')
	} 'effect category accepted';

	is(scalar($m->evidence), 3, 'three evidence entries added');

	# Default weight is 1 when not specified
	my @ev = $m->evidence;
	is($ev[0]{weight}, 1, 'default weight is 1');

	# Explicit weight is stored
	my $m2 = _method();
	$m2->add_evidence(
		category => 'return',
		signal   => 'returns_self',
		weight   => 15,
	);
	my @ev2 = $m2->evidence;
	is($ev2[0]{weight}, 15, 'explicit weight stored correctly');

	# Value field is stored when provided
	my $m3 = _method();
	$m3->add_evidence(
		category => 'return',
		signal   => 'returns_property',
		value    => 'name',
		weight   => 20,
	);
	my @ev3 = $m3->evidence;
	is($ev3[0]{value}, 'name', 'value field stored correctly');
};

# ==================================================================
# evidence and evidence_ref
# ==================================================================
subtest 'evidence and evidence_ref' => sub {
	my $m = _method();

	# Empty evidence
	my @ev = $m->evidence;
	is(scalar @ev, 0, 'evidence returns empty list initially');

	my $ref = $m->evidence_ref;
	is(ref($ref), 'ARRAY', 'evidence_ref returns arrayref');
	is(scalar @{$ref}, 0,  'evidence_ref is empty initially');

	# Add some evidence
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 10);
	$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 15);

	@ev = $m->evidence;
	is(scalar @ev, 2, 'evidence returns two entries');

	# evidence_ref and evidence return the same data
	$ref = $m->evidence_ref;
	is(scalar @{$ref}, 2, 'evidence_ref also has two entries');
	is($ref->[0]{signal}, $ev[0]{signal}, 'evidence_ref matches evidence');
};

# ==================================================================
# resolve_return_type
# ==================================================================
subtest 'resolve_return_type' => sub {
	# returns_property scores -> 'property'
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	is($m->resolve_return_type, 'property', 'returns_property resolves to property');
	is($m->return_type,         'property', 'return_type set as side effect');

	# returns_self scores -> 'object'
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 15);
	is($m->resolve_return_type, 'object', 'returns_self resolves to object');

	# returns_constant scores -> 'constant'
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 10);
	is($m->resolve_return_type, 'constant', 'returns_constant resolves to constant');

	# Highest weight wins -- property beats constant
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 10);
	is($m->resolve_return_type, 'property', 'highest weight wins: property > constant');

	# Highest weight wins -- object beats property
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 30);
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	is($m->resolve_return_type, 'object', 'highest weight wins: object > property');

	# No evidence -- tie-break alphabetically, 'constant' wins
	$m = _method();
	ok(defined($m->resolve_return_type), 'no evidence: returns a defined value');

	# Non-return category evidence is ignored
	$m = _method();
	$m->add_evidence(category => 'input',  signal => 'input_validated', weight => 100);
	$m->add_evidence(category => 'effect', signal => 'has_side_effect', weight => 100);
	is($m->resolve_return_type, 'constant', 'non-return evidence ignored in resolution');

	# legacy_type 'object' maps to object score
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'legacy_type', value => 'object', weight => 20);
	is($m->resolve_return_type, 'object', 'legacy_type object maps to object');

	# legacy_type 'self' maps to object score
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'legacy_type', value => 'self', weight => 20);
	is($m->resolve_return_type, 'object', 'legacy_type self maps to object');

	# legacy_type other maps to property score
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'legacy_type', value => 'string', weight => 20);
	is($m->resolve_return_type, 'property', 'legacy_type other maps to property');

	# context_aware maps to property
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'context_aware', weight => 15);
	is($m->resolve_return_type, 'property', 'context_aware maps to property');

	# error_pattern maps to property
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'error_pattern', weight => 15);
	is($m->resolve_return_type, 'property', 'error_pattern maps to property');
};

# ==================================================================
# resolve_confidence
# ==================================================================
subtest 'resolve_confidence' => sub {
	# No evidence -- score 0, level low
	my $m = _method();
	my $conf = $m->resolve_confidence;
	is(ref($conf), 'HASH', 'resolve_confidence returns hashref');
	is($conf->{score}, 0,     'no evidence: score is 0');
	is($conf->{level}, 'low', 'no evidence: level is low');

	# Score below medium threshold -- low
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant',
		weight => $MEDIUM_CONFIDENCE_THRESHOLD - 1);
	$conf = $m->resolve_confidence;
	is($conf->{level}, 'low', 'score below medium threshold: low');

	# Score at medium threshold -- medium
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant',
		weight => $MEDIUM_CONFIDENCE_THRESHOLD);
	$conf = $m->resolve_confidence;
	is($conf->{level},  'medium',                    'score at medium threshold: medium');
	is($conf->{score},  $MEDIUM_CONFIDENCE_THRESHOLD, 'score value correct at medium');

	# Score below high threshold -- medium
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant',
		weight => $HIGH_CONFIDENCE_THRESHOLD - 1);
	$conf = $m->resolve_confidence;
	is($conf->{level}, 'medium', 'score below high threshold: medium');

	# Score at high threshold -- high
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant',
		weight => $HIGH_CONFIDENCE_THRESHOLD);
	$conf = $m->resolve_confidence;
	is($conf->{level},  'high',                    'score at high threshold: high');
	is($conf->{score},  $HIGH_CONFIDENCE_THRESHOLD, 'score value correct at high');

	# Multiple evidence weights are summed
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 25);
	$conf = $m->resolve_confidence;
	is($conf->{score}, 45,     'multiple evidence weights summed');
	is($conf->{level}, 'high', 'combined weight above high threshold');

	# resolve_confidence sets the confidence field as side effect
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 50);
	$m->resolve_confidence;
	is(ref($m->confidence), 'HASH', 'confidence set as side effect');
	is($m->confidence->{level}, 'high', 'confidence level correct after resolution');
};

# ==================================================================
# resolve_classification
# ==================================================================
subtest 'resolve_classification' => sub {
	# object return_type -> chainable
	my $m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 20);
	is($m->resolve_classification, 'chainable', 'object return_type -> chainable');
	is($m->classification,         'chainable', 'classification set as side effect');

	# property return_type -> getter
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 20);
	is($m->resolve_classification, 'getter', 'property return_type -> getter');

	# constant return_type -> constant
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 20);
	is($m->resolve_classification, 'constant', 'constant return_type -> constant');

	# No evidence -> unknown (alphabetical tie-break gives constant,
	# but constant maps to 'constant' not 'unknown' -- need to test
	# the actual unknown path which requires a non-matching return_type)
	$m = _method();
	$m->return_type('something_else');
	is($m->resolve_classification, 'unknown',
		'unrecognised return_type -> unknown');

	# resolve_classification calls resolve_return_type if return_type not set
	$m = _method();
	$m->add_evidence(category => 'return', signal => 'returns_self', weight => 30);
	is($m->return_type, undef, 'return_type not yet set');
	$m->resolve_classification;
	ok(defined $m->return_type, 'resolve_classification triggers return_type resolution');
};

# ==================================================================
# absorb_legacy_output
# ==================================================================
subtest 'absorb_legacy_output' => sub {
	# undef output is silently ignored
	my $m = _method();
	lives_ok { $m->absorb_legacy_output(undef) }
		'absorb_legacy_output lives with undef';
	is(scalar($m->evidence), 0, 'undef output adds no evidence');

	# Non-hashref is silently ignored
	lives_ok { $m->absorb_legacy_output('string') }
		'absorb_legacy_output lives with non-hashref';
	is(scalar($m->evidence), 0, 'non-hashref adds no evidence');

	# type field adds legacy_type evidence with weight 20
	$m = _method();
	$m->absorb_legacy_output({ type => 'object' });
	my @ev = $m->evidence;
	is(scalar @ev, 1,             'type field adds one evidence entry');
	is($ev[0]{signal},   'legacy_type', 'signal is legacy_type');
	is($ev[0]{value},    'object',      'value is the type string');
	is($ev[0]{weight},   20,            'weight is 20');
	is($ev[0]{category}, 'return',      'category is return');

	# _returns_self adds returns_self evidence with weight 25
	$m = _method();
	$m->absorb_legacy_output({ _returns_self => 1 });
	@ev = $m->evidence;
	is(scalar @ev, 1,              '_returns_self adds one evidence entry');
	is($ev[0]{signal},  'returns_self', 'signal is returns_self');
	is($ev[0]{weight},  25,             'weight is 25');

	# _context_aware adds context_aware evidence with weight 15
	$m = _method();
	$m->absorb_legacy_output({ _context_aware => 1 });
	@ev = $m->evidence;
	is(scalar @ev, 1,               '_context_aware adds one evidence entry');
	is($ev[0]{signal},  'context_aware', 'signal is context_aware');
	is($ev[0]{weight},  15,              'weight is 15');

	# _error_return adds error_pattern evidence with weight 15
	$m = _method();
	$m->absorb_legacy_output({ _error_return => 'undef' });
	@ev = $m->evidence;
	is(scalar @ev, 1,               '_error_return adds one evidence entry');
	is($ev[0]{signal},  'error_pattern', 'signal is error_pattern');
	is($ev[0]{value},   'undef',         'value is the error return');
	is($ev[0]{weight},  15,              'weight is 15');

	# All four fields together add four evidence entries
	$m = _method();
	$m->absorb_legacy_output({
		type          => 'string',
		_returns_self => 1,
		_context_aware => 1,
		_error_return  => 'undef',
	});
	is(scalar($m->evidence), 4, 'all four fields add four evidence entries');

	# Empty hashref adds no evidence
	$m = _method();
	$m->absorb_legacy_output({});
	is(scalar($m->evidence), 0, 'empty hashref adds no evidence');

	# Falsy _returns_self does not add evidence
	$m = _method();
	$m->absorb_legacy_output({ _returns_self => 0 });
	is(scalar($m->evidence), 0, 'falsy _returns_self adds no evidence');
};

# ==================================================================
# confidence threshold constants
# ==================================================================
subtest 'confidence threshold constants' => sub {
	is($HIGH_CONFIDENCE_THRESHOLD,   40, 'HIGH_CONFIDENCE_THRESHOLD is 40');
	is($MEDIUM_CONFIDENCE_THRESHOLD, 20, 'MEDIUM_CONFIDENCE_THRESHOLD is 20');
	ok($HIGH_CONFIDENCE_THRESHOLD > $MEDIUM_CONFIDENCE_THRESHOLD,
		'high threshold > medium threshold');
};

# ==================================================================
# integration: full pipeline
# ==================================================================
subtest 'integration: full evidence pipeline' => sub {
	# Simulate a complete analysis of a getter method
	my $m = App::Test::Generator::Model::Method->new(
		name   => 'get_name',
		source => 'sub get_name { my $self = shift; return $self->{name}; }',
	);

	# Analyser::Return would add this
	$m->add_evidence(
		category => 'return',
		signal   => 'returns_property',
		value    => 'name',
		weight   => 20,
	);

	# SchemaExtractor legacy output absorption
	$m->absorb_legacy_output({
		type           => 'string',
		_context_aware => 1,
	});

	# Resolve the full chain
	my $return_type     = $m->resolve_return_type;
	my $classification  = $m->resolve_classification;
	my $confidence      = $m->resolve_confidence;

	is($return_type,    'property', 'pipeline: return_type is property');
	is($classification, 'getter',   'pipeline: classification is getter');
	ok($confidence->{score} > 0,    'pipeline: confidence score is positive');
};

done_testing();
