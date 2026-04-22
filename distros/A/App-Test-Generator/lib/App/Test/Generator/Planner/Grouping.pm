package App::Test::Generator::Planner::Grouping;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

# --------------------------------------------------
# Purity level strings from Analyzer::SideEffect
# --------------------------------------------------
Readonly my $PURITY_PURE          => 'pure';
Readonly my $PURITY_SELF_MUTATING => 'self_mutating';

# --------------------------------------------------
# Group keys in the output plan.
# Note: self_mutating maps to 'mutating' in the
# group key to keep the output API concise.
# --------------------------------------------------
Readonly my $GROUP_PURE     => 'pure';
Readonly my $GROUP_MUTATING => 'mutating';
Readonly my $GROUP_IMPURE   => 'impure';

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Groups methods by their purity level for more efficient test file
organisation. Pure methods can share setup; mutating methods need
per-test objects; impure methods need full isolation blocks.

=head2 new

Construct a new Grouping planner.

    my $planner = App::Test::Generator::Planner::Grouping->new;

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
        isa  => 'App::Test::Generator::Planner::Grouping',
    }

=cut

sub new {
	my $class = $_[0];
	return bless {}, $class;
}

=head2 plan

Group all methods in the schema by their purity level.

    my $planner = App::Test::Generator::Planner::Grouping->new;
    my $groups  = $planner->plan($schema);

    printf "Pure methods:    %s\n", join(', ', @{ $groups->{pure}     });
    printf "Mutating methods:%s\n", join(', ', @{ $groups->{mutating} });
    printf "Impure methods:  %s\n", join(', ', @{ $groups->{impure}   });

=head3 Arguments

=over 4

=item * C<$schema>

A hashref of method schemas each optionally containing a C<_analysis>
key with a C<side_effects> sub-key as produced by
L<App::Test::Generator::Analyzer::SideEffect>.

=back

=head3 Returns

A hashref with three keys — C<pure>, C<mutating>, and C<impure> —
each containing an arrayref of method names assigned to that group.
Methods without purity metadata are placed in C<impure> by default.

Note: the purity level C<self_mutating> from
L<App::Test::Generator::Analyzer::SideEffect> is mapped to the
C<mutating> group key in this output.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT,  isa => 'App::Test::Generator::Planner::Grouping' },
        schema => { type => HASHREF },
    }

=head4 output

    {
        type => HASHREF,
        keys => {
            pure     => { type => ARRAYREF },
            mutating => { type => ARRAYREF },
            impure   => { type => ARRAYREF },
        },
    }

=cut

sub plan {
	my ($self, $schema) = @_;

	# Validate that schema is a hashref before iterating
	croak 'schema must be a hashref'
		unless ref($schema) eq 'HASH';

	# Initialise all three groups so the output always
	# has all three keys even if some groups are empty
	my %groups = (
		$GROUP_PURE     => [],
		$GROUP_MUTATING => [],
		$GROUP_IMPURE   => [],
	);

	for my $method (keys %{$schema}) {
		# Default to empty string if purity_level is absent —
		# missing metadata falls through to the impure group
		my $level = $schema->{$method}{_analysis}{side_effects}{purity_level} // '';

		# Map purity level to group key — self_mutating becomes
		# 'mutating' to keep the output API concise
		my $group =
			$level eq $PURITY_PURE          ? $GROUP_PURE     :
			$level eq $PURITY_SELF_MUTATING ? $GROUP_MUTATING :
			                                  $GROUP_IMPURE;

		push @{ $groups{$group} }, $method;
	}

	return \%groups;
}

1;
