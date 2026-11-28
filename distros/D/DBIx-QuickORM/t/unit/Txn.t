# Test origin: AI
use Test2::V0;

use DBI;
use File::Spec;
use File::Temp qw/tempdir/;
use DBIx::QuickORM;

my $FILE = __FILE__;

sub orm {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)");
    return DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
}

# Records the SQL prepared, and fails the statements named in %FAIL.
my (@SQL, %FAIL);
my $mock = mock 'DBI::db' => (
    around => [
        prepare => sub {
            my ($orig, $dbh, $sql, @rest) = @_;
            push @SQL => $sql;
            die "$sql refused\n" if $FAIL{$sql};
            return $dbh->$orig($sql, @rest);
        },
    ],
);

subtest attributes => sub {
    my $orm  = orm();
    my $line = __LINE__ + 1;
    my $txn  = $orm->txn;
    ref_is($txn->connection, $orm->connection, "connection");
    like($txn->name, qr/^qorm_txn_\d+$/, "name");
    is($txn->depth,     1,                              "depth");
    is($txn->caller,    [__PACKAGE__, __FILE__, $line], "caller is where the ORM's txn was called");
    is($txn->opened_at, "$FILE line $line",             "opened_at");
    $txn->rollback;
};

subtest sql => sub {
    my $orm = orm();
    @SQL = ();
    my $txn = $orm->txn;
    my $sp1 = $orm->txn;
    $sp1->commit;
    my $sp2 = $orm->txn;
    $sp2->rollback;
    $txn->commit;
    $orm->txn->rollback;

    my ($n1, $n2) = ($sp1->name, $sp2->name);
    is(\@SQL, ['BEGIN', "SAVEPOINT $n1", "RELEASE SAVEPOINT $n1", "SAVEPOINT $n2", "ROLLBACK TO SAVEPOINT $n2", "RELEASE SAVEPOINT $n2", 'COMMIT', 'BEGIN', 'ROLLBACK'], "Transactions are SQL statements");
    ok($orm->connection->dbh->{AutoCommit}, "DBI's AutoCommit is never turned off");
};

subtest commit_fails => sub {
    my $orm  = orm();
    my $conn = $orm->connection;
    my $txn  = $orm->txn;
    $orm->insert(t => {id => 1, v => 'x'});

    local $FAIL{COMMIT} = 1;
    is(dies { $txn->commit },                                 "COMMIT refused\n", "A refused commit rethrows the database's error");
    is($conn->txns,                                           [],                 "after rolling back");
    is($conn->dbh->selectrow_array('SELECT COUNT(*) FROM t'), 0,                  "so the write is gone");
};

subtest commit_and_rollback_fail => sub {
    my $orm  = orm();
    my $conn = $orm->connection;
    my $pre  = $orm->insert(t => {id => 2, v => 'y'});
    my $txn  = $orm->txn;
    my $row  = $orm->insert(t => {id => 1, v => 'x'});

    {
        local @FAIL{qw/COMMIT ROLLBACK/} = (1, 1);
        like(dies { $txn->commit }, qr/^The outcome of the transaction opened at \Q$FILE\E line \d+ is unknown: committing it failed, and so did rolling it back\.\nCommit error: COMMIT refused\nRollback error: ROLLBACK refused/, "A refused commit and rollback report the outcome as unknown");
    }
    is($conn->txns, [], "The transaction is dropped");
    ok(!$conn->lookup->in_txn && !$orm->is_canon(t => $row), "and the transaction's lookup levels are emptied");
    ok($orm->is_canon(t => $pre), "but a row held from before the transaction is canon again");
    $conn->dbh->do('ROLLBACK');
};

subtest rollback_fails => sub {
    my $orm  = orm();
    my $conn = $orm->connection;
    my $txn  = $orm->txn;

    local $FAIL{ROLLBACK} = 1;
    my $cleanup = sub { local $FAIL{ROLLBACK} = 0; $conn->dbh->do('ROLLBACK') };
    is(dies { $txn->rollback }, "ROLLBACK refused\n", "A refused rollback throws");
    is(scalar(@{$conn->txns}),  1,                    "and leaves the transaction open");

    my $warnings = warnings { undef $txn };
    is($warnings,   [match qr/^The transaction opened at \Q$FILE\E line \d+ went out of scope without commit\(\) or rollback\(\), and rolling it back failed: ROLLBACK refused/], "Going out of scope then warns that the rollback failed");
    is($conn->txns, [],                                                                                                                                                           "and drops the transaction, which nothing could close any more");
    $cleanup->();

    my $err;
    $warnings = warnings {
        $err = dies {
            $orm->txn(sub { die "block error\n" })
        }
    };
    is($err,        "block error\n",                                                                                                                    "A block's exception propagates when the rollback after it fails");
    is($warnings,   [match qr/^Rolling back the transaction opened at \Q$FILE\E line \d+ after its block threw an exception failed: ROLLBACK refused/], "with one warning about the rollback");
    is($conn->txns, [],                                                                                                                                 "and the transaction is dropped");
    $cleanup->();
};

subtest unknown_outcome_empties_every_txn_level => sub {
    my $orm  = orm();
    my $conn = $orm->connection;

    # Each refuses the savepoint's rollback (and commit) so its outcome is unknown.
    my %paths = (
        commit => sub {
            my $sp = $orm->txn;
            local @FAIL{"RELEASE SAVEPOINT " . $sp->name, "ROLLBACK TO SAVEPOINT " . $sp->name} = (1, 1);
            like(dies { $sp->commit }, qr/is unknown/, "commit: the outcome is unknown");
        },
        block => sub {
            my $name;
            my $w = warnings {
                ok(
                    dies {
                        $orm->txn(sub { $name = "ROLLBACK TO SAVEPOINT " . $_[0]->name; $FAIL{$name} = 1; die "block error\n" })
                    },
                    "block: the block's error propagates"
                );
            };
            delete $FAIL{$name};
            is(scalar(@$w), 1, "block: with a warning");
        },
        destroy => sub {
            my $sp = $orm->txn;
            local $FAIL{"ROLLBACK TO SAVEPOINT " . $sp->name} = 1;
            my $w = warnings { undef $sp };
            is(scalar(@$w), 1, "destroy: going out of scope warns");
        },
    );

    for my $path (sort keys %paths) {
        my $txn = $orm->txn;
        my $row = $orm->insert(t => {id => 1, v => $path});
        $paths{$path}->();

        is(scalar(@{$conn->txns}),          1, "$path: the savepoint is dropped and the root stays open");
        is(scalar(@{$conn->lookup->stack}), 2, "$path: with one lookup level for it above the outside one");
        ok(!$orm->is_canon(t => $row), "$path: the parent level's row is no longer canon");
        $txn->rollback;
    }
};

subtest arguments => sub {
    my $orm = orm();
    like(dies { $orm->connection->txn(bogus => 1) }, qr/^Unknown argument\(s\) to txn\(\): bogus/, "Unknown arguments croak");
};

subtest program_exit => sub {
    my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'exit.sqlite');
    my $dbh  = DBI->connect("dbi:SQLite:dbname=$file", '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE t (id INTEGER PRIMARY KEY)");

    # A script file, not -e: cmd.exe does not take single quotes.
    my $script = File::Spec->catfile(tempdir(CLEANUP => 1), 'exit.pl');
    open(my $fh, '>', $script) or die "Could not write $script: $!";
    print $fh 'our $O = DBIx::QuickORM->new(credentials => {dsn => "dbi:SQLite:dbname=$ARGV[0]"}); our $T = $O->txn; $O->insert(t => {id => 1}); print "ready\n";';
    close($fh) or die "Could not write $script: $!";
    my $out = `"$^X" -Ilib -MDBIx::QuickORM "$script" "$file" 2>&1`;
    is($?,                                              0,         "A program exits cleanly with a transaction open in a global");
    is($out,                                            "ready\n", "quietly");
    is($dbh->selectrow_array('SELECT COUNT(*) FROM t'), 0,         "leaving the transaction uncommitted");
};

done_testing;
