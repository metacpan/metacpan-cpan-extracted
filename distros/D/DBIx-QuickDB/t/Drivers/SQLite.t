use Test2::V0 -target => DBIx::QuickDB::Driver::SQLite;
use Test2::Tools::QuickDB;

# Contaminate the ENV vars to make sure things work even when these are all
# set.
BEGIN { $ENV{$_} = 'fake' for qw{DBI_USER DBI_PASS DBI_DSN} }

skipall_unless_can_db(driver => 'SQLite');

subtest use_it => sub {
    my $db = get_db db => {driver => 'SQLite', load_sql => [quickdb => 't/schema/sqlite.sql']};
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
    my $db = get_db {driver => 'SQLite', load_sql => [quickdb => 't/schema/sqlite.sql']};
    my $dir = $db->dir;

    ok(-d $dir, "Can see the db dir");

    $db = undef;

    my $start = time;
    my $dir_gone = 0;
    while (1) {
        $dir_gone ||= !-d $dir;
        last if $dir_gone;
        last if time - $start > 10;
        sleep 0.2;
    }

    ok($dir_gone, "Cleaned up the dir when done");
};

ok(!(grep { $ENV{$_} ne 'fake' } qw/DBI_USER DBI_PASS DBI_DSN/), "All DBI env vars were restored");

done_testing;
