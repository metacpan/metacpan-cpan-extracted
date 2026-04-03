package App::Test::Generator::Planner::Isolation;

use strict;
use warnings;

our $VERSION = '0.30';

=head1 VERSION

Version 0.30

=cut

sub new { bless {}, shift }

sub plan {
	my ($self, $schema, $strategy) = @_;

	my %isolation;

	foreach my $method (keys %$strategy) {
		my $analysis = $schema->{$method}{_analysis} || {};
		my $effects  = $analysis->{side_effects}     || {};
		my $deps     = $analysis->{dependencies}     || {};

		my %plan;

    # --- fixture choice (existing behaviour) ---

    if (($effects->{purity_level}||'') eq 'pure') {
        $plan{fixture} = 'shared_fixture';
    }
    elsif (($effects->{purity_level}||'') eq 'self_mutating') {
        $plan{fixture} = 'fresh_object';
    }
    else {
        $plan{fixture} = 'isolated_block';
    }

    # --- NEW: dependency isolation ---

    if (my $env = $deps->{env}) {
        $plan{env} = $env;
    }

    if (my $fs = $deps->{filesystem}) {
        $plan{filesystem} = $fs;
    }

    if (my $time = $deps->{time}) {
        $plan{time} = 1;
    }

    if (my $net = $deps->{network}) {
        $plan{network} = 1;
    }

		$isolation{$method} = \%plan;
	}

	return \%isolation;
}

1;
