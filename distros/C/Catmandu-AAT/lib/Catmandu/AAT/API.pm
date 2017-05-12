package Catmandu::AAT::API;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Catmandu::AAT::SPARQL;

has term     => (is => 'ro', required => 1);
has language => (is => 'ro', default => 'nl');

##
# Search for a term
sub search {
    my $self = shift;
    my $search_query = '?Subject luc:term "%s" .';
    my $query = $self->build_query(sprintf($search_query, $self->term));
    return $self->request($query);
}

##
# Exactly match a term
sub match {
    my $self = shift;
    my $match_query = '?Subject skos:prefLabel "%s"@%s .';
    my $query = $self->build_query(sprintf($match_query, $self->term, $self->language));
    my $result = $self->request($query);
    if (scalar @{$result} >= 1) {
        return $result->[0];
    } else {
        return {};
    }
}

##
# By ID
sub id {
    my $self = shift;
    my $id_query = '?Subject dc:identifier "%s" .';
    my $query = $self->build_query(sprintf($id_query, $self->term));
    my $result = $self->request($query);
    if (scalar @{$result} >= 1) {
        return $result->[0];
    } else {
        return {};
    }
}

sub request {
    my ($self, $query) = @_;
    my $sparql = Catmandu::AAT::SPARQL->new(query => $query, lang => $self->language);
    if (defined ($sparql->results)) {
        return $self->parse($sparql->results);
    } else {
        return [];
    }
}


sub parse {
    my ($self, $raw_results) = @_;
    my $results = [];

    foreach my $raw_result (@{$raw_results->{'results'}->{'bindings'}}) {
        my $result = {
            'prefLabel' => $raw_result->{'prefLabel'}->{'value'},
            'id' => $raw_result->{'id'}->{'value'},
            'uri' => $raw_result->{'Subject'}->{'value'}
        };
        push @{$results}, $result;
    }
    return $results;
}

sub build_query {
    my ($self, $match_query) = @_;
    my $query = q(select ?prefLabel ?id ?Subject ?scheme { ?Subject xl:prefLabel [xl:literalForm ?prefLabel; dct:language gvp_lang:%s] . values ?scheme {<http://vocab.getty.edu/aat/>} . ?Subject dc:identifier ?id . ?Subject skos:inScheme ?scheme . %s });
    return sprintf($query, $self->language, $match_query);
}

1.
__END__