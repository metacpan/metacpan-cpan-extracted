# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Caching.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $dbh = $orm->connection->dbh;

    my $id      = $orm->insert(users => {name    => 'Ann'})->field('id');
    my $post_id = $orm->insert(posts => {user_id => $id, title => 'Hello'})->field('id');

    # ONE COPY PER ROW
    my $one = $orm->find(users => $id);
    my $two = $orm->handle('users')->where({id => $id})->only;

    # true: the same hash, so two objects share one copy of the data
    my $shared = $one->row_data == $two->row_data;

    $one->update({name => 'Ann B'});
    my $stale = $two->is_canon;         # false: $one's write replaced the canonical copy
    my $name  = $two->field('name');    # 'Ann': $two still holds the data it read

    # croaks: $two is not canonical
    my $ok = eval { $two->update({email => 'b@example.com'}); 1 };

    $two->refresh;                      # reads the database: $two is canonical again
    $two->update({email => 'b@example.com'});

    ok($shared, "two row objects for one row share its data");
    ok(!$stale, "a write through one leaves the other holding old data");
    is($name, 'Ann', "which it still reads");
    ok(!$ok, "writing through it croaks");
    my $three = $orm->find(users => $id);
    $two->update({name => 'Ann C'});
    like(dies { $three->update({name => 'x'}) }, qr/is not canon/, "the croak names the problem");
    ref_is($two->row_data, $orm->find(users => $id)->row_data, "refresh takes the canonical copy");
    is($orm->find(users => $id, cache => 0)->field('email'), 'b@example.com', "and the write goes through");

    # ENFORCE_CANON
    $one->refresh;
    # write by primary key alone, whatever the ORM holds
    $two->update({email => 'c@example.com'}, enforce_canon => 0);

    my $lax = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        enforce_canon => 0,    # for every write outside a transaction
    );

    ok(!$one->is_canon, "a stale row");
    is($orm->find(users => $id, cache => 0)->field('email'), 'c@example.com', "writes with enforce_canon => 0");
    my $lax_row = $lax->find(users => $id);
    $lax->clear_cache;
    ok(lives { $lax_row->update({name => 'Ann D'}) }, "an ORM with enforce_canon => 0 writes stale rows outside a transaction");
    $lax->clear_cache;
    $lax->txn(sub {
        like(dies { $lax_row->update({name => 'Ann E'}) }, qr/is not canon/, "but inside a transaction the check is on");
        like(dies { $lax_row->delete },                    qr/is not canon/, "for delete too");
        ok(lives { $lax_row->update({name => 'Ann E'}, enforce_canon => 0) }, "unless the call turns it off");
    });

    # READS FROM THE CANONICAL COPY
    $one->refresh;
    my $queries = 0;
    my $watch   = on_execute { $queries++ if $_[0] =~ m/^SELECT/ };

    my $ann   = $orm->find(users => $id);
    my $again = $orm->find(users => $id);    # no query: the canonical copy has every field asked for

    my $fresh = $orm->find(
        users => $id,
        cache => 0,                          # reads the database (same data, so the canonical copy stays)
    );

    is($queries, 1, "only find with cache => 0 reads the database while the row is held");
    ref_is($again->row_data, $ann->row_data, "the second find returns the canonical copy");
    ref_is($fresh->row_data, $ann->row_data, "and so does the read when the data matches");
    is($ann->field('name'), 'Ann E', "with the data the database holds");

    $db->connect->do("UPDATE users SET name = 'Changed' WHERE id = $id");    # another process

    my $changed = $orm->find(
        users => $id,
        cache => 0,                                                          # new data: this becomes the canonical copy
    );
    my $old = $ann->is_canon;                                                # false
    $ann->refresh;                                                           # true again

    is($changed->field('name'), 'Changed', "a read finding changed data");
    ok(!$old,          "makes the old copy stale");
    ok($ann->is_canon, "refresh makes the row canonical again");
    is($ann->field('name'), 'Changed', "with the new data");
    $queries = 0;
    my $h = $orm->handle('users')->where({id => $id});
    is($queries, 0, "where runs no query");
    my @all = $h->all;
    is($queries, 1, "the first all does");
    ref_is($all[0]->row_data, $ann->row_data, "and keeps the canonical copy when the data matches");
    $h->all;
    is($queries, 1, "a second all reuses the handle's rows");
    $h->iter;
    is($queries, 1, "so does iter");
    $h->clear;
    $h->all;
    is($queries, 2, "after clear the next read runs the query again");
    $ann->refresh;
    is($queries, 3, "refresh always reads the database");

    $queries = 0;
    my $apart = $orm->handle('users')->no_cache;
    my @rows  = $apart->all;                       # not canonical, and the row cache does not change

    # find is a CRUD operation and reads the canonical copy first, but cache => 0 forces a read
    my $read = $apart->find($id, cache => 0);

    ok(!$rows[0]->is_canon, "a no_cache handle's rows are not canonical");
    ref_is_not($rows[0]->row_data, $ann->row_data, "and leave the canonical copy alone");
    ok($ann->is_canon, "which stays canonical");
    is($queries, 2, "find with cache => 0 reads the database");
    ref_is($apart->find($id)->row_data, $ann->row_data, "while a plain find returns the canonical copy");
    is($queries, 2, "without a query");
    ok($apart->cache->where({id => $id})->only->is_canon, "cache undoes no_cache");
    undef $watch;

    # HOW LONG ROWS ARE HELD
    # the row object is gone at once
    my $tmp_id = $orm->insert(users => {name => 'Tmp'})->field('id');
    my $held   = $orm->refresh_row(
        users => {id => $tmp_id},
        db    => 0,                 # undef: nothing holds the row any more
    );

    my $keeper = DBIx::QuickORM->new(
        credentials => {
            dsn  => $dsn,
            user => $user,
            pass => $pass,
        },
        retain_cache => 1,
    );
    my $kept_id = $keeper->insert(users => {name => 'Kept'})->field('id');
    my $kept    = $keeper->refresh_row(
        users => {id => $kept_id},
        db    => 0,                  # the row: held until clear_cache
    );

    is($held,                undef,  "by default a row nothing holds is let go");
    is($kept->field('name'), 'Kept', "retain_cache keeps it");
    ok($orm->refresh_row(users => {id => $id}, db => 0), "a row something holds is held");
    $keeper->clear_cache;
    is($keeper->refresh_row(users => {id => $kept_id}, db => 0), undef, "until clear_cache");

    # CLEAR_CACHE
    # one row: a hashref, arrayref, row, or single value, as find takes it
    $orm->clear_cache(users => $id);
    $orm->clear_cache('users');      # one table
    $orm->clear_cache;               # everything
    my $current = $ann->is_canon;    # false: refresh makes it canonical again

    my $post = $orm->find(posts => $post_id);
    # a bulk update or delete drops the canonical copies of its table's rows
    $orm->handle('posts')->where({views => 0})->update({views => 1});
    my $dropped = $post->is_canon;    # false

    # mark_deleted: the held rows it deleted also say so
    my $temp = $orm->insert(
        posts => {
            user_id => $ann->field('id'),
            title   => 'Temp',
        }
    );
    $orm->handle('posts')->where({title => 'Temp'})->delete(mark_deleted => 1);
    my $deleted = $temp->was_deleted;    # true

    ok($deleted,  "mark_deleted marks the deleted rows");
    ok(!$current, "clear_cache drops the canonical copy");
    $ann->refresh;
    ok($ann->is_canon, "refresh makes the row canonical again");
    ok(!$dropped,      "a bulk update drops the table's canonical copies");
    ok($ann->is_canon, "and leaves other tables alone");
    for my $pk ({id => $id}, [$id], $ann) {
        $ann->refresh;
        $orm->clear_cache(users => $pk);
        ok(!$ann->is_canon, "clear_cache takes the key as a " . (ref($pk) eq 'HASH' ? 'hashref' : ref($pk) eq 'ARRAY' ? 'arrayref' : 'row'));
    }
};

done_testing;
