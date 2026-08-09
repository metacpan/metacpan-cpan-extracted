package QDB::Installs;
use strict;
use warnings;

# Test-only helper (never shipped, never referenced by lib/): find every
# usable installation of a database flavor, then run a test body against each
# one in an isolated child. Unix uses fork; MSWin32 launches a fresh Perl
# because its thread-based pseudo-fork is not supported by Test2.
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
use Test2::API qw/context test2_add_callback_context_release/;
use Test2::Tools::Subtest qw/subtest_buffered subtest_streamed/;
use IPC::Cmd qw/can_run/;
use Capture::Tiny qw/capture/;
use Carp qw/confess/;
use File::Temp qw/tempfile/;
use POSIX qw/WNOHANG/;
use Time::HiRes qw/sleep/;

use Importer Importer => 'import';
our @EXPORT = qw{
    run_per_install qdb_installs contaminate_env
    skip_remaining_on_resource_error is_resource_unavailable
    resource_unavailable_reason subtest_or_resource_skip
};

# Carried in the message: the Pool bodies are loaded with require, and perl
# rewrites an exception thrown from a file it is loading but keeps its text.
my $RESOURCE_PREFIX = 'QDB-RESOURCE-UNAVAILABLE: ';

# A skip-all plan is invalid after a test body has already emitted assertions.
# Pool tests can exhaust host IPC resources partway through, so record one
# ordinary skip for the unavailable remainder and throw. The DBIx test helper
# loads here rather than at file scope: only an install child may load it.
sub skip_remaining_on_resource_error {
    my ($err) = @_;

    require Test2::Tools::QuickDB;
    my $reason = Test2::Tools::QuickDB::resource_exhaustion_reason($err)
        or return 0;

    my $ctx = context();
    $ctx->skip('remaining Pool checks unavailable', ucfirst($reason));
    $ctx->release;

    # STDERR because the skip above sits in a buffered subtest that goes on to
    # pass, so nothing would print it and a smoker report would not say why.
    print STDERR "Skipping the remaining Pool checks: $reason\n";

    die "$RESOURCE_PREFIX$reason\n";
}

sub is_resource_unavailable {
    my ($err) = @_;
    return defined(resource_unavailable_reason($err)) ? 1 : 0;
}

sub resource_unavailable_reason {
    my ($err) = @_;
    return undef unless defined($err) && !ref($err);

    my ($reason) = $err =~ m/^\Q$RESOURCE_PREFIX\E(.*)$/m;
    return $reason;
}

# subtest reports an exception as a failure of that subtest and does not
# rethrow, which would leave a resource skip looking like a fault and let the
# rest of the body run. Re-raise it once the subtest has closed.
#
# Agent Note: this unwinds one level. A resource skip raised inside a plain
# nested subtest is swallowed by that subtest; nest with this instead.
sub subtest_or_resource_skip {
    my ($name, $code) = @_;

    # Without a context of our own every subtest here reports at this line
    # rather than at its own call site.
    my $ctx = context();

    my $unavailable;
    subtest_buffered(
        $name => sub {
            my $ok = eval { $code->(); 1 };
            return if $ok;

            $unavailable = $@;
            die $unavailable unless is_resource_unavailable($unavailable);
        }
    );

    $ctx->release;

    die $unavailable if defined $unavailable && is_resource_unavailable($unavailable);

    return;
}

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

my $CHILD_FLAVOR_ENV = 'QDB_INSTALL_EXTERNAL_FLAVOR';
my $CHILD_NAME_ENV   = 'QDB_INSTALL_EXTERNAL_NAME';
my $CHILD_BIN_ENV    = 'QDB_INSTALL_EXTERNAL_BIN_DIR';
my $CHILD_TRACE_ENV  = 'QDB_INSTALL_EXTERNAL_TRACE';

# A child dying before its first result leaves the harness only "Tests: 0 /
# No plan found". Returns a coderef that sets the phase, undef if unusable.
sub _trace_child_progress {
    # The same test the parent applies, so the two cannot disagree.
    my $file = $ENV{$CHILD_TRACE_ENV};
    return undef unless defined($file) && length($file);

    open(my $fh, '>', $file) or return undef;

    # Autoflush without IO::Handle: nothing ever closes this handle.
    { my $old = select($fh); $| = 1; select($old) }

    my $phase = 'child started, body has not run yet';
    my $where = '';

    # Rewritten in place, truncated after the write: an empty file would read
    # as nothing having been recorded.
    my $write = sub {
        seek($fh, 0, 0) or return;
        print $fh "phase: $phase\n";
        print $fh "$where\n" if length $where;
        truncate($fh, tell($fh));
        return;
    };

    $write->();

    # Context release, not a hub listener: a streamed subtest has its own hub.
    test2_add_callback_context_release(sub {
        my ($ctx) = @_;
        my $frame = eval { $ctx->trace->frame } or return;
        $where = "last Test2 context at $frame->[1] line $frame->[2]";
        $write->();
    });

    return sub { $phase = $_[0]; $write->() };
}

# STDERR, not TAP: the child owns that stream and may already have planned.
# STDERR also survives POSIX::_exit; buffered STDOUT does not.
sub _diag_external_child {
    my ($flavor, $inst, $note, $trace_file) = @_;

    my $label = "install '$inst->{name}'";
    print STDERR "$label: isolated $flavor process $note\n";

    my @progress;
    if (defined($trace_file) && length($trace_file) && open(my $fh, '<', $trace_file)) {
        chomp(@progress = <$fh>);
        @progress = grep { defined($_) && length($_) } @progress;
    }

    # Silence here would be indistinguishable from the reporting itself failing.
    unless (@progress) {
        print STDERR "$label: no progress was recorded by the child\n";
        return;
    }

    print STDERR "$label: child got as far as: $_\n" for @progress;

    return;
}

sub _external_child_command {
    my @inc = map { "-I$_" } grep { defined($_) && length($_) && !ref($_) } @INC;
    return ($^X, @inc, $0);
}

sub _with_external_child_env {
    my ($flavor, $inst, $code) = @_;

    local $ENV{$CHILD_FLAVOR_ENV} = $flavor;
    local $ENV{$CHILD_NAME_ENV}   = $inst->{name};
    local $ENV{$CHILD_BIN_ENV}    = defined($inst->{bin_dir}) ? $inst->{bin_dir} : '';

    return $code->();
}

# With one install, let the real child write TAP directly to the outer harness
# and mirror its exit status. This preserves partial TAP if an XS module crashes.
# The tiny parent has not loaded QuickDB, so POSIX::_exit is safe here.
sub _run_single_external_install {
    my ($flavor, $inst) = @_;
    my @cmd = _external_child_command();

    # A caller-set path is the caller's to keep; it is how the tests inspect this.
    my $trace_file = $ENV{$CHILD_TRACE_ENV};
    my $own_trace  = !(defined($trace_file) && length($trace_file));

    if ($own_trace) {
        # Unlinked by hand: POSIX::_exit skips END, so File::Temp never does.
        # DB-QUICK prefix so a debris sweep finds one a killed parent left.
        (my $trace_fh, $trace_file) = tempfile("DB-QUICK-TRACE-$$-XXXXXX", TMPDIR => 1, UNLINK => 0);
        close($trace_fh);
    }
    else {
        # Emptied first, dropped if that fails: an earlier run's content must
        # not be reported as this one's.
        my $trace_fh;
        unless (open($trace_fh, '>', $trace_file)) {
            warn "Could not empty the trace file '$trace_file': $!\n";
            undef $trace_file;
        }
        close($trace_fh) if $trace_fh;
    }

    # Empty, not undef: an undef assignment would warn.
    local $ENV{$CHILD_TRACE_ENV} = defined($trace_file) ? $trace_file : '';

    _with_external_child_env($flavor, $inst, sub {
        system(@cmd);
        my $status = $?;

        if ($status == -1) {
            _diag_external_child($flavor, $inst, "could not be launched: $!", $trace_file);
            unlink($trace_file) if $own_trace;
            POSIX::_exit(255);
        }

        my $signal = $status & 127;
        my $exit   = $signal ? 128 + $signal : $status >> 8;

        # A signalled child never exited 128+n; say what actually happened.
        my $note = $signal
            ? "was killed by signal $signal (status $status)"
            : "exited $exit (status $status)";

        _diag_external_child($flavor, $inst, $note, $trace_file) if $status;

        unlink($trace_file) if $own_trace;
        POSIX::_exit($exit);
    });
}

# Multiple developer installs cannot share one process: drivers capture PATH at
# load time. Run each in a real child sequentially, reducing its TAP to one
# parent assertion while retaining full child TAP on failure and any child
# stderr. QDB_INSTALL_JOBS deliberately applies only to the Unix fork path;
# serial execution also keeps captured child output from interleaving.
sub _run_external_install {
    my ($flavor, $inst) = @_;
    my @cmd = _external_child_command();
    my ($stdout, $stderr, $status, $launch_error);

    # This path captures its children instead; one shared path would clobber.
    local $ENV{$CHILD_TRACE_ENV};
    delete $ENV{$CHILD_TRACE_ENV};

    _with_external_child_env($flavor, $inst, sub {
        ($stdout, $stderr) = capture {
            system(@cmd);
            $status = $?;
            $launch_error = "$!" if $status == -1;
        };
    });

    my ($failed, $note);
    if ($status == -1) {
        $failed = 1;
        $note = "(launch failed: $launch_error)";
    }
    else {
        $failed = $status ? 1 : 0;
        $note = "(exit " . ($status >> 8) . ", sig " . ($status & 127) . ")";
    }

    my $ctx = context();
    $ctx->ok(!$failed, "install '$inst->{name}': external subprocess completed cleanly $note");
    $ctx->diag("child TAP:\n$stdout") if $failed && defined($stdout) && length($stdout);
    if (defined($stderr) && length($stderr)) {
        my $label = $failed ? 'child stderr' : 'child stderr (subprocess passed; informational)';
        $ctx->diag("$label:\n$stderr");
    }
    $ctx->release;
    return;
}

# Run $body->($install) once per install in an isolated process. Unix uses
# buffered subtests in real forks, up to $MAX_PAR at a time; MSWin32 uses fresh
# Perl processes. The child prepends the install's bin dir to $PATH BEFORE any
# DBIx::QuickDB code loads (see the warning at the top). skip_all when no
# install is usable.
sub run_per_install {
    my ($flavor, $body) = @_;

    # A real subprocess launched by the MSWin32 parent comes back through the
    # same test file. Run only its selected body in a streamed subtest, so the
    # existing wrapper semantics are preserved and a crash still leaves every
    # TAP event produced before it.
    if (defined(my $child_flavor = $ENV{$CHILD_FLAVOR_ENV})) {
        confess "External install child expected '$child_flavor', got '$flavor'"
            unless $child_flavor eq $flavor;

        # Test2::Plugin::SRand gives fresh test processes the same date-derived
        # seed. Reseed with the real child pid before File::Temp or test code
        # uses rand(), matching the collision defense in the Unix fork child.
        srand($$ ^ $^T);

        my $bin_dir = $ENV{$CHILD_BIN_ENV};
        $bin_dir = undef unless defined($bin_dir) && length($bin_dir);
        if ($bin_dir) {
            my $separator = $^O eq 'MSWin32' ? ';' : ':';
            $ENV{PATH} = length($ENV{PATH} || '')
                ? "$bin_dir$separator$ENV{PATH}"
                : $bin_dir;
        }

        my $inst = {name => $ENV{$CHILD_NAME_ENV}, bin_dir => $bin_dir};

        # No location is recorded before the body's first Test2 op.
        my $trace    = _trace_child_progress();
        my $returned = 0;
        subtest_streamed("$flavor install: $inst->{name}" => sub {
            $trace->('running the install body') if $trace;
            $body->($inst);
            $trace->('install body returned') if $trace;
            $returned = 1;
        });

        # subtest_streamed catches the exception and returns while the location
        # keeps advancing; skip_all lands here too, hence the wording.
        $trace->('install body did not return normally') if $trace && !$returned;

        return;
    }

    my @installs = qdb_installs($flavor);

    unless (@installs) {
        my $ctx = context();
        $ctx->plan(0, SKIP => _no_install_reason($flavor));    # exits the process
        $ctx->release;
        return;
    }

    # Test2 supports real fork but explicitly does not support the thread-based
    # pseudo-fork supplied by Windows Perl. QDB_INSTALL_NO_FORK is test-only
    # plumbing that exercises this path on Unix CI/developer machines.
    if ($^O eq 'MSWin32' || $ENV{QDB_INSTALL_NO_FORK}) {
        if (@installs == 1) {
            _run_single_external_install($flavor, $installs[0]);
            confess "External install process unexpectedly returned";
        }
        _run_external_install($flavor, $_) for @installs;
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
