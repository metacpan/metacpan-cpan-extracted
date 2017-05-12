#!perl -w -I./t

use Test::More;
use strict;
use Data::Dumper;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 26 + 4;

$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

$|=1;

use_ok('DBI', qw(:sql_types));
use_ok('ODBCTEST');

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

$dbh->{LongReadLen} = 1000;
is($dbh->{LongReadLen}, 1000, "Set Long Read Len");
my $dbname = $dbh->{odbc_SQL_DBMS_NAME};

ok(ODBCTEST::tab_create($dbh), "Create tables");

#### testing set/get of connection attributes
$dbh->{RaiseError} = 0;
$dbh->{AutoCommit} = 1;
ok($dbh->{AutoCommit}, "AutoCommit set on dbh");

my $rc = commitTest($dbh);

diag(" Strange: " . $dbh->errstr . "\n") if ($rc < -1);
SKIP: {
    skip "skipped due to lack of transaction support", 3 if ($rc == -1);

    is($rc, 1, "commitTest with AutoCommit");

    $dbh->{AutoCommit} = 0;
    ok(!$dbh->{AutoCommit}, "AutoCommit turned off");
    $rc = commitTest($dbh);
    diag(" Strange: " . $dbh->errstr . "\n") if ($rc < -1);
    is($rc, 0, "commitTest with AutoCommit off");
};

$dbh->{AutoCommit} = 1;
ok($dbh->{AutoCommit}, "Ensure autocommit back on");

# ------------------------------------------------------------

my $rows = 0;
# Check for tables function working.
my $sth;

my @table_info_cols = (
		       'TABLE_CAT',
		       'TABLE_SCHEM',
		       'TABLE_NAME',
		       'TABLE_TYPE',
		       'REMARKS',
		      );
my @odbc2_table_info_cols = (
                            'TABLE_QUALIFIER',
                            'TABLE_OWNER',
                            'TABLE_NAME',
                            'TABLE_TYPE',
                            'REMARKS');
SKIP:  {
    $sth = $dbh->table_info();
    skip "table_info returned undef sth", 7 unless $sth;
    my $cols = $sth->{NAME};
    isa_ok($cols, 'ARRAY', "sth {NAME} returns ref to array");
    diag("\nN.B. Some drivers (postgres/cache) may return ODBC 2.0 column names for the SQLTables result-set e.g. TABLE_QUALIFIER instead of TABLE_CAT");
    for (my $i = 0; $i < @$cols; $i++) {
       # print ${$cols}[$i], ": ", $sth->func($i+1, 3, ColAttributes),
       # "\n";
       ok(($cols->[$i] eq $table_info_cols[$i]) || ($cols->[$i] eq $odbc2_table_info_cols[$i]), "Column test for table_info $i") or diag("${$cols}[$i] ne $table_info_cols[$i]");
       if (($cols->[$i] ne $table_info_cols[$i]) &&
           ($cols->[$i] eq $odbc2_table_info_cols[$i])) {
           diag("Your driver is returning ODBC 2.0 column names for the SQLTables result-set");
           diag("    $odbc2_table_info_cols[$i] instead of $table_info_cols[$i]");
       }
    }
    while (@row = $sth->fetchrow()) {
        $rows++;
    }
    cmp_ok($rows, '>', 0, "must be some tables out there?");
    $sth->finish();
};

$rows = 0;
$dbh->{PrintError} = 0;
my @tables = $dbh->tables;

cmp_ok(@tables, '>', 0, "tables returns array");
$rows = 0;
if ($sth = $dbh->column_info(undef, undef, $ODBCTEST::table_name, undef)) {
    my $fetched = $sth->fetchall_arrayref;
    cmp_ok(scalar(@$fetched), '>', 0, "column info returns more than one row for test table") or
        diag(Dumper($fetched));
}

$rows = 0;

if ($sth = $dbh->primary_key_info(undef, undef, $ODBCTEST::table_name, undef)) {
    while (@row = $sth->fetchrow()) {
        $rows++;
    }
    $sth->finish();
}

SKIP: {
    skip "Primary Key Known to fail using MS Access through 2000", 1 if ($dbname =~ /Access/i);
    cmp_ok($rows, '>', 0, "primary key count");
};

# test $sth->{NAME} when using non-select statements
$sth = $dbh->prepare("update $ODBCTEST::table_name set COL_A = 100 WHERE COL_A = 100");
ok($sth, "prepare update statement returns valid sth ");
is(@{$sth->{NAME}}, 0, "update statement has 0 columns returned");
$sth->execute;
SKIP: {
    skip 'Testing $sth->{NAME} after successful execute on update statement known to fail in Postgres', 1 if ($dbname =~ /PostgreSQL/i);
    is(@{$sth->{NAME}}, 0, "update statement has 0 columns returned 2");
};

is($dbh->{odbc_query_timeout}, 0, 'verify default dbh odbc_query_timeout = 0');
my $sth_timeout = $dbh->prepare("select COL_A from $ODBCTEST::table_name");
is($sth_timeout->{odbc_query_timeout}, 0,
   'verify default sth odbc_query_timeout = 0');
$sth_timeout = undef;

$dbh->{odbc_query_timeout} = 30;
is($dbh->{odbc_query_timeout}, 30, "Verify odbc_query_timeout set ok");

$sth_timeout = $dbh->prepare("select COL_A from $ODBCTEST::table_name");
is($sth_timeout->{odbc_query_timeout}, 30, "verify dbh setting for query_timeout passed to sth");
$sth_timeout->{odbc_query_timeout} = 1;
is($sth_timeout->{odbc_query_timeout}, 1, "verify sth query_timeout can be overridden");

# odbc_column_display_size
is($dbh->{odbc_column_display_size}, 2001, 'verify default for odbc_column_display_size');
ok($dbh->{odbc_column_display_size} = 3000, 'set odbc_column_display_size');
is($dbh->{odbc_column_display_size}, 3000,
   'verify changed odbc_column_display_size');

$dbh->disconnect;
exit 0;
# avoid annoying warning
print $DBI::errstr;
# print STDERR $dbh->{odbc_SQL_DRIVER_ODBC_VER}, "\n";


# ------------------------------------------------------------
# returns true when a row remains inserted after a rollback.
# this means that autocommit is ON.
# ------------------------------------------------------------
sub commitTest {
    my $dbh = shift;
    my $rc = -2;
    my $sth;

    # since this test deletes the record, we should do it regardless
    # of whether or not it the db supports transactions.
    $dbh->do("DELETE FROM $ODBCTEST::table_name WHERE COL_A = 100") or return undef;

    { # suppress the "commit ineffective" warning
      local($SIG{__WARN__}) = sub { };
      $dbh->commit();
    }

    my $supported = $dbh->get_info(46); # SQL_TXN_CAPABLE
    # print "Transactions supported: $supported\n";
    if (!$supported) {
        return -1;
    }

    my $row = ODBCTEST::get_type_for_column($dbh, 'COL_D');
    my $dateval;
    if (ODBCTEST::isDateType($row->{DATA_TYPE})) {
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

