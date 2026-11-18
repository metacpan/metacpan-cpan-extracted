#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/regex_generation.t - pattern-based string generation is deterministic,
# bounded, and reports what it could not do.
#
# * a schema seed reproduces the same harness output run to run;
# * failures name the seed and the input so a run can be replayed;
# * a regex generator that hangs is bounded by config 'regex_timeout' and
#   falls back to a fixed matching value;
# * a pattern that cannot be satisfied is reported and the case skipped
#   instead of hanging or failing the run.
# ======================================================================

use Test::Most;
use Config;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Run3 qw(run3);
use Time::HiRes qw(time);
use App::Test::Generator;

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->catdir($dir, 'lib');
make_path(File::Spec->catdir($lib, 'Regex'));

my $module = File::Spec->catfile($lib, 'Regex', 'Target.pm');
open(my $fh, '>', $module) or die "cannot write $module: $!";
print {$fh} <<'MODULE';
package Regex::Target;
use strict;
use warnings;

sub slug
{
	my ($slug) = @_;

	die 'slug must be 3-6 lowercase letters'
		unless defined($slug) && !ref($slug) && ($slug =~ /^[a-z]{3,6}$/);
	return uc($slug);
}

sub abc
{
	my ($value) = @_;

	die 'value must be abc'
		unless defined($value) && !ref($value) && ($value eq 'abc');
	return $value;
}

sub anything
{
	my ($value) = @_;

	return defined($value) ? "$value" : '';
}

sub minimum
{
	my ($text) = @_;

	return defined($text) ? uc($text) : '';
}
1;
MODULE
close($fh) or die "cannot close $module: $!";

# A regex generator that is deliberately slow, to exercise the timeout.
my $fake = File::Spec->catdir($dir, 'fake');
make_path(File::Spec->catdir($fake, 'Data', 'Random', 'String'));
my $fake_module = File::Spec->catfile($fake, 'Data', 'Random', 'String', 'Matches.pm');
open(my $fake_fh, '>', $fake_module) or die "cannot write $fake_module: $!";
print {$fake_fh} <<'FAKE';
package Data::Random::String::Matches;
use strict;
use warnings;
use Time::HiRes ();

our $VERSION = '0.04';

sub create_random_string
{
	# Too slow to be useful: the harness must time this out and fall back.
	Time::HiRes::sleep(5);
	return 'zzz';
}
1;
FAKE
close($fake_fh) or die "cannot close $fake_module: $!";

sub _config
{
	return {
		test_empty     => 0,
		test_nuls      => 0,
		test_non_ascii => 0,
		test_security  => 0,
		test_undef     => 0,
	};
}

sub _generate
{
	my ($name, $function, $input, %extra) = @_;

	my $file = File::Spec->catfile($dir, "$name.t");
	my %config = (%{_config()}, %{$extra{config} || {}});

	lives_ok {
		App::Test::Generator->generate(
			schema => {
				module   => 'Regex::Target',
				function => $function,
				input    => $input,
				output   => { type => 'string' },
				config   => \%config,
				(defined($extra{seed}) ? (seed => $extra{seed}) : ()),
			},
			output_file => $file,
			quiet       => 1,
		);
	} "$name: generate() accepts the schema";

	ok(-f $file, "$name: the harness was written");
	return $file;
}

sub _run
{
	my ($file, $perl5lib) = @_;

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join($Config{path_sep}, grep { defined($_) && length($_) }
		($perl5lib, $lib, $ENV{PERL5LIB}));
	run3([$^X, $file], \undef, \$stdout, \$stderr);

	return ($? >> 8, "$stdout$stderr");
}

subtest 'a seed makes pattern generation reproducible' => sub {
	my $file = _generate(
		'regex_seeded', 'slug',
		{
			slug => {
				type     => 'string',
				optional => 0,
				position => 0,
				matches  => qr/^[a-z]{3,6}$/,
			},
		},
		seed => 42
	);

	my ($exit1, $first) = _run($file);
	my ($exit2, $second) = _run($file);

	is($exit1, 0, 'the first run passes') or diag($first);
	is($exit2, 0, 'the second run passes') or diag($second);
	is($first, $second, 'the same seed produces the same output');

	open(my $harness_fh, '<', $file) or die "cannot read $file: $!";
	my $harness = do { local $/; <$harness_fh> };
	close($harness_fh);
	like($harness, qr/srand\(\$seed = 42\)/, 'the harness seeds Perl\'s RNG from the schema');
};

subtest 'a failure names the seed and the input' => sub {
	my $file = _generate(
		'regex_failure_context', 'minimum',
		{
			text => {
				type     => 'string',
				optional => 0,
				position => 0,
				min      => 5,
			},
		},
		seed => 42
	);

	my ($exit, $output) = _run($file);

	isnt($exit, 0, 'a routine that ignores a declared minimum fails');
	like($output, qr/seed = 42/, 'the failure names the seed to replay');
	like($output, qr/input = /, 'the failure names the input that was sent');
};

subtest 'a hanging regex generator is bounded and falls back' => sub {
	my $file = _generate(
		'regex_timeout', 'abc',
		{
			value => {
				type     => 'string',
				optional => 0,
				position => 0,
				matches  => qr/^abc$/,
			},
		},
		config => { regex_timeout => 1 }
	);

	my $started = time();
	my ($exit, $output) = _run($file, $fake);
	my $elapsed = time() - $started;

	is($exit, 0, 'the run passes when generation falls back') or diag($output);
	like($output, qr/regex generation for .+ fell back to a fixed string/,
		'the fallback is reported');
	cmp_ok($elapsed, '<', 4, "the timeout bound the generator (took ${elapsed}s)");
};

subtest 'an unsatisfiable pattern is reported, not fatal' => sub {
	my $file = _generate(
		'regex_unsatisfiable', 'anything',
		{
			value => {
				type     => 'string',
				optional => 0,
				position => 0,
				matches  => '(?!)',
				_source  => 'pod',
			},
		},
		seed => 7
	);

	my ($exit, $output) = _run($file);

	is($exit, 0, 'an impossible documented pattern does not fail the run') or diag($output);
	like($output, qr/cannot generate a string matching/,
		'the pattern is reported as unusable');
	like($output, qr/seed 7/, 'the advisory report names the seed');
};

done_testing();
