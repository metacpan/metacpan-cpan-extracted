# Test origin: AI
use Test2::V0;
use lib 't/lib';

use POSIX();
use Time::HiRes qw/sleep time/;

use DBIx::QuickORM;
use DBIx::QuickORM::Test qw/do_for_all_dbs on_execute/;

my $BUSY = qr/^An async query is still pending on this connection; collect its iterator/;

# A lock one session holds and another's query waits on, so a query can be held back without timing.
my %GATE = (
    PostgreSQL => {
        hold    => 'SELECT pg_advisory_lock(4242)',
        gated   => 'SELECT pg_advisory_lock(4242) AS l, 1 AS x',
        release => 'SELECT pg_advisory_unlock(4242)',
    },
    MariaDB => {
        hold    => "SELECT GET_LOCK('qorm_test_gate', 120)",
        gated   => "SELECT GET_LOCK('qorm_test_gate', 120) AS l, 1 AS x",
        release => "SELECT RELEASE_LOCK('qorm_test_gate')",
    },
);
$GATE{MySQL} = $GATE{MariaDB};

# Waits for a pending iterator, giving up after 30 seconds. Never asserts on how long it took.
sub wait_ready {
    my ($it) = @_;
    my $until = time + 30;
    until ($it->ready) {
        die "The query was still not ready after 30 seconds\n" if time > $until;
        sleep 0.01;
    }
    return 1;
}

# Runs $code in a child that ends with POSIX::_exit, returning its exit status.
sub in_child {
    my ($code) = @_;
    my $pid = fork // die "Could not fork: $!";
    POSIX::_exit(eval { $code->() } // 255) unless $pid;
    waitpid($pid, 0);
    return $? >> 8;
}

sub names { [map { $_->field('name') } @_] }

# The platforms where DBD::Pg may crash in a child that exits with an inherited async query pending.
sub pg_fork_exit_crashes {
    return 1 if $^O eq 'solaris' || $^O eq 'openbsd';
    return 1 if $^O eq 'freebsd' && (POSIX::uname())[2] =~ m/CURRENT/;
    return 0;
}

do_for_all_dbs {
    my ($db, $set) = @_;

    # DuckDB sees only its own connection's writes, so the setup connection is closed before the ORM opens.
    my $setup = $db->connect;
    $setup->do("CREATE TABLE items (id INTEGER PRIMARY KEY, name VARCHAR(64))");
    $setup->do("INSERT INTO items (id, name) VALUES (?, ?)", undef, @$_) for [1, 'a'], [2, 'b'], [3, 'c'];
    $setup->do("CREATE TABLE floats (id INTEGER PRIMARY KEY, val " . ($set->{family} eq 'DuckDB' ? 'DOUBLE' : 'DOUBLE PRECISION') . ")");
    $setup->do("INSERT INTO floats (id, val) VALUES (1, ?)", undef, '0.30000000000000004');
    $setup->disconnect;

    my $orm     = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $h       = $orm->handle('items')->order_by('id');
    my $conn    = $orm->connection;
    my $dialect = $conn->dialect;
    my $gate    = $GATE{$set->{family}};

    # Aside and forked queries cannot start, or be read, while a transaction is open.
    my $txn_rules = sub {
        my ($mode) = @_;
        my $START  = qr/^$mode\(\) cannot start a query while a transaction is open; start it before the transaction, or after it ends/;
        my $READ   = qr/^This $mode\(\) query cannot be read while a transaction is open; read it after the transaction ends/;

        my $txn = $orm->txn;
        like(dies { $h->$mode->iter }, $START, "Starting a query inside a transaction croaks");
        like(dies { $h->$mode->all },  $START, "through the handle's reads too");
        $txn->rollback;

        my $it   = $h->where({id => 1})->$mode->iter;
        my $both = $h->where({id => 2})->$mode;
        my $started = $both->iter;    # starts its query
        $txn = $orm->txn;
        $orm->handle('items')->where({id => 3})->update({name => 'uncommitted'});
        for my $read (qw/ready next first last all only/) {
            like(dies { $it->$read }, $READ, "$read on a query started before the transaction croaks inside it");
        }
        like(dies { $both->all }, $READ, "so does the handle's own read");
        $txn->rollback;

        my ($row) = $it->all;
        is($row->field('name'), 'a', "After the transaction the query is still there to read");
        ok($orm->is_canon(items => $row), "and its rows are ingested");
        is(names($both->all), ['b'], "the handle reads its query too");

        $orm->txn(sub { 1 });
        ok($orm->is_canon(items => ($h->where({id => 2})->$mode->iter->all)[0]), "A query started after a transaction is ingested");
    };

    subtest async_unsupported => sub {
        skip_all "$set->{name} has async queries" if $dialect->supports_async;
        like(dies { $h->async }, qr/^The \w+ dialect has no async queries, so async\(\) cannot run/, "async croaks");
        like(dies { $h->aside }, qr/^The \w+ dialect has no async queries, so aside\(\) cannot run/, "and so does aside");
    };

    subtest can_and_maybe => sub {
        my $async  = $set->{family} =~ m/^(?:PostgreSQL|MySQL|MariaDB)\z/ ? 1 : 0;
        my $forked = $set->{family} eq 'DuckDB'                           ? 0 : 1;
        my %can    = (async => $async, aside => $async, forked => $forked);

        my $dbh_orm = DBIx::QuickORM->new(dbh => $db->connect);
        my $dbh_h   = $dbh_orm->handle('items')->order_by('id');
        my %dbh_can = (async => $async, aside => 0, forked => 0);

        for my $mode (qw/async aside forked/) {
            my ($can, $maybe) = ("can_$mode", "maybe_$mode");
            is($h->$can,     $can{$mode},     "$can is $can{$mode}");
            is($dbh_h->$can, $dbh_can{$mode}, "and $dbh_can{$mode} on an ORM given a dbh");

            for my $case ([$h, $can{$mode}, 'connect'], [$dbh_h, $dbh_can{$mode}, 'dbh']) {
                my ($base, $runs, $form) = @$case;
                my $m = $base->$maybe;
                ok($m != $base, "$maybe returns a new handle ($form)");
                is($m->mode, $runs ? $mode : undef, $runs ? "in $mode mode" : "with no mode");
                ok(wait_ready($m), "whose query becomes ready");
                is(names($m->all),       [qw/a b c/], "and returns the rows");
                is(names($m->iter->all), [qw/a b c/], "as does iter");
                like(dies { $base->$maybe; return }, qr/^$maybe\(\) returns a new handle and leaves this one unchanged/, "$maybe in void context croaks");
                is(dies { my $x = $base->$mode }, $runs ? undef : match(qr/cannot/), "and $can agrees with $mode()");
            }
        }

        is($h->forked->maybe_async->mode, 'forked', "a fallback leaves the mode as it was") if $forked && !$async;

        my $txn = $dbh_orm->txn;
        $dbh_orm->handle('items')->where({id => 1})->update({name => 'uncommitted'});
        is(names($dbh_h->where({id => 1})->maybe_aside->all), ['uncommitted'], "a fallback inside a transaction sees its uncommitted writes");
        $txn->rollback;
    };

    subtest forked_unsupported => sub {
        skip_all "$set->{name} can run forked queries" if $dialect->supports_second_connection($conn->dbh);
        like(dies { $h->forked }, qr/^No second connection can reach this \w+ database, so forked\(\) cannot run/, "forked croaks");
    };

    if ($dialect->supports_second_connection($conn->dbh)) {
        subtest forked_results => sub {
            my $it = $h->forked->iter;
            is($h->forked->mode, 'forked', "forked returns a handle in forked mode");
            like(dies { $h->forked; return }, qr/^forked\(\) returns a new handle and leaves this one unchanged/, "forked in void context croaks");
            ok(wait_ready($it), "a forked iterator becomes ready");
            my @rows = $it->all;
            is(names(@rows), [qw/a b c/], "its rows arrive");
            isa_ok($rows[0], ['DBIx::QuickORM::Row'], "as row objects");
            ok($orm->is_canon(items => $rows[0]), "collected outside a transaction, they are ingested");
            is($h->forked->where({id => 2})->iter->next->field('name'), 'b',         "next waits, and where applies");
            is(names($h->forked->all),                                  [qw/a b c/], "the handle's own reading methods wait as well");
            my $fh = $h->forked;
            ref_is($fh->iter->query, $fh->iter->query, "every iter on a forked handle shares its one query");
            is(names($fh->all), [qw/a b c/], "which the handle reads too");
            # Whether ready then all runs a second query is not checked here: a forked query runs in a child,
            # where on_execute cannot count it.

            my $f = $orm->handle('floats')->row_class(undef);
            is(sprintf('%.17g', ($f->forked->iter->all)[0]->{val}), sprintf('%.17g', ($f->iter->all)[0]->{val}), "a double keeps every digit on its way from the child");
        };

        subtest forked_and_transactions => sub { $txn_rules->('forked') };

        subtest forked_errors => sub {
            my $it = $orm->handle(\'SELECT * FROM qorm_no_such_table')->forked->iter;
            like(dies { $it->all }, qr/^The forked query failed: .*qorm_no_such_table/s, "the child's error is thrown on collection");
            is(names($h->forked->iter->all), [qw/a b c/], "and later forked queries work");

            my $dbh_orm = DBIx::QuickORM->new(dbh => $db->connect);
            like(dies { $dbh_orm->handle('items')->forked }, qr/^This ORM was given a 'dbh', so it cannot open the second connection forked\(\) needs/, "an ORM given a dbh croaks at forked()");
        };

        subtest forked_cancel => sub {
            {
                my $it = $h->forked->iter;
            }
            ok(waitpid(-1, POSIX::WNOHANG()) <= 0, "a forked iterator freed before collection reaps its child (no zombie is left)");

            skip_all "$set->{name} has no lock to hold a query back" unless $gate;
            my $holder = $db->connect;
            $holder->do($gate->{hold});
            {
                my $it = $orm->handle(\$gate->{gated})->forked->iter;
                ok(!$it->ready, "not ready while another session holds the lock");
            }
            ok(waitpid(-1, POSIX::WNOHANG()) <= 0, "a child blocked on a lock is killed and reaped, with the lock still held");
            $holder->do($gate->{release});
        };

        subtest forked_parent_survives => sub {
            my $dbh = $conn->dbh;
            $h->forked->iter->all for 1 .. 2;
            ref_is($orm->connection, $conn, "the ORM keeps its Connection after forked children came and went");
            is($h->count, 3, "and its connection still works");
        };
    }

    return unless $dialect->supports_async;

    subtest async_results => sub {
        my $ah = $h->async;
        is($ah->mode, 'async', "async returns a handle in async mode");
        like(dies { $h->async; return }, qr/^async\(\) returns a new handle and leaves this one unchanged/, "async in void context croaks");
        is($h->mode,                    undef,   "leaving the original alone");
        is($ah->where({id => 2})->mode, 'async', "and modifiers keep the mode");

        my $it = $ah->iter;
        ok(wait_ready($it), "the pending iterator becomes ready");
        my @rows = $it->all;
        is(names(@rows), [qw/a b c/], "its rows arrive");
        isa_ok($rows[0], ['DBIx::QuickORM::Row'], "as row objects");
        ok($orm->is_canon(items => $rows[0]), "ingested like a synchronous fetch");
        ok($it->ready,                        "a collected iterator stays ready");

        is(names($ah->iter->all),                            [qw/a b c/], "all waits for the rows");
        is($ah->where({id => 2})->iter->next->field('name'), 'b',         "next waits too, and where applies");
        is(names($ah->all),                                  [qw/a b c/], "the handle's own reading methods wait as well");
        my $ready = $h->async;
        wait_ready($ready);
        my $runs  = 0;
        my $watch = on_execute { $runs++ };
        is(names($ready->all),                                                                                      [qw/a b c/], "all after ready on an async handle");
        is($ready->first->field('name'),                                                                            'a',         "and first");
        is($runs,                                                                                                   0,           "read the query ready started");
        is([map { $_->{name} } $h->row_class(undef)->async->iter->all],                                             [qw/a b c/], "row_class applies");
        is([map { $_->field('n') } $orm->handle('items')->fields({n => 'name'})->order_by('id')->async->iter->all], [qw/a b c/], "computed rows work");
    };

    subtest async_busy => sub {
        my $it = $h->async->iter;
        like(dies { $h->iter },                                      $BUSY, "another query croaks while it is pending");
        like(dies { $h->async->iter },                               $BUSY, "so does a second async query");
        like(dies { $h->count },                                     $BUSY, "and a count");
        like(dies { $orm->insert(items => {id => 9, name => 'x'}) }, $BUSY, "and a write");
        like(dies { $orm->txn },                                     $BUSY, "and starting a transaction");
        is($conn->txns,     [],          "no transaction was started");
        is(names($it->all), [qw/a b c/], "collecting it");
        is($h->count,       3,           "frees the connection");

        my $txn = $orm->txn;
        $orm->insert(items => {id => 4, name => 'd'});
        $it = $h->async->iter;
        like(dies { $txn->commit },   $BUSY, "commit croaks while it is pending");
        like(dies { $txn->rollback }, $BUSY, "and so does rollback");
        is(scalar(@{$conn->txns}), 1, "the transaction is still open");
        my @rows = $it->all;
        is(names(@rows), [qw/a b c d/], "the async query ran inside the transaction and sees its write");
        ok($orm->is_canon(items => $rows[3]), "its rows are canon inside the transaction");
        $txn->rollback;
        is($h->count, 3, "after collecting, rollback works");
    };

    subtest async_shared => sub {
        my $ah  = $h->async;
        my $one = $ah->iter;
        my $two;
        ok(lives { $two = $ah->iter }, "a second iter on the same handle does not croak busy") or note($@);
        ref_is($two->query, $one->query, "it shares the one pending query");
        like(dies { $h->count }, $BUSY, "which is still pending");
        is(names($one->all), [qw/a b c/], "collecting through one iterator");
        is($h->count,        3,           "frees the connection");
        is(names($two->all), [qw/a b c/], "and collects for the other");
        is(names($ah->all),  [qw/a b c/], "and for the handle");

        {
            my $ch = $h->async;
            my $it = $ch->iter;
            $ch->clear;
        }
        is($h->count, 3, "the query is cancelled once the handle is cleared and its iterators are freed");
    };

    subtest async_errors => sub {
        my $it;
        ok(lives { $it = $orm->handle(\'SELECT * FROM qorm_no_such_table')->async->iter }, "starting a failing query lives") or note($@);
        like(dies { $it->all }, qr/qorm_no_such_table/, "its error is thrown on collection");
        like(dies { $it->$_ },  qr/qorm_no_such_table/, "and $_ throws it again") for qw/next all first last only/;
        ok(lives { $it->reset }, "reset only rewinds, so it does not throw");
        is($h->count, 3, "and the connection is free");

        $it = $orm->handle(\'SELECT * FROM qorm_no_such_table')->async->iter;
        like(dies { wait_ready($it) }, qr/qorm_no_such_table/, "ready throws the error once the result arrives");
        is($h->count, 3, "and frees the connection too");
    };

    subtest async_not_ready => sub {
        my $holder = $db->connect;
        $holder->do($gate->{hold});
        my $it = $orm->handle(\$gate->{gated})->row_class(undef)->async->iter;
        ok(!$it->ready, "not ready while another session holds the lock");
        ok(!$it->ready, "still not ready when polled again");
        $holder->do($gate->{release});
        ok(wait_ready($it), "ready once the lock is released");
        is($it->next->{x}, 1, "and its row arrives");
        $conn->dbh->do($gate->{release});
    };

    subtest async_cancel => sub {
        {
            my $it = $h->async->iter;
        }
        is($h->count, 3, "an iterator freed before collection frees the connection");

        skip_all "$set->{name} waits for a query it gives up on" unless $set->{family} eq 'PostgreSQL';
        my $holder = $db->connect;
        $holder->do($gate->{hold});
        {
            my $it = $orm->handle(\$gate->{gated})->row_class(undef)->async->iter;

            # A cancel that reaches the server before the query does is ignored, and the query would then wait on
            # the lock this process holds, so wait until it is blocked.
            my $until = time + 30;
            until ($holder->selectrow_array("SELECT COUNT(*) FROM pg_locks WHERE locktype = 'advisory' AND NOT granted")) {
                die "The gated query never blocked\n" if time > $until;
                sleep 0.01;
            }
        }
        is($h->count, 3, "a query blocked on a lock is cancelled, so the connection is free while the lock is still held");
        $holder->do($gate->{release});
    };

    subtest async_unwind => sub {
        my $CANCELLED = qr/^This async query was cancelled when the transaction it ran in was rolled back/;
        my $it;

        my $warnings = warnings {
            my $txn = $orm->txn;
            $orm->insert(items => {id => 5, name => 'e'});
            $it = $h->async->iter;
        };
        is($warnings,   [match qr/went out of scope without commit\(\) or rollback\(\); it was rolled back/], "a transaction dropped with an async query pending is rolled back");
        is($conn->txns, [],                                                                                   "and closed");
        like(dies { $it->all },  $CANCELLED, "its pending query was cancelled");
        like(dies { $it->next }, $CANCELLED, "and every later read says so");
        is($h->count, 3, "the connection is free and the insert is gone");

        like(
            dies {
                $orm->txn(sub { $orm->insert(items => {id => 5, name => 'e'}); $it = $h->async->iter; die "boom\n" })
            },
            qr/^boom$/,
            "a block that throws with an async query pending rethrows"
        );
        is($conn->txns, [], "after rolling back");
        like(dies { $it->all }, $CANCELLED, "and cancelling the query");
        is($h->count, 3, "the connection is free and the insert is gone");

        $orm->txn(sub {
            $orm->insert(items => {id => 5, name => 'e'});
            like(
                dies {
                    $orm->txn(sub { $orm->insert(items => {id => 6, name => 'f'}); $it = $h->async->iter; die "boom\n" })
                },
                qr/^boom$/,
                "a savepoint block that throws with an async query pending rethrows"
            );
            is(scalar(@{$conn->txns}), 1, "only the savepoint was rolled back");
            is($h->count,              4, "its insert is gone, the outer one is kept");
        });
        is($h->count, 4, "and the outer transaction commits");
        $orm->handle('items')->where({id => 5})->delete;

        skip_all "$set->{name} waits for a query it gives up on" unless $set->{family} eq 'PostgreSQL';
        my $holder = $db->connect;
        $holder->do($gate->{hold});
        $warnings = warnings {
            my $txn = $orm->txn;
            $orm->insert(items => {id => 5, name => 'e'});
            $it = $orm->handle(\$gate->{gated})->row_class(undef)->async->iter;

            my $until = time + 30;
            until ($holder->selectrow_array("SELECT COUNT(*) FROM pg_locks WHERE locktype = 'advisory' AND NOT granted")) {
                die "The gated query never blocked\n" if time > $until;
                sleep 0.01;
            }
        };
        is($warnings, [match qr/it was rolled back/], "a transaction dropped with a query blocked on a lock is rolled back");
        is($h->count, 3,                              "the query was cancelled, so the connection is free while the lock is still held");
        $holder->do($gate->{release});
    };

    subtest async_fork_boundary => sub {
        my $it     = $h->async->iter;
        my $status = in_child(sub {
            my $err = (dies { $it->next }) // '';
            return $err =~ m/^This iterator's query was started in process \d+; it cannot be read in process $$/ ? 0 : 1;
        });
        is($status,         0,           "a child cannot collect an iterator it inherited");
        is(names($it->all), [qw/a b c/], "and the parent still can");
        is($h->count,       3,           "the parent's connection survives the child");

        subtest child_exit => sub {
            skip_all "DBD::Pg may crash in a child exiting with an inherited async query pending on $^O (bucardo/dbdpg#218)"
                if $set->{family} eq 'PostgreSQL' && pg_fork_exit_crashes();

            # This child exits normally, so DBI's and the drivers' end-of-process cleanup runs with the parent's
            # query still pending on the inherited handle.
            $it = $h->async->iter;
            my $pid = fork // die "Could not fork: $!";
            unless ($pid) {
                my $ok = eval { $orm->handle('items')->count == 3 };
                undef $it;
                exit($ok ? 0 : 1);
            }
            waitpid($pid, 0);
            is($?,              0,           "a child can use the ORM, drop the inherited iterator, and exit normally");
            is(names($it->all), [qw/a b c/], "and the parent's pending query is untouched");
            is($h->count,       3,           "as is its connection");

            $it  = $h->async->iter;
            $pid = fork // die "Could not fork: $!";
            exit(0) unless $pid;
            waitpid($pid, 0);
            is($?,              0,           "a child that never uses the ORM exits normally holding the inherited iterator");
            is(names($it->all), [qw/a b c/], "and the parent's pending query is untouched");
        };
    };

    subtest aside_results => sub {
        my $it = $h->aside->iter;
        like(dies { $h->aside; return }, qr/^aside\(\) returns a new handle and leaves this one unchanged/, "aside in void context croaks");
        ok(wait_ready($it), "an aside iterator becomes ready");
        my @rows = $it->all;
        is(names(@rows), [qw/a b c/], "its rows arrive");
        ok($orm->is_canon(items => $rows[0]), "collected outside a transaction, they are ingested");
        is($h->aside->where({id => 3})->iter->next->field('name'), 'c', "next waits, and where applies");
        my $sh = $h->aside;
        ref_is($sh->iter->query, $sh->iter->query, "every iter on an aside handle shares its one query");
        is(names($sh->all), [qw/a b c/], "which the handle reads too");

        my $ready = $h->aside;
        wait_ready($ready);
        my $runs  = 0;
        my $watch = on_execute { $runs++ };
        is(names($ready->all),           [qw/a b c/], "all after ready on an aside handle");
        is($ready->first->field('name'), 'a',         "and first");
        is($runs,                        0,           "read the query ready started");

        my $async = $h->async->iter;
        is(names($h->aside->iter->all), [qw/a b c/], "an aside query runs while the ORM's connection is busy");
        is(names($async->all),          [qw/a b c/], "and the async query is still collected");
    };

    subtest aside_and_transactions => sub { $txn_rules->('aside') };

    subtest aside_not_ready => sub {
        my $holder = $db->connect;
        $holder->do($gate->{hold});
        my $it = $orm->handle(\$gate->{gated})->row_class(undef)->aside->iter;
        ok(!$it->ready, "not ready while another session holds the lock");
        is($h->count, 3, "and the ORM's own connection is free meanwhile");
        $holder->do($gate->{release});
        ok(wait_ready($it), "ready once the lock is released");
        is($it->next->{x}, 1, "and its row arrives");
    };

    subtest aside_closes => sub {
        my @handles;
        my $orm2 = DBIx::QuickORM->new(connect => sub { push @handles => $db->connect; $handles[-1] });
        my $h2   = $orm2->handle('items');

        is(scalar(@{[$h2->aside->iter->all]}), 3, "an aside query runs");
        is(scalar(@handles),                   2, "on a connection of its own");
        ok(!$handles[1]->{Active}, "which is closed once the rows are collected");

        {
            my $it = $h2->aside->iter;
        }
        ok(!$handles[2]->{Active}, "and closed when a pending iterator is freed before collection");

        my $it = $orm2->handle(\'SELECT * FROM qorm_no_such_table')->aside->iter;
        like(dies { $it->all }, qr/qorm_no_such_table/, "an aside query's error is thrown on collection");
        ok(!$handles[3]->{Active}, "and its connection is closed");
        ok($handles[0]->{Active},  "the ORM's own connection is untouched throughout");

        my $dbh_orm = DBIx::QuickORM->new(dbh => $db->connect);
        like(dies { $dbh_orm->handle('items')->aside }, qr/^This ORM was given a 'dbh', so it cannot open the second connection aside\(\) needs/, "an ORM given a dbh croaks at aside()");
        ok(lives { my $ah = $dbh_orm->handle('items')->async }, "but async() does not need a second connection");
    };
};

# An in-memory SQLite database: forked cannot reach it, even through connect.
{
    require DBI;
    my $mem = DBIx::QuickORM->new(
        connect => sub {
            my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
            $dbh->do("CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT)");
            $dbh->do("INSERT INTO items (id, name) VALUES (1, 'a')");
            return $dbh;
        }
    );
    my $h = $mem->handle('items');
    is([$h->can_async, $h->can_aside, $h->can_forked], [0, 0, 0], "in-memory SQLite runs no background mode");
    is($h->maybe_forked->mode,                         undef,     "so maybe_forked falls back");
    is(names($h->maybe_forked->all),                   ['a'],     "and runs the query");
}

done_testing;
