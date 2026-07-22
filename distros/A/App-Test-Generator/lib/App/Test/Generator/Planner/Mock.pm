package App::Test::Generator::Planner::Mock;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

# --------------------------------------------------
# Mock strategy labels written to the plan output.
# mock_system is used when a method calls external
# commands; capture_io when it performs IO operations.
# A method needing both gets an arrayref of both labels
# — see note in plan() below.
# --------------------------------------------------
Readonly my $MOCK_SYSTEM     => 'mock_system';
Readonly my $MOCK_CAPTURE_IO => 'capture_io';

our $VERSION = '0.44';

=head1 VERSION

Version 0.44

=head1 DESCRIPTION

Plans mock strategy for each method that has external side effects,
based on side effect analysis metadata in the schema. Methods that
call external commands are assigned a system mock; methods that
perform IO are assigned IO capture. Used by
L<App::Test::Generator::Emitter::Perl> to generate appropriate mock
setup code in the test output.

=head2 new

Construct a new Mock planner.

    my $planner = App::Test::Generator::Planner::Mock->new;

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
        isa  => 'App::Test::Generator::Planner::Mock',
    }

=cut

sub new { bless {}, shift }

=head2 plan

Produce a mock plan for each method that requires external mocking,
based on side effect analysis metadata in the schema.

    my $planner   = App::Test::Generator::Planner::Mock->new;
    my $mock_plan = $planner->plan($schema);

    for my $method (keys %{$mock_plan}) {
        printf "%s: %s\n", $method, $mock_plan->{$method};
    }

=head3 Arguments

=over 4

=item * C<$schema>

A hashref of method schemas, each optionally containing a
C<_analysis> key with a C<side_effects> sub-key as produced by
L<App::Test::Generator::Analyzer::SideEffect>.

=back

=head3 Returns

A hashref mapping method names to a mock strategy. Only methods that
require mocking appear in the output — pure methods are omitted.

Currently supported strategy values are C<mock_system> and
C<capture_io>. A method needing only one of these gets that value as
a plain scalar string. A method that both calls external commands and
performs IO needs both mocks applied, so it gets an arrayref
C<[mock_system, capture_io]> instead of a single string.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT,  isa => 'App::Test::Generator::Planner::Mock' },
        schema => { type => HASHREF },
    }

=head4 output

    {
        type => HASHREF,
        keys => {
            '*' => { type => 'scalar | arrayref' },
        },
    }

=cut

sub plan {
	my ($self, $schema) = @_;

	# Validate that schema is a hashref before iterating
	croak 'schema must be a hashref' unless ref($schema) eq 'HASH';

	my %mock_plan;

	for my $method (keys %{$schema}) {
		# Extract side effect analysis if present —
		# default to empty hashref if not available
		my $effects = $schema->{$method}{_analysis}{side_effects} || {};

		# --------------------------------------------------
		# Assign mock strategy based on detected side effects.
		# A method needing both gets an arrayref of both labels
		# rather than silently dropping one of them.
		# --------------------------------------------------
		if($effects->{calls_external} && $effects->{performs_io}) {
			$mock_plan{$method} = [$MOCK_SYSTEM, $MOCK_CAPTURE_IO];
		} elsif($effects->{calls_external}) {
			$mock_plan{$method} = $MOCK_SYSTEM;
		} elsif($effects->{performs_io}) {
			$mock_plan{$method} = $MOCK_CAPTURE_IO;
		}
		# Pure methods require no mocking — omit from plan
	}

	return \%mock_plan;
}

1;
