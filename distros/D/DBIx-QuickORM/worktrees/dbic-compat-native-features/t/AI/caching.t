use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Verify the per-connection row identity cache documented in
# DBIx::QuickORM::Manual::Caching: one row object per primary key per
# connection, identity preserved across update, cache entry moved on PK
# change, uncached on delete, and sources without a primary key never cached.
#
# Each mutating subtest gets its own database file so subtest ordering and
# row mutations cannot bleed across tests.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

sub fresh_db {
    my $file = "$dir/caching_" . ($seq++) . ".sqlite";
    my $dsn  = "dbi:SQLite:dbname=$file";

    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->do('INSERT INTO users (user_id, name) VALUES (1, ?)', undef, 'bob');
    $dbh->do('INSERT INTO users (user_id, name) VALUES (2, ?)', undef, 'alice');

    # A table with no primary key cannot be deduplicated.
    $dbh->do('CREATE TABLE logs (message TEXT NOT NULL)');
    $dbh->do('INSERT INTO logs (message) VALUES (?)', undef, 'hello');
    $dbh->do('INSERT INTO logs (message) VALUES (?)', undef, 'world');
    $dbh->disconnect;

    return $dsn;
}

sub connect_orm {
    my $dsn = shift // fresh_db();
    return DBIx::QuickORM->quick(credentials => {dsn => $dsn});
}

subtest default_manager_is_cached => sub {
    my $con = connect_orm();
    isa_ok($con->manager, ['DBIx::QuickORM::RowManager::Cached'], "default manager is Cached");
    ok($con->manager->does_cache, "does_cache is true for the default manager");
    ok($con->state_does_cache, "connection reports caching is on");
};

subtest identity_same_object => sub {
    my $con = connect_orm();

    my $a = $con->handle('users')->one(user_id => 1);
    my $b = $con->handle('users')->one(user_id => 1);

    ok($a, "fetched a row");
    ref_is($a, $b, "fetching the same primary key twice returns the SAME object");

    my $c = $con->handle('users')->one(user_id => 2);
    ref_is_not($a, $c, "different primary keys are different objects");
};

subtest identity_preserved_across_update => sub {
    my $con = connect_orm();

    my $a = $con->handle('users')->one(user_id => 1);
    $a->update(name => 'bobby');

    my $b = $con->handle('users')->one(user_id => 1);
    ref_is($a, $b, "row keeps identity after an update");
    is($b->field('name'), 'bobby', "the updated value is visible through the cached object");
};

subtest cache_entry_moves_on_pk_change => sub {
    my $con = connect_orm();

    my $a = $con->handle('users')->one(user_id => 2);
    ok($a, "fetched row with user_id 2");

    $a->update(user_id => 200);
    is($a->field('user_id'), 200, "primary key changed on the row");

    my $by_new = $con->handle('users')->one(user_id => 200);
    ref_is($a, $by_new, "cache entry moved to the new primary key");

    my $by_old = $con->handle('users')->one(user_id => 2);
    ok(!$by_old, "no row remains under the old primary key in the database");

    # The stale key should not resolve to the moved object via the cache either.
    my $cached_old = $con->state_cache_lookup('users', {user_id => 2});
    ok(!$cached_old, "old primary key no longer resolves in the cache");

    my $cached_new = $con->state_cache_lookup('users', {user_id => 200});
    ref_is($cached_new, $a, "new primary key resolves to the row in the cache");
};

subtest delete_uncaches => sub {
    my $con = connect_orm();

    my $a = $con->handle('users')->one(user_id => 1);
    ok($a, "fetched row");

    my $cached_before = $con->state_cache_lookup('users', {user_id => 1});
    ref_is($cached_before, $a, "row is in the cache before delete");

    $a->delete;

    my $cached_after = $con->state_cache_lookup('users', {user_id => 1});
    ok(!$cached_after, "deleted row is removed from the cache");
};

subtest no_pk_not_cached => sub {
    my $con = connect_orm();

    my @logs = $con->handle('logs')->all;
    is(scalar(@logs), 2, "fetched the pk-less rows");

    # A pk-less source has no identity, so a fresh fetch yields fresh objects.
    my @again = $con->handle('logs')->all;
    is(scalar(@again), 2, "fetched again");

    my $same = grep { my $l = $_; grep { $l == $_ } @again } @logs;
    is($same, 0, "pk-less rows are never deduplicated into the same object");

    # A pk-less source can never resolve through the identity cache.
    my $cached = $con->state_cache_lookup('logs', {});
    ok(!$cached, "pk-less source never resolves a cached row");
};

subtest per_connection_caches_are_independent => sub {
    my $dsn = fresh_db();
    my $con1 = connect_orm($dsn);
    my $con2 = connect_orm($dsn);

    ref_is_not($con1, $con2, "two quick connections are distinct objects");

    my $r1 = $con1->handle('users')->one(user_id => 1);
    my $r2 = $con2->handle('users')->one(user_id => 1);

    ok($r1 && $r2, "both connections fetched the row");
    ref_is_not($r1, $r2, "each connection has its own cache, so its own row object");
};

done_testing;
