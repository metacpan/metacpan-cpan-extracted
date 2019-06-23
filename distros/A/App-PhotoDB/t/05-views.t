use strict;
use warnings;
use Test::More;
use DBI;
use DBD::mysql;

SKIP: {
	# Only execute this set if we have a test DB
	my $dbh = DBI->connect('DBI:mysql:photodb:localhost', 'photodb', 'photodb') or plan skip_all => 'Could not connect to database' ;

	# Get a list of all views
	#my $query = "SHOW FULL TABLES WHERE TABLE_TYPE LIKE 'VIEW'";
	my $query = "SELECT TABLE_NAME FROM information_schema.`TABLES` WHERE TABLE_TYPE LIKE 'VIEW' AND TABLE_SCHEMA LIKE 'photodb'";
	my $sth = $dbh->prepare($query) or die "Can't prepare $query: $dbh->errstr\n";
	my $rv = $sth->execute or die "can't execute the query: $sth->errstr";

	my @views;
	while (my @row = $sth->fetchrow_array) {
		push(@views, $row[0]);
	}

	my $numviews = @views || 0;
	plan tests => $numviews;
	if ($numviews == 0) {
		plan skip_all => 'No SQL views found' ;
		exit;
	}

	# Test each view
	my @passes;
	my @failures;
	foreach my $view (@views) {
		ok(!&test_view($dbh, $view), "view $view");
	}
}

# Test a view
# Returns 0 for OK, error message if not
sub test_view {
	my $dbh = shift;
	my $view = shift;
	my $sth2 = $dbh->prepare("select * from $view") or return $dbh->errstr;
	my $rv2 = $sth2->execute or return $sth2->errstr;
	return 0;
}
