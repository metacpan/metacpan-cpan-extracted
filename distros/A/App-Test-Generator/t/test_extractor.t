#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(extended);	# New features
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Create a temporary module for testing
my $tempdir = tempdir(CLEANUP => 1);
my $test_module = File::Spec->catfile($tempdir, 'TestModule.pm');

# Write test module
open my $fh, '>', $test_module or die "Can't create test module: $!";
print $fh <<'END_MODULE';
package TestModule;

use strict;
use warnings;
use Carp qw(croak);

=head2 simple_string($name)

=head3 INPUT

  $name - string (3-50 chars), person's name

=cut

sub simple_string {
	my ($self, $name) = @_;
	croak unless defined $name;
	croak unless length($name) >= 3;
	croak unless length($name) <= 50;
	return uc($name);
}

=head2 simple_integer($count)

Parameters:
  $count - integer (1-100), number of items

=cut

sub simple_integer {
	my ($self, $count) = @_;
	croak unless $count >= 1;
	croak unless $count <= 100;
	return $count * 2;
}

=head2 with_regex($email)

Parameters:
  $email - string, matches /\@/

=cut

sub with_regex {
	my ($self, $email) = @_;
	croak unless $email =~ /\@/;
	return $email;
}

=head2 array_param($items)

Parameters:
  $items - arrayref

=cut

sub array_param {
	my ($self, $items) = @_;
	croak unless ref($items) eq 'ARRAY';
	return scalar @$items;
}

=head2 hash_param($config)

Parameters:
  $config - hashref

=cut

sub hash_param {
	my ($self, $config) = @_;
	croak unless ref($config) eq 'HASH';
	return keys %$config;
}

=head2 optional_param($required, $optional)

Parameters:
  $required - string
  $optional - string (optional)

=cut

sub optional_param {
	my ($self, $required, $optional) = @_;
	croak unless defined $required;
	return $required . ($optional || '');
}

=head2 poorly_documented($x)

Does something.

=cut

sub poorly_documented {
	my ($self, $x) = @_;
	return $x;
}

sub _private_method {
	my ($self) = @_;
	return 1;
}

1;
END_MODULE
close $fh;

# Module instantiation
my $extractor = App::Test::Generator::SchemaExtractor->new(
	input_file => $test_module,
	output_dir => File::Spec->catdir($tempdir, 'schemas'),
	verbose	=> 0,
);

isa_ok($extractor, 'App::Test::Generator::SchemaExtractor');

# Extract schemas
my $schemas = $extractor->extract_all();

ok($schemas, 'extract_all returns schemas');
is(ref($schemas), 'HASH', 'schemas is a hashref');

# Check we found the right number of methods (excludes private)
my @methods = keys %$schemas;
cmp_ok(scalar(@methods), '>=', 6, 'Found at least 6 methods');

# simple_string analysis
subtest 'simple_string method' => sub {
	my $schema = $schemas->{simple_string};
	ok($schema, 'simple_string schema exists');

	my $name_param = $schema->{input}{name};
	ok($name_param, 'name parameter detected');
	is($name_param->{type}, 'string', 'type is string');
	is($name_param->{min}, 3, 'min is 3');
	is($name_param->{max}, 50, 'max is 50');
	is($name_param->{optional}, 0, 'parameter is required');

	like($schema->{_confidence}{input}->{'level'}, qr/high|medium/, 'input confidence is high or medium');
};

# simple_integer analysis
subtest 'simple_integer method' => sub {
	my $schema = $schemas->{simple_integer};
	ok($schema, 'simple_integer schema exists');

	my $count_param = $schema->{input}{count};
	ok($count_param, 'count parameter detected');
	is($count_param->{type}, 'integer', 'type is integer');
	is($count_param->{min}, 1, 'min is 1');
	is($count_param->{max}, 100, 'max is 100');
};

# regex pattern detection
subtest 'with_regex method' => sub {
	my $schema = $schemas->{with_regex};
	ok($schema, 'with_regex schema exists');

	my $email_param = $schema->{input}{email};
	ok($email_param, 'email parameter detected');
	is($email_param->{type}, 'string', 'type is string');
	ok($email_param->{matches}, 'has matches constraint');
};

# arrayref detection
subtest 'array_param method' => sub {
	my $schema = $schemas->{array_param};
	ok($schema, 'array_param schema exists');

	my $items_param = $schema->{input}{items};
	ok($items_param, 'items parameter detected');
	is($items_param->{type}, 'arrayref', 'type is arrayref');
};

# hashref detection
subtest 'hash_param method' => sub {
	my $schema = $schemas->{hash_param};
	ok($schema, 'hash_param schema exists');

	my $config_param = $schema->{input}{config};
	ok($config_param, 'config parameter detected');
	is($config_param->{type}, 'hashref', 'type is hashref');
};

# optional parameter detection
subtest 'optional_param method' => sub {
	my $schema = $schemas->{optional_param};
	ok($schema, 'optional_param schema exists');

	my $required_param = $schema->{input}{required};
	my $optional_param = $schema->{input}{optional};

	ok($required_param, 'required parameter detected');
	ok($optional_param, 'optional parameter detected');

	is($required_param->{optional}, 0, 'required param marked as required');
	is($optional_param->{optional}, 1, 'optional param marked as optional');
};

# poorly documented method
subtest 'poorly_documented method' => sub {
	my $schema = $schemas->{poorly_documented};
	ok($schema, 'poorly_documented schema exists');

	is($schema->{_confidence}{input}->{'level'}, 'medium', 'input confidence is medium');
	is($schema->{_confidence}{output}->{'level'}, 'medium', 'output confidence is medium');
	# Notes might be present or not, depending on what we could infer
	# Just check the schema exists and has low confidence
};

# private methods excluded
ok(!exists($schemas->{_private_method}), 'private methods excluded');

# object instantiation detection
subtest 'object instantiation detection' => sub {
	# Instance methods should have 'new' field
	my $simple_string = $schemas->{simple_string};
	ok($simple_string->{new}, 'simple_string has new field');
	is($simple_string->{new}, 'TestModule', 'new field contains package name');

	my $array_param = $schemas->{array_param};
	ok($array_param->{new}, 'array_param has new field');
	is($array_param->{new}, 'TestModule', 'new field contains package name');

	# Note: We don't test constructors since they shouldn't have 'new' field
};

# positional argument detection
subtest 'positional argument detection' => sub {
	my $simple_string = $schemas->{simple_string};
	my $name_param = $simple_string->{input}{name};

	ok(defined($name_param->{position}), 'name parameter has position');
	is($name_param->{position}, 0, 'name is first parameter (position 0)');

	# Test optional_param which has two parameters
	my $optional_param_schema = $schemas->{optional_param};
	ok(defined($optional_param_schema->{input}{required}{position}), 'required has position');
	ok(defined($optional_param_schema->{input}{optional}{position}), 'optional has position');
	is($optional_param_schema->{input}{required}{position}, 0, 'required is position 0');
	is($optional_param_schema->{input}{optional}{position}, 1, 'optional is position 1');
};

# output/return value detection
subtest 'output detection' => sub {
	# simple_string returns uc($name), so should detect string return
	my $simple_string = $schemas->{simple_string};
	ok($simple_string->{output}, 'simple_string has output section');
	# Type might be detected or not depending on code analysis

	# simple_integer has explicit return value
	my $simple_integer = $schemas->{simple_integer};
	ok($simple_integer->{output}, 'simple_integer has output section');

	# array_param returns scalar @$items
	my $array_param = $schemas->{array_param};
	ok($array_param->{output}, 'array_param has output section');
	ok($array_param->{output}{type}, 'array_param output has type');
};

# YAML files written
my $schema_dir = File::Spec->catdir($tempdir, 'schemas');
ok(-d $schema_dir, 'schema directory created');

my $simple_string_yaml = File::Spec->catfile($schema_dir, 'simple_string.yml');
ok(-f $simple_string_yaml, 'simple_string.yml file created');

# YAML file content
open my $yaml_fh, '<', $simple_string_yaml or die "Can't read YAML: $!";
my $yaml_content = do { local $/; <$yaml_fh> };
close $yaml_fh;

like($yaml_content, qr/function:\s*simple_string/, 'YAML contains method name');
like($yaml_content, qr/type:\s*string/, 'YAML contains type');
like($yaml_content, qr/min:\s*3/, 'YAML contains min');
like($yaml_content, qr/max:\s*50/, 'YAML contains max');

done_testing();

__END__

=head1 NAME

test_extractor.t - Test suite for Schema Extractor

=head1 DESCRIPTION

Tests the schema extraction functionality including:
- POD parsing
- Code pattern analysis
- Type inference
- Confidence scoring
- YAML output generation

=cut
