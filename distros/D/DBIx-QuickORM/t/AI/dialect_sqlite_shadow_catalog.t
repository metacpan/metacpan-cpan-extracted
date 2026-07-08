use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# SQLite batch introspection sweeps the permanent (main) and temporary (temp)
# catalogs. When a temporary object shadows a permanent one of the same name,
# an UNQUALIFIED pragma_table_xinfo / pragma_index_list / etc. resolves to the
# temp object on both sweeps, poisoning the permanent table's metadata. The
# sweeps schema-qualify each catalog ('main' vs 'temp') and key their results
# by (is_temp, name), so each catalog keeps its own columns, DDL, indexes, and
# foreign keys.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM::Dialect::SQLite;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/shadow.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE foo (perm_id INTEGER PRIMARY KEY, perm_val TEXT)');
    $dbh->do('CREATE UNIQUE INDEX perm_u ON foo(perm_val)');
    $dbh->disconnect;
}

my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1});
$dbh->do('CREATE TEMP TABLE foo (temp_b TEXT, temp_y REAL)');

my $dialect = DBIx::QuickORM::Dialect::SQLite->new(dbh => $dbh, db_name => 'shadow');

subtest xinfo_per_catalog => sub {
    my $x = $dialect->_fetch_all_xinfo;

    my @perm = map { $_->{name} } @{$x->{0}{foo} // []};
    my @temp = map { $_->{name} } @{$x->{1}{foo} // []};

    is([sort @perm], ['perm_id', 'perm_val'], "permanent foo keeps its own columns");
    is([sort @temp], ['temp_b', 'temp_y'],   "temp foo keeps its own columns");
};

subtest ddl_per_catalog => sub {
    my $ddl = $dialect->_fetch_all_ddl;

    like($ddl->{0}{foo}, qr/perm_id/, "permanent foo DDL is the permanent one");
    like($ddl->{1}{foo}, qr/temp_b/,  "temp foo DDL is the temp one");
};

subtest columns_built_from_permanent_catalog => sub {
    my $x    = $dialect->_fetch_all_xinfo;
    my $cols = $dialect->build_columns_from_db(
        'foo',
        autofill     => TestAutofill->new,
        column_rows  => $x->{0}{foo},
        identity_col => undef,
    );

    is([sort keys %$cols], ['perm_id', 'perm_val'], "permanent foo columns are not poisoned by the temp table");
};

done_testing;

# Minimal autofill stub: build_columns_from_db calls skip(), hook(), and
# process_column() on it; none need to do anything for this test.
BEGIN {
    package TestAutofill;
    sub new            { bless {}, shift }
    sub skip           { 0 }
    sub hook           { }
    sub process_column { }
}
