#!perl

use Test::More;
use DBIx::TryAgain;

use DBD::SQLite;
use File::Temp;
use Data::Dumper;

use strict;

if ($^O =~ /bsd/i) {
    plan skip_all => "Locking on freebsd is unpredictable.";
    exit;
}

my $dbfile = File::Temp->new(UNLINK => 0);
unlink $dbfile;

my $dbh = DBIx::TryAgain->connect("dbi:SQLite:dbname=$dbfile","","", { PrintError => 0 } )
    or die "connect error ".$DBI::errstr;

is $dbh->try_again_max_retries, 5, "got default max retries";
$dbh->try_again_max_retries(3);
is $dbh->try_again_max_retries, 3, "set max retries to 3";

is $dbh->try_again_algorithm, 'fibonacci', "got default algorithm";
is_deeply $dbh->try_again_on_messages, [ qr/database is locked/i ], 'got default try_again_on_messages';

$dbh->do("create table foo (a int);");

my $locker = DBIx::TryAgain->connect("dbi:SQLite:dbname=$dbfile","","", { PrintError => 0 } );
ok $locker, "connected" or diag $DBI::errstr;

ok $locker->do("PRAGMA locking_mode = EXCLUSIVE"), 'lock' or diag $locker->errstr;
ok $locker->do("BEGIN EXCLUSIVE"), 'begin transaction' or diag $locker->errstr;
ok $locker->do("COMMIT"), 'commit' or diag $locker->errstr;

$dbh->sqlite_busy_timeout(1);

# Now ready to try again :
ok !$dbh->do("insert into foo (a) values (10)"), "do failed";
like ($DBI::errstr, qr/locked/i, "got locked message");

# Some versions fail when preparing, some versions
# fail when executing.
my $sth = $dbh->prepare("select * from foo");

if ($sth) {
    ok $sth, "Prepare succeeded.";
    ok !$sth->execute, "Execute failed";
    like ($sth->errstr, qr/locked/i, "got locked message");

    is $sth->{private_dbix_try_again_tries}, 3, "Tried 3 times";
    is_deeply $sth->{private_dbix_try_again_slept}, [1,1,2], "slept with fibonacci delay";

} else {
    diag "Prepare failed, not retrying prepare in this test.";
}

unlink $dbfile;
done_testing();

