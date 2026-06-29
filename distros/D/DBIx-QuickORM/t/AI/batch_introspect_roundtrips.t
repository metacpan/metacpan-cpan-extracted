use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;
use lib 't/lib';
use DBIx::QuickORM::Test qw/psql mysql/;

# Batch schema introspection issues a CONSTANT number of database round trips
# regardless of how many tables the database has (one sweep per metadata kind),
# instead of the old query-per-table behavior. This asserts that the round-trip
# count for a 2-table database equals the count for a 25-table database, and
# that it is far below the table count (i.e. O(1), not O(N)).

require DBIx::QuickORM;

# Introspect through the ORM with query-counting callbacks on the connection;
# return (round_trip_count, table_count). $open returns a fresh raw dbh.
sub introspect_queries {
    my ($open) = @_;

    my $count = 0;
    my $con = DBIx::QuickORM->quick(
        connect => sub {
            my $dbh = $open->();
            $dbh->{Callbacks} = {
                map { $_ => sub { $count++; return } }
                    qw/prepare do selectrow_array selectrow_arrayref selectall_arrayref selectcol_arrayref/
            };
            return $dbh;
        },
    );

    my @tables = $con->schema->tables;
    return ($count, scalar @tables);
}

sub make_range {
    my ($dbh, $from, $to, %c) = @_;
    my $id = $c{id} // 'INTEGER PRIMARY KEY';
    my $a  = $c{a}  // 'TEXT';

    for my $i ($from .. $to) {
        $dbh->do("CREATE TABLE t$i (id $id, a $a NOT NULL, b INTEGER)");
        $dbh->do("CREATE INDEX t${i}_b ON t$i(b)");
        $dbh->do("CREATE UNIQUE INDEX t${i}_a ON t$i(a)");
    }
}

# Build a 2-table db, count introspection round trips; grow it to 25 tables,
# count again. The two counts must be equal (constant) and well under 25.
sub check_flavor {
    my %a = @_;

    subtest $a{name} => sub {
        { my $dbh = $a{open}->(); make_range($dbh, 1, 2,  %{$a{cols} // {}}); $dbh->disconnect; }
        my ($q2, $t2) = introspect_queries($a{open});

        { my $dbh = $a{open}->(); make_range($dbh, 3, 25, %{$a{cols} // {}}); $dbh->disconnect; }
        my ($q25, $t25) = introspect_queries($a{open});

        is($t2,  2,  "2 tables introspected");
        is($t25, 25, "25 tables introspected");
        is($q2, $q25, "round-trip count is constant: $q2 (2 tables) == $q25 (25 tables)");
        cmp_ok($q25, '<', $t25, "sub-linear: $q25 round trips for $t25 tables (was O(N) per-table)");
    };
}

# SQLite (always available; the default backend).
SKIP: {
    skip "DBD::SQLite required" unless eval { require DBD::SQLite; 1 };
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/rt.sqlite";
    check_flavor(
        name => 'sqlite',
        open => sub { DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1}) },
    );
}

# DuckDB (embedded, no server; skip if the driver is missing or the file engine
# refuses the second connection).
SKIP: {
    skip "DBD::DuckDB required" unless eval { require DBD::DuckDB; 1 };
    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:DuckDB:dbname=$dir/rt.duckdb";
    my $ok = eval {
        check_flavor(
            name => 'duckdb',
            open => sub { DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1}) },
        );
        1;
    };
    skip "DuckDB unavailable: $@" unless $ok;
}

# PostgreSQL via an ephemeral QuickDB instance.
SKIP: {
    skip "DBD::Pg required" unless eval { require DBD::Pg; 1 };
    my $db = psql() or skip "Could not provision PostgreSQL";
    check_flavor(
        name => 'postgresql',
        cols => {id => 'SERIAL PRIMARY KEY', a => 'TEXT'},
        open => sub {
            my $dbh = $db->connect('quickdb', RaiseError => 1, PrintError => 0, AutoCommit => 1);
            $dbh->do('SET search_path TO public');
            return $dbh;
        },
    );
}

# MySQL / MariaDB via an ephemeral QuickDB instance.
SKIP: {
    skip "DBD::mysql or DBD::MariaDB required" unless eval { require DBD::mysql; 1 } || eval { require DBD::MariaDB; 1 };
    my $db = mysql() or skip "Could not provision MySQL";
    check_flavor(
        name => 'mysql',
        cols => {id => 'INTEGER AUTO_INCREMENT PRIMARY KEY', a => 'VARCHAR(64)'},
        open => sub { $db->connect('quickdb', RaiseError => 1, PrintError => 0, AutoCommit => 1) },
    );
}

done_testing;
