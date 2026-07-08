use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# When a declared table renames a physical table via db_name (e.g. a 'users'
# source backed by the physical 'app_users' table), merging the declared schema
# with the introspected one must collapse the two into a single source keyed by
# the declared ORM name, not leave both a declared 'users' and an introspected
# 'app_users' behind.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

use DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/alias.sqlite";

{
    my $dbh = DBI->connect("dbi:SQLite:dbname=$file", '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE app_users (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->disconnect;
}

orm myorm => sub {
    db mydb => sub {
        dialect 'SQLite';
        db_name $file;
    };

    autofill sub { 1 };

    schema sub {
        table users => sub {
            db_name 'app_users';
        };
    };
};

my $con    = orm('myorm')->connect;
my $schema = $con->schema;

is(scalar($schema->tables), 1, "exactly one source survives for the single physical table");

ok($schema->maybe_table('users'), "the declared ORM name 'users' is present");
ok(!$schema->maybe_table('app_users'), "no leftover source under the physical name 'app_users'");

my $table = $schema->maybe_table('users');
is($table->db_name, 'app_users', "the surviving source maps to the physical 'app_users' table");
is($table->primary_key, ['id'], "the surviving source carries the introspected primary key");
ok($table->column('id'), "the surviving source carries the introspected columns");

done_testing;
