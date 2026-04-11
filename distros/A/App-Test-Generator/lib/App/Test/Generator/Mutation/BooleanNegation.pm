package App::Test::Generator::Mutation::BooleanNegation;

use strict;
use warnings;
use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;

use PPI;

our $VERSION = '0.31';

=head1 VERSION

Version 0.31

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
		my $expr = $ret->schild(1) or next;

		my $original = $ret->content;
		my $line     = $ret->location->[0];

		push @mutants, App::Test::Generator::Mutant->new(
			id          => "BOOL_NEGATE_$line",
			group          => "BOOL_NEGATE:$line",
			description => 'Negate return expression',
            original    => $original,
            transform => sub {
		my $doc = $_[0];

		my $stmt = _find_stmt_by_line($doc, $line) or return;

		# Example simple rewrite:
		$stmt->replace(
			PPI::Statement->new("return !($expr->content);")
		);
	},
            line        => $line,
	    type => 'boolean'
        );
    }

    return @mutants;
}

1;
