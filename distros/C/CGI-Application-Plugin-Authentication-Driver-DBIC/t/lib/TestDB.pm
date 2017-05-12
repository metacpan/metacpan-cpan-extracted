package TestDB;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/ Users /);

sub setuptables {
   my $conn =  __PACKAGE__->connect('dbi:SQLite:t/db/users.db'); 

    foreach (__PACKAGE__->sources) {
        __PACKAGE__ ->class($_)->setuptable($conn->storage->dbh);
    }             
}

1;

