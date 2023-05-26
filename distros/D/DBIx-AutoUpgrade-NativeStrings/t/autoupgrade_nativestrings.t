use utf8;
use strict;
use warnings;
use Test::More;
use DBI;
use Getopt::Long;
use Encode qw/encode decode FB_CROAK LEAVE_SRC/;
use DBD::SQLite 1.68;                                 # minimal version for 'sqlite_string_mode' attr
use DBD::SQLite::Constants ':dbd_sqlite_string_mode';

# NOTE : this test program takes command-line options so that it can be tried on various databases.
# See %valid_options below -- you should at least supply -data_source, -user and -passwd.
# If no data source is explicitly given, a SQLite database is used as default.


# drivers known to properly upgrade latin1 native strings
my %driver_autoupgrades_latin1 = map {($_ => 1)} qw/SQLite Pg/;

# strings to be used in tests
my %tst_encodings = (
  default      => "cette hétaïre me plaît",
  'iso-8859-1' => "cette hétaïre me plaît",
  cp1252       => "il était une bergère, elle vendait ses œufs en ¥, ça paie 5¾ ‰ de mieux qu’en €",
 );

# parse command-line options and supply default values
my %valid_options = (
# name             Getopt format    default
# ====             =============    =======
  data_source  => ['s'            ,                   ],
  user         => ['s'            , ''                ],
  passwd       => ['s'            , ''                ],
  connect_attr => ['s%{,}'        , {RaiseError => 1} ],  # usage: -connect_attr key1=val1 key2=val2 ...
  TABLE        => ['s'            , 'TST'             ],  # name of a table where we can insert rows ..
  KEY_COL      => ['s'            , 'KEY'             ],  # .. with keys of that name
  VAL_COL      => ['s'            , 'VAL'             ],  # .. and with values of that name
  KEY_NATIVE   => ['s'            , 'TST_NATIVE'      ],  # key value for inserting a native string
  KEY_UTF8     => ['s'            , 'TST_UTF8'        ],  # key value for inserting a utf8 string
  sqlite_file  => ['s'            , 'foo.sqlite'      ],  
 );
GetOptions \my %opt, map {"$_=$valid_options{$_}[0]"} keys %valid_options;
$opt{$_} //= $valid_options{$_}[1] for keys %valid_options;

# create default sqlite database
if (!$opt{data_source}) {
  $opt{data_source}  = "dbi:SQLite:dbname=$opt{sqlite_file}";

  # create fresh database file with one table & two cols
  unlink $opt{sqlite_file};
  my $dbh = DBI->connect(@opt{qw/data_source user passwd connect_attr/});
  $dbh->do("CREATE TABLE $opt{TABLE}($opt{KEY_COL}, $opt{VAL_COL})");
  $dbh->disconnect;

  $opt{connect_attr}{sqlite_string_mode} = DBD_SQLITE_STRING_MODE_UNICODE_STRICT;
}


# do the tests
use_ok 'DBIx::AutoUpgrade::NativeStrings'
  or BAIL_OUT;
diag( "Testing DBIx::AutoUpgrade::NativeStrings $DBIx::AutoUpgrade::NativeStrings::VERSION, Perl $], $^X" );
while (my ($encoding, $str) = each %tst_encodings) {
  test_encoding($encoding, $str);
}
done_testing;


#======================================================================
# SUBROUTINES
#======================================================================

sub test_encoding {
  my ($encoding, $str) = @_;

  my ($downgrade, $upgrade)
    = $encoding eq 'default' ? (sub {my $str = shift; utf8::downgrade($str); $str},
                                sub {my $str = shift; utf8::upgrade($str)  ; $str})
                             : (sub {my $str = shift; encode($encoding, $str)},
                                sub {my $str = shift; decode($encoding, $str)});

  # connect to the database
  my $dbh = DBI->connect(@opt{qw/data_source user passwd connect_attr/}) or die $DBI::errstr;
  note "testing $encoding encoding on DBD driver $dbh->{Driver}{Name}";

  # first check how tests behave without the callbacks. This proves that semantically equivalent strings
  # are considered not equal by some drivers, and CP1252 strings are never considered equal to their UTF8
  # equivalent, because they need an explicit decode()
  my $expected_without_callbacks 
    = $encoding eq 'cp1252' || !$driver_autoupgrades_latin1{$dbh->{Driver}{Name}} ? 'NE' : 'EQ';
  run_tests($dbh, $encoding, without_callbacks => $expected_without_callbacks, $str, $downgrade, $upgrade);

  # now inject callbacks and test again, this time expecting 'EQ' results
  my $injector = DBIx::AutoUpgrade::NativeStrings->new(native => $encoding);
  $injector->inject_callbacks($dbh);
  run_tests($dbh, $encoding, with_callbacks => 'EQ',    $str, $downgrade, $upgrade);
}



sub run_tests {
  my ($dbh, $encoding, $have_callbacks, $expected, $str, $downgrade, $upgrade) = @_;

  my $context    = "$encoding, $have_callbacks: expecting $expected";
  my $str_native = $downgrade->($str);
  my $str_utf8   = $upgrade->($str_native);
  my ($sth, $result);
  my $maybe_from_dual = sub {my $sql = shift; $sql .= " FROM DUAL" if $dbh->{Driver}{Name} eq 'Oracle'; $sql};
  my $sql             = $maybe_from_dual->("SELECT CASE WHEN ?=? THEN 'EQ' ELSE 'NE' END CMP_RESULT");

  # testing dbh methods -- direct select from dbh
  ($result) = $dbh->selectrow_array(clonestr($sql), {}, clonestr($str_native, $str_utf8));
  is $result, $expected,                          "[$context] (selectrow_array)";

  $result = $dbh->selectrow_arrayref(clonestr($sql), {}, clonestr($str_native, $str_utf8));
  is $result->[0], $expected,                     "[$context] (selectrow_arrayref)";

  $result = $dbh->selectrow_hashref(clonestr($sql), {}, clonestr($str_native, $str_utf8));
  is $result->{CMP_RESULT}, $expected,            "[$context] (selectrow_hashref)";

  $result = $dbh->selectall_arrayref(clonestr($sql), {}, clonestr($str_native, $str_utf8));
  is $result->[0][0], $expected,                  "[$context] (selectall_arrayref)";

  ($result) = $dbh->selectall_array(clonestr($sql), {}, clonestr($str_native, $str_utf8));
  is $result->[0], $expected,                     "[$context] (selectall_array)";

  $result = $dbh->selectall_hashref(clonestr($sql), 'CMP_RESULT', {}, clonestr($str_native, $str_utf8));
  is $result->{$expected}{CMP_RESULT}, $expected, "[$context] (selectall_hashref)";


  # testing sth methods --- prepare / execute or prepare / bind_param / execute
  $sth = $dbh->prepare(clonestr($sql));
  $sth->execute(clonestr($str_native, $str_utf8));
  ($result) = $sth->fetchrow_array;
  is $result, $expected,                          "[$context] (prepare / execute)";

  $sth = $dbh->prepare(clonestr($sql));
  $sth->bind_param(1, clonestr($str_native));
  $sth->bind_param(2, clonestr($str_utf8));
  $sth->execute;
  ($result) = $sth->fetchrow_array;
  is $result, $expected,                          "[$context] (prepare / bind_param / execute)";

  # testing interpolated strings without bind values -- native and utf8.
  # Note: eval is needed because the result of interpolation without the callbacks may yield invalid SQL
  my $sql1 = $downgrade->($maybe_from_dual->("SELECT CASE WHEN '$str'=? THEN 'EQ' ELSE 'NE' END"));
  ($result) = eval {$dbh->selectrow_array(clonestr($sql1), {}, clonestr($str_utf8))};
  is $result, $expected,                          "[$context] (interpolated native string)" if $result;

  my $sql2 = $upgrade->($sql1);
  ($result) = eval {$dbh->selectrow_array(clonestr($sql2), {}, clonestr($str_native))};
  is $result, $expected,                          "[$context] (interpolated utf8 string)" if $result;

  # if there is a table we can write into, test the 'do' method and a roundtrip to the database
  if (!($opt{TABLE} && $opt{KEY_COL} && $opt{VAL_COL})) {
    note "skipping INSERT tests";
    note "to run those tests, you need to supply options -TABLE, -KEY_COL, -VAL_COL on the command-line";
  }
  else {
    my $sql_delete = "DELETE FROM $opt{TABLE} WHERE $opt{KEY_COL} IN (?, ?)";
    my $sql_insert = "INSERT INTO $opt{TABLE}($opt{KEY_COL}, $opt{VAL_COL}) VALUES(?, ?)";
    my $sql_select = "SELECT $opt{VAL_COL} FROM $opt{TABLE} WHERE $opt{KEY_COL} = ?";

    # delete data from previous tests, insert and select back
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/});
    $dbh->do($sql_insert, {}, $opt{KEY_NATIVE}, clonestr($str_native));
    ($result) = $dbh->selectrow_array(clonestr($sql_select), {}, $opt{KEY_NATIVE});
    my $cmp_strings = $result eq $str_utf8 ? 'EQ' : 'NE';
    is $cmp_strings, $expected,                   "[$context] (after do / INSERT / SELECT)";

    # same thing, but with bind_param_array()
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/});
    $sth = $dbh->prepare($sql_insert);
    $sth->bind_param_array(1, [@opt{qw/KEY_NATIVE KEY_UTF8/}]);
    $sth->bind_param_array(2, [clonestr($str_native, $str_utf8)]);
    $sth->execute_array({});
    ($result) = $dbh->selectrow_array(clonestr($sql_select), {}, $opt{KEY_NATIVE});
    $cmp_strings = $result eq $str_utf8 ? 'EQ' : 'NE';
    is $cmp_strings, $expected,                   "[$context] (after do / INSERT / bind_param_array / SELECT)";

    # same thing, but with bind values passed directl to execute_array()
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/});
    $sth = $dbh->prepare($sql_insert);
    $sth->execute_array({}, [@opt{qw/KEY_NATIVE KEY_UTF8/}], [clonestr($str_native, $str_utf8)]);
    ($result) = $dbh->selectrow_array($sql_select, {}, $opt{KEY_NATIVE});
    $cmp_strings = $result eq $str_utf8 ? 'EQ' : 'NE';
    is $cmp_strings, $expected,                   "[$context] (after do / INSERT / execute_array / SELECT)";

    # cleanup
    $dbh->do($sql_delete, {}, @opt{qw/KEY_NATIVE KEY_UTF8/});
  }
}


sub clonestr { # make fresh copies of strings for each test. Otherwise strings would be overridden by the 1st test
  my @c = @_;
  return @c;
}


# MISSING TESTS
# - debug method
# - ternary form of bind_param()
