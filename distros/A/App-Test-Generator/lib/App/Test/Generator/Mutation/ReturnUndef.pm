package App::Test::Generator::Mutation::ReturnUndef;

use strict;
use warnings;
use parent 'App::Test::Generator::Mutation::Base';

use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.32';

=head1 VERSION

Version 0.32

=cut

sub applies_to {
	my ($self, $node) = @_;
	return $node->isa('PPI::Statement::Return');
}

sub mutate {
	my ($self, $doc) = @_;

	my $returns = $doc->find('PPI::Statement::Return') || [];
	my @mutants;

	for my $ret (@$returns) {
		my $original = $ret->content();
		my $line = $ret->location->[0];

		push @mutants, App::Test::Generator::Mutant->new(
			id => "RETURN_UNDEF_$line",
			group => "RETURN_UNDEF:$line",
			description => 'Force return undef',
			line => $line,
			original => $original,
			type => 'return',
			transform => sub {
				my $doc = $_[0];

				my $stmt = _find_stmt_by_line($doc, $line) or return;

				$stmt->replace(PPI::Statement->new('return undef;'));
			},
		);
	}

	return @mutants;
}

1;
