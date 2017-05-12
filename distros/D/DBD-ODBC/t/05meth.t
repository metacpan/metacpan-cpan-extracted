#!/usr/bin/perl -I./t

## TBd: these tests don't seem to be terribly useful
#use sigtrap;
use Test::More;
use strict;

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 15;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

use_ok('DBI', qw(:sql_types));
use_ok('ODBCTEST');
use strict;

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


my @row;

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}


#### testing Tim's early draft DBI methods

ok(ODBCTEST::tab_create($dbh), "Create tables");

my $r1 = $DBI::rows;
$dbh->{AutoCommit} = 0;
my $sth;
$sth = $dbh->prepare("DELETE FROM $ODBCTEST::table_name");
ok($sth, "delete prepared statement");
$sth->execute();
cmp_ok($sth->rows, '>=', 0, "Number of rows >= 0");
cmp_ok($DBI::rows, '==', $sth->rows, "Number of rows from DBI matches sth");
$sth->finish();
$dbh->rollback();
pass("finished and rolled back");

$sth = $dbh->prepare("SELECT * FROM $ODBCTEST::table_name WHERE 1 = 0");
$sth->execute();
@row = $sth->fetchrow();
if ($sth->err) {
   diag(" $sth->err: " . $sth->err . "\n");
   diag(" $sth->errstr: " . $sth->errstr . "\n");
   diag(" $dbh->state: " . $dbh->state . "\n");
}
ok(!$sth->err, "no error");
$sth->finish();

my ($a, $b);
$sth = $dbh->prepare("SELECT COL_A, COL_B FROM $ODBCTEST::table_name");
$sth->execute();
while (@row = $sth->fetchrow()) {
    print " \@row     a,b:", $row[0], ",", $row[1], "\n";
}
$sth->finish();

$sth->execute();
$sth->bind_col(1, \$a);
$sth->bind_col(2, \$b);
while ($sth->fetch()) {
    print " bind_col a,b:", $a, ",", $b, "\n";
    unless (defined($a) && defined($b)) {
        print "not ";
        last;
	}
}
pass("?");
$sth->finish();

($a, $b) = (undef, undef);
$sth->execute();
$sth->bind_columns(undef, \$b, \$a);
while ($sth->fetch()) {
    print " bind_columns a,b:", $b, ",", $a, "\n";
    unless (defined($a) && defined($b)) {
        print "not ";
        last;
	}
}
pass("??");

$sth->finish();

# turn off error warnings.  We expect one here (invalid transaction state)
$dbh->{RaiseError} = 0;
$dbh->{PrintWarn} = 0;
$dbh->{PrintError} = 0;

ok( $dbh->{$_}, $_) for 'Active';
ok( $dbh-> $_ , $_) for 'ping';
ok( $dbh-> $_ , $_) for 'disconnect';
ok(!$dbh->{$_}, $_) for 'Active';
ok(!$dbh-> $_ , $_) for 'ping';;

# $dbh->disconnect(); # already disconnected
exit 0;

# avoid warning on one use of DBI::errstr
print $DBI::errstr;

# make sure there is an invalid transaction state error at the end here.
# (XXX not reliable, iodbc-2.12 with "INTERSOLV dBase IV ODBC Driver" == -1)
#print "# DBI::err=$DBI::err\nnot " if $DBI::err ne "25000";
#print "ok 7\n";

