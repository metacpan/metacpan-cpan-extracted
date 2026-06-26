#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

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

done_testing();
