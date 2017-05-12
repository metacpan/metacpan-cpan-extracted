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

pass('Statistics tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

eval { $dbh->statistics_info };
ok( $@,"Call to statistics_info with 0 arguments, error expected: $@");

{
  local $dbh->{Warn} = 0;
  local $dbh->{PrintError} = 0;

  my $sth = $dbh->statistics_info( undef, undef, undef, undef, undef );
}
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
SKIP: {
  my $non_supported = '-2146825037';
  skip('statistics_info not supported by provider', 10 )
    if $dbh->err && $dbh->err == $non_supported;


my $catalog = undef;  # TODO: current catalog?
my $schema  = undef;  # TODO: current schema?
my $tbl     = $DBD_TEST::table_name;

my $ti = DBD_TEST::get_type_for_column( $dbh,'A');
is( ref $ti,'HASH','Type info');

{
  local ($dbh->{Warn}, $dbh->{PrintError});
  $dbh->{PrintError} = $dbh->{Warn} = 0;
  $dbh->do("DROP TABLE $tbl");
}
# -----------------------------------------------------------------------------
{
  my $sql = <<"SQL";
CREATE TABLE $tbl
(
  K1 $ti->{TYPE_NAME} PRIMARY KEY
, K2 $ti->{TYPE_NAME}
)
SQL
  $dbh->do( $sql );
  is( $dbh->err, undef,"$sql");

  my $sth = $dbh->statistics_info( $catalog, $schema, $tbl, 0, 0 );
  ok( defined $sth,'Statement handle defined');

  my $a = $sth->fetchall_arrayref;

  print "# Statistics:\n";
  print '# ', DBI::neat_list( $_ ), "\n" for @$a;

  ok( $#$a > 0,'At least one row');
  is( $a->[0][6],'table', 'Type table');

  ok( $dbh->do( $_ ), $_ ) for "DROP TABLE $tbl";
}
# -----------------------------------------------------------------------------
SKIP: {
  my $sql = <<"SQL";
CREATE TABLE $tbl
(
  K1 $ti->{TYPE_NAME}
, K2 $ti->{TYPE_NAME}
, PRIMARY KEY ( K1, K2 )
)
SQL
  {
    local $dbh->{PrintError} = 0;
    $dbh->do( $sql );
  }
  is( $dbh->err, undef,"$sql");

  skip('PK test', 3 ) if $dbh->err;

  my $sth = $dbh->statistics_info( $catalog, $schema, $tbl, 0, 0 );
  ok( defined $sth,'Statement handle defined');

  my $a = $sth->fetchall_arrayref;

  print "# Statistics:\n";
  print '# ', DBI::neat_list( $_ ), "\n" for @$a;

  ok( $#$a > 0,'At least one row');
  is( $a->[0][6],'table', 'Type table');
}
# -----------------------------------------------------------------------------
} # SKIP
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

ok( $dbh->disconnect,'Disconnect');
