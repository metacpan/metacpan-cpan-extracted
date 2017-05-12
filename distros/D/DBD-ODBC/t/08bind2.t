#!/usr/bin/perl -w -I./t

use Test::More;
use strict;

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 6;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

# use_ok('DBI', qw(:sql_types));
# can't seem to get the imports right this way
use DBI qw(:sql_types);
use_ok('ODBCTEST');             # 1
use_ok('Data::Dumper');         # 2

my $dbh;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}
END {
    if ($dbh) {
        ODBCTEST::tab_delete($dbh);
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}

ok(ODBCTEST::tab_create($dbh), "Create tables");

SKIP:
{
   #skip "SQLDescribeParam not supported using " . $dbh->get_info(6) . "\n", 3, unless $dbh->func(58, 'GetFunctions');

   $dbh->{RaiseError} = 0;
   $dbh->{PrintError} = 0;
   $dbh->{LongReadLen} = 10000;

   my $longstr = "This is a test of a string that is longer than 80 characters.  It will be checked for truncation and compared with itself.";
   my $longstr2 = $longstr . "  " . $longstr . "  " . $longstr . "  " . $longstr;
   my $longstr3 = $longstr2 . "  " . $longstr2;

   my @data_no_dates = (
			[ 1, 'foo', 'test1', undef, undef ],
			[ 2, 'bar', 'test1', undef, undef ],
			[ 3, 'bletch', 'test1', undef, undef],
		       );

   my @data_no_dates_with_long = (
				  [ 4, 'foo2', $longstr, undef, undef ],
				  [ 5, 'bar2', $longstr2, undef, undef ],
				  [ 6, 'bletch2', $longstr3, undef, undef],
				 );

   my @data_with_dates = (
			  [ 7, 'foo22', 'test3',     "1998-05-13", "1998-05-13 00:01:00"],
			  [ 8, 'bar22', 'test3',    "1998-05-14", "1998-05-14 00:01:00"],
			  [ 9, 'bletch22', 'test3', "1998-05-15", "1998-05-15 00:01:00"],
			  [ 10, 'bletch22', 'test3', "1998-05-15", "1998-05-15 00:01:00.250"],
			  [ 11, 'bletch22', 'test3', "1998-05-15", "1998-05-15 00:01:00.390"],
			  [ 12, 'bletch22', 'test3', undef, undef],
			 );

   my $dbname = $dbh->get_info(17); # DBI::SQL_DBMS_NAME

   # turn off default binding of varchar to test this!
   $dbh->{odbc_default_bind_type} = 0;
   my $rc = ODBCTEST::tab_insert_bind($dbh, \@data_no_dates, 0);
   unless ($rc) {
      diag("These are tests which rely upon the driver to tell what the parameter type is for the column.  This means you need to ensure you tell your driver the type of the column in bind_col().\n");
   }
   ok($rc, "insert #1 various test data no dates, no long data"); # 3

   $dbh->{PrintError} = 0;
   $rc = ODBCTEST::tab_insert_bind($dbh, \@data_no_dates_with_long, 0);
   ok($rc, "insert #2 various test data no dates, with long data"); # 4

   $rc = ODBCTEST::tab_insert_bind($dbh, \@data_with_dates, 0);
   # warn "\nThis test is known to fail using Oracle's ODBC drivers for
   # versions 8.x and 9.0 -- please ignore the failure or, better yet, bug Oracle :)\n\n";
   SKIP:
   {

      skip "Known to fail using Oracle's ODBC drivers 8.x and 9.x", 1 if (!$rc && $dbname =~ /Oracle/i);
      # Driver without SQLDescribeParam rarely support binding
      # dates/times without a type
      skip "SQLDescribeParam not supported using " . $dbh->get_info(17) . "\n", 1, unless $dbh->func(58, 'GetFunctions');
      ok($rc, "insert #3 various test data data with dates"); # 5
   };

   ODBCTEST::tab_delete($dbh);

};

exit(0);
