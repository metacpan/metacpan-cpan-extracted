package App::Test::Generator::Mutation::ConditionalInversion;

use strict;
use warnings;
use Carp qw(croak);
use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.41';

=head1 VERSION

Version 0.41

=head1 METHODS

=head2 applies_to

Returns true if the document contains any C<if> or C<unless> compound
statements that this mutator can target.

=head3 Arguments

=over 4

=item * C<$doc>

A L<PPI::Document> object to inspect.

=back

=head3 Returns

A boolean.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::ConditionalInversion' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	my ($self, $doc) = @_;
	my $compounds = $doc->find('PPI::Statement::Compound') || [];
	for my $stmt (@{$compounds}) {
		my $first = $stmt->schild(0);
		next unless $first && $first->isa('PPI::Token::Word');
		my $type = $first->content();
		return 1 if $type eq 'if' || $type eq 'unless';
	}
	return 0;
}

=head2 mutate

Walk a PPI document and generate one mutant for each C<if> or C<unless>
statement, inverting the keyword to its opposite. This detects cases where
the test suite does not exercise both branches of a conditional.

    my $mutation = App::Test::Generator::Mutation::ConditionalInversion->new;
    my $doc      = PPI::Document->new(\$source);
    my @mutants  = $mutation->mutate($doc);

    for my $m (@mutants) {
        print $m->id, ': ', $m->description, "\n";
    }

=head3 Arguments

=over 4

=item * C<$self>

An instance of C<App::Test::Generator::Mutation::ConditionalInversion>.

=item * C<$doc>

A L<PPI::Document> object representing the parsed source file to mutate.
The document is not modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects, one per C<if> or
C<unless> statement found in the document. Returns an empty list if no
qualifying statements are found.

Each mutant carries a C<transform> closure that when called with a fresh
L<PPI::Document> copy will flip the targeted keyword from C<if> to
C<unless> or vice versa, targeting the exact statement by line and column
number.

=head3 Notes

Multiple conditionals on the same source line are each mutated
independently. Mutant IDs include both line and column number to ensure
uniqueness.

Each mutant's optional C<context> field is always set to
C<conditional> (every mutant produced by this strategy targets an
C<if>/C<unless> keyword); its C<line_content> field holds the raw
source text of the mutated line. Both are consumed by
L<App::Test::Generator::Mutator>'s fast-mode dedup.

=head3 API specification

=head4 input

    {
        self => {
            type => OBJECT,
            isa  => 'App::Test::Generator::Mutation::ConditionalInversion',
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

	# Find all compound statements in the document
	my $compounds = $doc->find('PPI::Statement::Compound') || [];
	my @mutants;

	for my $stmt (@{$compounds}) {
		# Only process if and unless statements
		# Use the actual first token content rather than ->type() since
		# PPI >= 1.270 returns 'if' for both if and unless via ->type()
		my $first_word = $stmt->schild(0);
		next unless $first_word && $first_word->isa('PPI::Token::Word');
		my $type = $first_word->content();
		next unless $type eq 'if' || $type eq 'unless';

		# Verify the statement has a condition block to invert
		my ($cond) = grep { $_->isa('PPI::Structure::Condition') } $stmt->children;
		next unless $cond;

		# Capture location for precise targeting in the transform closure
		my $line = $stmt->location->[0];
		my $col  = $stmt->location->[1];

		# Determine what the keyword flips to
		my $flipped = $type eq 'if' ? 'unless' : 'if';

		my $mutant = eval {
			App::Test::Generator::Mutant->new(
				id           => "COND_INV_${line}_${col}",
				group        => "COND_INV:$line",
				description  => "Invert condition $type to $flipped",
				line         => $line,
				type         => 'boolean',
				original     => $cond->content(),
				context      => 'conditional',
				line_content => $self->_line_content($doc, $line),

				# Closure captures line, col and flipped so it targets
				# exactly the right statement in the document copy
				transform   => sub {
					my ($doc) = @_;
					my $stmts = $doc->find('PPI::Statement::Compound') || [];

					for my $stmt (@{$stmts}) {
						# Match by line and column to avoid mutating
						# the wrong conditional on the same line
						next unless $stmt->location->[0] == $line;
						next unless $stmt->location->[1] == $col;

						# Flip the leading keyword
						my $first = $stmt->schild(0);
						next unless $first && $first->isa('PPI::Token::Word');
						$first->set_content($flipped);
						last;
					}
				},
			);
		};

		# Report construction failures clearly rather than silently dropping
		if($@ || !$mutant) {
			warn "Failed to construct mutant COND_INV_${line}_${col}: $@" if $@;
			next;
		}

		push @mutants, $mutant;
	}

	return @mutants;
}

1;
