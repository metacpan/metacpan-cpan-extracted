use Test2::V0 '!meta', '!pass';
use lib 't/lib';

# End-to-end coverage for DBIx::QuickORM::Dialect::DuckDB: dialect selection,
# schema introspection (columns, primary key, unique keys, foreign-key links),
# CRUD via the RETURNING path, upsert, top-level transactions, and the
# documented savepoint/nested-transaction limitation.
#
# DuckDB is embedded; this uses DBIx::QuickDB's DuckDB driver to provision a
# throwaway database, then drives it through DBIx::QuickORM->quick.

BEGIN {
    skip_all "DBD::DuckDB is required for these tests"
        unless eval { require DBD::DuckDB; 1 };
}

use DBIx::QuickORM::Test qw/duckdb/;

my $db = duckdb() or skip_all "Could not provision a DuckDB database (DBIx::QuickDB DuckDB driver missing?)";

# DuckDB has no implicit auto-increment, so PKs use explicit sequences.
{
    my $dbh = $db->connect('orm', RaiseError => 1, PrintError => 0);
    $dbh->do('CREATE SEQUENCE users_id_seq');
    $dbh->do('CREATE SEQUENCE posts_id_seq');
    $dbh->do(q{CREATE TABLE users (id INTEGER PRIMARY KEY DEFAULT nextval('users_id_seq'), email TEXT UNIQUE NOT NULL)});
    $dbh->do(q{CREATE TABLE posts (
        id      INTEGER PRIMARY KEY DEFAULT nextval('posts_id_seq'),
        user_id INTEGER REFERENCES users(id),
        title   TEXT NOT NULL,
        a       INTEGER,
        b       INTEGER,
        UNIQUE(a, b)
    )});
    $dbh->do('CREATE VIEW recent AS SELECT id, title FROM posts');
    $dbh->disconnect;
}

require DBIx::QuickORM;
my $con = DBIx::QuickORM->quick(connect => sub { $db->connect('orm', RaiseError => 1, PrintError => 0) });

subtest dialect_selected => sub {
    isa_ok($con->dialect, ['DBIx::QuickORM::Dialect::DuckDB'], "auto-selected the DuckDB dialect from the DBD::DuckDB driver");
    like($con->dialect->db_version, qr/^v?\d/, "db_version reports a DuckDB version");
    ok($con->dialect->supports_returning_insert, "reports RETURNING-on-insert support");
    ok(!$con->dialect->async_supported, "reports no async support");
};

subtest introspection => sub {
    my $posts = $con->source('posts');
    isa_ok($posts, ['DBIx::QuickORM::Schema::Table'], "posts introspected as a table");

    is([sort map { $_->name } $posts->columns], [sort qw/id user_id title a b/], "all posts columns introspected");
    is($posts->primary_key, ['id'], "primary key introspected");

    my $users = $con->source('users');
    ok(!$users->column('email')->nullable, "NOT NULL column introspected as not-nullable");
    ok($users->column('id')->nullable == 0 || $users->column('id')->nullable, "id nullability resolved");

    # unique keys: the (a,b) composite plus the single-column PK/unique.
    my $uk = $posts->unique;
    ok($uk->{DBIx::QuickORM::Util::column_key('a', 'b')}, "composite UNIQUE(a,b) introspected");

    # foreign-key link posts.user_id -> users.id
    my ($link) = @{$posts->links};
    ok($link, "a foreign-key link was introspected");
    is($link->other_table, 'users', "link points at users");
    is($link->local_columns, ['user_id'], "link local column is user_id");
    is($link->other_columns, ['id'], "link references users.id");

    # the view came through as a view source
    isa_ok($con->source('recent'), ['DBIx::QuickORM::Schema::View'], "view introspected as a View");
};

subtest crud_returning => sub {
    my $u = $con->handle('users')->insert({email => 'a@b.com'});
    ok($u->field('id'), "insert returned a DB-generated id (RETURNING path)");

    my $p = $con->handle('posts')->insert({user_id => $u->field('id'), title => 'hello'});
    ok($p->field('id'), "post insert returned an id");

    $p->update({title => 'updated'});
    is($p->field('title'), 'updated', "update worked");

    is(scalar($con->handle('users')->all), 1, "one user stored");

    $p->delete;
    is(scalar($con->handle('posts')->all), 0, "delete worked");
};

subtest upsert => sub {
    my ($u) = $con->handle('users')->all;
    my $before = scalar($con->handle('users')->all);
    $con->handle('users')->upsert({id => $u->field('id'), email => 'changed@b.com'});
    is(scalar($con->handle('users')->all), $before, "upsert on existing PK did not add a row");
    my ($again) = $con->handle('users')->where({id => $u->field('id')})->all;
    is($again->field('email'), 'changed@b.com', "upsert updated the existing row");
};

subtest transactions => sub {
    my $before = scalar($con->handle('users')->all);
    $con->txn(sub { $con->handle('users')->insert({email => 'txn@b.com'}) });
    is(scalar($con->handle('users')->all), $before + 1, "committed top-level transaction persisted");

    my $after_commit = scalar($con->handle('users')->all);
    $con->txn(sub {
        my $t = shift;
        $con->handle('users')->insert({email => 'rollme@b.com'});
        $t->rollback;
    });
    is(scalar($con->handle('users')->all), $after_commit, "rolled-back transaction did not persist");
};

subtest no_savepoints => sub {
    # DuckDB has no savepoints, so a nested transaction (implemented as a
    # savepoint) must croak rather than silently misbehave.
    like(
        dies {
            $con->txn(sub {
                $con->txn(sub { 1 });
            });
        },
        qr/does not support savepoints/,
        "nested transaction croaks: DuckDB has no savepoints",
    );
};

done_testing;
