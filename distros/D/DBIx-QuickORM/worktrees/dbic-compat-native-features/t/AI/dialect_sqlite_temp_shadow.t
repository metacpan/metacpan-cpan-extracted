use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Regression: batch introspection sweeps the permanent (sqlite_master) and
# temporary (sqlite_temp_master) catalogs separately and joins the pragma table
# functions laterally with an UNQUALIFIED table name. When a temporary table
# shadows a permanent one of the same name, SQLite resolves the unqualified
# pragma call to the temp object on BOTH sweeps. If the sweeps keyed rows by
# bare name they would pile a shadowed table's rows under one key and double
# its primary-key / unique / index / foreign-key column lists. Keying by
# (is_temp, name) keeps them separate; the temporary table (which shadows)
# wins, exactly as a query against the unqualified name would.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/shadow.sqlite";

# Permanent 'foo' with a DIFFERENT shape than the temp 'foo' created per
# connection below, so we can prove the temp table's metadata is what surfaces.
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE foo (perm_id INTEGER PRIMARY KEY, perm_val TEXT)');
    $dbh->disconnect;
}

# Temp tables live on the connection, so create the shadowing temp 'foo' (and
# the table it references) on every introspection connection.
my $con = DBIx::QuickORM->quick(
    connect => sub {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0, AutoCommit => 1});
        $dbh->do('CREATE TEMP TABLE base (bid INTEGER PRIMARY KEY)');
        $dbh->do(<<'        EOT');
            CREATE TEMP TABLE foo (
                k1     INTEGER,
                k2     INTEGER,
                ref_id INTEGER REFERENCES base(bid),
                PRIMARY KEY (k1, k2),
                UNIQUE (ref_id)
            )
        EOT
        return $dbh;
    },
);

my $schema = $con->schema;
my $foo    = $schema->table('foo');

subtest temp_shadows_permanent => sub {
    ok($foo->is_temp, "the temporary 'foo' shadows the permanent one");
    is([sort $foo->column_names], [qw/k1 k2 ref_id/], "temp table's columns surface (not the permanent table's)");
};

subtest no_doubling => sub {
    is($foo->primary_key, ['k1', 'k2'], "composite primary key has exactly its 2 columns, not doubled");
    is(scalar @{$foo->primary_key}, 2, "primary key length is 2 (doubling would make it 4)");

    ok($foo->unique->{'ref_id'}, "UNIQUE(ref_id) recorded");
    ok($foo->unique->{'k1, k2'}, "composite primary key recorded as a unique key with its real signature");

    for my $idx (@{$foo->indexes}) {
        my %seen;
        $seen{$_}++ for @{$idx->{columns}};
        my ($dupe) = grep { $seen{$_} > 1 } keys %seen;
        ok(!$dupe, "index '$idx->{name}' has no duplicated columns")
            or diag("columns: @{$idx->{columns}}");
    }

    my @links = @{$foo->links};
    is(scalar @links, 1, "exactly one foreign-key link (not duplicated)");
    is($links[0]->local_columns, ['ref_id'], "link local columns not doubled");
    is($links[0]->other_table, 'base', "link points at the referenced table");
};

done_testing;
