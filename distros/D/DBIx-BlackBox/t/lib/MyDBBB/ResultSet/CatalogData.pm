package MyDBBB::ResultSet::CatalogData;

use Moose;
use namespace::autoclean;

has 'id' => (
    is => 'rw',
    isa => 'Int',
);
has 'hierarchy' => (
    is => 'rw',
    isa => 'Int',
);
has 'description' => (
    is => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;

