use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# An autoname table rename (via the pre_table hook) must land the table under
# its new (ORM) name in the schema, as the PostgreSQL dialect already did.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

use DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/autoname.sqlite";

{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$file", '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE widgets (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->disconnect;
}

orm myorm => sub {
    db mydb => sub {
        dialect 'SQLite';
        db_name $file;
    };

    autofill sub {
        autoname table => sub {
            my %params = @_;
            return "renamed_$params{name}";
        };
    };
};

my $con    = orm('myorm')->connect;
my $schema = $con->schema;

my $table = $schema->maybe_table('renamed_widgets');
ok($table, "renamed table is keyed under its new name");
ok(!$schema->maybe_table('widgets'), "no entry remains under the original database name");
is($table->name, 'renamed_widgets', "table object carries the new ORM name");
is($table->db_name, 'widgets', "table object keeps the database name");

done_testing;
