package App::Test::Generator::Planner;

use strict;
use warnings;
use Carp qw(croak);
use Readonly;

use App::Test::Generator::TestStrategy;
use App::Test::Generator::Planner::Isolation;
use App::Test::Generator::Planner::Fixture;
use App::Test::Generator::Planner::Mock;
use App::Test::Generator::Planner::Grouping;

our $VERSION = '0.44';

# Accessor type strings used in plan_all() strategy mapping
Readonly my $ACCESSOR_GET      => 'get';
Readonly my $ACCESSOR_GETSET   => 'getset';
Readonly my $ACCESSOR_INJECTOR => 'injector';

# Output type string for boolean detection
Readonly my $OUTPUT_BOOLEAN => 'boolean';

=head1 VERSION

Version 0.44

=head2 new

Construct a new Planner instance.

    my $planner = App::Test::Generator::Planner->new(
        schemas => \%schemas,
        package => 'My::Module',
    );

=head3 Arguments

=over 4

=item * C<schemas> - hashref of method name to schema hashref. Required.

=item * C<package> - the Perl package name of the module under test. Required.

=back

=head3 Returns

A blessed hashref. Croaks if C<schemas> or C<package> is missing.

=head3 API specification

=head4 input

    {
        schemas => { type => HASHREF },
        package => { type => SCALAR  },
    }

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Planner',
    }

=cut

sub new {
	my ($class, %args) = @_;

	# schemas and package are required for meaningful planning
	croak 'schemas required' unless defined $args{schemas};
	croak 'package required' unless defined $args{package};

	return bless {
		schemas => $args{schemas},
		package => $args{package},
	}, $class;
}

=head2 plan_all

Generate a test plan for every method in the schema.

    my $plans = $planner->plan_all();

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A hashref mapping method name to a plan hashref. Each plan hashref
contains boolean flags such as C<getter_test>, C<getset_test>,
C<object_injection_test>, and C<boolean_test> indicating which test
types should be emitted for that method.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Planner' },
    }

=head4 output

    { type => HASHREF }

=cut

sub plan_all {
	my $self = $_[0];
	my %method_plan;

	# Build a plan for each method in the schema
	foreach my $method (keys %{ $self->{schemas} }) {
		my $schema = $self->{schemas}{$method};
		my %plan;

		# Map accessor type to the appropriate test flag
		if($schema->{accessor} && $schema->{accessor}->{type}) {
			my $type = $schema->{accessor}->{type};
			if($type eq $ACCESSOR_GET) {
				$plan{getter_test} = 1;
			} elsif($type eq $ACCESSOR_GETSET) {
				$plan{getset_test} = 1;
			} elsif($type eq $ACCESSOR_INJECTOR) {
				# Object injection requires a mock object in the test
				$plan{object_injection_test} = 1;
			}
		}

		# Boolean output type requires a predicate test
		if($schema->{output}->{type} && $schema->{output}->{type} eq $OUTPUT_BOOLEAN) {
			$plan{boolean_test} = 1;
		}

		$method_plan{$method} = \%plan;
	}

	return \%method_plan;
}

=head2 build_plan

Build a comprehensive test plan by running the schema through all
available planning subsystems in sequence: strategy generation,
isolation, fixture, mock, and grouping.

    my $plan = $planner->build_plan();

=head3 Arguments

None beyond C<$self>.

=head3 Returns

A hashref with five keys: C<strategy> (from
L<App::Test::Generator::TestStrategy/generate_plan>), C<isolation>
(from L<App::Test::Generator::Planner::Isolation/plan>, given the
strategy as context), C<fixture> (from
L<App::Test::Generator::Planner::Fixture/plan>, given the isolation
plan as context), C<mock> (from
L<App::Test::Generator::Planner::Mock/plan>), and C<groups> (from
L<App::Test::Generator::Planner::Grouping/plan>).

=head3 Notes

Unlike C<plan_all>, which is the planner actually used by the test
generation pipeline, C<build_plan> is not currently called anywhere
else in this distribution. It is kept as a public entry point for
the richer combined plan it produces.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Planner' },
    }

=head4 output

    { type => HASHREF }

=cut

sub build_plan {
	my $self = $_[0];

	# Generate the base strategy from the schema
	my $strategy_engine = App::Test::Generator::TestStrategy->new(
		schema => $self->{schemas}
	);
	my $strategy = $strategy_engine->generate_plan();

	# Apply isolation, fixture, mock and grouping layers
	my $isolation = App::Test::Generator::Planner::Isolation->new()->plan(
		$self->{schemas}, $strategy
	);
	my $fixture = App::Test::Generator::Planner::Fixture->new()->plan(
		$self->{schemas}, $isolation
	);
	my $mock   = App::Test::Generator::Planner::Mock->new()->plan($self->{schemas});
	my $groups = App::Test::Generator::Planner::Grouping->new()->plan($self->{schemas});

	return {
		strategy  => $strategy,
		isolation => $isolation,
		fixture   => $fixture,
		mock      => $mock,
		groups    => $groups,
	};
}

=head1 AUTHOR

Nigel Horne

=cut

1;
