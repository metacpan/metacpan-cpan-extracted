package Test::Pool;
BEGIN { $INC{'Test/Pool.pm'} = __FILE__ }

use Test2::V0 -target => 'DBIx::QuickDB::Pool';
use File::Temp qw/tempdir/;
use Time::HiRes qw/time/;
use Capture::Tiny qw/capture/;

# This is only here for developing the test, in most cases the test will be
# called with a driver.
my $caller = caller;
my $driver = $caller ? $caller->DRIVER : 'PostgreSQL';

ok($driver, "Got a driver ($driver)") or die "Cannot continue without a driver";

use DBIx::QuickDB::Pool cache_dir => tempdir(CLEANUP => 1), verbose => 0;
is(\@Test::Pool::EXPORT_OK, ['db'], "Added db to export_ok");

isa_ok(QDB_POOL(), [$CLASS], "We have access to the $CLASS instance");
can_ok(
    QDB_POOL(),
    [qw/library verbose set_verbose update_checksums set_update_checksums purge_old set_purge_old/],
    "Accessors are as expected"
);
is(QDB_POOL()->library, __PACKAGE__, "Set the library");

driver $driver => (
    driver_args => { $caller->can('DBD_DRIVER') ? (dbd_driver => $caller->DBD_DRIVER) : () },
    build => sub {
        my $class = shift;
        my ($db) = @_;

        $db->load_sql(quickdb => lc("t/schema/$driver.sql"));

        my $dbh = $db->connect;
        isa_ok($dbh, ['DBI::db'], "Connected");

        ok($dbh->do("INSERT INTO quick_test(test_val) VALUES('base')"), "Insert success");

        my $sth = $dbh->prepare('SELECT * FROM quick_test WHERE test_val = ?');
        $sth->execute('base');
        my $all = $sth->fetchall_arrayref({});
        is(
            $all,
            [{test_val => 'base', test_id => 1}],
            "Got the inserted row"
        );
    },
);

my $start = time();
my $base = db($driver);
my $total = time() - $start;
note(sprintf("Initialized DB from scratch in %.6f seconds", $total));

isa_ok($base, ['DBIx::QuickDB::Driver', "DBIx::QuickDB::Driver::$driver"], "Got the database");

my $called = 0;
our $foo_sum = "a";
build foo => (
    from     => $driver,
    checksum => sub { $foo_sum },

    build => sub {
        my $class = shift;
        my ($db, %params) = @_;
        is($class, __PACKAGE__, "Called as method");
        isa_ok($db, ['DBIx::QuickDB::Driver'], "Got database as first argument");
        ok($db->started, "Already started for us");

        is($params{name}, 'foo', "got name param");
        ok($params{dir}, "Got a dir: $params{dir}");
        ref_is($params{qdb}, QDB_POOL, "Got the pool instance as a param");

        my $dbh = $db->connect;
        isa_ok($dbh, ['DBI::db'], "Connected");

        ok($dbh->do("INSERT INTO quick_test(test_val) VALUES('foo')"), "Insert success");

        my $sth = $dbh->prepare('SELECT * FROM quick_test ORDER BY test_id');
        $sth->execute();
        my $all = $sth->fetchall_arrayref({});
        is(
            $all,
            [
                {test_val => 'base', test_id => 1},
                {test_val => 'foo',  test_id => 2},
            ],
            "Got the inserted row"
        );

        $called++;
    },
);

$start = time();
my $foo1 = db('foo');
$total = time() - $start;
note(sprintf("Initialized 'foo' from $driver in %.6f seconds", $total));
isnt($foo1->dir, QDB_POOL()->{databases}->{foo}->{dir}, "The copy does not have the original data dir");

$start = time();
my $foo2 = db('foo');
$total = time() - $start;
note(sprintf("Initialized 'foo2' from cache in %.6f seconds", $total));

is($called, 1, "Only called the builder once");
ref_is_not($foo1, $foo2, "Each 'foo' is a clone, not the same ref");
isnt($foo1->dir, $foo2->dir, "Both instances have different directories");

ok(!QDB_POOL()->{databases}->{foo}->{db}->started, "The original 'foo' is stopped")
    unless $driver eq 'SQLite';

my $fooh1 = $foo1->connect();
my $fooh2 = $foo2->connect();

ok($fooh1->do("INSERT INTO quick_test(test_val) VALUES('foo 1')"), "Insert success (foo 1)");
ok($fooh2->do("INSERT INTO quick_test(test_val) VALUES('foo 2')"), "Insert success (foo 2)");

my $sth_f1 = $fooh1->prepare('SELECT * FROM quick_test ORDER BY test_id');
$sth_f1->execute();
is(
    $sth_f1->fetchall_arrayref({}),
    [
        {test_val => 'base',  test_id => 1},
        {test_val => 'foo',   test_id => 2},
        {test_val => 'foo 1', test_id => 3},
    ],
    "Got only the row for foo 1"
);

my $sth_f2 = $fooh2->prepare('SELECT * FROM quick_test ORDER BY test_id');
$sth_f2->execute();
is(
    $sth_f2->fetchall_arrayref({}),
    [
        {test_val => 'base',  test_id => 1},
        {test_val => 'foo',   test_id => 2},
        {test_val => 'foo 2', test_id => 3},
    ],
    "Got only the row for foo 2"
);

build bar => (
    from     => 'foo',
    checksum => sub { "salright" },

    build => sub {
        my $class = shift;
        my ($db, %params) = @_;

        my $dbh = $db->connect;

        ok($dbh->do("INSERT INTO quick_test(test_val) VALUES('bar')"), "Insert success");

        my $sth = $dbh->prepare('SELECT * FROM quick_test ORDER BY test_id');
        $sth->execute();
        my $all = $sth->fetchall_arrayref({});
        is(
            $all,
            [
                {test_val => 'base', test_id => 1},
                {test_val => 'foo',  test_id => 2},
                {test_val => 'bar',  test_id => 3},
            ],
            "Got the inserted row"
        );
    },
);

$start = time();
my $bar = db('bar');
$total = time() - $start;
note(sprintf("Initialized 'bar' from 'foo' in %.6f seconds", $total));

subtest checksum_change_update => sub {
    QDB_POOL->set_update_checksums(1);

    my $c = $called + 1;
    my $cached = {
        $driver => "" . QDB_POOL->{databases}->{$driver}->{db},
        foo => "" . QDB_POOL->{databases}->{foo}->{db},
        bar => "" . QDB_POOL->{databases}->{bar}->{db},
    };

    $foo_sum++;

    $start = time;
    my $x = db('bar');
    $total = time - $start;
    note(sprintf("Re-Initialized 'foo' and 'bar' from $driver in %.6f seconds", $total));

    is($called, $c, "Called the foo builder again");
    is(QDB_POOL->{databases}->{$driver}->{db}, $cached->{$driver}, "Base db did not change");
    isnt(QDB_POOL->{databases}->{foo}->{db}, $cached->{foo}, "foo was rebuilt");
    isnt(QDB_POOL->{databases}->{bar}->{db}, $cached->{bar}, "bar was rebuilt");
};

subtest checksum_change_no_update => sub {
    QDB_POOL->set_update_checksums(0);

    my $c = $called;
    my $cached = {
        $driver => "" . QDB_POOL->{databases}->{$driver}->{db},
        foo => "" . QDB_POOL->{databases}->{foo}->{db},
        bar => "" . QDB_POOL->{databases}->{bar}->{db},
    };

    local $foo_sum = $foo_sum;
    $foo_sum++;

    my $x = db('bar');

    is($called, $c, "Did not call foo builder again");
    is(QDB_POOL->{databases}->{$driver}->{db}, $cached->{$driver}, "Base db did not change");
    is(QDB_POOL->{databases}->{foo}->{db}, $cached->{foo}, "foo was not rebuilt");
    is(QDB_POOL->{databases}->{bar}->{db}, $cached->{bar}, "bar was not rebuilt");
};

# This test removes all instances of the databases, even the root copies, they
# should spin back up super fast using the cached directories
subtest reclaim => sub {
    $base   = undef;
    $sth_f1 = undef;
    $sth_f2 = undef;
    $fooh1  = undef;
    $fooh2  = undef;
    $foo1   = undef;
    $foo2   = undef;
    $bar    = undef;

    for my $spec (values %{QDB_POOL()->{databases}}) {
        delete $spec->{db};
        delete $spec->{dir};
        delete $spec->{built_checksum};
    }

    $start = time();
    ok(db('bar'), "Got bar");
    $total = time() - $start;
    note(sprintf("Initialized 'bar' from reclaiming the entire chain in %.6f seconds", $total));
};

subtest init => sub {
    like(
        dies { $CLASS->new() },
        qr/'cache_dir' is a required_attribute/,
        "Need a cache_dir"
    );

    like(
        dies { $CLASS->new(cache_dir => ':::SOMETHING FAKE') },
        qr/'cache_dir' must point to an existing directory/,
        "Need a cache_dir to be valid"
    );

    my $one = $CLASS->new(cache_dir => tempdir(CLEANUP => 1));
    isa_ok($one, [$CLASS], "Created an instance");
    like(
        $one,
        {
            library          => __PACKAGE__,
            verbose          => 0,
            purge_old        => 0,
            update_checksums => 1,
            databases        => {},
        },
        "Set attributes"
    );
};

subtest export => sub {
    my $one = $CLASS->new(cache_dir => tempdir(CLEANUP => 1), library => 'Fake::Export::Lib');
    $one->export;
    {
        package Fake::Export::Lib;
        use Test2::Tools::Exports;
        imported_ok(qw/QDB_POOL driver build db/, '@EXPORT_OK');
    }

    ref_is(Fake::Export::Lib->QDB_POOL, $one, "Same instance");
    is(\@Fake::Export::Lib::EXPORT_OK, ['db'], "Can re-export db()");
};

subtest throw => sub {
    my $one = $CLASS->new(cache_dir => tempdir(CLEANUP => 1));

    my $line;
    my $throw = sub { $one->throw('haha') };
    is(
        dies { $line = __LINE__; $throw->() },
        "haha at ${ \__FILE__ } line $line.\n",
        "Throw without a caller figures it out."
    );

    is(
        dies { $one->throw("haha", caller => ['Foo::Bar', 'Foo/Bar.pm', 42]) },
        "haha at Foo/Bar.pm line 42.\n",
        "Throw uses caller if provided"
    );
};

subtest alert => sub {
    my $one = $CLASS->new(cache_dir => tempdir(CLEANUP => 1));

    my $line;
    my $alert = sub { $one->alert('haha') };
    is(
        warning { $line = __LINE__; $alert->() },
        "haha at ${ \__FILE__ } line $line.\n",
        "Alert without a caller figures it out."
    );

    is(
        warning { $one->alert("haha", caller => ['Foo::Bar', 'Foo/Bar.pm', 42]) },
        "haha at Foo/Bar.pm line 42.\n",
        "Alert uses caller if provided"
    );
};

subtest diag => sub {
    my $one = $CLASS->new(cache_dir => tempdir(CLEANUP => 1));

    like(
        [capture { $one->diag("haha") }],
        ["", ""],
        "No output, not verbose"
    );

    $one->set_verbose(1);
    like(
        [capture { $one->diag("haha") }],
        ["haha\n", ""],
        "Output to STDOUT"
    );

    $one->set_verbose(2);
    like(
        [capture { $one->diag("haha") }],
        ["", "haha\n"],
        "Output to STDERR"
    );

    $one->set_verbose(1);
    like(
        [capture { $one->diag("haha", caller => ['Foo::Bar', 'Foo/Bar.pm', 42]) }],
        ["haha at Foo/Bar.pm line 42.\n", ""],
        "Output with caller"
    );
};

# If run directly
done_testing() unless $caller;

1;
