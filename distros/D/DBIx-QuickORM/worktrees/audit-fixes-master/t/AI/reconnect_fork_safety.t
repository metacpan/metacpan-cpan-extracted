use Test2::V0;
use DBI;
use POSIX qw/_exit/;
use File::Temp qw/tempdir/;

# Regression: post-fork reconnect() must NOT issue an explicit disconnect on
# the handle inherited from the parent. InactiveDestroy suppresses only the
# implicit disconnect at DESTROY, not an explicit disconnect(), which would
# send a protocol-level terminate over the socket the child shares with the
# parent and tear down the parent's session. (Harmless for file-backed SQLite,
# but the code path is what we assert.)

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/fork.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY)');
    $dbh->disconnect;
}

subtest post_fork_reconnect_keeps_inherited_handle => sub {
    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    $con->handle('t')->count;    # force a real dbh to exist before the fork

    my $pid = fork;
    defined($pid) or skip_all "fork() is not available";
    if (!$pid) {
        # Child: reconnect() sees pid != $$ and must leave the inherited handle
        # connected (only marking InactiveDestroy), not disconnect it.
        my $old = $con->dbh;
        $con->reconnect;
        my $pass = ($old->{Active} && $old->{InactiveDestroy}) ? 0 : 1;
        _exit($pass);
    }

    waitpid($pid, 0);
    is($? >> 8, 0, "inherited handle stays connected (InactiveDestroy set, no explicit disconnect)");
};

subtest same_process_reconnect_disconnects => sub {
    my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    $con->handle('t')->count;
    my $old = $con->dbh;

    $con->reconnect;

    ok(!$old->{Active}, "same-process reconnect disconnects the old handle cleanly");
    ok($con->dbh->{Active}, "and the connection has a fresh live handle");
};

done_testing;
