use Test2::V0 -target => DBIx::QuickDB::Driver::PostgreSQL;
use Test2::Tools::QuickDB;

my @ENV_VARS;

# Contaminate the ENV vars to make sure things work even when these are all
# set.
BEGIN {
    @ENV_VARS = qw{
        DBI_USER DBI_PASS DBI_DSN
        PGAPPNAME PGCLIENTENCODING PGCONNECT_TIMEOUT PGDATABASE PGDATESTYLE
        PGGEQO PGGSSLIB PGHOST PGHOSTADDR PGKRBSRVNAME PGLOCALEDIR PGOPTIONS
        PGPASSFILE PGPASSWORD PGPORT PGREQUIREPEER PGREQUIRESSL PGSERVICE
        PGSERVICEFILE PGSSLCERT PGSSLCOMPRESSION PGSSLCRL PGSSLKEY PGSSLMODE
        PGSSLROOTCERT PGSYSCONFDIR PGTARGETSESSIONATTRS PGTZ PGUSER
    };
    $ENV{$_} = 'fake' for @ENV_VARS;
}

skipall_unless_can_db('PostgreSQL');

subtest use_it => sub {
    my $db = get_db db => {driver => 'PostgreSQL', load_sql => [quickdb => 't/schema/postgresql.sql'], verbose => 0};
    isa_ok($db, [$CLASS], "Got a database of the right type");

    is(get_db_or_skipall('db'), exact_ref($db), "Cached the instance by name");

    my $dbh = $db->connect;
    isa_ok($dbh, ['DBI::db'], "Connected");

    ok($dbh->do("INSERT INTO quick_test(test_val) VALUES('foo')"), "Insert success");

    my $sth = $dbh->prepare('SELECT * FROM quick_test WHERE test_val = ?');
    $sth->execute('foo');
    my $all = $sth->fetchall_arrayref({});
    is(
        $all,
        [{test_val => 'foo', test_id => 1}],
        "Got the inserted row"
    );

    $dbh->disconnect;
    $db->stop;
    my $clone = $db->clone;
    my $dbh2 = $clone->connect;
    my $sth2 = $dbh2->prepare('UPDATE quick_test SET test_val = ? WHERE test_id = ?');
    $sth2->execute('bar', 1);

    $sth2 = $dbh2->prepare('SELECT * FROM quick_test WHERE test_val = ?');
    $sth2->execute('bar');
    $all = $sth2->fetchall_arrayref({});
    is(
        $all,
        [{test_val => 'bar', test_id => 1}],
        "Cloned db was changed"
    );

    $db->start;
    $dbh = $db->connect;
    $sth = $dbh->prepare('SELECT * FROM quick_test WHERE test_id = ?');
    $sth->execute(1);
    $all = $sth->fetchall_arrayref({});
    is(
        $all,
        [{test_val => 'foo', test_id => 1}],
        "Original DB not changed"
    );
};

subtest cleanup => sub {
    my $db = get_db {driver => 'PostgreSQL', load_sql => [quickdb => 't/schema/postgresql.sql']};
    my $dir = $db->dir;
    my $pid = $db->watcher->server_pid;

    ok(-d $dir, "Can see the db dir");
    ok(kill(0, $pid), "Can signal the db process (it's alive!)");

    $db = undef;

    my $start = time;
    my $pid_gone = 0;
    my $dir_gone = 0;
    while (1) {
        $pid_gone ||= !kill(0, $pid);
        $dir_gone ||= !-d $dir;
        last if $pid_gone && $dir_gone;
        last if time - $start > 10;
        sleep 0.2;
    }

    ok($dir_gone, "Cleaned up the dir when done");
    ok($pid_gone, "Cleaned up the process when done");
};

subtest viable => sub {
    my ($v, $why) = $CLASS->viable({initdb => 'a fake path', bootstrap => 1});
    ok(!$v, "Not viable without a valid initdb");

    ($v, $why) = $CLASS->viable({createdb => 'a fake path', bootstrap => 1});
    ok(!$v, "Not viable without a valid createdb");

    ($v, $why) = $CLASS->viable({postgres => 'a fake path', autostart => 1});
    ok(!$v, "Not viable without a valid postgres");

    ($v, $why) = $CLASS->viable({psql => 'a fake path', load_sql => 1});
    ok(!$v, "Not viable without a valid psql");
};

ok(!(grep { $ENV{$_} ne 'fake' } @ENV_VARS), "All DBI/driver specific env vars were restored");

done_testing;
