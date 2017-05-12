#!/usr/bin/perl -I./t
$| = 1;
print "1..$tests\n";

use DBI qw(:sql_types);
use ODBCTEST;

print "ok 1\n";

print " Test 2: connecting to the database\n";
my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";

print "ok 2\n";


#### testing a simple select"

print " Test 3: create test table\n";
$rc = ODBCTEST::tab_create($dbh);
print "not " unless($rc);
print "ok 3\n";

print " Test 4: insert test data\n";
my @data = (
	[ 1, 'foo', 'foo varchar' ],
      [ 2, 'bar', 'bar varchar' ],
	  [ 3, 'bletch', 'bletch varchar' ],
);
$rc = tab_insert($dbh, \@data);
unless ($rc) {
	warn "Test 4 is known to fail often. It is not a major concern.\n";
	print "not "
}
print "ok 4\n";

print " Test 5: select test data\n";
$rc = tab_select($dbh, \@data);
print "not " unless($rc);
print "ok 5\n";

$rc = ODBCTEST::tab_delete($dbh);

BEGIN {$tests = 5;}
exit(0);

sub tab_select {
    my $dbh = shift;
    my $dref = shift;
    my @data = @{$dref};
    my @row;

    my $sth = $dbh->prepare("SELECT A,B,C,D FROM $ODBCTEST::table_name WHERE a = ?")
    	or return undef;
	my @bind_vals = (1, 3);
	my $bind_val;
	foreach $bind_val (@bind_vals) {
		$sth->bind_param(1, $bind_val, SQL_INTEGER);
		$sth->execute;
    while (@row = $sth->fetchrow()) {
	print "$row[0]|$row[1]|$row[2]|\n";
			if ($row[0] != $bind_val) {
				print "Bind value failed! bind value = $bind_val, returned value = $row[0]\n";
				return undef;
			}
		}
    }
    return 1;
}

sub tab_insert {
    my $dbh = shift;
    my $dref = shift;
    my @data = @{$dref};
    my $sth = $dbh->prepare(<<"/");
INSERT INTO $ODBCTEST::table_name (a, b, c)
VALUES (?, ?, ?)
/
    unless ($sth) {
	warn $DBI::errstr;
	return 0;
    }
    $sth->{PrintError} = 1;
    foreach (@data) {
	$sth->bind_param(1, $_->[0], SQL_INTEGER);
	$sth->bind_param(2, $_->[1], SQL_VARCHAR);
	$sth->bind_param(3, $_->[2], SQL_VARCHAR);
	return 0 unless $sth->execute;
	$sth->finish();
    }
    my($warn, $result);
    $SIG{__WARN__} = sub { $warn = @_ };
    $result = $dbh->commit();
    $SIG{__WARN__} = 'DEFAULT';
    if (!$result) {
	warn $DBI::errstr;
	return 0;
    }
    1;
}

sub tab_create {
    $dbh->do(<<"/");
DROP TABLE perl_dbd_test
/
    my $fields = "A INTEGER, B CHAR(20), C VARCHAR(100)";
    if ($^O eq 'solaris') {	# Assume Dbf driver. Sad and tacky.
	$fields = "A FLOAT(10,0), B CHAR(20), C MEMO";
    }
    $dbh->do("CREATE TABLE perl_dbd_test ($fields)");
}

sub tab_delete {
    $dbh->do(<<"/");
DELETE FROM perl_dbd_test
/
}

__END__

