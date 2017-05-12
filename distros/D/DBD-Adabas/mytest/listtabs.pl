#!/usr/bin/perl -I./t

require DBI;

my (@row);

my ($dsn, $user, $pass) = soluser();

my $dbh = DBI->connect()
    || die "Can't connect to your $ENV{DBI_DSN} using user: $ENV{DBI_USER} and pass: $ENV{DBI_PASS}\n$DBI::errstr\n";
# ------------------------------------------------------------

my $rows = 0;
if ($sth = $dbh->tables) {
    my $cols = $sth->{NAME};
    print join(', ', @$cols), "\n";
    while (@row = $sth->fetchrow) {
	$rows++;
	print join(', ', @row), "\n";
	my $sthcols = $dbh->func('',$row[1], $row[2],'', columns);
	if ($sthcols) {
	    while (@row = $sthcols->fetchrow()) {
		print "\t", join(', ', @row), "\n";
	    }
	} else {
	    # hmmm...none of my drivers support this...dang.  I can't test it.
	    print "SQLColumns: $DBI::errstr\n";
	}
    }
    $sth->finish();
}

$dbh->disconnect();

