#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;
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

done_testing();
