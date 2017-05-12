package # hide from PAUSE
    CatTest::Model::DBIC;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'DBICTest::Schema',
    connect_info => [ 'dbi:SQLite:t/var/DBIxClass.db', '', '' ],
);

1;
