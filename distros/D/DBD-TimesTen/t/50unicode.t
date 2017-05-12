#!perl -w
# $Id: 50unicode.t 546 2006-11-26 17:51:19Z wagnerch $

use Test::More;
use DBI qw(:sql_types);
use Encode;
unshift @INC, 't';

$| = 1;
plan tests => 27;


unless ($] >= 5.006)
{
   BAILOUT("Unable to run UTF8 tests, perl must be 5.6 or later");
   exit 0;
}

my ($sth, $tmp1, $tmp2);

## Connect
my $dbh = DBI->connect();
unless ($dbh)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


$dbh->{PrintError} = 0;
$dbh->do("DROP TABLE dbd_timesten_unicode_test");
$dbh->{PrintError} = 1;

$dbh->do("
   CREATE TABLE dbd_timesten_unicode_test (
       tcol1 NVARCHAR(100) NOT NULL
   )
", undef);
ok(!$DBI::err, 'create table ok');

my (@test_data) = (
    [ "\x00\x54\x00\x69\x00\x6d\x00\x65\x00\x73\x00\x54\x00\x65\x00\x6e", 1 ]
   ,[ "\x26\x3A", 1 ]
   ,[ Encode::encode('utf16', 'teste'), 1 ]
);

foreach $data (@test_data)
{
   my ($sth) = $dbh->prepare("
      INSERT INTO dbd_timesten_unicode_test (tcol1)
      VALUES (?)
   ");
   ok(!$DBI::err, 'prepare ok');

   $sth->bind_param(1, $data->[0], SQL_WVARCHAR);
   ok(!$DBI::err, 'bind_param ok');

   $sth->execute();
   ok(!$DBI::err, 'execute ok');
   $sth->finish();

   $sth = $dbh->prepare("
      SELECT tcol1
        FROM dbd_timesten_unicode_test
   ");
   ok($sth, 'prepare ok');
   $sth->execute();
   ok(!$DBI::err, 'execute ok');
   my ($row) = $sth->fetchrow_arrayref();
   ok($row, 'fetch ok');
   $sth->finish();

   $tmp1 = join('|', unpack("C*", $data->[0]));
   $tmp2 = join('|', unpack("C*", $row->[0]));
   cmp_ok(($tmp1 eq $tmp2), '==', $data->[1], 'compare ok');

   $dbh->do("
      DELETE FROM dbd_timesten_unicode_test
   ");
   ok(!$DBI::err, 'delete ok');
}

$dbh->do("DROP TABLE dbd_timesten_unicode_test");
ok(!$DBI::err, 'drop table ok');

ok($dbh->disconnect(), 'disconnect ok');
exit 0;
