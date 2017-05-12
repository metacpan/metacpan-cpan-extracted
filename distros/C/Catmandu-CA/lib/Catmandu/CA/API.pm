package Catmandu::CA::API;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;

use JSON;
use Catmandu::CA::API::QueryBuilder;
use Catmandu::CA::API::Request;

has username   => (is => 'ro', required => 1);
has password   => (is => 'ro', required => 1);
has url        => (is => 'ro', required => 1);
has lang       => (is => 'ro', default => 'nl_NL');
has model      => (is => 'ro', default => 'ca_objects');

sub id {
    my ($self, $id, $field_list) = @_;
    my $q = Catmandu::CA::API::QueryBuilder->new(field_list => $field_list);
    my $r = Catmandu::CA::API::Request->new(
        url       => $self->url,
        url_query => sprintf('service.php/item/%s/id/%s', $self->model, $id),
        username  => $self->username,
        password  => $self->password,
        lang      => $self->lang
    );
    return $r->get($q->query);
}

sub simple {
    my ($self, $id) = @_;
    my $r = Catmandu::CA::API::Request->new(
        url       => $self->url,
        url_query => sprintf('service.php/item/%s/id/%s', $self->model, $id),
        username  => $self->username,
        password  => $self->password,
        lang      => $self->lang
    );
    return $r->get('{}');
}

sub add {
    my ($self, $data) = @_;
    my $r = Catmandu::CA::API::Request->new(
        url       => $self->url,
        url_query => sprintf('service.php/item/%s', $self->model),
        username  => $self->username,
        password  => $self->password,
        lang      => $self->lang
    );
    return $r->put(encode_json($data));
}

sub update {
    my ($self, $id, $data) = @_;
    my $r = Catmandu::CA::API::Request->new(
        url       => $self->url,
        url_query => sprintf('service.php/item/%s/id/%s', $self->model, $id),
        username  => $self->username,
        password  => $self->password,
        lang      => $self->lang
    );
    return $r->put(encode_json($data));
}

sub delete {
    my ($self, $id) = @_;
    my $r = Catmandu::CA::API::Request->new(
        url       => $self->url,
        url_query => sprintf('service.php/item/%s/id/%s', $self->model, $id),
        username  => $self->username,
        password  => $self->password,
        lang      => $self->lang
    );
    return $r->delete();
}

sub list {
    my ($self, $field_list) = @_;
    my $q = Catmandu::CA::API::QueryBuilder->new(field_list => $field_list);
    my $r = Catmandu::CA::API::Request->new(
        url       => $self->url,
        url_query => sprintf('service.php/find/%s?q=*', $self->model),
        username  => $self->username,
        password  => $self->password,
        lang      => $self->lang
    );
    return $r->get($q->query);
}

1;
__END__