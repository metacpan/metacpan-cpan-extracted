package TestAppCheckHasCol::Model::TestAppDB;

use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

use Catalyst::Utils;

__PACKAGE__->config(
    schema_class => 'RestTest::Schema',
    connect_info => [
        "dbi:SQLite:t/var/DBIxClass.db",
        undef,
        undef,
        {AutoCommit => 1}
    ]
);

1;
