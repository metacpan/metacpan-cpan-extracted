package App::PerlNitpick::Rule::MoreOrLessSpaces;
use Moose;
use PPI::Document;
use PPI::Token::Whitespace;

no Moose;

sub rewrite {
    my ($self, $document) = @_;

    for my $el (@{ $document->find('PPI::Token::Whitespace') ||[]}) {
        next if $el->parent->isa('PPI::Statement');
        next unless $el->content =~ m/\A +\n( *)/;
        $el->set_content("\n$1");
    }

    for my $el (@{ $document->find('PPI::Token::Whitespace') ||[]}) {
        next if $el->parent->isa('PPI::Statement');

        my $prev1 = $el->previous_sibling or next;
        my $prev2 = $prev1->previous_sibling or next;
        next unless $prev1->isa('PPI::Token::Whitespace') && $prev1->content eq "\n" && $prev2->isa('PPI::Token::Whitespace') && $prev2->content eq "\n";
        if ($el->content eq "\n") {
            $el->delete;
        } elsif ($el->content =~ m/\A\n( +)\z/) {
            $el->set_content("$1");
        }
    }

    for my $el0 (@{ $document->find('PPI::Structure::List') ||[]}) {
        for my $el (@{ $el0->find('PPI::Token::Operator') ||[]}) {
            next unless $el->content eq ',';
            my $next_el = $el->next_sibling or next;
            unless ($next_el->isa('PPI::Token::Whitespace')) {
                # Insert a new one.
                my $wht = PPI::Token::Whitespace->new(' ');
                $el->insert_after($wht);
            }
        }
    }

    return $document;
}

1;

__END__

=head1 MoreOrLessSpaces

In this rule, space characters is inserted or removed within one line
between punctuation boundaries.

