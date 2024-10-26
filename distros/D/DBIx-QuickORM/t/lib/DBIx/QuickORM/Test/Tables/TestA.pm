package DBIx::QuickORM::Test::Tables::TestA;
use strict;
use warnings;

use DBIx::QuickORM ':TABLE_CLASS';
use DBIx::QuickORM::MetaTable aaa => 'DBIx::QuickORM::Row::AutoAccessors', sub {
    column aaa_id => sub {
        primary_key;
        serial;
        sql_spec(
            mysql      => {type => 'INTEGER'},
            postgresql => {type => 'SERIAL'},
            sqlite     => {type => 'INTEGER'},

            type => 'INTEGER',    # Fallback
        );
    };

    column foo => sub {
        sql_spec {type => 'INTEGER'};
    };

    accessors ':ALL';
};

sub id { shift->column('aaa_id') }

1;
