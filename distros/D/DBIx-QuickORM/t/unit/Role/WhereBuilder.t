# Test origin: AI
use Test2::V0;

use Role::Tiny();
use DBIx::QuickORM::Role::WhereBuilder;
use DBIx::QuickORM::WhereBuilder::RawSQL;
use DBIx::QuickORM::WhereBuilder::Simple;
use DBIx::QuickORM::WhereBuilder::SQLAbstract;

ok("DBIx::QuickORM::WhereBuilder::$_"->DOES('DBIx::QuickORM::Role::WhereBuilder'), "$_ consumes the role") for qw/RawSQL Simple SQLAbstract/;

like(
    dies { Role::Tiny->apply_roles_to_package('My::Half', 'DBIx::QuickORM::Role::WhereBuilder') },
    qr/missing can_build_where, build_where/,
    "can_build_where and build_where are required",
);

done_testing;
