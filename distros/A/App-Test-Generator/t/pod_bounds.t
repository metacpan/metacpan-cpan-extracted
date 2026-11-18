#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# t/pod_bounds.t - a size bound that only the documentation states is a
# hint for valid data, not a promise the routine has to keep.
#
# Lingua::EN::NameCase documents names => { type => 'arrayref', min => 1 }
# while its ARGS section and code accept an empty array.  A POD string
# minimum has the same problem.  The harness must not fail such a routine,
# it must say that it tolerated the bound, and it must keep failing an
# ordinary schema that says a bound is enforced.
#
# Fixtures are written here so the two behaviours stay distinguishable.
# ======================================================================

use Test::Most;
use Config;
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use IPC::Run3;
use YAML::XS qw(LoadFile DumpFile);

my $lib = abs_path(File::Spec->catdir($Bin, File::Spec->updir(), 'lib'));
my $script = abs_path(File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'extract-schemas'));
my $generator = abs_path(File::Spec->catfile($Bin, File::Spec->updir(), 'bin', 'fuzz-harness-generator'));

ok(-f $script, 'extract-schemas is where the test expects it') or BAIL_OUT('cannot find extract-schemas');
ok(-f $generator, 'fuzz-harness-generator is where the test expects it') or BAIL_OUT('cannot find fuzz-harness-generator');

my $dir = File::Temp::tempdir(CLEANUP => 1);
my %module_file;

sub _spec_block
{
	my ($line) = @_;

	return "\t{\n\t\t$line,\n\t}";
}

sub _write_module
{
	my ($name, $input_block, $output_type, $body) = @_;

	my @parts = split(/::/, $name);
	my $file = pop(@parts);
	my $parent = File::Spec->catdir($dir, 'lib', @parts);
	make_path($parent);
	my $path = File::Spec->catfile($parent, "$file.pm");

	my $source = <<"HEADER";
package $name;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(looks_like_number);

=head2 tidy

=head4 input

$input_block

=head4 output

	{ type => '$output_type' }

=cut

$body

1;
HEADER

	open(my $fh, '>', $path) or die "cannot write $path: $!";
	print {$fh} $source;
	close($fh) or die "cannot close $path: $!";

	$module_file{$name} = $path;
}

_write_module(
	'Bounds::Accepts',
	_spec_block("names => { type => 'arrayref', optional => 0, min => 1 }"),
	'arrayref',
	<<'BODY');
sub tidy
{
	my ($names) = @_;

	return [ map { lc($_) } @{$names} ];
}
BODY

_write_module(
	'Bounds::Enforces',
	_spec_block("names => { type => 'arrayref', optional => 0, min => 1 }"),
	'arrayref',
	<<'BODY');
sub tidy
{
	my ($names) = @_;

	croak('tidy: at least one name is required') unless @{$names};

	return [ map { lc($_) } @{$names} ];
}
BODY

# Accepts strings shorter than the documented minimum, like a routine that
# only trims or upper-cases whatever it is handed.
_write_module(
	'Bounds::AcceptsString',
	_spec_block("text => { type => 'string', optional => 0, min => 5 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	return uc($text);
}
BODY

# Ignores a documented minimum that is longer than the generator's fixed
# short samples ("hello", "he\nlo", ...).  Those samples must not be sent
# as expected-to-live values at all, even though this routine accepts them.
_write_module(
	'Bounds::AcceptsStringMin',
	_spec_block("text => { type => 'string', optional => 0, min => 10 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	return uc($text);
}
BODY

_write_module(
	'Bounds::EnforcesString',
	_spec_block("text => { type => 'string', optional => 0, min => 5 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: at least five characters are required') unless length($text) >= 5;

	return uc($text);
}
BODY

# Enforces a stricter minimum than the POD states: the documented range says
# five characters are valid, but the routine rejects them.
_write_module(
	'Bounds::EnforcesStringStricter',
	_spec_block("text => { type => 'string', optional => 0, min => 5 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: more than five characters are required') unless length($text) >= 6;

	return uc($text);
}
BODY

# Accepts fewer array elements than the documented minimum.  The random
# array generator makes short arrays, so fuzzing can observe the contradiction.
_write_module(
	'Bounds::AcceptsArrayMin',
	_spec_block("names => { type => 'arrayref', optional => 0, min => 5 }"),
	'arrayref',
	<<'BODY');
sub tidy
{
	my ($names) = @_;

	return [ map { lc($_) } @{$names} ];
}
BODY

# Enforces a longer documented minimum, so no short fixed sample may be
# generated as a value that should survive.
_write_module(
	'Bounds::EnforcesStringMin',
	_spec_block("text => { type => 'string', optional => 0, min => 10 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: at least ten characters are required') unless length($text) >= 10;

	return uc($text);
}
BODY

# Enforces both ends of a documented string range.
_write_module(
	'Bounds::EnforcesStringRange',
	_spec_block("text => { type => 'string', optional => 0, min => 5, max => 10 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: text must be 5 to 10 characters')
		unless length($text) >= 5 && length($text) <= 10;

	return uc($text);
}
BODY

# Accepts integers below the documented minimum, like a routine that only
# doubles whatever it is handed.
_write_module(
	'Bounds::AcceptsInteger',
	_spec_block("count => { type => 'integer', optional => 0, min => 5 }"),
	'integer',
	<<'BODY');
sub tidy
{
	my $count = shift;

	# Ignores the documented minimum, but still rejects non-integers.
	croak('tidy: count must be an integer')
		unless defined($count) && !ref($count) && looks_like_number($count) && int($count) == $count;

	return $count * 2;
}
BODY

# Ignores the documented numeric minimum, but still rejects non-numbers.
_write_module(
	'Bounds::AcceptsNumber',
	_spec_block("ratio => { type => 'number', optional => 0, min => 5 }"),
	'number',
	<<'BODY');
sub tidy
{
	my $ratio = shift;

	croak('tidy: ratio must be a number')
		unless defined($ratio) && !ref($ratio) && looks_like_number($ratio);

	return $ratio * 2;
}
BODY

# Accepts a documented range that starts at zero, including the string "0".
# Enforces both ends of a documented numeric range.
_write_module(
	'Bounds::EnforcesNumberRange',
	_spec_block("ratio => { type => 'number', optional => 0, min => 5, max => 10 }"),
	'number',
	<<'BODY');
sub tidy
{
	my $ratio = shift;

	croak('tidy: ratio must be between 5 and 10')
		unless defined($ratio) && !ref($ratio) && looks_like_number($ratio)
			&& $ratio >= 5 && $ratio <= 10;

	return $ratio * 2;
}
BODY

_write_module(
	'Bounds::AcceptsStringRange',
	_spec_block("text => { type => 'string', optional => 0, min => 0, max => 10 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: text must be a string')
		unless defined($text) && !ref($text);

	return uc($text);
}
BODY

# Accepts strings longer than the documented maximum.
_write_module(
	'Bounds::AcceptsStringMax',
	_spec_block("text => { type => 'string', optional => 0, max => 5 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: text must be a string')
		unless defined($text) && !ref($text);

	return uc($text);
}
BODY

# Enforces a hand-written maximum; random values must stay at or below it.
_write_module(
	'Bounds::EnforcesStringMax',
	_spec_block("text => { type => 'string', optional => 0, max => 5 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: text must be a string')
		unless defined($text) && !ref($text);
	croak('tidy: text must be at most five characters') if length($text) > 5;

	return uc($text);
}
BODY

_write_module(
	'Bounds::EnforcesIntegerMax',
	_spec_block("count => { type => 'integer', optional => 0, max => 5 }"),
	'integer',
	<<'BODY');
sub tidy
{
	my $count = shift;

	croak('tidy: count must be an integer')
		unless defined($count) && !ref($count) && looks_like_number($count) && int($count) == $count;
	croak('tidy: count must be at most five') if $count > 5;

	return $count * 2;
}
BODY

_write_module(
	'Bounds::EnforcesNumberMax',
	_spec_block("ratio => { type => 'number', optional => 0, max => 5 }"),
	'number',
	<<'BODY');
sub tidy
{
	my $ratio = shift;

	croak('tidy: ratio must be a number')
		unless defined($ratio) && !ref($ratio) && looks_like_number($ratio);
	croak('tidy: ratio must be at most five') if $ratio > 5;

	return $ratio * 2;
}
BODY

# Accepts strings that break a documented maximum and its pattern.
_write_module(
	'Bounds::AcceptsMaxMatches',
	"\t" . 'C<$slug> - string (max 5), matches /^[a-z]+$/',
	'string',
	<<'BODY');
sub tidy
{
	my $slug = shift;

	croak('tidy: slug must be a string')
		unless defined($slug) && !ref($slug);

	return uc($slug);
}
BODY

# Accepts numbers above the documented maximum.
_write_module(
	'Bounds::AcceptsNumberMax',
	_spec_block("ratio => { type => 'number', optional => 0, max => 5 }"),
	'number',
	<<'BODY');
sub tidy
{
	my $ratio = shift;

	croak('tidy: ratio must be a number')
		unless defined($ratio) && !ref($ratio) && looks_like_number($ratio);

	return $ratio * 2;
}
BODY

# A documented pattern the code does not enforce.
_write_module(
	'Bounds::AcceptsMatches',
	"\t" . 'C<$slug> - string, matches /^[a-z]+$/',
	'string',
	<<'BODY');
sub tidy
{
	my $slug = shift;

	return uc($slug);
}
BODY

# The documented set and pattern are enforced, so advisory probes die and
# nothing is reported.
_write_module(
	'Bounds::EnforcesMemberof',
	_spec_block("colour => { type => 'string', optional => 1, memberof => ['red', 'green'] }"),
	'string',
	<<'BODY');
sub tidy
{
	my $colour = shift;

	croak('tidy: colour must be red or green')
		if defined($colour) && ($colour ne 'red') && ($colour ne 'green');

	return defined($colour) ? uc($colour) : '';
}
BODY

_write_module(
	'Bounds::EnforcesMatches',
	"\t" . 'C<$slug> - string, matches /^[a-z]+$/',
	'string',
	<<'BODY');
sub tidy
{
	my $slug = shift;

	croak('tidy: slug must be lowercase letters')
		if defined($slug) && ($slug !~ /^[a-z]+$/);

	return defined($slug) ? uc($slug) : '';
}
BODY

# A documented set the code does not enforce.
_write_module(
	'Bounds::AcceptsMemberof',
	_spec_block("colour => { type => 'string', optional => 1, memberof => ['red', 'green'] }"),
	'string',
	<<'BODY');
sub tidy
{
	my $colour = shift;

	return defined($colour) ? uc($colour) : '';
}
BODY

# Integers in a documented set: the same reporting applies to a numeric
# allowed set, not only to strings.
_write_module(
	'Bounds::AcceptsIntegerMemberof',
	_spec_block("level => { type => 'integer', optional => 1, memberof => [1, 2] }"),
	'integer',
	<<'BODY');
sub pick
{
	my $level = shift;

	return defined($level) ? $level : 0;
}
BODY

# The same set, enforced: a hand-written schema must not feed it a random
# integer as a valid value.
_write_module(
	'Bounds::EnforcesIntegerMemberof',
	_spec_block("level => { type => 'integer', memberof => [1, 2] }"),
	'integer',
	<<'BODY');
sub pick
{
	my $level = shift;

	croak('level must be 1 or 2') unless(defined($level) && ($level eq '1' || $level eq '2'));
	return $level;
}
BODY

# A prose minimum on an integer.
_write_module(
	'Bounds::ProseInteger',
	"\t" . 'C<$count> - integer (at least 5)',
	'integer',
	<<'BODY');
sub tidy
{
	my $count = shift;

	croak('tidy: count must be an integer')
		unless defined($count) && !ref($count) && looks_like_number($count) && int($count) == $count;

	return $count * 2;
}
BODY

# The minimum is stated only in prose, the way most POD documents it.
_write_module(
	'Bounds::ProseMin',
	"\t" . 'C<$text> - string (at least 5 characters)',
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	return uc($text);
}
BODY

_write_module(
	'Bounds::ProseRange',
	"\t" . 'C<$text> - string (3-50 chars)',
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	return uc($text);
}
BODY

# The documented minimum and the maximum the code enforces are separate
# constraints: only the minimum is a documentation claim.
_write_module(
	'Bounds::MixedPodMinCodeMax',
	_spec_block("text => { type => 'string', optional => 0, min => 5 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: at most ten characters are allowed') if length($text) > 10;

	return uc($text);
}
BODY

_write_module(
	'Bounds::MixedPodMaxCodeMin',
	_spec_block("text => { type => 'string', optional => 0, max => 10 }"),
	'string',
	<<'BODY');
sub tidy
{
	my $text = shift;

	croak('tidy: at least five characters are required') unless length($text) >= 5;

	return uc($text);
}
BODY

sub _extract
{
	my ($module) = @_;

	my $out = File::Spec->catdir($dir, 'schemas', $module =~ s{::}{-}gr);
	make_path($out);

	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join($Config{path_sep}, $lib, File::Spec->catdir($dir, 'lib'), $ENV{PERL5LIB} // '');
	run3([$^X, "-I$lib", $script, '--output-dir', $out, $module_file{$module}], \undef, \$stdout, \$stderr);
	is($? >> 8, 0, "$module: extract-schemas succeeded")
		or diag("stdout:\n$stdout\nstderr:\n$stderr");

	my $yml = File::Spec->catfile($out, 'tidy.yml');
	return (LoadFile($yml), $yml);
}

sub _note_count
{
	my ($output) = @_;

	return scalar(() = $output =~ /documented-only constraint/g);
}

# A hand-written schema carries no provenance: neither the field's _source
# nor the per-constraint map that extraction adds.
sub _make_hand_written
{
	my ($spec) = @_;

	delete $spec->{_source};
	delete $spec->{_constraint_source};
}

sub _run_harness
{
	my ($schema_file, $label, @generator_args) = @_;

	my $test_file = File::Spec->catfile($dir, "$label.t");
	my ($stdout, $stderr) = ('', '');
	local $ENV{PERL5LIB} = join($Config{path_sep}, $lib, File::Spec->catdir($dir, 'lib'), $ENV{PERL5LIB} // '');
	run3([$^X, "-I$lib", $generator, @generator_args, $schema_file, '-o', $test_file], \undef, \$stdout, \$stderr);
	is($? >> 8, 0, "$label: harness generated") or diag("stdout:\n$stdout\nstderr:\n$stderr");

	my ($tap_out, $tap_err) = ('', '');
	run3([$^X, "-I$lib", $test_file], \undef, \$tap_out, \$tap_err);

	return ($? >> 8, "$tap_out$tap_err");
}

subtest 'a documented min is marked as documentation-only' => sub {
	my ($schema) = _extract('Bounds::Accepts');

	is($schema->{input}{names}{min}, 1, 'the documented bound is kept');
	is($schema->{input}{names}{_source}, 'input_spec', 'and marked as a documentation claim');
};

subtest 'a routine that accepts fewer than the documented minimum still passes' => sub {
	my ($schema, $yml) = _extract('Bounds::Accepts');
	my ($exit, $output) = _run_harness($yml, 'accepts');

	is($exit, 0, 'harness passes') or diag($output);
	like($output, qr/documented-only constraint on 'names'/, 'the tolerated bound is logged');
};

subtest 'a routine that enforces the minimum also passes' => sub {
	my ($schema, $yml) = _extract('Bounds::Enforces');
	my ($exit, $output) = _run_harness($yml, 'enforces');

	is($exit, 0, 'harness passes') or diag($output);
};

subtest 'a documented string minimum is marked and tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsString');

	is($schema->{input}{text}{min}, 5, 'the documented string bound is kept');
	is($schema->{input}{text}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_string');

	is($exit, 0, 'a routine that ignores the documented minimum passes') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the tolerated string bound is logged');
	like($output, qr/routine accepted a value outside the documented bound on 'text' \(min 5\)/,
		'the below-minimum acceptance is reported as a documentation contradiction');
};

subtest 'a routine that accepts fewer than a longer documented string minimum still passes' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsStringMin');

	is($schema->{input}{text}{min}, 10, 'the longer documented string minimum is kept');
	is($schema->{input}{text}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_string_min');

	is($exit, 0, 'a routine that ignores the longer documented minimum passes') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the tolerated string bound is logged');
	unlike($output, qr/tidy\(hello\)/, 'a short fixed sample is not generated as expected-to-live data');
};

subtest 'a routine that enforces the documented string minimum also passes' => sub {
	my ($schema, $yml) = _extract('Bounds::EnforcesString');
	my ($exit, $output) = _run_harness($yml, 'enforces_string');

	is($exit, 0, 'harness passes') or diag($output);
};

subtest 'a routine that rejects a documented-valid value is reported and tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::EnforcesStringStricter');

	is($schema->{input}{text}{min}, 5, 'the documented string minimum is kept');
	is($schema->{input}{text}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'enforces_string_stricter');

	is($exit, 0, 'the contradiction does not fail a normal run') or diag($output);
	like($output, qr/Documented-constraint contradictions found by fuzzing/, 'the run reports its findings');
	like($output, qr/routine rejected a value inside the documented bound on 'text' \(min 5\)/,
		'the in-bound rejection is recorded against the POD bound');
	like($output, qr/These contradictions are tolerated; use --strict-documented/,
		'the normal run says how to make the finding fatal');
};

subtest 'a routine that accepts a value outside a documented bound is reported' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsArrayMin');

	is($schema->{input}{names}{min}, 5, 'the documented array minimum is kept');
	is($schema->{input}{names}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_array_min');

	is($exit, 0, 'the contradiction does not fail a normal run') or diag($output);
	like($output, qr/routine accepted a value outside the documented bound on 'names' \(min 5\)/,
		'the out-of-bound acceptance is recorded against the POD bound');
};

subtest '--strict-documented fails on an outside-bound acceptance' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsStringMax');

	my ($exit, $output) = _run_harness($yml, 'accepts_string_max_strict', '--strict-documented');

	isnt($exit, 0, 'the strict run fails') or diag($output);
	like($output, qr/not ok .*strict-documented: routine accepted a value outside the documented bound on 'text' \(max 5\)/,
		'the outside-bound acceptance is a failing test in strict mode');
};

subtest '--strict-documented turns a documented-bound contradiction into a failure' => sub {
	my ($schema, $yml) = _extract('Bounds::EnforcesStringStricter');

	my ($exit, $output) = _run_harness($yml, 'enforces_string_stricter_strict', '--strict-documented');

	isnt($exit, 0, 'the strict run fails') or diag($output);
	like($output, qr/not ok .*strict-documented: routine rejected a value inside the documented bound on 'text' \(min 5\)/,
		'the recorded contradiction is a failing test');
	like($output, qr/Documented-constraint contradictions found by fuzzing/, 'the findings are still reported');
};

subtest 'a routine that enforces a longer documented string minimum passes' => sub {
	my ($schema, $yml) = _extract('Bounds::EnforcesStringMin');

	is($schema->{input}{text}{min}, 10, 'the documented string minimum is kept');
	is($schema->{input}{text}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'enforces_string_min');

	is($exit, 0, 'probes shorter than the documented minimum are allowed to die') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the tolerated string bound is logged');
	unlike($output, qr/routine accepted a value outside the documented bound on 'text'/,
		'a routine that enforces the minimum produces no outside-bound finding');
};

subtest 'a routine that enforces a documented string range passes' => sub {
	my ($schema, $yml) = _extract('Bounds::EnforcesStringRange');

	my ($exit, $output) = _run_harness($yml, 'enforces_string_range');

	is($exit, 0, 'no value outside the documented range is generated') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the tolerated string range is logged');
};

subtest 'a routine that enforces a documented number range passes' => sub {
	my ($schema, $yml) = _extract('Bounds::EnforcesNumberRange');

	is($schema->{input}{ratio}{min}, 5, 'the documented numeric minimum is kept');
	is($schema->{input}{ratio}{max}, 10, 'the documented numeric maximum is kept');
	is($schema->{input}{ratio}{_source}, 'input_spec', 'and both are marked as documentation claims');

	my ($exit, $output) = _run_harness($yml, 'enforces_number_range');

	is($exit, 0, 'no number outside the documented range is generated') or diag($output);
	like($output, qr/documented-only constraint on 'ratio'/, 'the tolerated numeric range is logged');
};

subtest 'a documented integer minimum is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsInteger');

	is($schema->{input}{count}{min}, 5, 'the documented integer bound is kept');
	is($schema->{input}{count}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_integer');

	is($exit, 0, 'a routine that ignores the documented minimum passes') or diag($output);
	like($output, qr/documented-only constraint on 'count'/, 'the tolerated integer bound is logged');
};

subtest 'a documented number minimum is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsNumber');

	is($schema->{input}{ratio}{min}, 5, 'the documented number bound is kept');
	is($schema->{input}{ratio}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_number');

	is($exit, 0, 'a routine that ignores the documented number minimum passes') or diag($output);
	like($output, qr/documented-only constraint on 'ratio'/, 'the tolerated number bound is logged');
};

subtest 'a documented range starting at zero is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsStringRange');

	is($schema->{input}{text}{min}, 0, 'the documented zero minimum is kept');
	is($schema->{input}{text}{max}, 10, 'the documented maximum is kept');
	is($schema->{input}{text}{_source}, 'input_spec', 'and both are marked as documentation claims');

	my ($exit, $output) = _run_harness($yml, 'accepts_string_range');

	is($exit, 0, 'a routine that ignores the documented range passes') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the tolerated range is logged');
	is(_note_count($output), 1, 'the range is logged once');
};

subtest 'a documented string maximum is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsStringMax');

	is($schema->{input}{text}{max}, 5, 'the documented string maximum is kept');
	is($schema->{input}{text}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_string_max');

	is($exit, 0, 'a routine that ignores the documented maximum passes') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the tolerated string maximum is logged');
	like($output, qr/routine accepted a value outside the documented bound on 'text' \(max 5\)/,
		'the above-maximum acceptance is reported as a documentation contradiction');
};

subtest 'a documented number maximum is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsNumberMax');

	is($schema->{input}{ratio}{max}, 5, 'the documented number maximum is kept');
	is($schema->{input}{ratio}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_number_max');

	is($exit, 0, 'a routine that ignores the documented maximum passes') or diag($output);
	like($output, qr/documented-only constraint on 'ratio'/, 'the tolerated number maximum is logged');
	like($output, qr/routine accepted a value outside the documented bound on 'ratio' \(max 5\)/,
		'the above-maximum acceptance is reported as a documentation contradiction');
};

subtest 'a documented maximum with a pattern is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsMaxMatches');

	is($schema->{input}{slug}{max}, 5, 'the documented maximum is kept');
	ok($schema->{input}{slug}{matches}, 'the documented pattern is kept');
	is($schema->{input}{slug}{_source}, 'pod', 'and both are marked as documentation claims');

	my ($exit, $output) = _run_harness($yml, 'accepts_max_matches');

	is($exit, 0, 'a routine that ignores the documented maximum and pattern passes') or diag($output);
	like($output, qr/documented-only constraint on 'slug'/, 'the tolerated constraints are logged');
	is(_note_count($output), 1, 'two constraints on one field are logged once');
};

subtest 'a hand-written string maximum is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsStringMax');

	my $strict = File::Spec->catfile($dir, 'strict_string_max.yml');
	_make_hand_written($schema->{input}{text});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict_string_max');

	isnt($exit, 0, 'harness fails when the routine ignores a string maximum it declares');
	like($output, qr/not ok/, 'the failure is reported');
};

subtest 'a hand-written number maximum is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsNumberMax');

	my $strict = File::Spec->catfile($dir, 'strict_number_max.yml');
	_make_hand_written($schema->{input}{ratio});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict_number_max');

	isnt($exit, 0, 'harness fails when the routine ignores a number maximum it declares');
	like($output, qr/not ok/, 'the failure is reported');
};

subtest 'a hand-written zero minimum is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsStringRange');

	my $strict = File::Spec->catfile($dir, 'strict_zero_min.yml');
	_make_hand_written($schema->{input}{text});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict_zero_min');

	isnt($exit, 0, 'harness fails when a hand-written schema expects 0 to die');
	like($output, qr/not ok/, 'the failure is reported');
};

subtest 'a minimum stated in POD prose is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::ProseMin');

	is($schema->{input}{text}{min}, 5, 'the prose minimum becomes a bound');
	is($schema->{input}{text}{_source}, 'pod', 'and is marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'prose_min');

	is($exit, 0, 'a routine that ignores the prose minimum passes') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the tolerated prose bound is logged');
};

subtest 'a prose minimum on an integer is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::ProseInteger');

	is($schema->{input}{count}{min}, 5, 'the prose integer minimum becomes a bound');
	is($schema->{input}{count}{_source}, 'pod', 'and is marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'prose_integer');

	is($exit, 0, 'a routine that ignores the prose integer minimum passes') or diag($output);
	like($output, qr/documented-only constraint on 'count'/, 'the tolerated prose integer bound is logged');
};

subtest 'a range stated in POD prose is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::ProseRange');

	is($schema->{input}{text}{min}, 3, 'the prose range minimum becomes a bound');
	is($schema->{input}{text}{max}, 50, 'the prose range maximum becomes a bound');
	is($schema->{input}{text}{_source}, 'pod', 'and both are marked as documentation claims');

	my ($exit, $output) = _run_harness($yml, 'prose_range');

	is($exit, 0, 'a routine that ignores the prose range passes') or diag($output);
	is(_note_count($output), 1, 'the prose range is logged once');
};

subtest 'a documented match pattern is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsMatches');

	ok($schema->{input}{slug}{matches}, 'the documented pattern is kept');
	is($schema->{input}{slug}{_source}, 'pod', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_matches');

	is($exit, 0, 'a routine that ignores the documented pattern passes') or diag($output);
	like($output, qr/documented-only constraint on 'slug'/, 'the tolerated pattern is logged');
	like($output, qr/routine accepted a value that does not match the documented pattern on 'slug'/,
		'the run reports that the routine accepts a value the POD says is invalid');
};

subtest 'a documented member list is tolerated' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsMemberof');

	is_deeply($schema->{input}{colour}{memberof}, ['red', 'green'], 'the documented list is kept');
	is($schema->{input}{colour}{_source}, 'input_spec', 'and marked as a documentation claim');

	my ($exit, $output) = _run_harness($yml, 'accepts_memberof');

	is($exit, 0, 'a routine that ignores the documented list passes') or diag($output);
	like($output, qr/documented-only constraint on 'colour'/, 'the tolerated list is logged');
	like($output, qr/routine accepted a value outside the documented memberof list on 'colour' \(one of: red, green\)/,
		'the run reports the undocumented value it accepted');
};

subtest '--strict-documented fails on an accepted documented list value' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsMemberof');
	my ($exit, $output) = _run_harness($yml, 'strict_documented_memberof', '--strict-documented');

	isnt($exit, 0, 'the advisory finding becomes a failure when requested');
	like($output, qr/not ok .*strict-documented: routine accepted a value outside the documented memberof list on 'colour'/,
		'the failure names the documented list');
};

subtest 'a documented member list on an integer is tolerated' => sub {
	my $schema = {
		module   => 'Bounds::AcceptsIntegerMemberof',
		function => 'pick',
		input    => {
			level => {
				type     => 'integer',
				optional => 0,
				position => 0,
				memberof => [1, 2],
				_source  => 'pod',
			},
		},
		output => { type => 'integer' },
		config => {
			test_empty     => 0,
			test_nuls      => 0,
			test_non_ascii => 0,
			test_security  => 0,
			test_undef     => 0,
		},
	};

	my $yml = File::Spec->catfile($dir, 'documented_integer_memberof.yml');
	DumpFile($yml, $schema);

	my ($exit, $output) = _run_harness($yml, 'documented_integer_memberof');

	is($exit, 0, 'a routine that ignores a documented integer set passes') or diag($output);
	like($output, qr/documented-only constraint on 'level'/, 'the tolerated set is logged');
	like($output, qr/routine accepted a value outside the documented memberof list on 'level' \(one of: 1, 2\)/,
		'the run reports the integer it accepted outside the documented set');
	like($output, qr/pick\(3\) survives/, 'the value outside the set is always tried, not left to chance');
};

subtest 'a hand-written integer member list on a lone mandatory argument' => sub {
	my $schema = {
		module   => 'Bounds::EnforcesIntegerMemberof',
		function => 'pick',
		input    => {
			level => { type => 'integer', optional => 0, position => 0, memberof => [1, 2] },
		},
		output => { type => 'integer' },
		config => {
			test_empty     => 0,
			test_nuls      => 0,
			test_non_ascii => 0,
			test_security  => 0,
			test_undef     => 0,
		},
	};

	my $yml = File::Spec->catfile($dir, 'enforced_integer_memberof.yml');
	DumpFile($yml, $schema);

	my ($exit, $output) = _run_harness($yml, 'enforced_integer_memberof');

	is($exit, 0, 'a routine that enforces the set passes') or diag($output);
	like($output, qr/pick\(3\) dies/, 'the value outside the set must die');
	unlike($output, qr/pick\((?![12]\))[^)]*\) survives/, 'no value outside the set is expected to survive');
};

subtest '--strict-documented fails on an accepted non-matching value' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsMatches');
	my ($exit, $output) = _run_harness($yml, 'strict_documented_matches', '--strict-documented');

	isnt($exit, 0, 'the advisory finding becomes a failure when requested');
	like($output, qr/not ok .*strict-documented: routine accepted a value that does not match the documented pattern on 'slug'/,
		'the failure names the documented pattern');
};

subtest 'a routine that enforces its documented constraints reports no acceptance' => sub {
	foreach my $case (
		[ 'Bounds::EnforcesMemberof', 'enforces_memberof' ],
		[ 'Bounds::EnforcesMatches',  'enforces_matches' ],
	) {
		my ($module, $label) = @{$case};
		my ($schema, $yml) = _extract($module);
		my ($exit, $output) = _run_harness($yml, $label);

		is($exit, 0, "$label: an enforced documented constraint passes") or diag($output);
		unlike($output, qr/routine accepted a value outside the documented/,
			"$label: no outside acceptance is reported");
		unlike($output, qr/does not match the documented pattern/,
			"$label: no pattern breach is reported");
	}
};

subtest 'a hand-written match pattern is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsMatches');

	my $strict = File::Spec->catfile($dir, 'strict_matches.yml');
	_make_hand_written($schema->{input}{slug});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict_matches');

	isnt($exit, 0, 'harness fails when the routine ignores a pattern it declares');
	like($output, qr/not ok/, 'the failure is reported');
};

subtest 'a hand-written member list is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsMemberof');

	my $strict = File::Spec->catfile($dir, 'strict_memberof.yml');
	_make_hand_written($schema->{input}{colour});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict_memberof');

	isnt($exit, 0, 'harness fails when the routine ignores a list it declares');
	like($output, qr/not ok/, 'the failure is reported');
};

subtest 'a hand-written integer bound is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsInteger');

	my $strict = File::Spec->catfile($dir, 'strict_integer.yml');
	_make_hand_written($schema->{input}{count});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict_integer');

	isnt($exit, 0, 'harness fails when the routine ignores an integer bound it declares');
	like($output, qr/not ok/, 'the failure is reported');
};

subtest 'a hand-written string bound is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::AcceptsString');

	# Same schema without the mark, as a hand-written one would be.
	my $strict = File::Spec->catfile($dir, 'strict_string.yml');
	_make_hand_written($schema->{input}{text});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict_string');

	isnt($exit, 0, 'harness fails when the routine ignores a string bound it declares');
	like($output, qr/not ok/, 'the failure is reported');
	unlike($output, qr/documented-only constraint/, 'no tolerance is logged without the mark');
};

subtest 'a hand-written arrayref bound is still required to die' => sub {
	my ($schema, $yml) = _extract('Bounds::Accepts');

	# Same schema without the mark, as a hand-written one would be.
	my $strict = File::Spec->catfile($dir, 'strict.yml');
	_make_hand_written($schema->{input}{names});
	DumpFile($strict, $schema);

	my ($exit, $output) = _run_harness($strict, 'strict');

	isnt($exit, 0, 'harness fails when the routine ignores a bound it declares');
	like($output, qr/not ok/, 'the failure is reported');
};

subtest 'a mark with no constraint to relax logs nothing' => sub {
	my ($schema) = _extract('Bounds::AcceptsString');

	my $bare = File::Spec->catfile($dir, 'bare_mark.yml');
	delete $schema->{input}{text}{min};
	DumpFile($bare, $schema);

	my ($exit, $output) = _run_harness($bare, 'bare_mark');

	is($exit, 0, 'a routine with only the marker passes') or diag($output);
	is(_note_count($output), 0, 'nothing is logged when there is no constraint to tolerate');
};

subtest 'positional random strings respect a documented bound' => sub {
	foreach my $case ([ 'Bounds::AcceptsStringMin', 'scalar_string_min' ], [ 'Bounds::AcceptsStringMax', 'scalar_string_max' ]) {
		my ($module, $label) = @{$case};
		my ($schema) = _extract($module);

		my %scalar = %{$schema};
		$scalar{input} = { text => { %{$schema->{input}{text}}, position => 0 } };
		my $file = File::Spec->catfile($dir, "$label.yml");
		DumpFile($file, \%scalar);

		my ($exit, $output) = _run_harness($file, $label);

		is($exit, 0, "$label: positional string stays inside its bound") or diag($output);
	}
};

subtest 'random values respect a hand-written maximum' => sub {
	foreach my $case (
		[ 'Bounds::EnforcesIntegerMax', 'count', 'scalar_integer_max' ],
		[ 'Bounds::EnforcesNumberMax',  'ratio', 'scalar_number_max' ],
		[ 'Bounds::EnforcesStringMax',  'text',  'scalar_string_max_strict' ],
	) {
		my ($module, $field, $label) = @{$case};
		my ($schema) = _extract($module);

		my %scalar = %{$schema};
		$scalar{input} = { $field => { %{$schema->{input}{$field}}, position => 0 } };
		_make_hand_written($scalar{input}{$field});
		my $file = File::Spec->catfile($dir, "$label.yml");
		DumpFile($file, \%scalar);

		my ($exit, $output) = _run_harness($file, $label);

		is($exit, 0, "$label: random values stay at or below the declared maximum") or diag($output);
	}
};

# ==================================================================
# Per-constraint provenance
#
# A field may get its minimum from POD and its maximum from the code (or
# the other way round).  The documented end is a hint for valid data; the
# end the code enforces is a check.  One _source value per field cannot
# express that, so the schema records provenance per constraint.
# ==================================================================

subtest 'a documented minimum does not make a code maximum tolerant' => sub {
	my ($schema, $yml) = _extract('Bounds::MixedPodMinCodeMax');

	is($schema->{input}{text}{min}, 5, 'the documented minimum is kept');
	is($schema->{input}{text}{max}, 10, 'the maximum enforced by the code is kept');
	is_deeply(
		$schema->{input}{text}{_constraint_source},
		{ min => 'input_spec', max => 'code' },
		'each bound carries its own provenance'
	);

	my ($exit, $output) = _run_harness($yml, 'mixed_min_pod_max_code');
	is($exit, 0, 'the routine passes the harness') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the documented minimum is tolerated');
};

subtest 'a documented maximum does not make a code minimum tolerant' => sub {
	my ($schema, $yml) = _extract('Bounds::MixedPodMaxCodeMin');

	is_deeply(
		$schema->{input}{text}{_constraint_source},
		{ min => 'code', max => 'input_spec' },
		'the code minimum and the documented maximum stay separate'
	);

	my ($exit, $output) = _run_harness($yml, 'mixed_max_pod_min_code');
	is($exit, 0, 'the routine passes the harness') or diag($output);
	like($output, qr/documented-only constraint on 'text'/, 'the documented maximum is tolerated');
};

subtest 'a code maximum stays strict beside a documented minimum' => sub {
	my ($schema) = _extract('Bounds::AcceptsString');
	my $field = $schema->{input}{text};

	# The routine accepts any length; only the minimum is documented.
	$field->{max} = 10;
	$field->{_constraint_source} = { min => 'input_spec', max => 'code' };

	my $strict = File::Spec->catfile($dir, 'mixed_strict_max.yml');
	DumpFile($strict, $schema);
	my ($exit, $output) = _run_harness($strict, 'mixed_strict_max');

	isnt($exit, 0, 'harness fails when the routine accepts more than the code maximum') or diag($output);
	like($output, qr/not ok/, 'the failure is reported');

	# The same maximum claimed by the documentation is only a hint.
	$field->{_constraint_source}{max} = 'input_spec';
	my $tolerant = File::Spec->catfile($dir, 'mixed_tolerant_max.yml');
	DumpFile($tolerant, $schema);
	my ($exit2, $output2) = _run_harness($tolerant, 'mixed_tolerant_max');

	is($exit2, 0, 'harness passes when the same maximum is only documented') or diag($output2);
};

subtest 'a code minimum stays strict beside a documented maximum' => sub {
	my ($schema) = _extract('Bounds::AcceptsString');
	my $field = $schema->{input}{text};

	# The routine accepts any length; only the maximum is documented.
	$field->{max} = 10;
	$field->{_constraint_source} = { min => 'code', max => 'input_spec' };

	my $strict = File::Spec->catfile($dir, 'mixed_strict_min.yml');
	DumpFile($strict, $schema);
	my ($exit, $output) = _run_harness($strict, 'mixed_strict_min');

	isnt($exit, 0, 'harness fails when the routine accepts less than the code minimum') or diag($output);
	like($output, qr/not ok/, 'the failure is reported');

	$field->{_constraint_source}{min} = 'input_spec';
	my $tolerant = File::Spec->catfile($dir, 'mixed_tolerant_min.yml');
	DumpFile($tolerant, $schema);
	my ($exit2, $output2) = _run_harness($tolerant, 'mixed_tolerant_min');

	is($exit2, 0, 'harness passes when the same minimum is only documented') or diag($output2);
};

done_testing();
