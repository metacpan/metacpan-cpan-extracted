#!/usr/bin/perl -I./t
$|=1;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
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

use DBI;
use ODBCTEST;

my @row;

Test(1);	# loaded DBI ok.

my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";
my $dbname = $dbh->{odbc_SQL_DBMS_NAME};
Test(1);	 # connected ok

#### testing set/get of connection attributes
$dbh->{RaiseError} = 0;
$dbh->{'AutoCommit'} = 1;
$rc = commitTest($dbh);
print " ", $DBI->errstr, "" if ($rc < 0);
Test($rc == 1); # print "not " unless ($rc == 1);
Test($dbname eq $dbh->{odbc_SQL_DBMS_NAME});

Test($dbh->{AutoCommit});
Test($dbname eq $dbh->{odbc_SQL_DBMS_NAME});

$dbh->{'AutoCommit'} = 0;
$rc = commitTest($dbh);
print $DBI->errstr, "\n" if ($rc < 0);
Test($rc == 0);
Test($dbname eq $dbh->{odbc_SQL_DBMS_NAME});

$dbh->{'AutoCommit'} = 1;

# ------------------------------------------------------------

my $rows = 0;
# TBD: Check for tables function working.  
if ($sth = $dbh->table_info()) {
    while (@row = $sth->fetchrow()) {
        $rows++;
    }
    $sth->finish();
}
Test($rows > 0);
Test($dbname eq $dbh->{odbc_SQL_DBMS_NAME});

$rows = 0;
$dbh->{PrintError} = 0;
my @tables = $dbh->tables;

Test($#tables > 0); # 7
Test($dbname eq $dbh->{odbc_SQL_DBMS_NAME});
$rows = 0;
if ($sth = $dbh->column_info(undef, undef, $ODBCTEST::table_name, undef)) {
    while (@row = $sth->fetchrow()) {
        $rows++;
    }
    $sth->finish();
}
Test($rows > 0);
Test($dbname eq $dbh->{odbc_SQL_DBMS_NAME});

$rows = 0;

if ($sth = $dbh->primary_key_info(undef, undef, $ODBCTEST::table_name, undef)) {
    while (@row = $sth->fetchrow()) {
        $rows++;
    }
    $sth->finish();
}
# my $dbname = $dbh->get_info(17); # DBI::SQL_DBMS_NAME
if ($dbname =~ /Access/i) {
   Test(1, " # Skipped: Known to fail using MS Access through 2000");
} else {
   Test($rows > 0);
}
Test($dbname eq $dbh->{odbc_SQL_DBMS_NAME});

BEGIN { $tests = 16; }
$dbh->disconnect;
# print STDERR $dbh->{odbc_SQL_DRIVER_ODBC_VER}, "\n";

# ------------------------------------------------------------
# returns true when a row remains inserted after a rollback.
# this means that autocommit is ON. 
# ------------------------------------------------------------
sub commitTest {
    my $dbh = shift;
    my @row;
    my $rc = -1;
    my $sth;

    $dbh->do("DELETE FROM $ODBCTEST::table_name WHERE COL_A = 100") or return undef;

    { # suppress the "commit ineffective" warning
      local($SIG{__WARN__}) = sub { };
      $dbh->commit();
    }

    @row = ODBCTEST::get_type_for_column($dbh, 'COL_D');
    my $dateval;
    if (ODBCTEST::isDateType($row[1])) {
       $dateval = "{d '1997-01-01'}";
    } else {
       $dateval = "{ts '1997-01-01 00:00:00'}";
    }
    $dbh->do("insert into $ODBCTEST::table_name values(100, 'x', 'y', $dateval)");
    { # suppress the "rollback ineffective" warning
	  local($SIG{__WARN__}) = sub { };
      $dbh->rollback();
    }
    $sth = $dbh->prepare("SELECT COL_A FROM $ODBCTEST::table_name WHERE COL_A = 100");
    $sth->execute();
    if (@row = $sth->fetchrow()) {
        $rc = 1;
    }
    else {
	$rc = 0;
    }
    # in case not all rows have been returned..there shouldn't be more than one.
    $sth->finish(); 
    $rc;
}

# ------------------------------------------------------------

