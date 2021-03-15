package App::PerlNitpick::Rule::AppendUnimportStatement;
# ABSTRACT: Ensure a 'no Moose;' statement is there if 'use Moose;' is.

=encoding UTF-8

=head1 DESCRIPTION

This nitpicking rule ensure a 'no Moose' statement is present in the file if a 'use Moose' is there.

=cut

use Moose;
use PPI::Document;

sub rewrite {
    my ($self, $doc) = @_;

    for my $module ('Moose', 'Mouse', 'Moo', 'Moose::Role', 'Mouse::Role') {
        if ($self->has_import_but_has_no_unimport($doc, $module)) {
            $self->append_unimport($doc, $module);
        }
    }

    return $doc;
}

sub has_import_but_has_no_unimport {
    my ($self, $doc, $module) = @_;
    my $include_statements = $doc->find(sub { $_[1]->isa('PPI::Statement::Include') }) || [];

    my ($has_use, $has_no);
    for my $st (@$include_statements) {
        next unless $st->module eq $module;
        if ($st->type eq 'use') {
            $has_use = 1;
        } elsif ($st->type eq 'no') {
            $has_no = 1;
        }
    }
    return $has_use && !$has_no;
}

sub append_unimport {
    my ($self, $doc, $module) = @_;

    my $doc2 = PPI::Document->new(\"no ${module};");
    my $el = $doc2->find_first('PPI::Statement::Include');
    $el->remove;

    my @child = $doc->schildren();
    $child[-1]->insert_before($el);
    $child[-1]->insert_before(PPI::Token::Whitespace->new("\n"));

    return $doc;
}

1;
