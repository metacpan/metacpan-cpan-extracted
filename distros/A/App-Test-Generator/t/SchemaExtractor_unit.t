#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;
use App::Test::Generator::Provenance qw(source_is_valid);
use File::Temp qw(tempdir);
use File::Spec;

# Black-box unit tests for App::Test::Generator::SchemaExtractor.
# Tests each public function according to its POD API specification.

BEGIN { use_ok('App::Test::Generator::SchemaExtractor') }

# --------------------------------------------------
# Helper: write a minimal .pm file and return its path
# --------------------------------------------------
sub _make_pm {
	my ($src, $name) = @_;
	$name //= 'TestModule.pm';
	my $tmpdir = tempdir(CLEANUP => 1);
	my $pm     = File::Spec->catfile($tmpdir, $name);
	open my $fh, '>', $pm or die "Cannot write $pm: $!";
	print $fh $src;
	close $fh;
	return ($pm, $tmpdir);
}

my $SIMPLE_SRC = <<'END_PM';
package TestModule;

=head2 greet

Say hello.

=head3 Arguments

=over 4

=item * C<name> - the name to greet (string, required)

=back

=head3 Returns

A greeting string.

=cut

sub greet {
	my ($self, $name) = @_;
	return "Hello, $name";
}

1;
END_PM

my $MULTI_SRC = <<'END_PM';
package TestModule;

sub public_method { return 1 }
sub _private_method { return 2 }
sub another_public { return 3 }

1;
END_PM

# ==================================================================
# new()
#
# POD spec:
#   Required: input_file (must exist on disk)
#   Optional: output_dir, verbose, include_private,
#             max_parameters, confidence_threshold, strict_pod
#   Returns:  blessed hashref
#   Croaks:   when input_file is missing or does not exist
# ==================================================================

subtest 'new() returns a blessed SchemaExtractor object' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	isa_ok($e, 'App::Test::Generator::SchemaExtractor');
};

subtest 'new() croaks when input_file is missing' => sub {
	throws_ok(
		sub { App::Test::Generator::SchemaExtractor->new() },
		qr/input_file required|Usage.*input_file/,
		'missing input_file croaks',
	);
};

subtest 'new() croaks when input_file does not exist on disk' => sub {
	throws_ok(
		sub {
			App::Test::Generator::SchemaExtractor->new(
				input_file => '/no/such/file.pm'
			)
		},
		qr/does not exist/,
		'nonexistent file croaks',
	);
};

subtest 'new() stores input_file' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	is($e->{input_file}, $pm, 'input_file stored correctly');
};

subtest 'new() stores optional output_dir' => sub {
	my ($pm, $tmpdir) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		output_dir => $tmpdir,
	);
	is($e->{output_dir}, $tmpdir, 'output_dir stored correctly');
};

subtest 'new() defaults verbose to 0' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	is($e->{verbose}, 0, 'verbose defaults to 0');
};

subtest 'new() stores supplied verbose flag' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		verbose    => 1,
	);
	is($e->{verbose}, 1, 'verbose stored as 1');
};

subtest 'new() defaults include_private to 0' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	is($e->{include_private}, 0, 'include_private defaults to 0');
};

subtest 'new() stores supplied include_private flag' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file      => $pm,
		include_private => 1,
	);
	is($e->{include_private}, 1, 'include_private stored as 1');
};

subtest 'new() defaults max_parameters to 20' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	is($e->{max_parameters}, 20, 'max_parameters defaults to 20');
};

subtest 'new() stores supplied max_parameters' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file     => $pm,
		max_parameters => 50,
	);
	is($e->{max_parameters}, 50, 'max_parameters stored as 50');
};

subtest 'new() defaults confidence_threshold to 0.5' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	is($e->{confidence_threshold}, 0.5, 'confidence_threshold defaults to 0.5');
};

subtest 'new() stores supplied confidence_threshold' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file           => $pm,
		confidence_threshold => 0.8,
	);
	is($e->{confidence_threshold}, 0.8, 'confidence_threshold stored as 0.8');
};

subtest 'new() defaults strict_pod to 0' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	is($e->{strict_pod}, 0, 'strict_pod defaults to 0');
};

subtest 'new() accepts strict_pod numeric values 0, 1, 2' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	for my $level (0, 1, 2) {
		my $e = App::Test::Generator::SchemaExtractor->new(
			input_file => $pm,
			strict_pod => $level,
		);
		is($e->{strict_pod}, $level, "strict_pod=$level stored correctly");
	}
};

subtest 'new() accepts strict_pod string values off/warn/fatal' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my %map = (off => 0, warn => 1, fatal => 2);
	for my $str (qw(off warn fatal)) {
		my $e = App::Test::Generator::SchemaExtractor->new(
			input_file => $pm,
			strict_pod => $str,
		);
		is($e->{strict_pod}, $map{$str},
			"strict_pod='$str' normalised to $map{$str}");
	}
};

subtest 'new() each call returns a distinct object' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e1 = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $e2 = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	isnt($e1, $e2, 'distinct objects returned');
};

# ==================================================================
# extract_all()
#
# POD spec:
#   Optional: no_write (default 0)
#   Returns:  hashref of method_name => schema_hashref
#   Each schema has: function, module, input, output, _analysis keys
#   Private methods excluded unless include_private set
#   Does not write files when no_write => 1
# ==================================================================

subtest 'extract_all() returns a hashref' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $result = $e->extract_all(no_write => 1);
	is(ref($result), 'HASH', 'returns hashref');
};

subtest 'extract_all() includes public methods' => sub {
	my ($pm) = _make_pm($MULTI_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	ok(exists $schemas->{public_method},  'public_method included');
	ok(exists $schemas->{another_public}, 'another_public included');
};

subtest 'extract_all() excludes private methods by default' => sub {
	my ($pm) = _make_pm($MULTI_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	ok(!exists $schemas->{_private_method}, '_private_method excluded by default');
};

subtest 'extract_all() includes private methods when include_private set' => sub {
	my ($pm) = _make_pm($MULTI_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file      => $pm,
		include_private => 1,
	);
	my $schemas = $e->extract_all(no_write => 1);
	ok(exists $schemas->{_private_method}, '_private_method included when flag set');
};

subtest 'extract_all() each schema has required keys' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	for my $method (keys %{$schemas}) {
		my $s = $schemas->{$method};
		for my $key (qw(function module input output _analysis)) {
			ok(exists $s->{$key}, "$method schema has '$key' key");
		}
	}
};

subtest 'extract_all() function key matches method name' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	for my $method (keys %{$schemas}) {
		is($schemas->{$method}{function}, $method,
			"$method: function key matches method name");
	}
};

subtest 'extract_all() module key contains package name' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	for my $method (keys %{$schemas}) {
		is($schemas->{$method}{module}, 'TestModule',
			"$method: module key is TestModule");
	}
};

subtest 'extract_all() input and output keys are hashrefs' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	for my $method (keys %{$schemas}) {
		is(ref($schemas->{$method}{input}),  'HASH',
			"$method: input is a hashref");
		is(ref($schemas->{$method}{output}), 'HASH',
			"$method: output is a hashref");
	}
};

subtest 'extract_all() no_write => 1 does not create output files' => sub {
	my ($pm, $tmpdir) = _make_pm($SIMPLE_SRC);
	my $out = File::Spec->catdir($tmpdir, 'schemas');
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		output_dir => $out,
	);
	$e->extract_all(no_write => 1);
	ok(!-d $out, 'output_dir not created when no_write => 1');
};

subtest 'extract_all() with no_write => 0 writes schema files' => sub {
	my ($pm, $tmpdir) = _make_pm($SIMPLE_SRC);
	my $out = File::Spec->catdir($tmpdir, 'schemas');
	mkdir $out or die $!;
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		output_dir => $out,
	);
	lives_ok(sub { $e->extract_all(no_write => 0) },
		'extract_all with no_write=>0 lives');
	my @files = glob(File::Spec->catfile($out, '*.yml'));
	ok(scalar @files > 0, 'schema YAML files written to output_dir');
};

subtest 'extract_all() returns empty hashref for module with no subs' => sub {
	my ($pm) = _make_pm("package Empty;\n1;\n");
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	is(scalar keys %{$schemas}, 0, 'empty hashref for module with no subs');
};

# ==================================================================
# generate_pod_validation_report()
#
# POD spec:
#   Arguments: $schemas (hashref, required)
#   Returns:   string — report or all-passed message
#   No side effects.
#   Only shows methods with _pod_validation_errors key.
#   Returns all-passed message when no errors found.
# ==================================================================

subtest 'generate_pod_validation_report() returns a string' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	my $report = $e->generate_pod_validation_report($schemas);
	ok(defined $report,    'returns defined value');
	ok(!ref($report),      'returns a scalar string');
	ok(length($report) > 0, 'returns non-empty string');
};

subtest 'generate_pod_validation_report() returns all-passed for no errors' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	# strict_pod => 0 means no errors are recorded
	my $schemas = $e->extract_all(no_write => 1);
	my $report = $e->generate_pod_validation_report($schemas);
	like($report, qr/All methods passed/i,
		'all-passed message when strict_pod is 0');
};

subtest 'generate_pod_validation_report() includes method name when errors present' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	# Inject a fake validation error directly into a schema
	my $schemas = {
		my_method => {
			function              => 'my_method',
			module                => 'TestModule',
			input                 => {},
			output                => {},
			_analysis             => {},
			_pod_validation_errors => ['param foo in POD but not code'],
			_pod_disagreement     => 1,
		}
	};
	my $report = $e->generate_pod_validation_report($schemas);
	like($report, qr/my_method/, 'method name appears in report');
	like($report, qr/foo in POD but not code/, 'error text appears in report');
};

subtest 'generate_pod_validation_report() includes POD/Code header when errors present' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = {
		foo => {
			function               => 'foo',
			module                 => 'TestModule',
			input                  => {},
			output                 => {},
			_analysis              => {},
			_pod_validation_errors => ['some error'],
			_pod_disagreement      => 1,
		}
	};
	my $report = $e->generate_pod_validation_report($schemas);
	like($report, qr/POD.+Validation|Validation.+Report/i,
		'report header present');
};

subtest 'generate_pod_validation_report() skips methods with no errors' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = {
		clean_method => {
			function  => 'clean_method',
			module    => 'TestModule',
			input     => {},
			output    => {},
			_analysis => {},
			# no _pod_validation_errors key
		},
		broken_method => {
			function               => 'broken_method',
			module                 => 'TestModule',
			input                  => {},
			output                 => {},
			_analysis              => {},
			_pod_validation_errors => ['type mismatch for param x'],
			_pod_disagreement      => 1,
		},
	};
	my $report = $e->generate_pod_validation_report($schemas);
	unlike($report, qr/clean_method/, 'clean method not in report');
	like($report,   qr/broken_method/, 'broken method in report');
};

subtest 'generate_pod_validation_report() methods appear in sorted order' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = {
		z_method => {
			function               => 'z_method',
			module                 => 'TestModule',
			input                  => {},
			output                 => {},
			_analysis              => {},
			_pod_validation_errors => ['error z'],
			_pod_disagreement      => 1,
		},
		a_method => {
			function               => 'a_method',
			module                 => 'TestModule',
			input                  => {},
			output                 => {},
			_analysis              => {},
			_pod_validation_errors => ['error a'],
			_pod_disagreement      => 1,
		},
	};
	my $report = $e->generate_pod_validation_report($schemas);
	my $pos_a = index($report, 'a_method');
	my $pos_z = index($report, 'z_method');
	ok($pos_a < $pos_z, 'a_method appears before z_method in sorted output');
};

subtest 'generate_pod_validation_report() has no side effects' => sub {
	my ($pm) = _make_pm($SIMPLE_SRC);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	my $keys_before = join ',', sort keys %{$schemas};
	$e->generate_pod_validation_report($schemas);
	my $keys_after = join ',', sort keys %{$schemas};
	is($keys_after, $keys_before, 'schemas hashref unchanged after report');
};

# ==================================================================
# Regression: numeric boundary value hints must not be double-counted.
#
# _analyze_method used two separate %seen guards for the same loop —
# one keyed on the raw (possibly undef) value, one keyed on a
# normalised '__undef__' placeholder — so an undef boundary value
# could be pushed twice. _numeric_boundary_values() never actually
# returns undef today, but the dedup logic must still be correct if
# that ever changes (and a single dedup pass is also simpler).
# ==================================================================

subtest '_analyze_method() does not double-count numeric boundary hints' => sub {
	Test::Mockingbird::mock(
		'App::Test::Generator::SchemaExtractor',
		'_numeric_boundary_values',
		sub { return [ -1, 0, undef, 1 ] },
	);

	my $src = <<'END_PM';
package TestModule;

sub add_one {
	my ($self, $n) = @_;
	return $n + 1;
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	my $boundary_values = $schemas->{add_one}{_yamltest_hints}{boundary_values};
	ok($boundary_values, 'boundary_values hint present');

	my $undef_count = grep { !defined $_ } @{$boundary_values};
	is($undef_count, 1, 'undef boundary value appears exactly once, not twice');

	Test::Mockingbird::unmock('App::Test::Generator::SchemaExtractor', '_numeric_boundary_values');
};

# --------------------------------------------------
# Invocant variable stripping: $pkg, $proto, $klass
# --------------------------------------------------

subtest 'import with $pkg invocant produces no input parameters' => sub {
	my $src = <<'END_PM';
package Database::Abstraction;

=head2 import

Initialise via C<use>.

=cut

sub import
{
	my $pkg = shift;

	if((scalar(@_) % 2) == 0) {
		my %h = @_;
		configure($pkg, \%h);
	} elsif((scalar(@_) == 1) && (ref($_[0]) eq 'HASH')) {
		configure($pkg, $_[0]);
	}
}

1;
END_PM
	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	ok(exists $schemas->{import}, 'import sub found');
	my $input = $schemas->{import}{input} // {};
	ok(!exists $input->{pkg}, '$pkg not extracted as input parameter');
	is(scalar keys %$input, 0, 'import has no extracted input parameters');
};

subtest 'constructor with $proto invocant produces no invocant parameter' => sub {
	my $src = <<'END_PM';
package Foo;

=head2 new

Constructor.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	return bless {}, $class;
}

1;
END_PM
	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	ok(exists $schemas->{new}, 'new sub found');
	my $input = $schemas->{new}{input} // {};
	ok(!exists $input->{proto}, '$proto not extracted as input parameter');
};

subtest 'class method with $klass invocant produces no invocant parameter' => sub {
	my $src = <<'END_PM';
package Bar;

=head2 create

Factory method.

=cut

sub create {
	my $klass = shift;
	my ($x) = @_;
	return bless { x => $x }, $klass;
}

1;
END_PM
	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	ok(exists $schemas->{create}, 'create sub found');
	my $input = $schemas->{create}{input} // {};
	ok(!exists $input->{klass}, '$klass not extracted as input parameter');
	ok(exists $input->{x}, 'real parameter $x is still extracted');
};

# ==================================================================
# Documented file writes
#
# A routine whose POD documents creating a file is doing what it was
# asked to do, so the generated schema must turn the harness's
# leftover-file test off for it.
# ==================================================================

subtest '_pod_documents_file_write recognises a documented file write' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	my $pod = <<'END_POD';
=head3 SIDE EFFECTS

=over 4

=item * Creates or updates the local cache file on a successful download.

=back
END_POD

	ok($e->_pod_documents_file_write($pod), 'creating a file counts as a file write');
};

subtest '_pod_documents_file_write ignores files named outside SIDE EFFECTS' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	my $pod = <<'END_POD';
=head3 ARGUMENTS

=item * C<output_file> - the file to write.

=head3 SIDE EFFECTS

=item * Populates the in-memory lookup table.

=back
END_POD

	ok(!$e->_pod_documents_file_write($pod), 'an argument description alone is not a side effect');
};

subtest '_pod_documents_file_write handles missing POD' => sub {
	my $e = bless {}, 'App::Test::Generator::SchemaExtractor';
	ok(!$e->_pod_documents_file_write(undef), 'no POD means no documented file write');
};

subtest '_write_schema emits check_files: 0 for a documented file writer' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $e = bless { output_dir => $dir }, 'App::Test::Generator::SchemaExtractor';
	my $schema = {
		function => 'write_cache',
		input => {},
		output => { type => 'hashref' },
		_confidence => {
			input  => { level => 'low' },
			output => { level => 'low' },
		},
		_analysis => { side_effects => { writes_file => 1 } },
	};

	$e->_write_schema('write_cache', $schema);

	my $yaml = do {
		open my $fh, '<', File::Spec->catfile($dir, 'write_cache.yml') or die $!;
		local $/;
		<$fh>;
	};

	like($yaml, qr/^  check_files: 0$/m, 'check_files is off for the generated schema');
};

# ==================================================================
# Documented value lists in prose
#
# A parameter documented as "one of red, green or blue" has a
# documented set of valid values.  That is a statement about valid
# input, not a check the routine was seen to make, so the parameter
# is marked _source => 'pod' and the harness tolerates values outside
# the set.  Ordinary prose containing "one of" must not be mistaken
# for a list.
# ==================================================================

subtest '_analyze_pod reads a documented value list from prose' => sub {
	my $src = <<'END_PM';
package ProseModule;

=head2 paint

=head3 Arguments

=over 4

=item * C<$colour>

string, one of red, green or blue

=item * C<$level>

integer, must be one of C<1>, C<5> or C<111>

=item * C<$mode>

string; valid values are C<fast>, C<safe> and C<tiny>

=item * C<$switch>

string, either C<on> or C<off>

=item * C<$words>

string, one of the four recognised keys set to a true value also adds

=back

=cut

sub paint {
	my ($self, %args) = @_;
	return join(' ', map { $args{$_} // '' } qw(colour level mode switch words));
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	my $input = $schemas->{paint}{input};
	is_deeply($input->{colour}{memberof}, [qw(red green blue)],
		'"one of red, green or blue" sets the documented values');
	is($input->{colour}{_source}, 'pod',
		'a prose list is documentation, not a validator');
	is_deeply($input->{level}{memberof}, [qw(1 5 111)],
		'"must be one of" with C<> codes sets the values');
	is_deeply($input->{mode}{memberof}, [qw(fast safe tiny)],
		'"valid values are" sets the values');
	is_deeply($input->{switch}{memberof}, [qw(on off)],
		'"either X or Y" sets the values');
	ok(!exists $input->{words}{memberof},
		'ordinary prose containing "one of" is not a list');
};

# ==================================================================
# Regression: a compound length guard enforces nothing.
#
# `croak ... if length($text) < 5 || $other` still croaks for long text
# when $other is true, and `... if length($text) < 5 && $other` accepts
# short text when $other is false.  In both cases the whole condition does
# not require a length of 5, so the extractor must not turn the comparison
# into a min (and thereby into a promise the routine does not keep).
# ==================================================================

subtest 'a compound length guard yields no inferred bound' => sub {
	my $src = <<'END_PM';
package TestModule;

=head2 guard_or

=head4 input

	{
		text => { type => 'string', optional => 0 },
		other => { type => 'boolean', optional => 0 },
	}

=head4 output

	{ type => 'string' }

=cut

sub guard_or {
	my ($self, $text, $other) = @_;
	croak('too short') if length($text) < 5 || $other;
	return $text;
}

=head2 guard_and

=head4 input

	{
		text => { type => 'string', optional => 0 },
		other => { type => 'boolean', optional => 0 },
	}

=head4 output

	{ type => 'string' }

=cut

sub guard_and {
	my ($self, $text, $other) = @_;
	croak('too short') if length($text) < 5 && $other;
	return $text;
}

=head2 guard_simple

=head4 input

	{ text => { type => 'string', optional => 0 } }

=head4 output

	{ type => 'string' }

=cut

sub guard_simple {
	my ($self, $text) = @_;
	croak('too short') if length($text) < 5;
	return $text;
}

=head2 guard_unless

=head4 input

	{ text => { type => 'string', optional => 0 } }

=head4 output

	{ type => 'string' }

=cut

sub guard_unless {
	my ($self, $text) = @_;
	croak('too short') unless length($text) >= 5;
	return $text;
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	foreach my $function (qw(guard_or guard_and)) {
		my $text = $schemas->{$function}{input}{text};
		ok(!exists($text->{min}), "$function: the || / && comparison is not a minimum");
		ok(!exists($text->{max}), "$function: the || / && comparison is not a maximum");
		is($text->{type}, 'string', "$function: length() still marks the field as a string");
	}

	is($schemas->{guard_simple}{input}{text}{min}, 5,
		'an inverted whole-condition `if` guard still yields its bound');
	is($schemas->{guard_unless}{input}{text}{min}, 5,
		'a whole-condition `unless` guard still yields its bound');
};

# ==================================================================
# Provenance regression: every extracted parameter says where its type
# came from, and the removed flags cannot come back.
#
# _bounds_unverified, _type_checked and _from_input_spec were replaced by
# _source and _constraint_source.  A stale flag would be silently ignored
# by the harness, so extraction must never emit one again.
# ==================================================================

my @REMOVED_PROVENANCE = qw(_bounds_unverified _type_checked _from_input_spec);

sub _removed_provenance_paths
{
	my ($value, $path) = @_;

	$path //= '';
	return () unless ref($value);
	if(ref($value) eq 'HASH') {
		my @found;
		foreach my $key (sort keys %{$value}) {
			my $here = length($path) ? "$path.$key" : $key;
			push @found, $here if grep { $_ eq $key } @REMOVED_PROVENANCE;
			push @found, _removed_provenance_paths($value->{$key}, $here);
		}
		return @found;
	}
	if(ref($value) eq 'ARRAY') {
		return map { _removed_provenance_paths($value->[$_], "$path\[$_]") } 0 .. $#{$value};
	}
	return ();
}

subtest 'extracted parameters carry _source and no removed provenance flags' => sub {
	my $src = <<'END_PM';
package ProvenanceModule;

=head2 combine

=head4 input

	{ text => { type => 'string', optional => 0 }, count => { type => 'integer', optional => 1, min => 1 } }

=head4 output

	{ type => 'string' }

=cut

sub combine {
	my ($self, %args) = @_;
	croak('combine: text is required') unless defined $args{text};
	return $args{text} x ($args{count} // 1);
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	my $input = $schemas->{combine}{input};
	is_deeply([sort keys %{$input}], [qw(count text)], 'both documented parameters are extracted');

	foreach my $name (sort keys %{$input}) {
		my $spec = $input->{$name};
		ok(exists($spec->{_source}), "$name carries a _source");
		ok(source_is_valid($spec->{_source}), "$name has a recognised provenance value");
	}

	my @stale = _removed_provenance_paths($schemas);
	is_deeply(\@stale, [], 'no removed provenance flag is emitted anywhere in the schema');
};

# ==================================================================
# Input files
#
# A routine that only tests that a path exists (-e/-f) can be called
# with any real file, so the schema marks the parameter
# semantic => 'existing_file' and the harness supplies a temporary
# file.  A routine that reads the file's contents cannot be satisfied
# that way and stays skipped, with a reason that says why.
# ==================================================================

subtest 'a file-existence check gets an existing-file fixture, not a skip' => sub {
	my $src = <<'END_PM';
package ExistsModule;

use Carp qw(croak);

=head2 new

=head3 Arguments

=over 4

=item * C<$file>

Path to the module.

=back

=cut

sub new {
	my ($class, %args) = @_;
	croak('file required') unless defined $args{file};
	croak("file '$args{file}' does not exist") unless -f $args{file};
	return bless { file => $args{file} }, $class;
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	ok(!exists($schemas->{new}{skip}), 'the constructor is not skipped');
	is($schemas->{new}{input}{file}{semantic}, 'existing_file',
		'the path parameter is declared to need an existing file');
};

subtest 'a routine that parses file contents keeps a skip saying why' => sub {
	my $src = <<'END_PM';
package SlurpModule;

use Carp qw(croak);

=head2 load

=head3 Arguments

=over 4

=item * C<$file>

Path to the file to read.

=back

=cut

sub load {
	my ($class, %args) = @_;
	my $file = $args{file};
	croak('file required') unless defined $file;
	open my $fh, '<', $file or croak("cannot read $file: $!");
	local $/;
	my $text = <$fh>;
	close $fh;
	return $text;
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	like($schemas->{load}{skip}, qr/contents it parses/,
		'the skip says the routine parses the file contents');
	ok(!exists($schemas->{load}{input}{file}{semantic}),
		'a parsed file is not reduced to an existence-check fixture');
};

subtest 'a formal input spec is read when prose and comments come before it' => sub {
	my $src = <<'END_PM';
package ProseSpecModule;

=head2 new

=over 4

=item * C<logger> (optional, object)

An object used to write diagnostic messages.

=back

=head3 API SPECIFICATION

=head4 input

C<new()> normalizes its arguments.  The recognized parameters are:

    # Accepted as a flat list or a hash reference.
    {
        directory => { type => 'string' },   # readable directory path
        logger    => { type => 'object',
                       can => [ 'info', 'error' ],
                       optional => 1
                     },
    }

=cut

sub new {
	my ($class, %args) = @_;
	return bless { %args }, $class;
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{new}{input}{logger}{type}, 'object',
		'the type comes from the spec, not from the prose item');
	is($schemas->{new}{input}{logger}{_source}, 'input_spec', 'and is marked as coming from the spec');
	is($schemas->{new}{input}{directory}{type}, 'string', 'a parameter named only in the spec is found');
};

subtest 'config_file handed to Object::Configure needs an existing file' => sub {
	my $src = <<'END_PM';
package ConfiguredModule;

=head2 new

=head3 API SPECIFICATION

=head4 input

    {
        config_file => { type => 'string', optional => 1 },
        upload_dir  => { type => 'string', optional => 1 },
    }

=cut

sub new {
	my $class = shift;
	my $params = { @_ };

	$params = Object::Configure::configure($class, $params);
	return bless { %{$params} }, $class;
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	ok(!exists($schemas->{new}{skip}), 'the constructor is not skipped');
	is($schemas->{new}{input}{config_file}{semantic}, 'existing_file',
		'config_file is declared to need an existing file');
	isnt($schemas->{new}{input}{upload_dir}{semantic} // '', 'existing_file',
		'another string parameter is left alone');
};

subtest 'a constructor that parses a copied-out file argument is skipped, and so are its methods' => sub {
	my $src = <<'END_PM';
package ResultsModule;

use Carp qw(croak);

=head2 new

=head3 API SPECIFICATION

=head4 input

    { results_from => { type => 'any' } }

=cut

sub new {
	my ($class, %args) = @_;
	my $results = $args{results_from};
	if(!ref($results)) {
		croak "results_from '$results' does not exist" unless -f $results;
		open(my $fh, '<', $results) or croak "Cannot read '$results': $!";
		$results = do { local $/; <$fh> };
		close($fh);
	}
	return bless { results => $results }, $class;
}

=head2 count

Returns the number of results.

=cut

sub count {
	my $self = shift;
	return length($self->{results});
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	like($schemas->{new}{skip}, qr/needs an existing input file/,
		'open(...) on a local copy of the argument is seen as reading the file');
	ok(exists($schemas->{count}{new}) && !ref($schemas->{count}{new}),
		'the instance method is not given constructor arguments')
		or diag(explain($schemas->{count}{new}));
};

# ==================================================================
# Regression: an =item description that continues on later lines.
#
# /s makes `.` match newlines, so a greedy `-.*` in the =item pattern
# consumed everything up to the last =back/=head in the POD.  That hid
# every later parameter (strict_pod among them) and the documented
# value list in their descriptions.
# ==================================================================

subtest 'a value list in a multi-line =item description is read' => sub {
	my $src = <<'END_PM';
package ProseModule;

=head2 configure

=head3 Arguments

=over 4

=item * C<$mode>

Controls validation. C<0> disables it. Also accepts
the strings C<off>, C<warn>, and C<fatal>. Optional, default 0.

=item * C<$other>

string, required

=back

=cut

sub configure {
	my ($self, %args) = @_;
	return $args{mode} // 'off';
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	my $input = $schemas->{configure}{input};
	is_deeply($input->{mode}{memberof}, [qw(off warn fatal)],
		'the continuation-line value list is read');
	ok(exists($input->{other}),
		'an =item after the multi-line description is still extracted');
};

# ==================================================================
# Detections that the type inference cannot see in a signature.
#
# A callback is often only recognised when it is invoked or has ref()
# checked through $args{...}; a value checked against a module-level
# constant has that constant's values as its domain; an abstract method
# always dies; and a routine that returns a list must be called in list
# context, but only when the POD says it returns a list rather than an
# arrayref.
# ==================================================================

subtest 'coderef detection through $args{...}' => sub {
	my $src = <<'END_PM';
package CallbackModule;

=head2 map_values

=head3 Arguments

=over 4

=item * C<$callback>

Called for each value.

=item * C<$values>

The values.

=back

=cut

sub map_values {
	my ($self, %args) = @_;
	return [ map { $args{callback}->($_) } @{ $args{values} } ];
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{map_values}{input}{callback}{type}, 'coderef',
		'a callback invoked through $args{...} is a coderef');
};

subtest 'memberof from a module-level constant' => sub {
	my $src = <<'END_PM';
package ConstantModule;

use Carp qw(croak);

my %CATEGORIES = map { $_ => 1 } qw(alpha beta gamma);

=head2 add

=head3 Arguments

=over 4

=item * C<$category>

=back

=cut

sub add {
	my ($self, %args) = @_;
	my $category = $args{category};
	croak "bad category" unless $CATEGORIES{$category};
	return $category;
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is_deeply($schemas->{add}{input}{category}{memberof},
		[qw(alpha beta gamma)],
		'the constant the value is checked against supplies the member list');
};

subtest 'an abstract method is marked DIES' => sub {
	my $src = <<'END_PM';
package AbstractModule;

use Carp qw(croak);

=head2 process

=cut

sub process {
	my ($self, %args) = @_;
	croak(__PACKAGE__, '::process must be implemented by subclass');
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{process}{output}{_STATUS}, 'DIES',
		'a method that must be implemented by a subclass always dies');
};

subtest 'the list-return POD rule needs the POD to say list' => sub {
	my $src = <<'END_PM';
package ListModule;

=head2 names

Returns a list of names.

=cut

sub names {
	my ($self) = @_;
	return @{ $self->{names} };
}

=head2 name_ref

Returns an arrayref of names.

=cut

sub name_ref {
	my ($self) = @_;
	return @{ $self->{names} };
}

1;
END_PM

	my ($pm) = _make_pm($src);
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{names}{output}{type}, 'array',
		'"returns a list" makes the output an array (list context)');
	is($schemas->{name_ref}{output}{type}, 'arrayref',
		'an arrayref return is not turned into a list return');
};

# ==================================================================
# Regression: a matches pattern must stay a data-file string.
#
# The extractor used to compile the pattern and hand the Regexp to the
# YAML writer, which produced a !!perl/regexp object that a YAML
# consumer cannot read back.  Emitter::Perl's package-name check is the
# case that exposed it.
# ==================================================================

subtest 'a matches pattern is written to YAML as a plain string' => sub {
	my $src = <<'END_PM';
package PackageCheck;

use Carp qw(croak);

=head2 new

=head3 Arguments

=over 4

=item * C<$package>

The Perl package name of the module under test.

=back

=cut

sub new {
	my ($class, %args) = @_;
	croak "package '$args{package}' is not a valid Perl package name"
		unless $args{package} =~ /^[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z/;
	return bless { package => $args{package} }, $class;
}

1;
END_PM

	my ($pm, $tmpdir) = _make_pm($src, 'PackageCheck.pm');
	my $out = File::Spec->catdir($tmpdir, 'schemas');
	mkdir $out or die $!;
	my $e = App::Test::Generator::SchemaExtractor->new(
		input_file => $pm,
		output_dir => $out,
	);
	my $schemas = $e->extract_all(no_write => 0);

	my $matches = $schemas->{new}{input}{package}{matches};
	is($matches, '^[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*\z',
		'the in-memory pattern is the plain pattern body');
	ok(!ref($matches), 'the in-memory pattern is not a Regexp object');

	my $yaml = do {
		open my $fh, '<', File::Spec->catfile($out, 'new.yml') or die $!;
		local $/;
		<$fh>;
	};
	unlike($yaml, qr/!!perl\/regexp/, 'no !!perl/regexp tag is written');
	like($yaml, qr/^    matches: \^\[A-Za-z_\]/m,
		'the pattern body is written as a plain YAML string');
};

# ==================================================================
# Regression: a code span naming another parameter must not decide
# optionality.  CoverageGuidedFuzzer::new documents schema as Required,
# but mentions the parameter C<optional> later in the same description;
# the extractor read that as "optional" and the harness then omitted a
# required constructor argument.
# ==================================================================

subtest 'a code span naming optional does not make a required parameter optional' => sub {
	my $src = <<'END_PM';
package OptionalNameModule;

use Carp qw(croak);

=head2 new

Construct a new fuzzer.

=head3 Arguments

=over 4

=item * C<schema>

A hashref representing the parsed schema. Required.  Its keys include
C<$optional> as well as C<$type> and C<$min>.

=item * C<iterations>

Number of iterations to run. Optional - defaults to 100.

=back

=cut

sub new {
	my ($class, %args) = @_;
	croak 'schema required' unless $args{schema};
	return bless { schema => $args{schema}, iterations => $args{iterations} }, $class;
}

1;
END_PM

	my ($pm) = _make_pm($src, 'OptionalNameModule.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{new}{input}{schema}{optional}, 0,
		'Required wins over a code span naming optional');
	is($schemas->{new}{input}{iterations}{optional}, 1,
		'a prose Optional still marks the parameter optional');
};

# ==================================================================
# Regression: a constructor that needs a non-empty arrayref of live
# objects cannot be built from YAML.  Database::Join->new requires one
# or more Database::Abstraction instances and calls columns() on each;
# the extractor used to emit new: { databases: [] }, so the harness
# built an object the constructor refused and every instance method died.
# ==================================================================

subtest 'a constructor needing live objects is unbuildable' => sub {
	my $src = <<'END_PM';
package JoinModule;

use Carp qw(croak);
use Scalar::Util qw(blessed);

=head2 new

Build a join over one or more databases.

=head3 API SPECIFICATION

=head4 Input

    {
        databases   => { type => 'arrayref', required => 1 },
        join_column => { type => 'string', optional => 1 },
    }

=cut

sub new {
	my ($class, %args) = @_;

	croak 'At least one database object is required'
		unless @{ $args{databases} };

	for my $i (0 .. $#{ $args{databases} }) {
		croak 'not a database object'
			unless blessed($args{databases}[$i])
			    && $args{databases}[$i]->can('columns');
	}

	return bless { dbs => $args{databases}, join_column => $args{join_column} }, $class;
}

=head2 count

Return the number of databases.

=cut

sub count {
	my ($self) = @_;
	return scalar @{ $self->{dbs} };
}

1;
END_PM

	my ($pm) = _make_pm($src, 'JoinModule.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{new}{input}{databases}{optional}, 0,
		'required => 1 marks the arrayref required');
	is($schemas->{new}{input}{join_column}{optional}, 1,
		'optional => 1 is still honoured');
	like($schemas->{new}{skip}, qr/non-empty arrayref of live objects/,
		'new itself is reported as skipped, not fuzzed with an impossible value');
	ok(exists($schemas->{count}{new}) && !ref($schemas->{count}{new}),
		'the instance method gets new: ~ instead of an invalid constructor fixture')
		or diag(explain($schemas->{count}{new}));
};

subtest 'required => 1 is read from a bare-list input spec' => sub {
	my $src = <<'END_PM';
package BareSpecModule;

use Carp qw(croak);

=head2 new

=head3 API SPECIFICATION

=head4 Input

    databases   => { type => 'arrayref', required => 1 }
    join_column => { type => 'string', optional => 1 }

=cut

sub new {
	my ($class, %args) = @_;
	croak 'databases is required' unless $args{databases};
	return bless { %args }, $class;
}

1;
END_PM

	my ($pm) = _make_pm($src, 'BareSpecModule.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{new}{input}{databases}{optional}, 0,
		'a required => 1 flag in a bare list is honoured');
};

# ==================================================================
# Regression: a module may declare a small helper package after the
# main one (Database::Join::Catalog's error class).  Extraction used to
# croak with "More than one package declaration found"; it now analyses
# the primary package and ignores routines owned by later packages.
# ==================================================================

subtest 'a multi-package file is analysed as its primary package' => sub {
	my $src = <<'END_PM';
package MultiModule;

use Carp qw(croak);

=head2 answer

Return a number.

=cut

sub answer {
	return 42;
}

package MultiModule::Error;

=head2 new

Build an error object.

=cut

sub new {
	my ($class, %args) = @_;
	return bless { %args }, $class;
}

=head2 message

Return the error message.

=cut

sub message {
	my ($self) = @_;
	return $self->{message};
}

1;
END_PM

	my ($pm) = _make_pm($src, 'MultiModule.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	ok(exists($schemas->{answer}), 'a routine from the primary package is extracted');
	ok(!exists($schemas->{message}), 'a routine from the helper package is ignored');
	ok(!exists($schemas->{new}), 'the helper package constructor is ignored');
	is($schemas->{answer}{module}, 'MultiModule', 'schemas are attributed to the primary package');
	like($schemas->{answer}{skip}, qr/multi-package file/,
		'the file is skipped explicitly rather than aborting extraction');
};

# ==================================================================
# Regression: a required => 1 inside a nested properties map belongs to
# the property, not to the parameter, and an explicit optional => 1 on the
# parameter is never overridden by it.
# ==================================================================

subtest 'a nested required flag does not make its parent required' => sub {
	my $src = <<'END_PM';
package NestedSpec;

=head2 run

=head3 API SPECIFICATION

=head4 input

  {
    opts => { type => 'hashref', optional => 1, properties => { x => { type => 'string', required => 1 } } },
    cfg => { type => 'hashref', properties => { y => { required => 1 } } },
  }

=cut

sub run {
	my ($class, %args) = @_;
	return $args{opts};
}

1;
END_PM

	my ($pm) = _make_pm($src, 'NestedSpec.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);
	my $input = $schemas->{run}{input};

	is($input->{opts}{optional}, 1, 'an explicit optional => 1 is kept');
	ok(!exists($input->{x}) && !exists($input->{y}),
		'nested property names are not promoted to parameters');
};

subtest 'only top-level entries of a bare-list spec are read' => sub {
	my @entries = App::Test::Generator::SchemaExtractor::_top_level_hash_entries(
		"a => { required => 1, properties => { b => { required => 1 } } }\nc => { optional => 1 }"
	);
	is_deeply([ map { $_->[0] } @entries ], [ 'a', 'c' ], 'nested names are skipped');
	is(App::Test::Generator::SchemaExtractor::_spec_optionality($entries[0][1]), 0,
		'the top-level required flag is read');
	is(App::Test::Generator::SchemaExtractor::_spec_optionality(
		"type => 'string', optional => 1, required => 1"), 1,
		'an explicit optional wins over required');
	is(App::Test::Generator::SchemaExtractor::_spec_optionality(
		"type => 'hashref', properties => { x => { required => 1 "), undef,
		'a truncated nested required flag is ignored');
};

subtest 'a field whose name only starts with the parameter is not matched' => sub {
	my $body = <<'END_BODY';
sub new {
	my ($class, %args) = @_;
	my $self = bless { %args }, $class;
	$self->{databases_count}[0]->foo;
	return $self;
}
END_BODY
	my $schema = { input => { databases => { type => 'arrayref', optional => 0 } } };
	ok(!App::Test::Generator::SchemaExtractor::_constructor_requires_live_objects($body, $schema),
		'$self->{databases_count} is not $self->{databases}');
	$body =~ s/databases_count/databases/;
	like(App::Test::Generator::SchemaExtractor::_constructor_requires_live_objects($body, $schema),
		qr/live objects in 'databases'/, 'the exact field is still matched');
};

done_testing();

