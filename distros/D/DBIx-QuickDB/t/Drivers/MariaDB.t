use Test2::V0 -target => DBIx::QuickDB::Driver::MySQL;
use Test2::Require::Module 'DBD::MariaDB';
use Test2::Tools::QuickDB;

my @ENV_VARS;

# Contaminate the ENV vars to make sure things work even when these are all
# set.
BEGIN {
    @ENV_VARS = qw{
        DBI_USER DBI_PASS DBI_DSN
        LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN LIBMYSQL_PLUGINS
        LIBMYSQL_PLUGIN_DIR MYSQLX_TCP_PORT MYSQLX_UNIX_PORT MYSQL_DEBUG
        MYSQL_GROUP_SUFFIX MYSQL_HISTFILE MYSQL_HISTIGNORE MYSQL_HOME
        MYSQL_HOST MYSQL_OPENSSL_UDF_DH_BITS_THRESHOLD
        MYSQL_OPENSSL_UDF_DSA_BITS_THRESHOLD
        MYSQL_OPENSSL_UDF_RSA_BITS_THRESHOLD MYSQL_PS1 MYSQL_PWD
        MYSQL_SERVER_PREPARE MYSQL_TCP_PORT MYSQL_TEST_LOGIN_FILE
        MYSQL_TEST_TRACE_CRASH MYSQL_TEST_TRACE_DEBUG MYSQL_UNIX_PORT
    };
    $ENV{$_} = 'fake' for @ENV_VARS;
}

skipall_unless_can_db('MySQL');

{
    local $@;
    eval { require DBD::mysql };
    no warnings 'redefine';
    *DBD::mysql::dr::connect = sub { die "Should not be using me!" };
}

subtest use_it => sub {
    my $db = get_db db => {driver => 'MySQL', dbd_driver => 'DBD::MariaDB', load_sql => [quickdb => 't/schema/mysql.sql']};
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
    my $db = get_db {driver => 'MySQL', dbd_driver => 'DBD::MariaDB', load_sql => [quickdb => 't/schema/mysql.sql']};
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
    my ($v, $why) = $CLASS->viable({mysqld => 'a fake path', bootstrap => 1});
    ok(!$v, "Not viable without a valid mysqld");

    ($v, $why) = $CLASS->viable({mysqld => 'a fake path', autostart => 1});
    ok(!$v, "Not viable without a valid mysqld");

    ($v, $why) = $CLASS->viable({mysql => 'a fake path', load_sql => 1});
    ok(!$v, "Not viable without a valid mysql");
};

ok(!(grep { $ENV{$_} ne 'fake' } @ENV_VARS), "All DBI/driver specific env vars were restored");

done_testing;
