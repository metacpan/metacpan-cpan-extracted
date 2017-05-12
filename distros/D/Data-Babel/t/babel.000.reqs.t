# check requirements for running tests
# for some reason, test driver does not always ensure these guys exist, even though
# they are in 'build_requires'
#   - Class::AutoDB 
#   - DBD::mysql
# check whether MySQl test database is accessible
use strict;
use Test::More;

# assert TAP version 13 support for pragmas to communicate results to TAP::Harness
# if requirements not met, no further tests will run, but results reported as PASS
print "TAP version 13\n";

# NG 13-07-29: use this code from 002.pod to avoid need to hardcode required versions
use t::Build;
my $builder=t::Build->current;
my $module=$builder->module_name;
my $version=$builder->dist_version;
diag("\nTesting $module $version, Perl $], $^X" );

# my $autobd_version=$builder->build_requires->{'Class::AutoDB'};
# my $dbd_version=$builder->build_requires->{'DBD::mysql'};
my $ok=1;

# CAUTION: may not work to put DBD::mysql in prereqs. 
#  in past, saw bug where if DBD::mysq not present, install tries to install 'DBD'
#  which does not exist
check_module('Class::AutoDB') or $ok=0;
check_module('DBI') or $ok=0;
check_module('DBD::mysql') or $ok=0;

# TODO: database name should be configurable
# CAUTION: $test_db duplicated in t/babelUtil.pm
my $test_db='test';
check_mysql($test_db) or $ok=0;

if ($ok) {
  pass('requirements are met');
} else {
  pass('requirements tested ');
}
done_testing();

sub check_module {
  my($module,$version)=@_;
  defined $version or $version=$builder->build_requires->{$module};
  eval "use $module $version";
  if ($@) {
    my $diag= <<DIAG


These tests require that $module version $version or higher be installed.
For some reason, the test driver does not reliably check this requirement.

When loading this module, the test driver got the following error message:

$@

DIAG
      ;
    report_fail($diag);
    return undef;
  }
  1;
}

# check whether MySQL test database is accessible
# NG 13-10-13: check for MySQL duplicate removal bug
sub check_mysql {
  my($test_db)=@_;
  # make sure we can talk to MySQL
  my($dbh,$errstr);
  eval
    {$dbh=DBI->connect("dbi:mysql:",undef,undef,
		       {AutoCommit=>1, ChopBlanks=>1, PrintError=>0, PrintWarn=>0, Warn=>0,})};
  $errstr=$@, goto FAIL if $@;
  goto FAIL unless $dbh;

  # NG 13-09-15: print MySQL version to help track down subtle FAILs
  my $version=$dbh->selectrow_arrayref(qq(SELECT version())) or fail('get MySQL version');
  if ($version) {
    if (scalar(@$version)==1) {
      diag('MySQL version ',$version->[0]);
    } else {
      fail('get MySQL version returned row with wrong nuber of columns. expected 1, got '.
	   scalar(@$version));
    }
  }
  # try to create database if necessary, then use it
  # don't worry about create-errors: may be able to use even if can't create
  $dbh->do(qq(CREATE DATABASE IF NOT EXISTS $test_db));
  $dbh->do(qq(USE $test_db)) or goto FAIL;

  # make sure we can do all necessary operations
  # create, alter, drop tables. insert, select, replace, update, select, delete
  # NG 10-11-19: ops on views needed for Babel, not AutoDB
  # NG 10-11-19: DROP tables and views if they exist
  $dbh->do(qq(DROP TABLE IF EXISTS test_table)) or goto FAIL;
  $dbh->do(qq(DROP VIEW IF EXISTS test_table)) or goto FAIL;
  $dbh->do(qq(DROP TABLE IF EXISTS test_view)) or goto FAIL;
  $dbh->do(qq(DROP VIEW IF EXISTS test_view)) or goto FAIL;

  $dbh->do(qq(CREATE TABLE test_table(xxx INT))) or goto FAIL;
  $dbh->do(qq(ALTER TABLE test_table ADD COLUMN yyy INT)) or goto FAIL;
  $dbh->do(qq(CREATE VIEW test_view AS SELECT * from test_table)) or goto FAIL;
  # do drop at end, since we need table here
  $dbh->do(qq(INSERT INTO test_table(xxx) VALUES(123))) or goto FAIL;
  $dbh->do(qq(SELECT * FROM test_table)) or goto FAIL;
  $dbh->do(qq(SELECT * FROM test_view)) or goto FAIL;
  $dbh->do(qq(REPLACE INTO test_table(xxx) VALUES(456))) or goto FAIL;
  $dbh->do(qq(UPDATE test_table SET yyy=789 WHERE xxx=123)) or goto FAIL;
  $dbh->do(qq(DELETE FROM test_table WHERE xxx=123)) or goto FAIL;
  $dbh->do(qq(DROP VIEW IF EXISTS test_view)) or goto FAIL;
  $dbh->do(qq(DROP TABLE IF EXISTS test_table)) or goto FAIL;

  # NG 13-10-13: check for MySQL duplicate removal bug
  $dbh->do(qq(CREATE TABLE test_table(A VARCHAR(255),B VARCHAR(255)))) or goto FAIL;
  $dbh->do(qq(INSERT INTO test_table(A,B) VALUES ('a','b1'),('a','b2'))) or goto FAIL;
  my($count)=$dbh->selectrow_array(qq(SELECT COUNT(*) FROM test_table)) or goto FAIL;
  if ($count!=2) {
    $errstr="After inserting 2 rows into test_table,\nSELECT COUNT(*) found $count rows (should be 2)";
    goto FAIL2;
  }
  my $rows=$dbh->selectall_arrayref(qq(SELECT DISTINCT A,B FROM test_table))  or goto FAIL;
  if (@$rows!=2) {
    my $count=@$rows;
    $errstr="After inserting 2 rows into test_table,\nSELECT DISTINCT all columns got $count rows (should be 2)\n";
    $errstr.=diag_rows($rows) if $count>0;
    goto FAIL2;
  } 
  my $rows=$dbh->selectall_arrayref(qq(SELECT DISTINCT A,A,B FROM test_table))  or goto FAIL;
  if (@$rows!=2) {
    my $count=@$rows;
    $errstr="After inserting 2 rows into test_table,\nSELECT DISTINCT with repeated column got $count rows (should be 2)\n";
    $errstr.=diag_rows($rows) if $count>0;
    goto FAIL2;
  } 

  # since we made it here, we can do everything!
  return 1;
 FAIL:
  $errstr or $errstr=DBI->errstr;
  my $diag=<<DIAG


These tests require that MySQL be running on 'localhost', that the user 
running the tests can access MySQL without a password, and with these
credentials, has sufficient privileges to (1) create a 'test' database, 
(2) create, alter, and drop tables in the 'test' database, (3) create and
drop views, and (4) run queries and updates on the database.

When verifying these capabilities, the test driver got the following
error message:

$errstr

DIAG
    ;
  diag($diag);
  print "pragma +stop_testing\n";
  return undef;

 FAIL2:
  $errstr or $errstr=DBI->errstr;
  my $diag=<<DIAG


Some versions of MySQL have a bug in dupiclate removal (SELECT DISTINCT) with
repeated output columns. This bug is present in MySQL 5.0.32, and fixed in or 
before MySQL 5.0.86. 

When checking for this bug, the test driver got the following error message:

$errstr

DIAG
    ;
  diag($diag);
  print "pragma +stop_testing\n";
  return undef;

}

sub report_fail {
  my($diag)=@_;
  diag($diag);
  print "pragma +stop_testing\n";
  undef;
}
sub diag_rows {
  my($rows)=@_;
  my @diag='----------';
  for my $row (@$rows) {
    # replace undef by NULL
    push(@diag,join("\t",map {defined $_? $_: 'NULL'} @$row));
  }
  push(@diag,'----------');
  my $diag=join("\n",@diag);
  $diag;
}
