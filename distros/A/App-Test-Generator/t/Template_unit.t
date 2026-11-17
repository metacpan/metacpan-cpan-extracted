#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Capture::Tiny qw(capture);
use File::Temp qw(tempfile);
use App::Test::Generator;

# Black-box unit tests for App::Test::Generator::Template.
# Tests each public function according to its POD API specification.

BEGIN { use_ok('App::Test::Generator::Template') }

# ==================================================================
# get_data_section
#
# POD spec:
#   input:  $template_file — string, the template name
#   output: a reference to the template content
# ==================================================================

subtest 'get_data_section() called as class method returns a reference' => sub {
	my $result = App::Test::Generator::Template->get_data_section('test.tt');
	ok(defined $result,          'returns defined value');
	ok(ref($result),             'returns a reference');
};

subtest 'get_data_section() content is non-empty for test.tt' => sub {
	my $result = App::Test::Generator::Template->get_data_section('test.tt');
	ok(length(${ $result }) > 0, 'template content is non-empty');
};

subtest 'get_data_section() called as plain function returns same content' => sub {
	my $class_result = App::Test::Generator::Template->get_data_section('test.tt');
	my $plain_result = App::Test::Generator::Template::get_data_section('test.tt');
	is(${ $class_result }, ${ $plain_result },
		'class method and plain call return identical content');
};

subtest 'get_data_section() strips class name argument when called as method' => sub {
	# Calling ->get_data_section('test.tt') must not treat the class name
	# as the template name — verify the returned content is the template,
	# not undef from looking up 'App::Test::Generator::Template'
	my $result = App::Test::Generator::Template->get_data_section('test.tt');
	ok(defined ${ $result }, 'content is defined — class name not used as key');
};

subtest 'get_data_section() returns ref to undef for unknown template name' => sub {
	my $result = App::Test::Generator::Template->get_data_section('nonexistent.tt');
	ok(ref($result),              'still returns a reference');
	ok(!defined(${ $result }),    'dereferenced value is undef for unknown name');
};

subtest 'get_data_section() with undef argument returns a reference' => sub {
	my $result = App::Test::Generator::Template->get_data_section(undef);
	ok(defined $result, 'returns defined value for undef argument');
	ok(ref($result),    'returns a reference for undef argument');
};

subtest 'get_data_section() content for test.tt contains expected Perl boilerplate' => sub {
	my $result = App::Test::Generator::Template->get_data_section('test.tt');
	like(${ $result }, qr/use strict/,   'template contains "use strict"');
	like(${ $result }, qr/use warnings/, 'template contains "use warnings"');
};

# ==================================================================
# _dedup_cases (embedded in the test.tt template, copied verbatim
# into every generated .t file — extract its source and eval it in
# isolation to exercise the dedup logic directly).
#
# Regression: a `return \@rc;` inside the `eval { }` block returns
# from the eval, not from _dedup_cases — the deduped result must be
# captured from the eval's value, or the sub always falls through to
# returning the original, undeduplicated $cases.
# ==================================================================

subtest '_dedup_cases removes duplicate cases' => sub {
	my $template = ${ App::Test::Generator::Template->get_data_section('test.tt') };

	my ($sub_src) = $template =~ /(sub _dedup_cases\b.*?\n\}\n)/s;
	ok($sub_src, 'extracted _dedup_cases source from test.tt template');

	package Template::TestSandbox;
	use JSON::PP qw(encode_json);
	eval $sub_src; ## no critic
	die "failed to eval _dedup_cases: $@" if $@;
	package main;

	my @cases = (
		{ a => 1, b => 2 },
		{ a => 1, b => 2 },
		{ a => 3, b => 4 },
	);

	my $deduped = Template::TestSandbox::_dedup_cases(\@cases);

	is(scalar(@{$deduped}), 2, 'duplicate case was removed');
};

# ==================================================================
# Regression: an integer edge case for one named parameter of a
# multi-parameter (hash-style) API must carry that parameter's name.
# Passing it as _input called the routine with a single positional
# value, so the routine died on the argument count instead of on the
# value's type.
# ==================================================================

subtest 'named integer edge cases keep the parameter name' => sub {
	my $template = ${ App::Test::Generator::Template->get_data_section('test.tt') };

	unlike($template, qr/\{ _input => "007"/,
		'integer-as-string case is not a bare positional input');
	like($template, qr/\{ %case_input, \(\$field => "007"\)/,
		'integer-as-string case is passed as a named parameter');
};

# ==================================================================
# memberof tolerance
#
# A list that came from documentation (_source pod/input_spec) sizes
# the valid data but is not a check the routine was seen to make: the
# harness uses each value and generates no must-die case outside the
# set.  A hand-written schema carries no provenance marker, so its
# memberof is treated as checked and an outside value must die.
# ==================================================================

# Generate a harness for $yaml and return its source.
sub _generated_harness {
	my $yaml = shift;

	my ($fh, $schema) = tempfile(SUFFIX => '.yml', UNLINK => 1);
	print $fh $yaml;
	close $fh;

	my ($out) = capture(sub { App::Test::Generator->generate($schema) });
	return $out;
}

subtest 'documented memberof is tolerated' => sub {
	my $out = _generated_harness(<<'YAML');
module: My::Fake
function: pick
input:
  colour:
    type: string
    memberof: [red, green, blue]
    _source: pod
output:
  type: string
YAML

	like($out, qr/memberof => \[ 'red', 'green', 'blue' \]/,
		'the documented values reach the harness');
	like($out, qr/_source => 'pod'/,
		'the documentation marker reaches the harness');
	like($out, qr/_constraint_is_documented\(\$spec, 'memberof'\)/,
		'the outside case is gated on the memberof provenance');
	like($out, qr/documented memberof probe/,
		'the outside value is kept as an advisory probe rather than a must-die case');
};

# ==================================================================
# per-constraint tolerance predicate
#
# _constraint_is_documented is what decides whether a bound or list is a
# documented set (valid data only) or a checked one (an outside value must
# die).  Provenance can differ per constraint, so a documented minimum must
# not make a code-enforced maximum tolerant.  Extract the helpers from the
# template, as the _dedup_cases test does, and exercise them directly.
# ==================================================================

subtest '_constraint_is_documented separates documented constraints from checked ones' => sub {
	my $template = ${ App::Test::Generator::Template->get_data_section('test.tt') };

	my %src;
	foreach my $name (qw(_spec_source _constraint_source _constraint_is_documented)) {
		($src{$name}) = $template =~ /(sub \Q$name\E\b.*?\n\}\n)/s;
		ok($src{$name}, "extracted $name from test.tt");
	}

	package Template::SourceSandbox;
	# The generated harness declares these from App::Test::Generator::Provenance;
	# supply the same shared values when the subs are exercised on their own.
	our %documented_sources = map { $_ => 1 } App::Test::Generator::Provenance::documented_sources();
	our $type_checks_source = App::Test::Generator::Provenance::type_checks_source();
	foreach my $name (qw(_spec_source _constraint_source _constraint_is_documented)) {
		eval $src{$name}; ## no critic
		die "failed to eval $name: $@" if $@;
	}
	package main;

	ok(Template::SourceSandbox::_constraint_is_documented({ type => 'string', _source => 'pod' }, 'min'),
		'prose (pod) provenance is documented');
	ok(Template::SourceSandbox::_constraint_is_documented({ type => 'string', _source => 'input_spec' }, 'max'),
		'a formal input spec is documented');
	ok(!Template::SourceSandbox::_constraint_is_documented({ type => 'string', memberof => [qw(red green)] }, 'memberof'),
		'a hand-written schema has no marker, so its list is checked');
	ok(!Template::SourceSandbox::_constraint_is_documented({ type => 'string', _source => 'validator' }, 'min'),
		'a validator-backed parameter is checked');

	my $mixed = { type => 'string', _source => 'pod', _constraint_source => { min => 'pod', max => 'code' } };
	ok(Template::SourceSandbox::_constraint_is_documented($mixed, 'min'),
		'the documented minimum keeps its own provenance');
	ok(!Template::SourceSandbox::_constraint_is_documented($mixed, 'max'),
		'the code-enforced maximum is not made tolerant by the documented minimum');
};

# ==================================================================
# existing-file fixtures
#
# A schema may mark a path parameter semantic => 'existing_file' when the
# routine only checks that it exists.  Nothing generated from a pattern
# can exist, so the harness must create a temporary file and use it.
# ==================================================================

subtest 'an existing_file parameter gets a temporary-file fixture' => sub {
	my $out = _generated_harness(<<'YAML');
module: My::Fake
function: new
input:
  file:
    type: string
    semantic: existing_file
    optional: 0
output:
  type: object
YAML

	like($out, qr/next unless\(\(\$spec->\{'semantic'\} \/\/ ''\) eq 'existing_file'\)/,
		'the harness looks for the existing_file marker');
	like($out, qr/File::Temp::tempfile\(SUFFIX => '\.pm', UNLINK => 1\)/,
		'the harness creates a temporary file');
	like($out, qr/\$spec->\{'memberof'\} = \[ \$path \]/,
		'the parameter is given the existing file');
	like($out, qr/memberof => 'existing_file'/,
		'the fixture list records where it came from');
	like($out, qr/semantic => 'existing_file'/,
		'the marker reaches the generated input spec');
};

done_testing();
