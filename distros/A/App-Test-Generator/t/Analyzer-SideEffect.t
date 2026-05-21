#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Readonly;

BEGIN {
	use_ok('App::Test::Generator::Analyzer::SideEffect');
}

# --------------------------------------------------
# Purity classification labels matching the Readonly
# constants declared in the module under test.
# A rename in the source will cause the corresponding
# tests to fail deliberately rather than silently.
# --------------------------------------------------
Readonly my $PURITY_PURE          => 'pure';
Readonly my $PURITY_SELF_MUTATING => 'self_mutating';
Readonly my $PURITY_IMPURE        => 'impure';

# --------------------------------------------------
# Helper: call analyze with the given body string
# wrapped in the hashref the method expects.
# --------------------------------------------------
sub _analyze_body {
	my $body = $_[0];
	my $analyser = App::Test::Generator::Analyzer::SideEffect->new();
	return $analyser->analyze({ body => $body // '' });
}

# ==================================================================
# new
# --------------------------------------------------
# Tests for the constructor
# ==================================================================
subtest 'new' => sub {
	# Constructor returns a defined blessed object
	my $analyser = App::Test::Generator::Analyzer::SideEffect->new();
	ok(defined $analyser, 'new() returns defined value');
	isa_ok($analyser, 'App::Test::Generator::Analyzer::SideEffect');

	# Object is a plain blessed hashref in the correct class
	is(ref($analyser), 'App::Test::Generator::Analyzer::SideEffect',
		'object is blessed into correct class');

	# Each call produces a distinct object
	my $analyser2 = App::Test::Generator::Analyzer::SideEffect->new();
	isnt($analyser, $analyser2, 'each call produces a distinct object');

	done_testing();
};

# ==================================================================
# analyze -- return structure
# --------------------------------------------------
# The return value must always be a hashref with all
# six required keys regardless of input content
# ==================================================================
subtest 'analyze return structure' => sub {
	my $report = _analyze_body('');

	is(ref($report), 'HASH', 'analyze returns hashref');

	# All six keys must be present
	ok(exists $report->{mutates_self},    'mutates_self key present');
	ok(exists $report->{mutates_globals}, 'mutates_globals key present');
	ok(exists $report->{performs_io},     'performs_io key present');
	ok(exists $report->{calls_external},  'calls_external key present');
	ok(exists $report->{mutation_fields}, 'mutation_fields key present');
	ok(exists $report->{purity_level},    'purity_level key present');

	# mutation_fields must be an arrayref
	is(ref($report->{mutation_fields}), 'ARRAY', 'mutation_fields is arrayref');

	done_testing();
};

# ==================================================================
# analyze -- baseline: empty body
# --------------------------------------------------
# An empty method body must produce all-zero flags,
# an empty mutation_fields list, and purity 'pure'
# ==================================================================
subtest 'analyze: baseline for empty body' => sub {
	my $report = _analyze_body('');

	is($report->{mutates_self},    0,            'mutates_self is 0 for empty body');
	is($report->{mutates_globals}, 0,            'mutates_globals is 0 for empty body');
	is($report->{performs_io},     0,            'performs_io is 0 for empty body');
	is($report->{calls_external},  0,            'calls_external is 0 for empty body');
	is(scalar @{$report->{mutation_fields}}, 0,  'mutation_fields empty for empty body');
	is($report->{purity_level},    $PURITY_PURE, 'purity_level is pure for empty body');

	done_testing();
};

# ==================================================================
# analyze -- baseline: no-op body
# --------------------------------------------------
# A method that only reads but never assigns should
# also be classified as pure
# ==================================================================
subtest 'analyze: pure read-only method' => sub {
	my $body = 'sub get { my $self = shift; return $self->{name}; }';
	my $report = _analyze_body($body);

	is($report->{mutates_self},    0,            'read-only does not mutate self');
	is($report->{mutates_globals}, 0,            'read-only does not mutate globals');
	is($report->{performs_io},     0,            'read-only performs no IO');
	is($report->{calls_external},  0,            'read-only calls no external');
	is($report->{purity_level},    $PURITY_PURE, 'read-only is pure');

	done_testing();
};

# ==================================================================
# analyze -- mutates_self detection
# --------------------------------------------------
# Pattern: $self->{field} = value
# ==================================================================
subtest 'analyze: mutates_self detection' => sub {
	# Simple single-field assignment
	my $report = _analyze_body(
		'sub set_name { my ($self, $n) = @_; $self->{name} = $n; }'
	);
	is($report->{mutates_self}, 1, 'single field assignment detected');
	ok(grep({ $_ eq 'name' } @{$report->{mutation_fields}}),
		'field name captured in mutation_fields');

	# Multiple distinct fields -- all captured
	$report = _analyze_body(
		'sub init { $self->{name} = "x"; $self->{age} = 0; }'
	);
	is($report->{mutates_self}, 1, 'multiple field assignments detected');
	my %fields = map { $_ => 1 } @{$report->{mutation_fields}};
	ok($fields{name}, 'name field captured');
	ok($fields{age},  'age field captured');

	# Same field assigned twice -- must be deduplicated
	$report = _analyze_body(
		'sub reset { $self->{count} = 0; $self->{count} = 1; }'
	);
	is($report->{mutates_self}, 1, 'repeated field assignment detected');
	my @counts = grep { $_ eq 'count' } @{$report->{mutation_fields}};
	is(scalar @counts, 1, 'repeated field deduplicated in mutation_fields');

	# Reading from $self->{field} without assignment must NOT trigger
	$report = _analyze_body('sub get { return $self->{value}; }');
	is($report->{mutates_self}, 0, 'read-only access does not set mutates_self');
	is(scalar @{$report->{mutation_fields}}, 0,
		'read-only access produces no mutation_fields');

	done_testing();
};

# ==================================================================
# analyze -- mutates_globals detection
# --------------------------------------------------
# The GLOBAL_PATTERN covers %ENV, %SIG, @ARGV, $_, $/, $0 etc.
# Note: $_ matches because it is a Perl global; $/ does not match
# the \$\/ branch because the slash in qr// needs special handling.
# The test expectations reflect actual module behaviour.
# ==================================================================
subtest 'analyze: mutates_globals detection' => sub {
	# %ENV modification
	my $report = _analyze_body('$ENV{PATH} = "/usr/bin";');
	is($report->{mutates_globals}, 1, '%ENV triggers mutates_globals');

	# %SIG modification
	$report = _analyze_body('$SIG{__WARN__} = sub {};');
	is($report->{mutates_globals}, 1, '%SIG triggers mutates_globals');

	# @ARGV reference
	$report = _analyze_body('my @args = @ARGV;');
	is($report->{mutates_globals}, 1, '@ARGV triggers mutates_globals');

	# $_ special variable
	$report = _analyze_body('$_ = "reset";');
	is($report->{mutates_globals}, 1, '$_ triggers mutates_globals');

	# $/ special variable (input record separator)
	$report = _analyze_body('local $/ = undef;');
	is($report->{mutates_globals}, 1, '$/ triggers mutates_globals');

	# $0 (program name)
	$report = _analyze_body('$0 = "new_name";');
	is($report->{mutates_globals}, 1, '$0 triggers mutates_globals');

	# Clean code with no globals -- must produce 0
	$report = _analyze_body('my $x = 42; return $x;');
	is($report->{mutates_globals}, 0, 'no global pattern produces 0');

	done_testing();
};

# ==================================================================
# analyze -- performs_io detection
# --------------------------------------------------
# Patterns: print, say, printf, warn, open, close,
# syswrite, sysread, readline, read, write
# ==================================================================
subtest 'analyze: performs_io detection' => sub {
	# print statement
	my $report = _analyze_body('print "hello\n";');
	is($report->{performs_io}, 1, 'print triggers performs_io');

	# say statement
	$report = _analyze_body('say "hello";');
	is($report->{performs_io}, 1, 'say triggers performs_io');

	# printf statement
	$report = _analyze_body('printf "%s\n", $x;');
	is($report->{performs_io}, 1, 'printf triggers performs_io');

	# warn statement
	$report = _analyze_body('warn "something wrong";');
	is($report->{performs_io}, 1, 'warn triggers performs_io');

	# open call
	$report = _analyze_body('open my $fh, "<", $file or die;');
	is($report->{performs_io}, 1, 'open triggers performs_io');

	# close call
	$report = _analyze_body('close $fh;');
	is($report->{performs_io}, 1, 'close triggers performs_io');

	# syswrite call
	$report = _analyze_body('syswrite $fh, $data;');
	is($report->{performs_io}, 1, 'syswrite triggers performs_io');

	# sysread call
	$report = _analyze_body('sysread $fh, my $buf, 1024;');
	is($report->{performs_io}, 1, 'sysread triggers performs_io');

	# readline call
	$report = _analyze_body('my $line = readline $fh;');
	is($report->{performs_io}, 1, 'readline triggers performs_io');

	# Clean code with no IO -- must produce 0
	$report = _analyze_body('my $x = $self->{name}; return $x;');
	is($report->{performs_io}, 0, 'no IO pattern produces 0');

	done_testing();
};

# ==================================================================
# analyze -- calls_external detection
# --------------------------------------------------
# Patterns: system(), exec(), qx(), backtick operator
# ==================================================================
subtest 'analyze: calls_external detection' => sub {
	# system() call
	my $report = _analyze_body('system("ls -la");');
	is($report->{calls_external}, 1, 'system() triggers calls_external');

	# exec() call
	$report = _analyze_body('exec "perl", $script;');
	is($report->{calls_external}, 1, 'exec triggers calls_external');

	# qx() call
	$report = _analyze_body('my $out = qx(ls);');
	is($report->{calls_external}, 1, 'qx() triggers calls_external');

	# Backtick operator
	$report = _analyze_body('my $out = `ls -la`;');
	is($report->{calls_external}, 1, 'backtick triggers calls_external');

	# Clean code with no external calls -- must produce 0
	$report = _analyze_body('return $self->{value} + 1;');
	is($report->{calls_external}, 0, 'no external call pattern produces 0');

	done_testing();
};

# ==================================================================
# analyze -- purity_level classification
# --------------------------------------------------
# Three levels: pure, self_mutating, impure
# ==================================================================
subtest 'analyze: purity_level classification' => sub {
	# Pure: no side effects of any kind
	my $report = _analyze_body('sub get { my $self = shift; return $self->{name}; }');
	is($report->{purity_level}, $PURITY_PURE,
		'read-only method is pure');

	# Pure: arithmetic with no mutation or IO
	$report = _analyze_body(
		'sub add { my ($self, $x, $y) = @_; return $x + $y; }'
	);
	is($report->{purity_level}, $PURITY_PURE,
		'arithmetic method with no mutation is pure');

	# self_mutating: only mutates own state, no external effects
	$report = _analyze_body(
		'sub set { my ($self, $v) = @_; $self->{value} = $v; return $self; }'
	);
	is($report->{purity_level}, $PURITY_SELF_MUTATING,
		'setter with no external effects is self_mutating');

	# impure: performs IO even without self mutation
	$report = _analyze_body('sub log_it { print "logged\n"; }');
	is($report->{purity_level}, $PURITY_IMPURE,
		'IO without self mutation is impure');

	# impure: calls external even without self mutation
	$report = _analyze_body('sub run { system("ls"); }');
	is($report->{purity_level}, $PURITY_IMPURE,
		'external call without self mutation is impure');

	# impure: mutates globals even without self mutation
	$report = _analyze_body('sub setup { $ENV{KEY} = "val"; }');
	is($report->{purity_level}, $PURITY_IMPURE,
		'global mutation without self mutation is impure');

	# impure: mutates self AND performs IO
	$report = _analyze_body(
		'sub save { $self->{saved} = 1; print "saved\n"; }'
	);
	is($report->{purity_level}, $PURITY_IMPURE,
		'self mutation + IO is impure');

	# impure: mutates self AND calls external
	$report = _analyze_body(
		'sub deploy { $self->{deployed} = 1; system("deploy.sh"); }'
	);
	is($report->{purity_level}, $PURITY_IMPURE,
		'self mutation + external call is impure');

	done_testing();
};

# ==================================================================
# analyze -- mutation_fields content and deduplication
# ==================================================================
subtest 'analyze: mutation_fields content' => sub {
	# No fields when no self mutation occurs
	my $report = _analyze_body('sub get { return $self->{name}; }');
	is(scalar @{$report->{mutation_fields}}, 0,
		'mutation_fields empty when no assignment');

	# Single field captured by name
	# Note: $_[1] in the body also matches the $_ global pattern,
	# so use a clean positional-arg-free body here
	$report = _analyze_body(
		'sub set_name { my ($self, $n) = @_; $self->{name} = $n; }'
	);
	ok(grep({ $_ eq 'name' } @{$report->{mutation_fields}}),
		'name field captured');

	# Two distinct fields -- both present, order not guaranteed
	$report = _analyze_body(
		'sub init { $self->{x} = 0; $self->{y} = 0; }'
	);
	is(scalar @{$report->{mutation_fields}}, 2, 'two distinct fields captured');
	my %f = map { $_ => 1 } @{$report->{mutation_fields}};
	ok($f{x}, 'x field captured');
	ok($f{y}, 'y field captured');

	# Underscore-prefixed private field captured
	$report = _analyze_body(
		'sub _set { my ($self) = @_; $self->{_cache} = {}; }'
	);
	is(scalar @{$report->{mutation_fields}}, 1, 'private field captured');
	is($report->{mutation_fields}[0], '_cache', 'private field name correct');

	done_testing();
};

# ==================================================================
# analyze -- combined side effects
# --------------------------------------------------
# All flags can fire independently and simultaneously
# ==================================================================
subtest 'analyze: all flags can fire simultaneously' => sub {
	my $body = <<'CODE';
sub do_everything {
	my $self = shift;
	$self->{done} = 1;
	$ENV{STATUS} = 'running';
	print "starting\n";
	system("helper.sh");
	return $self;
}
CODE

	my $report = _analyze_body($body);

	is($report->{mutates_self},    1, 'mutates_self fires in combined body');
	is($report->{mutates_globals}, 1, 'mutates_globals fires in combined body');
	is($report->{performs_io},     1, 'performs_io fires in combined body');
	is($report->{calls_external},  1, 'calls_external fires in combined body');
	is($report->{purity_level},    $PURITY_IMPURE,
		'combined body is impure');

	done_testing();
};

# ==================================================================
# analyze -- tolerates missing body key
# --------------------------------------------------
# analyze must not die when body key is absent or undef
# ==================================================================
subtest 'analyze: tolerates missing body key' => sub {
	my $analyser = App::Test::Generator::Analyzer::SideEffect->new();

	# No body key at all -- defaults to empty string
	lives_ok { $analyser->analyze({}) }
		'analyze lives when body key absent';

	my $report = $analyser->analyze({});
	is($report->{purity_level}, $PURITY_PURE,
		'absent body defaults to pure');

	# Explicit undef body -- defaults to empty string
	lives_ok { $analyser->analyze({ body => undef }) }
		'analyze lives when body is undef';

	$report = $analyser->analyze({ body => undef });
	is($report->{purity_level}, $PURITY_PURE,
		'undef body defaults to pure');

	done_testing();
};

# ==================================================================
# analyze -- purity_level string values match constants
# ==================================================================
subtest 'purity_level constants have correct values' => sub {
	is($PURITY_PURE,          'pure',         'PURITY_PURE is "pure"');
	is($PURITY_SELF_MUTATING, 'self_mutating', 'PURITY_SELF_MUTATING is "self_mutating"');
	is($PURITY_IMPURE,        'impure',        'PURITY_IMPURE is "impure"');

	# Confirm they are all distinct from each other
	isnt($PURITY_PURE,          $PURITY_SELF_MUTATING, 'pure != self_mutating');
	isnt($PURITY_PURE,          $PURITY_IMPURE,        'pure != impure');
	isnt($PURITY_SELF_MUTATING, $PURITY_IMPURE,        'self_mutating != impure');

	done_testing();
};

done_testing();
