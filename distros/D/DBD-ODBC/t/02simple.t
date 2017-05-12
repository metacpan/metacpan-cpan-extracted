#!perl -w -I./t

use Test::More;
use strict;
use Config;
use DBD::ODBC;

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 65;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

use_ok('DBI', qw(:sql_types));
use_ok('ODBCTEST');
#use_ok('Data::Dumper');

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}
END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}


my $dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database ($DBI::errstr)\nTests skipped.\n");
   exit 0;
}
my $driver_name;
# Output DBMS which is useful when debugging cpan-testers output
{
    diag("\n");
    diag("Perl $Config{PERL_REVISION}.$Config{PERL_VERSION}.$Config{PERL_SUBVERSION}\n");
    diag("osname=$Config{osname}, osvers=$Config{osvers}, archname=$Config{archname}\n");
    diag("Using DBI $DBI::VERSION\n");
    diag("Using DBD::ODBC $DBD::ODBC::VERSION\n");
    diag("Using DBMS_NAME " . DBI::neat($dbh->get_info(17)) . "\n");
    diag("Using DBMS_VER " . DBI::neat($dbh->get_info(18)) . "\n");
    $driver_name = DBI::neat($dbh->get_info(6));
    diag("Using DRIVER_NAME $driver_name\n");
    diag("Using DRIVER_VER " . DBI::neat($dbh->get_info(7)) . "\n");
    diag("odbc_has_unicode " . ($dbh->{odbc_has_unicode} || '') . "\n");
}

# ReadOnly
{
    # NOTE: the catching of warnings here needs a DBI > 1.628
	local $dbh->{AutoCommit} = 0;
    my $warning;
    local $SIG{__WARN__} = sub {diag "AA:"; diag @_; $warning = 1};
    $dbh->{ReadOnly} = 1;
    if ($warning) {
        diag "Your ODBC driver does not support setting ReadOnly";
    }
    is($dbh->{ReadOnly}, 1, 'ReadOnly set');
    $dbh->{ReadOnly} = 0;
    is($dbh->{ReadOnly}, 0, 'ReadOnly cleared');
}


#
# test private_attribute_info.
# connection handles and statement handles should return a hash ref of
# private attributes
#
SKIP: {
    skip "DBI too old for private_attribute_info", 3
	if ($DBI::VERSION < 1.54);
    my $pai = $dbh->private_attribute_info();
    #diag Data::Dumper->Dump([$pai], [qw(dbc_private_attribute_info)]);
    ok(defined($pai), 'dbc private_attribute_info result');
    ok(ref($pai) eq 'HASH', 'dbc private_attribute_info is hashref');
    ok(scalar(keys %{$pai}) >= 1,
       'dbc private_attribute_info has some attributes');
};

SKIP: {
    skip "DBI too old for private_attribute_info", 3
	if ($DBI::VERSION < 1.54);

    my $sql;
    my $drv = $dbh->get_info(17);
    if ($drv =~ /Oracle/i) {
        $sql = q/select 1 from dual/;
    } elsif ($drv =~ /Firebird/i) {
        $sql = q/select 1 from rdb$database/;
    } else {
        $sql = q/select 1/;
    }
    my $sth = $dbh->prepare($sql);
    my $pai = $sth->private_attribute_info();
    #diag Data::Dumper->Dump([$pai], [qw(stmt_private_attribute_info)]);
    ok(defined($pai), 'stmt private_attribute_info result');
    ok(ref($pai) eq 'HASH', 'stmt private_attribute_info is hashref');
    ok(scalar(keys %{$pai}) >= 1, 'stmt private_attribute_info has some attributes');
    $sth->finish;
};

#
# Test changing of AutoCommit - start by setting away from the default
#
$dbh->{AutoCommit} = 0;
pass("Set Auto commit off");
is($dbh->{AutoCommit}, 0, 'Auto commit off retrieved');
$dbh->{AutoCommit} = 1;
pass("Set Auto commit on");
is($dbh->{AutoCommit}, 1, "Auto commit on restored");

#### testing a simple select

my $rc = 0;
ok(ODBCTEST::tab_create($dbh), "create test table");

cmp_ok(ODBCTEST::tab_exists($dbh), '>=', 0, "test table exists");

ok(ODBCTEST::tab_insert($dbh), "insert test data");

ok(tab_select($dbh), "select test data");

$rc = undef;
#
# LongReadLen
#
my $lrl = $dbh->{LongReadLen};
ok(defined($lrl), 'Get LongReadLen starting value');
ok(DBI::looks_like_number($lrl), 'LongReadLen is numeric');
$dbh->{LongReadLen} = $lrl + 1;
pass('Set LongReadLen');
is($dbh->{LongReadLen}, $lrl + 1, "Read changed LongReadLen back");

#
# LongTruncOk
#
my $lto = $dbh->{LongTruncOk};
ok(defined($lto), 'Get LongTruncOk starting value');
$dbh->{LongTruncOk} = 1;
pass('Set LongTruncOk on');
is($dbh->{LongTruncOk}, 1, "LongTruncOk on");


$dbh->{PrintError} = 0;
is($dbh->{PrintError}, '', "Set Print Error");

#
# check LongTruncOk works i.e. select a column longer than 50
# check truncated data agrees with LongReadLen
#
$dbh->{LongTruncOk} = 1;
$dbh->{LongReadLen} = 50;
my $max_col_len;
ok(select_long($dbh, \$max_col_len, 1), "Select Long data, LongTruncOk");
ok(!defined($dbh->err), 'err not set on LongTruncOk handle');
# NOTE: there is an existing bug in DBD::ODBC that truncates to LongReadLen
# + 1 instead of LongReadLen. Not fixed yet and failing test causes loads
# of people to post saying it fails so change to test not more than
# LongReadLen + 1.
ok($max_col_len <= 51, 'Truncated column to LongReadLen') or
    diag("Got $max_col_len");

# now force an error and ensure we get a long truncated event.
$dbh->{LongTruncOk} = 0;
is($dbh->{LongTruncOk}, '', "Set Long TruncOk 0");
# Following test fails with FreeTDS 0.63 and 0.64 because FreeTDS does not
# report a data truncation error and hence no error is raised and there
# err, errstr and state are not set.
$rc = select_long($dbh, \$max_col_len, 0);
ok(!$rc, "Select Long Data failure");
ok($dbh->err, 'error set on truncated handle');
ok($dbh->errstr, 'errstr set on truncated handle');
ok($dbh->state, 'state set on truncated handle');
if ($rc && ($driver_name =~ /tdsodbc/)) {
    diag(qq/\nNOTE:\nFreeTDS fails the previous 4 tests because when you select a column greater\nthan 80 characters with LongTruncOk it does not generate a\n01004, "String data, right truncation error\n"/);
}

my $sth = $dbh->prepare("SELECT * FROM $ODBCTEST::table_name ORDER BY COL_A");
ok(defined($sth), "prepare select from table");
if ($sth) {
   ok($sth->execute(), "Execute select");
   my $colcount = $sth->func(1, 0, 'ColAttributes'); # 1 for col (unused) 0 for SQL_COLUMN_COUNT
   #diag("Column count is: $colcount\n");
   is($sth->{NUM_OF_FIELDS}, $colcount,
      'NUM_OF_FIELDS = ColAttributes(SQL_COLUMN_COUNT)');
   my ($coltype, $colname, $i, @row);
   my $is_ok = 0;
   for ($i = 1; $i <= $sth->{NUM_OF_FIELDS}; $i++) {
      # $i is colno (1 based) 2 is for SQL_COLUMN_TYPE, 1 is for SQL_COLUMN_NAME
      $coltype = $sth->func($i, 2, 'ColAttributes');
      # NOTE: changed below to uc (uppercase) as keys in TestFieldInfo are
      # uppercase and databases are not guaranteed to return column names in
      # uppercase.
      $colname = uc($sth->func($i, 1, 'ColAttributes'));
      #diag("$i: $colname = $coltype ", $coltype+1-1);
      if (grep { $coltype == $_ } @{$ODBCTEST::TestFieldInfo{$colname}}) {
          $is_ok++;
      } else {
          diag("Coltype $coltype for column $colname not found in list ", join(', ', @{$ODBCTEST::TestFieldInfo{$colname}}), "\n");
      }
   }
   is($is_ok, $colcount, "Col count matches correct col count");
   # print "not " unless $is_ok == $colcount;
   # print "ok 9\n";

   $sth->finish;
} else {
   fail("select didn't work, so column count won't work");
}

$dbh->{RaiseError} = 0;
is($dbh->{RaiseError}, '', "Set RaiseError 0");
$dbh->{PrintError} = 0;
is($dbh->{PrintError}, '', "Set PrintError 0");
#
# some ODBC drivers will prepare this OK, but not execute.
#
$sth = $dbh->prepare("SELECT XXNOTCOLUMN FROM $ODBCTEST::table_name");
$sth->execute() if $sth;
if (!defined($DBI::errstr) || (length($DBI::errstr) == 0)) {
    fail("Error reported on bad query");
    if ($driver_name =~ /tdsodbc/) {
        diag(qq/NOTE:\nfreeTDS 0.63 at least, fails the previous test because no error is returned\nfrom SQLPrepare or SQLExecute when you enter a\n"select non_existent_table_name from table" query.\nVersion 0.82 seems to have fixed this./);
    }
} else {
    pass("Error reported on bad query");
}
my $row = ODBCTEST::get_type_for_column($dbh, 'COL_D');

my $dateval;
if (ODBCTEST::isDateType($row->{DATA_TYPE})) {
   $dateval = "{d '1998-05-13'}";
} else {
   $dateval = "{ts '1998-05-13 12:13:01'}";
}

$sth = $dbh->prepare("SELECT COL_D FROM $ODBCTEST::table_name WHERE COL_D > $dateval");
ok(defined($sth), "date check select");
ok($sth->execute(), "date check execute");
my $count = 0;
while (my @row = $sth->fetchrow) {
	$count++ if ($row[0]);
	# diag("$row[0]\n");
}
is($count, 1, "date check rows");

$sth = $dbh->prepare("SELECT COL_A, COUNT(*) FROM $ODBCTEST::table_name GROUP BY COL_A");
ok($sth, "group by query prepare");
ok($sth->execute(), "group by query execute");
$count = 0;
while (my @row = $sth->fetchrow) {
	$count++ if ($row[0]);
	# diag("$row[0], $row[1]\n");
}
cmp_ok($count, '!=', 0, "group by query returned rows");

$rc = ODBCTEST::tab_delete($dbh);

# Note, this test will fail if no data sources defined or if
# data_sources is unsupported.
my @data_sources = DBI->data_sources('ODBC');
#diag("Data sources:\n\t", join("\n\t",@data_sources),"\n\n");
# NOTE: data_sources may return 0 data sources if there are none
# and we are using a DSN-less connection string
cmp_ok($#data_sources, '>=', -1, "data sources test");


ok($dbh->ping, "test ping method");

is($dbh->{odbc_ignore_named_placeholders}, 0, "Attrib odbc_ignore_named_placeholders 0 to start");
$dbh->{odbc_ignore_named_placeholders} = 1;
is($dbh->{odbc_ignore_named_placeholders}, 1, "Attrib odbc_ignore_named_placeholders set to 1");

my $dbh2 = DBI->connect();
ok(defined($dbh2), "test connecting twice to the same database");
$dbh2->disconnect;


my $dbname;
$dbname = $dbh->get_info(17); # SQL_DBMS_NAME
# diag(" connected to $dbname\n");
ok(defined($dbname) && $dbname ne '', "database name is returned successfully");
#print "\nnot " unless (defined($dbname) && $dbname ne '');
#print "ok 17\n";

$sth = $dbh->prepare("select count(*) from $ODBCTEST::table_name");
$sth->execute;
$sth->fetch;
ok($sth->execute, "automatically finish when execute run again");

#DBI->trace(9, "c:/trace.txt");
# TBD: Make skip block!
my $connstr = $ENV{DBI_DSN};
SKIP: {
   skip "DSN already contains DRIVER= or DSN=", 3 unless (!($connstr =~ /DSN=/i || $connstr =~ /DRIVER=/i));
   $connstr =~ s/ODBC:/ODBC:DSN=/;

   my $dbh3 = DBI->connect($ENV{DBI_DSN} . "x", $ENV{DBI_USER}, $ENV{DBI_PASS}, {RaiseError=>0, PrintError=>0});
   ok(defined($DBI::errstr), "INVALID DSN Test: " . $DBI::errstr . "\n");
   $dbh3->disconnect if (defined($dbh3));

   $dbh3 = DBI->connect($connstr, $ENV{DBI_USER}, $ENV{DBI_PASS}, {RaiseError=>0, PrintError=>0});
   ok(defined($dbh3), "Connection with DSN=$connstr");
   $dbh3->disconnect if (defined($dbh3));

   my $cs = $connstr;
   $cs .= ";UID=$ENV{DBI_USER}" if exists($ENV{DBI_USER});
   $cs .= ";PWD=$ENV{DBI_PASS}" if exists($ENV{DBI_PASS});
   $dbh3 = DBI->connect($cs,undef,undef, {RaiseError=>0, PrintError=>0});
   ok(defined($dbh3),
      "Connection with DSN=$connstr and UID and PWD are set") or diag($cs);
   $dbh3->disconnect if (defined($dbh3));
};

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

    my $sth = $dbh->prepare("SELECT COL_A, COL_B, COL_C, COL_D FROM $ODBCTEST::table_name ORDER BY COL_A")
		or return undef;
    $sth->execute();
    ok($sth->{NUM_OF_FIELDS} == 4, 'NUM_OF_FIELDS');
    my $columns = $sth->{NAME_uc};
    #diag Data::Dumper->Dump([$columns], [qw(column_names)]);
    is(scalar(@$columns), 4, 'NAME returns right number of columns');
    is($columns->[0], 'COL_A', 'column name for column 1');
    is($columns->[1], 'COL_B', 'column name for column 2');
    is($columns->[2], 'COL_C', 'column name for column 3');
    is($columns->[3], 'COL_D', 'column name for column 4');
    while (@row = $sth->fetchrow())	{
       # print "$row[0]|$row[1]|$row[2]|\n";
       ++$rowcount;
       if ($rowcount != $row[0]) {
	    # print "Basic retrieval of rows not working!\nRowcount = $rowcount, while retrieved value = $row[0]\n";
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
            if (!is($row[1], $ODBCTEST::longstr, "long strings compare")) {
                diag("Basic retrieval of longer rows not working\n" .
                    DBI::data_diff($row[1], $ODBCTEST::longstr));
                return 0;
            }
 	} elsif ($row[0] == 5) {
	    if (!is($row[1], $ODBCTEST::longstr2, "long strings compare 255")) {
                diag("Basic retrieval of row longer than 255 chars" .
                         " not working!\n" .
                             DBI::data_diff($row[1], $ODBCTEST::longstr2));
                return 0;
	    }
	}
    }

    return 1;
}

#
# returns 1 unless the eval around the select fails (e.g. if truncation)
#
sub select_long
{
    my ($dbh, $max_col, $expect) = @_;
    $$max_col = undef;
    my @row;
    my $sth;
    my $rc = 0;
    my $longest = undef;

    local $dbh->{RaiseError} = 1;
    local $dbh->{PrintError} = 0;
    local $dbh->{PrintWarn} = 0;

    $sth = $dbh->prepare("SELECT COL_A,COL_C FROM $ODBCTEST::table_name WHERE COL_A=4");
    if ($sth) {
        $sth->execute();
        eval {
            while (@row = $sth->fetchrow()) {
                foreach my $c (@row) {
                    if (!$longest) {
                        $longest = length($c);
                    } else {
                        $longest = length($c) if length($c) > $longest;
                    }
                }
            }
        };
        $rc = 1 unless ($@) ;
    }
    if ($rc != $expect) {
        diag("Row " . (map {(defined($_) ? $_ : 'undef') . ','} @row) . "\n");
        diag("expect=$expect, Longest: " . DBI::neat($longest) . "\n");
    }
    $$max_col = $longest;
    $rc;
}

__END__
