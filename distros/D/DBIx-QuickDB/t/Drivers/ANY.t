use Test2::V0;
use Test2::Tools::QuickDB;

use List::Util qw/shuffle/;

my @drivers = shuffle qw/MySQL PostgreSQL SQLite/;
my %load = (
    MySQL      => [quickdb => 't/schema/mysql.sql'],
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
};

subtest cleanup => sub {
    my $db = get_db {drivers => \@drivers, load_sql => \%load};
    my $dir = $db->dir;
    my $pid = $db->pid;

    ok(-d $dir, "Can see the db dir");

    $db = undef;
    ok(!-d $dir, "Cleaned up the dir when done");
};

done_testing;
