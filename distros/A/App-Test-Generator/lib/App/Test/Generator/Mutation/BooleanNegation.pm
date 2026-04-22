package App::Test::Generator::Mutation::BooleanNegation;

use strict;
use warnings;

use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.33';

=head1 NAME

App::Test::Generator::Mutation::BooleanNegation - Negate boolean return
expressions to expose missing assertion coverage

=head1 VERSION

Version 0.33

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

	# This strategy only targets return statements — other node
	# types cannot produce boolean negation mutants
	return $node->isa('PPI::Statement::Return');
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

	# Find all return statements in the document
	my $returns = $doc->find('PPI::Statement::Return') || [];
	my @mutants;

	for my $ret (@{$returns}) {
		# Skip bare return statements with no expression to negate
		my $expr = $ret->schild(1) or next;

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

					# Find all return statements in the fresh document copy
					my $rets = $doc->find('PPI::Statement::Return') || [];

					for my $ret (@{$rets}) {
						# Match by line and column to avoid mutating
						# the wrong return statement
						next unless $ret->line_number   == $line;
						next unless $ret->column_number == $col;

						# Skip bare returns with no expression
						my $expr = $ret->schild(1) or last;

						# Wrap the expression in logical negation.
						# Operate on the token content directly to
						# avoid PPI document ownership issues that
						# arise when replacing entire statement nodes
						my $content = $expr->content;
						$expr->set_content("!($content)");
						last;
					}
				},
			);
		};

		# If Mutant construction fails, report clearly rather than
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
