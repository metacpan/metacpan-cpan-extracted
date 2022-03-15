package App::PerlNitpick::Rule::RemoveUnnecessaryScalarKeyword;
# ABSTRACT: Remove unnecessary scalar keyword

=encoding UTF-8

This nitpicking rules removes C<scalar> keywords that are use in scalar context, for example, in this statement:

    my $n = scalar @items;

Since the left hand side is a single scalar variable, the assignment is already in scalar context. It is not necessary to include C<scalar> on the right-hand side.

=cut

use Moose;
use PPI::Document;
use Perl::Critic::Document;
use Perl::Critic::Policy::TooMuchCode::ProhibitUnnecessaryScalarKeyword;

use App::PerlNitpick::PCPWrap;

no Moose;

sub rewrite {
    my ($self, $doc) = @_;

    my $o = App::PerlNitpick::PCPWrap->new('Perl::Critic::Policy::TooMuchCode::ProhibitUnnecessaryScalarKeyword');

    my $elems = $doc->find( $o->applies_to ) or return $doc;
    my @vio = map { $o->violates($_, $doc) } @$elems;

    for (@vio) {
        my ($msg, $explain, $el) = @$_;
        if ($el->next_sibling eq ' ') {
            $el->next_sibling->remove;
        }
        $el->remove;
    }

    return $doc;
}

1;
