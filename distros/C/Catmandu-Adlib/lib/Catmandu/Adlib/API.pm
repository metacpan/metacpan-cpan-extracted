package Catmandu::Adlib::API;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;
use JSON;

use Catmandu::Adlib::API::Login;
use Catmandu::Adlib::API::QueryBuilder;

has username => (is => 'ro', required => 1);
has password => (is => 'ro', required => 1);
has endpoint => (is => 'ro', required => 1);
has database => (is => 'ro', required => 1);

has ua => (is => 'lazy');
has qb => (is => 'lazy');

sub _build_ua {
    my $self = shift;
    return Catmandu::Adlib::API::Login->new(
        username => $self->username,
        password => $self->password
    );
}

sub _build_qb {
    my $self = shift;
    return Catmandu::Adlib::API::QueryBuilder->new(
        database => $self->database
    );
}

sub get_by_object_number {
    my ($self, $id) = @_;
    my $response = $self->by_object_id($id);
    # We need to get the detailfields, and to do that, we need the priref
    if ($response->code == 404) {
        return {};
    } elsif(!$response->is_success) {
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
    my $json = decode_json($response->decoded_content);
    # If there are multiple results for the same object_id, I'm gonna turn violent.
    return $self->get_by_priref($self->get_priref($json->{'adlibXML'}->{'recordList'}->{'record'}->[0]));
}

sub get_by_priref {
    my ($self, $priref) = @_;
    my $url = sprintf('%s/%s', $self->endpoint, $self->qb->priref($priref));
    my $response = $self->ua->get($url);
    if ($response->is_success) {
        # It's XML - is it already structured? TODO: see
        return $response->decoded_content;
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
    }
}

sub by_object_id {
    my ($self, $id) = @_;
    my $url = sprintf('%s/%s', $self->endpoint, $self->qb->object_id($id));
    my $response = $self->ua->get($url);
    return $response;
}

sub add {
    my ($self, $data) = @_;
    Catmandu::NotImplemented->throw(
        message => 'Adding items is not supported.'
    );
}

sub update {
    my ($self, $id, $data) = @_;
    Catmandu::NotImplemented->throw(
        message => 'Updating items is not supported.'
    );
}

sub delete {
    my ($self, $id) = @_;
    Catmandu::NotImplemented->throw(
        message => 'Deleting items is not supported.'
    );
}

sub list {
    my ($self, $start) = @_;
    my $url = sprintf('%s/%s', $self->endpoint, $self->qb->all());
    if (defined($start)) {
        $url = sprintf('%s&startfrom=%s', $url, $start);
    } else {
        $url = sprintf('%s&startfrom=1', $url);
    }
    warn $url;
    my $response = $self->ua->get($url);
    if ($response->is_success) {
        return decode_json($response->decoded_content);
    } elsif ($response->code == 404) {
        return [];
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

sub get_priref {
    my ($self, $json_record) = @_;
    return $json_record->{'priref'}->[0];
}

1;
__END__