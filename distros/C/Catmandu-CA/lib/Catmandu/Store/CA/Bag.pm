package Catmandu::Store::CA::Bag;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Catmandu::CA::API;

with 'Catmandu::Bag';

has api => (is => 'lazy');

sub _build_api {
    my $self = shift;
    return Catmandu::CA::API->new(
        url        => $self->store->url,
        username   => $self->store->username,
        password   => $self->store->password,
        lang       => $self->store->lang,
        model      => $self->store->model
    );
}

sub generator {
    my $self = shift;
    my $field_list = $self->store->_field_list;
    my $stack = $self->api->list($field_list)->{'results'};

    return sub {
        # Consume the stack here
        return pop @{$stack};
    };
}

sub each {
    my ($self, $sub) = @_;
    my $n = 0;
    my $field_list = $self->store->_field_list;
    my $stack = $self->api->list($field_list)->{'results'};
    while (my $data = pop @{$stack}) {
        $sub->($data);
        $n++;
    }
    return $n;
}

sub get {
    my ($self, $id) = @_;
    my $field_list = $self->store->_field_list;
    return $self->api->id($id, $field_list);
}

sub add {
    my ($self, $data) = @_;
    return $self->api->add($data);
}

sub update {
    my ($self, $id, $data) = @_;
    return $self->api->update($id, $data);
}

sub delete {
    my ($self, $id) = @_;
    return $self->api->delete($id);
}

sub delete_all {
    my $self = shift;
    Catmandu::NotImplemented->throw(
        message => 'Deleting items from store not supported.'
    );
}

1;
__END__