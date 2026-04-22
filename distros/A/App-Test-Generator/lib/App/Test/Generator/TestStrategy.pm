package App::Test::Generator::TestStrategy;

use strict;
use warnings;
use Readonly;

# --------------------------------------------------
# Accessor type strings from the schema
# --------------------------------------------------
Readonly my $ACCESSOR_GETTER   => 'getter';
Readonly my $ACCESSOR_SETTER   => 'setter';
Readonly my $ACCESSOR_GETSET   => 'getset';

# --------------------------------------------------
# Output type strings from the schema
# --------------------------------------------------
Readonly my $TYPE_BOOLEAN => 'boolean';
Readonly my $TYPE_OBJECT  => 'object';
Readonly my $TYPE_VOID    => 'void';

# --------------------------------------------------
# Default confidence threshold for plan generation
# --------------------------------------------------
Readonly my $DEFAULT_CONFIDENCE => 'medium';

# --------------------------------------------------
# Test plan flag keys written to the method plan
# --------------------------------------------------
Readonly my $TEST_CONTEXT         => 'context_tests';
Readonly my $TEST_PREDICATE       => 'predicate_test';
Readonly my $TEST_GETTER          => 'getter_test';
Readonly my $TEST_SETTER          => 'setter_test';
Readonly my $TEST_GETSET          => 'getset_test';
Readonly my $TEST_OBJECT_INJECT   => 'object_injection_test';
Readonly my $TEST_BOOLEAN_SET     => 'boolean_set_test';
Readonly my $TEST_VOID            => 'void_context_test';
Readonly my $TEST_ERROR_HANDLING  => 'error_handling_test';
Readonly my $TEST_BOUNDARY        => 'boundary_tests';
Readonly my $TEST_CHAINING        => 'chaining_test';
Readonly my $TEST_BASIC           => 'basic_test';

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Generates a test strategy plan for all methods in a schema, determining
which test types should be produced for each method based on its
accessor classification, output type, side effects, and other metadata.

=head2 new

Construct a new TestStrategy.

    my $strategy = App::Test::Generator::TestStrategy->new(
        schema     => \%schemas,
        thresholds => { confidence => 'high' },
    );

=head3 Arguments

=over 4

=item * C<schema>

A hashref of method name to schema hashref. Optional — defaults to
an empty hashref.

=item * C<thresholds>

A hashref of threshold configuration. Optional — defaults to
C<< { confidence => 'medium' } >>.

=back

=head3 Returns

A blessed hashref.

=head3 API specification

=head4 input

    {
        schema     => { type => HASHREF, optional => 1 },
        thresholds => { type => HASHREF, optional => 1 },
    }

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::TestStrategy',
    }

=cut

sub new {
	my ($class, %args) = @_;
	return bless {
		schema     => $args{schema}     || {},
		thresholds => $args{thresholds} || { confidence => $DEFAULT_CONFIDENCE },
		plans      => {},
	}, $class;
}

=head2 generate_plan

Generate a test plan for all methods in the schema and return it as
a hashref mapping method names to plan hashrefs.

    my $strategy = App::Test::Generator::TestStrategy->new(
        schema => \%schemas,
    );
    my $plan = $strategy->generate_plan;

    for my $method (keys %{$plan}) {
        print "$method: ", join(', ', keys %{ $plan->{$method} }), "\n";
    }

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A hashref mapping method names to test plan hashrefs, each containing
boolean flags for the test types that should be generated.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::TestStrategy' },
    }

=head4 output

    {
        type => HASHREF,
        keys => {
            '*' => { type => HASHREF },
        },
    }

=cut

sub generate_plan {
	my $self = $_[0];

	for my $method (keys %{ $self->{schema} }) {
		my $schema = $self->{schema}{$method};

		# Extract analysis metadata from the schema — note that
		# $schema is already the per-method hashref so we access
		# _analysis directly, not via the method name key again
		my $analysis = $schema->{_analysis}          || {};
		my $effects  = $analysis->{side_effects}     || {};
		my $deps     = $analysis->{dependencies}     || {};

		# Generate and store the plan for this method
		$self->{plans}{$method} = $self->_plan_for_method($schema);
	}

	return $self->{plans};
}

# --------------------------------------------------
# _plan_for_method
#
# Purpose:    Determine which test types should be
#             generated for a single method based on
#             its schema metadata.
#
# Entry:      $schema - the per-method schema hashref
#
# Exit:       Returns a hashref of test type flags.
#             Always contains at least basic_test => 1.
#
# Side effects: None.
#
# Notes:      All string comparisons use // '' guards
#             to avoid uninitialized value warnings
#             when schema fields are absent.
# --------------------------------------------------
sub _plan_for_method {
	my ($self, $schema) = @_;

	my %plan;

	# --------------------------------------------------
	# Context-aware returns need both scalar and list
	# context tests to verify correct behaviour in each
	# --------------------------------------------------
	if($schema->{output}{_context_aware}) {
		$plan{$TEST_CONTEXT} = 1;
	}

	# --------------------------------------------------
	# Accessor detection — choose test types based on
	# whether the method is a getter, setter, or both
	# --------------------------------------------------
	if($schema->{accessor} && scalar keys %{ $schema->{accessor} }) {
		my $acc_type = $schema->{accessor}{type} // '';

		if($acc_type eq $ACCESSOR_GETTER) {
			# Boolean getters are predicates and need
			# truthy/falsy tests in addition to getter tests
			if(($schema->{output}{type} // '') eq $TYPE_BOOLEAN) {
				$plan{$TEST_PREDICATE} = 1;
			}
			$plan{$TEST_GETTER} = 1;

		} elsif($acc_type eq $ACCESSOR_SETTER) {
			$plan{$TEST_SETTER} = 1;

		} elsif($acc_type eq $ACCESSOR_GETSET) {
			# For getset accessors, check the input parameter
			# type to determine if object injection or boolean
			# set tests are more appropriate
			my ($param) = grep { !/^_/ } keys %{ $schema->{input} || {} };
			my $param_type = ($param && $schema->{input}{$param}{type}) // '';

			if($param_type eq $TYPE_OBJECT) {
				$plan{$TEST_OBJECT_INJECT} = 1;
			} elsif($param_type eq $TYPE_BOOLEAN) {
				$plan{$TEST_BOOLEAN_SET} = 1;
			}
			$plan{$TEST_GETSET} = 1;
		}
	}

	# --------------------------------------------------
	# Void return type — verify the method returns nothing
	# and does not accidentally return a useful value
	# --------------------------------------------------
	if(($schema->{output}{type} // '') eq $TYPE_VOID) {
		$plan{$TEST_VOID} = 1;
	}

	# --------------------------------------------------
	# Error handling — verify error return conventions
	# are tested explicitly
	# --------------------------------------------------
	if($schema->{output}{_error_return}
	|| $schema->{output}{success_failure_pattern}) {
		$plan{$TEST_ERROR_HANDLING} = 1;
	}

	# --------------------------------------------------
	# Boundary hints from YAML test configuration —
	# generate boundary/equivalence class tests
	# --------------------------------------------------
	if($schema->{_yamltest_hints} && keys %{ $schema->{_yamltest_hints} }) {
		$plan{$TEST_BOUNDARY} = 1;
	}

	# --------------------------------------------------
	# Method chaining — verify that $self is returned
	# and that calls can be chained
	# --------------------------------------------------
	if($schema->{output}{_returns_self}) {
		$plan{$TEST_CHAINING} = 1;
	}

	# --------------------------------------------------
	# Boolean output — needs predicate tests regardless
	# of whether an accessor was detected
	# --------------------------------------------------
	if(($schema->{output}{type} // '') eq $TYPE_BOOLEAN) {
		$plan{$TEST_PREDICATE} = 1;
	}

	# --------------------------------------------------
	# Always generate at least a basic call test even
	# if no other test types were identified
	# --------------------------------------------------
	$plan{$TEST_BASIC} = 1 unless %plan;

	return \%plan;
}

1;
