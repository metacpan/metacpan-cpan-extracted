#!perl -w
# $Id: 60array.t 570 2006-12-02 03:32:36Z wagnerch $

use Test::More;
use DBI;
unshift @INC, 't';

$| = 1;
plan tests => 116;


my ($sth, $tmp);

## Connect
my $dbh = DBI->connect();
unless ($dbh)
{
   BAILOUT("Unable to connect to database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}


my (@test_data) = (
    [ 'VARCHAR(10)'
     , [ 'foo', 'bar', 'fee', 'foo', 'fum' ]
     , [ 'abc', 'def', 'ghi', 'jkl', 'mno' ]
     , [ 'pqr', 'stu', 'vwy', 'z01', '234' ]
    ]
   ,[ 'INTEGER'
     , [ '1', '2', '3', '4', '5' ]
     , [ '6', '7', '8', '9', '10' ]
     , [ '11', '12', '13', '-2147483648', '-2147483647' ]
    ]
   ,[ 'BIGINT'
     , [ '1', '2', '3', '4', '5' ]
     , [ '6', '7', '8', '9', '10' ]
     , [ '11', '12', '13', '-9223372036854775807', '9223372036854775807' ]
    ]
   ,[ 'NUMERIC(38,2)'
     , [ '1.5', '2.3', '3.4', '4.6', '5.6' ]
     , [ '6.33', '7.66', '8.88', '9.0', '10.2' ]
     , [ '11.22', '12.95', '13.9', '14.3', '222222222222222222222222222222222222.22' ]
    ]
   ,[ 'DOUBLE'
     , [ '1.5', '2.3', '3.4', '4.6', '5.6' ]
     , [ '6.33', '7.66', '8.88', '9.0', '16666666666666666666666666666666666666666666666666666' ]
     , [ '11.22', '12.95', '13.9', '-1.7e+308', '1.7e+308' ]
    ]
   ,[ 'REAL'
     , [ '1.5', '2.3', '3.4', '4.6', '5.6' ]
     , [ '6.33', '7.66', '8.88', '9.0', '377777777777777777777777' ]
     , [ undef, '12.95', undef, '-3.4e+38', '3.4e+38' ]
    ]
);

foreach $data (@test_data)
{
   $dbh->{PrintError} = 0;
   $dbh->do("DROP TABLE dbd_timesten_array_test");
   $dbh->{PrintError} = 1;

   $dbh->do("
      CREATE TABLE dbd_timesten_array_test (
          tcol1 " . $data->[0] . " NOT NULL
         ,tcol2 " . $data->[0] . " NOT NULL
         ,tcol3 " . $data->[0] . "
      )
   ", undef);
   ok(!$DBI::err, 'create table ' . $data->[0]);

   my $tuple_status = [];

   $sth = $dbh->prepare("
      INSERT INTO dbd_timesten_array_test (tcol1, tcol2, tcol3)
      VALUES (?, ?, ?)
   ");

   ok ($sth->execute_array (
          { ArrayTupleStatus => $tuple_status }
         ,$data->[1]
         ,$data->[2]
         ,$data->[3]), 'execute array ' . $data->[0]);

   $sth->finish();

   $sth = $dbh->prepare("
      SELECT tcol1, tcol2, tcol3
        FROM dbd_timesten_array_test
   ");

   ok (!$DBI::err, 'prepare');
   ok ($sth->execute(), 'execute');

   my ($j) = 0;
   while ($tmp = $sth->fetchrow_arrayref())
   {
      my ($i);
      for ($i = 0; $i < 3; $i++)
      {
         if ($data->[0] =~ /CHAR/)
         {
            cmp_ok($data->[$i + 1]->[$j], 'eq', $tmp->[$i], 'row ' . $j . '/column ' . $i . ' compare');
         }
         else
         {
            if (defined $data->[$i + 1]->[$j])
            {
               cmp_ok($data->[$i + 1]->[$j] - $tmp->[$i], '<=', 0.1, 'row ' . $j . '/column ' . $i . ' compare');
            }
            else
            {
               ok(!defined ($data->[$i + 1]->[$j]) && !defined ($tmp->[$i]), 'row ' . $j . '/column ' . $i . ' compare');
            }
         }
      }

      $j++;
   }
}

$dbh->do("DROP TABLE dbd_timesten_array_test");
ok(!$DBI::err, 'drop table');

ok($dbh->disconnect(), 'disconnect');
exit 0;
