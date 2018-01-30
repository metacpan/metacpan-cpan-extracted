use Test2::V0 -target => DBIx::QuickDB::Driver::MySQL;
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

subtest use_it => sub {
    my $db = get_db db => {driver => 'MySQL', load_sql => [quickdb => 't/schema/mysql.sql']};
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
};

subtest cleanup => sub {
    my $db = get_db {driver => 'MySQL', load_sql => [quickdb => 't/schema/mysql.sql']};
    my $dir = $db->dir;
    my $pid = $db->pid;

    ok(-d $dir, "Can see the db dir");
    ok(kill(0, $pid), "Can signal the db process (it's alive!)");

    $db = undef;
    ok(!-d $dir, "Cleaned up the dir when done");
    is(kill(0, $pid), 0, "cannot singal pid (It's dead Jim)");
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
