use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# reconnect() drops the async/aside/fork registries (those queries ran on the
# now-dead handle, or hold their own private connections from the pre-reconnect
# state). A statement handle that survives the reconnect still tries to clear
# itself from the connection as it finalizes. Those clear_* calls must be
# tolerant of the wiped registry rather than croaking.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $file = "$dir/reconnect_clear.sqlite";
my $dsn  = "dbi:SQLite:dbname=$file";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE users (user_id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

# Stand-ins for surviving statement handles. clear_async/clear_aside/clear_fork
# only do registry bookkeeping (a lookup/compare and a delete); they never call
# methods on the handle, so a bare blessed ref is enough. Strong refs are held
# so the weakened registry entries do not vanish before reconnect.
my $async = bless {}, 'My::Surviving::Handle';
my $aside = bless {}, 'My::Surviving::Handle';
my $fork  = bless {}, 'My::Surviving::Handle';

$con->set_async($async);
$con->add_aside($aside);
$con->add_fork($fork);

$con->reconnect;

ok(lives { $con->clear_async($async) }, "clear_async is a no-op after reconnect wiped the async registry")
    or diag($@);
ok(lives { $con->clear_aside($aside) }, "clear_aside is a no-op after reconnect wiped the aside registry")
    or diag($@);
ok(lives { $con->clear_fork($fork) }, "clear_fork is a no-op after reconnect wiped the fork registry")
    or diag($@);

done_testing;
