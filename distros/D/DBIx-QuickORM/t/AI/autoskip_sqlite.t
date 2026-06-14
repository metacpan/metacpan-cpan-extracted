use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# autoskip support in the SQLite dialect: skipped tables are not introspected
# at all, and skipped columns are left out of their table.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

use DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/autoskip.sqlite";

{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$file", '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT, hidden_col TEXT)');
    $dbh->do('CREATE TABLE secrets (id INTEGER PRIMARY KEY, payload TEXT)');
    $dbh->disconnect;
}

orm myorm => sub {
    db mydb => sub {
        dialect 'SQLite';
        db_name $file;
    };

    autofill sub {
        autoskip table  => 'secrets';
        autoskip column => ('widgets', 'hidden_col');
    };
};

my $con    = orm('myorm')->connect;
my $schema = $con->schema;

ok(!$schema->maybe_table('secrets'), "autoskipped table was not introspected");

my $widgets = $schema->table('widgets');
ok($widgets, "non-skipped table was introspected");
is([sort $widgets->column_names], [qw/id name/], "autoskipped column left out of the table");

done_testing;
