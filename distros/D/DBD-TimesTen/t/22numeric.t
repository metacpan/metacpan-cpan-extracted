#!perl -w
# $Id: 22numeric.t 557 2006-11-30 23:44:55Z wagnerch $

use Test::More;
use DBI;
unshift @INC, 't';

$| = 1;
plan tests => 44;


my ($sth, $tmp);

## Connect
my $dbh = DBI->connect();
unless ($dbh)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


my (@test_data) = (
    [ 'BIGINT', '-9223372036854775807' ]
   ,[ 'BIGINT', '9223372036854775807' ]
   ,[ 'NUMERIC(38,2)', '222222222222222222222222222222222222.22' ]
   ,[ 'REAL', '377777777777777777777777' ]
   ,[ 'DOUBLE', '16666666666666666666666666666666666666666666666666666' ]
   ,[ 'INTEGER', '-2147483648' ]
   ,[ 'INTEGER', '2147483647' ]
);

foreach $data (@test_data)
{
   $dbh->{PrintError} = 0;
   $dbh->do("DROP TABLE dbd_timesten_numeric_test");
   $dbh->{PrintError} = 1;

   $dbh->do("
      CREATE TABLE dbd_timesten_numeric_test (
          tcol1 " . $data->[0] . "
      )
   ", undef);
   ok(!$DBI::err, 'create ' . $data->[0] . ' table');

   $dbh->do("
      INSERT INTO dbd_timesten_numeric_test (tcol1)
      VALUES (?)
   ", undef, $data->[1]);
   ok(!$DBI::err, 'insert');

   my ($sth) = $dbh->prepare("
      SELECT tcol1
        FROM dbd_timesten_numeric_test
   ");
   ok($sth, 'prepare');
   ok($sth->execute(), 'execute');
   my ($row) = $sth->fetchrow_arrayref();
   ok($row, 'row fetch');
   $sth->finish();
   cmp_ok($data->[1] - $row->[0], '<=', 1, 'compare ' . $data->[0]);
}

$dbh->do("DROP TABLE dbd_timesten_numeric_test");
ok(!$DBI::err, 'drop table');

ok($dbh->disconnect(), 'disconnect');
exit 0;
