package DBIx::QuickORM::Test;
use strict;
use warnings;

use Test2::V0 '!meta', '!pass';
use Test2::IPC qw/cull/;
use List::Util qw/first/;
use Time::HiRes qw/sleep/;
use Importer Importer => 'import';

use DBIx::QuickORM::Util qw/debug/;

our @EXPORT = qw{
    psql
    mysql
    mariadb
    percona
    sqlite
    duckdb
    debug

    do_for_all_dbs
    dialect_has_savepoints
    curdb_version
    pg_older_than
    wait_ready
};

use version ();

sub psql     { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'PostgreSQL', fast_destroy => 1, @args}) } or diag(clean_err($@)) }
sub mysql    { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'MySQL', fast_destroy => 1,      @args}) } or diag(clean_err($@)) }
sub mysqlcom { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'MySQLCom', fast_destroy => 1,   @args}) } or diag(clean_err($@)) }
sub mariadb  { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'MariaDB', fast_destroy => 1,    @args}) } or diag(clean_err($@)) }
sub percona  { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'Percona', fast_destroy => 1,    @args}) } or diag(clean_err($@)) }
sub sqlite   { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'SQLite', fast_destroy => 1,     @args}) } or diag(clean_err($@)) }
sub duckdb   { require Test2::Tools::QuickDB; my @args = @_; eval { Test2::Tools::QuickDB::get_db({driver => 'DuckDB', fast_destroy => 1,     @args}) } or diag(clean_err($@)) }

# Static sets that do not live under ~/dbs: the system-installed servers and
# sqlite. These are always offered (and skipped at runtime if unavailable).
my @STATIC_SETS = (
    {name => 'system_postgresql', ver => '', db => \&psql,   dialect => 'PostgreSQL', dbi => ['Pg'],               quickdb => 'PostgreSQL', env => {}},
    {name => 'sqlite',            ver => '', db => \&sqlite, dialect => 'SQLite',     dbi => ['SQLite'],           quickdb => 'SQLite',     env => {}},
    {name => 'duckdb',            ver => '', db => \&duckdb, dialect => 'DuckDB',     dbi => ['DuckDB'],           quickdb => 'DuckDB',     env => {}},
    {name => 'system_mysql',      ver => '', db => \&mysql,  dialect => 'MySQL',      dbi => ['mysql', 'MariaDB'], quickdb => 'MySQL',      env => {}},
);

# The quickdb name of the set currently running under do_for_all_dbs.
our $CURRENT_QDB;

# The full set descriptor currently running under do_for_all_dbs.
our $CURRENT_SET;

# DuckDB has no savepoints, so it cannot run the nested-transaction (savepoint)
# subtests. Tests that exercise nested transactions guard them with this.
sub dialect_has_savepoints { ($CURRENT_QDB // '') ne 'DuckDB' }

# Full version of the ~/dbs set currently running ("9.3.15"), parsed from its
# name, or undef for the static system sets whose name carries no version.
sub curdb_version {
    my $set = $CURRENT_SET or return undef;
    my ($v) = $set->{name} =~ m/-(\d[\d.]*)$/;
    return $v;
}

# True when the running database is a versioned PostgreSQL install older than
# the given major.minor (e.g. pg_older_than('9.5')). The static system
# PostgreSQL set carries no version and is assumed current, so returns false.
sub pg_older_than {
    my ($want) = @_;
    return 0 unless ($CURRENT_QDB // '') eq 'PostgreSQL';
    my $have = curdb_version() or return 0;
    return version->parse("v$have") < version->parse("v$want");
}

# Maps the engine prefix of a "~/dbs/<engine>-<version>" directory to its driver
# metadata. 'server' is the binary that must exist under bin/ for the install to
# count.
my %ENGINE = (
    postgresql => {db => \&psql,     dialect => 'PostgreSQL',       dbi => ['Pg'],               quickdb => 'PostgreSQL', server => 'postgres'},
    mariadb    => {db => \&mariadb,  dialect => 'MySQL::MariaDB',   dbi => ['mysql', 'MariaDB'], quickdb => 'MariaDB',    server => 'mariadbd'},
    mysql      => {db => \&mysqlcom, dialect => 'MySQL::Community', dbi => ['mysql', 'MariaDB'], quickdb => 'MySQLCom',   server => 'mysqld'},
    percona    => {db => \&percona,  dialect => 'MySQL::Percona',   dbi => ['mysql', 'MariaDB'], quickdb => 'Percona',    server => 'mysqld'},
);

# Discover every versioned database install under ~/dbs. Each is a directory
# named "<engine>-<version>" (e.g. postgresql-17.9, mariadb-12.2) holding a bin/
# with the server binary; that bin/ is prepended to PATH so QuickDB boots that
# exact version. 'ver' is the major version, used to pick a version-specific SQL
# schema file (e.g. postgresql17.sql) when one exists, falling back otherwise.
sub discover_db_sets {
    my $root = "$ENV{HOME}/dbs";
    return () unless -d $root;

    opendir(my $dh, $root) or return ();
    my @dirs = readdir($dh);
    closedir($dh);

    my @sets;
    for my $dir (@dirs) {
        next unless $dir =~ m/^([a-z]+)-(\d+(?:\.\d+)*)$/;
        my ($engine, $version) = ($1, $2);
        my $meta = $ENGINE{$engine} or next;

        my $bin = "$root/$dir/bin";
        next unless -d $bin && -x "$bin/$meta->{server}";

        my ($major) = split /\./, $version;

        push @sets => {
            name    => $dir,
            ver     => $major,
            db      => $meta->{db},
            dialect => $meta->{dialect},
            dbi     => $meta->{dbi},
            quickdb => $meta->{quickdb},
            env     => {PATH => "$bin:$ENV{PATH}"},
        };
    }

    # Stable order: engine name, then numeric major, then full dir name.
    return sort {
        my ($ae) = $a->{name} =~ m/^([a-z]+)/;
        my ($be) = $b->{name} =~ m/^([a-z]+)/;
        $ae cmp $be || $a->{ver} <=> $b->{ver} || $a->{name} cmp $b->{name};
    } @sets;
}

my @SETS = (@STATIC_SETS, discover_db_sets());

sub clean_err {
    my $err = shift;

    my @lines = split /\n/, $err;

    my $out = "";
    while (@lines) {
        my $line = shift @lines;
        next unless $line;
        last if $out && $line =~ m{^Aborting at.*DBIx/QuickDB\.pm};

        $out = $out ? "$out\n$line" : $line;
    }

    return $out;
}

# Poll an async/aside/forked object until it reports ready, bounded by a
# timeout so a wedged or never-completing query cannot hang the whole suite.
# Returns whatever ready() returned; bails out (fatal) once the timeout elapses.
sub wait_ready {
    my ($obj, $timeout) = @_;
    $timeout //= 30;

    my $start = time;
    while (1) {
        my $ready = $obj->ready;
        return $ready if $ready;
        bail_out("Timed out after ${timeout}s waiting for an async result to become ready") if time - $start > $timeout;
        sleep 0.1;
    }
}

our $END_DELAY = 0;
sub do_for_all_dbs(&;@) {
    my $code = shift;
    my %only = map { $_ => 1 } @_;
    require Parallel::Runner;
    my $pr = Parallel::Runner->new(
        $ENV{DBIXQORM_TEST_CONCURRENCY} // 4,
        iteration_callback => \&cull,
    );

    my ($pkg, $file, $line) = caller;

    for my $set (@SETS) {
        next if @_ && !$only{$set->{name}};
        for my $dbi (@{$set->{dbi}}) {
            cull();
            $pr->run(sub {
                # Re-seed in the forked child. Test2::V0 seeds srand
                # deterministically (from the date), and fork inherits that
                # state, so sibling children otherwise produce identical
                # File::Temp 'DB-QUICK-XXXX' names -> two databases collide on
                # one temp dir -> initdb / disk I/O failures under concurrency.
                srand();

                subtest "$set->{name} x DBD::$dbi" => sub {
                    local $CURRENT_QDB = $set->{quickdb};
                    local $CURRENT_SET = $set;
                    $ENV{$_} = $set->{env}->{$_} for keys %{$set->{env}};
                    my $qdb = "DBIx::QuickDB::Driver::$set->{quickdb}";
                    my %dbd_args = $dbi =~ m/^(?:mysql|MariaDB)$/ ? (dbd_driver => "DBD::$dbi") : ();
                    my $have_qdb = eval { require "DBIx/QuickDB/Driver/$set->{quickdb}.pm"; my ($v, $why) = $qdb->viable({load_sql => 1, bootstrap => 1, %dbd_args}); $v || die $why } or note $@;
                    my $have_dbi = eval { require "DBD/$dbi.pm"; 1 } or note $@;

                    unless ($have_qdb && $have_dbi) {
                        skip_all "Skipping $set->{name} (DBD::$dbi)...";
                        return;
                    }
                    note "Running $set->{name} (DBD::$dbi)";

                    {
                        no strict 'refs';
                        no warnings 'redefine';
                        *{"$pkg\::curdb"}      = $set->{db};
                        *{"$pkg\::curname"}    = sub { $set->{name} };
                        *{"$pkg\::curdbi"}     = sub { "DBD::$dbi" };
                        *{"$pkg\::curqdb"}     = sub { $set->{quickdb} };
                        *{"$pkg\::curdialect"} = sub { $set->{dialect} };
                    }

                    my $lc_dial = lc($set->{dialect});
                    $lc_dial =~ s/::/_/g;

                    my $prefix;
                    if ($pkg->can('SCHEMA_DIR')) {
                        $prefix = $pkg->SCHEMA_DIR;
                    }
                    else {
                        $prefix = $file;
                        $prefix =~ s{\.t$}{}g;
                    }

                    my $sql_file = "${prefix}/$lc_dial";
                    my @check = ( "${sql_file}$set->{ver}.sql", "${sql_file}.sql" );
                    push @check => "${prefix}/mariadb.sql" if $sql_file =~ m/mariadb/;
                    push @check => "${prefix}/mysql.sql" if $sql_file =~ m/(mysql|mariadb)/;
                    $sql_file = first { -f $_ } @check;
                    my $db;
                    if ($sql_file) {
                        note "Loading SQL file: $sql_file\n";
                        $db = $set->{db}->(%dbd_args, load_sql => [quickdb => $sql_file]);
                    }
                    else {
                        note "No sql file found, skipping...\n";
                        $db = $set->{db}->(%dbd_args);
                    }

                    # The db getters return diag()'s value (false) when the boot
                    # fails, so guard before handing a non-object to the test body.
                    unless ($db) {
                        skip_all "Failed to boot $set->{name}";
                        return;
                    }

                    $code->($db);

                    sleep $END_DELAY if $END_DELAY;
                };
            }, 'force_fork');
        }
    }

    $pr->finish;
}

1;
