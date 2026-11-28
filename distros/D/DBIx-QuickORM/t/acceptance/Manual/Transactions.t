# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Transactions.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $dbh = $orm->connection->dbh;

    my $names = sub { [map { $_->field('name') } $orm->handle('users')->order_by('id')->all] };

    # BLOCK FORM
    $orm->txn(sub {
        my $ann = $orm->insert(users => {name => 'Ann'});
        $orm->insert(
            posts => {
                user_id => $ann->field('id'),
                title   => 'Hello',
            }
        );
    });    # commits when the block returns

    my $ok = eval {
        $orm->txn(sub {
            $orm->insert(users => {name => 'Bob'});
            die "no\n";    # rolls back, and the exception is rethrown
        });
        1;
    };

    # returns what the block returns
    my $count = $orm->txn(sub { $orm->handle('users')->count });

    $orm->txn(sub {
        my $txn = shift;
        $orm->insert(users => {name => 'Cy'});
        # or commit: the transaction is over, and the rest of the block runs outside it
        $txn->rollback;
    });

    is($names->(),                   ['Ann'], "a block commits on return; an exception and an early rollback roll back");
    is($orm->handle('posts')->count, 1,       "with every write in it");
    ok(!$ok, "the exception is rethrown");
    is($count,                            1, "txn returns what the block returns");
    is(scalar(@{$orm->connection->txns}), 0, "and no transaction is left open");
    $orm->txn(sub {
        $_[0]->rollback;
        is(scalar(@{$orm->connection->txns}), 0, "after an early rollback the rest of the block runs outside the transaction");
    });

    # OBJECT FORM
    my $txn = $orm->txn;
    $orm->insert(users => {name => 'Di'});
    $txn->commit;

    my $undo = $orm->txn;
    $orm->insert(users => {name => 'Eve'});
    $undo->rollback;

    is($names->(), ['Ann', 'Di'], "commit keeps the write, rollback drops it");
    like(warnings { my $dropped = $orm->txn; $orm->insert(users => {name => 'Dropped'}) }, [match qr/went out of scope without commit\(\) or rollback\(\); it was rolled back/], "an unfinished transaction going out of scope warns");
    is($names->(), ['Ann', 'Di'], "and is rolled back");

    # SAVEPOINTS
    $orm->txn(sub {
        $orm->insert(users => {name => 'Fay'});
        eval {
            $orm->txn(sub {
                $orm->insert(users => {name => 'Gus'});
                die "undo Gus only\n";
            });
        };
        $orm->insert(users => {name => 'Hal'});
    });    # Fay and Hal are committed, but Gus was rolled back with his savepoint

    my $outer = $orm->txn;
    my $inner = $orm->txn;    # a savepoint
    $orm->insert(users => {name => 'Ian'});
    $inner->rollback;         # the innermost open transaction has to finish first
    $outer->commit;           # without Ian

    is($names->(), ['Ann', 'Di', 'Fay', 'Hal'], "a savepoint rolls back alone; the rest of the transaction commits");
    {
        my $outer = $orm->txn;
        my $inner = $orm->txn;
        like(dies { $outer->commit },   qr/a transaction opened inside it is still open/, "the outer transaction cannot be committed while a savepoint is open");
        like(dies { $outer->rollback }, qr/a transaction opened inside it is still open/, "nor rolled back");
        $inner->rollback;
        $outer->rollback;
    }

    # A FAILED STATEMENT
    {
        $orm->insert(users => {name => 'Lu', email => 'lu@example.com'});

        $orm->txn(sub {
            # the failure rolls back only the nested transaction
            my $dup = !eval {
                $orm->txn(sub {
                    $orm->insert(users => {name => 'Lu2', email => 'lu@example.com'});
                });
                1;
            };
            $orm->insert(users => {name => 'Mo'});
        });    # Mo is committed

        my $ok = eval {
            $orm->txn(sub {
                $orm->insert(users => {name => 'Ned'});
                # caught, but the failure marks the transaction failed
                eval { $orm->insert(users => {name => 'Ned2', email => 'lu@example.com'}) };
            });    # croaks: the commit rolls back instead, so Ned is gone too
            1;
        };

        is($names->(), ['Ann', 'Di', 'Fay', 'Hal', 'Lu', 'Mo'], "a failure in a nested transaction rolls back only it; a caught failure without one rolls the whole transaction back");
        ok(!$ok, "the commit croaks");
        like($@, qr/^The transaction opened at .* was rolled back instead of committed, since a statement in it failed/, "saying why");
        is(scalar(@{$orm->connection->txns}), 0, "and the transaction is closed");
        $orm->txn(sub {
            eval { $orm->insert(users => {name => 'Ned3', email => 'lu@example.com'}) };
            like(dies { $orm->insert(users => {name => 'Ola'}) }, qr/^A statement in the transaction opened at .* failed, so the transaction can only be rolled back/, "after a failure every other statement croaks");
            $_[0]->rollback;
        });
        $orm->handle('users')->where({name => [qw/Lu Mo/]})->delete;
    }

    # ISOLATION
    {
        my ($dsn, $user, $pass) = ($db->connect_string, $db->username, $db->password);
        my @begins;
        $dbh->{Callbacks} = {
            prepare => sub { push @begins => $_[1] if $_[1] =~ m/^BEGIN/; return },
        };

        # every outermost transaction opens at read committed unless told otherwise
        $orm->txn(sub { $orm->insert(users => {name => 'Kim'}) });

        # one transaction at another level
        my $total = $orm->txn(
            sub { $orm->handle('posts')->count },
            isolation => 'repeatable read',
        );

        # another default for every transaction of this ORM
        my $strict = DBIx::QuickORM->new(
            connect   => sub { DBI->connect($dsn, $user, $pass, {RaiseError => 1}) },
            isolation => 'serializable',
        );

        # a plain BEGIN: the database's own default level
        $orm->txn(sub { $orm->handle('users')->count }, isolation => 'server');

        delete $dbh->{Callbacks};
        is(\@begins, ['BEGIN ISOLATION LEVEL READ COMMITTED', 'BEGIN ISOLATION LEVEL REPEATABLE READ', 'BEGIN'], "each transaction states its level; 'server' sends a plain BEGIN");
        is($total,   1,                                                                                          "the block's value comes back");
        my $level = sub { scalar $_[0]->connection->dbh->selectrow_array('SHOW transaction_isolation') };
        is($strict->isolation,                                                     'serializable',   "the ORM keeps its default");
        is($strict->txn(sub { $level->($strict) }),                                'serializable',   "and every transaction opens at it");
        is($strict->txn(sub { $level->($strict) }, isolation => 'Read Committed'), 'read committed', "unless the call names another, in any case");
        like(dies { DBIx::QuickORM->new(dbh => $db->connect, isolation => 'snapshot') }, qr/^'isolation' must be one of: /, "an unknown level croaks");
    }

    # RETRY
    my $other   = $db->connect;
    my $updates = 0;
    my @begins;
    # The first run reads the row, then another session changes it before the update: under SERIALIZABLE a serialization failure.
    my $watch = on_execute { $other->do("UPDATE posts SET views = 100 WHERE title = 'Hello'") if $_[0] =~ m/^UPDATE/ && !$updates++ };
    $dbh->{Callbacks} = {
        prepare => sub { push @begins => $_[1] if $_[1] =~ m/^BEGIN/; return },
    };

    use DBIx::QuickORM::Value qw/sql/;

    my $post_id = $orm->handle('posts')->only->field('id');

    $orm->txn(
        sub {
            my $post = $orm->find(posts => $post_id);
            $post->update({views => $post->field('views') + 1});
        },
        # the database reports a conflicting write as a serialization failure
        isolation => 'serializable',
        retry     => 3,                # then the block runs again, up to 3 more times
    );

    my $post = $orm->find(posts => $post_id);
    # the database does the arithmetic, so concurrent increments all count
    $post->update({views => sql('views + 1')});

    undef $watch;
    delete $dbh->{Callbacks};
    is($updates,                                                  3,                                                                            "three UPDATEs: the attempt that hit the serialization failure, the retry, and the sql() increment");
    is(\@begins,                                                  ['BEGIN ISOLATION LEVEL SERIALIZABLE', 'BEGIN ISOLATION LEVEL SERIALIZABLE'], "every attempt began at the level asked for");
    is($post->field('views'),                                     102,                                                                          "the second run saw the other session's 100 and committed 101; sql() then added one without a read");
    is($orm->find(posts => $post_id, cache => 0)->field('views'), 102,                                                                          "in the database too");

    {
        my $watch = on_execute { $other->do("UPDATE posts SET views = views + 1 WHERE id = $post_id") if $_[0] =~ m/^UPDATE/ };
        my $tries = 0;
        my $err   = dies {
            $orm->txn(
                sub {
                    $tries++;
                    my $post = $orm->find(posts => $post_id);
                    $post->update({views => $post->field('views') + 1});
                },
                isolation => 'serializable',
                retry     => 3,
            );
        };
        is($tries,     4,                       "retry => 3 allows four attempts");
        is($err->kind, 'serialization_failure', "and the last failure is rethrown");
    }
    {
        my $views = $orm->find(posts => $post_id, cache => 0)->field('views');
        my $watch = on_execute { $other->do("UPDATE posts SET views = 500 WHERE id = $post_id") if $_[0] =~ m/^UPDATE/ };
        $orm->txn(sub {
            my $post = $orm->find(posts => $post_id);
            $post->update({views => $post->field('views') + 1});
        });
        is($orm->find(posts => $post_id, cache => 0)->field('views'), $views + 1, "at the default level the read-then-write silently overwrites the other session's 500");
    }
    my $open = $orm->txn;
    like(
        dies {
            $orm->txn(sub { 1 }, retry => 1)
        },
        qr/'retry' is only for a root transaction/,
        "retry croaks on a nested transaction"
    );
    like(
        dies {
            $orm->txn(sub { 1 }, isolation => 'serializable')
        },
        qr/'isolation' is only for a root transaction/,
        "and so does isolation"
    );
    $open->rollback;

    # THE ROWS YOU HOLD
    {
        my $views = $orm->find(posts => $post_id, cache => 0)->field('views');

        my $post = $orm->find(posts => $post_id);    # canonical: the ORM's cached copy of the row

        my ($before, $inside);
        $orm->txn(sub {
            # false: a row read before the transaction is not canonical inside it
            $before = $post->is_canon;
            # read again: the database holds the same data, so $post's copy is reused
            my $same = $orm->find(posts => $post_id);
            $inside = $post->is_canon;    # true
        });
        my $after = $post->is_canon;      # true: the commit kept the copy the transaction reused

        my $gone;
        $orm->txn(sub {
            my $txn = shift;
            my $tmp = $orm->insert(users => {name => 'Jo'});
            $txn->rollback;
            $gone = $tmp->is_canon;    # false: a rollback forgets everything the transaction held
        });

        my $stale;
        $orm->txn(sub {
            my $post = $orm->find(posts => $post_id);
            eval {
                $orm->txn(sub {
                    $post->update({views => 99});
                    die "undo\n";
                });
            };
            $stale = $post->is_canon;    # false: the savepoint's data was rolled back
            $post->refresh;              # reads the database: back to the earlier views
        });

        ok(!$before, "a row read before a transaction is not canonical inside it");
        ok($inside,  "until it is read again with the same data");
        ok($after,   "and is canonical after the commit");
        ok(!$gone,   "a row written in a rolled back transaction is not canonical");
        ok(!$stale,  "nor one updated in a rolled back savepoint");
        is($names->()->[-1], 'Kim', "Jo's write is gone");
        $orm->txn(sub {
            my $same = $orm->find(posts => $post_id);
            ref_is($same->row_data, $post->row_data, "read again with the same data, the held copy is reused");
        });

        $orm->txn(sub {
            my $post = $orm->find(posts => $post_id);
            eval {
                $orm->txn(sub { $post->update({views => 99}); die "undo\n" });
            };
            is($post->field('views'), 99, "a row updated in a rolled back savepoint still holds the savepoint's data");
            $post->refresh;
            ok($post->is_canon, "refresh makes it canonical");
            is($post->field('views'), $views, "with the database's data");
        });

        my $changed = $orm->find(posts => $post_id);
        $orm->txn(sub {
            my $txn = shift;
            $orm->find(posts => $post_id)->update({views => 7});
            $txn->rollback;
        });
        ok(!$changed->is_canon, "after a root rollback a row the transaction changed is not canonical");
        $changed->refresh;
        ok($changed->is_canon, "until refreshed");
        is($changed->field('views'), $views, "with the data the database kept");
    }

    # WRITING A ROW READ BEFORE THE TRANSACTION
    {
        my $post = $orm->find(posts => $post_id);

        $orm->txn(sub {
            # croaks: $post is not canonical inside the transaction
            my $ok = eval { $post->update({views => 5}); 1 };
            # succeeds only if views still equals the value $post read
            $post->cas_update({views => 5}) or die "Changed elsewhere\n";
        });

        $orm->txn(sub {
            $post->refresh;                 # reads the database: $post is canonical again
            $post->update({views => 6});    # then update as usual
        });

        is($orm->find(posts => $post_id, cache => 0)->field('views'), 6, "cas_update wrote, and so did update after a refresh");
        my $stale = $orm->find(posts => $post_id);
        $orm->txn(sub {
            like(dies { $stale->update({views => 7}) }, qr/is not canon/, "update croaks on a row read before the transaction");
            like(dies { $stale->delete },               qr/is not canon/, "and so does delete");
            ok(lives { $stale->update({views => 7}, enforce_canon => 0) }, "unless the call passes enforce_canon => 0");
            $stale->refresh;
            ok($stale->cas_update({views => 7}), "cas_update writes it while the database holds what it read");
        });

        my $other_orm = DBIx::QuickORM->new(connect => sub { $db->connect });
        $other_orm->find(posts => $post_id)->update({views => 50});
        $orm->txn(sub {
            is($stale->cas_update({views => 8}), undef, "cas_update returns undef once the database no longer holds what the row read");
        });
        is($orm->find(posts => $post_id, cache => 0)->field('views'), 50, "and changes nothing");
    }
};

done_testing;
