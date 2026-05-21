package App::Test::Generator::Mutation::ReturnUndef;

use strict;
use warnings;
use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.38';

=head1 NAME

App::Test::Generator::Mutation::ReturnUndef - Replace return expressions
with undef to expose missing undef-return checks in the test suite

=head1 VERSION

Version 0.38

=head1 METHODS

=head2 applies_to

Return true if this mutation strategy applies to the given PPI node.
Used by the mutation framework to pre-filter nodes before calling
C<mutate>.

    my $applies = $mutation->applies_to($node);

=head3 Arguments

=over 4

=item * C<$node>

A L<PPI::Element> node to test.

=back

=head3 Returns

True if the node is a C<PPI::Statement::Return>, false otherwise.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::ReturnUndef' },
        node => { type => OBJECT, isa => 'PPI::Element' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	my ($self, $node) = @_;

	# PPI >= 1.270 classifies return as PPI::Statement::Break
	# rather than the dedicated PPI::Statement::Return class
	return 0 unless $node->isa('PPI::Statement::Break');

	# Confirm it is specifically a return statement and not
	# last, next, or redo which are also PPI::Statement::Break
	my $first = $node->schild(0) or return 0;
	return $first->content eq 'return';
}

=head2 mutate

Walk a PPI document and generate one mutant for each non-bare return
statement, replacing its expression with C<undef>. For example,
C<return $result> becomes C<return undef>.

Bare C<return;> statements are skipped because they already return
undef - mutating them would produce a redundant mutant that can never
be killed.

    my $mutation = App::Test::Generator::Mutation::ReturnUndef->new;
    my $doc      = PPI::Document->new(\$source);
    my @mutants  = $mutation->mutate($doc);

    for my $m (@mutants) {
        print $m->id, ': ', $m->description, "\n";
    }

=head3 Arguments

=over 4

=item * C<$self>

An instance of C<App::Test::Generator::Mutation::ReturnUndef>.

=item * C<$doc>

A L<PPI::Document> object representing the parsed source to mutate.
The document is not modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects, one per qualifying
return statement found in the document. Returns an empty list if no
non-bare return statements are found.

Each mutant carries a C<transform> closure that when called with a
fresh L<PPI::Document> copy will replace the targeted return expression
with the literal C<undef>.

=head3 Notes

Mutant IDs include both line and column number to ensure uniqueness
when multiple return statements appear in the same source file.

Only return statements with an expression child are mutated - bare
C<return;> statements are skipped as they already return undef.

=head3 API specification

=head4 input

    {
        self => {
            type => OBJECT,
            isa  => 'App::Test::Generator::Mutation::ReturnUndef',
        },
        doc => {
            type => OBJECT,
            isa  => 'PPI::Document',
        },
    }

=head4 output

    {
        type     => ARRAYREF,
        elements => {
            type => OBJECT,
            isa  => 'App::Test::Generator::Mutant',
        },
    }

=cut

sub mutate {
	my ($self, $doc) = @_;

	# PPI >= 1.270 classifies return statements as PPI::Statement::Break
	# rather than PPI::Statement::Return -- use a custom predicate
	my $returns = $doc->find(sub {
		my $node = $_[1];
		# Match Break nodes that are specifically return statements
		return 0 unless $node->isa('PPI::Statement::Break');
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];

	my @mutants;

	for my $ret (@{$returns}) {
		# Skip bare return statements — they already return undef
		# so mutating them would produce a redundant mutant that
		# can never be killed by any meaningful test
		my $expr = $ret->schild(1) or next;

		# Skip bare semicolon — PPI may include the statement
		# terminator as a significant child on bare returns
		next if $expr->isa('PPI::Token::Structure') && $expr->content eq ';';
		# Skip structure nodes (e.g. return ($x, $y) gives a
		# PPI::Structure::List) — we can only mutate token expressions
		next unless $expr->isa('PPI::Token');

		# Skip postfix conditionals — replacing 'unless ...' with undef is invalid syntax
		next if $expr->isa('PPI::Token::Word') && $expr->content =~ /^(?:if|unless|while|until|for|foreach)$/;

		# Capture location so the transform closure targets the
		# exact statement rather than the first match on that line
		my $line = $ret->location->[0];
		my $col  = $ret->location->[1];

		# Build a unique ID from line and column so multiple return
		# statements in the same file never collide
		my $id = "RETURN_UNDEF_${line}_${col}";

		my $mutant = eval {
			App::Test::Generator::Mutant->new(
				id          => $id,
				group       => "RETURN_UNDEF:$line",
				description => 'Replace return expression with undef',
				original    => $ret->content(),
				line        => $line,
				type        => 'return',

				# The transform closure captures line and col so it
				# targets precisely the right return statement in the
				# document copy it receives at test time
				transform => sub {
					my $doc  = $_[0];
					# PPI >= 1.270 uses PPI::Statement::Break for return
					my $rets = $doc->find(sub {
						my $node = $_[1];
						return 0 unless $node->isa('PPI::Statement::Break');
						my $first = $node->schild(0) or return 0;
						return $first->content eq 'return';
						}) || [];
					for my $ret (@{$rets}) {
						next unless $ret->line_number   == $line;
						next unless $ret->column_number == $col;
						my $expr = $ret->schild(1) or last;

						# Skip bare semicolon — already returns undef
						next if $expr->isa('PPI::Token::Structure') && $expr->content eq ';';

						# Skip structure nodes (e.g. PPI::Structure::List from
						# return ($x, $y)) — set_content only exists on tokens
						next unless $expr->isa('PPI::Token');

						# Skip postfix conditionals — replacing 'unless ...' with undef is invalid syntax
						next if $expr->isa('PPI::Token::Word') && $expr->content =~ /^(?:if|unless|while|until|for|foreach)$/;

						$expr->set_content('undef');
						last;
					}
				},
			);
		};

		# If the Mutant construction fails, report clearly rather than
		# silently dropping the mutant from the results
		if($@ || !$mutant) {
			warn "Failed to construct mutant $id: $@" if $@;
			next;
		}

		push @mutants, $mutant;
	}

	return @mutants;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
