# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test qw/do_for_all_dbs on_execute/;
use DBIx::QuickORM::Value qw/sql/;

my %BLOB = (PostgreSQL => 'BYTEA', MySQL => 'VARBINARY(20)', MariaDB => 'VARBINARY(20)', SQLite => 'BLOB', DuckDB => 'BLOB');

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE people (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20), age INTEGER, bio VARCHAR(50))");
    $dbh->do("CREATE TABLE blobs (id INTEGER NOT NULL PRIMARY KEY, data $BLOB{$family})");
    $dbh->do("CREATE TABLE marks (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20))");
    $dbh->do("CREATE TABLE nokey (name VARCHAR(20))");
    $dbh->do("CREATE TABLE pairs (u CHAR(36) NOT NULL, n INTEGER NOT NULL, PRIMARY KEY (u, n))");

    my $orm = DBIx::QuickORM->new(
        dbh       => $dbh,
        row_class => undef,
        omit      => {people => ['bio']},
        types     => {pairs  => {u => 'UUID'}},
    );
    my $people = $orm->handle('people');
    my $q      = $orm->connection->dialect->quote_char;

    subtest insert_and_find => sub {
        $people->insert({id => $_, name => "p$_", age => $_ * 10, bio => "bio $_"}) for 1 .. 5;
        my $three = $people->find(3);
        is($three, {id => 3, name => 'p3', age => 30}, "find reads the default fields");
        ok($orm->is_canon(people => $three), "and the row is canon");
        is($people->refresh_row({id => 3}, fields => ['bio'])->{bio}, 'bio 3', "refresh_row fills in the table");
    };

    subtest fetch => sub {
        my $ids = sub { [map { $_->{id} } $_[0]->all] };
        is($ids->($people->order_by('id')),                                         [1 .. 5],                           "all, in order");
        is($ids->($people->where({age => {'>' => 25}})->order_by({-desc => 'id'})), [5, 4, 3],                          "where and a descending order");
        is($ids->($people->order_by('id')->limit(2)->offset(1)),                    [2, 3],                             "limit and offset");
        is($ids->($people->order_by('id')->offset(3)),                              [4, 5],                             "offset alone");
        is($people->where({name => 'p2'})->only,                                    {id => 2, name => 'p2', age => 20}, "only");
        is($people->where({name => 'none'})->only,                                  undef,                              "only is undef with no rows");
        is($people->order_by('id')->first->{id},                                    1,                                  "first");
        is($people->order_by('id')->last->{id},                                     5,                                  "last");

        my $it = $people->order_by('id')->iter;
        my @seen;
        while (my $r = $it->next) { push @seen => $r->{id} }
        is(\@seen, [1 .. 5], "iter walks every row");

        is($people->fields(['name'])->where({id => 1})->only, {id => 1, name => 'p1', age => 10}, "A subset of fields is ingested into the held row");
        $orm->clear_cache;
        is($people->fields(['bio'])->where({id => 1})->only, {id => 1, bio => 'bio 1'}, "fields selects only those, with the primary key");
    };

    subtest one_query_per_handle => sub {
        my $runs  = 0;
        my $watch = on_execute { $runs++ if $_[0] =~ m/\bpeople\b/ };
        my $h     = $people->order_by('id');

        is($h->first->{id},            1,        "first runs the query");
        is([map { $_->{id} } $h->all], [1 .. 5], "all");
        is($h->last->{id},             5,        "last");
        ok($h->ready, "ready");
        is($runs, 1, "the handle's reading methods share one query");

        my ($one, $two) = ($h->iter, $h->iter);
        ok($one != $two, "iter returns a new iterator each call");
        is($runs,            1, "over the handle's one query");
        is($one->next->{id}, 1, "starting at the first row");
        is($one->next->{id}, 2, "each iterator");
        is($two->next->{id}, 1, "at its own position");

        is($h->next->{id},   1, "next on the handle walks its own iterator");
        is($h->next->{id},   2, "keeping its position");
        is($one->next->{id}, 3, "apart from the iterators'");
        $h->reset;
        is($h->next->{id}, 1, "reset on the handle rewinds it");
        is($runs,          1, "still one query");

        is(scalar(@{[$h->limit(10)->all]}), 5, "a modifier's new handle");
        is($runs,                           2, "runs its own query");
        $h->all;
        is($runs, 2, "while the original keeps its rows");

        $h->clear;
        is($runs,            2, "clear sends nothing");
        is($h->next->{id},   1, "the next read starts over");
        is($runs,            3, "with the query sent again");
        is($two->next->{id}, 2, "an iterator from before clear keeps its rows");
        is($runs,            3, "without a query");
    };

    subtest string_where => sub {
        my $ids = sub { [sort map { $_->{id} } $_[0]->all] };
        is($ids->($people->where('id > 3')->and({name => 'p4'})),                                    [4],       "A plain-string where is raw SQL under and");
        is($ids->($people->where('id > 3')->or({name => 'p1'})),                                     [1, 4, 5], "and under or");
        is($ids->($people->where({name => 'p1'})->or('id > 3')),                                     [1, 4, 5], "on either side");
        is($ids->($people->where('id > 3')->and('id < 5')),                                          [4],       "and as both sides");
        is($ids->($people->where('id = 1 OR id = 2')->and({name => 'p2'})),                          [2],       "A raw side stays grouped: its OR does not escape and");
        is($ids->($people->where(sql('id = ? OR id = ?', 1, 2))->and({name => 'p2'})),               [2],       "and so does an sql() side");
        is($ids->($people->where(sql('id = ? OR id = ?', 1, 2))->or({name => 'p5'})),                [1, 2, 5], "under or too");
        is($ids->($people->where({name => 'p5'})->or('id = 1 OR id = 2')->and({age => 20})),         [2],       "and when nested again");
        is($ids->($people->where(\['id = ? OR id = ?', [id => 1], [id => 2]])->and({name => 'p2'})), [2],       "and so does a \\[...] side");
        is($ids->($people->where('')),                                                               [1 .. 5],  "An empty-string where is no where");
        is($ids->($people->where({id => 1})->and('')),                                               [1],       "An empty-string condition drops out of and");
        like(dies { my $x = $people->where('')->or({id => 1}) }, qr/^or\(\) needs a where/, "or on an empty-string where croaks");
    };

    subtest count => sub {
        is($people->count, 5, "count counts every row");
        is($people->where({age => {'<' => 30}})->count,           2, "or the rows matching the where");
        is($people->where({age => {'<' => 30}})->limit(1)->count, 2, "ignoring the limit");
    };

    subtest queries => sub {
        my $h = $orm->handle(\["SELECT id, name FROM people WHERE age > ? ORDER BY id DESC", 30]);
        is([map { $_->{id} } $h->all], [5, 4], "A query runs as written, with its binds and order");
        ok(!$orm->is_canon(people => $h->first), "its rows are never canon");
        is([map { $_->{name} } $h->where({id => 4})->all], ['p4'], "and becomes a subquery under a where");
        is($h->count,                                      2,      "count works on a query");
        like(dies { $h->insert({id => 9}) }, qr/needs a handle on a table, not a query/, "a query cannot be written through");
    };

    subtest bulk => sub {
        my $five = $people->find(5);
        ok($orm->is_canon(people => $five), "A held row");
        is($people->where({age => {'>=' => 40}})->update({name => 'old'}), 2, "update returns the number of rows changed");
        ok(!$orm->is_canon(people => $five), "and stops holding any row of the table");
        is($dbh->selectcol_arrayref("SELECT id FROM people WHERE name = 'old' ORDER BY id"), [4, 5], "the rows changed");

        my $txn = $orm->txn;
        my $one = $people->find(1);
        is($people->where({name => 'old'})->delete, 2, "delete returns the number of rows deleted");
        is($people->count,                          3, "and they are gone");
        $txn->rollback;
        is($people->count, 5, "a rollback restores them");

        is($people->update({age => 0}), 5, "Without a where every row is updated");
    };

    subtest bulk_delete_mark_deleted => sub {
        my $marks = $orm->handle('marks');
        my $state = sub { DBIx::QuickORM::LookupTable->row_state($_[0]) // 'live' };
        my $depth = sub { scalar @{$orm->connection->txns} };
        my $mysql = !$orm->connection->dialect->supports_returning_delete;
        $marks->insert({id => $_, name => "m$_"}) for 1 .. 8;
        my %held = map { $_ => $marks->find($_) } 1 .. 8;

        my @sql;
        my $watch = on_execute { push @sql => $_[0] if $_[0] =~ m/marks/ };
        is($marks->where({id => {'<=' => 2}})->delete(mark_deleted => 1), 2, "mark_deleted returns the number of rows deleted");
        undef $watch;
        is([map { $state->($held{$_}) } 1 .. 3], ['deleted', 'deleted', 'live'], "and marks exactly the deleted rows' held hashes");
        ok(!$orm->is_canon(marks => $held{3}), "the rest of the table is dropped, as by any bulk write");
        is($depth->(), 0, "no transaction is left open");
        if ($mysql) {
            is(scalar(@sql), 2, "$family: two statements");
            like($sql[0], qr/^SELECT .* FOR UPDATE$/, "a SELECT ... FOR UPDATE of the keys");
            like($sql[1], qr/^DELETE /,               "then the DELETE");
            unlike($sql[1], qr/ IN /, "with the same where, not the key list");
        }
        else {
            is(scalar(@sql), 1, "$family: one statement");
            like($sql[0], qr/^DELETE .* RETURNING ${q}id${q}$/, "DELETE ... RETURNING the key");
        }

        $held{3} = $marks->find(3);    # held again: the first delete dropped the table
        my $txn = $orm->txn;
        is($marks->where({id => 3})->delete(mark_deleted => 1), 1,         "Inside a transaction");
        is($state->($held{3}),                                  'deleted', "the row is marked");
        is($depth->(),                                          1,         "and no extra transaction level is left");
        $txn->rollback;
        is($state->($held{3}),              'live', "a rollback unmarks it");
        is($marks->where({id => 3})->count, 1,      "and the row is back");

        if ($orm->connection->dialect->supports_savepoints) {
            my $outer = $orm->txn;
            my $four  = $marks->find(4);
            my $inner = $orm->txn;
            $marks->where({id => 4})->delete(mark_deleted => 1);
            is($state->($four), 'deleted', "Inside a savepoint the row is marked");
            $inner->rollback;
            is($state->($four), 'live', "rolling the savepoint back unmarks it");
            $outer->commit;
        }

        $held{5} = $marks->find(5);    # each bulk delete drops the table
        $orm->txn(sub { $marks->where({id => 5})->delete(mark_deleted => 1) });
        is($state->($held{5}), 'deleted', "A commit keeps the mark");

        is($marks->where({id => 99})->delete(mark_deleted => 1), 0, "Nothing matching deletes and marks nothing");

        my $seven = $marks->find(7);
        ok($orm->is_canon(marks => $seven), "A held row");
        my $six = $held{6};
        is($marks->where({id => 6})->delete(mark_deleted => 0), 1,      "mark_deleted => 0 is a plain bulk delete");
        is($state->($six),                                      'live', "which marks nothing");
        ok(!$orm->is_canon(marks => $seven), "and drops the table's held rows");

        my $pairs = $orm->handle('pairs');
        my @uuid  = ('0190f0a4-7d6c-7e5b-9c1a-3f2e4d5c6b7a', '0190f0a4-7d6c-7e5b-9c1a-3f2e4d5c6b7b');
        my @pair  = map {
            my $u = $_;
            map { $pairs->insert({u => $u, n => $_}) } 1 .. 2
        } @uuid;
        @sql   = ();
        $watch = on_execute { push @sql => $_[0] if $_[0] =~ m/pairs/ };
        is($pairs->where({n => 1})->delete(mark_deleted => 1), 2, "A compound typed key: the count");
        undef $watch;
        is([map { $state->($_) } @pair], ['deleted', 'live', 'deleted', 'live'], "and exactly the deleted rows are marked");
        is($pairs->count,                2,                                      "the others remain");

        if ($mysql) {
            like($sql[0], qr/^SELECT ${q}u${q}, ${q}n${q} FROM .* FOR UPDATE$/, "$family: the SELECT names every key column");
        }
        else {
            like($sql[0], qr/^DELETE .* RETURNING ${q}u${q}, ${q}n${q}$/, "$family: RETURNING names every key column");
        }

        like(
            dies { $orm->handle('nokey')->delete(mark_deleted => 1) },
            qr/^delete\(mark_deleted => 1\) needs a primary key, and the table 'nokey' has none/,
            "A table without a primary key croaks"
        );
        like(dies { $marks->delete(marked => 1) }, qr/^delete\(\) takes only 'mark_deleted => \$bool'/, "Other arguments croak");
    };

    subtest no_cache => sub {
        my $held = $people->find(2);
        $dbh->do("UPDATE people SET name = 'changed' WHERE id = 2");

        my $row = $people->no_cache->where({id => 2})->only;
        is($row, {id => 2, name => 'changed', age => 0}, "A no_cache read returns the rows as fetched");
        ok(!$orm->is_canon(people => $row),  "which are not current");
        ok($orm->is_canon(people  => $held), "and leaves the held row current");
        is($held->{name}, 'p2', "and unchanged");
        like(dies { $people->update_row($row, {age => 1}) }, qr/is not canon/, "Writing with a no_cache row croaks under enforce_canon");

        my $obj = $people->row_class('DBIx::QuickORM::Row')->no_cache->where({id => 2})->only;
        isa_ok($obj, ['DBIx::QuickORM::Row'], "Row objects work too");
        is($obj->field('name'), 'changed', "over the fetched data");
        ok(!$orm->is_canon(people => $obj), "and are not current either");
        like(dies { $obj->update({age => 1}) }, qr/is not canon/, "so they cannot write");

        like(dies { $people->no_cache(1) }, qr/^no_cache\(\) takes no arguments/,                                 "no_cache takes no argument");
        like(dies { $people->no_cache; 1 }, qr/^no_cache\(\) returns a new handle and leaves this one unchanged/, "and croaks in void context");
        $orm->clear_cache;
    };

    subtest cache => sub {
        $dbh->do("UPDATE people SET name = 'again' WHERE id = 3");

        my $row = $people->no_cache->cache->where({id => 3})->only;
        is($row->{name}, 'again', "cache undoes no_cache: the read is fetched");
        ok($orm->is_canon(people => $row),                  "and ingested, so the row is current");
        ok(lives { $people->update_row($row, {age => 3}) }, "so writing with it passes enforce_canon");

        my $read = $people->cache->where({id => 3})->only;
        ok($orm->is_canon(people => $read), "cache on a handle that never had no_cache changes nothing: rows are ingested");

        like(dies { $people->cache(1) }, qr/^cache\(\) takes no arguments/,                                 "cache takes no argument");
        like(dies { $people->cache; 1 }, qr/^cache\(\) returns a new handle and leaves this one unchanged/, "and croaks in void context");
        $orm->clear_cache;
    };

    subtest binary => sub {
        my $bytes = "\x00\xff\xe9 \x01";
        my $blobs = $orm->handle('blobs');
        $blobs->insert({id => 1, data => $bytes});
        $blobs->insert({id => 2, data => "\x01"});
        is($blobs->where({data => $bytes})->only->{id},                   1, "A value compared with a binary field is bound as binary");
        is($blobs->where({data => $bytes})->update({data => "\x02\x00"}), 1, "in bulk writes too");
        is($blobs->where({data => "\x02\x00"})->count,                    1, "and the change is bound as binary");
    };

    subtest find_or_insert => sub {
        my $marks = $orm->handle('marks');
        my $new   = $marks->find_or_insert({id => 71, name => 'foi seven'});
        is($new->{id},                                                              71,                              "A table handle's find_or_insert inserts on its table");
        is($marks->find_or_insert({id => 72, name => 'foi seven'}, by => ['name']), {id => 71, name => 'foi seven'}, "and finds by the 'by' fields");

        my $rows = $marks->row_class('DBIx::QuickORM::Row');
        isa_ok($rows->find_or_insert({id => 71}), ['DBIx::QuickORM::Row'], "with the handle's row class");
        is(ref($rows->data_only->find_or_insert({id => 79, name => 'foi nine'})), 'HASH', "data_only gives the row data");
        is(ref($rows->find_or_insert({id => 79}, data => 1)),                     'HASH', "and so does data => 1");

        like(dies { $marks->where({id => 1})->find_or_insert({id => 80}) },  qr/^find_or_insert\(\) works on the whole table, but the handle has a where/, "It croaks with a where");
        like(dies { $orm->handle(\'SELECT 1')->find_or_insert({id => 80}) }, qr/^find_or_insert\(\) needs a handle on a table, not a query or join/,       "and on a query (or join)");
        is($marks->where({id => 80})->count, 0, "before inserting anything");
    };
};

done_testing;
