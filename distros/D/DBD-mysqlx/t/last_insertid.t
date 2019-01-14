use strict;
use warnings;
use DBI;
use DBD::mysqlx;
use Test::More tests => 7;

my $dsn = "DBI:mysqlx:localhost/test";
my $dbh = DBI->connect($dsn, "msandbox", "msandbox");

ok $dbh->do("CREATE TEMPORARY TABLE t1(id int auto_increment primary key)");
ok my $sth = $dbh->prepare("INSERT INTO t1() VALUES()");

ok $sth->execute();
is $sth->last_insert_id(undef, undef, undef, undef), 1;

ok $sth->execute();
is $sth->last_insert_id(undef, undef, undef, undef), 2;

ok $sth->finish();

$dbh->disconnect();
