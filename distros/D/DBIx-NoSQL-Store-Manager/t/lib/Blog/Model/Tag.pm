package Blog::Model::Tag;

use strict;
use warnings;

use Moose;

with 'DBIx::NoSQL::Store::Manager::Model';

has tag => (
    traits   => [ 'StoreKey' ],
    is       => 'ro',
    required => 1,
);


__PACKAGE__->meta->make_immutable;

1;
