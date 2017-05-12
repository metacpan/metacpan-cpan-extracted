#!/usr/bin/perl -w -I./t
# $Id: rt_38977.t 13874 2010-03-24 14:22:58Z mjevans $
#
# rt 59621
#
# Check DBD::ODBC handles MS SQL Server XML column type properly
#
use Test::More;
use strict;
$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 11;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

use DBI qw(:sql_types);
use_ok('ODBCTEST');             # 1

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
            $dbh->do(q/drop table PERL_DBD_RT_59621/);
        };
    }
    Test::NoWarnings::had_no_warnings() # 12
          if ($has_test_nowarnings);
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
$dbh->{RaiseError} = 1;

my $dbms_name = $dbh->get_info(17);
ok($dbms_name, "got DBMS name: $dbms_name"); # 2
my $dbms_version = $dbh->get_info(18);
ok($dbms_version, "got DBMS version: $dbms_version"); # 3
my $driver_name = $dbh->get_info(6);
ok($driver_name, "got DRIVER name: $driver_name"); # 4
my $driver_version = $dbh->get_info(7);
ok($driver_version, "got DRIVER version $driver_version"); # 5

my ($ev, $sth);

SKIP: {
    skip "not SQL Server", 6 if $dbms_name !~ /Microsoft SQL Server/;
    skip "Easysoft OOB", 6 if $driver_name =~ /esoobclient/;

    eval {
        local $dbh->{PrintWarn} = 0;
        local $dbh->{PrintError} = 0;
        $dbh->do('drop table PERL_DBD_RT_59621');
    };

    # try and create a table with an XML column
    # if we cannot, we'll have to assume your SQL Server is too old
    # and skip the rest of the tests
    eval {
        $dbh->do('create table PERL_DBD_RT_59621 (a int primary key, b xml)');
    };
    $ev = $@;

  SKIP: {
        skip "Failed to create test table with XML type - server too old and perhaps does not support XML column type ($ev)",
            6 if $ev;
        pass('created test table'); # 6
        eval {
            $sth = $dbh->prepare('INSERT into PERL_DBD_RT_59621 VALUES (?,?)');
        };
        $ev = $@;
        diag($ev) if $ev;
        ok(!$ev, 'prepare insert'); # 7
      SKIP: {                       # 1
            skip "Failed to prepare xml insert - $@", 4 if $ev;

            my $x = '<xx>' .('z' x 500) . '</xx>';
            eval {
                $sth->execute(1, $x);
            };
            $ev = $@;
            diag($ev) if $ev;
            ok(!$ev, 'execute insert'); # 8
          SKIP: {                      # 3
                skip "Failed to execute insert", 3 if $ev;

                # now try and select the XML back
                # we expect a data truncation error the first time as
                # LongReadLen defaults to 80
                eval {
                    local $dbh->{PrintError} = 0;
                    $sth = $dbh->selectall_arrayref(
                        'select * from PERL_DBD_RT_59621');
                };
                ok($@, 'expected select on XML type too big failed'); # 9
                is($sth->state, '01004', 'data truncation error'); # 10

                # now bump up LongReadLen and all should be ok
                # we need to make it more than 2 * expected in case it is
                # retrieved as WCHARs
                $dbh->{LongReadLen} = 2000;
                eval {
                    $sth = $dbh->selectall_arrayref(
                        'select * from PERL_DBD_RT_59621');
                };
                $ev = $@;
                diag($ev) if $ev;
                ok(!$@, 'select on XML type with LongReadLen ok'); # 11
            };
        };
    };
    eval {
        local $dbh->{PrintWarn} = 0;
        local $dbh->{PrintError} = 0;
        $dbh->do('drop table PERL_DBD_RT_59621');
    };
};

