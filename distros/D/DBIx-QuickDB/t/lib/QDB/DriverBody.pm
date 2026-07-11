package QDB::DriverBody;
use strict;
use warnings;

# The shared test body for t/Drivers/*.t, run once per installation by
# QDB::Installs::run_per_install.
#
# ONLY EVER LOAD THIS IN A run_per_install CHILD. It loads
# Test2::Tools::QuickDB, which loads DBIx::QuickDB; loading it in the parent
# would capture the parent's $PATH in driver caches and defeat the
# per-install $PATH handling (see the warning in QDB::Installs).

use Test2::V0;
use Test2::Tools::QuickDB;
use Time::HiRes qw/sleep time/;

use QDB::Installs qw/contaminate_env/;

use Importer Importer => 'import';
our @EXPORT = qw/driver_body/;

sub _no_bins {
    my (@classes) = @_;
    no strict 'refs';
    no warnings 'redefine';
    for my $class (@classes) {
        my $file = $class;
        $file =~ s{::}{/}g;
        require "$file.pm";
        *{"$class\::server_bin"} = sub { undef };
        *{"$class\::client_bin"} = sub { undef };
    }
}

# How to break each driver for the viable() subtest, and what the missing
# binaries are called in the assertion descriptions.
my %PARAMS = (
    MariaDB => {
        schema  => 't/schema/mariadb.sql',
        server  => 1,
        viable  => sub { _no_bins('DBIx::QuickDB::Driver::MariaDB') },
        vnames  => [qw/mariadbd mariadb/],
    },
    MySQL => {
        schema  => 't/schema/mysql.sql',
        server  => 1,
        viable  => sub { _no_bins(map "DBIx::QuickDB::Driver::$_", qw/MariaDB MySQLCom Percona/) },
        vnames  => [qw/mysqld mysql/],
    },
    MySQLCom => {
        schema  => 't/schema/mysqlcom.sql',
        server  => 1,
        viable  => sub { _no_bins('DBIx::QuickDB::Driver::MySQLCom') },
        vnames  => [qw/mysqld mysql/],
    },
    Percona => {
        schema  => 't/schema/percona.sql',
        server  => 1,
        viable  => sub { _no_bins('DBIx::QuickDB::Driver::Percona') },
        vnames  => [qw/mysqld mysql/],
    },
    PostgreSQL => {
        schema       => 't/schema/postgresql.sql',
        server       => 1,
        use_it_extra => {verbose => 0},
        pg_viable    => 1,
    },
    SQLite => {schema => 't/schema/sqlite.sql', server => 0},
    DuckDB => {schema => 't/schema/duckdb.sql', server => 0},
);

sub driver_body {
    my ($driver) = @_;
    my $params = $PARAMS{$driver} or die "No driver body params for '$driver'";
    my $class  = "DBIx::QuickDB::Driver::$driver";

    # Contaminate the env vars the driver is expected to mask, to make sure
    # things work even when these are all set.
    my @env_vars = contaminate_env($driver);

    skipall_unless_can_db($driver);

    subtest use_it => sub {
        my $db = get_db db => {driver => $driver, load_sql => [quickdb => $params->{schema}], %{$params->{use_it_extra} || {}}};
        isa_ok($db, [$class], "Got a database of the right type");

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

        $dbh->disconnect if $params->{server};
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
        my $db = get_db {driver => $driver, load_sql => [quickdb => $params->{schema}]};
        my $dir = $db->dir;
        my $pid = $params->{server} ? $db->watcher->server_pid : undef;

        ok(-d $dir, "Can see the db dir");
        ok(kill(0, $pid), "Can signal the db process (it's alive!)") if $pid;

        $db = undef;

        my $start = time;
        my $pid_gone = $pid ? 0 : 1;
        my $dir_gone = 0;
        while (1) {
            $pid_gone ||= !kill(0, $pid) if $pid;
            $dir_gone ||= !-d $dir;
            last if $pid_gone && $dir_gone;
            last if time - $start > 10;
            sleep 0.2;
        }

        ok($dir_gone, "Cleaned up the dir when done");
        ok($pid_gone, "Cleaned up the process when done") if $pid;
    };

    if ($params->{viable}) {
        subtest viable => sub {
            $params->{viable}->();
            my ($sname, $cname) = @{$params->{vnames}};

            my ($v, $why) = $class->viable({bootstrap => 1});
            ok(!$v, "Not viable without a valid $sname");

            ($v, $why) = $class->viable({autostart => 1});
            ok(!$v, "Not viable without a valid $sname");

            ($v, $why) = $class->viable({load_sql => 1});
            ok(!$v, "Not viable without a valid $cname");
        };
    }
    elsif ($params->{pg_viable}) {
        subtest viable => sub {
            my ($v, $why) = $class->viable({initdb => 'a fake path', bootstrap => 1});
            ok(!$v, "Not viable without a valid initdb");

            ($v, $why) = $class->viable({createdb => 'a fake path', bootstrap => 1});
            ok(!$v, "Not viable without a valid createdb");

            ($v, $why) = $class->viable({postgres => 'a fake path', autostart => 1});
            ok(!$v, "Not viable without a valid postgres");

            ($v, $why) = $class->viable({psql => 'a fake path', load_sql => 1});
            ok(!$v, "Not viable without a valid psql");
        };
    }

    ok(!(grep { $ENV{$_} ne 'fake' } @env_vars), "All DBI/driver specific env vars were restored");

    return;
}

1;
