#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('App::Test::Generator::Template') }

# ==================================================================
# get_data_section — called as class method
# ==================================================================
subtest 'get_data_section() as class method returns a reference' => sub {
	my $result = App::Test::Generator::Template->get_data_section('test.tt');
	ok(defined $result, 'returns defined value');
	is(ref($result), 'SCALAR', 'returns a SCALAR reference');
};

subtest 'get_data_section() as class method returns non-empty content' => sub {
	my $result = App::Test::Generator::Template->get_data_section('test.tt');
	ok(length(${ $result }) > 0, 'template content is non-empty');
};

# ==================================================================
# get_data_section — called as plain function
# ==================================================================
subtest 'get_data_section() as plain function returns a reference' => sub {
	my $result = App::Test::Generator::Template::get_data_section('test.tt');
	ok(defined $result, 'returns defined value');
	is(ref($result), 'SCALAR', 'returns a SCALAR reference');
};

subtest 'get_data_section() class method and plain call return same content' => sub {
	my $class_result = App::Test::Generator::Template->get_data_section('test.tt');
	my $plain_result = App::Test::Generator::Template::get_data_section('test.tt');
	is(${ $class_result }, ${ $plain_result }, 'both calling styles return identical content');
};

# ==================================================================
# get_data_section — unknown template name
# ==================================================================
subtest 'get_data_section() returns undef for unknown template' => sub {
	my $result = App::Test::Generator::Template->get_data_section('nonexistent.tt');
	ok(!defined(${ $result }), 'unknown template name returns ref to undef');
};

# ==================================================================
# get_data_section — undef argument
# ==================================================================
subtest 'get_data_section() with undef returns ref to all sections' => sub {
	my $result = App::Test::Generator::Template->get_data_section(undef);
	ok(defined $result, 'undef arg returns defined value');
	# When called with undef, Data::Section::Simple returns a hashref
	# of all sections rather than a single scalar
	ok(ref($result), 'returns a reference');
};

done_testing();
