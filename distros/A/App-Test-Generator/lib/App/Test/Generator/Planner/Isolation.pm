package App::Test::Generator::Planner::Isolation;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

# --------------------------------------------------
# Purity levels from Analyzer::SideEffect
# --------------------------------------------------
Readonly my $PURITY_PURE          => 'pure';
Readonly my $PURITY_SELF_MUTATING => 'self_mutating';

# --------------------------------------------------
# Fixture isolation modes written to the plan output
# --------------------------------------------------
Readonly my $FIXTURE_SHARED   => 'shared_fixture';
Readonly my $FIXTURE_FRESH    => 'fresh_object';
Readonly my $FIXTURE_ISOLATED => 'isolated_block';

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Plans isolation strategy for each method under test, based on side
effect analysis and dependency metadata from the schema. Determines
whether each method needs a shared fixture, a fresh object per test,
or a fully isolated block, and records any environmental dependencies
that need mocking.

=head2 new

Construct a new Isolation planner.

    my $planner = App::Test::Generator::Planner::Isolation->new;

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
        isa  => 'App::Test::Generator::Planner::Isolation',
    }

=cut

sub new { bless {}, shift }

=head2 plan

Produce an isolation plan for each method based on its side effect
analysis and dependency metadata.

    my $planner   = App::Test::Generator::Planner::Isolation->new;
    my $isolation = $planner->plan($schema, $strategy);

    for my $method (keys %{$isolation}) {
        printf "%s fixture: %s\n", $method, $isolation->{$method}{fixture};
    }

=head3 Arguments

=over 4

=item * C<$schema>

A hashref of method schemas, each optionally containing a C<_analysis>
key with C<side_effects> and C<dependencies> sub-keys.

=item * C<$strategy>

A hashref whose keys are the method names to plan isolation for.
Values are not used directly — the hashref is used only for its keys.

=back

=head3 Returns

A hashref mapping method names to isolation plan hashrefs. Each plan
has a C<fixture> key and optionally C<env>, C<filesystem>, C<time>,
and C<network> keys where relevant dependencies were detected.

=head3 API specification

=head4 input

    {
        self     => { type => OBJECT,  isa  => 'App::Test::Generator::Planner::Isolation' },
        schema   => { type => HASHREF },
        strategy => { type => HASHREF },
    }

=head4 output

    {
        type => HASHREF,
        keys => {
            '*' => {
                type => HASHREF,
                keys => {
                    fixture    => { type => SCALAR },
                    env        => { type => HASHREF,  optional => 1 },
                    filesystem => { type => HASHREF,  optional => 1 },
                    time       => { type => SCALAR,   optional => 1 },
                    network    => { type => SCALAR,   optional => 1 },
                },
            },
        },
    }

=cut

sub plan {
	my ($self, $schema, $strategy) = @_;

	# Validate that strategy is a hashref before iterating its keys
	croak 'strategy must be a hashref'
		unless ref($strategy) eq 'HASH';

	my %isolation;

	for my $method (keys %{$strategy}) {
		# Extract side effect and dependency analysis from schema
		# if present — default to empty hashrefs if not available
		my $analysis = $schema->{$method}{_analysis} || {};
		my $effects  = $analysis->{side_effects}     || {};
		my $deps     = $analysis->{dependencies}     || {};

		my %plan;

		# --------------------------------------------------
		# Choose fixture isolation mode based on purity level
		# as determined by Analyzer::SideEffect:
		#   pure          -> shared fixture safe to reuse
		#   self_mutating -> fresh object needed per test
		#   impure        -> full isolation block required
		# --------------------------------------------------
		my $purity = $effects->{purity_level} // '';
		$plan{fixture} =
			$purity eq $PURITY_PURE          ? $FIXTURE_SHARED   :
			$purity eq $PURITY_SELF_MUTATING ? $FIXTURE_FRESH     :
			                                   $FIXTURE_ISOLATED;

		# --------------------------------------------------
		# Record dependency isolation requirements so the
		# test emitter knows what to mock or stub out
		# --------------------------------------------------

		# Environment variable dependencies — pass through
		# the full env hashref for the emitter to use
		$plan{env}        = $deps->{env}        if $deps->{env};

		# Filesystem dependencies — pass through the full
		# filesystem hashref for the emitter to use
		$plan{filesystem} = $deps->{filesystem} if $deps->{filesystem};

		# Time and network are boolean flags — we only care
		# whether they are present, not their value
		$plan{time}    = 1 if $deps->{time};
		$plan{network} = 1 if $deps->{network};

		$isolation{$method} = \%plan;
	}

	return \%isolation;
}

1;
