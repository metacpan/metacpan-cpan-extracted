package App::Test::Generator::Mutation::BooleanNegation;

use strict;
use warnings;

use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.38';

=head1 NAME

App::Test::Generator::Mutation::BooleanNegation - Negate boolean return
expressions to expose missing assertion coverage

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
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::BooleanNegation' },
        node => { type => OBJECT, isa => 'PPI::Element' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	my ($self, $node) = @_;

	# PPI >= 1.270 classifies return as PPI::Statement::Break
	# rather than PPI::Statement::Return
	return 0 unless $node->isa('PPI::Statement::Break');

	# Must specifically be a return statement, not last/next/redo
	my $first = $node->schild(0) or return 0;
	return $first->content eq 'return';
}

=head2 mutate

Walk a PPI document and generate one mutant for each return statement
whose expression can be negated. For example, C<return $ok> becomes
C<return !($ok)>.

    my $mutation = App::Test::Generator::Mutation::BooleanNegation->new;
    my $doc      = PPI::Document->new(\$source);
    my @mutants  = $mutation->mutate($doc);

    for my $m (@mutants) {
        print $m->id, ': ', $m->description, "\n";
    }

=head3 Arguments

=over 4

=item * C<$self>

An instance of C<App::Test::Generator::Mutation::BooleanNegation>.

=item * C<$doc>

A L<PPI::Document> object representing the parsed source to mutate.
The document is not modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects, one per qualifying
return statement found in the document. Returns an empty list if no
return statements with expressions are found.

Each mutant carries a C<transform> closure that when called with a
fresh L<PPI::Document> copy will wrap the targeted return expression
in C<!( )>, negating its boolean value.

=head3 Notes

Mutant IDs include both line and column number to ensure uniqueness
when multiple return statements appear on different lines of the same
source file.

Only return statements that have an expression child (i.e. not bare
C<return;> statements) are mutated.

=head3 API specification

=head4 input

    {
        self => {
            type => OBJECT,
            isa  => 'App::Test::Generator::Mutation::BooleanNegation',
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
	# (alongside last/next/redo) rather than PPI::Statement::Return.
	# Use a custom predicate to match only 'return' Break nodes.
	my $returns = $doc->find(sub {
		my $node = $_[1];
		# Must be a Break statement -- the parent class for return in
		# newer PPI versions
		return 0 unless $node->isa('PPI::Statement::Break');
		# Distinguish return from last/next/redo by checking the
		# first significant child token
		my $first = $node->schild(0) or return 0;
		return $first->content eq 'return';
	}) || [];

	my @mutants;

	for my $ret (@{$returns}) {
		# Skip bare return statements with no expression to negate.
		# Also skip if the only child after 'return' is a semicolon —
		# PPI may include the statement terminator as a significant child
		my $expr = $ret->schild(1) or next;
		next if $expr->isa('PPI::Token::Structure') && $expr->content eq ';';

		# Skip structure nodes (e.g. return ($x, $y) gives a
		# PPI::Structure::List) — set_content only exists on tokens
		next unless $expr->isa('PPI::Token');

		# Skip postfix conditionals — wrapping 'unless ...' in !() is invalid syntax
		next if $expr->isa('PPI::Token::Word') && $expr->content =~ /^(?:if|unless|while|until|for|foreach)$/;

		# Capture location so the transform closure targets the
		# exact statement rather than the first match on that line
		my $line = $ret->location->[0];
		my $col  = $ret->location->[1];

		# Build a unique ID from line and column so multiple return
		# statements in the same file never collide
		my $id = "BOOL_NEGATE_${line}_${col}";

		my $mutant = eval {
			App::Test::Generator::Mutant->new(
				id          => $id,
				group       => "BOOL_NEGATE:$line",
				description => 'Negate boolean return expression',
				original    => $ret->content,
				line        => $line,
				type        => 'boolean',

				# The transform closure captures line and col so it
				# targets precisely the right return statement in the
				# document copy it receives at test time
				transform => sub {
					my $doc  = $_[0];

					# Locate all return statements in the fresh document copy using
					# the same PPI::Statement::Break predicate as the outer find --
					# PPI >= 1.270 no longer uses PPI::Statement::Return
					my $rets = $doc->find(sub {
						my $node = $_[1];
						# Match Break nodes only -- covers return/last/next/redo
						return 0 unless $node->isa('PPI::Statement::Break');
						# Filter to return specifically by inspecting the first token
						my $first = $node->schild(0) or return 0;
						return $first->content eq 'return';
					}) || [];

					for my $ret (@{$rets}) {
						# Match by line and column to avoid mutating
						# the wrong return statement
						next unless $ret->line_number   == $line;
						next unless $ret->column_number == $col;

						# Skip bare returns with no expression
						my $expr = $ret->schild(1) or last;

						# Skip bare semicolon
						next if $expr->isa('PPI::Token::Structure') && $expr->content eq ';';

						# Skip structure nodes — set_content only exists on tokens
						next unless $expr->isa('PPI::Token');

						# Skip postfix conditionals — wrapping 'unless ...' in !() is invalid syntax
						next if $expr->isa('PPI::Token::Word') && $expr->content =~ /^(?:if|unless|while|until|for|foreach)$/;

						my $content = $expr->content();
						$expr->set_content("!($content)");
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

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational,
Government) must apply in writing for a licence for use from Nigel Horne
at the above e-mail.

=back

=cut

1;
