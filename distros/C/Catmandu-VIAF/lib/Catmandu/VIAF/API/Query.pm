package Catmandu::VIAF::API::Query;

our $VERSION = '0.04';

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

use LWP::UserAgent;
use Catmandu::VIAF::API::ID;
use Catmandu::VIAF::API::Parse;

has query => (is => 'ro', required => 1);
has lang  => (is => 'ro', default => 'nl-NL');

has results => (is => 'lazy');
has client  => (is => 'lazy');

sub _build_client {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => sprintf('catmandu-store-viaf/%s', $VERSION)
    );
    return $ua;
}


sub _build_results {
    my $self = shift;
    my $url = sprintf('https://www.viaf.org/viaf/search?query=%s&httpAccept=application/json', $self->query);
    my $response = $self->client->get($url);

    if (!$response->is_success) {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->status_line,
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return [];
    }

    my $results = $self->parse($response->decoded_content);
    $results = $results->{'searchRetrieveResponse'}->{'records'};
    my $records = [];
    foreach my $result (@{$results}) {
        push @{$records}, $self->get_from_id($result->{'record'}->{'recordData'}->{'viafID'});
    }
    return $records;
}

sub get_from_id {
    my ($self, $id) = @_;
    my $api_id = Catmandu::VIAF::API::ID->new(viafid => $id);
    return $api_id->result;
}

sub parse {
    my ($self, $response) = @_;
    my $parser = Catmandu::VIAF::API::Parse->new(items => $response);
    return $parser->json();
}


1;
__END__