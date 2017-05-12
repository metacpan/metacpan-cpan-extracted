#!/usr/bin/perl -w -I./t
# loads of execute_array and execute_for_fetch tests using DBD::ODBC's native methods

use Test::More;
use strict;
#use Data::Dumper;
use Config;

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;

my ($dbh, $ea);

use DBI qw(:sql_types);
use ExecuteArray;

BEGIN {
    plan skip_all => "DBI_DSN is undefined"
        if (!defined $ENV{DBI_DSN});
}
END {
    if ($dbh && $ea) {
        $ea->drop_table($dbh);
        $dbh->disconnect();
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
{
    my $driver_name = DBI::neat($dbh->get_info(6));
    my $dbms_name = $dbh->get_info(17);
    if (($driver_name =~ /odbcjt32.dll/i) ||
            ($driver_name =~ /ACEODBC.DLL/i) ||
                ($dbms_name eq 'ACCESS')) { # for OOB
        $has_test_nowarnings = 0;
        plan skip_all => 'MS Access does not support array operations';
    }
    if ($driver_name =~ /sqlite/) {
        $has_test_nowarnings = 0;
        plan skip_all => "SQLite fails this test horribly - I can't find anywhere to report it";
    }

    diag("\n\nNOTE: This is an experimental test. Since DBD::ODBC added the execute_for_fetch method this tests the native method and not DBI's fallback method. If you fail this test it probably means the ODBC driver you are using does not have sufficient support (or is buggy) for array operations. If you pass this test your ODBC Driver seems ok and you can get faster insert/update/delete operations using DBI's execute_array or execute_for_fetch methods by setting the odbc_array_operations to true.

If this test fails it should not stop you installing DBD::ODBC but if it fails with an error other than something indicating 'connection busy' I'd strongly suggest you don't set odbc_array_operations and stick with DBI's default implementation.

If this test fails for your driver I'd like to hear about it so I can compile a list of working drivers and perhaps pass bug reports on to the maintainers. Please rerun this test with TEST_VERBOSE set or using prove and send the results to the dbi-users mailing list.\n\n");

    diag("\n");
    diag("Perl $Config{PERL_REVISION}.$Config{PERL_VERSION}.$Config{PERL_SUBVERSION}\n");
    diag("osname=$Config{osname}, osvers=$Config{osvers}, archname=$Config{archname}\n");
    diag("Using DBI $DBI::VERSION\n");
    diag("Using DBD::ODBC $DBD::ODBC::VERSION\n");
    diag("Using DBMS_NAME " . DBI::neat($dbh->get_info(17)) . "\n");
    diag("Using DBMS_VER " . DBI::neat($dbh->get_info(18)) . "\n");
    diag("Using DRIVER_NAME $driver_name\n");
    diag("Using DRIVER_VER " . DBI::neat($dbh->get_info(7)) . "\n");
    diag("odbc_has_unicode " . $dbh->{odbc_has_unicode} . "\n");

}

note("Using driver $dbh->{Driver}->{Name}");

$ENV{ODBC_DISABLE_ARRAY_OPERATIONS} = 0; # force array ops
$ea = ExecuteArray->new($dbh, 0); # don't set odbc_disable_array_operations
$dbh = $ea->dbh;

$ea->drop_table($dbh);
ok($ea->create_table($dbh), "create test table") or exit 1;
$ea->simple($dbh, {array_context => 1, raise => 1});
$ea->simple($dbh, {array_context => 0, raise => 1});
$ea->error($dbh, {array_context => 1, raise => 1});
$ea->error($dbh, {array_context => 0, raise => 1});
$ea->error($dbh, {array_context => 1, raise => 0});
$ea->error($dbh, {array_context => 0, raise => 0});

$ea->row_wise($dbh, {array_context => 1, raise => 1});

$ea->update($dbh, {array_context => 1, raise => 1});

# do all the error ones again without specifying ArrayTupleStatus
$ea->error($dbh, {array_context => 1, raise => 1, notuplestatus => 1});
$ea->error($dbh, {array_context => 0, raise => 1, notuplestatus => 1});
$ea->error($dbh, {array_context => 1, raise => 0, notuplestatus => 1});
$ea->error($dbh, {array_context => 0, raise => 0, notuplestatus => 1});

