package App::Test::Generator::TestStrategy;

use strict;
use warnings;
use Carp;

our $VERSION = '0.32';

=head1 VERSION

Version 0.32

=cut

# Constructor
sub new {
	my ($class, %args) = @_;
	my $self = bless {
		schema => $args{schema} || {},
		thresholds => $args{thresholds} || { confidence => 'medium' },
		plans => {},
	}, $class;
	return $self;
}

# Main entry: generate a test plan for all methods
sub generate_plan {
	my ($self) = @_;

	foreach my $method (keys %{ $self->{schema} }) {
		my $schema = $self->{schema}{$method};

		my $analysis = $schema->{$method}{_analysis} || {};
		my $effects = $analysis->{side_effects} || {};
		my $deps = $analysis->{dependencies} || {};

		# next if (($effects->{purity_level}||'') ne 'pure') && !exists $deps->{env};

		$self->{plans}{$method} = $self->_plan_for_method($schema);
	}

	return $self->{plans};
}

sub _plan_for_method {
	my ($self, $schema) = @_;

	my %plan;

	# Context-aware returns
	if ($schema->{output}{_context_aware}) {
		$plan{context_tests} = 1;
	}

	# Getter/setter detection
	if($schema->{accessor} && (scalar keys(%{$schema->{accessor}}))) {
		if ($schema->{accessor}{type} eq 'getter') {
			if(($schema->{output}{type}||'') eq 'boolean') {
				$plan{predicate_test} = 1;
			}
			$plan{getter_test} = 1;
		} elsif ($schema->{accessor}{type} eq 'setter') {
			$plan{setter_test} = 1;
		} elsif ($schema->{accessor}{type} eq 'getset') {
			my ($param) = grep { $_ !~ /^_/ } keys %{ $schema->{input} || {} };
			if ($param && $schema->{input} && ($schema->{input}{$param}{type} eq 'object')) {
				$plan{object_injection_test} = 1;
			} elsif($param && $schema->{input}{$param}{type} eq 'boolean') {
				$plan{boolean_set_test} = 1;
			}
			$plan{getset_test} = 1;
		}
	}

	# Void or mutator detection
	if ($schema->{output}{type} && $schema->{output}{type} eq 'void') {
		$plan{void_context_test} = 1;
	}

	# Error handling / return conventions
	if ($schema->{output}{_error_return} || $schema->{output}{success_failure_pattern}) {
		$plan{error_handling_test} = 1;
	}

	# Boundary / equivalence class hints
	if ($schema->{_yamltest_hints} && keys %{ $schema->{_yamltest_hints} }) {
		$plan{boundary_tests} = 1;
	}

	# Method chaining / returns self
	if ($schema->{output}{_returns_self}) {
		$plan{chaining_test} = 1;
	}

	if ($schema->{output}{type} eq 'boolean') {
		$plan{predicate_test} = 1;
	}

	# Default: basic call with typical inputs
	$plan{basic_test} = 1 unless %plan;	# Always at least one test

	return \%plan;
}

1;
