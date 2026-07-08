use Test2::V0 '!meta', '!pass';
use DBIx::QuickORM;

use lib 't/lib';
use DBIx::QuickORM::Test;

# Cross-flavor consistency for trigger-driven values: a column a trigger sets on
# write is auto-marked volatile and read back with the real stored value on
# EVERY flavor. On SQLite and PostgreSQL a RETURNING clause would miss an
# AFTER-trigger change (RETURNING is computed before AFTER triggers), so the
# dialect must fall back to a fetch for a table with triggers -- exactly what
# MySQL/MariaDB already do (no RETURNING). Each flavor's schema (with a
# flavor-appropriate trigger) is loaded from the sibling SQL file. DuckDB has no
# triggers, so it is skipped.

do_for_all_dbs {
    my $db = shift;

    if (curqdb() eq 'DuckDB') {        # DuckDB does not support triggers
        ok(1, "DuckDB has no triggers; the RETURNING/trigger case does not apply");
        return;
    }

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill sub { };
    };

    # Introspecting the triggered table warns (expected: we cannot fully resolve
    # trigger effects). Drop just that warning so it does not flood the output.
    local $SIG{__WARN__} = sub {
        return if $_[0] =~ /has an insert\/update trigger/;
        warn $_[0];
    };

    my $con = orm('my_orm')->connect;
    my $name = curname();

    my $t = $con->schema->table('things');
    ok($t->has_triggers, "has_triggers detected on a triggered table ($name)");
    ok($t->column('tag')->volatile, "the trigger-set column 'tag' is auto-marked volatile ($name)");

    my $row = $con->handle('things')->insert({name => 'alice'});
    is($row->field('tag'), 'DB:alice', "trigger-computed value read back correctly, not the untrusted written value ($name)");

    # A safe (trigger-free) table still uses the fast RETURNING path and reads
    # back normally.
    my $safe = $con->handle('plain')->insert({name => 'bob'});
    is($safe->field('name'), 'bob', "a trigger-free table still round-trips normally ($name)");
    ok(!$con->schema->table('plain')->has_triggers, "the trigger-free table is not flagged has_triggers ($name)");
};

done_testing;
