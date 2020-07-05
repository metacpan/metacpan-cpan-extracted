use strict;
use Test::More;
use DBIx::TempDB;
use URI::db;

plan skip_all => 'TEST_PG_DSN=postgresql://postgres@localhost' unless $ENV{TEST_PG_DSN};

$ENV{DBIX_TEMP_DB_KEEP_DATABASE} = 1;
$ENV{DBIX_TEMP_DB_SILENT} //= 1;
my $tempdb = DBIx::TempDB->new($ENV{TEST_PG_DSN});
undef $tempdb;    # should normally drop database

my $url = URI::db->new($ENV{DBIX_TEMP_DB_URL});
my $dbh = eval { DBI->connect(DBIx::TempDB::Util::dsn_for($ENV{DBIX_TEMP_DB_URL})) };
ok !$@, 'DBIX_TEMP_DB_KEEP_DATABASE=1' or diag $@;

# clean up manually
$dbh = DBI->connect(DBIx::TempDB::Util::dsn_for("$ENV{TEST_PG_DSN}/postgres"));
$dbh->do("drop database " . $url->dbname);

done_testing;
