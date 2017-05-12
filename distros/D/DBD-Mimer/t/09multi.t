#!/usr/bin/perl -I./t -w
$| = 1;

use strict;
use DBI;
use ODBCTEST;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}
# $ENV{'ODBCINI'}="/export/cmn/etc/odbc.ini" ;
#my($connectString) = "dbi:Mimer:DSN=TESTDB;Database=xxxxx;uid=usrxxxxx;pwd=xxxxx" ;

{
    my $numTest = 0;
    sub Test($;$) {
	my $result = shift; my $str = shift || '';
	printf("%sok %d%s\n", ($result ? "" : "not "), ++$numTest, $str);
	$result;
    }
}

my $dbh=DBI->connect()
       || die "Can't connect to your $ENV{DBI_DSN} using user: $ENV{DBI_USER} and pass: $ENV{DBI_PASS}\n$DBI::errstr\n";
$dbh->{RaiseError} = 1;
$dbh->{PrintError} = 0;
$dbh->{LongReadLen} = 10000;

my($sqlStr) ;
my @test_colnames = sort(keys(%ODBCTEST::TestFieldInfo));
$sqlStr = "select $test_colnames[0] FROM $ODBCTEST::table_name;
           select $test_colnames[0] from $ODBCTEST::table_name" ;
#$sqlStr = "select emp_id from employee where emp_id = 2
#           select emp_id, emp_name, address1, address2 from employee where emp_id = 2" ;

my $result_sets = 0;
$| = 1;

my $sth;
eval {
   $sth = $dbh->prepare($sqlStr);
   $sth->execute;
};

if ($@) {
   # skipping test on this platform.
   print "1..0 # Skipped multiple statements not supported using ", $dbh->get_info(17), "\n";
   print $@;
   exit 0;
}


print "1..4\n";

# Test 1, simple empty data (should be simple), same # of columns in the two
# result sets.
my @row;
my $cnt = 0;
$result_sets = 0;

do {
   # print join(":", @{$sth->{NAME}}), "\n";
   while ( my $ref = $sth->fetch ) {
      # print join(":", @$ref), "\n";
   }
   $result_sets++;
} while ( $sth->{odbc_more_results}  ) ;

Test($result_sets == 2);

my $sql;
my @expected_result_cols;

# lets get some dummy data for testing.
ODBCTEST::tab_insert($dbh);

$sql = "select $test_colnames[0] from $ODBCTEST::table_name order by $test_colnames[0];
        select $test_colnames[0],$test_colnames[1]  from $ODBCTEST::table_name order by $test_colnames[0]";
@expected_result_cols = (1, 2);
Test(RunMultiTest($sql, \@expected_result_cols));


$sql = "select $test_colnames[0],$test_colnames[1]  from $ODBCTEST::table_name order by $test_colnames[0];
        select $test_colnames[0] from $ODBCTEST::table_name order by $test_colnames[0]";

@expected_result_cols = (2, 1);
Test(RunMultiTest($sql, \@expected_result_cols));

$sql = "select " . join(", ", grep {/COL_[ABC]/} @test_colnames) . " from $ODBCTEST::table_name order by $test_colnames[0];
        select $test_colnames[0] from $ODBCTEST::table_name order by $test_colnames[0]";

@expected_result_cols = ($#test_colnames, 1);
Test(RunMultiTest($sql, \@expected_result_cols));




# clean up the dummy data.
ODBCTEST::tab_delete($dbh);
$dbh->disconnect();


sub RunMultiTest {
   my $sql = shift;
   my $ref_expected_result_cols = shift;

   my @expected_result_cols = @$ref_expected_result_cols;
   my $test_pass = 1;
   my $result_sets = 0;
   $sth = $dbh->prepare($sql);
   $sth->execute;

   do {

      # $#expected_result_cols is the array of number of result cols
      # and the count/array size represents the number of result sets...
      if ($result_sets > $#expected_result_cols) {
	 print "Number of result sets not correct in test $result_sets is more than the expected $#expected_result_cols.\n";
	 $test_pass = 0;
      } else {
	 if ($sth->{NUM_OF_FIELDS} != $expected_result_cols[$result_sets]) {
	    print "Num of fields not correct in result set $result_sets.  Expected $expected_result_cols[$result_sets], found $sth->{NUM_OF_FIELDS}\n";
	    $test_pass = 0;
	 }
      }
      # print join(", ", @{$sth->{NAME}}), "\n";
      my $i = 0;
      while ( my $ref = $sth->fetchrow_arrayref ) {
	 # if ($] > 5.005) {
	 #   no warnings;
	    # print join(":", @$ref), "\n";
         #}
	 my $row = $ODBCTEST::tab_insert_values[$i];
	 
	 my $j;
	 for ($j = 0; $j < $sth->{NUM_OF_FIELDS}; $j++) {
	    if ($row->[$j] ne $ref->[$j]) {
	       print "Data mismatch, result set $result_sets, row $i, col $j ($row->[$j] != $ref->[$j])\n";
	       $test_pass = 0;
	    }
	 }

	 $i++;
      }
      $result_sets++;
   } while ( $sth->{odbc_more_results}  ) ;

   if ($result_sets <= $#expected_result_cols) {
      print "Number of result sets not correct in test (fewer than expected)\n";
      $test_pass = 0;
   }
   $test_pass;
}
