package App::Test::Generator::Mutation::ConditionalInversion;

use strict;
use warnings;

use parent 'App::Test::Generator::Mutation::Base';

use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.30';

=head1 VERSION

Version 0.30

=cut

sub mutate {
	my ($self, $doc) = @_;

	my $compounds = $doc->find('PPI::Statement::Compound') || [];
	my @mutants;

	for my $stmt (@$compounds) {
		next unless(($stmt->type||'') eq 'if' || ($stmt->type||'') eq 'unless');

		my ($cond) = grep { $_->isa('PPI::Structure::Condition') } $stmt->children;

		next unless $cond;

		push @mutants, App::Test::Generator::Mutant->new(
			id => 'COND_INV_' . $stmt->location->[0],
			group => 'COND_INV:' . $stmt->location->[0],
			description => 'Invert condition',
			line => $stmt->location->[0],
			type => 'boolean',
			original => $cond->content(),
			transform => sub {
				my ($doc) = @_;

				my $stmts = $doc->find('PPI::Statement::Compound') || [];

				for my $stmt (@$stmts) {
					my @children = $stmt->children;
					next unless @children;

					my $first = $children[0];
					next unless $first->isa('PPI::Token::Word');

					if ($first->content eq 'if') {
						$first->set_content('unless');
						last;
					} elsif ($first->content eq 'unless') {
						$first->set_content('if');
						last;
					}
				}
			},
		);
	}

	return @mutants;
}

sub _find_stmt_by_line {
	my ($doc, $line) = @_;
	my $stmts = $doc->find('PPI::Statement::Compound') || [];

	for my $s (@$stmts) {
		return $s if $s->location->[0] == $line;
	}
	return;
}

1;
