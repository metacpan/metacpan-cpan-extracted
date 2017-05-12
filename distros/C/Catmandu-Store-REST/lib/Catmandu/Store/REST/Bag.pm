package Catmandu::Store::REST::Bag;

use Moo;
use JSON;

use Catmandu::Sane;
use Catmandu::Store::REST::API;

with 'Catmandu::Bag';

has api => (is => 'lazy');

sub _build_api {
    my $self = shift;
    return Catmandu::Store::REST::API->new(
        base_url     => $self->store->base_url,
        query_string => $self->store->query_string,
    );
}

sub generator {
    my $self = shift;
    Catmandu::NotImplemented->throw('Generator not implemented.');
    return undef;
}

sub get {
    my ($self, $id) = @_;
    return $self->api->get($id);
}

sub add {
    my ($self, $data) = @_;
    return $self->api->post($data);
}

sub delete {
    my ($self, $id) = @_;
    return $self->api->delete($id);
}

sub update {
    my ($self, $id, $data) = @_;
    return $self->api->put($id, $data);
}

sub delete_all {
    my $self = shift;
    Catmandu::NotImplemented->throw('Deleting all items not implemented.');
    return undef;
}

1;