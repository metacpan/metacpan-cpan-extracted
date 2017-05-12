use strict;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'TEST_PG_DSN=postgresql://postgres@localhost' unless $ENV{TEST_PG_DSN};

my $tmpdb = DBIx::TempDB->new($ENV{TEST_PG_DSN}, auto_create => 0);
is $ENV{DBIX_TEMP_DB_URL}, undef, 'DBIX_TEMP_DB_URL is not set';

$tmpdb->create_database;
my $database_name = $tmpdb->url->dbname;
is $ENV{DBIX_TEMP_DB_URL}, "$ENV{TEST_PG_DSN}/$database_name", 'DBIX_TEMP_DB_URL is set';

my $dbh = DBI->connect($tmpdb->dsn);
is $dbh->{pg_db}, $database_name, "pg_db $database_name";

$tmpdb->execute_file("users.sql");
$tmpdb->execute("insert into users (name) values ('batman')");

my $sth = $dbh->prepare("select name from users");
$sth->execute;
is $sth->fetchrow_arrayref->[0], "batman", "batman is a user";

done_testing;
