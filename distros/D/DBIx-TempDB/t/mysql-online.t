use strict;
use Test::More;
use DBIx::TempDB;

plan skip_all => 'TEST_MYSQL_DSN=mysql://root@127.0.0.1' unless $ENV{TEST_MYSQL_DSN};

my $tmpdb         = DBIx::TempDB->new($ENV{TEST_MYSQL_DSN});
my $database_name = $tmpdb->url->dbname;
my $dbh           = DBI->connect($tmpdb->dsn);

my $sth = $dbh->prepare('select database()');
$sth->execute;
is $sth->fetchrow_arrayref->[0], $database_name, "mysql $database_name";

done_testing;
