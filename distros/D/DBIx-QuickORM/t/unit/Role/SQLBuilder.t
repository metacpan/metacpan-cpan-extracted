# Test origin: AI
use Test2::V0;

use Role::Tiny();
use DBIx::QuickORM::Role::SQLBuilder;
use DBIx::QuickORM::SQLBuilder::SQLAbstract;

ok(DBIx::QuickORM::SQLBuilder::SQLAbstract->DOES('DBIx::QuickORM::Role::SQLBuilder'), "The default builder consumes the role");

like(
    dies { Role::Tiny->apply_roles_to_package('My::Half', 'DBIx::QuickORM::Role::SQLBuilder') },
    qr/missing select, count, update, delete, combine_where/,
    "select, count, update, delete, and combine_where are required",
);

done_testing;
