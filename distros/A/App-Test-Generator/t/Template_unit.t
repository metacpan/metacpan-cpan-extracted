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

done_testing();
