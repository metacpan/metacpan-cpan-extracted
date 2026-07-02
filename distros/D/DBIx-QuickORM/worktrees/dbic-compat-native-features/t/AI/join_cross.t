use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# cross_join() must produce a link-less CROSS JOIN with no ON clause
# (CROSS JOIN ... ON is rejected by PostgreSQL) and actually run.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/join_cross.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE foo (foo_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
    $dbh->do('CREATE TABLE bar (bar_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

$con->handle('foo')->insert({name => $_}) for qw/f1 f2/;
$con->handle('bar')->insert({name => $_}) for qw/b1 b2 b3/;

subtest sql_shape => sub {
    my $h       = $con->handle('foo')->cross_join('bar');
    my $moniker = ${$h->source->source_db_moniker};

    like($moniker, qr/\bCROSS JOIN\b/, "moniker contains CROSS JOIN");
    unlike($moniker, qr/\bON\b/, "moniker contains no ON clause");
};

subtest results => sub {
    my $h = $con->handle('foo')->cross_join('bar')->order_by(qw/a.foo_id b.bar_id/);

    my @rows = $h->data_only->all;
    is(scalar(@rows), 6, "cross join yields the full cartesian product (2 x 3)");

    is(
        [map { [$_->{'a.name'}, $_->{'b.name'}] } @rows],
        [
            ['f1', 'b1'], ['f1', 'b2'], ['f1', 'b3'],
            ['f2', 'b1'], ['f2', 'b2'], ['f2', 'b3'],
        ],
        "every foo is paired with every bar"
    );

    is($h->count, 2, "count over a cross join still counts distinct primary rows");
};

subtest errors => sub {
    like(
        dies { my $x = $con->handle('foo')->cross_join() },
        qr/No table provided to cross_join\(\)/,
        "cross_join with no arguments croaks"
    );

    like(
        dies { my $x = $con->handle('foo')->join() },
        qr/No link provided to join\(\)/,
        "join with no arguments croaks"
    );

    like(
        dies { my $x = $con->handle('foo')->cross_join('not_a_table') },
        qr/Table 'not_a_table' is not defined/,
        "cross_join with an unknown table croaks"
    );
};

done_testing;
