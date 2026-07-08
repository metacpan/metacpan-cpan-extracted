use Test2::V0;

# Regression: STH::Aside re-composed Role::STH and Role::Async on top of its
# parent STH::Async, which reinstalled the roles' croaking default cancel/
# cancel_supported and shadowed the working STH::Async overrides -- so an aside
# query could never be cancelled. The roles now arrive only via the parent.

require DBIx::QuickORM::STH::Aside;
require DBIx::QuickORM::STH::Async;

ok(DBIx::QuickORM::STH::Aside->DOES('DBIx::QuickORM::Role::STH'),   "Aside still consumes Role::STH");
ok(DBIx::QuickORM::STH::Aside->DOES('DBIx::QuickORM::Role::Async'), "Aside still consumes Role::Async");

ref_is(
    DBIx::QuickORM::STH::Aside->can('cancel'),
    DBIx::QuickORM::STH::Async->can('cancel'),
    "Aside inherits STH::Async's cancel instead of the croaking role default",
);
ref_is(
    DBIx::QuickORM::STH::Aside->can('cancel_supported'),
    DBIx::QuickORM::STH::Async->can('cancel_supported'),
    "Aside inherits STH::Async's cancel_supported",
);

done_testing;
