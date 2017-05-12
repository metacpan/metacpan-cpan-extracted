#!/usr/bin/perl -I./t
$| = 1;

use DBI qw(:sql_types);
use ODBCTEST;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 21;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

{
   my $numTest = 0;
   sub Test($;$) {
      my $result = shift; my $str = shift || '';
	printf("%sok %d%s\n", ($result ? "" : "not "), ++$numTest, $str);
	$result;
    }
}

print "1..$tests\n";

Test(1);

print " Test 2: connecting to the database\n";
#DBI->trace(2);
my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";
$dbh->{AutoCommit} = 1;

Test(1);


#### testing a simple select

print " Test 3: create test table\n";
my $rc = 0;
$rc = ODBCTEST::tab_create($dbh);
Test($rc);

print " Test 4: check existance of test table\n";
$rc = ODBCTEST::tab_exists($dbh);
Test($rc >= 0);

print " Test 5: insert test data\n";
$rc = ODBCTEST::tab_insert($dbh);
Test($rc);

print " Test 6: select test data\n";
$rc = tab_select($dbh);
Test($rc);

print " Tests 7,8: test LongTruncOk\n";
$rc = undef;
$dbh->{LongReadLen} = 50;
$dbh->{LongTruncOk} = 1;
$dbh->{PrintError} = 0;
$rc = select_long($dbh);
Test($rc);

# now force an error and ensure we get a long truncated event.
$dbh->{LongTruncOk} = 0;
$rc = select_long($dbh);
Test(!$rc);

print " Test 9: test ColAttributes\n";
my $sth = $dbh->prepare("SELECT * FROM $ODBCTEST::table_name ORDER BY COL_A");

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
		print "$i: $colname = $coltype ", $coltype+1-1;
 		++$is_ok if grep { $coltype == $_ } @{$ODBCTEST::TestFieldInfo{$colname}};
		print " yes\n" if grep { $coltype == $_ } @{$ODBCTEST::TestFieldInfo{$colname}};
	}
	print "\n";
	Test($is_ok == $colcount);
	# print "not " unless $is_ok == $colcount;
	# print "ok 9\n";
	
	$sth->finish;
}
else {
   Test(0);
}

print " Test 10: test \$DBI::err\n";
$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
#
# some ODBC drivers will prepare this OK, but not execute.
# 
$sth = $dbh->prepare("SELECT XXNOTCOLUMN FROM $ODBCTEST::table_name");
$sth->execute() if $sth;
Test(length($DBI::err) > 0);

print " Test 11: test date or timestamp values\n";
my @row = ODBCTEST::get_type_for_column($dbh, 'COL_D');

my $dateval;
if (ODBCTEST::isDateType($row[1])) {
   $dateval = "{d '1998-05-13'}";
} else {
   $dateval = "{ts '1998-05-13 12:13:01'}";
}

$sth = $dbh->prepare("SELECT COL_D FROM $ODBCTEST::table_name WHERE COL_D > $dateval");
$sth->execute();
my $count = 0;
while (@row = $sth->fetchrow) {
	$count++ if ($row[0]);
	print "$row[0]\n";
}
Test($count == 1);

print " Test 12: test group by queries\n";
$sth = $dbh->prepare("SELECT COL_A, COUNT(*) FROM $ODBCTEST::table_name GROUP BY COL_A");
$sth->execute();
$count = 0;
while (@row = $sth->fetchrow) {
	$count++ if ($row[0]);
	print "$row[0], $row[1]\n";
}
Test($count != 0);

$rc = ODBCTEST::tab_delete($dbh);

# Note, this test will fail if no data sources defined or if
# data_sources is unsupported.
print " Test 13: test data_sources\n";
my @data_sources = DBI->data_sources('Mimer');
print "Data sources:\n\t", join("\n\t",@data_sources),"\n\n";
Test($#data_sources >= 0);

print " Test 14: test ping method\n";
Test($dbh->ping);

print " Test 15: test storing of DBH parameter\n";
if ($dbh->{odbc_ignore_named_placeholders}) {
   print "Attrib not 0 to start (", $dbh->{odbc_ignore_named_placeholders}, ")\n ";
   Test(0);
} else {
   $dbh->{odbc_ignore_named_placeholders} = 1;
   Test($dbh->{odbc_ignore_named_placeholders} == 1);
   print "Attrib not true (", $dbh->{odbc_ignore_named_placeholders}, ")\n";
}

print " Test 16: test connecting twice to the same db.\n";
my $dbh2 = DBI->connect();

Test(defined($dbh2));# 16
$dbh2->disconnect;


print " Test 17: test get_info\n";
my $dbname;
$dbname = $dbh->get_info(17); # SQL_DBMS_NAME
print " connected to $dbname\n";
Test(defined($dbname) && $dbname ne '');
#print "\nnot " unless (defined($dbname) && $dbname ne '');
#print "ok 17\n";

print " Test 18: test automatically finish when execute run again\n";
$sth = $dbh->prepare("select count(*) from $ODBCTEST::table_name");
$sth->execute;
$sth->fetch;
Test($sth->execute);

my $connstr = $ENV{DBI_DSN};
if (!($connstr =~ /DSN=/i || $connstr =~ /DRIVER=/i)) {
   $connstr =~ s/Mimer:/Mimer:DSN=/;

   print " Test 19: test connection success when DBI DSN is invalid\n";
   my $dbh3 = DBI->connect($ENV{DBI_DSN} . "x", $ENV{DBI_USER}, $ENV{DBI_PASS}, {RaiseError=>0, PrintError=>0});
   print "Test Ok if Errstr not undef: " . $DBI::errstr . "\n";
   Test(defined($DBI::errstr));
   $dbh3->disconnect if (defined($dbh3));
   
   print " Test 20: test connection success when DBI DSN has DSN=\n";
   $dbh3 = DBI->connect($connstr, $ENV{DBI_USER}, $ENV{DBI_PASS}, {RaiseError=>0, PrintError=>0});
   Test(defined($dbh3));
   $dbh3->disconnect if (defined($dbh3));

   print " Test 21: test connection success when DBI DSN has DSN= and uid and pwd are set\n";
   $dbh3 = DBI->connect($connstr . ";UID=$ENV{DBI_USER};PWD=$ENV{DBI_PASS}",undef,undef, {RaiseError=>0, PrintError=>0});
   Test(defined($dbh3));

   $dbh3->disconnect if (defined($dbh3));

} else {
   Test(1, " # Skipped: DSN already set with DSN= or DRIVER=");
   Test(1, " # Skipped: DSN already set with DSN= or DRIVER=");
   Test(1, " # Skipped: DSN already set with DSN= or DRIVER=");
}
	    
# Test(1);
# clean up
$sth->finish;
exit(0);

sub tab_select
{
    my $dbh = shift;
    my @row;
    my $rowcount = 0;

    $dbh->{LongReadLen} = 1000;

    my $sth = $dbh->prepare("SELECT * FROM $ODBCTEST::table_name ORDER BY COL_A")
		or return undef;
    $sth->execute();
    while (@row = $sth->fetchrow())	{
	print "$row[0]|$row[1]|$row[2]|\n";
	++$rowcount;
	if ($rowcount != $row[0]) {
	    print "Basic retrieval of rows not working!\nRowcount = $rowcount, while retrieved value = $row[0]\n";
	    $sth->finish;
	    return 0;
	}
    }
    $sth->finish();
    
    $sth = $dbh->prepare("SELECT COL_A,COL_C FROM $ODBCTEST::table_name WHERE COL_A>=4")
	   or return undef;
    $sth->execute();
    while (@row = $sth->fetchrow()) {
	if ($row[0] == 4) {
	    if ($row[1] eq $ODBCTEST::longstr) {
		print "retrieved ", length($ODBCTEST::longstr), " byte string OK\n";
	    } else {
		print "Basic retrieval of longer rows not working!\nRetrieved value = $row[0]\n";
		return 0;
	    }
	} elsif ($row[0] == 5) {
	    if ($row[1] eq $ODBCTEST::longstr2) {
		print "retrieved ", length($ODBCTEST::longstr2), " byte string OK\n";
	    } else {
		print "Basic retrieval of row longer than 255 chars not working!",
						"\nRetrieved ", length($row[1]), " bytes instead of ", 
						length($ODBCTEST::longstr2), "\nRetrieved value = $row[1]\n";
		return 0;
	    }
	}
    }

    return 1;
}


sub select_long
{
	my $dbh = shift;
	my @row;
	my $sth;
	my $rc = undef;
	
	$dbh->{RaiseError} = 1;
	$sth = $dbh->prepare("SELECT COL_A,COL_C FROM $ODBCTEST::table_name WHERE COL_A=4");
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




