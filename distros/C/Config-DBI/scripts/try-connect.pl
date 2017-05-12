use Config::DBI;

my $test_database = 'homebox';

my $dbh = Config::DBI->$test_database;

if ($dbh) {
  print "Connection successful.";
} else {
  print "Connection failed.";
}

print $/;


