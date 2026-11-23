#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird;
use App::Test::Generator ();
use App::Test::Generator::Provenance qw(source_is_valid);
use File::Temp qw(tempdir);
use File::Spec;
use YAML::XS qw(LoadFile);

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

# ==================================================================
# Regression: an Input section written as a table -- one `name : type`
# or `$name SCALAR` line per parameter -- states each type, its bounds
# and the invocant, and the extractor must use them instead of guessing
# from the code (Database::BI documents every routine this way).
# ==================================================================

subtest 'a documented input table supplies types, bounds and the invocant' => sub {
	my $src = <<'END_PM';
package TableSpec;

=head2 point_key

=head3 API SPECIFICATION

=head4 INPUT

  lat : number  -90 .. 90
  lon : number  -180 .. 180
  level : string  optional, default 'county'

=head4 OUTPUT

    SCALAR   the key

=cut

sub point_key {
	my ($class, $lat, $lon) = @_;
	return;
}

=head2 json_lists

=head3 API SPECIFICATION

=head4 INPUT

    $class   SCALAR   the class (called as a class method)
    $path    SCALAR   a readable .json file

=head4 OUTPUT

    ARRAYREF of HASHREF

=cut

sub json_lists {
	my ($class, $path) = @_;
	my ($text, $data) = _json_read($path);
	return [];
}

sub _json_read {
	my ($path) = @_;
	open(my $fh, '<', $path) or return '';
	local $/;
	return <$fh>;
}

1;
END_PM

	my ($pm) = _make_pm($src, 'TableSpec.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	my $point = $schemas->{point_key}{input};
	is($point->{lat}{type}, 'number', 'a column table gives the documented type');
	is($point->{lat}{min}, -90, 'the documented lower bound is kept');
	is($point->{lat}{max}, 90, 'the documented upper bound is kept');
	is($point->{lat}{_source}, 'input_spec', 'the type is marked as documented');
	is($point->{level}{optional}, 1, "an entry with a default is optional");
	ok(!exists($schemas->{point_key}{invocant}), 'a positional routine is not a class method');

	my $json = $schemas->{json_lists};
	is($json->{input}{path}{type}, 'string', 'a SCALAR path stays a string');
	ok(!exists($json->{input}{path}{isa}),
		'a call such as _json_read($path) does not make its argument a filehandle');
	is($json->{input}{path}{semantic}, 'existing_file',
		'a readable file is a precondition the harness supplies');
	ok(!exists($json->{input}{class}), 'the documented $class is not a parameter');
	is($json->{invocant}, 'class', 'a documented $class makes the routine a class method');
};

subtest 'a helper block after the subs, method holders and variable regexes' => sub {
	my $src = <<'END_PM';
package LaterModule;

my $EXT_RE = qr/\.json\z/i;

sub helper_date {
	my ($val, $pattern) = @_;
	return undef unless defined $val && defined $pattern;
	return undef if ref $pattern;
	return '2026-01-15';
}

sub keep_ext {
	my ($path) = @_;
	return 0 unless defined $path;
	return 1 if $path =~ $EXT_RE;
	return 0;
}

sub refresh {
	my ($cache) = @_;
	return $cache->get('key');
}

sub keeper {
	my ($blob) = @_;
	die 'blob is required' unless defined $blob && length $blob;
	return $blob;
}

=head2 Date handling (standalone helpers)

    helper_date($value, $pattern) -> ISO string or undef

Returns undef when the value does not match the pattern.

=head3 API SPECIFICATION

=head4 INPUT

	$value     # string
	$pattern   # one of the accepted date patterns

=head4 OUTPUT

	'string' | undef

=cut

1;
END_PM

	my ($pm) = _make_pm($src, 'LaterModule.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	my $date = $schemas->{helper_date}{input};
	is($date->{value}{type}, 'string', 'a later block documenting the routine is read');
	is($date->{value}{_source}, 'input_spec', 'the table marks the argument as documented');
	is($date->{value}{position}, 0, 'the table gives the first argument its position');
	is($date->{pattern}{position}, 1, 'the table keeps the argument order');
	is($date->{pattern}{type}, 'string', 'an unrecognised description still names a string');
	ok(!exists($date->{val}),
		'the code variable for a documented positional slot is not a second argument');

	my $keep = $schemas->{keep_ext}{input}{path};
	ok(!exists($keep->{matches}),
		'a pattern held in a variable is not recorded as the regex');

	my $refresh = $schemas->{refresh}{input}{cache};
	is($refresh->{type}, 'object', 'an argument called as a method holder is an object');
	is($refresh->{optional}, 0, 'a method call on it cannot be omitted');

	my $keeper = $schemas->{keeper}{input}{blob};
	is($keeper->{_not_empty}, 1, 'an argument the code refuses when empty is marked so');
	is($keeper->{optional}, 0, 'and it is required');
};

subtest 'a constructor with live dependencies, and the preconditions the POD states' => sub {
	my $src = <<'END_PM';
package Stateful;

use Params::Get ();
use Params::Validate::Strict qw(validate_strict);

sub new {
	my $class = shift;
	my $args = validate_strict(
		schema => {
			cache => { type => 'object', optional => 1, default => undef },
			level => { type => 'string', optional => 1, default => 'county' },
		},
		input => Params::Get::get_params(undef, \@_),
	);
	my $self = bless { %{$args} }, $class;
	$self->{'_level'} = $args->{'level'};
	return $self;
}

sub level_of {
	my ($self, $country) = @_;
	return $self->{'_level'};
}

=head2 ranks

  ranks : hashref of { country code => place rank }

Croaks on a key that is not a two-letter code.

=cut

sub ranks {
	my (undef, $ranks) = @_;
	my %checked = %{$ranks};
	return \%checked;
}

=head2 numeric_text

Returns the text when it holds a digit, else undef.

=cut

sub numeric_text {
	my ($text) = @_;
	return undef unless defined $text;
	return $text =~ /[0-9%]/ ? $text : undef;
}

=head2 cache_dir_for

=head4 INPUT

    $model_dir => string, required; an existing directory

=cut

sub cache_dir_for {
	my (undef, $model_dir) = @_;
	croak 'not a directory' unless -d $model_dir;
	return 1;
}

=head2 connect

=head4 INPUT

    $server    SCALAR string     the name of the server, for messages
    $settings  HASHREF           { database, host?, username?, password? }

=cut

sub connect {
	my ($class, $server, $settings) = @_;
	return 1;
}

=head2 report

=head4 INPUT

    \%models  => hashref, required;  the existing model store
    \@columns arrayref of names      # required; one or more
    $suffix   => string, optional;   added at the end

=cut

sub report {
	my ($models, $columns, $suffix) = @_;
	return \%models;
}

1;
END_PM

	my ($pm) = _make_pm($src, 'Stateful.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	is($schemas->{new}{input}{cache}{type}, 'object',
		'the validator gives the constructor its object parameter');
	ok(!exists($schemas->{new}{accessor}),
		'a constructor that stores one field is not read as an accessor');
	like($schemas->{new}{skip} // '', qr/live 'cache' object/,
		'a constructor needing an unmockable object is reported as skipped');
	is($schemas->{level_of}{new}, 'Stateful',
		'its instance methods are left unbuildable rather than failed');

	like($schemas->{ranks}{skip} // '', qr/hashref in the shape/,
		'a hashref whose POD states its shape is a precondition');
	is($schemas->{ranks}{output}{type}, 'hashref',
		'a return of \\%hash is typed as a hashref');

	is($schemas->{numeric_text}{output}{type}, 'string',
		'a / and a % inside a regex literal are not read as arithmetic');
	unlike($schemas->{numeric_text}{input}{text}{type} // '', qr/number/,
		'and the argument is not typed from them either');

	is($schemas->{cache_dir_for}{input}{model_dir}{semantic}, 'directory',
		'an existing directory in the POD is marked for a temporary one');
	is($schemas->{cache_dir_for}{input}{model_dir}{optional}, 0,
		'and the row keeps its required status');

	like($schemas->{connect}{skip} // '', qr/live database/,
		'settings naming a database and password need a live server');

	is($schemas->{report}{input}{models}{type}, 'hashref',
		'a \\%name => hashref row is read from the POD table');
	is($schemas->{report}{input}{models}{optional}, 0, 'and its required status');
	is($schemas->{report}{input}{columns}{type}, 'arrayref',
		'a \\@name arrayref row is read too');
	is($schemas->{report}{input}{columns}{min}, 1,
		'"one or more" is a size floor');
	is($schemas->{report}{input}{suffix}{optional}, 1,
		'a $name => string, optional row stays optional');
};

subtest 'a trailing POD block, and text that looks like an operator' => sub {
	# The subs come first and the POD block after them, as Database::BI::Extract
	# writes its file: the section headed with the routine's name documents it.
	my $src = <<'END_PM';
package Trailing;

use Carp qw(croak);

sub put {
	my ($self, $spec, $mtime, $size, $bytes) = @_;
	croak 'sqlite_bytes are required' unless defined $bytes && length $bytes;
	return $self->{'dir'} . '/' . $spec;
}

sub note {
	my $key = shift;
	my %notes = (
		pop_delta => 'Period-over-period change in the sum',
		top_mover => 'Largest period-over-period change',
	);
	return $notes{$key} // $key;
}

sub stamp {
	my ($epoch) = @_;
	my @tm = gmtime(defined $epoch ? $epoch : time);
	return sprintf '%04d-%02d-%02dT%02d:%02d:%02dZ', $tm[5] + 1900, $tm[4] + 1, $tm[3], $tm[2], $tm[1], $tm[0];
}

sub spec_key {
	my ($spec) = @_;
	return $spec unless defined $spec && $spec =~ m{\Apath:(?!/\.\./)([^\n]+)\z};
	return $spec unless -e $1;
	return "path:$1";
}

sub new {
	my ($class, %args) = @_;
	return bless { dir => $args{'model_dir'} }, $class;
}

=head2 new

=head4 INPUT

	model_dir => 'string',   # the folder the extracts live under

=cut

=head2 put

=head4 INPUT

	$spec, $mtime, $size   # as for path
	$bytes                 # required; the SQLite file's contents

=cut

1;
END_PM

	my ($pm) = _make_pm($src, 'Trailing.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	my $put = $schemas->{put};
	is($put->{input}{spec}{_source}, 'input_spec',
		'a section headed with the routine name documents it after the subs');
	is($put->{input}{spec}{position}, 0, 'a row naming several parameters gives each a position');
	is($put->{input}{mtime}{position}, 1, 'in call order');
	is($put->{input}{size}{position}, 2, 'and all of them');
	is($put->{input}{bytes}{semantic}, 'bytes',
		"the SQLite file's contents is a byte string");

	is($schemas->{note}{input}{key}{type}, 'string',
		'a hyphen in a string literal does not make the argument a number');
	is($schemas->{note}{input}{key}{type}, 'string',
		'and // is a defined-or, not a division');
	is($schemas->{stamp}{output}{type}, 'string',
		'sprintf returns text, whatever its arguments add up to');
	is($schemas->{spec_key}{output}{type}, 'string',
		'-e is a file test, not a subtraction');

	is(ref($put->{new}), 'HASH', 'the constructor can be built for an instance method');
	is($put->{new}{model_dir}{_path}, 'directory',
		'its directory argument is marked for a temporary directory');
	like(App::Test::Generator::render_args_hash($put->{new}), qr/File::Temp::tempdir/,
		'which the generated test makes at run time');
};

subtest 'localtime and gmtime returns are a list of numbers' => sub {
	my $src = <<'END_PM';
package ZoneWall;

our $ZONE;

=head2 zone_wall($epoch)

Returns the wall clock as localtime does.

=cut

sub zone_wall {
	my ($epoch) = @_;
	return ($ZONE && $ZONE->{kind} eq 'fixed')
		? gmtime($epoch + $ZONE->{offset})
		: localtime($epoch);
}

=head2 clock($epoch)

Returns one field of the wall clock.

=cut

sub clock {
	my ($epoch) = @_;
	return scalar localtime($epoch);
}

1;
END_PM

	my ($pm) = _make_pm($src, 'ZoneWall.pm');
	my $schemas = App::Test::Generator::SchemaExtractor->new(input_file => $pm)->extract_all(no_write => 1);

	is($schemas->{zone_wall}{output}{type}, 'array',
		'a localtime/gmtime return is the nine-element time list');
	is($schemas->{zone_wall}{output}{element_type}, 'number',
		'whose elements are numbers');
	is($schemas->{zone_wall}{input}{epoch}{type}, 'number',
		'the epoch argument stays a number');
	isnt($schemas->{clock}{output}{type}, 'array',
		'a scalar localtime stays a single value');
};

subtest 'defined-or and arrows are not arithmetic, and table rows keep their routine' => sub {
	my $src = <<'END_PM';
package OutTypes;

sub count_or_default {
	my ($self, $row) = @_;
	return $self->{'count'} // 0;
}

sub label_or_default {
	my ($row) = @_;
	return $row->{'label'} // 'none';
}

sub tally {
	my ($self, $row) = @_;
	return $self->{'n'} - 1;
}

sub compile_pattern {
	my ($pattern) = @_;
	return qr/$pattern/;
}

=head2 Pattern helpers

=head4 INPUT

    compile_pattern: $pattern   # string, the pattern to compile
    other_helper: $extra        # string, the text to measure

=cut

sub other_helper {
	my ($extra) = @_;
	return length $extra;
}

1;
END_PM

	my ($pm) = _make_pm($src, 'OutTypes.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	# A defined-or is not a division: `$x // 0` returns $x, not a number.
	unlike($schemas->{count_or_default}{output}{type} // '', qr/^(?:number|integer)$/,
		'`// 0` does not type a method-call return as a number');
	unlike($schemas->{label_or_default}{output}{type} // '', qr/^(?:number|integer)$/,
		'nor a hash element return');
	# The rule must not hide arithmetic that is there.
	is($schemas->{tally}{output}{type}, 'number',
		'but a subtraction is still arithmetic');

	# One POD block documents several helpers, each row prefixed with the
	# routine it belongs to: a routine reads its own row and no other.
	is($schemas->{other_helper}{input}{extra}{_source}, 'input_spec',
		"a row prefixed with the routine's name documents its own parameter");
	ok(!exists($schemas->{other_helper}{input}{pattern}),
		"another routine's row is not other_helper's parameter");
	is($schemas->{compile_pattern}{input}{pattern}{_source}, 'code',
		'the routine above the block is documented by its code, not the table');
	ok(!exists($schemas->{compile_pattern}{input}{extra}),
		"and does not borrow the table's rows");
};

	subtest 'an Input section written as a Perl hash documents its outer keys' => sub {
		my $src = <<'END_PM';
package HashInput;

=head2 plan_thing

=head3 API specification

=head4 input

    {
        self     => { type => OBJECT,  isa  => 'HashInput' },
        schema   => { type => HASHREF, optional => 1 },
        strategy => { type => HASHREF, optional => 0 },
    }

Valid and invalid input, by partition:

=over 4

=item Argument count

Valid: 0 or 1.  Invalid: 2 or more.

=back

=cut

sub plan_thing {
	my ($self, $schema, $strategy) = @_;
	die 'strategy must be a hashref' unless ref($strategy) eq 'HASH';
	return {};
}

1;
END_PM

		my ($pm) = _make_pm($src, 'HashInput.pm');
		my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
		my $schemas = $e->extract_all(no_write => 1);
		my $input = $schemas->{plan_thing}{input};

		is_deeply([ sort keys %{$input} ], [ qw(schema strategy) ],
			'only the hash\'s outer keys are parameters');
		is($input->{schema}{type}, 'hashref', 'an inner type word types the parameter');
		ok($input->{schema}{optional}, 'and its optional flag is read');
		ok(!$input->{strategy}{optional}, 'including an explicit optional => 0');
		ok(!exists($input->{Valid}) && !exists($input->{type}),
			'prose and inner keys are not parameters');
	};

subtest 'a documented stand-in for a constructor argument, and argument shapes' => sub {
	my $src = <<'END_PM';
package Joinish;

use Carp qw(carp croak);
use Params::Get ();
use Params::Validate::Strict qw(validate_strict);

sub new {
	my ($class, @args) = @_;
	my $args = validate_strict(
		schema => {
			databases         => { type => 'arrayref', required => 1 },
			join_column       => { type => 'string', optional => 1, default => 'entry' },
			filters           => { type => 'hashref', optional => 1 },
			mandatory_filters => { type => 'arrayref', optional => 1 },
		},
		input => Params::Get::get_params(undef, @args),
	);
	croak 'databases is required' unless @{ $args->{databases} };
	my $cols = $args->{databases}[0]->columns();
	croak 'join_column is absent' unless grep { $_ eq $args->{join_column} } @{$cols};
	return bless { %{$args} }, $class;
}

sub rows {
	my $self = shift;
	return $self->{_rows} // [];
}

=head2 aggregate

=head4 Input

    measures : arrayref, required; one or more
    by       : arrayref, optional

=cut

sub aggregate {
	my ($self, @args) = @_;
	my $p = Params::Get::get_params(undef, @args) // {};
	croak 'measures is required' unless ref($p->{measures}) eq 'ARRAY';
	return [];
}

=head2 selectall_arrayref

=head4 Output

    Arrayref of hashrefs, one per row

=cut

sub selectall_arrayref {
	my ($self, @args) = @_;
	return [];
}

=head2 selectall_hashref

Deprecated alias of selectall_arrayref.

=cut

sub selectall_hashref {
	my $self = shift;
	carp 'selectall_hashref is deprecated';
	return $self->selectall_arrayref(@_);
}

=head2 new

=head4 Input

    databases         => { type => 'arrayref', required => 1 }
                        # One or more subclass of C<Database::Abstraction> objects.

    join_column       => { type => 'string', optional => 1, default => 'entry' }
                        # The column shared by every database.

    filters           => { type => 'hashref', optional => 1 }
                        # Zero-based database index => criteria hashref.

    mandatory_filters => { type => 'arrayref', optional => 1 }
                        # Arrayref of {col, op, val} predicate hashrefs.
                        # Each predicate must supply:
                        #   col -- a column name present in the merged view
                        #   op  -- one of: eq, ne, lt, lte, gt, gte, like, contains
                        #   val -- the comparison value (plain scalar)

=cut

1;
END_PM

	my ($pm) = _make_pm($src, 'Joinish.pm');
	my $e = App::Test::Generator::SchemaExtractor->new(input_file => $pm);
	my $schemas = $e->extract_all(no_write => 1);

	ok(!$schemas->{new}{skip}, 'the constructor builds with a documented stand-in');
	my $stub = $schemas->{new}{input}{databases}{_stub_elements};
	is($stub->{isa}, 'Database::Abstraction', 'the stub is the class the POD names');
	is_deeply($stub->{methods}{columns}, [ 'entry' ],
		'and publishes the documented join column');
	is($schemas->{new}{input}{databases}{min}, 1, 'the constructor needs at least one');
	is_deeply($schemas->{new}{input}{join_column}{memberof}, [ 'entry' ],
		'the join column is the one the stub advertises, as a fixture');
	is($schemas->{new}{input}{join_column}{_constraint_source}{memberof}, 'fixture',
		'so a value outside it is not called a documented error');
	is($schemas->{new}{input}{filters}{schema}{type}, 'hashref',
		'a hashref documented as index => criteria hashref holds hashrefs');
	is_deeply($schemas->{new}{input}{mandatory_filters}{schema}{op}{memberof},
		[ qw(eq ne lt lte gt gte like contains) ],
		'an arrayref of fixed-key hashrefs gets the documented element shape');
	is($schemas->{new}{input}{mandatory_filters}{schema}{col}{memberof}[0], 'entry',
		'and its column is one the stand-in publishes');

	ok(!exists($schemas->{aggregate}{input}{measures}{position}),
		'a routine taking @args gets its documented names, not call positions');
	is(ref($schemas->{rows}{new}), 'HASH', 'the instance methods build from the stand-in');
	is(ref($schemas->{rows}{new}{databases}[0]{_stub}), 'HASH',
		'and their constructor argument carries it');

	is($schemas->{selectall_hashref}{output}{type}, 'arrayref',
		'a deprecated forwarding alias returns what it forwards to');
};

subtest 'types quoted in an Input hash dump' => sub {
	my $src = <<'END_PM';
package Quoted;

use strict;
use warnings;

=head2 build

=head4 Input

	{
	    insights => 'arrayref',  # optional; insight hashrefs
	    spec_key => 'string',    # optional; bookkeeping only
	    row_count => 'integer',  # optional; rows analysed (default 0)
	    use_ai   => 'boolean',   # optional; ask for prose
	    config   => 'hashref',   # optional; settings
	    allowed  => 'coderef',   # optional; asked before each call
	}

=cut

sub build {
	my (%args) = @_;
	return { ok => 1 };
}

1;
END_PM

	my ($pm) = _make_pm($src, 'Quoted.pm');
	my $schemas = App::Test::Generator::SchemaExtractor->new(input_file => $pm)->extract_all(no_write => 1);
	my $input = $schemas->{build}{input};

	is($input->{insights}{type}, 'arrayref', 'a quoted hash-dump value types its parameter');
	is($input->{spec_key}{type}, 'string', 'the other rows keep their quoted types');
	is($input->{row_count}{type}, 'integer', 'an integer row is an integer');
	is($input->{use_ai}{type}, 'boolean', 'a boolean row is a boolean');
	is($input->{config}{type}, 'hashref', 'a hashref row is a hashref');
	is($input->{allowed}{type}, 'coderef', 'a coderef row is a coderef');
	ok($input->{insights}{optional}, 'the comment still marks the row optional');
};

subtest 'an arrayref documented as insight hashrefs holds hashes' => sub {
	my $src = <<'END_PM';
package Mixed;

use strict;
use warnings;

=head2 build

=head4 Input

	{
	    password => 'string',   # required; not empty
	    rounds   => 'integer',  # optional, 10_000 to 100_000_000
	    insights => 'arrayref', # optional; insight hashrefs
	}

=cut

sub build {
	my ($password, %opts) = @_;
	return { password => $password };
}

1;
END_PM

	my ($pm) = _make_pm($src, 'Mixed.pm');
	my $schemas = App::Test::Generator::SchemaExtractor->new(input_file => $pm)->extract_all(no_write => 1);
	my $input = $schemas->{build}{input};

	is($input->{insights}{type}, 'arrayref', 'the quoted type still types the parameter');
	is($input->{insights}{schema}{type}, 'hashref',
		'an arrayref documented as insight hashrefs holds hashes');
};

subtest 'a documented output shape led by an adverb and an article' => sub {
	my $src = <<'END_PM';
package Shape;

use strict;
use warnings;

=head2 rows

=head4 Output

Always an arrayref of hashrefs (never C<undef>).

=cut

sub rows {
	my $self = shift;
	return [];
}

1;
END_PM

	my ($pm) = _make_pm($src, 'Shape.pm');
	my $schemas = App::Test::Generator::SchemaExtractor->new(input_file => $pm)->extract_all(no_write => 1);

	is($schemas->{rows}{output}{type}, 'arrayref',
		'"Always an arrayref of hashrefs" documents an arrayref return');
};

subtest 'a guarded undef return does not type the success value' => sub {
	my $src = <<'END_PM';
package Guarded;

use strict;
use warnings;

sub span {
	my ($interval) = @_;
	return undef unless defined $interval && length $interval;
	my $n = 1;
	return undef if $n < 1;
	return { n => $n, unit => 'm' };
}

1;
END_PM

	my ($pm) = _make_pm($src, 'Guarded.pm');
	my $schemas = App::Test::Generator::SchemaExtractor->new(input_file => $pm)->extract_all(no_write => 1);
	my $output = $schemas->{span}{output};

	is($output->{type}, 'hashref', 'the record the routine returns on success is its type');
	is($output->{_error_return}, 'undef', 'and the guards are the documented error return');
};

subtest 'only a documented cache handle turns the fd check off' => sub {
	my $src = <<'END_PM';
package Cacheish;

use strict;
use warnings;

=head2 dbi_source

Return the handle of the cache file so a parent can attach it.

=head3 API SPECIFICATION

=head4 Output

    { dbh => $dbh, table => '_result' }

=cut

sub dbi_source {
	my ($self) = @_;
	return { dbh => $self->{_sqlite_cache}{dbh}, table => '_result' };
}

=head2 count

Count the rows of the cached join tables.

=head3 API SPECIFICATION

=head4 Output

    { type => 'integer' }

=cut

sub count {
	my ($self, @args) = @_;
	return $self->_sqlite_join({}, count_only => 1);
}

=head2 add_database

Add a source to the join.

=head3 API SPECIFICATION

=head4 Output

    { type => 'object' }

=cut

sub add_database {
	my ($self, $db) = @_;
	if(my $old = delete $self->{_sqlite_cache}) {
		eval { $old->{dbh}->disconnect } if $old->{dbh};
	}
	$self->{_db_cols} = undef;
	return $self;
}

1;
END_PM

	my ($pm, $tmpdir) = _make_pm($src, 'Cacheish.pm');
	my $out = File::Spec->catdir($tmpdir, 'out');
	App::Test::Generator::SchemaExtractor->new(input_file => $pm, output_dir => $out)->extract_all();

	my $dbi_source = LoadFile(File::Spec->catfile($out, 'dbi_source.yml'));
	is($dbi_source->{config}{check_fds}, 0,
		'a returned handle that the POD documents as dbh turns the fd check off');

	my $count = LoadFile(File::Spec->catfile($out, 'count.yml'));
	is($count->{config}{check_fds}, 0,
		'a query against the documented cache keeps the handle it builds');

	my $add_database = LoadFile(File::Spec->catfile($out, 'add_database.yml'));
	ok(!exists($add_database->{config}{check_fds}),
		'invalidating the cache holds nothing, so its calls stay checked');
};

subtest 'a positional argument followed by named options is a mixed call' => sub {
	my $src = <<'END_PM';
package MixedSig;

use strict;
use warnings;

=head2 hash_it

=head3 API SPECIFICATION

=head4 INPUT

    $password: string, required, not empty
    rounds:    integer, optional, 10_000 to 100_000_000 (default 200_000).
               Domains: 10_000, 10_001, 99_999_999 and 100_000_000 are accepted.

=head4 OUTPUT

    { type => 'string' }

=cut

sub hash_it {
	my ($password, %opts) = @_;
	die 'password required' unless defined($password) && !ref($password) && length($password);
	my $rounds = $opts{rounds} // 200_000;
	die 'rounds out of range' unless $rounds >= 10_000 && $rounds <= 100_000_000;
	return "$password/$rounds";
}

1;
END_PM

	my ($pm) = _make_pm($src, 'MixedSig.pm');
	my $schemas = App::Test::Generator::SchemaExtractor->new(input_file => $pm)->extract_all(no_write => 1);
	my $input = $schemas->{hash_it}{input};

	is($input->{password}{position}, 0, 'the leading scalar keeps position 0');
	is($input->{password}{named} // 0, 0, 'and is not a named option');
	ok(!exists($input->{rounds}{position}), 'the option after the slurpy has no position');
	is($input->{rounds}{named}, 1, 'it is passed by name after the positional arguments');
	is($input->{rounds}{min}, 10_000, 'a range written with words is a documented minimum');
	is($input->{rounds}{max}, 100_000_000, 'and a documented maximum');
	is($input->{rounds}{default}, 200_000, 'the documented default is recorded');
	is($input->{rounds}{sample_max}, 200_000,
		'the default caps the data generated for a work factor');
};

subtest 'a bounded numeric option is generated across its whole range' => sub {
	my $src = <<'END_PM';
package Ported;

use strict;
use warnings;

=head2 listen

=head3 API SPECIFICATION

=head4 INPUT

    port: integer, optional, 1 to 65535 (default 8080)

=head4 OUTPUT

    { type => 'string' }

=cut

sub listen {
	my (%opts) = @_;
	my $port = $opts{port} // 8080;
	die 'port out of range' unless $port >= 1 && $port <= 65535;
	return "listening on $port";
}

1;
END_PM

	my ($pm) = _make_pm($src, 'Ported.pm');
	my $schemas = App::Test::Generator::SchemaExtractor->new(input_file => $pm)->extract_all(no_write => 1);
	my $input = $schemas->{listen}{input};

	is($input->{port}{max}, 65_535, 'the documented maximum is kept');
	is($input->{port}{default}, 8080, 'the documented default is recorded');
	ok(!exists($input->{port}{sample_max}),
		'the default does not cap an option whose maximum is close to it');
};

subtest 'an example signature in a comment is not a parameter' => sub {
	my $src = <<'END_PM';
package Commented;

use strict;
use warnings;

=head2 collect

Collect the options.

=cut

sub collect {
	my $self = shift;
	my $params = Params::Get::get_params(undef, @_) || {};

	# The comment below used to be read as this routine's signature:
	# my ($password, %opts) = @_;
	return $params;
}

1;
END_PM

	my ($pm) = _make_pm($src, 'Commented.pm');
	my $schemas = eval {
		App::Test::Generator::SchemaExtractor->new(
			input_file => $pm,
			strict_pod => 'fatal',
		)->extract_all(no_write => 1);
	};
	is($@, '', 'the comment does not cause a strict-POD disagreement');
	ok($schemas, 'schemas extracted');
	my $input = $schemas->{collect}{input};
	ok(!exists $input->{password}, 'a name only in the comment is not a parameter');
	ok(!exists $input->{opts}, 'the slurpy in the comment is not a parameter');
};

done_testing();

