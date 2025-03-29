use Test2::V0;
use Test2::Tools::QuickDB;

use List::Util qw/shuffle/;

BEGIN {
    $ENV{PATH} = "$ENV{HOME}/dbs/mysql8/bin:$ENV{PATH}"    if -d "$ENV{HOME}/dbs/mysql8/bin";
    $ENV{PATH} = "$ENV{HOME}/dbs/percona8/bin:$ENV{PATH}"  if -d "$ENV{HOME}/dbs/percona8/bin";
    $ENV{PATH} = "$ENV{HOME}/dbs/mariadb11/bin:$ENV{PATH}" if -d "$ENV{HOME}/dbs/mariadb11/bin";
}

my @drivers = shuffle qw/MariaDB Percona MySQL AnyMySQL PostgreSQL SQLite/;
my %load    = (
    MariaDB    => [quickdb => 't/schema/mariadb.sql'],
    Percona    => [quickdb => 't/schema/percona.sql'],
    MySQL      => [quickdb => 't/schema/mysql.sql'],
    AnyMySQL   => [quickdb => 't/schema/mysql.sql'],
    PostgreSQL => [quickdb => 't/schema/postgresql.sql'],
    SQLite     => [quickdb => 't/schema/sqlite.sql'],
);

skipall_unless_can_db(\@drivers);

diag("Search order: " . join(', ' => @drivers));

subtest use_it => sub {
    my $db = get_db db => {drivers => \@drivers, load_sql => \%load};
    isa_ok($db, ['DBIx::QuickDB::Driver'], "Got a database of the right type");

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
    my $db = get_db {drivers => \@drivers, load_sql => \%load};
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

done_testing;
