package Catmandu::Store::Datahub::API;

use strict;
use warnings;

use Catmandu;
use Moo;
use JSON;

use LWP::UserAgent;

has url           => (is => 'ro', required => 1);
has client_id     => (is => 'ro', required => 1);
has client_secret => (is => 'ro', required => 1);
has username      => (is => 'ro', required => 1);
has password      => (is => 'ro', required => 1);

has client       => (is => 'lazy');
has access_token => (
    is      => 'lazy',
    writer  => '_set_access_token',
    builder => '_build_access_token'
);

sub _build_client {
    my $self = shift;
    return LWP::UserAgent->new(keep_alive => 1);
}

sub _build_access_token {
    my $self = shift;
    return $self->generate_token();
}

sub set_access_token {
    my $self = shift;
    # Used to regenerate the token when it becomes invalid
    return $self->_set_access_token($self->generate_token());
}

sub generate_token {
    my $self = shift;
    my $oauth = Catmandu::Store::Datahub::OAuth->new(username => $self->username, password => $self->password, client_id => $self->client_id, client_secret => $self->client_secret, url => $self->url);
    return $oauth->token();
}

sub get {
    my ($self, $id) = @_;
    my $url = sprintf('%s/api/v1/data/%s', $self->url, $id);

    my $response = $self->client->get($url, Authorization => sprintf('Bearer %s', $self->access_token));

    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } elsif ($response->code == 401) {
        my $error = decode_json($response->decoded_content);
        if ($error->{'error_description'} eq 'The access token provided has expired.') {
            $self->set_access_token();
            return $self->get($id);
        }
    } elsif ($response->code == 404) {
        return {};
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->headers->header('message'),
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return undef;
    }
}

sub add {
    my ($self, $data) = @_;
    my $url = sprintf('%s/api/v1/data.lidoxml', $self->url);

    my $token = $self->access_token;
    my $response;

    $response = $self->client->post($url, Content_Type => 'application/lido+xml', Authorization => sprintf('Bearer %s', $token), Content => $data);

    if ($response->is_success) {
        return $response->decoded_content;
    } elsif ($response->code == 401) {
        my $error = decode_json($response->decoded_content);
        if ($error->{'error_description'} eq 'The access token provided has expired.') {
            $self->set_access_token();
            return $self->add($data);
        }
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->headers->header('message'),
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return undef;
    }
}

sub update {
    my ($self, $id, $data) = @_;
    my $url = sprintf('%s/api/v1/data/%s', $self->url, $id);

    my $token = $self->access_token;
    my $response;

    $response = $self->client->put($url, Content_Type => 'application/lido+xml', Authorization => sprintf('Bearer %s', $token), Content => $data);

    if ($response->is_success) {
        return $response->decoded_content;
    } elsif ($response->code == 401) {
        my $error = decode_json($response->decoded_content);
        if ($error->{'error_description'} eq 'The access token provided has expired.') {
            $self->set_access_token();
            return $self->update($id, $data);
        }
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->headers->header('message'),
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return undef;
    }
}

sub delete {
    my ($self, $id) = @_;
    my $url = sprintf('%s/api/v1/data/%s', $self->url, $id);

    my $token = $self->access_token;
    my $response;

    $response = $self->client->delete($url, Authorization => sprintf('Bearer %s', $token));

    if ($response->is_success) {
        return $response->decoded_content;
    } elsif ($response->code == 401) {
        my $error = decode_json($response->decoded_content);
        if ($error->{'error_description'} eq 'The access token provided has expired.') {
            $self->set_access_token();
            return $self->delete($id);
        }
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->headers->header('message'),
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return undef;
    }
}

sub list {
    my ($self) = @_;
    my $url = sprintf('%s/api/v1/data', $self->url);

    my $token = $self->access_token;
    my $response = $self->client->get($url, Authorization => sprintf('Bearer %s', $token));

    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } else {
        Catmandu::HTTPError->throw({
                code             => $response->code,
                message          => $response->headers->header('message'),
                url              => $response->request->uri,
                method           => $response->request->method,
                request_headers  => [],
                request_body     => $response->request->decoded_content,
                response_headers => [],
                response_body    => $response->decoded_content,
            });
        return undef;
    }
}

1;

__END__
