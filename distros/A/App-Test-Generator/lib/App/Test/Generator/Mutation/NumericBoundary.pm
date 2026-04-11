package App::Test::Generator::Mutation::NumericBoundary;

use strict;
use warnings;
use parent 'App::Test::Generator::Mutation::Base';

use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.31';

=head1 VERSION

Version 0.31

=cut

sub mutate {
	my ($self, $doc) = @_;

	my $ops = $doc->find('PPI::Token::Operator') || [];
	my @mutants;

	for my $op (@$ops) {
		my $content = $op->content();
		next unless $content =~ /^(>|<|>=|<=|==)$/;

		my $line = $op->location->[0];
		my $original = $op->content();

		my %flip = (
			'>' => ['<', '>=', '<=', '=='],
			'<' => ['>', '<=', '>='],
			'>=' => ['>', '<', '<='],
			'<=' => ['<', '>', '>='],
			'==' => ['!='],
		);

		next unless $flip{$original};

		foreach my $change (@{$flip{$original}}) {
			push @mutants, App::Test::Generator::Mutant->new(
				id => "NUM_BOUNDARY_$line",
				group => "NUM_BOUNDARY:$line",
				description => "Numeric boundary flip $original to $change",
				original => $original,
				transform => sub {
					my $doc = $_[0];

					my $ops = $doc->find('PPI::Token::Operator') || [];

					for my $op (@$ops) {
						next unless $op->line_number == $line;
						next unless $op->content eq $original;

						$op->set_content($change);
						last;
					}
				},
				line => $line,
				type => 'comparison',
			);
		}
	}

	return @mutants;
}

1;
