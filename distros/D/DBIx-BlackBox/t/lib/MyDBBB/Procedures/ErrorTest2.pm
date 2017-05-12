package MyDBBB::Procedures::ErrorTest2;

use Moose;
use namespace::autoclean;

with 'DBIx::BlackBox::Procedure' => {
    name => 'error_test2',
    resultsets => [qw(
        MyDBBB::ResultSet::Catalogs
        MyDBBB::ResultSet::CatalogData
    )],
};

has 'root_id' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
);
has 'org_id' => (
    is => 'rw',
    isa => 'Maybe[Int]',
);

__PACKAGE__->meta->make_immutable;

1;

