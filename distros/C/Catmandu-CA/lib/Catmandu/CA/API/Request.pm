package Catmandu::CA::API::Request;

our $VERSION = '0.06';

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use LWP::UserAgent;
use JSON;

use Catmandu::CA::API::Login;

has url       => (is => 'ro', required => 1);
has url_query => (is => 'ro', required => 1);

has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);

has lang => (is => 'ro', default => 'nl_NL');

has token   => (is => 'lazy');
has ua      => (is => 'lazy');

sub _build_token {
    my $self = shift;
    my $login = Catmandu::CA::API::Login->new(username => $self->username, password => $self->password, url => $self->url);
    return $login->token();
}

sub _build_ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(
        agent => sprintf('catmandu-ca/%s', $VERSION)
    );
    return $ua;
}

sub get {
    my ($self, $query) = @_;
    my $url_string = '%s/%s?source=%s&authToken=%s&lang=%s';

    # If $self->url_query matches a '?' with no more '/' behind it
    if ($self->url_query =~ /\?[^\/]/) {
        $url_string = '%s/%s&source=%s&authToken=%s&lang=%s';
    }

    my $url = sprintf($url_string,
        $self->url,
        $self->url_query,
        $query,
        $self->token,
        $self->lang
    );
    my $response = $self->ua->get($url);
    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } elsif ($response->code == 404) {
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
                response_body    => $response->decoded_content,
        });
        return {};
    }
}

sub put {
    my ($self, $data) = @_;
    my $url = sprintf('%s/%s&authToken=%s', $self->url, $self->url_query, $self->token);
    my $response = $self->ua->put($url, Content => $data, Content_type => 'application/json');

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
        return 0;
    }

    return 1;
}

sub delete {
    my $self = shift;
    my $url = sprintf('%s/%s&authToken=%s', $self->url, $self->url_query, $self->token);
    my $response = $self->ua->delete($url);

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
        return 0;
    }

    return 1;
}
1;
__END__