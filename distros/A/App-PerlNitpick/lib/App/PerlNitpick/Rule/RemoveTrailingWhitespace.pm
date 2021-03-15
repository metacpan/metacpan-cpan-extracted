package App::PerlNitpick::Rule::RemoveTrailingWhitespace;
# ABSTRACT: Remove trailing whitespace.

=encoding UTF-8

=head2 DESCRIPTION

This nitpicking rules removes trailing whitespaces

=cut

use Moose;
use PPI::Document;
use Perl::Critic::Document;
use Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace;
use App::PerlNitpick::PCPWrap;

no Moose;

sub rewrite {
    my ($self, $doc) = @_;

    my $o = App::PerlNitpick::PCPWrap->new('Perl::Critic::Policy::CodeLayout::ProhibitTrailingWhitespace');

    my $doc2 = Perl::Critic::Document->new(-source => $doc);
    for my $type ( $o->applies_to() ) {
        my @elements;
        if ($type eq 'PPI::Document') {
            @elements = ($doc2);
        }
        else {
            @elements = @{ $doc2->find($type) || [] };
        }

        for my $element (@elements) {
            VIOLATION:
            for my $vio ($o->violates( $element, $doc )) {
                my ($msg, $explain, $el) = @$vio;
                my $t = $el->content =~ s< ( (?! \n) \s )+ \n ><\n>xmsr;
                $el->set_content($t);
            }
        }
    }

    return $doc;
}

1;
