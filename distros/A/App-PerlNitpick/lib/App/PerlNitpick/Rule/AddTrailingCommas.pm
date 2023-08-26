package App::PerlNitpick::Rule::AddTrailingCommas;
# ABSTRACT: Put a comma at the end of every multi-line list declaration, including the last one.

use Moose;
use PPI::Document;
use PPI::Token::Operator;
use Perl::Critic::Policy::CodeLayout::RequireTrailingCommas;
use App::PerlNitpick::PCPWrap;
use PPI::Dumper;

sub rewrite {
    my ($self, $doc) = @_;

    my $o = App::PerlNitpick::PCPWrap->new('Perl::Critic::Policy::CodeLayout::RequireTrailingCommas');

    my $elems = $doc->find( $o->applies_to ) or return $doc;
    my @vio = map { $o->violates($_, $doc) } @$elems;

    for (@vio) {
        my ($msg, $explain, $el) = @$_;

        # $el is a PPI::Structure::List. In this loop, we must match
        # what Perl::Critic::Policy::CodeLayout::RequireTrailingCommas
        # is doing in order to correctly navigate ourself to the final
        # non-whitespace element inside this list -- which is
        # something other than a comma.
        my $expr = $el->schild(0);
        my @children = $expr->schildren();
        my $final = $children[-1];

        # Insert a new comma right after the last non-whitespace
        # child, and before all trailing whitespace children.
        $final->insert_after( PPI::Token::Operator->new(",") );
    }

    return $doc;
}

1;
