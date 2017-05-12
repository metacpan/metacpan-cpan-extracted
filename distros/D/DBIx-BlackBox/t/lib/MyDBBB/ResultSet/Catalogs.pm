package MyDBBB::ResultSet::Catalogs;

use Moose;
use namespace::autoclean;

has 'id' => (
    is => 'rw',
    isa => 'Int',
);
has 'name' => (
    is => 'rw',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;


