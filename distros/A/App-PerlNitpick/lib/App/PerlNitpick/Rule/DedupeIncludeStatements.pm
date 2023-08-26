package App::PerlNitpick::Rule::DedupeIncludeStatements;
use Moose;

sub rewrite {
    my ($self, $document) = @_;

    my %used;
    my @to_delete;
    for my $el (@{ $document->find('PPI::Statement::Include') ||[]}) {
        next unless $el->type && $el->type eq 'use';
        my $module = $el->module;
        my $code = "$el";
        if ($used{$code}) {
            push @to_delete, $el;
        } else {
            $used{$code} = 1;
        }
    }

    for my $el (@to_delete) {
        $self->_remove_with_trailing_characters($el);
    }

    return $document;
}

sub _remove_with_trailing_characters {
    my ($self, $el) = @_;

    while ( my $next = $el->next_sibling ) {
        last if !$next->isa('PPI::Token::Whitespace');
        $next->remove;
        last if $next eq "\n";
    }
    $el->remove;
    return;
}

no Moose;
1;

__END__

=head1 DedupeIncludeStatements

In this rule, multiple identical "use" statements of the same module are merged.

For example, this code:

    use File::Temp;
    use Foobar;
    use File::Temp;

... is transformed to:

    use File::Temp;
    use Foobar;

Two statements are consider identical if, and only if, they are literally the same, character-to-character.
