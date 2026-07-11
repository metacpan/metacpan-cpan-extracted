package QDB::Installs;
use strict;
use warnings;

# Test-only helper (never shipped, never referenced by lib/): find every
# usable installation of a database flavor, then run a test body against each
# one in its own forked subprocess.
#
# Installations come from two places:
#  - The system install found via $PATH (always considered).
#  - Developer installs under ~/dbs/*/bin, ONLY when AUTHOR_TESTING is set
#    (see AGENTS.md). These are scanned live: whatever directories exist are
#    used, so new installs are picked up and deleted ones vanish. Nothing is
#    hardcoded.
#
# THE PARENT PROCESS MUST NEVER LOAD DBIx::QuickDB OR ANY DRIVER. The drivers
# capture $PATH at load time (PostgreSQL caches binary paths in a BEGIN block)
# and in private caches (%PROVIDER_CACHE in the MySQL driver is a lexical that
# cannot be cleared from outside). A forked child inherits all of that, which
# would defeat its per-install $PATH. Instead each child prepends its
# install's bin dir to $PATH and only THEN loads DBIx::QuickDB code, so every
# BEGIN block and cache initializes under the right $PATH. This is also why
# this module duplicates the provider '-V' regexes instead of calling
# verify_provider(). The one exception: when no install is found at all, the
# parent loads DBIx::QuickDB to produce an accurate skip reason -- safe, since
# it skips the whole file and never forks.

use Test2::IPC;    # Load before Test2::V0 and before any fork, so child events reach the harness.
use Test2::API qw/context/;
use Test2::Tools::Subtest qw/subtest_buffered/;
use IPC::Cmd qw/can_run/;
use Capture::Tiny qw/capture/;
use Carp qw/confess/;
use POSIX qw/WNOHANG/;
use Time::HiRes qw/sleep/;

use Importer Importer => 'import';
our @EXPORT = qw/run_per_install qdb_installs contaminate_env/;

my %MYSQL_FORK = (
    MariaDB  => {servers => [qw/mariadbd mysqld/], clients => [qw/mariadb mysql/], match => qr/MariaDB/i},
    MySQLCom => {servers => [qw/mysqld/],          clients => [qw/mysql/],         match => qr/MySQL Community Server/i},
    Percona  => {servers => [qw/mysqld/],          clients => [qw/mysql/],         match => qr/Percona Server/i},
);

my @MYSQL_DBD = ('DBD::MariaDB', 'DBD::mysql');

my %FLAVORS = (
    (map { $_ => {specs => [$MYSQL_FORK{$_}], dbd => \@MYSQL_DBD} } keys %MYSQL_FORK),

    # The dispatching 'MySQL' driver accepts any fork.
    MySQL => {specs => [@MYSQL_FORK{qw/MariaDB MySQLCom Percona/}], dbd => \@MYSQL_DBD},

    PostgreSQL => {
        specs => [{servers => [qw/postgres/], clients => [], match => qr/PostgreSQL/i, extra => [qw/initdb createdb psql/]}],
        dbd   => ['DBD::Pg'],
    },

    # No server binaries to hunt for; a single 'system' entry when the DBD
    # module is present.
    SQLite => {specs => [], dbd => ['DBD::SQLite']},
    DuckDB => {specs => [], dbd => ['DBD::DuckDB']},
);

# Env vars each flavor's tests contaminate to prove the drivers mask them.
my @BASIC_ENV = qw/DBI_USER DBI_PASS DBI_DSN/;

my @MYSQL_ENV = qw{
    LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN LIBMYSQL_PLUGINS
    LIBMYSQL_PLUGIN_DIR MYSQLX_TCP_PORT MYSQLX_UNIX_PORT MYSQL_DEBUG
    MYSQL_GROUP_SUFFIX MYSQL_HISTFILE MYSQL_HISTIGNORE MYSQL_HOME
    MYSQL_HOST MYSQL_OPENSSL_UDF_DH_BITS_THRESHOLD
    MYSQL_OPENSSL_UDF_DSA_BITS_THRESHOLD
    MYSQL_OPENSSL_UDF_RSA_BITS_THRESHOLD MYSQL_PS1 MYSQL_PWD
    MYSQL_SERVER_PREPARE MYSQL_TCP_PORT MYSQL_TEST_LOGIN_FILE
    MYSQL_TEST_TRACE_CRASH MYSQL_TEST_TRACE_DEBUG MYSQL_UNIX_PORT
};

my @PG_ENV = qw{
    PGAPPNAME PGCLIENTENCODING PGCONNECT_TIMEOUT PGDATABASE PGDATESTYLE
    PGGEQO PGGSSLIB PGHOST PGHOSTADDR PGKRBSRVNAME PGLOCALEDIR PGOPTIONS
    PGPASSFILE PGPASSWORD PGPORT PGREQUIREPEER PGREQUIRESSL PGSERVICE
    PGSERVICEFILE PGSSLCERT PGSSLCOMPRESSION PGSSLCRL PGSSLKEY PGSSLMODE
    PGSSLROOTCERT PGSYSCONFDIR PGTARGETSESSIONATTRS PGTZ PGUSER
};

my %FLAVOR_ENV = (
    (map { $_ => [@BASIC_ENV, @MYSQL_ENV] } qw/MariaDB MySQL MySQLCom Percona/),
    PostgreSQL => [@BASIC_ENV, @PG_ENV],
    SQLite     => [@BASIC_ENV],
    DuckDB     => [@BASIC_ENV],
);

# Set every env var the flavor's drivers should mask to a known-bad value.
# Returns the list so callers can verify restoration afterward.
sub contaminate_env {
    my ($flavor) = @_;
    my $vars = $FLAVOR_ENV{$flavor} or confess "Unknown flavor '$flavor'";
    $ENV{$_} = 'fake' for @$vars;
    return @$vars;
}

sub _probe_version {
    my ($bin, $match) = @_;
    return 0 unless $bin && -x $bin;
    my ($out, $err) = capture { system($bin, '-V') };
    my $txt = ($out // '') . "\n" . ($err // '');
    return $txt =~ $match;
}

sub _system_matches {
    my ($spec) = @_;

    my $hit = 0;
    for my $name (@{$spec->{servers}}) {
        my $path = can_run($name) or next;
        next unless _probe_version($path, $spec->{match});
        $hit = 1;
        last;
    }
    return 0 unless $hit;

    if (@{$spec->{clients}}) {
        return 0 unless grep { can_run($_) } @{$spec->{clients}};
    }

    for my $name (@{$spec->{extra} || []}) {
        return 0 unless can_run($name);
    }

    return 1;
}

sub _dir_matches {
    my ($spec, $bin_dir) = @_;

    my $hit = 0;
    for my $name (@{$spec->{servers}}) {
        next unless -x "$bin_dir/$name";
        next unless _probe_version("$bin_dir/$name", $spec->{match});
        $hit = 1;
        last;
    }
    return 0 unless $hit;

    if (@{$spec->{clients}}) {
        return 0 unless grep { -x "$bin_dir/$_" } @{$spec->{clients}};
    }

    for my $name (@{$spec->{extra} || []}) {
        return 0 unless -x "$bin_dir/$name";
    }

    return 1;
}

# Returns a list of {name, bin_dir} hashes. bin_dir is undef for the system
# install (plain $PATH). Empty list when the flavor is unusable here.
sub qdb_installs {
    my ($flavor) = @_;
    my $f = $FLAVORS{$flavor} or confess "Unknown flavor '$flavor'";

    # Without a usable DBD module nothing can connect; no installs at all.
    return unless grep { my $m = $_; eval "require $m; 1" } @{$f->{dbd}};

    # Flavors with no server binaries (DBD-only) are a single system entry.
    return ({name => 'system', bin_dir => undef}) unless @{$f->{specs}};

    my @out;

    push @out => {name => 'system', bin_dir => undef}
        if grep { _system_matches($_) } @{$f->{specs}};

    if ($ENV{AUTHOR_TESTING} && $ENV{HOME} && -d "$ENV{HOME}/dbs") {
        for my $bin_dir (sort glob("$ENV{HOME}/dbs/*/bin")) {
            next unless grep { _dir_matches($_, $bin_dir) } @{$f->{specs}};
            my ($name) = $bin_dir =~ m{/dbs/([^/]+)/bin$};
            push @out => {name => $name, bin_dir => $bin_dir};
        }
    }

    return @out;
}

sub _no_install_reason {
    my ($flavor) = @_;

    # Safe to load lib/ code here: the whole file is about to skip, no child
    # will ever fork. check_driver gives the same detailed reason
    # skipall_unless_can_db would have produced.
    my $why;
    if (eval { require DBIx::QuickDB; 1 }) {
        (undef, undef, $why) = DBIx::QuickDB->check_driver($flavor, {bootstrap => 1, autostart => 1, load_sql => 1});
    }
    $why ||= "No viable $flavor installation found";
    $why .= " (AUTHOR_TESTING not set, did not scan ~/dbs)"
        if !$ENV{AUTHOR_TESTING} && $ENV{HOME} && -d "$ENV{HOME}/dbs";
    return $why;
}

# Cap on concurrently running install subprocesses per test file. The suite
# already runs many files in parallel (prove -j16), so keep this modest.
my $MAX_PAR = ($ENV{QDB_INSTALL_JOBS} && $ENV{QDB_INSTALL_JOBS} =~ /^\d+$/ && $ENV{QDB_INSTALL_JOBS} > 0)
    ? $ENV{QDB_INSTALL_JOBS}
    : 4;

# Run $body->($install) once per install, each in its own forked subprocess
# wrapped in a subtest, up to $MAX_PAR at a time. The child prepends the
# install's bin dir to $PATH BEFORE any DBIx::QuickDB code loads (see the
# warning at the top). skip_all when no install is usable.
sub run_per_install {
    my ($flavor, $body) = @_;

    my @installs = qdb_installs($flavor);

    unless (@installs) {
        my $ctx = context();
        $ctx->plan(0, SKIP => _no_install_reason($flavor));    # exits the process
        $ctx->release;
        return;
    }

    my %running;    # pid => install

    # Reap exactly one of OUR children, blocking until one exits. Never
    # waitpid(-1): that can steal the exit status of a child some other part
    # of the process owns. WNOHANG polling over the known pids keeps the wait
    # targeted; a -1 return (ECHILD: something else already reaped it, e.g. a
    # rogue SIGCHLD handler) is reported as a loud failure since the exit
    # status was lost.
    my $reap = sub {
        while (keys %running) {
            for my $pid (sort { $a <=> $b } keys %running) {
                my $got = waitpid($pid, WNOHANG);
                next if $got == 0;    # still running

                my $inst = delete $running{$pid};
                my ($failed, $note);
                if ($got == $pid) {
                    my $exit = $?;
                    $failed = $exit ? 1 : 0;
                    $note   = "(exit " . ($exit >> 8) . ", sig " . ($exit & 127) . ")";
                }
                else {
                    $failed = 1;
                    $note   = "(reaped by someone else, exit status lost)";
                }

                my $ctx = context();
                # Child failures already streamed through Test2::IPC; this
                # pins the failure to an install and catches a child that
                # died before producing events.
                $ctx->ok(!$failed, "install '$inst->{name}': subprocess completed cleanly $note");
                $ctx->release;
                return 1;
            }
            sleep 0.05;
        }
        return 0;
    };

    for my $inst (@installs) {
        $reap->() while keys(%running) >= $MAX_PAR;

        my $pid = fork();
        confess "Could not fork: $!" unless defined $pid;

        if ($pid) {
            $running{$pid} = $inst;
        }
        else {
            # Every child inherits the parent's rand state -- identical for
            # all children of this file, and identical ACROSS files because
            # Test2::Plugin::SRand seeds every test process with the same
            # date seed. File::Temp derives temp names from rand(), so
            # without a reseed concurrent children draw the same names.
            # (lib/ also embeds $$ in its tempdir templates; this is defense
            # in depth for anything else rand-derived.)
            srand($$ ^ $^T);

            my $ok = eval {
                $ENV{PATH} = "$inst->{bin_dir}:$ENV{PATH}" if $inst->{bin_dir};
                subtest_buffered("$flavor install: $inst->{name}" => sub { $body->($inst) });
            };
            my $err = $@;
            print STDERR $err if !$ok && $err;
            exit($ok ? 0 : 1);    # plain exit (not POSIX::_exit) so DESTROY still stops any servers
        }
    }

    $reap->() while keys %running;

    return;
}

1;
