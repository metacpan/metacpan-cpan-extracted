use DBI;
use DB::Introspector;

my $dbh = DBI->connect( @ARGV );

my $introspector = DB::Introspector->get_instance($dbh);

my $table = $introspector->find_table('flavors')
  || die("table flavors could not be found");

print $table->name."\n";

foreach my $column ($table->columns) {
    print "\t".$column->name."\t".ref($column)."\n";
}

$dbh->disconnect();
