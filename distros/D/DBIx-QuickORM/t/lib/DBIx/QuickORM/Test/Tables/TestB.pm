package DBIx::QuickORM::Test::Tables::TestB;
use strict;
use warnings;

use DBIx::QuickORM ':TABLE_CLASS';
use DBIx::QuickORM::MetaTable bbb => sub {
    column bbb_id => sub {
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
};

sub id { shift->column('bbb_id') }

1;
