# Test origin: AI
use Test2::V0;
use lib 't/lib';

use POSIX();

use DBIx::QuickORM;
use DBIx::QuickORM::Exception::DB;
use DBIx::QuickORM::Test qw/do_for_all_dbs on_execute/;

my $FILE = __FILE__;

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE t (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(20))");

    my $orm        = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    my $conn       = $orm->connection;
    my $savepoints = $conn->dialect->supports_savepoints;

    # Reads on the ORM's own session, so inside a transaction they see its uncommitted work.
    my $name_of = sub { scalar $dbh->selectrow_array("SELECT name FROM t WHERE id = ?", undef, $_[0]) };
    my $depth   = sub { scalar @{$conn->txns} };
    my $canon   = sub { $orm->is_canon(t => $_[0]) };

    subtest object_form => sub {
        my $txn = $orm->txn;
        isa_ok($txn, ['DBIx::QuickORM::Txn'], "txn returns a transaction");
        is($depth->(), 1, "which is open");
        $orm->insert(t => {id => 1, name => 'kept'});
        is($txn->commit,  1,      "commit");
        is($depth->(),    0,      "closes it");
        is($name_of->(1), 'kept', "and the write is committed");
        like(dies { $txn->commit }, qr/^Cannot commit the transaction opened at \Q$FILE\E line \d+: it is already finished/, "A finished transaction cannot be committed again");

        $txn = $orm->txn;
        $orm->insert(t => {id => 2, name => 'dropped'});
        is($txn->rollback, 1,     "rollback");
        is($depth->(),     0,     "closes it");
        is($name_of->(2),  undef, "and the write is gone");
        like(dies { $txn->rollback }, qr/^Cannot roll back the transaction opened at \Q$FILE\E line \d+: it is already finished/, "nor rolled back again");
    };

    subtest block_form => sub {
        my $got;
        my @out = $orm->txn(sub { $got = shift; $orm->insert(t => {id => 3, name => 'block'}); return (1, 2) });
        isa_ok($got, ['DBIx::QuickORM::Txn'], "The block gets the transaction");
        is(\@out,                            [1, 2],  "txn returns what the block returns");
        is($depth->(),                       0,       "A normal return closes the transaction");
        is($name_of->(3),                    'block', "and commits");
        is(scalar($orm->txn(sub { 'one' })), 'one',   "The block runs in the caller's context");

        is(
            dies {
                $orm->txn(sub { $orm->insert(t => {id => 4, name => 'x'}); die "boom\n" })
            },
            "boom\n",
            "An exception propagates"
        );
        is($depth->(),    0,     "after closing the transaction");
        is($name_of->(4), undef, "by rolling back");

        ok(
            lives {
                $orm->txn(sub { $orm->insert(t => {id => 5, name => 'x'}); $_[0]->rollback })
            },
            "A block may finish its transaction itself"
        );
        is($name_of->(5), undef, "which is not committed again");
    };

    subtest nested => sub {
        skip_all "the backend has no savepoints" unless $savepoints;

        my $outer = $orm->txn;
        $orm->insert(t => {id => 10, name => 'outer'});
        my $sp = $orm->txn;
        is($depth->(), 2, "A nested transaction is a savepoint");
        isnt($sp->name, $outer->name, "with a name of its own");
        $orm->insert(t => {id => 11, name => 'inner'});
        $sp->rollback;
        is($name_of->(11), undef,   "Rolling back the savepoint drops its write");
        is($name_of->(10), 'outer', "and keeps the outer one");

        $orm->txn(sub { $orm->insert(t => {id => 12, name => 'inner'}) });
        is($depth->(), 1, "A nested block closes its savepoint");
        $outer->commit;
        is([map { $name_of->($_) } 10, 11, 12], ['outer', undef, 'inner'], "The outer commit keeps what the savepoints committed");
    };

    subtest savepoint_lookup => sub {
        skip_all "the backend has no savepoints" unless $savepoints;

        my $outer = $orm->txn;
        my $gone  = $orm->insert(t => {id => 20, name => 'gone'});
        my $old   = $orm->insert(t => {id => 21, name => 'old'});

        my $sp = $orm->txn;
        ok($canon->($gone) && $canon->($old), "The parent's canon rows are canon in a savepoint");
        $orm->delete_row('t', $gone);
        my $new = $orm->update_row('t', $old, {name => 'new'});
        ok(!$canon->($gone),                  "A deleted row is not canon");
        ok(!$canon->($old) && $canon->($new), "An updated row has new canon data");

        $sp->rollback;
        ok($canon->($gone), "Rolling back the savepoint makes the deleted row canon again");
        ok($canon->($old),  "and the updated row's parent data");
        ok(!$canon->($new), "not the savepoint's");
        is([$name_of->(20), $name_of->(21)], ['gone', 'old'], "as the database agrees");

        $sp = $orm->txn;
        my $kept = $orm->update_row('t', $old, {name => 'kept'});
        $sp->commit;
        ok($canon->($kept) && !$canon->($old), "Committing a savepoint keeps its canon data");
        $outer->commit;
        ok($canon->($kept), "and so does the root commit");
    };

    subtest no_savepoints => sub {
        skip_all "the backend has savepoints" if $savepoints;

        my $txn = $orm->txn;
        like(dies { $orm->txn }, qr/^The DuckDB dialect has no savepoints, so transactions cannot be nested/, "Nesting croaks");
        is($depth->(), 1, "leaving the outer transaction open");
        $txn->rollback;

        like(
            dies {
                $orm->txn(sub {
                    $orm->txn(sub { 1 });
                })
            },
            qr/^The DuckDB dialect has no savepoints/,
            "in the block form too"
        );
        is($depth->(), 0, "which rolls the outer block back");
    };

    subtest innermost_only => sub {
        skip_all "the backend has no savepoints" unless $savepoints;

        my $outer = $orm->txn;
        my $inner = $orm->txn;
        like(dies { $outer->commit },   qr/^Cannot commit the transaction opened at \Q$FILE\E line \d+: a transaction opened inside it is still open/,    "The outer transaction cannot commit while a savepoint is open");
        like(dies { $outer->rollback }, qr/^Cannot roll back the transaction opened at \Q$FILE\E line \d+: a transaction opened inside it is still open/, "nor roll back");
        is($depth->(), 2, "Both stay open");
        $inner->rollback;
        $outer->rollback;

        my $held;
        like(
            dies {
                $orm->txn(sub { $orm->insert(t => {id => 30, name => 'x'}); $held = $orm->txn });
            },
            qr/^Cannot commit the transaction opened at .*: a transaction opened inside it is still open/,
            "A block returning with a savepoint still open throws",
        );
        is($depth->(),               0,     "after rolling back both");
        is($name_of->(30),           undef, "and the block's write");
        is(warnings { undef $held }, [],    "The savepoint is finished and goes quietly");
    };

    subtest out_of_scope => sub {
        my $line;
        my $warnings = warnings {
            $line = __LINE__ + 1;
            my $txn = $orm->txn;
            $orm->insert(t => {id => 40, name => 'x'});
        };
        is($warnings,      [match qr/^The transaction opened at \Q$FILE\E line $line went out of scope without commit\(\) or rollback\(\); it was rolled back$/], "An unfinished transaction going out of scope warns, naming where it was opened");
        is($depth->(),     0,                                                                                                                                     "and is closed");
        is($name_of->(40), undef,                                                                                                                                 "by rolling back");

        return unless $savepoints;

        my $outer = $orm->txn;
        my $inner = $orm->txn;
        $orm->insert(t => {id => 41, name => 'x'});
        is(scalar(@{warnings(sub { undef $outer })}), 1,     "Dropping a transaction with a savepoint open inside warns once");
        is($depth->(),                                0,     "and closes both");
        is($name_of->(41),                            undef, "rolling back");
        like(dies { $inner->commit }, qr/already finished/, "The savepoint is finished");
        is(warnings { undef $inner }, [], "and goes quietly");

        $outer = $orm->txn;
        is(scalar(@{warnings(sub { my $sp = $orm->txn; $orm->insert(t => {id => 42, name => "x"}) })}), 1, "A dropped savepoint warns");
        is($depth->(),                                                                                  1, "and only it is closed");
        $outer->commit;
        is($name_of->(42), undef, "its write rolled back");
    };

    subtest forked_child => sub {
        my $txn = $orm->txn;
        $orm->insert(t => {id => 50, name => 'parent'});

        my $pid = fork // die "Could not fork: $!";
        unless ($pid) {
            my $sql = 0;
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings => @_ };
            my $mock   = mock 'DBI::db' => (before => [do => sub { $sql++ }, prepare => sub { $sql++ }]);
            my $commit = (dies { $txn->commit }) // '';
            undef $txn;

            my $ok = $commit =~ m/^Cannot commit the transaction opened at .* from process $$; process \d+ opened it/;
            POSIX::_exit($ok && !$sql && !@warnings ? 0 : 1);
        }
        waitpid($pid, 0);

        is($?,             0,        "In a forked child the transaction croaks on commit and goes quietly, issuing no SQL");
        is($depth->(),     1,        "The parent's transaction is still open");
        is($name_of->(50), 'parent', "with its write");
        $txn->commit;
        is($name_of->(50), 'parent', "and commits");
    };

    subtest canon_boundary => sub {
        my $before = $orm->insert(t => {id => 60, name => 'before'});
        my $other  = $orm->insert(t => {id => 61, name => 'other'});
        ok($canon->($before), "A row is canon outside a transaction");

        my $txn = $orm->txn;
        ok(!$canon->($before), "but not inside one begun after it");
        like(dies { $orm->update_row('t', $before, {name => 'x'}) }, qr/is not canon/, "so writing it croaks");
        ref_is($orm->refresh_row('t', {id => 60}), $before, "Read again with the same data, the row held from before is reused");
        ok($canon->($before), "and canon inside the transaction");
        $txn->commit;
        ok($canon->($before), "and after the root commit");
        ok($canon->($other),  "A row the transaction did not touch is canon again after the root commit");

        $txn = $orm->txn;
        ref_is($orm->refresh_row('t', {id => 60}), $before, "Read again in another transaction");
        $txn->rollback;
        ok($canon->($before) && $canon->($other), "rows held from before are canon after a root rollback");

        $txn = $orm->txn;
        my $updated = $orm->update_row('t', {id => 61}, {name => 'changed'}, enforce_canon => 0);
        $txn->commit;
        ok(!$canon->($other) && $canon->($updated), "A row updated in a transaction leaves the old row data non-canon after commit");

        $txn = $orm->txn;
        $dbh->do("UPDATE t SET name = 'behind' WHERE id = 60");
        my $changed = $orm->refresh_row('t', {id => 60});
        ok($changed != $before && $canon->($changed), "Read again with different data, the row gets new row data");
        $txn->rollback;
        ok(!$canon->($before), "and the row held from before stays non-canon after the transaction");

        my $kept = $orm->refresh_row('t', {id => 60});
        $txn = $orm->txn;
        $orm->handle('t')->where({id => 999})->update({name => 'none'});
        $txn->rollback;
        ok(!$canon->($kept), "A bulk update in a transaction drops its table's rows held from before");

        $kept = $orm->refresh_row('t', {id => 60});
        $orm->txn(sub { $orm->refresh_row('t', {id => 60}); $orm->clear_cache(t => 60) });
        ok(!$canon->($kept), "A row cleared in a committed transaction is not current after it");

        $kept = $orm->refresh_row('t', {id => 60});
        $orm->txn(sub { $orm->clear_cache('t'); $_[0]->rollback });
        ok(!$canon->($kept), "nor after a rolled back one");
    };

    subtest enforce_canon => sub {
        my $lax = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, enforce_canon => 0);
        $lax->insert(t => {id => 70, name => 'a'});

        ok(lives { $lax->update_row('t', {id => 70}, {name => 'b'}) }, "Outside a transaction the ORM's enforce_canon (off here) applies");
        my $txn = $lax->txn;
        like(dies { $lax->update_row('t', {id => 70}, {name => 'c'}) }, qr/is not canon/, "Inside one canon is enforced by default");
        ok(lives { $lax->update_row('t', {id => 70}, {name => 'c'}, enforce_canon => 0) }, "unless the call turns it off");
        $txn->rollback;
    };

    subtest weak_and_retained => sub {
        for my $retain (0, 1) {
            my $id     = 80 + $retain;
            my $o      = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, retain_cache => $retain);
            my $lookup = $o->connection->lookup;

            my $txn    = $o->txn;
            my $unused = $o->insert(t => {id => $id, name => 'x'});
            undef $unused;
            ok($lookup->lookup(t => {id => $id}), "retain_cache $retain: inside a transaction an unused row stays held");
            $txn->commit;

            if   ($retain) { ok($lookup->lookup(t  => {id => $id}), "retain_cache 1: and after the root commit") }
            else           { ok(!$lookup->lookup(t => {id => $id}), "retain_cache 0: the root commit weakens it, so it is freed") }
        }
    };

    subtest isolation => sub {
        my $family = $set->{family};
        my $levels = $family ne 'SQLite' && $family ne 'DuckDB';

        like(
            dies {
                $orm->txn(sub { 1 }, isolation => 'snapshot')
            },
            qr/^'isolation' must be one of: 'read committed', 'read uncommitted', 'repeatable read', 'serializable', 'server'/,
            "An unknown level croaks"
        );
        like(
            dies { DBIx::QuickORM->new(dbh => $db->connect, isolation => 'snapshot') },
            qr/^'isolation' must be one of: /,
            "So does an unknown ORM default"
        );

        my $outer = $orm->txn;
        like(
            dies { $orm->txn(isolation => 'serializable') },
            qr/^'isolation' is only for a root transaction, and a transaction is already open/,
            "A nested transaction cannot set a level"
        );
        is($depth->(), 1, "leaving the outer one open");
        $outer->rollback;

        # The statements each root transaction opens with.
        my $begins = sub {
            my ($o, @args) = @_;
            my @sql;
            my $h = $o->connection->dbh;
            local $h->{Callbacks} = {prepare => sub { push @sql => $_[1]; return }};
            $o->txn(sub { 1 }, @args);
            pop @sql;    # COMMIT
            return \@sql;
        };

        is($orm->isolation,                        undef,     "The ORM default is undef unless given");
        is($begins->($orm, isolation => 'server'), ['BEGIN'], "'server' sends a plain BEGIN");

        unless ($levels) {
            is($begins->($orm), ['BEGIN'], "$family: the default sends nothing extra");
            like(
                dies {
                    $orm->txn(sub { 1 }, isolation => 'serializable')
                },
                qr/^The $family dialect cannot set a transaction isolation level/,
                "$family has no level to set"
            );
            is($depth->(), 0, "and opens no transaction");

            my $fixed = DBIx::QuickORM->new(dbh => $db->connect, isolation => 'Serializable');
            is($fixed->isolation, 'serializable', "An ORM default is kept in lower case");
            like(
                dies {
                    $fixed->txn(sub { 1 })
                },
                qr/^The $family dialect cannot set a transaction isolation level/,
                "$family: an ORM default level croaks when a transaction opens"
            );
            is($begins->($fixed, isolation => 'server'), ['BEGIN'], "unless the call says 'server'");
            return;
        }

        my @rc  = $family eq 'PostgreSQL' ? ('BEGIN ISOLATION LEVEL READ COMMITTED') : ('SET TRANSACTION ISOLATION LEVEL READ COMMITTED', 'BEGIN');
        my @ser = $family eq 'PostgreSQL' ? ('BEGIN ISOLATION LEVEL SERIALIZABLE')   : ('SET TRANSACTION ISOLATION LEVEL SERIALIZABLE',   'BEGIN');
        is($begins->($orm),                              \@rc,  "Every root transaction states read committed by default");
        is($begins->($orm, isolation => 'Serializable'), \@ser, "A level given in any case is stated instead");

        my $strict = DBIx::QuickORM->new(dbh => $db->connect, isolation => 'serializable');
        is($begins->($strict), \@ser, "An ORM default is stated for every root transaction");
        is($begins->($strict, isolation => 'read committed'), \@rc,      "unless the call names a level");
        is($begins->($strict, isolation => 'server'),         ['BEGIN'], "or 'server'");

        if ($family eq 'PostgreSQL') {
            my $level = sub { scalar $_[0]->connection->dbh->selectrow_array('SHOW transaction_isolation') };
            $dbh->do('SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ');
            is($orm->txn(sub { $level->($orm) }),                        'read committed',  "The default is in effect even when the session's default changed");
            is($orm->txn(sub { $level->($orm) }, isolation => 'server'), 'repeatable read', "'server' leaves the session's default");
            $dbh->do('SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ COMMITTED');

            is($orm->txn(sub { $level->($orm) }, isolation => 'Serializable'), 'serializable', "A block runs at the level given");
            my $txn = $orm->txn(isolation => 'REPEATABLE READ');
            is($level->($orm), 'repeatable read', "So does the object form");
            $txn->rollback;
            is($strict->txn(sub { $level->($strict) }), 'serializable', "And at the ORM default");
        }

        # The level decides whether the transaction sees another session's commit. The MySQL family has no
        # way to read the open transaction's level (@@transaction_isolation is the session's), so behavior
        # is the check on every family.
        my $other = $db->connect;
        $orm->insert(t => {id => 85, name => 'before'});
        my $second_read = sub {
            $other->do("UPDATE t SET name = 'before' WHERE id = 85");
            return $orm->txn(
                sub {
                    $name_of->(85);
                    $other->do("UPDATE t SET name = 'after' WHERE id = 85");
                    return $name_of->(85);
                },
                @_,
            );
        };
        is($second_read->(isolation => 'REPEATABLE READ'), 'before',                                     "Under repeatable read the second read sees the snapshot");
        is($second_read->(isolation => 'read committed'),  'after',                                      "Under read committed it sees the other session's commit");
        is($second_read->(),                               'after',                                      "The next transaction is back at the default, read committed");
        is($second_read->(isolation => 'server'),          $family eq 'PostgreSQL' ? 'after' : 'before', "'server' runs at the database's default level");
    };

    subtest retry => sub {
        my $fail = sub { die DBIx::QuickORM::Exception::DB->new(kind => $_[0], message => "injected $_[0]\n") };

        my $tries = 0;
        my @out   = $orm->txn(
            sub {
                $tries++;
                $orm->insert(t => {id => 100 + $tries, name => "try $tries"});
                $fail->('deadlock') if $tries < 3;
                return 'done';
            },
            retry => 2,
        );
        is(\@out,                               ['done'],                "A retried block returns what its last run returned");
        is($tries,                              3,                       "A retriable database error runs the block again, up to the retry count");
        is([map { $name_of->($_) } 101 .. 103], [undef, undef, 'try 3'], "each failed run rolled back");

        $tries = 0;
        is(
            dies {
                $orm->txn(sub { $tries++; $fail->('serialization_failure') }, retry => 2)
            },
            "injected serialization_failure\n",
            "Past the count the error is rethrown"
        );
        is($tries, 3, "after the last retry");

        {
            my $do    = \&DBIx::QuickORM::Connection::_do;
            my $begun = 0;
            no warnings 'redefine';
            local *DBIx::QuickORM::Connection::_do = sub { $fail->('deadlock') if $_[1] =~ m/^BEGIN/ && !$begun++; goto &$do };
            $tries = 0;
            is($orm->txn(sub { ++$tries }, retry => 1), 1, "A retriable error opening the transaction is retried too");
            is($begun,                                  2, "with a new BEGIN");
        }

        for my $case (['unique_violation', "a database error that is not retriable"], [undef, "one of unknown kind"]) {
            my ($kind, $name) = @$case;
            $tries = 0;
            ok(
                dies {
                    $orm->txn(sub { $tries++; die DBIx::QuickORM::Exception::DB->new(kind => $kind, message => "x\n") }, retry => 2)
                },
                "$name dies"
            );
            is($tries, 1, "$name is not retried");
        }

        $tries = 0;
        ok(
            dies {
                $orm->txn(sub { $tries++; die "plain\n" }, retry => 2)
            },
            "Nor is a plain exception"
        );
        is($tries, 1, "which runs once");

        like(dies { $orm->txn(retry => 1) }, qr/^'retry' needs a block/, "retry needs a block");
        like(
            dies {
                $orm->txn(sub { 1 }, retry => 'x')
            },
            qr/^'retry' must be a count of retries/,
            "and a count"
        );

        my $outer = $orm->txn;
        like(
            dies {
                $orm->txn(sub { 1 }, retry => 1)
            },
            qr/^'retry' is only for a root transaction, and a transaction is already open/,
            "retry croaks inside another transaction"
        );
        is($depth->(), 1, "leaving the outer one open");
        $outer->rollback;
    };

    subtest failed_statement => sub {
        my $FAILED = qr/^A statement in the transaction opened at \Q$FILE\E line \d+ failed, so the transaction can only be rolled back/;
        my $ROLLED = qr/^The transaction opened at \Q$FILE\E line \d+ was rolled back instead of committed, since a statement in it failed/;
        my $dup    = sub { $orm->insert(t => {id => 200, name => 'dup'}) };
        $orm->insert(t => {id => 200, name => 'taken'});

        my ($row, $after);
        my $err = dies {
            $orm->txn(sub {
                $row = $orm->insert(t => {id => 201, name => 'kept?'});
                ok(dies { $dup->() }, "A duplicate key fails");
                $after = dies { $orm->insert(t => {id => 202, name => 'x'}) };
                return 1;
            });
        };
        like($after, $FAILED, "Once a statement failed, the next one croaks naming the transaction");
        like($err,   $ROLLED, "A block that caught the error and returned: the commit croaks");
        is($depth->(),      0,     "the transaction is closed");
        is($name_of->(201), undef, "by rolling back");
        ok(!$canon->($row), "so its rows are not canon");

        my $txn = $orm->txn;
        ok(dies { $dup->() }, "Object form: a duplicate key fails");
        like($txn->failed,                                 qr/./,   "and marks the transaction failed with the error");
        like(dies { $orm->handle('t')->all },              $FAILED, "a read croaks");
        like(dies { $orm->refresh_row('t', {id => 200}) }, $FAILED, "so does a refresh");
        like(dies { $txn->commit },                        $ROLLED, "commit rolls back and croaks");
        is($depth->(), 0, "and closes it");

        $txn = $orm->txn;
        ok(dies { $dup->() }, "Another failure");
        is($txn->rollback,                                                       1,      "and a rollback is allowed");
        is($orm->txn(sub { $orm->insert(t => {id => 203, name => 'next'}); 1 }), 1,      "The next transaction runs as usual");
        is($name_of->(203),                                                      'next', "and commits");

        return unless $savepoints;

        $orm->txn(sub {
            $orm->insert(t => {id => 204, name => 'outer'});
            ok(
                dies {
                    $orm->txn(sub { $dup->() })
                },
                "A failure inside a nested transaction"
            );
            $orm->insert(t => {id => 205, name => 'after'});
        });
        is([map { $name_of->($_) } 204, 205], ['outer', 'after'], "rolls back only the savepoint; the outer transaction goes on and commits");

        # A deadlock or serialization error inside a savepoint takes the same path as this statement error.
        my $outer = $orm->txn;
        my $sp    = $orm->txn;
        ok(dies { $dup->() },        "A failure inside a savepoint");
        ok(!defined($outer->failed), "marks only the innermost transaction");
        like(dies { $orm->insert(t => {id => 206, name => 'x'}) }, $FAILED, "and blocks every other statement");
        like(dies { $orm->txn },                                   $FAILED, "a new savepoint included");
        $sp->rollback;
        $orm->insert(t => {id => 206, name => 'recovered'});
        $outer->commit;
        is($name_of->(206), 'recovered', "Rolling the savepoint back clears the mark");

        $orm->txn(sub {
            is($orm->find_or_insert(t => {id => 200, name => 'dup'})->{id}, 200, "find_or_insert finds inside a transaction");
            is($orm->find_or_insert(t => {id => 207, name => 'new'})->{id}, 207, "and inserts");
        });
        is($name_of->(207), 'new', "and the transaction commits");

        return if $set->{family} eq 'SQLite';    # a second session cannot write while the transaction reads

        # Another session inserts the row between find_or_insert's find and its insert.
        my $other = $db->connect;
        my $race  = on_execute { $other->do("INSERT INTO t (id, name) VALUES (208, 'theirs')") if $_[0] =~ m/^INSERT/ && !$other->selectrow_array('SELECT 1 FROM t WHERE id = 208') };
        $orm->txn(sub {
            is($orm->find_or_insert(t => {id => 208, name => 'mine'})->{name}, 'theirs', "find_or_insert whose insert fails inside a transaction finds the other session's row");
            $orm->insert(t => {id => 209, name => 'goes on'});
        });
        undef $race;
        is($name_of->(209), 'goes on', "and the transaction goes on and commits");
    };

    subtest retry_real_conflict => sub {
        my $family = $set->{family};
        skip_all "DuckDB lets one connection at a time open the database file, so no second session can conflict" if $family eq 'DuckDB';

        my $other = $db->connect;
        $orm->insert(t => {id => 90, name => 'start'});

        # Each family makes the ORM's first run of the block fail with a real retriable error from a second session.
        my ($kind, $prepare, $release, $block, @iso);
        if ($family eq 'PostgreSQL') {
            $kind    = 'serialization_failure';
            @iso     = (isolation => 'serializable');
            $prepare = $release = sub { };
            $block   = sub {
                my ($try) = @_;
                my $row = $orm->refresh_row('t', {id => 90}, cache => 0);
                $other->do("UPDATE t SET name = 'other' WHERE id = 90") if $try == 1;
                $orm->update_row('t', $row, {name => "mine $try"});
            };
        }
        else {
            $kind = 'lock_timeout';
            if ($family eq 'SQLite') {
                $dbh->sqlite_busy_timeout(50);
                $prepare = sub { $other->do('BEGIN IMMEDIATE') };
            }
            else {
                $dbh->do('SET SESSION innodb_lock_wait_timeout = 1');
                $prepare = sub { $other->do('BEGIN'); $other->do("UPDATE t SET name = 'locked' WHERE id = 90") };
            }
            $release = sub { $other->do('ROLLBACK') };
            $block   = sub {
                my ($try) = @_;
                $release->() if $try == 2;
                $orm->update_row('t', {id => 90}, {name => "mine $try"}, enforce_canon => 0);
            };
        }

        $prepare->();
        my $err = dies {
            $orm->txn(sub { $block->(1) }, @iso)
        };
        $release->();
        isa_ok($err, ['DBIx::QuickORM::Exception::DB'], "The conflict raises a database error");
        is($err->kind,      $kind, "of kind $kind");
        is($err->retriable, 1,     "which is retriable");

        $prepare->();
        my $tries = 0;
        $orm->txn(sub { $block->(++$tries) }, retry => 3, @iso);
        is($tries,         2,        "With retry, the block runs again after the conflict");
        is($name_of->(90), 'mine 2', "and its second run commits");
    };
};

done_testing;
