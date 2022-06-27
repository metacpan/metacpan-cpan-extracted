package App::PerlNitpick::Rule::RewriteWithAssignmentOperators;
use Moose;
use PPI::Document;
use PPI::Token::Whitespace;

no Moose;

sub rewrite {
    my ($self, $document) = @_;

    my @found = grep {
        # Find a statement that looks like $x = $x + $y;
        my $c0 = $_->schild(0);  # $x
        my $c1 = $_->schild(1);  # =
        my $c2 = $_->schild(2);  # $x
        my $c3 = $_->schild(3);  # +
        my $c4 = $_->schild(4);  # $y
        my $c5 = $_->schild(5);  # ;

        ($c1->isa('PPI::Token::Operator') && $c1->content eq '=') &&
        ($c5->isa('PPI::Token::Structure') && $c5->content eq ';') &&
        ($c3->isa('PPI::Token::Operator') && $c3->content !~ m{\A( -> | > | < | \.)\z}x) &&
        ($c0->isa('PPI::Token::Symbol') && $c0->raw_type eq '$' &&
        $c2->isa('PPI::Token::Symbol') && $c2->raw_type eq '$' &&
        $c1->content && $c2->content)
    } grep {
        $_->schildren == 6
    } @{ $document->find('PPI::Statement') ||[] };

    return $document unless @found;

    for my $statement (@found) {
        my @child = $statement->schildren;

        # assigment operator :)
        my $assop = PPI::Token::Operator->new($child[3]->content . $child[1]->content);

        $child[3]->remove;
        $child[2]->remove;
        $child[1]->insert_after($assop);
        $child[1]->remove;
    }

    return $document;
}

1;

__END__

=head1 DESCRIPTION

This rule rewrites those assignments that alter a single varible with itself.
For example, this one:

    $x = $x + 2;

Is rewritten with the C<+=> assignment operator, as:

    $x += 2;

=cut
