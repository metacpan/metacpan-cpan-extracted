use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Regression: joins are only implemented over table/view sources. A handle
# backed by a LiteralSource (a derived-table / literal SQL source) has no
# resolve_link and a bind-ref moniker, so building a join around it used to
# fail deep in construction with obscure errors. It must croak early instead.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/g.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $lit = $con->source(\"SELECT * FROM users");

subtest join_rejects_non_table_sources => sub {
    like(
        dies { my $x = $con->handle($lit)->join('whatever') },
        qr/joins require table sources/,
        "join() on a literal-source handle croaks early",
    );

    like(
        dies { my $x = $con->handle('users')->cross_join(table => $lit) },
        qr/must be a table source/,
        "cross_join() with a literal-source table croaks early",
    );
};

done_testing;
