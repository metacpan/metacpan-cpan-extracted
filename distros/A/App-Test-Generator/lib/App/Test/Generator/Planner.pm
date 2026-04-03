package App::Test::Generator::Planner;

use strict;
use warnings;

use App::Test::Generator::TestStrategy;
use App::Test::Generator::Planner::Isolation;
use App::Test::Generator::Planner::Fixture;
use App::Test::Generator::Planner::Mock;
use App::Test::Generator::Planner::Grouping;

our $VERSION = '0.30';

=head1 VERSION

Version 0.30

=cut

sub new {
	my ($class, %args) = @_;
	bless {
		schemas  => $args{schemas},
		package => $args{package},
	}, $class;
}

sub plan_all {
	my $self = $_[0];

	my $global = $self->build_plan();

	my %method_plan;

	foreach my $method (keys %{ $self->{schemas} }) {

		my $schema = $self->{schemas}{$method};

		my %plan;

		# -----------------------------------
		# Strategy mapping
		# -----------------------------------

        if ($schema->{accessor} && $schema->{accessor}->{type}) {

            if ($schema->{accessor}->{type} eq 'get') {
                $plan{getter_test} = 1;
            }

            elsif ($schema->{accessor}->{type} eq 'getset') {
                $plan{getset_test} = 1;
            }

            elsif ($schema->{accessor}->{type} eq 'injector') {
                $plan{object_injection_test} = 1;
            }
        }

        if ($schema->{output}->{type} && $schema->{output}->{type} eq 'boolean') {

            $plan{boolean_test} = 1;
        }

        $method_plan{$method} = \%plan;
    }

die Dumper(\%method_plan);
	return \%method_plan;
}

sub build_plan {
	my $self = $_[0];

	# Strategy
	my $strategy_engine = App::Test::Generator::TestStrategy->new(schema => $self->{schemas});

	my $strategy = $strategy_engine->generate_plan();

	# Isolation
	my $isolation = App::Test::Generator::Planner::Isolation->new()->plan($self->{schemas}, $strategy);

	# Fixture
	my $fixture = App::Test::Generator::Planner::Fixture->new()->plan($self->{schemas}, $isolation);

	# Mock
	my $mock = App::Test::Generator::Planner::Mock->new()->plan($self->{schemas});

	# Grouping
	my $groups = App::Test::Generator::Planner::Grouping->new()->plan($self->{schemas});

	return {
		strategy  => $strategy,
		isolation => $isolation,
		fixture   => $fixture,
		mock      => $mock,
		groups    => $groups,
	};
}

1;

