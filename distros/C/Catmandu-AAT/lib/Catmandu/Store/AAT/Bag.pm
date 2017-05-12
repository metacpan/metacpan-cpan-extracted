package Catmandu::Store::AAT::Bag;

use strict;
use warnings;

use Moo;
use Catmandu::Sane;

use Catmandu::AAT::API;

with 'Catmandu::Bag';

sub generator {
    my $self = shift;
}

sub get {
    my ($self, $id) = @_;
    my $api = Catmandu::AAT::API->new(term => $id, language => $self->store->lang);
    return $api->id();
}

sub add {
    my ($self, $data) = @_;
    Catmandu::NotImplemented->throw(
        message => 'Adding item to store not supported.'
    );
}

sub update {
    my ($self, $id, $data) = @_;
    Catmandu::NotImplemented->throw(
        message => 'Updating item in store not supported.'
    );
}

sub delete {
    my ($self, $id) = @_;
    Catmandu::NotImplemented->throw(
        message => 'Deleting item from store not supported.'
    );
}

sub delete_all {
    my $self = shift;
    Catmandu::NotImplemented->throw(
        message => 'Deleting items from store not supported.'
    );
}

1;
__END__