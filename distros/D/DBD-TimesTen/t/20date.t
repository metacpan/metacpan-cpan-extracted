#!perl -w
# $Id: 20date.t 546 2006-11-26 17:51:19Z wagnerch $

use Test::More;
use DBI;
unshift @INC, 't';

$| = 1;
plan tests => 30;


my ($sth, $tmp);

## Connect
my $dbh = DBI->connect();
unless ($dbh)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


$dbh->{PrintError} = 0;
$dbh->do("DROP TABLE dbd_timesten_date_test");
$dbh->{PrintError} = 1;

$dbh->do("
   CREATE TABLE dbd_timesten_date_test (
       tcol1 TIME NOT NULL
      ,tcol2 DATE NOT NULL
      ,tcol3 TIMESTAMP NOT NULL
   )
", undef);
ok(!$DBI::err, 'create table ok');

my (@test_data) = (
    [ '12:59:59', '2000-01-01', '2000-01-01 12:59:59' ]
   ,[ '00:00:00', '1999-12-31', '1999-12-31 00:00:00' ]
   ,[ '12:00:00', '2008-02-29', '2008-02-29 12:00:00' ]
);

foreach $data (@test_data)
{
   $dbh->do("
      INSERT INTO dbd_timesten_date_test (tcol1, tcol2, tcol3)
      VALUES (?, ?, ?)
   ", undef, $data->[0], $data->[1], $data->[2]);
   ok(!$DBI::err, 'insert ok');

   my ($sth) = $dbh->prepare("
      SELECT tcol1, tcol2, tcol3
        FROM dbd_timesten_date_test
   ");
   ok($sth, 'prepare ok');
   ok($sth->execute(), 'execute ok');
   my ($row) = $sth->fetchrow_arrayref();
   ok($row, 'row fetch ok');
   $sth->finish();

   my ($i);
   for ($i = 0; $i < 3; $i++)
   {
      ok($data->[$i] eq $row->[$i], 'column ' . $i . ' compare ok');
   }

   $dbh->do("
      DELETE FROM dbd_timesten_date_test
   ");
   ok(!$DBI::err, 'delete ok');
   cmp_ok($sth->rows, '==', 1, 'rows affected == 1');
}

$dbh->do("DROP TABLE dbd_timesten_date_test");
ok(!$DBI::err, 'drop table ok');

ok($dbh->disconnect(), 'disconnect ok');
exit 0;
