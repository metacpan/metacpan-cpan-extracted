use Test2::V0 '!meta', '!pass';

# Import-time option handling: only/skip must not disable the machinery
# ('import' + 'builder') that a downstream `use My::ORM` depends on, an unknown
# import 'type' must be rejected, and `no DBIx::QuickORM` must remove a function
# installed under a renamed name.

# 1. only => ['table'] keeps import + builder installed.
{
    package My::Only;
    use DBIx::QuickORM only => ['table'];
}

ok(My::Only->can('table'),   "only => ['table'] installs the requested function");
ok(My::Only->can('builder'), "only => [...] still installs 'builder'");
# ->can('import') is always true (every package inherits a default import), so
# check the actually-installed slot in the package instead.
ok(defined(&My::Only::import), "only => [...] still installs 'import' for a type=>orm package");
ok(!My::Only->can('schema'), "only => ['table'] does skip the non-listed functions");

# 2. Unknown type croaks at import time.
like(
    dies { eval "package My::Bogus; use DBIx::QuickORM type => 'bogus'; 1" or die $@ },
    qr/Unknown import type 'bogus'/,
    "an unknown import type croaks",
);

# 3. A renamed function is removed by unimport.
{
    package My::Rename;
    use DBIx::QuickORM rename => {table => 'mytable'};
}

ok(My::Rename->can('mytable'), "rename installs the function under the new name");
ok(!My::Rename->can('table'),  "rename does not also install the original name");

# This is exactly what `no DBIx::QuickORM` inside My::Rename resolves to.
DBIx::QuickORM->unimport_from('My::Rename');

ok(!My::Rename->can('mytable'), "unimport removes the renamed function");

done_testing;
