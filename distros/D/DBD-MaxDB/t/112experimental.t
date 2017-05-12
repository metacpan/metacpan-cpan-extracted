#!perl -w -I./t
#/*!
#  @file           112experimental.t
#  @author         GeroD
#  @ingroup        dbd::MaxDB
#  @brief          checks all methods described as 'experimental'. Such as tables, type_info_all, type_info,
#
#\if EMIT_LICENCE
#
#    ========== licence begin  GPL
#    Copyright (C) 2001-2004 SAP AG
#
#    This program is free software; you can redistribute it and/or
#    modify it under the terms of the GNU General Public License
#    as published by the Free Software Foundation; either version 2
#    of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#    ========== licence end
#
#
#\endif
#*/
use DBI;
use MaxDBTest;

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
   $tests = 10;
   $MaxDBTest::numTest=0;
   unless (defined $ENV{DBI_DSN}) {
      print "1..0 # Skipped: DBI_DSN is undefined\n";
      exit;
   }
}

print "1..$tests\n";

# prepare

MaxDBTest::beginTest("connect");
my $dbh = DBI->connect() or die "Can't connect $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable");
MaxDBTest::endTest();

MaxDBTest::beginTest("create table");
$dbh->do("CREATE TABLE GerosTestTable (i INTEGER)") or die "CREATE TABLE failed $DBI::err $DBI::errstr\n";
MaxDBTest::endTest();


# run

MaxDBTest::beginTest("tables");
@names = $dbh->tables() or MaxDBTest::logerror(qq{dbh->tables failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("see if 'GEROSTESTTABLE' is available");
if (@names) {
    my $found = 0;
    foreach $name (@names) {
#        MaxDBTest::loginfo("$name");
        if (($name =~ /\.GEROSTESTTABLE$/) or ($name eq "\"DBA\".\"GEROSTESTTABLE\"")) {
            $found = 1;
            last;
        } elsif ($name =~ /GEROSTESTTABLE/) {
            MaxDBTest::logerror("the following invalid string was listed: '$name'");
            MaxDBTest::logerror("expected was: 'GEROSTESTTABLE' or '???.GEROSTESTTABLE'");
            $found = 1;
        }
    }
    if (!$found) {
        MaxDBTest::logerror("table 'GerosTestTable' was created but not listed by dbh->tables");
    }
} else {
    MaxDBTest::logerror("no tables were returned. Can't check...");
}
MaxDBTest::endTest();

MaxDBTest::beginTest("type_info_all");
my $type_info_allref = $dbh->type_info_all() or
    MaxDBTest::logerror(qq{dbh->type_info_all failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

my @required = qw/TYPE_NAME DATA_TYPE COLUMN_SIZE LITERAL_PREFIX LITERAL_SUFFIX
    CREATE_PARAMS NULLABLE CASE_SENSITIVE SEARCHABLE UNSIGNED_ATTRIBUTE
    FIXED_PREC_SCALE AUTO_UNIQUE_VALUE LOCAL_TYPE_NAME MINIMUM_SCALE
    MAXIMUM_SCALE NUM_PREC_RADIX/;
    
my @additional = qw/SQL_DATA_TYPE SQL_DATETIME_SUB INTERVAL_PRECISION/;

my $DATA_TYPE_index=0;

MaxDBTest::beginTest("check if all name / index pairs are set");
if ($type_info_allref) {
    my $pairs = $$type_info_allref[0];
    foreach $name (@required) {
        if (!defined($$pairs{$name})) {
            MaxDBTest::logerror("$name has no index");
        }
    }
    foreach my $name (@additional) {
        if (!defined($$pairs{$name})) {
            MaxDBTest::logwarning("$name has no index");
        }
    }
    $DATA_TYPE_index = $$pairs{DATA_TYPE};
} else {
    MaxDBTest::logerror("no type info was returned. Can't check...");
}
MaxDBTest::endTest();

MaxDBTest::beginTest("type_info for all types");
if ($type_info_allref) {
    # cut off the first element
    my ($dummy, @type_info_allarray) = @$type_info_allref;

    foreach my $type_inforef (@type_info_allarray) {
        my @type_info = $dbh->type_info($$type_inforef[$DATA_TYPE_index]) or
            MaxDBTest::logerror(qq{dbh->type_info failed for $$type_inforef[$DATA_TYPE_index]. $DBI::err $DBI::errstr});
    }
} else {
    MaxDBTest::logerror("no type info was returned. Can't check...");
}
MaxDBTest::endTest();


# release

MaxDBTest::beginTest("drop table");
MaxDBTest::dropTable($dbh, "GerosTestTable") or MaxDBTest::logerror(qq{drop table failed $DBI::err $DBI::errstr});
MaxDBTest::endTest();

MaxDBTest::beginTest("disconnect");
$dbh->disconnect or MaxDBTest::logerror(qq{Can't disconnect $DBI::err $DBI::errstr});
MaxDBTest::endTest();

