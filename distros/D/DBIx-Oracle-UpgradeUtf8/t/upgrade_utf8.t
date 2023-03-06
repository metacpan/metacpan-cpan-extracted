use utf8;
use strict;
use warnings;
use Test::More;
use DBI;
use DBIx::Oracle::UpgradeUtf8;
use Getopt::Long;

use_ok 'DBIx::Oracle::UpgradeUtf8'
  or BAIL_OUT;

diag( "Testing DBIx::Oracle::UpgradeUtf8 $DBIx::Oracle::UpgradeUtf8::VERSION, Perl $], $^X" );

# command-line options for connecting to the Oracle database
GetOptions \my %opt,
  'oradb=s',
  'user=s',
  'passwd=s',
  'TABLE=s',
  'KEY_COL=s',
  'VAL_COL=s',
  'KEY_NATIVE=s',
  'KEY_UTF8=s',
  ;

#default values
$opt{KEY_NATIVE} //= 'TST_UPG_NATIVE';
$opt{KEY_UTF8}   //= 'TST_UPG_UTF8';

# string data to be used in tests
my $str        = "il était une bergère";
my $str_native = $str; utf8::downgrade($str_native);
my $str_utf8   = $str; utf8::upgrade($str_utf8);

# run tests
if (!$opt{oradb}) {
  note "no Oracle database connection, skipping all tests";
  note "to run the tests, pass options -oradb, -user, -passwd on the command line";
}
else {
  # connect to the database
  my $dbh = DBI->connect("dbi:Oracle:$opt{oradb}", $opt{user}, $opt{passwd},
                         {RaiseError => 1, PrintError => 1, AutoCommit => 1})
    or die $DBI::errstr;

  # prove that tests indeed do fail without the callbacks
  run_tests_in_context($dbh, without_callbacks => 'NE');

  # inject callbacks and test again, this time getting 'EQ' results
  my $injector = DBIx::Oracle::UpgradeUtf8->new(debug => sub {warn @_, "\n"});
  $injector->inject_callbacks($dbh);
  run_tests_in_context($dbh, with_callbacks => 'EQ');
}

# the end
done_testing;

#======================================================================
# SUBROUTINES
#======================================================================


sub run_tests_in_context {
  my ($dbh, $context, $expected) = @_;

  my ($sth, $result);

  my $sql = "SELECT CASE WHEN ?=? THEN 'EQ' ELSE 'NE' END CMP_RESULT FROM DUAL";

  # testing dbh methods -- direct select from dbh
  ($result) = $dbh->selectrow_array($sql, {}, str_cpies($str_native, $str_utf8));
  is $result, $expected,                          "[$context: $expected] (selectrow_array)";

  $result = $dbh->selectrow_arrayref($sql, {}, str_cpies($str_native, $str_utf8));
  is $result->[0], $expected,                     "[$context: $expected] (selectrow_arrayref)";

  $result = $dbh->selectrow_hashref($sql, {}, str_cpies($str_native, $str_utf8));
  is $result->{CMP_RESULT}, $expected,            "[$context: $expected] (selectrow_hashref)";

  $result = $dbh->selectall_arrayref($sql, {}, str_cpies($str_native, $str_utf8));
  is $result->[0][0], $expected,                  "[$context: $expected] (selectall_arrayref)";

  ($result) = $dbh->selectall_array($sql, {}, str_cpies($str_native, $str_utf8));
  is $result->[0], $expected,                     "[$context: $expected] (selectall_array)";

  $result = $dbh->selectall_hashref($sql, 'CMP_RESULT', {}, str_cpies($str_native, $str_utf8));
  is $result->{$expected}{CMP_RESULT}, $expected, "[$context: $expected] (selectall_hashref)";


  # testing sth methods --- prepare / execute or prepare / bind_param / execute
  $sth = $dbh->prepare($sql);
  $sth->execute(str_cpies($str_native, $str_utf8));
  ($result) = $sth->fetchrow_array;
  is $result, $expected, "[$context: $expected] (prepare / execute)";

  $sth = $dbh->prepare($sql);
  $sth->bind_param(1, str_cpies($str_native));
  $sth->bind_param(2, str_cpies($str_utf8));
  $sth->execute;
  ($result) = $sth->fetchrow_array;
  is $result, $expected, "[$context: $expected] (prepare / bind_param / execute)";

  # testing interpolated strings without bind values -- native and utf8
  my $sql1 = "SELECT CASE WHEN 'il était une bergère'=? THEN 'EQ' ELSE 'NE' END FROM DUAL";
  utf8::downgrade($sql1);
  ($result) = $dbh->selectrow_array($sql1, {}, str_cpies($str_utf8));
  is $result, $expected, "[$context: $expected] (interpolated native string)";

  my $sql2 = $sql1;
  utf8::upgrade($sql2);
  ($result) = $dbh->selectrow_array($sql2, {}, str_cpies($str_native));
  is $result, $expected, "[$context: $expected] (interpolated utf8 string)";

  # if there is a table we can write into, test the 'do' method and a roundtrip to the database
  if (!$opt{TABLE}) {
    note "skipping INSERT tests";
    note "to run those tests, you need to supply options -TABLE, -KEY_COL, -VAL_COL on the command-line";
  }
  else {

    my $sql_delete = "DELETE FROM $opt{TABLE} WHERE $opt{KEY_COL} IN (?, ?)";
    my $sql_insert = "INSERT INTO $opt{TABLE}($opt{KEY_COL}, $opt{VAL_COL}) VALUES(?, ?)";
    my $sql_select = "SELECT $opt{VAL_COL} FROM $opt{TABLE} WHERE $opt{KEY_COL} = ?";

    # delete data from previous tests, insert and select back
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/})        or die $dbh->errstr;
    $dbh->do($sql_insert, {}, $opt{KEY_NATIVE}, str_cpies($str_native)) or die $dbh->errstr;
    ($result) = $dbh->selectrow_array($sql_select, {}, str_cpies($opt{KEY_NATIVE}));
    my $cmp_strings = $result eq $str_native ? 'EQ' : 'NE';
    is $cmp_strings, $expected,                   "[$context: $expected] (after do / INSERT / SELECT)";

    # same thing, but with bind_param_array()
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/})        or die $dbh->errstr;
    $sth = $dbh->prepare($sql_insert);
    $sth->bind_param_array(1, [@opt{qw/KEY_NATIVE KEY_UTF8/}]);
    $sth->bind_param_array(2, [str_cpies($str_native, $str_utf8)]);
    $sth->execute_array({});
    ($result) = $dbh->selectrow_array($sql_select, {}, str_cpies($opt{KEY_NATIVE}));
    $cmp_strings = $result eq $str_native ? 'EQ' : 'NE';
    is $cmp_strings, $expected,                   "[$context: $expected] (after do / INSERT / bind_param_array / SELECT)";

    # same thing, but with bind values passed directl to execute_array()
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/})        or die $dbh->errstr;
    $sth = $dbh->prepare($sql_insert);
    $sth->execute_array({}, [@opt{qw/KEY_NATIVE KEY_UTF8/}], [str_cpies($str_native, $str_utf8)]);
    ($result) = $dbh->selectrow_array($sql_select, {}, str_cpies($opt{KEY_NATIVE}));
    $cmp_strings = $result eq $str_native ? 'EQ' : 'NE';
    is $cmp_strings, $expected,                   "[$context: $expected] (after do / INSERT / execute_array / SELECT)";

    # cleanup
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/})        or die $dbh->errstr;
  }

}


sub str_cpies { # make fresh copies of strings for each test. Otherwise utf8::upgrade overrides the string
  my @c = @_;
  return @c;
}
