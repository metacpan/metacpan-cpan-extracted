# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Background.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test qw/do_for_all_dbs/;
use DBIx::QuickORM::Test::Examples;

my $BUSY = qr/^An async query is still pending on this connection/;

my $polls = 0;
sub do_something_else { $polls++ }

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my $alice_id = $orm->insert(users => {name => 'Alice'})->field('id');
    $orm->insert(posts => {user_id => $alice_id, title => "Post $_"}) for 1 .. 3;

    # ASYNC
    my $it = $orm->handle('posts')->order_by('id')->async->iter;    # the query starts, and iter returns at once
    do_something_else() until $it->ready;                           # polls, and collects the result when ready
    my @posts = $it->all;

    is([map { $_->field('title') } @posts], ['Post 1', 'Post 2', 'Post 3'], "an async query returns its rows");
    ok($orm->is_canon(posts => $posts[0]), "which are canonical");

    my $pending = $orm->handle('posts')->async->iter;
    # croaks: an async query is pending on this connection
    my $count = eval { $orm->handle('users')->count };
    my @rows  = $pending->all;                                      # collected, and the connection is free again

    is($count, undef, "another query croaks while the async query is pending");
    like(dies { my $p = $orm->handle('posts')->async->iter; $orm->handle('users')->count }, $BUSY, "saying so");
    is(scalar(@rows),                3, "the pending query is collected");
    is($orm->handle('users')->count, 1, "and the connection is free again");

    # ASIDE
    {
        my $aside = $orm->handle('posts')->aside->iter;    # on a second connection
        my $count = $orm->handle('users')->count;          # the ORM's own connection is free meanwhile
        my @posts = $aside->all;                           # the second connection closes

        is($count,         1, "the ORM's connection answers while the aside query runs");
        is(scalar(@posts), 3, "and the aside query returns its rows");
    }

    # FORKED
    {
        # in a child process, on its own connection
        my $forked = $orm->handle('posts')->forked->iter;
        my $count  = $orm->handle('users')->count;
        my @posts  = $forked->all;                          # the child sent the rows and exited

        is($count,         1, "the ORM's connection answers while the forked query runs");
        is(scalar(@posts), 3, "and the forked query returns its rows");
    }

    # ON THE HANDLE OR A NEW ITERATOR
    {
        my $h = $orm->handle('users')->async;
        do_something_else() until $h->ready;                # the first call starts the query
        my @users = $h->all;                                # that same query's rows

        my $it = $h->iter;                                  # a new iterator over the same query
        $h->clear;                                          # the next read starts another query

        is(scalar(@users),   1, "the handle's ready and all share its query");
        is(scalar($it->all), 1, "and iter reads the same rows");
        is(scalar($h->all),  1, "after clear the handle queries again");
    }

    # AND TRANSACTIONS
    {
        # aside and forked: start before the transaction, read after it
        my $posts = $orm->handle('posts')->aside->iter;

        $orm->txn(sub {
            $orm->insert(users => {name => 'Zoe'});    # another table meanwhile

            my @mine = $orm->handle('posts')->async->iter->all;    # async: the transaction's own connection, sees its writes
        });

        my @posts = $posts->all;

        # croaks: aside and forked cannot start, or be read, inside a transaction
        my $ok = eval {
            $orm->txn(sub { $orm->handle('posts')->aside->iter });
            1;
        };

        ok(scalar(@posts),                     "an aside query started before a transaction is read after it");
        ok($orm->is_canon(posts => $posts[0]), "and its rows are canonical");
        ok(!$ok,                               "starting one inside a transaction croaks");
        like($@, qr/^aside\(\) cannot start a query while a transaction is open/, "saying so");
    }

    $orm->txn(sub {
        $orm->insert(
            posts => {
                user_id => $alice_id,
                title   => 'Draft',
            }
        );
        my @mine = $orm->handle('posts')->async->iter->all;
        is(scalar(grep { $_->field('title') eq 'Draft' } @mine), 1, "an async query sees the transaction's insert");
        ok($orm->is_canon(posts => $mine[0]), "async rows are canonical inside the transaction");
        my $later = $orm->handle('posts')->forked;
        like(dies { $later->all }, qr/^forked\(\) cannot start a query while a transaction is open/, "forked croaks inside a transaction too");
    });
    $orm->handle('posts')->where({title => 'Draft'})->delete;
    $orm->handle('users')->where({name  => 'Zoe'})->delete;

    my $cancelled;
    my $warned = warnings {
        my $txn = $orm->txn;
        $cancelled = $orm->handle('posts')->async->iter;
    };
    like($warned,                  [match qr/it was rolled back/],                               "a transaction dropped with an async query pending rolls back");
    like(dies { $cancelled->all }, qr/cancelled when the transaction it ran in was rolled back/, "and the query was cancelled");

    my $refused = warnings {
        my $txn     = $orm->txn;
        my $pending = $orm->handle('posts')->async->iter;
        like(dies { $txn->rollback }, $BUSY, "an explicit rollback croaks while an async query is pending");
        $pending->all;
        $txn->rollback;
    };
    is($refused, [], "collected, the transaction rolls back quietly");

    # ERRORS
    # a scalar reference: a handle over SQL you write
    my $bad = $orm->handle(\'SELECT * FROM no_such_table')->async->iter;
    # the database error is thrown here, and again on every later read
    my $rows = eval { [$bad->all] };

    is($rows, undef, "a failed query throws on collection");
    like($@,                                                                       qr/no_such_table/,                              "the database's error");
    like(dies { $bad->next },                                                      qr/no_such_table/,                              "and again on a later read");
    like(dies { $orm->handle(\'SELECT * FROM no_such_table')->forked->iter->all }, qr/^The forked query failed: .*no_such_table/s, "a forked child's error arrives the same way");

    # FORKING YOUR OWN PROCESS
    my $parent = $orm->connection;

    my $pid = fork // die "Could not fork: $!";
    unless ($pid) {
        my $count = $orm->handle('users')->count;    # the ORM reconnects in the child by itself
        exit($count ? 0 : 1);
    }
    waitpid($pid, 0);

    is($?, 0, "the child queried through its own connection");
    ref_is($orm->connection, $parent, "and the parent kept its own");

    my $dbh_orm = DBIx::QuickORM->new(dbh => $db->connect);
    like(dies { $dbh_orm->handle('posts')->aside },  qr/given a 'dbh'/, "aside croaks on an ORM given a dbh");
    like(dies { $dbh_orm->handle('posts')->forked }, qr/given a 'dbh'/, "and so does forked");
};

# BACKEND SUPPORT, on every database
do_for_all_dbs {
    my ($db, $set) = @_;

    # DuckDB sees only its own connection's writes, so the setup connection is closed before the ORM opens.
    my $setup = $db->connect;
    $setup->do("CREATE TABLE posts (id INTEGER PRIMARY KEY, title VARCHAR(20) NOT NULL)");
    $setup->do("INSERT INTO posts (id, title) VALUES (?, ?)", undef, $_, "Post $_") for 1 .. 3;
    $setup->disconnect;
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    my $it = $orm->handle('posts')->order_by('id')->maybe_async->iter;    # async where the database can, otherwise an ordinary query

    do_something_else() until $it->ready;                                 # the same iterator API either way
    my @rows = $it->all;

    my $dialect = $orm->connection->dialect;
    my $posts   = $orm->handle('posts')->order_by('id');
    is([map { $_->field('id') } @rows], [1, 2, 3],                                                    "the rows arrive through either iterator");
    is($dialect->supports_async,        $set->{family} =~ m/^(?:PostgreSQL|MySQL|MariaDB)\z/ ? 1 : 0, "async is PostgreSQL and the MySQL family");
    like(dies { $posts->async },  qr/has no async queries/,           "elsewhere async croaks") unless $dialect->supports_async;
    like(dies { $posts->forked }, qr/No second connection can reach/, "forked croaks where a second connection cannot reach the data") if $set->{family} eq 'DuckDB';
};

done_testing;
