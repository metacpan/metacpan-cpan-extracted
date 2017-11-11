package Catmandu::VIAF::API::ID;

our $VERSION = '0.05';

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

use LWP::UserAgent;
use Catmandu::VIAF::API::Parse;

has viafid => (is => 'ro', required => 1);

has client => (is => 'lazy');
has result=> (is => 'lazy');

sub _build_client {
    my $self = shift;
     my $ua = LWP::UserAgent->new(
        agent => sprintf('catmandu-store-viaf/%s', $VERSION)
    );
    return $ua;
}

sub _build_result {
    my $self = shift;
    my $url = sprintf('https://www.viaf.org/viaf/%s/rdf.xml', $self->viafid);
    my $response = $self->client->get($url);

    if (!$response->is_success) {
        if ($response->code == 404) {
            return {};
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
            return {};
        }
    }
    my $rdf = $response->decoded_content;
    my $document = sprintf('<?xml version="1.0" encoding="UTF-8"?>%s', $rdf);
    my $parser = Catmandu::VIAF::API::Parse->new(items => $document);
    return $parser->xml();
}

1;
__END__