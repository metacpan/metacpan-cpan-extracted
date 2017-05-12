#!/usr/bin/perl -w -I./t
# loads of execute_array and execute_for_fetch tests using DBI's methods

use Test::More;
use strict;
#use Data::Dumper;

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

diag("\n\nNOTE: This tests execute_array and execute_for_fetch using DBI's version and not the native DBD::ODBC execute_for_fetch. It should work as it is using nothing special in DBD::ODBC other than the normal methods.");
$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
note("Using driver $dbh->{Driver}->{Name}");

$ea = ExecuteArray->new($dbh, 1); # set odbc_disable_array_operations
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

$ea->error($dbh, {array_context => 1, raise => 1, notuplestatus => 1});
$ea->error($dbh, {array_context => 0, raise => 1, notuplestatus => 1});
$ea->error($dbh, {array_context => 1, raise => 0, notuplestatus => 1});
$ea->error($dbh, {array_context => 0, raise => 0, notuplestatus => 1});
