package MyDBBB::Procedures::ErrorTest3;

use Moose;
use namespace::autoclean;

with 'DBIx::BlackBox::Procedure' => {
    name => 'error_test3',
};

__PACKAGE__->meta->make_immutable;

1;

