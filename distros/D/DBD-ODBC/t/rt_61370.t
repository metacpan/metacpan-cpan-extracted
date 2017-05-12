#!/usr/bin/perl -w -I./t
#
# rt 61370
#
# Check DBD::ODBC handles MS SQL Server XML column type as Unicode
# and that set magic is used internally to ensure length() returns the
# correct value.
#
use Test::More;
use strict;
eval "require Test::NoWarnings";
my $has_test_nowarnings = ($@ ? undef : 1);

#my $has_test_more_utf8 = 1;
#eval "require Test::More::UTF8";
#$has_test_more_utf8 = undef if $@;

binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

binmode STDOUT, ':utf8';

use DBI qw(:sql_types);
use_ok('ODBCTEST');

my $dbh;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}

END {
    if ($dbh) {
        eval {
            local $dbh->{PrintWarn} = 0;
            local $dbh->{PrintError} = 0;
            $dbh->do(q/drop table PERL_DBD_RT_61370/);
        };
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
    done_testing();
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
$dbh->{RaiseError} = 1;
$dbh->{ChopBlanks} = 1;

my ($txt_de, $txt_ru);
{
    use utf8;
    $txt_de = 'Käse';
    $txt_ru = 'Москва';
}

my $dbms_name = $dbh->get_info(17);
ok($dbms_name, "got DBMS name: $dbms_name"); # 2
my $dbms_version = $dbh->get_info(18);
ok($dbms_version, "got DBMS version: $dbms_version"); # 3
my $driver_name = $dbh->get_info(6);
ok($driver_name, "got DRIVER name: $driver_name"); # 4
my $driver_version = $dbh->get_info(7);
ok($driver_version, "got DRIVER version $driver_version"); # 5

my ($ev, $sth);

# this needs to be MS SQL Server and not the OOB driver
if ($dbms_name !~ /Microsoft SQL Server/) {
    note('Not Microsoft SQL Server');
    exit 0;
}
if ($driver_name =~ /esoobclient/) {
    note("Easysoft OOB");
    exit 0;
}
if (!$dbh->{odbc_has_unicode}) {
    note('DBD::ODBC not built with unicode support');
    exit 0;
}
eval {
    local $dbh->{PrintWarn} = 0;
    local $dbh->{PrintError} = 0;
    $dbh->do('drop table PERL_DBD_RT_61370');
};

# try and create a table with an XML column
# if we cannot, we'll have to assume your SQL Server is too old
# and skip the rest of the tests
eval {
    $dbh->do('create table PERL_DBD_RT_61370 (a int primary key, b xml)');
};
$ev = $@;

if ($@) {
    note("Failed to create test table with XML type - server too old and perhaps does not support XML column type ($ev)");
    done_testing;
    exit 0;
}

pass('created test table');
eval {
    $sth = $dbh->prepare('INSERT into PERL_DBD_RT_61370 VALUES (?,?)');
};
$ev = $@;
diag($ev) if $ev;
ok(!$ev, 'prepare insert');
SKIP: {
    skip "Failed to prepare xml insert - $@", 8 if $ev;

    my @rowdata = ([1, "<d>$txt_de</d>"], [2, "<d>$txt_ru</d>"]);
    $ev = undef;
    foreach my $row(@rowdata) {
        $sth->bind_param(1, $row->[0]);
        $sth->bind_param(2, $row->[1]);
        eval {$sth->execute};
        if ($@) {
            $ev = $@;
            fail('execute for insert'); # 1,2
        } else {
            pass('execute for insert'); # 1,2
        }
    }
  SKIP: {
        skip "Could not insert test data - $@", 6 if $ev;

        $sth = $dbh->prepare(q/select a,b from PERL_DBD_RT_61370 order by a/);
        ok($sth, 'prepare for select');           # 1
        ok($sth->execute, 'execute for select'); # 2
        $sth->bind_col(1, \my $pkey);
        # the SQL_WCHAR in the below call does nothing from DBD::ODBC 1.38_1
        # as it became the deault and you cannot override the bind type:
        $sth->bind_col(2, \my $xml, {TYPE => SQL_WCHAR});

        foreach my $row(@rowdata) {
            $sth->fetch;
            #diag(sprintf("%3u %s", length($row->[1]), $row->[1]));
            is($pkey, $row->[0], 'inserted/selected pkey match');
            is($xml, $row->[1], 'inserted/selected strings match'); # 3,5
            is(length($xml), length($row->[1]),
               'inserted/selected string sizes match'); # 4,6
        }
    };
};

eval {
    local $dbh->{PrintWarn} = 0;
    local $dbh->{PrintError} = 0;
    $dbh->do('drop table PERL_DBD_RT_61370');
};


