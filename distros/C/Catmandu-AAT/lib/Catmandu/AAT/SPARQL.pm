package Catmandu::AAT::SPARQL;

our $VERSION = '0.03';

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use LWP::UserAgent;
use JSON;

has query => (is => 'ro', required => 1);
has url   => (is => 'ro', default => 'http://vocab.getty.edu/sparql.json');
has lang  => (is => 'ro', default => 'nl');

has results => (is => 'lazy');
has ua      => (is => 'lazy');

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => sprintf('catmandu-store-aat/%s', $VERSION)
    );
    # Otherwise, the endpoint blows up.
    $ua->default_header('Accept' => '*/*');
    return $ua;
}


sub _build_results {
    my $self = shift;
    my $r = $self->get();
    return $r;
}

sub get {
    my $self = shift;
    my $form_template = 'query=%s';
    my $form = {
        'query' => $self->query
    };
    my $response = $self->ua->post($self->url, $form);
    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } else {
         Catmandu::HTTPError->throw({
            code             => $response->code,
            message          => $response->status_line,
            url              => $response->request->uri,
            method           => $response->request->method,
            request_headers  => [],
            request_body     => $response->request->decoded_content,
            response_headers => [],
            response_body    => $response->decoded_content
        });
        return undef;
    }
}


1;

__END__

=head1 DESCRIPTION

=head2 SPARQL Query

    select ?anyLabel ?id ?Subject ?scheme {
        ?Subject xl:prefLabel|xl:altLabel [xl:literalForm ?anyLabel; dct:language gvp_lang:nl] .
        values ?scheme {<http://vocab.getty.edu/aat/>} .
        ?Subject dc:identifier ?id .
        ?Subject skos:inScheme ?scheme .
        ?Subject luc:term "schildering" .
    }

=cut