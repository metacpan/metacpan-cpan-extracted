package Catmandu::Store::Datahub::Generator;

use LWP::UserAgent;
use JSON;
use Moo;

use Catmandu::Sane;
use Catmandu::Store::Datahub::OAuth;

has token => (is => 'ro', required => 1);
has url   => (is => 'ro', required => 1);

has list  => (is => 'rw', default => sub {
    return [];
});

has ua   => (is => 'lazy');

sub _build_ua {
    my $self = shift;
    return LWP::UserAgent->new();
}

sub set_list {
    my ($self) = @_;
    my $url = sprintf('%s/api/v1/data', $self->url);
    my $response = $self->ua->get($url, Authorization => sprintf('Bearer %s', $self->token));
    if ($response->is_success) {
        my $json = $response->decoded_content;
        my $decoded_json = decode_json($json);
        $self->list = $decoded_json->['results'];
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
    }
}

sub get_single {
    my ($self, $id) = @_;
    my $url = sprintf('%s/api/v1/data.lidoxml/%s', $self->url, $id);
    my $response = $self->ua->get($url, Authorization => sprintf('Bearer %s', $self->token));
    if ($response->is_success) {
        return $response->decoded_content;
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
        return undef;
    }
}

sub next {
    my ($self) = @_;
    my $next = shift @$self->list;
    return $self->get_single($next->['data_pids'][0]);
}

1;