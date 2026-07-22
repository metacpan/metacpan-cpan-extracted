package App::Test::Generator::Mutation::NumericBoundary;

use strict;
use warnings;
use Carp qw(croak);
use parent 'App::Test::Generator::Mutation::Base';
use App::Test::Generator::Mutant;
use PPI;

our $VERSION = '0.44';

=head1 VERSION

Version 0.44

=cut

# --------------------------------------------------
# Mapping of each comparison operator to the list of
# operators it should be flipped to when mutating.
# Both directions are covered so that e.g. != can be
# mutated to == and vice versa.
# --------------------------------------------------
my %FLIP = (
	'>'  => [ '<', '>=', '<=' ],
	'<'  => [ '>', '<=', '>=' ],
	'>=' => [ '>', '<',  '<=' ],
	'<=' => [ '<', '>',  '>=' ],
	'==' => [ '!=' ],
	'!=' => [ '==' ],
);

=head2 applies_to

Returns true if the document contains any comparison operators that this
mutator can target (C<E<gt>>, C<E<lt>>, C<E<gt>=>, C<E<lt>=>, C<==>,
C<!=>).

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
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::NumericBoundary' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	my ($self, $doc) = @_;
	my $ops = $doc->find('PPI::Token::Operator') || [];
	for my $op (@{$ops}) {
		next unless exists $FLIP{$op->content()};
		my $parent = $op->parent();
		next unless $parent->isa('PPI::Statement')
			|| $parent->isa('PPI::Structure::Condition')
			|| $parent->isa('PPI::Structure::Block');
		return 1;
	}
	return 0;
}

=head2 mutate

Walk a PPI document and generate one mutant for each comparison operator
that can be flipped to reveal a boundary condition not caught by the test
suite. For example, C<E<gt>=> is flipped to C<E<gt>>, C<E<lt>>, and
C<E<lt>=>  in turn, producing three independent mutants.

    my $mutation = App::Test::Generator::Mutation::NumericBoundary->new;
    my $doc      = PPI::Document->new(\$source);
    my @mutants  = $mutation->mutate($doc);

    for my $m (@mutants) {
        print $m->id, ': ', $m->description, "\n";
    }

=head3 Arguments

=over 4

=item * C<$self>

An instance of C<App::Test::Generator::Mutation::NumericBoundary>.

=item * C<$doc>

A L<PPI::Document> object representing the parsed source file to mutate.
The document is not modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects, one per
(operator, flip) pair found in the document. Returns an empty list if no
qualifying comparison operators are found.

Each mutant carries a C<transform> closure that when called with a fresh
L<PPI::Document> copy will replace the targeted operator with its flipped
equivalent, targeting the exact operator by line and column number to
ensure that multiple comparison operators on the same source line are each
mutated independently.

=head3 Notes

The following operators and their flips are supported:

    >   flips to  <  >=  <=
    <   flips to  >  <=  >=
    >=  flips to  >  <   <=
    <=  flips to  <  >   >=
    ==  flips to  !=
    !=  flips to  ==

Mutant IDs include line number, column number, and the flip target to
ensure uniqueness even when multiple operators share a source line.

Each mutant's optional C<context> field is set to C<conditional> if
the operator sits inside (or is itself the keyword of) an
C<if>/C<unless>/C<while>/C<until> compound statement, or C<expression>
otherwise; its C<line_content> field holds the raw source text of the
mutated line. Both are consumed by
L<App::Test::Generator::Mutator>'s fast-mode dedup.

=head3 API specification

=head4 input

    {
        self => {
            type => OBJECT,
            isa  => 'App::Test::Generator::Mutation::NumericBoundary',
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

	# Find all operator tokens in the document
	my $ops = $doc->find('PPI::Token::Operator') || [];
	my @mutants;

	for my $op (@{$ops}) {
		my $original = $op->content();

		# Only process comparison operators that have defined flips
		next unless exists $FLIP{$original};

		# Only mutate operators that are direct children of
		# a condition or expression, not list arguments
		my $parent = $op->parent();
		next unless $parent->isa('PPI::Statement')
			|| $parent->isa('PPI::Structure::Condition')
			|| $parent->isa('PPI::Structure::Block');

		# Capture location so the transform closure targets the
		# exact operator rather than the first match on that line
		my $line = $op->location->[0];
		my $col  = $op->location->[1];

		# PPI always wraps a condition's content in a
		# PPI::Statement::Expression, so the operator's immediate
		# parent is never literally PPI::Structure::Condition --
		# use the shared ancestor-walking helper instead, as
		# BooleanNegation and ReturnUndef do, to correctly detect
		# operators inside if/unless/while/until conditions
		my $context = $self->_in_conditional($op) ? 'conditional' : 'expression';

		# Generate one mutant per flip of this operator
		for my $change (@{ $FLIP{$original} }) {
			# Build a unique id from location and the specific flip
			# so multiple operators on the same line don't collide
			my $id = "NUM_BOUNDARY_${line}_${col}_${change}";

			my $mutant = eval {
				App::Test::Generator::Mutant->new(
					id           => $id,
					group        => "NUM_BOUNDARY:$line",
					description  => "Numeric boundary flip $original to $change",
					original     => $original,
					line         => $line,
					type         => 'comparison',
					context      => $context,
					line_content => $self->_line_content($doc, $line),

					# The transform closure captures line, col, original
					# and change so it targets precisely the right operator
					# in the document copy it receives at test time
					transform => sub {
						my $doc  = $_[0];
						my $ops  = $doc->find('PPI::Token::Operator') || [];

						for my $op (@{$ops}) {
							next unless $op->line_number   == $line;
							next unless $op->column_number == $col;
							next unless $op->content       eq $original;

							$op->set_content($change);
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
	}

	return @mutants;
}

1;
