package Catmandu::Store::REST::API;

use Catmandu::Sane;
use Moo;
use JSON;
use LWP::UserAgent;

has base_url     => (is => 'ro', required => 1);
has query_string => (is => 'ro');

has client   => (is => 'lazy');

sub _build_client {
    my $self = shift;
    return LWP::UserAgent->new();
}

sub mk_url {
    my ($self, $id) = @_;
    if (defined($id)) {
        return sprintf('%s/%s%s', $self->base_url, $id, $self->query_string);
    } else {
        return sprintf('%s%s', $self->base_url, $self->query_string);
    }
}

sub get {
    my ($self, $id) = @_;
    my $url = $self->mk_url($id);

    my $response = $self->client->get($url);

    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } elsif ($response->code == 404) {
        return {};
    } else {
        Catmandu::HTTPError->throw({
            code             => $response->code,
            message          => $response->status_line,
            url              => $response->request->url,
            method           => $response->request->method,
            request_headers  => [],
            request_body     => $response->request->decoded_content,
            response_headers => [],
            response_body    => $response->decoded_content,
        });
        return {};
    }
}

sub post {
    my ($self, $data) = @_;
    my $url = $self->mk_url();
    my $json_data = encode_json($data);
    
    my $response = $self->client->post($url, Content_Type => 'application/json', Content => $json_data);

    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } else {
        Catmandu::HTTPError->throw({
            code             => $response->code,
            message          => $response->status_line,
            url              => $response->request->url,
            method           => $response->request->method,
            request_headers  => [],
            request_body     => $response->request->decoded_content,
            response_headers => [],
            response_body    => $response->decoded_content,
        });
        return {};
    }
}

sub put {
    my ($self, $id, $data) = @_;
    my $url = $self->mk_url($id);
    my $json_data = encode_json($data);
    
    my $response = $self->client->put($url, Content_Type => 'application/json', Content => $json_data);

    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } else {
        Catmandu::HTTPError->throw({
            code             => $response->code,
            message          => $response->status_line,
            url              => $response->request->url,
            method           => $response->request->method,
            request_headers  => [],
            request_body     => $response->request->decoded_content,
            response_headers => [],
            response_body    => $response->decoded_content,
        });
        return {};
    }
}

sub delete {
    my ($self, $id) = @_;
    my $url = $self->mk_url($id);

    my $response = $self->client->delete($url);
    
    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } else {
        Catmandu::HTTPError->throw({
            code             => $response->code,
            message          => $response->status_line,
            url              => $response->request->url,
            method           => $response->request->method,
            request_headers  => [],
            request_body     => $response->request->decoded_content,
            response_headers => [],
            response_body    => $response->decoded_content,
        });
        return {};
    }
}

1;