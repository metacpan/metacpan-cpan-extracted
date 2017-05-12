#!/usr/bin/perl -w -I./t
#
# rt62033 - not really this rt but a bug discovered when looking in to it
#
# Check active is enabled on a statement after SQLMoreResults indicates
# there is another result-set.
#
use Test::More;
use strict;
eval "require Test::NoWarnings";
my $has_test_nowarnings = ($@ ? undef : 1);

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
            $dbh->do(q/drop table PERL_DBD_RT_62033/);
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
$dbh->{PrintError} = 0;

my $dbms_name = $dbh->get_info(17);
ok($dbms_name, "got DBMS name: $dbms_name"); # 2
my $dbms_version = $dbh->get_info(18);
ok($dbms_version, "got DBMS version: $dbms_version"); # 3
my $driver_name = $dbh->get_info(6);
ok($driver_name, "got DRIVER name: $driver_name"); # 4
my $driver_version = $dbh->get_info(7);
ok($driver_version, "got DRIVER version $driver_version"); # 5

my ($ev, $sth);

# this needs to be MS SQL Server
if ($dbms_name !~ /Microsoft SQL Server/) {
    note('Not Microsoft SQL Server');
    exit 0;
}
eval {
    local $dbh->{PrintWarn} = 0;
    local $dbh->{PrintError} = 0;
    $dbh->do('drop table PERL_DBD_RT_62033');
};

# try and create a table to test with
eval {
    $dbh->do(
        'create table PERL_DBD_RT_62033 (a int identity, b char(10) not null)');
};
$ev = $@;

if ($@) {
    BAIL_OUT("Failed to create test table - aborting test ($ev)");
    exit 0;
}
pass('created test table');

sub doit
{
    my $dbh = shift;
    my $expect = shift;         # undef if we expect this to fail

    my $s = $dbh->prepare_cached(
        q/insert into PERL_DBD_RT_62033 (b) values(?);select @@identity/);
    eval {$s->execute(@_)};

    if (!$expect) {             # expected to fail
        ok($@, 'Error for constraint - expected');
        note("For some drivers (freeTDS/MS SQL Server for Linux) there is no way out of this so expect further errors");
    } else {
        ok(!$@, 'Execute ok') or diag($@);
    }

    # Some drivers won't like us calling SQLMoreResults/SQLDescribe etc
    # after the above if it errors. When we call odbc_more_results it actually
    # ends up doing a SQLDescribe. For most drivers I've tested they
    # are ok with this but a few (freeTDS) are not. The problem with freeTDS
    # is that if you then omit the SQLMoreResults and continue with this test
    # you'll get an SQL_ERROR from the next execute without an error msg
    # so it would seem there is no way to make this work in freeTDS as it
    # stands.
    #
    # Some drivers (basically all those I've tested except freeTDS) need you
    # to call SQLMoreResults even if the above fails or you'll get invalid
    # cursor state on the next statement (MS SQL Server and MS native client
    # driver).

    if ($s->{NUM_OF_FIELDS} == 0) {
        my $x = $s->{odbc_more_results};
    }
    if ($expect) {

        # for the error case where we attempt to insert a NULL into column b
        # we'd expect odbc_more_results to return 0/false - there are no more
        # results
        my $identity;
        ($identity) = $s->fetchrow_array;
        #diag("identity = ", DBI::neat($identity), "\n");
        is($identity, $expect, "Identity");
        ($identity) = $s->fetchrow_array;
    } else {
        $s->finish;
    }
}

doit($dbh, undef, undef);
doit($dbh, 2, 'fred');

eval {
    local $dbh->{PrintWarn} = 0;
    local $dbh->{PrintError} = 0;
    $dbh->do('drop table PERL_DBD_RT_62033');
};


