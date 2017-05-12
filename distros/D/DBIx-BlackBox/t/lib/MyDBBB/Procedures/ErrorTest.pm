package MyDBBB::Procedures::ErrorTest;

use Moose;
use namespace::autoclean;

with 'DBIx::BlackBox::Procedure' => {
    name => 'error_test',
    resultsets => [qw(
        MyDBBB::ResultSet::Catalogs
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

