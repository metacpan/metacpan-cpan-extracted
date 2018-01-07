package Blog::Model::Author;

use strict;
use warnings;

use Moose;

with 'DBIx::NoSQL::Store::Manager::Model';

has name => (
    traits   => [ 'StoreKey' ],
    is       => 'ro',
    required => 1,
);

has bio => (
    is     => 'rw',
);

__PACKAGE__->meta->make_immutable;

1;
