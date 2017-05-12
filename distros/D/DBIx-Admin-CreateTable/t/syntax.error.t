use strict;
use warnings;

use DBI;
use DBIx::Admin::CreateTable;
use Test::More;

# --------------------------------------------------

my($dbh);

eval{$dbh = DBI -> connect($ENV{'DBI_DSN'}, $ENV{'DBI_USER'}, $ENV{'DBI_PASS'}, {PrintError => 0, RaiseError => 0})};

if ($dbh)
{
		plan (tests => 2);
}
else
{
		plan (skip_all => '$DBI_DSN etc not defined, so skipping all tests in syntax.error.pl');
}

my($creator)            = DBIx::Admin::CreateTable -> new(dbh => $dbh, verbose => 0);
my($db_vendor)          = $creator -> db_vendor();
my($table_name)         = 'test';
my($primary_index_name) = $creator -> generate_primary_index_name($table_name);
my($primary_key_sql)    = $creator -> generate_primary_key_sql($table_name);

ok($creator -> drop_table($table_name) eq '', "Drop table '$table_name' worked (table may not have existed)");
ok($creator -> create_table(<<SQL) ne '', "Create table '$table_name' failed, due to a syntax error (missing ,)");
create table $table_name
(
id $primary_key_sql
data varchar(255)
)
SQL

