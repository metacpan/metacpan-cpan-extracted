package Buscador::Search;
use strict;

=head1 NAME

Buscador::Search - allow searching from within Buscador

=head1 DESCRIPTION

Provides various methods so that you can do

    ${base}/mail/search/[terms]

=head1 AUTHOR

Simon Cozens, <simon@cpan.org>

with work from

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Cozens

=cut



package Email::Store::Mail;
use strict;
use Text::Context;
use HTML::Entities;


sub search :Exported {
    return shift->SUPER::search(@_) if caller ne "Maypole::Model::Base";
    my ($self, $r) = @_;
    $self = $self->do_pager($r);
    $r->objects([ $self->plucene_search( $r->{query}{terms} ) ]);
} # Don't you just love it when a plan comes together?

sub _unlucene {
    my ($asset_terms) = @_;
    use Data::Dumper;
    return map {
        $_->{query}     eq "SUBQUERY" ? _unlucene($_->{subquery})
            : $_->{query} ne "PHRASE"   ? $_->{term}
            : (split /\s+/, $_->{term})    }
            grep
                { $_->{type} ne "PROHIBITED" and (!exists($_->{field}) or $_->{field} eq "text")}
            @{$asset_terms};
}

sub parsed_query {
    my ($q) = @_;
    my $parser = Plucene::QueryParser->new({
            analyzer => Plucene::Analysis::SimpleAnalyzer->new(),
            default  => "text",
        });
    $parser->parse($q, 1);
}

sub contextualize_result {
    my ($mail, $terms) = @_;
    my @terms = _unlucene(parsed_query($terms));
    my $body = $mail->body;
    Text::Context->new($body, @terms)->as_html( start=> "<b>", end => "</b>" )
    || encode_entities($mail->original);

}


1;
