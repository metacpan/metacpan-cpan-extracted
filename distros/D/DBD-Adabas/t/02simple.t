#!/usr/bin/perl -I./t
$| = 1;

use DBI qw(:sql_types);
use ODBCTEST;

print "1..$tests\n";

my ($longstr) = "THIS IS A STRING LONGER THAN 80 CHARS.  THIS SHOULD BE CHECKED FOR TRUNCATION AND COMPARED WITH ITSELF.";
my ($longstr2) = $longstr . "  " . $longstr . "  " . $longstr . "  " . $longstr;

print "ok 1\n";

print " Test 2: connecting to the database\n";
#DBI->trace(2);
my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";
$dbh->{AutoCommit} = 1;

print "ok 2\n";


#### testing a simple select

print " Test 3: create test table\n";
$rc = ODBCTEST::tab_create($dbh);
print "not " unless($rc);
print "ok 3\n";

print " Test 4: check existance of test table\n";
my $rc = 0;
$rc = ODBCTEST::tab_exists($dbh);
print "not " unless($rc >= 0);
print "ok 4\n";

print " Test 5: insert test data\n";
$rc = tab_insert($dbh);
print "not " unless($rc);
print "ok 5\n";

print " Test 6: select test data\n";
$rc = tab_select($dbh);
print "not " unless($rc);
print "ok 6\n";

print " Tests 7,8: test LongTruncOk\n";
$rc = undef;
$dbh->{LongReadLen} = 50;
$dbh->{LongTruncOk} = 1;
$rc = select_long($dbh);
print "not " unless($rc);
print "ok 7\n";

$dbh->{LongTruncOk} = 0;
$rc = select_long($dbh);
print "not " if ($rc);
print "ok 8\n";

print " Test 9: test ColAttributes\n";
$sth = $dbh->prepare("SELECT * FROM $ODBCTEST::table_name ORDER BY A");

if ($sth) {
	$sth->execute();
	my $colcount = $sth->func(1, 0, ColAttributes); # 1 for col (unused) 0 for SQL_COLUMN_COUNT
	print "Column count is: $colcount\n";
	my ($coltype, $colname, $i, @row);
	my $is_ok = 0;
	for ($i = 1; $i <= $colcount; $i++) {
		# $i is colno (1 based) 2 is for SQL_COLUMN_TYPE, 1 is for SQL_COLUMN_NAME
		$coltype = $sth->func($i, 2, ColAttributes);
		$colname = $sth->func($i, 1, ColAttributes);
		print "$i: $colname = $coltype\n";
 		++$is_ok if grep { $coltype == $_ } @{$ODBCTEST::TestFieldInfo{$colname}};
	}
	print "not " unless $is_ok == $colcount;
	print "ok 9\n";
	
	$sth->finish;
}
else {
	print "not ok 9\n";
}

print " Test 10: test \$DBI::err\n";
$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
#
# some ODBC drivers will prepare this OK, but not execute.
# 
$sth = $dbh->prepare("SELECT XXNOTCOLUMN FROM $ODBCTEST::table_name");
$sth->execute() if $sth;
print "not " if (length($DBI::err) < 1);
print "ok 10\n";

print " Test 11: test date values\n";
$sth = $dbh->prepare("SELECT D FROM $ODBCTEST::table_name WHERE D > {d '1998-05-13'}");
$sth->execute();
my $count = 0;
while (@row = $sth->fetchrow) {
	$count++ if ($row[0]);
	# print "$row[0]\n";
}
print "not " if $count != 1;
print "ok 11\n";
  
print " Test 12: test group by queries\n";
$sth = $dbh->prepare("SELECT A, COUNT(*) FROM $ODBCTEST::table_name GROUP BY A");
$sth->execute();
$count = 0;
while (@row = $sth->fetchrow) {
	$count++ if ($row[0]);
	print "$row[0], $row[1]\n";
}
print "not " if $count == 0;
print "ok 12\n";

$rc = ODBCTEST::tab_delete($dbh);

BEGIN {$tests = 12;}
exit(0);

sub tab_select
    {
    my $dbh = shift;
    my @row;
    my $rowcount = 0;

    $dbh->{LongReadLen} = 1000;

    my $sth = $dbh->prepare("SELECT * FROM $ODBCTEST::table_name ORDER BY A")
  		or return undef;
    $sth->execute();
    while (@row = $sth->fetchrow())   {
	    print((defined($row[0]) ? $row[0] : "NULL"), "|",
		  (defined($row[1]) ? $row[1] : "NULL"), "|",
		  (defined($row[2]) ? $row[2] : "NULL"), "\n");
	    ++$rowcount;
	    if ($rowcount != $row[0]) {
		print "Basic retrieval of rows not working!\nRowcount = $rowcount, while retrieved value = $row[0]\n";
		$sth->finish;
		return 0;
	    }
	}
    $sth->finish();

    $sth = $dbh->prepare("SELECT A,C FROM $ODBCTEST::table_name WHERE A>=4")
     	or return undef;
    $sth->execute();
    while (@row = $sth->fetchrow()) {
	if ($row[0] == 4) {
	    if ($row[1] eq $longstr) {
		print "retrieved ", length($longstr), " byte string OK\n";
	    } else {
		print "Basic retrieval of longer rows not working!\nRetrieved value = $row[0]\n";
		return 0;
	    }
	} elsif ($row[0] == 5) {
	    if ($row[1] eq $longstr2) {
		print "retrieved ", length($longstr2), " byte string OK\n";
	    } else {
		print "Basic retrieval of row longer than 255 chars not working!",
		"\nRetrieved ", length($row[1]), " bytes instead of ", 
		length($longstr2), "\nRetrieved value = $row[1]\n";
		return 0;
	    }
	}
    }
  
    return 1;
}
 

#
# show various ways of inserting data without binding parameters.
# Note, these are not necessarily GOOD ways to
# show this...
#
sub tab_insert {
    my $dbh = shift;

    # qeDBF needs a space after the table name!
    my $stmt = "INSERT INTO $ODBCTEST::table_name (a, b, c, d) VALUES ("
	    . join(", ", 3, $dbh->quote("bletch"), "?",
		   "\{d '1998-05-10'\}"). ")";
    my $sth = $dbh->prepare($stmt) || die "prepare: $stmt: $DBI::errstr";
    $sth->execute("bletch varchar") || die "execute: $stmt: $DBI::errstr";
    $sth->finish;

    $dbh->do(qq{INSERT INTO $ODBCTEST::table_name (a, b, c, d) VALUES (1, 'foo', ?, \{d '1998-05-11'\})}, undef, 'foo varchar');
    $dbh->do(qq{INSERT INTO $ODBCTEST::table_name (a, b, c, d) VALUES (2, 'bar', ?, \{d '1998-05-12'\})}, undef, 'bar varchar');
    $stmt = "INSERT INTO $ODBCTEST::table_name (a, b, c, d) VALUES ("
	    . join(", ", 4, $dbh->quote("80char"), "?", "{d '1998-05-13'}"). ")";
    $sth = $dbh->prepare($stmt) || die "prepare: $stmt: $DBI::errstr";
    $sth->execute($longstr) || die "execute: $stmt: $DBI::errstr";
    $stmt = "INSERT INTO $ODBCTEST::table_name (a, b, c, d) VALUES ("
	    . join(", ", 5, $dbh->quote("gt250char"), "?", "{d '1998-05-14'}"). ")";
    $sth = $dbh->prepare($stmt) || die "prepare: $stmt: $DBI::errstr";
    $sth->execute($longstr2) || die "execute: $stmt: $DBI::errstr";
    $sth->finish;
}

sub select_long
{
    my $dbh = shift;
	my @row;
	my $sth;
	my $rc = undef;

	$dbh->{RaiseError} = 1;
	$sth = $dbh->prepare("SELECT A,C FROM $ODBCTEST::table_name WHERE A=4");
	if ($sth) {
		$sth->execute();
		eval {
			while (@row = $sth->fetchrow()) {
		}
		};
		$rc = 1 unless ($@) ;
	}
	$rc;
}
	
__END__




