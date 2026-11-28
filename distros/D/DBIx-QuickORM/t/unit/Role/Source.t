# Test origin: AI
use Test2::V0;

use Role::Tiny();
use DBIx::QuickORM::Role::Source;
use DBIx::QuickORM::Source::Query;
use DBIx::QuickORM::Source::Table;

use DBIx::QuickORM::Source::Join;

ok($_->DOES('DBIx::QuickORM::Role::Source'), "$_ consumes the role") for qw/DBIx::QuickORM::Source::Table DBIx::QuickORM::Source::Query DBIx::QuickORM::Source::Join/;

like(
    dies { Role::Tiny->apply_roles_to_package('My::Half', 'DBIx::QuickORM::Role::Source') },
    qr/missing table, pk, select_fields, field_records, from_sql, query_sql, results/,
    "table, pk, select_fields, field_records, from_sql, query_sql, and results are required",
);

done_testing;
