use DBI();
use DBD::ADO::Const();

$, = ', ';

print "\nCalling OpenSchema: @ARGV\n\n";

my ( $QueryType, @Criteria ) = @ARGV;

for ( @Criteria ) { undef $_ unless $_ }

unless ( $QueryType )
{
  print "Usage: $0 [QueryType] [Criteria]\n\n";
  print "  QueryTypes:\n";
  print "    $_\n" for sort keys %{DBD::ADO::Const->Enums->{SchemaEnum}};
  exit;
}
my $dbh = DBI->connect or die $DBI::errstr;
   $dbh->{RaiseError} = 1;
   $dbh->{PrintError} = 0;

my $sth = $dbh->func( $QueryType, @Criteria,'OpenSchema');

print @{$sth->{NAME}},"\n";

$sth->dump_results;

$dbh->disconnect;
