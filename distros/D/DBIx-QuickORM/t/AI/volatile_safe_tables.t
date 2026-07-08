use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# The "safe tables" listing: Schema/Connection->volatile_free_tables reports the
# tables with no volatile columns, and Table->has_volatile_columns is the
# per-table predicate.

use DBIx::QuickORM;

subtest schema_level => sub {
    my $schema = schema safe_check => sub {
        table risky => sub {
            column id      => sub { primary_key; affinity 'numeric' };
            column touched => sub { affinity 'string'; volatile };
        };
        table calm => sub {
            column id   => sub { primary_key; affinity 'numeric' };
            column name => sub { affinity 'string' };
        };
    };

    ok($schema->table('risky')->has_volatile_columns,  "a table with a volatile column reports has_volatile_columns");
    ok(!$schema->table('calm')->has_volatile_columns,  "a table with no volatile column reports none");
    is([$schema->volatile_free_tables], ['calm'], "volatile_free_tables lists only the table with no volatile columns");
};

subtest connection_level => sub {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };

    my $dir = tempdir(CLEANUP => 1);
    my $dsn = "dbi:SQLite:dbname=$dir/safe.sqlite";
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        # widgets has an identity column (auto-volatile); notes has none.
        $dbh->do('CREATE TABLE widgets (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
        $dbh->do('CREATE TABLE notes (note_id TEXT PRIMARY KEY, body TEXT NOT NULL)');
        $dbh->disconnect;
    }

    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    my @safe = $con->volatile_free_tables;
    ok((grep { $_ eq 'notes' } @safe),    "a table with no volatile columns is listed as safe");
    ok(!(grep { $_ eq 'widgets' } @safe), "a table with an identity (auto-volatile) column is not listed as safe");
};

done_testing;
