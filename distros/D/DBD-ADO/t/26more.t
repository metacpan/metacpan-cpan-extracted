#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 7;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('More results tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

my $tbl = $DBD_TEST::table_name;

ok( DBD_TEST::tab_create( $dbh ),"CREATE TABLE $tbl");

my $info =  $dbh->get_info( 36 );
ok( ( $info eq 'Y') || ( $info eq 'N'),'SQL_MULT_RESULT_SETS is Y/N');

SKIP: {
  skip('More results not supported', 2 ) unless $info eq 'Y';

  my $sth = $dbh->prepare(<<"SQL");
SELECT A                  FROM $tbl;
INSERT                    INTO $tbl( a ) VALUES( ? );
SELECT A                  FROM $tbl;
SELECT A, 2  AS B, 3 AS C FROM $tbl;
INSERT                    INTO $tbl( a ) VALUES( ? );
SELECT A,'b' AS B         FROM $tbl;
DELETE                    FROM $tbl;
SQL
  ok( defined $sth,'Statement handle defined');
  $sth->execute( 7, 8 );
  my @a;
  do
  {
    push @a, $sth->{NUM_OF_FIELDS} ? $sth->fetchall_arrayref : [ undef ];
  }
  while ( $sth->more_results );
  my @b =
  (
    []
  , [ undef ]
  , [ [ 7 ] ]
  , [ [ 7, 2, 3 ] ]
  , [ undef ]
  , [ [ 7,'b']
    , [ 8,'b'] ]
  , [ undef ]
  );
  is_deeply( \@a, \@b,'Results o.k.')
}
ok( $dbh->disconnect,'Disconnect');
