use strict;
use warnings;

use Test::Most;
use Readonly;

use App::Test::Generator::Model::Method;
use App::Test::Generator::BenchmarkGenerator;
use App::Test::Generator::CoverageGuidedFuzzer;
use App::Test::Generator::Mutant;
use App::Test::Generator::Analyzer::Complexity;
use App::Test::Generator::Analyzer::SideEffect;

# --------------------------------------------------
# Domain constants used throughout
# --------------------------------------------------

# Model::Method::resolve_confidence thresholds
Readonly my $MEDIUM_THRESHOLD => 20;
Readonly my $HIGH_THRESHOLD   => 40;

# Analyzer::Complexity thresholds
Readonly my $COMPLEXITY_LOW_THRESHOLD  => 3;
Readonly my $COMPLEXITY_HIGH_THRESHOLD => 7;

# Valid evidence categories and signals
Readonly my @VALID_CATEGORIES => qw(return input effect);
Readonly my @VALID_SIGNALS    => qw(
	returns_property returns_constant returns_self
	legacy_type context_aware error_pattern
	input_validated input_typed input_optional
	has_side_effect no_side_effect
);

# Representative numeric boundaries for weight BVA
Readonly my $WEIGHT_LOW_BELOW   =>  19;   # below medium threshold
Readonly my $WEIGHT_MEDIUM_MIN  =>  20;   # exact lower bound of medium
Readonly my $WEIGHT_MEDIUM_MAX  =>  39;   # exact upper bound of medium
Readonly my $WEIGHT_HIGH_MIN    =>  40;   # exact lower bound of high

# Complexity cyclomatic score boundaries (base=1)
# Each branch keyword contributes +1 to the score.
# LOW_THRESHOLD=3: score<=3 is 'low'
# HIGH_THRESHOLD=7: score<=7 is 'moderate', score>7 is 'high'
Readonly my $BRANCHES_AT_LOW_BOUNDARY  => 2;   # base(1)+2 = 3 = LOW_THRESHOLD  → 'low'
Readonly my $BRANCHES_ABOVE_LOW        => 3;   # base(1)+3 = 4                  → 'moderate'
Readonly my $BRANCHES_AT_HIGH_BOUNDARY => 6;   # base(1)+6 = 7 = HIGH_THRESHOLD → 'moderate'
Readonly my $BRANCHES_ABOVE_HIGH       => 7;   # base(1)+7 = 8                  → 'high'

# _representative_value numeric defaults
Readonly my $INTEGER_DEFAULT => 42;
Readonly my $FLOAT_DEFAULT   => '3.14';

# ============================================================
# Helper: build a Method with a given total evidence weight
# ============================================================
sub _method_with_weight {
	my ($weight) = @_;
	my $m = App::Test::Generator::Model::Method->new(
		name   => 'x',
		source => 'sub x {}',
	);
	$m->add_evidence(
		category => 'return',
		signal   => 'returns_property',
		weight   => $weight,
	) if $weight > 0;
	return $m;
}

# Helper: build a body string containing N occurrences of 'if'
sub _body_with_branches {
	my ($n) = @_;
	return join(' ', ('if ($x) { 1; }') x $n);
}

# ============================================================
# 1. Model::Method::new — required parameter domain
# ============================================================

subtest 'Method::new — name parameter equivalence partitions' => sub {
	# EP valid: any defined scalar, including empty string
	ok(
		App::Test::Generator::Model::Method->new(name => 'get_foo', source => 'sub {}'),
		'name=ordinary string accepted'
	);
	ok(
		App::Test::Generator::Model::Method->new(name => '', source => 'sub {}'),
		'name=empty string accepted (defined check only)'
	);
	ok(
		App::Test::Generator::Model::Method->new(name => '0', source => 'sub {}'),
		'name="0" (false but defined) accepted'
	);

	# EP invalid: name absent
	throws_ok {
		App::Test::Generator::Model::Method->new(source => 'sub {}')
	} qr/name required/, 'name absent → croak "name required"';

	# EP invalid: name=undef
	throws_ok {
		App::Test::Generator::Model::Method->new(name => undef, source => 'sub {}')
	} qr/name required/, 'name=undef → croak "name required"';
};

subtest 'Method::new — source parameter equivalence partitions' => sub {
	# EP valid: any defined scalar
	ok(
		App::Test::Generator::Model::Method->new(name => 'f', source => 'sub f { 1 }'),
		'source=real source text accepted'
	);
	ok(
		App::Test::Generator::Model::Method->new(name => 'f', source => ''),
		'source=empty string accepted'
	);

	# EP invalid: source absent
	throws_ok {
		App::Test::Generator::Model::Method->new(name => 'f')
	} qr/source required/, 'source absent → croak "source required"';

	# EP invalid: source=undef
	throws_ok {
		App::Test::Generator::Model::Method->new(name => 'f', source => undef)
	} qr/source required/, 'source=undef → croak "source required"';
};

# ============================================================
# 2. Model::Method::add_evidence — category domain
# ============================================================

subtest 'Method::add_evidence — category equivalence partitions' => sub {
	my $m = App::Test::Generator::Model::Method->new(name => 'f', source => 'sub f {}');

	# EP valid: each of the three recognised categories
	for my $cat (@VALID_CATEGORIES) {
		lives_ok {
			$m->add_evidence(category => $cat, signal => 'returns_property')
		} "category='$cat' accepted";
	}

	# EP invalid: unrecognised category string
	throws_ok {
		$m->add_evidence(category => 'bogus', signal => 'returns_property')
	} qr/Invalid evidence category 'bogus'/, 'category="bogus" → croak with name';

	# EP invalid: empty-string category (boundary between absent and present)
	throws_ok {
		$m->add_evidence(category => '', signal => 'returns_property')
	} qr/Invalid evidence category ''/, 'category="" → croak';

	# EP invalid: undef category (defaults to '' inside add_evidence)
	throws_ok {
		$m->add_evidence(signal => 'returns_property')
	} qr/Invalid evidence category ''/, 'category absent (undef) → croak';
};

# ============================================================
# 3. Model::Method::add_evidence — signal domain
# ============================================================

subtest 'Method::add_evidence — signal equivalence partitions' => sub {
	my $m = App::Test::Generator::Model::Method->new(name => 'f', source => 'sub f {}');

	# EP valid: every recognised signal name is accepted regardless of category
	for my $sig (@VALID_SIGNALS) {
		lives_ok {
			$m->add_evidence(category => 'return', signal => $sig)
		} "signal='$sig' accepted";
	}

	# EP invalid: unrecognised signal string
	throws_ok {
		$m->add_evidence(category => 'return', signal => 'no_such_signal')
	} qr/Invalid evidence signal 'no_such_signal'/, 'bogus signal → croak with name';

	# EP invalid: empty-string signal
	throws_ok {
		$m->add_evidence(category => 'return', signal => '')
	} qr/Invalid evidence signal ''/, 'signal="" → croak';

	# EP invalid: signal absent
	throws_ok {
		$m->add_evidence(category => 'return')
	} qr/Invalid evidence signal ''/, 'signal absent → croak';
};

# ============================================================
# 4. Model::Method::add_evidence — weight domain (BVA)
# ============================================================

subtest 'Method::add_evidence — weight boundary value analysis' => sub {
	my $m = App::Test::Generator::Model::Method->new(name => 'f', source => 'sub f {}');

	# Partition: weight absent → defaults to 1
	$m->add_evidence(category => 'return', signal => 'returns_property');
	is(($m->evidence)[-1]{weight}, 1, 'weight absent → default 1');

	# Partition: weight=0 → stored as 0, NOT defaulted (defined check is true for 0)
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 0);
	is(($m->evidence)[-1]{weight}, 0, 'weight=0 → stored as 0 (not coerced to default)');

	# Partition: weight=1 (minimum meaningful positive)
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 1);
	is(($m->evidence)[-1]{weight}, 1, 'weight=1 accepted');

	# Partition: weight negative (no validation — stored as-is)
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => -5);
	is(($m->evidence)[-1]{weight}, -5, 'negative weight stored as-is (no validation)');

	# Partition: very large weight
	$m->add_evidence(category => 'return', signal => 'returns_property', weight => 10_000);
	is(($m->evidence)[-1]{weight}, 10_000, 'large weight stored as-is');
};

# ============================================================
# 5. Model::Method::resolve_confidence — score threshold BVA
# ============================================================
#
# MEDIUM_CONFIDENCE_THRESHOLD = 20
# HIGH_CONFIDENCE_THRESHOLD   = 40
#
# score < 20  → 'low'
# 20 <= score < 40 → 'medium'
# score >= 40 → 'high'

subtest 'Method::resolve_confidence — boundary value analysis on thresholds' => sub {
	# BVA: score=0 (empty evidence) → 'low'
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		my $c = $m->resolve_confidence;
		is($c->{score}, 0,     'no evidence → score=0');
		is($c->{level}, 'low', 'score=0 → level low');
	}

	# BVA: score=19 (one below medium lower bound) → 'low'
	{
		my $m = _method_with_weight($WEIGHT_LOW_BELOW);
		my $c = $m->resolve_confidence;
		is($c->{score}, $WEIGHT_LOW_BELOW, "score=$WEIGHT_LOW_BELOW stored correctly");
		is($c->{level}, 'low', "score=$WEIGHT_LOW_BELOW (one below medium bound) → 'low'");
	}

	# BVA: score=20 (exact lower bound of medium) → 'medium'
	{
		my $m = _method_with_weight($WEIGHT_MEDIUM_MIN);
		my $c = $m->resolve_confidence;
		is($c->{score}, $WEIGHT_MEDIUM_MIN, "score=$WEIGHT_MEDIUM_MIN stored correctly");
		is($c->{level}, 'medium', "score=$WEIGHT_MEDIUM_MIN (exact medium lower bound) → 'medium'");
	}

	# BVA: score=39 (one below high lower bound) → 'medium'
	{
		my $m = _method_with_weight($WEIGHT_MEDIUM_MAX);
		my $c = $m->resolve_confidence;
		is($c->{score}, $WEIGHT_MEDIUM_MAX, "score=$WEIGHT_MEDIUM_MAX stored correctly");
		is($c->{level}, 'medium', "score=$WEIGHT_MEDIUM_MAX (one below high bound) → 'medium'");
	}

	# BVA: score=40 (exact lower bound of high) → 'high'
	{
		my $m = _method_with_weight($WEIGHT_HIGH_MIN);
		my $c = $m->resolve_confidence;
		is($c->{score}, $WEIGHT_HIGH_MIN, "score=$WEIGHT_HIGH_MIN stored correctly");
		is($c->{level}, 'high', "score=$WEIGHT_HIGH_MIN (exact high lower bound) → 'high'");
	}

	# BVA: score=41 (one above high lower bound) → 'high'
	{
		my $m = _method_with_weight($WEIGHT_HIGH_MIN + 1);
		my $c = $m->resolve_confidence;
		is($c->{level}, 'high', 'score=41 → level remains high above threshold');
	}
};

# ============================================================
# 6. Model::Method::resolve_return_type — signal→bucket EP
# ============================================================
#
# Signal mapping:
#   returns_self              → object
#   legacy_type{value=object} → object
#   legacy_type{value=self}   → object
#   legacy_type{value=other}  → property
#   returns_property          → property
#   context_aware             → property
#   error_pattern             → property
#   returns_constant          → constant
#
# Tie-break: alphabetical among tied buckets (constant < object < property)
# All zero → constant wins

subtest 'Method::resolve_return_type — signal equivalence partitions' => sub {
	# EP: returns_self → object
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'returns_self', weight => 10);
		is($m->resolve_return_type, 'object', 'returns_self → object');
	}

	# EP: legacy_type value=object → object
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'legacy_type', value => 'object', weight => 10);
		is($m->resolve_return_type, 'object', 'legacy_type(object) → object');
	}

	# EP: legacy_type value=self → object
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'legacy_type', value => 'self', weight => 10);
		is($m->resolve_return_type, 'object', 'legacy_type(self) → object');
	}

	# EP: legacy_type with unrecognised value → property
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'legacy_type', value => 'scalar', weight => 10);
		is($m->resolve_return_type, 'property', 'legacy_type(other) → property');
	}

	# EP: returns_property → property
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'returns_property', weight => 10);
		is($m->resolve_return_type, 'property', 'returns_property → property');
	}

	# EP: context_aware → property
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'context_aware', weight => 10);
		is($m->resolve_return_type, 'property', 'context_aware → property');
	}

	# EP: error_pattern → property
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'error_pattern', weight => 10);
		is($m->resolve_return_type, 'property', 'error_pattern → property');
	}

	# EP: returns_constant → constant
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'returns_constant', weight => 10);
		is($m->resolve_return_type, 'constant', 'returns_constant → constant');
	}

	# EP: no evidence at all → constant wins alphabetical tie-break (c < o < p)
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		is($m->resolve_return_type, 'constant', 'no evidence → constant wins tie-break');
	}

	# Combinatorial: object=property tied → object wins (o < p alphabetically)
	{
		my $m = App::Test::Generator::Model::Method->new(name => 'f', source => '');
		$m->add_evidence(category => 'return', signal => 'returns_self',     weight => 5);
		$m->add_evidence(category => 'return', signal => 'returns_property', weight => 5);
		is($m->resolve_return_type, 'object', 'object=property tie → object wins (o<p)');
	}
};

# ============================================================
# 7. BenchmarkGenerator::new — schema parameter domain
# ============================================================

subtest 'BenchmarkGenerator::new — schema parameter equivalence partitions' => sub {
	# EP valid: non-empty hashref
	ok(
		App::Test::Generator::BenchmarkGenerator->new(schema => { module => 'Foo', function => 'bar' }),
		'schema=valid hashref accepted'
	);

	# EP valid: empty hashref (required check is `unless $args{schema}` — {} is truthy)
	ok(
		App::Test::Generator::BenchmarkGenerator->new(schema => {}),
		'schema=empty hashref accepted (truthy ref)'
	);

	# EP invalid: schema absent — Params::Get throws its own Usage error
	# before the defined check inside new() fires.
	throws_ok {
		App::Test::Generator::BenchmarkGenerator->new()
	} qr/schema/i, 'schema absent → Params::Get usage error (schema mentioned)';

	# EP invalid: schema=undef
	throws_ok {
		App::Test::Generator::BenchmarkGenerator->new(schema => undef)
	} qr/schema is required/, 'schema=undef → croak "schema is required"';

	# EP invalid: schema=arrayref (wrong ref type)
	throws_ok {
		App::Test::Generator::BenchmarkGenerator->new(schema => [])
	} qr/schema must be a hashref/, 'schema=arrayref → croak "schema must be a hashref"';

	# EP invalid: schema=plain string
	throws_ok {
		App::Test::Generator::BenchmarkGenerator->new(schema => 'foo')
	} qr/schema must be a hashref/, 'schema=string → croak "schema must be a hashref"';

	# EP invalid: schema=scalar ref
	throws_ok {
		my $x = 'str';
		App::Test::Generator::BenchmarkGenerator->new(schema => \$x)
	} qr/schema must be a hashref/, 'schema=scalarref → croak "schema must be a hashref"';
};

# ============================================================
# 8. BenchmarkGenerator::generate — required schema keys
# ============================================================

subtest 'BenchmarkGenerator::generate — schema key domain' => sub {
	# EP invalid: module key absent
	{
		my $bg = App::Test::Generator::BenchmarkGenerator->new(
			schema => { function => 'check' }
		);
		throws_ok { $bg->generate() } qr/schema missing module/,
			'module absent → croak "schema missing module"';
	}

	# EP invalid: function key absent
	{
		my $bg = App::Test::Generator::BenchmarkGenerator->new(
			schema => { module => 'Foo' }
		);
		throws_ok { $bg->generate() } qr/schema missing function/,
			'function absent → croak "schema missing function"';
	}

	# EP valid: both keys present
	{
		my $bg = App::Test::Generator::BenchmarkGenerator->new(
			schema => { module => 'Foo', function => 'bar', input => {} }
		);
		my $out;
		lives_ok { $out = $bg->generate() } 'module+function → generate() lives';
		like($out, qr/use Foo;/, 'non-builtin module → use statement emitted');
	}

	# EP special: module='builtin' → no use statement
	{
		my $bg = App::Test::Generator::BenchmarkGenerator->new(
			schema => { module => 'builtin', function => 'abs', input => {} }
		);
		my $out = $bg->generate();
		unlike($out, qr/use builtin;/, 'module=builtin → no "use" statement');
		like($out,  qr/abs\(/, 'builtin call uses bare function name');
	}

	# EP: transforms absent → single "default" variant
	{
		my $bg = App::Test::Generator::BenchmarkGenerator->new(
			schema => { module => 'Foo', function => 'f', input => {} }
		);
		my $out = $bg->generate();
		like($out, qr/'default'/, 'transforms absent → single default variant');
	}

	# EP: transforms present → named variants (not "default")
	{
		my $bg = App::Test::Generator::BenchmarkGenerator->new(
			schema => {
				module   => 'Foo',
				function => 'f',
				input    => {},
				transforms => {
					fast => { input => {} },
					slow => { input => {} },
				},
			}
		);
		my $out = $bg->generate();
		like($out,   qr/'fast'/,    'transforms present → fast variant emitted');
		like($out,   qr/'slow'/,    'transforms present → slow variant emitted');
		unlike($out, qr/'default'/, 'transforms present → no default variant');
	}
};

# ============================================================
# 9. BenchmarkGenerator::_representative_value — BVA on type+constraints
# ============================================================
# Tests the private helper directly (white-box domain analysis).

subtest 'BenchmarkGenerator::_representative_value — type equivalence partitions' => sub {
	my $rv = \&App::Test::Generator::BenchmarkGenerator::_representative_value;

	# EP: integer, no constraints → 42
	is($rv->({ type => 'integer' }), $INTEGER_DEFAULT, 'integer no constraints → 42');

	# EP: number, no constraints → 42
	is($rv->({ type => 'number' }),  $INTEGER_DEFAULT, 'number no constraints → 42');

	# EP: float, no constraints → 3.14
	is($rv->({ type => 'float' }),   $FLOAT_DEFAULT,   'float no constraints → 3.14');

	# EP: string → 'hello'
	is($rv->({ type => 'string' }),  "'hello'",        "string → 'hello'");

	# EP: boolean → 1
	is($rv->({ type => 'boolean' }), 1,                'boolean → 1');

	# EP: arrayref → []
	is($rv->({ type => 'arrayref' }), '[]',            'arrayref → []');

	# EP: hashref → {}
	is($rv->({ type => 'hashref' }),  '{}',            'hashref → {}');

	# EP: unknown type → "'value'"
	is($rv->({ type => 'widget' }),   "'value'",       "unknown type → 'value'");

	# EP: undef spec → 'undef'
	is($rv->(undef),                  'undef',         'undef spec → undef literal');

	# EP: spec with no type key → default string behaviour → 'hello'
	is($rv->({}),                     "'hello'",       'no type key → string default');
};

subtest 'BenchmarkGenerator::_representative_value — BVA on numeric constraints (integer)' => sub {
	my $rv = \&App::Test::Generator::BenchmarkGenerator::_representative_value;

	# BVA: min only — default(42) is STRICTLY greater than min → use default
	# Boundary: min=41 → 42 > 41 → use 42
	is($rv->({ type => 'integer', min => 41 }), $INTEGER_DEFAULT,
		'min=41: default(42)>41 → use default 42');

	# BVA: min only — default(42) NOT strictly greater than min → use min+1
	# Boundary: min=42 → 42 > 42 is false → use 43
	is($rv->({ type => 'integer', min => 42 }), 43,
		'min=42: default(42) not > 42 → use min+1=43 (strict > boundary)');

	# BVA: min=43 → 42 < 43 → use min+1=44
	is($rv->({ type => 'integer', min => 43 }), 44,
		'min=43: default(42) not > 43 → use min+1=44');

	# BVA: max only — default(42) is STRICTLY less than max → use default
	# Boundary: max=43 → 42 < 43 → use 42
	is($rv->({ type => 'integer', max => 43 }), $INTEGER_DEFAULT,
		'max=43: default(42)<43 → use default 42');

	# BVA: max only — default(42) NOT strictly less than max → use max-1
	# Boundary: max=42 → 42 < 42 is false → use 41
	is($rv->({ type => 'integer', max => 42 }), 41,
		'max=42: default(42) not < 42 → use max-1=41 (strict < boundary)');

	# BVA: max=41 → use 40
	is($rv->({ type => 'integer', max => 41 }), 40,
		'max=41: default(42) not < 41 → use max-1=40');

	# BVA: min and max both set → midpoint int((min+max)/2)
	is($rv->({ type => 'integer', min => 10, max => 20 }), 15,
		'min=10 max=20 → midpoint 15');

	# BVA: min and max produce half-integer → truncated toward zero
	is($rv->({ type => 'integer', min => 0, max => 1 }), 0,
		'min=0 max=1 → int(0.5)=0');

	is($rv->({ type => 'integer', min => 1, max => 2 }), 1,
		'min=1 max=2 → int(1.5)=1');

	# Combinatorial: min at default, max far above default → use default
	is($rv->({ type => 'integer', max => 100 }), $INTEGER_DEFAULT,
		'max=100 far above default → use default 42');

	# Combinatorial: min far above default → use min+1
	is($rv->({ type => 'integer', min => 1000 }), 1001,
		'min=1000 far above default → use min+1=1001');
};

# ============================================================
# 10. BenchmarkGenerator::_quote_value — value type domain
# ============================================================

subtest 'BenchmarkGenerator::_quote_value — value equivalence partitions' => sub {
	my $qv = \&App::Test::Generator::BenchmarkGenerator::_quote_value;

	# EP: undef → 'undef'
	is($qv->(undef), 'undef', 'undef → literal undef string');

	# EP: numeric 0 → returned as-is (no quotes) — looks_like_number(0) is true
	is($qv->(0), 0, 'numeric 0 → 0 as-is (no quotes)');

	# EP: positive integer → as-is
	is($qv->(42), 42, 'positive integer → as-is');

	# EP: float → as-is
	is($qv->(3.14), 3.14, 'float → as-is');

	# EP: plain string → single-quoted
	is($qv->('hello'), "'hello'", "plain string → single-quoted");

	# EP: string with embedded single-quote → backslash-escaped
	is($qv->("it's"), q{'it\'s'}, "string with single-quote → escaped");

	# EP: empty string → single-quoted empty
	is($qv->(''), "''", 'empty string → empty single-quoted string');

	# EP: string that looks like a number → returned as-is (looks_like_number true)
	is($qv->('007'), '007', '"007" is looks_like_number → as-is');

	# Combinatorial: string with multiple single-quotes → all escaped
	is($qv->("can't won't"), q{'can\'t won\'t'}, 'multiple single-quotes → all escaped');
};

# ============================================================
# 11. CoverageGuidedFuzzer::new — parameter domain
# ============================================================

subtest 'CoverageGuidedFuzzer::new — schema parameter domain' => sub {
	my $safe_sub = sub { 1 };

	# EP valid: non-empty hashref
	ok(
		App::Test::Generator::CoverageGuidedFuzzer->new(
			schema     => { function => 'f', input => {} },
			target_sub => $safe_sub,
		),
		'schema=non-empty hashref accepted'
	);

	# EP valid: empty hashref is a truthy ref — passes the `unless $args{schema}` check
	ok(
		App::Test::Generator::CoverageGuidedFuzzer->new(
			schema     => {},
			target_sub => $safe_sub,
		),
		'schema=empty hashref accepted (truthy ref)'
	);

	# EP invalid: schema absent (undef — fails truthiness check)
	throws_ok {
		App::Test::Generator::CoverageGuidedFuzzer->new(target_sub => $safe_sub)
	} qr/schema required/, 'schema absent → croak "schema required"';

	# EP invalid: schema=undef
	throws_ok {
		App::Test::Generator::CoverageGuidedFuzzer->new(
			schema     => undef,
			target_sub => $safe_sub,
		)
	} qr/schema required/, 'schema=undef → croak "schema required"';
};

subtest 'CoverageGuidedFuzzer::new — target_sub parameter domain' => sub {
	my $schema = { function => 'f', input => {} };

	# EP valid: coderef
	ok(
		App::Test::Generator::CoverageGuidedFuzzer->new(
			schema     => $schema,
			target_sub => sub { 1 },
		),
		'target_sub=coderef accepted'
	);

	# EP invalid: target_sub absent
	throws_ok {
		App::Test::Generator::CoverageGuidedFuzzer->new(schema => $schema)
	} qr/target_sub required/, 'target_sub absent → croak "target_sub required"';

	# EP invalid: target_sub=undef
	throws_ok {
		App::Test::Generator::CoverageGuidedFuzzer->new(
			schema     => $schema,
			target_sub => undef,
		)
	} qr/target_sub required/, 'target_sub=undef → croak "target_sub required"';
};

subtest 'CoverageGuidedFuzzer::new — optional parameters BVA' => sub {
	my $schema     = { function => 'f', input => {} };
	my $target_sub = sub { 1 };

	# iterations: absent → default 100
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub
		);
		is($f->{iterations}, 100, 'iterations absent → default 100');
	}

	# iterations: 0 → stored as 0 (// checks defined, not truth)
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub, iterations => 0
		);
		is($f->{iterations}, 0, 'iterations=0 → stored 0 (not defaulted)');
	}

	# iterations: 1 (minimum meaningful — just above zero)
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub, iterations => 1
		);
		is($f->{iterations}, 1, 'iterations=1 → stored 1');
	}

	# timeout: absent → default 5
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub
		);
		is($f->{timeout}, 5, 'timeout absent → default 5');
	}

	# timeout: 0 (disables alarm)
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub, timeout => 0
		);
		is($f->{timeout}, 0, 'timeout=0 stored (disables alarm)');
	}

	# timeout: 1 (minimum positive)
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub, timeout => 1
		);
		is($f->{timeout}, 1, 'timeout=1 → stored 1 (minimum positive)');
	}

	# seed: absent → defaults to time() (just check it's a number)
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub
		);
		like($f->{seed}, qr/^\d+$/, 'seed absent → numeric default (time())');
	}

	# seed: explicit value → stored as provided
	{
		my $f = App::Test::Generator::CoverageGuidedFuzzer->new(
			schema => $schema, target_sub => $target_sub, seed => 42
		);
		is($f->{seed}, 42, 'seed=42 → stored 42');
	}
};

# ============================================================
# 12. Mutant::new — required/optional attribute domain
# ============================================================
#
# Note: required check uses `exists $args{$key}`, NOT `defined`.
# So passing undef explicitly PASSES the required check but may
# surprise callers who omit the key entirely.

subtest 'Mutant::new — required attribute domain (exists check)' => sub {
	my $noop_xform = sub { };

	# EP valid: all required attributes present
	ok(
		App::Test::Generator::Mutant->new(
			id          => 'M1',
			description => 'test',
			original    => '==',
			line        => 10,
			transform   => $noop_xform,
		),
		'all required attributes → accepted'
	);

	# EP invalid: each required attribute absent (missing the key entirely)
	for my $attr (qw(id description original line transform)) {
		my %full = (
			id          => 'M1',
			description => 'desc',
			original    => '!=',
			line        => 5,
			transform   => $noop_xform,
		);
		delete $full{$attr};
		throws_ok {
			App::Test::Generator::Mutant->new(%full)
		} qr/Missing required attribute: $attr/, "attribute '$attr' absent → croak";
	}

	# Domain note: exists check — undef value for a required attr PASSES (key exists)
	# This is a documented invariant from the data-flow tests.
	ok(
		App::Test::Generator::Mutant->new(
			id          => undef,    # exists but undef — passes required check
			description => 'desc',
			original    => '!=',
			line        => 5,
			transform   => $noop_xform,
		),
		'id=undef (key exists) passes the required-exists check'
	);
};

subtest 'Mutant::new — transform type domain' => sub {
	my %base = (
		id          => 'M1',
		description => 'desc',
		original    => '==',
		line        => 10,
	);

	# EP valid: coderef
	ok(
		App::Test::Generator::Mutant->new(%base, transform => sub { }),
		'transform=coderef accepted'
	);

	# EP invalid: arrayref
	throws_ok {
		App::Test::Generator::Mutant->new(%base, transform => [])
	} qr/transform must be a CODE reference/, 'transform=arrayref → croak';

	# EP invalid: hashref
	throws_ok {
		App::Test::Generator::Mutant->new(%base, transform => {})
	} qr/transform must be a CODE reference/, 'transform=hashref → croak';

	# EP invalid: plain string
	throws_ok {
		App::Test::Generator::Mutant->new(%base, transform => 'not a coderef')
	} qr/transform must be a CODE reference/, 'transform=string → croak';

	# EP invalid: undef (key present, value undef — fails the ref() check)
	throws_ok {
		App::Test::Generator::Mutant->new(%base, transform => undef)
	} qr/transform must be a CODE reference/, 'transform=undef → croak (ref(undef) is "")';
};

subtest 'Mutant::new — optional attributes domain' => sub {
	my %required = (
		id          => 'M1',
		description => 'desc',
		original    => '==',
		line        => 10,
		transform   => sub { },
	);

	# EP: optional attrs absent → accessors return undef
	{
		my $m = App::Test::Generator::Mutant->new(%required);
		is($m->type,         undef, 'type absent → accessor returns undef');
		is($m->group,        undef, 'group absent → accessor returns undef');
		is($m->context,      undef, 'context absent → accessor returns undef');
		is($m->line_content, undef, 'line_content absent → accessor returns undef');
	}

	# EP: optional attrs present → accessors return provided values
	{
		my $m = App::Test::Generator::Mutant->new(
			%required,
			type         => 'comparison',
			group        => 'NUM:10',
			context      => 'conditional',
			line_content => 'if ($x == $y) {',
		);
		is($m->type,         'comparison',       'type stored and returned');
		is($m->group,        'NUM:10',            'group stored and returned');
		is($m->context,      'conditional',       'context stored and returned');
		is($m->line_content, 'if ($x == $y) {',  'line_content stored and returned');
	}

	# EP: line=0 (falsy but valid) — exists check means it must be storable
	{
		my $m = App::Test::Generator::Mutant->new(%required, line => 0);
		is($m->line, 0, 'line=0 accepted and stored');
	}

	# EP: line=1 (minimum meaningful positive line number)
	{
		my $m = App::Test::Generator::Mutant->new(%required, line => 1);
		is($m->line, 1, 'line=1 (first valid source line) stored correctly');
	}
};

# ============================================================
# 13. Analyzer::Complexity::analyze — cyclomatic threshold BVA
# ============================================================
#
# base score = 1 (CYCLOMATIC_BASE)
# LOW_THRESHOLD  = 3: score <= 3 → 'low'
# HIGH_THRESHOLD = 7: 3 < score <= 7 → 'moderate', score > 7 → 'high'
#
# BVA boundary points: 3, 4, 7, 8

subtest 'Analyzer::Complexity::analyze — cyclomatic score BVA' => sub {
	my $a = App::Test::Generator::Analyzer::Complexity->new;

	# BVA: empty body → score=1 (base only) → 'low'
	{
		my $r = $a->analyze({ body => '' });
		is($r->{cyclomatic_score},  1,     'empty body → cyclomatic_score=1 (base only)');
		is($r->{complexity_level}, 'low',  'empty body → level=low');
	}

	# BVA: undef body → treated as '' → score=1
	{
		my $r = $a->analyze({ body => undef });
		is($r->{cyclomatic_score},  1,     'undef body → cyclomatic_score=1');
		is($r->{complexity_level}, 'low',  'undef body → level=low');
	}

	# BVA: score=3 (base=1 + 2 branch tokens) — exactly at LOW_THRESHOLD → 'low'
	{
		my $body = _body_with_branches($BRANCHES_AT_LOW_BOUNDARY);   # 2 'if' tokens
		my $r    = $a->analyze({ body => $body });
		is($r->{cyclomatic_score},   3,    "score=3 (base+$BRANCHES_AT_LOW_BOUNDARY branches) → low boundary");
		is($r->{complexity_level}, 'low',  'score=3 → level=low (<=LOW_THRESHOLD)');
	}

	# BVA: score=4 (base=1 + 3 branch tokens) — one above LOW_THRESHOLD → 'moderate'
	{
		my $body = _body_with_branches($BRANCHES_ABOVE_LOW);          # 3 'if' tokens
		my $r    = $a->analyze({ body => $body });
		is($r->{cyclomatic_score},      4,          "score=4 (base+$BRANCHES_ABOVE_LOW branches) → above low boundary");
		is($r->{complexity_level}, 'moderate',      'score=4 → level=moderate');
	}

	# BVA: score=7 (base=1 + 6 branch tokens) — exactly at HIGH_THRESHOLD → 'moderate'
	{
		my $body = _body_with_branches($BRANCHES_AT_HIGH_BOUNDARY);   # 6 'if' tokens
		my $r    = $a->analyze({ body => $body });
		is($r->{cyclomatic_score},      7,          "score=7 (base+$BRANCHES_AT_HIGH_BOUNDARY branches) → high boundary");
		is($r->{complexity_level}, 'moderate',      'score=7 → level=moderate (<=HIGH_THRESHOLD)');
	}

	# BVA: score=8 (base=1 + 7 branch tokens) — one above HIGH_THRESHOLD → 'high'
	{
		my $body = _body_with_branches($BRANCHES_ABOVE_HIGH);         # 7 'if' tokens
		my $r    = $a->analyze({ body => $body });
		is($r->{cyclomatic_score},   8,    "score=8 (base+$BRANCHES_ABOVE_HIGH branches) → above high boundary");
		is($r->{complexity_level}, 'high', 'score=8 → level=high (>HIGH_THRESHOLD)');
	}
};

subtest 'Analyzer::Complexity::analyze — early_returns BVA' => sub {
	my $a = App::Test::Generator::Analyzer::Complexity->new;

	# BVA: exactly 1 return → early_returns=0 (first return is not an "early" path)
	{
		my $r = $a->analyze({ body => 'return $x;' });
		is($r->{early_returns}, 0, '1 return statement → early_returns=0');
	}

	# BVA: exactly 2 returns → early_returns=1
	{
		my $r = $a->analyze({ body => 'return 1 if $x; return 0;' });
		is($r->{early_returns}, 1, '2 return statements → early_returns=1');
	}

	# BVA: 3 returns → early_returns=2
	{
		my $r = $a->analyze({ body => 'return -1 if $x < 0; return 0 if $x == 0; return 1;' });
		is($r->{early_returns}, 2, '3 return statements → early_returns=2');
	}
};

subtest 'Analyzer::Complexity::analyze — nesting_depth BVA' => sub {
	my $a = App::Test::Generator::Analyzer::Complexity->new;

	# Depth 0: no braces
	is($a->analyze({ body => 'return 1;' })->{nesting_depth}, 0,
		'no braces → nesting_depth=0');

	# Depth 1: single level
	is($a->analyze({ body => 'if ($x) { return 1; }' })->{nesting_depth}, 1,
		'one level of braces → nesting_depth=1');

	# Depth 2: nested
	is($a->analyze({ body => 'if ($x) { if ($y) { return 1; } }' })->{nesting_depth}, 2,
		'two levels of braces → nesting_depth=2');

	# Unmatched closing brace: the guard `if $depth > 0` prevents underflow
	is($a->analyze({ body => '} return 1;' })->{nesting_depth}, 0,
		'unmatched closing brace → depth guard fires, nesting_depth=0');
};

# ============================================================
# 14. Analyzer::SideEffect::analyze — purity classification EP
# ============================================================

subtest 'Analyzer::SideEffect::analyze — purity_level equivalence partitions' => sub {
	my $a = App::Test::Generator::Analyzer::SideEffect->new;

	# EP: no side effects → 'pure'
	{
		my $r = $a->analyze({ body => 'return $self->{name};' });
		is($r->{purity_level}, 'pure', 'read-only accessor → pure');
		is($r->{mutates_self},    0, 'read-only → mutates_self=0');
		is($r->{mutates_globals}, 0, 'read-only → mutates_globals=0');
		is($r->{performs_io},     0, 'read-only → performs_io=0');
		is($r->{calls_external},  0, 'read-only → calls_external=0');
	}

	# EP: empty body → all flags 0, pure
	{
		my $r = $a->analyze({ body => '' });
		is($r->{purity_level}, 'pure', 'empty body → pure');
	}

	# EP: undef body (defaults to '') → pure
	{
		my $r = $a->analyze({ body => undef });
		is($r->{purity_level}, 'pure', 'undef body → pure (defaults to empty)');
	}

	# EP: mutates_self only → 'self_mutating'
	{
		my $r = $a->analyze({ body => '$self->{x} = 1;' });
		is($r->{purity_level},   'self_mutating', 'self mutation only → self_mutating');
		is($r->{mutates_self},   1, 'self assignment detected');
		is($r->{mutates_globals}, 0, 'no global mutation');
	}

	# EP: mutates_globals only → 'impure'
	{
		my $r = $a->analyze({ body => '$ENV{PATH} = "/usr/bin";' });
		is($r->{purity_level},    'impure', 'global mutation → impure');
		is($r->{mutates_globals}, 1, 'global mutation detected');
	}

	# EP: performs_io only → 'impure'
	{
		my $r = $a->analyze({ body => 'print "hello\n";' });
		is($r->{purity_level}, 'impure',  'IO operation → impure');
		is($r->{performs_io},  1, 'IO detected');
	}

	# EP: calls_external only → 'impure'
	{
		my $r = $a->analyze({ body => 'system("ls");' });
		is($r->{purity_level},   'impure', 'external call → impure');
		is($r->{calls_external}, 1, 'external call detected');
	}

	# Combinatorial: mutates_self AND mutates_globals → 'impure'
	{
		my $r = $a->analyze({ body => '$self->{x} = 1; $ENV{FOO} = "bar";' });
		is($r->{purity_level},    'impure', 'self+global → impure (external dominates)');
		is($r->{mutates_self},    1, 'self mutation present');
		is($r->{mutates_globals}, 1, 'global mutation present');
	}
};

subtest 'Analyzer::SideEffect::analyze — mutation_fields dedup domain' => sub {
	my $a = App::Test::Generator::Analyzer::SideEffect->new;

	# EP: single field assigned once → appears once in mutation_fields
	{
		my $r = $a->analyze({ body => '$self->{name} = "Alice";' });
		is_deeply($r->{mutation_fields}, ['name'], 'single field → one entry');
	}

	# EP: same field assigned twice → deduplicated to one entry
	{
		my $r = $a->analyze({ body => '$self->{x} = 1; $self->{x} = 2;' });
		is_deeply($r->{mutation_fields}, ['x'], 'same field twice → deduplicated');
	}

	# EP: two distinct fields → both appear
	{
		my $r = $a->analyze({ body => '$self->{a} = 1; $self->{b} = 2;' });
		my @fields = sort @{ $r->{mutation_fields} };
		is_deeply(\@fields, ['a', 'b'], 'two distinct fields → both present');
	}

	# EP: no self-mutation → mutation_fields is empty arrayref
	{
		my $r = $a->analyze({ body => 'return 1;' });
		is_deeply($r->{mutation_fields}, [], 'no self mutation → empty arrayref');
	}
};

subtest 'Analyzer::SideEffect::analyze — string-stripping isolation' => sub {
	my $a = App::Test::Generator::Analyzer::SideEffect->new;

	# A keyword inside a string literal must NOT trigger the detector
	{
		my $r = $a->analyze({ body => 'my $msg = "print this later";' });
		is($r->{performs_io}, 0, '"print" inside double-quoted string → no false positive');
	}

	# A keyword inside a single-quoted string must NOT trigger
	{
		my $r = $a->analyze({ body => "my \$msg = 'system unavailable';" });
		is($r->{calls_external}, 0, "'system' inside single-quoted string → no false positive");
	}

	# A keyword inside a comment must NOT trigger
	{
		my $r = $a->analyze({ body => '# warn the caller if needed' . "\n" . 'return 1;' });
		is($r->{performs_io}, 0, '"warn" inside comment → no false positive');
	}

	# $self->{field}= inside a string must NOT trigger mutation detection
	{
		my $r = $a->analyze({ body => 'my $s = "$self->{name}= cached";' });
		is($r->{mutates_self}, 0, '$self->{field}= inside string → no false positive');
	}
};

# --------------------------------------------------
# Logic-reducer tests: invariant assertions added after boolean reduction
# --------------------------------------------------

subtest 'Model::Method::resolve_classification — unreachable else confesses on invalid return_type' => sub {
	# The else branch in resolve_classification is unreachable via the normal
	# add_evidence → resolve_return_type path, because resolve_return_type only
	# ever returns object/property/constant.  Directly injecting an alien value
	# into {return_type} confirms the confess guard fires correctly.
	my $m = App::Test::Generator::Model::Method->new(name => 'f', source => 'sub f {}');
	$m->{return_type} = 'alien';    # bypass resolve_return_type
	throws_ok { $m->resolve_classification() }
		qr/invariant violation/, 'injected alien return_type → confess fires';
};

subtest 'Model::Method::add_evidence — category validation uses module-level constant (no per-call rebuild)' => sub {
	# Validate that the three valid categories are accepted and that an invalid
	# category is rejected — same behaviour as before the Readonly promotion,
	# but now verified post-refactor.
	my $m = App::Test::Generator::Model::Method->new(name => 'f', source => 'sub f {}');
	lives_ok { $m->add_evidence(category => 'return',  signal => 'returns_constant') } 'return accepted';
	lives_ok { $m->add_evidence(category => 'input',   signal => 'input_validated')  } 'input accepted';
	lives_ok { $m->add_evidence(category => 'effect',  signal => 'has_side_effect')  } 'effect accepted';
	throws_ok { $m->add_evidence(category => 'unknown', signal => 'returns_constant') }
		qr/Invalid evidence category 'unknown'/, 'invalid category → correct error message';
};

# ==================================================================
# GROUP A — Analyzer::Return::analyze
#
# Analyzer::Return adds evidence to a Model::Method object based on
# pattern-matching against the method body. It does not produce a
# standalone result hashref; it adds signals. We test the three
# patterns it detects (returns_self, returns_property, returns_constant)
# and the empty/undef body edge cases.
# ==================================================================

use App::Test::Generator::Analyzer::Return;

Readonly my $RETURN_ANALYZER_CLASS => 'App::Test::Generator::Analyzer::Return';

subtest 'EP: Analyzer::Return — returns_self signal added for "return $self"' => sub {
	my $ra = $RETURN_ANALYZER_CLASS->new;
	my $m  = App::Test::Generator::Model::Method->new(
		name   => 'foo',
		source => 'sub foo { return $self }',
	);
	$ra->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_self' } $m->evidence;
	ok(scalar @ev > 0, 'returns_self evidence added for "return $self"');
};

subtest 'EP: Analyzer::Return — returns_property signal added for "return $self->{key}"' => sub {
	my $ra = $RETURN_ANALYZER_CLASS->new;
	my $m  = App::Test::Generator::Model::Method->new(
		name   => 'foo',
		source => 'sub foo { return $self->{name} }',
	);
	$ra->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_property' } $m->evidence;
	ok(scalar @ev > 0, 'returns_property evidence added for "return $self->{key}"');
};

subtest 'EP: Analyzer::Return — returns_constant signal added for numeric literal' => sub {
	my $ra = $RETURN_ANALYZER_CLASS->new;
	my $m  = App::Test::Generator::Model::Method->new(
		name   => 'foo',
		source => 'sub foo { return 1 }',
	);
	$ra->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_constant' } $m->evidence;
	ok(scalar @ev > 0, 'returns_constant evidence added for "return 1"');
};

subtest 'EP: Analyzer::Return — returns_constant signal added for "return undef"' => sub {
	my $ra = $RETURN_ANALYZER_CLASS->new;
	my $m  = App::Test::Generator::Model::Method->new(
		name   => 'foo',
		source => 'sub foo { return undef }',
	);
	$ra->analyze($m);
	my @ev = grep { $_->{signal} eq 'returns_constant' } $m->evidence;
	ok(scalar @ev > 0, 'returns_constant evidence added for "return undef"');
};

subtest 'EP: Analyzer::Return — empty body adds no evidence' => sub {
	my $ra = $RETURN_ANALYZER_CLASS->new;
	my $m  = App::Test::Generator::Model::Method->new(
		name   => 'foo',
		source => '',
	);
	lives_ok { $ra->analyze($m) } 'analyze() lives on empty body';
	is(scalar($m->evidence), 0, 'no evidence added for empty body');
};

subtest 'EP: Analyzer::Return — raw hashref accepted (SchemaExtractor code path)' => sub {
	# SchemaExtractor passes a raw hashref, not a Model::Method object.
	my $ra = $RETURN_ANALYZER_CLASS->new;
	my $method_hashref = { source => 'sub foo { return $self }' };
	lives_ok { $ra->analyze($method_hashref) } 'analyze() lives on raw hashref';
};

# ==================================================================
# GROUP B — Planner::Isolation::plan parameter domain
# ==================================================================

use App::Test::Generator::Planner::Isolation;

Readonly my $ISOLATION_CLASS => 'App::Test::Generator::Planner::Isolation';

subtest 'EP: Planner::Isolation::plan — strategy must be a hashref' => sub {
	my $iso    = $ISOLATION_CLASS->new;
	my $schema = {};
	throws_ok { $iso->plan($schema, undef) }
		qr/strategy must be a hashref/, 'undef strategy croaks';
	throws_ok { $iso->plan($schema, 'string') }
		qr/strategy must be a hashref/, 'string strategy croaks';
	throws_ok { $iso->plan($schema, []) }
		qr/strategy must be a hashref/, 'arrayref strategy croaks';
};

subtest 'EP: Planner::Isolation — dependencies.time = 0 (falsy scalar) → key omitted' => sub {
	my $iso    = $ISOLATION_CLASS->new;
	my $schema = { foo => { _analysis => { side_effects => { purity_level => 'pure' },
	                                        dependencies => { time => 0 } } } };
	my $res    = $iso->plan($schema, { foo => 1 });
	ok(!exists $res->{foo}{time}, 'time => 0 is omitted from result');
};

subtest 'EP: Planner::Isolation — dependencies.time = "" (falsy string) → key omitted' => sub {
	my $iso    = $ISOLATION_CLASS->new;
	my $schema = { foo => { _analysis => { side_effects => { purity_level => 'pure' },
	                                        dependencies => { time => '' } } } };
	my $res    = $iso->plan($schema, { foo => 1 });
	ok(!exists $res->{foo}{time}, 'time => "" is omitted from result');
};

subtest 'EP: Planner::Isolation — dependencies.time = 1 (truthy) → key present, normalised to 1' => sub {
	my $iso    = $ISOLATION_CLASS->new;
	my $schema = { foo => { _analysis => { side_effects => { purity_level => 'pure' },
	                                        dependencies => { time => 1 } } } };
	my $res    = $iso->plan($schema, { foo => 1 });
	is($res->{foo}{time}, 1, 'time => 1 is present and normalised to 1');
};

subtest 'EP: Planner::Isolation — dependencies.network domain mirrors time' => sub {
	my $iso     = $ISOLATION_CLASS->new;
	my $schema0 = { m => { _analysis => { side_effects => { purity_level => 'pure' },
	                                       dependencies => { network => 0 } } } };
	my $res_off = $iso->plan($schema0, { m => 1 });
	ok(!exists $res_off->{m}{network}, 'network => 0 omitted');

	my $schema1 = { m => { _analysis => { side_effects => { purity_level => 'pure' },
	                                       dependencies => { network => 1 } } } };
	my $res_on  = $iso->plan($schema1, { m => 1 });
	is($res_on->{m}{network}, 1, 'network => 1 present');
};

subtest 'EP: Planner::Isolation — dependencies.env = {} (empty hashref, truthy ref) → key present' => sub {
	my $iso    = $ISOLATION_CLASS->new;
	my $schema = { foo => { _analysis => { side_effects => { purity_level => 'pure' },
	                                        dependencies => { env => {} } } } };
	my $res    = $iso->plan($schema, { foo => 1 });
	ok(exists $res->{foo}{env}, 'env => {} (truthy ref) is present in result');
};

subtest 'EP: Planner::Isolation — dependencies.env = 0 (falsy scalar) → key omitted' => sub {
	my $iso    = $ISOLATION_CLASS->new;
	my $schema = { foo => { _analysis => { side_effects => { purity_level => 'pure' },
	                                        dependencies => { env => 0 } } } };
	my $res    = $iso->plan($schema, { foo => 1 });
	ok(!exists $res->{foo}{env}, 'env => 0 (falsy scalar) omitted');
};

subtest 'EP: Planner::Isolation — dependencies.env = {K=>V} → stored verbatim' => sub {
	my $iso     = $ISOLATION_CLASS->new;
	my $env_val = { TZ => 'UTC' };
	my $schema  = { foo => { _analysis => { side_effects => { purity_level => 'pure' },
	                                         dependencies => { env => $env_val } } } };
	my $res     = $iso->plan($schema, { foo => 1 });
	is_deeply($res->{foo}{env}, $env_val, 'env hashref stored verbatim');
};

# ==================================================================
# GROUP C — PodExampleExtractor::new and extract
# ==================================================================

use File::Temp qw(tempfile tempdir);
use File::Spec;
use File::Path qw(make_path);
use App::Test::Generator::PodExampleExtractor;

Readonly my $EXTRACTOR_CLASS => 'App::Test::Generator::PodExampleExtractor';

subtest 'EP: PodExampleExtractor::new — undef file croaks' => sub {
	throws_ok { $EXTRACTOR_CLASS->new(file => undef) }
		qr/file is required/, 'undef file → croaks "file is required"';
};

subtest 'EP: PodExampleExtractor::new — absent file key croaks' => sub {
	throws_ok { $EXTRACTOR_CLASS->new() }
		qr/file is required/, 'absent file → croaks "file is required"';
};

subtest 'EP: PodExampleExtractor::new — non-existent path croaks' => sub {
	throws_ok { $EXTRACTOR_CLASS->new(file => '/no/such/file.pm') }
		qr/File not found/, 'non-existent file → croaks "File not found"';
};

subtest 'EP: PodExampleExtractor::new — directory path croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { $EXTRACTOR_CLASS->new(file => $dir) }
		qr/File not found/, 'directory path → croaks "File not found"';
};

subtest 'BVA: PodExampleExtractor::extract — file with 0 examples returns empty arrayref' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh "package NoExamples;\n1;\n";
	close $fh;
	my $ex  = $EXTRACTOR_CLASS->new(file => $path);
	my $res = $ex->extract;
	is(ref($res), 'ARRAY', 'extract returns arrayref');
	is(scalar @$res, 0, 'empty arrayref for file with no POD examples');
};

subtest 'BVA: PodExampleExtractor::extract — file with exactly 1 example' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh <<'PM';
package OneEx;
=head1 SYNOPSIS
    my $x = 1;
=cut
1;
PM
	close $fh;
	my $ex  = $EXTRACTOR_CLASS->new(file => $path);
	my $res = $ex->extract;
	is(scalar @$res, 1, 'exactly 1 example returned');
	ok(defined $res->[0]{label},   'entry has label');
	ok(defined $res->[0]{section}, 'entry has section');
	ok(defined $res->[0]{code},    'entry has code');
};

subtest 'EP: PodExampleExtractor::extract — annotated line captures expected value' => sub {
	my ($fh, $path) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $fh <<'PM';
package Annotated;
=head1 SYNOPSIS
    my $result = add(1, 2);    # returns 3
=cut
1;
PM
	close $fh;
	my $ex  = $EXTRACTOR_CLASS->new(file => $path);
	my $res = $ex->extract;
	my @ann = grep { defined $_->{expected} } @$res;
	ok(scalar @ann > 0, 'at least one annotated example with expected value');
	is($ann[0]{expected}, '3', 'expected value correctly captured');
};

# ==================================================================
# GROUP D — Mutator::new parameter domain
# ==================================================================

use App::Test::Generator::Mutator;

Readonly my $MUTATOR_CLASS => 'App::Test::Generator::Mutator';

{
	# Create a real .pm file to use as the Mutator file target
	my ($mfh, $mpath) = tempfile(SUFFIX => '.pm', UNLINK => 1);
	print $mfh "package Dummy;\n1;\n";
	close $mfh;

	subtest 'EP: Mutator::new — absent file croaks' => sub {
		throws_ok { $MUTATOR_CLASS->new(lib_dir => 'lib') }
			qr/file required/, 'absent file → croaks "file required"';
	};

	subtest 'EP: Mutator::new — undef file croaks' => sub {
		throws_ok { $MUTATOR_CLASS->new(file => undef, lib_dir => 'lib') }
			qr/file required/, 'undef file → croaks "file required"';
	};

	subtest 'EP: Mutator::new — non-existent file croaks' => sub {
		throws_ok { $MUTATOR_CLASS->new(file => '/no/such/module.pm') }
			qr/file not found/, 'non-existent file → croaks "file not found"';
	};

	subtest 'EP: Mutator::new — valid relative lib_dir accepted' => sub {
		lives_ok {
			$MUTATOR_CLASS->new(file => $mpath, lib_dir => 'lib')
		} 'valid relative lib_dir accepted';
	};

	subtest 'EP: Mutator::new — absent mutation_level defaults to "full"' => sub {
		my $mut = $MUTATOR_CLASS->new(file => $mpath);
		is($mut->{mutation_level}, 'full', 'absent mutation_level defaults to full');
	};

	subtest 'EP: Mutator::new — mutation_level "fast" accepted' => sub {
		my $mut = $MUTATOR_CLASS->new(file => $mpath, mutation_level => 'fast');
		is($mut->{mutation_level}, 'fast', 'fast mutation_level stored correctly');
	};

	subtest 'EP: Mutator::new — mutation_level "full" accepted' => sub {
		my $mut = $MUTATOR_CLASS->new(file => $mpath, mutation_level => 'full');
		is($mut->{mutation_level}, 'full', 'full mutation_level stored correctly');
	};
}

# ==================================================================
# GROUP E — BenchmarkGenerator::_build_call dispatch EP
# ==================================================================

Readonly my $BENCH_CLASS => 'App::Test::Generator::BenchmarkGenerator';

subtest 'EP: BenchmarkGenerator::_build_call — named + has_new → $obj->func(k=>v)' => sub {
	my $input = { x => { type => 'integer' }, y => { type => 'integer' } };
	my $call = App::Test::Generator::BenchmarkGenerator::_build_call(
		'Mod', 'func', 1, $input);
	like($call, qr/^\$obj->func\(/, 'named + has_new → $obj->func(...)');
};

subtest 'EP: BenchmarkGenerator::_build_call — named + !has_new → Module::func(k=>v)' => sub {
	my $input = { x => { type => 'integer' } };
	my $call = App::Test::Generator::BenchmarkGenerator::_build_call(
		'Mod', 'func', 0, $input);
	like($call, qr/^Mod::func\(/, 'named + !has_new → Module::func(...)');
};

subtest 'EP: BenchmarkGenerator::_build_call — positional + has_new → $obj->func(args)' => sub {
	my $input = { a => { type => 'integer', position => 0 } };
	my $call = App::Test::Generator::BenchmarkGenerator::_build_call(
		'Mod', 'func', 1, $input);
	like($call, qr/^\$obj->func\(/, 'positional + has_new → $obj->func(args)');
};

subtest 'EP: BenchmarkGenerator::_build_call — positional + !has_new + !builtin → Module::func(args)' => sub {
	my $input = { a => { type => 'integer', position => 0 } };
	my $call = App::Test::Generator::BenchmarkGenerator::_build_call(
		'Mod', 'func', 0, $input);
	like($call, qr/^Mod::func\(/, 'positional + !has_new + !builtin → Module::func(args)');
};

done_testing();
