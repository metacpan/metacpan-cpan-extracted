#!perl
use strict;
use warnings;

use DBI;
use DBIx::Timeout;

# try to make a connection to the test DB - skip all if not available
{
    my $dbh = _dbi_connect();

    if ($@ or !$dbh) {
        eval 'use Test::More skip_all => '
          . '"Unable to run live MySQL tests - '
          . 'set DBI_DSN, DBI_USER and DBI_PASS and try again."';
        die $@ if $@;
    } else {
        eval 'use Test::More qw(no_plan)';
        die $@ if $@;
    }

    ok($dbh, 'connected to MySQL');

}

{
    my $dbh = _dbi_connect();

    # make a second connect to use for locks
    my $lock_dbh = _dbi_connect();
    ok($lock_dbh, 'made second connection');

    # take out a lock, for use with timeouts
    ok( $lock_dbh->selectrow_array("SELECT GET_LOCK('timeout_test', 0)"),
        'got lock on timeout_test');

    # this call must timeout
    my $start = time;
    my $ok = DBIx::Timeout->call_with_timeout(
        dbh  => $dbh,
        code => sub {
            $dbh->do("DO GET_LOCK('timeout_test', 5)");
        },
        timeout => 1);

    # check the result returned and the time it took
    is($ok, 0, "timeout worked");
    ok(time - $start < 5, "timeout worked - it didn't take 5 seconds");
}

{
    my $dbh = _dbi_connect();

    # make a second connect to use for locks
    my $lock_dbh = _dbi_connect();
    ok($lock_dbh, 'made second connection');

    # take out a lock, for use with timeouts
    ok( $lock_dbh->selectrow_array("SELECT GET_LOCK('timeout_test', 0)"),
        'got lock on timeout_test');

    # this call should not timeout
    my $start = time;
    my $ok = DBIx::Timeout->call_with_timeout(
        dbh  => $dbh,
        code => sub {
            $dbh->do("DO GET_LOCK('timeout_test', 3)");
        },
        timeout => 10);

    # check the result returned and the time it took
    is($ok, 1, "timeout didn't fire");
    ok( time - $start >= 3,
        "timeout didn't fire - it between 3 and 10 seconds");
    ok( time - $start <= 10,
        "timeout didn't fire - it between 3 and 10 seconds");
}

sub _dbi_connect {
    my $test_dsn  = $ENV{'DBI_DSN'}  || 'DBI:mysql:database=test';
    my $test_user = $ENV{'DBI_USER'} || '';
    my $test_pass = $ENV{'DBI_PASS'} || '';

    return DBI->connect($test_dsn, $test_user, $test_pass, {RaiseError => 1});
}
