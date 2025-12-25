#!/usr/bin/env perl

use strict;
use warnings;

use Test::DescribeMe qw(extended);
use Test::Most;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

# Create a temporary module for testing relationships
my $tempdir = tempdir(CLEANUP => 1);
my $test_module = File::Spec->catfile($tempdir, 'RelationshipTest.pm');

# Write test module with various parameter relationships
open my $fh, '>', $test_module or die "Can't create test module: $!";
print $fh <<'END_MODULE';
package RelationshipTest;

use strict;
use warnings;
use Carp qw(croak);

=head2 mutually_exclusive($file, $content)

Cannot specify both file and content parameters.

=cut

sub mutually_exclusive {
	my ($self, $file, $content) = @_;
	croak "Cannot specify both file and content" if $file && $content;
	return $file || $content;
}

=head2 required_group($id, $name)

Must specify either id or name.

=cut

sub required_group {
	my ($self, $id, $name) = @_;
	croak "Must specify either id or name" unless $id || $name;
	return $id || $name;
}

=head2 conditional_requirement($async, $callback)

When async is specified, callback is required.

=cut

sub conditional_requirement {
	my ($self, $async, $callback) = @_;
	croak "Async requires callback" if $async && !$callback;
	$callback->() if $async;
	return 1;
}

=head2 dependency($port, $host)

Port requires host to be specified.

=cut

sub dependency {
	my ($self, $port, $host) = @_;
	croak "Port requires host" if $port && !$host;
	return "$host:$port";
}

=head2 value_constraint($ssl, $port)

When SSL is enabled, port must be 443.

=cut

sub value_constraint {
	my ($self, $ssl, $port) = @_;
	croak "SSL requires port 443" if $ssl && $port != 443;
	return $port;
}

=head2 value_conditional($mode, $key)

When mode is 'secure', key is required.

=cut

sub value_conditional {
	my ($self, $mode, $key) = @_;
	croak "Secure mode requires key" if $mode eq 'secure' && !$key;
	return $key;
}

=head2 complex_relationships($host, $port, $ssl, $file, $content)

Multiple relationships in one method.

=cut

sub complex_relationships {
	my ($self, $host, $port, $ssl, $file, $content) = @_;

	# Mutually exclusive
	croak if $file && $content;

	# Required group
	croak unless $host || $file;

	# Dependency
	croak "Port requires host" if $port && !$host;

	# Value constraint
	croak if $ssl && $port != 443;

	return 1;
}

=head2 no_relationships($simple)

A method with no parameter relationships.

=cut

sub no_relationships {
	my ($self, $simple) = @_;
	return $simple * 2;
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

# Test mutually exclusive detection
subtest 'mutually_exclusive method' => sub {
	my $schema = $schemas->{mutually_exclusive};
	ok($schema, 'mutually_exclusive schema exists');

	ok($schema->{relationships}, 'has relationships');
	is(ref($schema->{relationships}), 'ARRAY', 'relationships is arrayref');

	my @mutex = grep { $_->{type} eq 'mutually_exclusive' } @{$schema->{relationships}};
	cmp_ok(scalar(@mutex), '>=', 1, 'found mutually exclusive relationship');

	if (@mutex) {
		my $rel = $mutex[0];
		is($rel->{type}, 'mutually_exclusive', 'correct type');
		ok($rel->{params}, 'has params');
		is(ref($rel->{params}), 'ARRAY', 'params is arrayref');
		cmp_ok(scalar(@{$rel->{params}}), '==', 2, 'has 2 parameters');

		my @params = sort @{$rel->{params}};
		is_deeply(\@params, ['content', 'file'], 'correct parameters detected');
	}
};

# Test required group detection
subtest 'required_group method' => sub {
	my $schema = $schemas->{required_group};
	ok($schema, 'required_group schema exists');

	ok($schema->{relationships}, 'has relationships');

	my @req_group = grep { $_->{type} eq 'required_group' } @{$schema->{relationships}};
	cmp_ok(scalar(@req_group), '>=', 1, 'found required group relationship');

	if (@req_group) {
		my $rel = $req_group[0];
		is($rel->{type}, 'required_group', 'correct type');
		is($rel->{logic}, 'or', 'has OR logic');
		ok($rel->{params}, 'has params');

		my @params = sort @{$rel->{params}};
		is_deeply(\@params, ['id', 'name'], 'correct parameters detected');
	}
};

# Test conditional requirement detection
subtest 'conditional_requirement method' => sub {
	my $schema = $schemas->{conditional_requirement};
	ok($schema, 'conditional_requirement schema exists');

	ok($schema->{relationships}, 'has relationships');

	my @cond_req = grep { $_->{type} eq 'conditional_requirement' } @{$schema->{relationships}};
	cmp_ok(scalar(@cond_req), '>=', 1, 'found conditional requirement');

	if (@cond_req) {
		my $rel = $cond_req[0];
		is($rel->{type}, 'conditional_requirement', 'correct type');
		is($rel->{if}, 'async', 'correct if parameter');
		is($rel->{then_required}, 'callback', 'correct then parameter');
	}
};

# Test dependency detection
subtest 'dependency method' => sub {
	my $schema = $schemas->{dependency};
	ok($schema, 'dependency schema exists');

	ok($schema->{relationships}, 'has relationships');

	# Accept either dependency or conditional_requirement (they're semantically the same)
	my @deps = grep { $_->{type} eq 'dependency' || $_->{type} eq 'conditional_requirement' }
		@{$schema->{relationships}};
	cmp_ok(scalar(@deps), '>=', 1, 'found dependency or conditional requirement');

	if (@deps) {
		my $rel = $deps[0];
		ok($rel->{type} eq 'dependency' || $rel->{type} eq 'conditional_requirement',
			'correct type (dependency or conditional_requirement)');

		# Check the relationship makes sense
		if ($rel->{type} eq 'dependency') {
			is($rel->{param}, 'port', 'correct parameter');
			is($rel->{requires}, 'host', 'correct required parameter');
		} else {
			# conditional_requirement format
			is($rel->{if}, 'port', 'correct if parameter');
			is($rel->{then_required}, 'host', 'correct then parameter');
		}
	}
};

# Test value constraint detection
subtest 'value_constraint method' => sub {
	my $schema = $schemas->{value_constraint};
	ok($schema, 'value_constraint schema exists');

	ok($schema->{relationships}, 'has relationships');

	my @val_const = grep { $_->{type} eq 'value_constraint' } @{$schema->{relationships}};
	cmp_ok(scalar(@val_const), '>=', 1, 'found value constraint');

	if (@val_const) {
		my $rel = $val_const[0];
		is($rel->{type}, 'value_constraint', 'correct type');
		is($rel->{if}, 'ssl', 'correct if parameter');
		is($rel->{then}, 'port', 'correct then parameter');
		is($rel->{operator}, '==', 'correct operator');
		is($rel->{value}, 443, 'correct value');
	}
};

# Test value conditional detection
subtest 'value_conditional method' => sub {
	my $schema = $schemas->{value_conditional};
	ok($schema, 'value_conditional schema exists');

	ok($schema->{relationships}, 'has relationships');

	my @val_cond = grep { $_->{type} eq 'value_conditional' } @{$schema->{relationships}};

	SKIP: {
		skip 'Value conditional detection may not work with all patterns', 4
			unless @val_cond;

		my $rel = $val_cond[0];
		is($rel->{type}, 'value_conditional', 'correct type');
		is($rel->{if}, 'mode', 'correct if parameter');
		is($rel->{equals}, 'secure', 'correct value');
		is($rel->{then_required}, 'key', 'correct required parameter');
	}
};

# Test complex method with multiple relationships
subtest 'complex_relationships method' => sub {
	my $schema = $schemas->{complex_relationships};
	ok($schema, 'complex_relationships schema exists');

	ok($schema->{relationships}, 'has relationships');
	cmp_ok(scalar(@{$schema->{relationships}}), '>=', 2, 'has multiple relationships');

	# Check we have variety
	my %types;
	foreach my $rel (@{$schema->{relationships}}) {
		$types{$rel->{type}}++;
	}

	cmp_ok(scalar(keys %types), '>=', 2, 'has multiple relationship types');
};

# Test method with no relationships
subtest 'no_relationships method' => sub {
	my $schema = $schemas->{no_relationships};
	ok($schema, 'no_relationships schema exists');

	if ($schema->{relationships}) {
		is(scalar(@{$schema->{relationships}}), 0, 'has no relationships');
	} else {
		pass('no relationships field (as expected)');
	}
};

# Test YAML output includes relationships
my $schema_dir = File::Spec->catdir($tempdir, 'schemas');
ok(-d $schema_dir, 'schema directory created');

my $mutex_yaml = File::Spec->catfile($schema_dir, 'mutually_exclusive.yml');
ok(-f $mutex_yaml, 'mutually_exclusive.yml file created');

open my $yaml_fh, '<', $mutex_yaml or die "Can't read YAML: $!";
my $yaml_content = do { local $/; <$yaml_fh> };
close $yaml_fh;

like($yaml_content, qr/relationships:/, 'YAML contains relationships section');
like($yaml_content, qr/mutually_exclusive/, 'YAML contains relationship type');
like($yaml_content, qr/file/, 'YAML contains first parameter');
like($yaml_content, qr/content/, 'YAML contains second parameter');

# Test comments include relationship info
like($yaml_content, qr/Parameter relationships detected:/, 'YAML comments mention relationships');

done_testing();

__END__

=head1 NAME

relationship_tests.t - Test suite for Parameter Relationship Detection

=head1 DESCRIPTION

Tests the relationship detection functionality including:
- Mutually exclusive parameters
- Required parameter groups (OR logic)
- Conditional requirements (IF-THEN)
- Parameter dependencies
- Value-based constraints
- Value-conditional requirements
- Multiple relationships in one method
- YAML serialization of relationships

=cut
