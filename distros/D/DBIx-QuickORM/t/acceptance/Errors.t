# Test origin: AI
use Test2::V0;
use lib 't/lib';

use POSIX();

use DBIx::QuickORM;
use DBIx::QuickORM::Test;

my $EXC = 'DBIx::QuickORM::Exception::DB';

# What each family reports: the SQLSTATE on PostgreSQL, the native code on SQLite and the MySQL family, only the
# message on DuckDB.
my %EXPECT = (
    PostgreSQL => {state  => {unique_violation => '23505', foreign_key_violation => '23503', not_null_violation => '23502', check_violation => '23514'}},
    SQLite     => {native => {pk               => 1555, unique_violation => 2067, foreign_key_violation => 787,  not_null_violation => 1299, check_violation => 275}},
    MariaDB    => {native => {unique_violation => 1062, fk_insert        => 1452, fk_delete             => 1451, nn_null            => 1048, nn_omitted      => 1364, check_violation => 4025}},
    MySQL      => {native => {unique_violation => 1062, fk_insert        => 1452, fk_delete             => 1451, nn_null            => 1048, nn_omitted      => 1364, check_violation => 3819}},
    DuckDB     => {},
);

# The MySQL family parsed and ignored CHECK before MySQL 8.0.16 and MariaDB 10.2.1.
sub enforces_check {
    my ($dbh, $family) = @_;
    return 1 unless $family =~ m/^(?:MySQL|MariaDB)$/;
    my ($version) = $dbh->selectrow_array('SELECT version()');
    my @v         = $version =~ m/^(\d+)\.(\d+)\.(\d+)/;
    my @min       = $version =~ m/MariaDB/i ? (10, 2, 1) : (8, 0, 16);
    return ($v[0] <=> $min[0] || $v[1] <=> $min[1] || $v[2] <=> $min[2]) >= 0;
}

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};
    my $expect = $EXPECT{$family};

    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });    # SQLite: the ORM turns foreign keys on
    my $dbh = $orm->connection->dbh;

    $dbh->do('CREATE TABLE parent (id INTEGER PRIMARY KEY)');
    $dbh->do('CREATE TABLE child (id INTEGER PRIMARY KEY, pid INTEGER NOT NULL, n INTEGER, u INTEGER UNIQUE, CHECK (n > 0), FOREIGN KEY (pid) REFERENCES parent (id))');
    $dbh->do('INSERT INTO parent (id) VALUES (1)');
    $dbh->do('INSERT INTO child (id, pid, n, u) VALUES (1, 1, 1, 1)');

    my $check = sub {
        my ($name, $kind, $sql, $code_key) = @_;

        my $err = dies { $dbh->do($sql) };
        isa_ok($err, [$EXC], "$name: a database exception") or return note($err);
        is($err->kind,      $kind, "$name: the kind is $kind");
        is($err->retriable, 0,     "$name: not retriable");
        like($err->errstr, qr/\S/, "$name: with the driver's error text");

        if (my $state = $expect->{state} && $expect->{state}->{$kind}) {
            is($err->state, $state, "$name: SQLSTATE $state");
        }
        if (my $native = $expect->{native} && ($expect->{native}->{$code_key // ''} // $expect->{native}->{$kind})) {
            is($err->native, $native, "$name: native code $native");
        }
    };

    $check->('duplicate primary key',    'unique_violation',      'INSERT INTO child (id, pid, n, u) VALUES (1, 1, 1, 2)', 'pk');
    $check->('duplicate unique column',  'unique_violation',      'INSERT INTO child (id, pid, n, u) VALUES (2, 1, 1, 1)');
    $check->('missing parent row',       'foreign_key_violation', 'INSERT INTO child (id, pid, n, u) VALUES (3, 9, 1, 3)',    'fk_insert');
    $check->('delete referenced parent', 'foreign_key_violation', 'DELETE FROM parent WHERE id = 1',                          'fk_delete');
    $check->('null in NOT NULL column',  'not_null_violation',    'INSERT INTO child (id, pid, n, u) VALUES (4, NULL, 1, 4)', 'nn_null');
    $check->('NOT NULL column left out', 'not_null_violation',    'INSERT INTO child (id, n, u) VALUES (5, 1, 5)',            'nn_omitted');

    SKIP: {
        skip "this server version does not enforce CHECK constraints", 1 unless enforces_check($dbh, $family);
        $check->('failed CHECK', 'check_violation', 'INSERT INTO child (id, pid, n, u) VALUES (6, 1, -1, 6)');
    }

    subtest message => sub {
        my $sql   = 'INSERT INTO child (id, pid, n, u) VALUES (1, 1, 1, 1)';
        my $plain = $db->connect;
        $plain->{PrintError} = 0;
        my $dbi = eval { $plain->do($sql); 1 } ? undef : $@;
        my $err = dies { $dbh->do($sql) };

        ok(!ref($dbi), "Without the ORM, DBI dies with a string");
        like($dbi, qr/^\Q$err\E at \S+ line \d+\.$/, "The exception stringifies to DBI's message, without the location Perl adds");

        my $sth = $dbh->prepare($sql);
        $err = dies { $sth->execute };
        is($err->statement, $sql, "An error on a statement handle names its SQL");
    };

    subtest unclassified => sub {
        my $err = dies { $dbh->do('SELECT * FROM qorm_no_such_table') };
        isa_ok($err, [$EXC], "An unclassified error is an exception too");
        is($err->kind,      undef, "with no kind");
        is($err->retriable, undef, "and unknown retriability");
    };

    subtest dbh_form => sub {
        my $orm = DBIx::QuickORM->new(dbh => $db->connect);
        isa_ok(dies { $orm->connection->dbh->do('SELECT * FROM qorm_no_such_table') }, [$EXC], "A given handle raises exceptions too");
    };

    subtest sqlite_foreign_keys => sub {
        skip_all "SQLite only" unless $family eq 'SQLite';

        my $fresh = DBIx::QuickORM->new(connect => sub { $db->connect });                   # its map sees the tables
        my $err   = dies { $fresh->delete_row(parent => {id => 1}, enforce_canon => 0) };
        isa_ok($err, [$EXC], "Deleting a referenced row croaks");
        is($err->kind, 'foreign_key_violation', "with the foreign key error");

        my $on = sub { scalar $_[0]->connection->dbh->selectrow_array('PRAGMA foreign_keys') };
        is($on->($orm),                                     1, "Foreign keys are on for a connection the ORM opens");
        is($on->(DBIx::QuickORM->new(dbh => $db->connect)), 1, "and for a handle it is given");

        my $pid = fork // die "Could not fork: $!";
        POSIX::_exit($on->($orm) == 1 ? 0 : 1) unless $pid;
        waitpid($pid, 0);
        is($?, 0, "and for a forked child's reconnect");
    };

    subtest own_croaks => sub {
        my $err = dies { $orm->is_canon(qorm_no_such_table => {}) };
        ok(!ref($err), "The ORM's own croaks are plain strings");
    };
};

done_testing;
