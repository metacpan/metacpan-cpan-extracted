package Test::Pool;
BEGIN { $INC{'Test/Pool.pm'} = __FILE__ }

# These pool tests build, clone, start, and stop many servers in sequence. On a
# slow or loaded host (e.g. a CPAN smoke box) the library's default start/stop
# timeouts are too tight and the test spuriously fails. Ask for generous
# timeouts here -- this only affects the test, not normal consumers of the
# library, which keep the default timeouts. Respect any value already set.
#
# Keep the stop grace small. stop() forces a CHECKPOINT first, so a SIGKILL
# cannot corrupt a clone. Some servers (notably PostgreSQL 9.3, which the
# FreeBSD smokers run) intermittently wedge during shutdown under this test's
# rapid start/stop churn -- the postmaster acknowledges the shutdown signal but
# never completes it (no clients connected), so it can only be reaped by the
# eventual SIGKILL. Those stops never finish no matter how long we wait, so a
# large grace just stalls each one for the whole window. A small grace reaps
# them quickly; the start timeout stays generous since startup genuinely needs
# time on a slow host.
BEGIN {
    $ENV{QDB_START_TIMEOUT} = 120 unless defined $ENV{QDB_START_TIMEOUT};
    $ENV{QDB_STOP_GRACE}    = 5   unless defined $ENV{QDB_STOP_GRACE};
}

use Test2::V0 -target => 'DBIx::QuickDB::Pool';
use File::Spec;
use File::Temp qw/tempdir/;
use Time::HiRes qw/time/;
use Capture::Tiny qw/capture/;

# This is only here for developing the test, in most cases the test will be
# called with a driver.
my $caller = caller;
my $driver = $caller ? $caller->DRIVER : 'PostgreSQL';

sub check_cloned {
    my $db = shift;
    return unless -f $db->dir . "/cloned";
    open(my $fh, '<', $db->dir . "/cloned") or die "$!";
    chomp(my $stamp = <$fh>);
    return $stamp;
}

sub alter_cloned {
    my $db = shift;
    my ($delta) = @_;
    return unless -f $db->dir . "/cloned";

    my $stamp = check_cloned($db);
    $stamp += $delta;

    open(my $fh, '>', $db->dir . "/cloned") or die "$!";
    print $fh $stamp, "\n";
    1;
}

# Compare result rows by their test_val column (in order) without asserting the
# absolute test_id values. A PostgreSQL crash recovery -- e.g. after a slow host
# blew the watcher's shutdown grace period and the server was SIGKILLed --
# advances a SERIAL sequence by up to SEQ_LOG_VALS (32), so test_id is not
# deterministic across runs. We still require the ids to be present, positive,
# and strictly increasing in the requested order.
sub check_rows {
    my ($got, $expect_vals, $name) = @_;

    my @vals = map { $_->{test_val} } @$got;
    my $vals_ok = is(\@vals, $expect_vals, $name);

    my $ids_ok = 1;
    my $prev;
    for my $row (@$got) {
        my $id = $row->{test_id};
        unless (defined($id) && $id =~ /^\d+$/ && $id > 0 && (!defined($prev) || $id > $prev)) {
            $ids_ok = 0;
            last;
        }
        $prev = $id;
    }
    ok($ids_ok, "$name (test_ids present, positive, strictly increasing)")
        or diag("test_ids: " . join(', ', map { defined $_->{test_id} ? $_->{test_id} : 'undef' } @$got));

    return $vals_ok && $ids_ok;
}

# Diagnostics for the intermittent freebsd/PostgreSQL-9.3 failure where a clone
# that started fine is dead by the time we connect to it. Dumps everything we
# can about a db -- socket/pid liveness and, crucially, the server's own log --
# to STDERR so it shows up in CPAN smoke reports. Best-effort; never dies.
sub qdb_diag {
    my ($db, $label) = @_;
    return unless $db;

    my @out = ("==== QDB-DIAG [$label] pid=$$ ====");

    my $dir  = eval { $db->dir };
    push @out, "  dir: " . (defined $dir ? $dir : '?');

    my $sock = eval { $db->socket };
    push @out, "  socket: " . (defined $sock ? $sock : '?')
        . " exists=" . (defined $sock && -e $sock ? 1 : 0)
        . " is_socket=" . (defined $sock && -S $sock ? 1 : 0);

    push @out, "  started(): " . (eval { $db->started } ? 1 : 0);

    my $w = $db->{ +DBIx::QuickDB::Driver::WATCHER() };
    if ($w) {
        my $spid = eval { $w->server_pid };
        push @out, "  server_pid: " . (defined $spid ? $spid : '?')
            . " alive=" . (defined $spid && kill(0, $spid) ? 1 : 0);
    }
    else {
        push @out, "  watcher: none (object thinks it is stopped)";
    }

    my $log = eval { $db->error_log };
    if ($log && -f $log) {
        open(my $fh, '<', $log) or push(@out, "  error.log: open failed: $!");
        if ($fh) {
            my @l = <$fh>;
            close($fh);
            @l = @l[-25 .. -1] if @l > 25;
            push @out, "  --- $log (last " . scalar(@l) . " lines) ---";
            for my $line (@l) { chomp $line; push @out, "    | $line" }
        }
    }
    else {
        push @out, "  error.log: " . (defined $log ? "$log (missing)" : 'n/a');
    }

    my $ipcs = eval { `ipcs -m 2>/dev/null | wc -l` };
    my $ipss = eval { `ipcs -s 2>/dev/null | wc -l` };
    chomp($ipcs) if defined $ipcs;
    chomp($ipss) if defined $ipss;
    push @out, "  ipcs shmem-lines=" . (defined $ipcs ? $ipcs : '?')
        . " sem-lines=" . (defined $ipss ? $ipss : '?');

    print STDERR join("\n", @out), "\n";
    return;
}

# Wrap a connect; on failure dump diagnostics for the db, its sibling, and the
# sources it was cloned from, then rethrow so the test still fails.
sub diag_connect {
    my ($db, $label, @others) = @_;
    my $dbh;
    return $dbh if eval { $dbh = $db->connect(); 1 };
    my $err = $@;
    print STDERR "==== QDB-DIAG connect FAILED for [$label]: $err\n";
    qdb_diag($db, $label);
    qdb_diag($_->[1], $_->[0]) for @others;

    # Global snapshot: which postgres processes are alive (orphans?), and the
    # System V IPC objects in play -- the prime suspect for this 9.3 race.
    my $ps = eval { `ps -axww 2>/dev/null | grep '[p]ostgres'` };
    print STDERR "==== QDB-DIAG postgres processes ====\n", (length($ps // '') ? $ps : "  (none)\n");
    my $ipcs = eval { `ipcs -a 2>/dev/null` };
    print STDERR "==== QDB-DIAG ipcs -a ====\n", (length($ipcs // '') ? $ipcs : "  (none)\n");

    die $err;
}

ok($driver, "Got a driver ($driver)") or die "Cannot continue without a driver";

use Test2::Tools::QuickDB qw/skipall_on_resource_error/;
use DBIx::QuickDB::Pool cache_dir => tempdir(CLEANUP => 1), verbose => 0;

# db() that builds/clones a new server can fail on a host out of System V IPC at
# any point in the run, not just the very first build. Wrap the new-server
# allocations so such a host skips (environment limit) instead of failing; any
# other error is rethrown.
sub db_or_skip {
    my @out;
    my $ok = eval { @out = db(@_); 1 };
    return wantarray ? @out : $out[0] if $ok;
    my $err = $@;
    skipall_on_resource_error($err);
    die $err;
}
is(\@Test::Pool::EXPORT_OK, ['db'], "Added db to export_ok");

isa_ok(QDB_POOL(), [$CLASS], "We have access to the $CLASS instance");
can_ok(
    QDB_POOL(),
    [qw/library verbose set_verbose update_checksums set_update_checksums purge_old set_purge_old/],
    "Accessors are as expected"
);
is(QDB_POOL()->library, __PACKAGE__, "Set the library");

driver $driver => (
    driver_args => { $caller && $caller->can('DBD_DRIVER') ? (dbd_driver => $caller->DBD_DRIVER) : () },
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
        check_rows($all, ['base'], "Got the inserted row");
    },
);

my $start = time();
# This is the first server built from scratch (initdb + start). On a smoke host
# already out of System V semaphores/shared memory it fails right here; treat
# that as a skip (environment limit), not a failure. Any other error is real.
my $base = eval { db($driver) };
if (my $err = $@) {
    skipall_on_resource_error($err);
    die $err;
}
my $total = time() - $start;
note(sprintf("Initialized DB from scratch in %.6f seconds", $total));

my $ddb = delete QDB_POOL->{databases}->{$driver}->{db};
QDB_POOL->clear_old_cache(500);
ok(-d $ddb->dir, "Did not Delete the directory when expiring cache");
alter_cloned($ddb, -1000);
QDB_POOL->clear_old_cache(500);
my $dir = $ddb->dir;
ok(!-d $dir, "Deleted the directory when expiring cache");
ok(!-e "$dir.READY", "Deleted the READY file when expiring cache");
ok(!-e "$dir.lock", "Deleted the lock when expiring cache");

$base = db_or_skip($driver);
my $stamp = check_cloned(QDB_POOL->{databases}->{$driver}->{db});

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
        check_rows($all, ['base', 'foo'], "Got the inserted row");

        $called++;
    },
);

$start = time();
my $foo1 = db_or_skip('foo');
$total = time() - $start;
note(sprintf("Initialized 'foo' from $driver in %.6f seconds", $total));
isnt($foo1->dir, QDB_POOL()->{databases}->{foo}->{dir}, "The copy does not have the original data dir");
isnt($stamp, check_cloned(QDB_POOL->{databases}->{$driver}->{db}), "clone stamp changed");

$start = time();
my $foo2 = db_or_skip('foo');
$total = time() - $start;
note(sprintf("Initialized 'foo2' from cache in %.6f seconds", $total));

is($called, 1, "Only called the builder once");
ref_is_not($foo1, $foo2, "Each 'foo' is a clone, not the same ref");
isnt($foo1->dir, $foo2->dir, "Both instances have different directories");

ok(!QDB_POOL()->{databases}->{foo}->{db}->started, "The original 'foo' is stopped")
    unless $driver eq 'SQLite' || $driver eq 'DuckDB';

my $foo_src  = QDB_POOL()->{databases}->{foo}->{db};
my $base_src = QDB_POOL()->{databases}->{$driver}->{db};
my $fooh1 = diag_connect($foo1, 'foo1', ['foo2', $foo2], ['foo source', $foo_src], ['base source', $base_src]);
my $fooh2 = diag_connect($foo2, 'foo2', ['foo1', $foo1], ['foo source', $foo_src], ['base source', $base_src]);

ok($fooh1->do("INSERT INTO quick_test(test_val) VALUES('foo 1')"), "Insert success (foo 1)");
ok($fooh2->do("INSERT INTO quick_test(test_val) VALUES('foo 2')"), "Insert success (foo 2)");

my $sth_f1 = $fooh1->prepare('SELECT * FROM quick_test ORDER BY test_id');
$sth_f1->execute();
check_rows(
    $sth_f1->fetchall_arrayref({}),
    ['base', 'foo', 'foo 1'],
    "Got only the row for foo 1"
);

my $sth_f2 = $fooh2->prepare('SELECT * FROM quick_test ORDER BY test_id');
$sth_f2->execute();
check_rows(
    $sth_f2->fetchall_arrayref({}),
    ['base', 'foo', 'foo 2'],
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
        check_rows($all, ['base', 'foo', 'bar'], "Got the inserted row");
    },
);

$start = time();
my $bar = db_or_skip('bar');
$total = time() - $start;
note(sprintf("Initialized 'bar' from 'foo' in %.6f seconds", $total));

subtest resync => sub {
    my $bar = db_or_skip('bar');

    my $dbh = $bar->connect;

    ok($dbh->do("INSERT INTO quick_test(test_val) VALUES('XXX')"), "Insert success");

    my $sth = $dbh->prepare('SELECT * FROM quick_test ORDER BY test_id');
    $sth->execute();
    my $all = $sth->fetchall_arrayref({});
    check_rows($all, ['base', 'foo', 'bar', 'XXX'], "Got the inserted row");

    $dbh->disconnect;

    $bar->resync;

    $dbh = $bar->connect;
    $sth = $dbh->prepare('SELECT * FROM quick_test ORDER BY test_id');
    $sth->execute();
    $all = $sth->fetchall_arrayref({});
    check_rows($all, ['base', 'foo', 'bar'], "Inserted row is gone");
};

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
    my $x = db_or_skip('bar');
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

    my $x = db_or_skip('bar');

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
    ok(db_or_skip('bar'), "Got bar");
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

subtest instance_dir => sub {
    my $instdir = tempdir(CLEANUP => 1);
    my $one     = $CLASS->new(cache_dir => tempdir(CLEANUP => 1), instance_dir => $instdir);

    $one->add_driver(
        $driver => (
            name => 'xyz',
            driver_args => {$caller && $caller->can('DBD_DRIVER') ? (dbd_driver => $caller->DBD_DRIVER) : ()},
            build       => sub {
                my $class = shift;
                my ($db) = @_;

                $db->load_sql(quickdb => lc("t/schema/$driver.sql"));

                my $dbh = $db->connect;
                isa_ok($dbh, ['DBI::db'], "Connected");

                ok($dbh->do("INSERT INTO quick_test(test_val) VALUES('base')"), "Insert success");

                my $sth = $dbh->prepare('SELECT * FROM quick_test WHERE test_val = ?');
                $sth->execute('base');
                my $all = $sth->fetchall_arrayref({});
                check_rows($all, ['base'], "Got the inserted row");
            },
        )
    );

    my $db = eval { $one->fetch_db('xyz') };
    if (my $err = $@) { skipall_on_resource_error($err); die $err }
    opendir(my $dh, $instdir) or die "Could not open dir: $!";

    my $found = 0;
    for my $path (readdir($dh)) {
        my $user = $ENV{USER} // $ENV{USERNAME} // 'quickdb';
        next unless $path =~ m/^\Q$user\E-.*$/;
        is(File::Spec->canonpath("$instdir/$path"), File::Spec->canonpath($db->dir), "Database was stored in the instance dir");
        $found++;
    }

    is($found, 1, "Found exactly 1 data dir");
};

# If run directly
done_testing() unless $caller;

1;
