#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 14;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Stored procedures tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

SKIP: {
  skip('SQLOLEDB specific tests', 11 )
    if $dbh->{ado_conn}{Provider} !~ /^SQLOLEDB/;

  $dbh->{AutoCommit} = 0;

  my $proc = $DBD_TEST::table_name . '_SP1';

  my $sql = "CREATE PROCEDURE $proc" . '( @i int, @o int OUTPUT ) AS set @o = 2 * @i; return 3 * @i';

  ok( $dbh->do( $sql ),"do: $sql");

  my $sth;
  my $i = 16;
  my $o;
  ok( $sth = $dbh->prepare( $proc, { CommandType => 'adCmdStoredProc'} ),'prepare');
  ok( $sth->bind_param_inout( 2, \$o, 1024 ),'bind_param_inout');
  for (1..2)
  {
    ok( $sth->bind_param( 1, ++$i ),'bind_param');
    ok( $sth->execute,'execute');
    is( $o, 2 * $i,"o: $o = 2 * $i");
    is( $sth->{ado_returnvalue}, 3 * $i,"r: $sth->{ado_returnvalue}");
  }
}
ok( $dbh->disconnect,'Disconnect');
