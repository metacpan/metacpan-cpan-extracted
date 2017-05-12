use strict;
use warnings;
use Test::More;
use Test::Requires qw(
    DBI
    DBD::SQLite
    SQL::Interp
);

use DBI;
my $db = DBI->connect(
    'dbi:SQLite:dbname=:memory:', '', '', {
        RootClass          => 'DBIx::Simple::Inject',
        RaiseError         => 1,
        PrintError         => 0,
        ShowErrorStatement => 1,
    }
);

ok($db);
isa_ok($db, 'DBI::db');
isa_ok($db, 'DBIx::Simple::Inject::db');
isa_ok($db->simple(), 'DBIx::Simple');

$db->do('create table foo (id integer primary key, var text)');

ok($db->begin(), "begin()");
ok($db->query('insert into foo (id, var) values (?, ?)', 1, "one"), "query()");

$db->commit();

is_deeply($db->select(foo => ['var'], { id => 1 })->hash, { var => "one" }, "select()");
ok($db->insert(foo => { id => 2, var => "two" }), "insert()");
ok($db->update(foo => { var => "xxx"}), "update()");
ok($db->delete(foo => { id => 2 }), "delete()");

ok($db->iquery('SELECT * FROM foo WHERE id = ', 1), "iquery()");

eval {
    $db->query("foo");
};
like($db->error, qr/foo/, "error()");

ok($db->lc_columns("dummy"), "lc_columns() set");
is($db->lc_columns, "dummy", "lc_columns() get");
ok($db->keep_statements("dummy"), "keep_statements() set");
is($db->keep_statements, "dummy", "keep_statements() get");
ok($db->result_class("dummy"), "result_class() set");
is($db->result_class, "dummy", "result_class() get");
ok($db->abstract("dummy"), "abstract() set");
is($db->abstract, "dummy", "abstract() get");

ok($db->disconnect(), "disconnect()");

done_testing;
