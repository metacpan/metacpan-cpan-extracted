package RestTest::Model::DB;

use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

use Catalyst::Utils;

__PACKAGE__->config(
    schema_class => 'RestTest::Schema',
    connect_info =>
        [ "DBI:SQLite:t/var/DBIxClass.db", "", "", { AutoCommit => 1 } ]
);

1;
