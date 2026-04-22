package App::Test::Generator::Planner::Fixture;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

# --------------------------------------------------
# Isolation mode that triggers shared fixture reuse
# --------------------------------------------------
Readonly my $MODE_SHARED_FIXTURE => 'shared_fixture';

# --------------------------------------------------
# Fixture mode labels written to the plan output
# --------------------------------------------------
Readonly my $FIXTURE_SHARED       => 'shared';
Readonly my $FIXTURE_NEW_PER_TEST => 'new_per_test';

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Plans fixture setup strategy for each method under test, based on the
isolation requirements provided by
L<App::Test::Generator::Planner::Isolation>. Methods that share state
are assigned a shared fixture; all others get a fresh fixture per test.

=head2 new

Construct a new Fixture planner.

    my $planner = App::Test::Generator::Planner::Fixture->new;

=head3 Arguments

None.

=head3 Returns

A blessed hashref.

=head3 API specification

=head4 input

    {}

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Planner::Fixture',
    }

=cut

sub new {
	my $class = $_[0];
	return bless {}, $class;
}

=head2 plan

Produce a fixture plan for each method based on its isolation mode.
Methods with isolation mode C<shared_fixture> are assigned a shared
fixture; all other methods get a fresh fixture per test.

    my $planner   = App::Test::Generator::Planner::Fixture->new;
    my $fixture   = $planner->plan($schema, $isolation);

    for my $method (keys %{$fixture}) {
        printf "%s: %s\n", $method, $fixture->{$method}{mode};
    }

=head3 Arguments

=over 4

=item * C<$schema>

A hashref representing the module schema. Currently unused but
reserved for future fixture customisation based on schema metadata.

=item * C<$isolation>

A hashref mapping method names to isolation mode strings as produced
by L<App::Test::Generator::Planner::Isolation>.

=back

=head3 Returns

A hashref mapping method names to fixture plan hashrefs, each with a
C<mode> key set to either C<shared> or C<new_per_test>.

=head3 API specification

=head4 input

    {
        self      => { type => OBJECT,  isa     => 'App::Test::Generator::Planner::Fixture' },
        schema    => { type => HASHREF },
        isolation => { type => HASHREF },
    }

=head4 output

    {
        type  => HASHREF,
        keys  => {
            '*' => {
                type => HASHREF,
                keys => { mode => { type => SCALAR } },
            },
        },
    }

=cut

sub plan {
	my ($self, $schema, $isolation) = @_;

	# Validate that isolation is a hashref before iterating
	croak 'isolation must be a hashref' unless ref($isolation) eq 'HASH';

	my %fixture;

	# --------------------------------------------------
	# Assign fixture mode per method based on isolation.
	# Shared fixture mode reuses one object across tests
	# for methods that share state; all others get a
	# fresh object constructed per test case.
	# --------------------------------------------------
	for my $method (keys %{$isolation}) {
		my $mode = $isolation->{$method} eq $MODE_SHARED_FIXTURE
			? $FIXTURE_SHARED
			: $FIXTURE_NEW_PER_TEST;

		$fixture{$method} = { mode => $mode };
	}

	return \%fixture;
}

1;
