package Catmandu::Store::RKD::Bag;

use Moo;
use LWP::UserAgent;

use Catmandu::Store::RKD::API::Number;

use Catmandu::Sane;

with 'Catmandu::Bag';


sub generator {
    my $self = shift;
}

sub get {
    my ($self, $id) = @_;
    my $sr = Catmandu::Store::RKD::API::Number->new(
        artist_id => $id
    );
    return $sr->results;
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