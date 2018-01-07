package Blog::Model::Entry;

use strict;
use warnings;

use Moose;

with 'DBIx::NoSQL::Store::Manager::Model';

has url => (
    traits   => [ 'StoreKey' ],
    is       => 'ro',
    required => 1,
);

has author => (
    traits => [ 'StoreModel' ],
    store_model => 'Blog::Model::Author',
    is     => 'rw',
);


__PACKAGE__->meta->make_immutable;

1;
