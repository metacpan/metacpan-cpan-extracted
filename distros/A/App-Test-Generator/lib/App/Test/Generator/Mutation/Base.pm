package App::Test::Generator::Mutation::Base;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.42';

=head1 VERSION

Version 0.42

=head1 DESCRIPTION

Abstract base class for all mutation strategies in
App::Test::Generator. Subclasses must implement both
C<applies_to> and C<mutate>.

=head2 new

Construct a new mutation strategy object.

    my $strategy = My::Mutation::Subclass->new;

=head3 Arguments

None.

=head3 Returns

A blessed hashref of the subclass type.

=head3 API specification

=head4 input

    {}

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Mutation::Base',
    }

=cut

sub new { bless {}, shift }

=head2 applies_to

Return true if this mutation strategy applies to the
given PPI document. Subclasses must override this method.

    if ($strategy->applies_to($doc)) {
        my @mutants = $strategy->mutate($doc);
    }

=head3 Arguments

=over 4

=item * C<$doc>

A L<PPI::Document> object.

=back

=head3 Returns

A boolean. Croaks if called on the base class directly.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::Base' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	my ($self, $doc) = @_;
	croak ref($self) . '::applies_to() must be implemented by subclass';
}

=head2 mutate

Generate and return a list of mutants for the given PPI
document. Subclasses must override this method.

    my @mutants = $strategy->mutate($doc);

=head3 Arguments

=over 4

=item * C<$doc>

A L<PPI::Document> object representing the source file
to mutate. Must not be modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects.
Croaks if called on the base class directly.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::Base' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    {
        type     => ARRAYREF,
        elements => { type => OBJECT, isa => 'App::Test::Generator::Mutant' },
    }

=cut

sub mutate {
	my ($self, $doc) = @_;
	croak ref($self) . '::mutate() must be implemented by subclass';
}

# --------------------------------------------------
# _line_content
#
# Purpose:    Fetch the raw source text of a single line,
#             for the optional line_content field on a
#             Mutant (used by Mutator::_is_redundant_mutation
#             to skip mutations targeting comment-only lines).
#
# Entry:      $doc  - a PPI::Document.
#             $line - a 1-based line number.
#
# Exit:       Returns the text of that line, or '' if out
#             of range.
#
# Side effects: None.
# --------------------------------------------------
sub _line_content {
	my ($self, $doc, $line) = @_;
	my @lines = split /\n/, $doc->serialize;
	return $lines[$line - 1] // '';
}

# --------------------------------------------------
# _in_conditional
#
# Purpose:    Determine whether a PPI node sits inside
#             (or is itself the keyword of) an if/unless/
#             while/until compound statement, for the
#             optional context field on a Mutant.
#
# Entry:      $node - a PPI::Element.
#
# Exit:       Returns 1 if an ancestor (or the node itself)
#             is an if/unless/while/until compound statement,
#             0 otherwise.
#
# Side effects: None.
# --------------------------------------------------
sub _in_conditional {
	my ($self, $node) = @_;

	for(my $parent = $node; $parent; $parent = $parent->parent) {
		next unless $parent->isa('PPI::Statement::Compound');
		my $first = $parent->schild(0);
		next unless $first && $first->isa('PPI::Token::Word');
		return 1 if $first->content =~ /^(?:if|unless|while|until)$/;
	}

	return 0;
}

1;
