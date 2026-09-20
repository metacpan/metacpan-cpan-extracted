package TestKarr;
use strict;
use warnings;
use TestEnv; # k288: scrub KARR_CLAIM before any dispatch() call below runs

# In-process karr runner: dispatch the command classes many times in one
# interpreter instead of paying ~0.3s of Perl startup per `karr` subprocess.
# It goes through the SAME dispatch path as bin/karr -- App::karr::Dispatch --
# so there are no two copies to drift, and captures stdout/stderr/exit
# byte-identically to the open3 runner the test files used to carry inline.
#
# Drop-in for the per-file `_run_karr($cwd, @argv)` helper: same signature, same
# { exit, stdout, stderr } return. run_karr_stdin adds the stdin-fed variant for
# the commands that read a payload (restore, set-refs, delete's confirmation).
#
# KARR_TEST_SUBPROC=1 falls back to the old open3 path -- a safety net, and the
# way to run a test that genuinely needs a fresh interpreter (e.g. a PERL5OPT
# monkeypatch) without editing it.

use Cwd qw( getcwd abs_path );
use Scalar::Util qw( blessed );
use Exporter qw( import );

our @EXPORT_OK = qw( run_karr run_karr_stdin );

# Whether to use the subprocess fallback. Fixed at load time: it decides, at
# compile time below, whether the exit override is installed at all.
our $SUBPROC;
BEGIN { $SUBPROC = $ENV{KARR_TEST_SUBPROC} ? 1 : 0 }

# The exit-signal an intercepted exit() raises. App::karr::Dispatch re-raises
# any caught exception answering __karr_dispatch_exit rather than classifying it
# as a command that died, so the code carried here reaches _run_inprocess intact.
BEGIN {
    package TestKarr::Exit;
    sub new { my ( $class, $code ) = @_; bless { code => $code }, $class }
    sub code                 { $_[0]{code} }
    sub __karr_dispatch_exit { 1 }
}

# Install a permanent CORE::GLOBAL::exit override BEFORE App::karr and its
# modules compile, so their bare exit() calls bind to it rather than the real
# builtin. karr reaches exit() from three places -- App::karr::Dispatch's
# handler, App::karr::Role::ExitCodes, and App::karr::_print_help -- and all
# three are covered.
#
# The permanent override merely delegates to the real exit, so Test::More's own
# exit (BAIL_OUT, Test::Builder's END) is unaffected. _run_inprocess swaps in a
# throwing version with `local` only for the duration of one dispatch, which the
# already-compiled exit() calls pick up at runtime (verified: a locally-swapped
# CORE::GLOBAL::exit intercepts a sub compiled against the permanent one).
BEGIN {
    unless ($SUBPROC) {
        no warnings 'once';
        *CORE::GLOBAL::exit = sub { CORE::exit( defined $_[0] ? $_[0] : 0 ) };
    }
}

# Compiles App::karr under the override above. Loaded unconditionally so the
# module is always usable; the subprocess path just never calls dispatch().
use App::karr::Dispatch qw( dispatch );
use App::karr::SyncGuard;
use App::karr::Encoding qw( to_octets );
use App::karr::Error qw( is_usage_error );

# For the subprocess fallback only.
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub run_karr {
    my ( $cwd, @argv ) = @_;
    return _run( $cwd, undef, @argv );
}

sub run_karr_stdin {
    my ( $cwd, $stdin, @argv ) = @_;
    return _run( $cwd, \$stdin, @argv );
}

sub _run {
    my ( $cwd, $stdin_ref, @argv ) = @_;
    return $SUBPROC
        ? _run_subproc( $cwd, $stdin_ref, @argv )
        : _run_inprocess( $cwd, $stdin_ref, @argv );
}

sub _run_inprocess {
    my ( $cwd, $stdin_ref, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    # Hand dispatch the octet argv the OS would have handed bin/karr, so its
    # decode_argv reverses it and the run is byte-identical to a subprocess in
    # a UTF-8 locale. Only a character string (the utf8 flag on) is encoded --
    # a caller that already built raw octets itself (to hand dispatch exactly
    # the bytes a shell would have passed, mojibake fixtures included) has that
    # payload passed through untouched, because encoding it again would be the
    # very double-encode this boundary exists to prevent.
    my @octet_argv = map {
        my $v = "$_";
        utf8::is_utf8($v) ? to_octets($v) : $v;
    } @argv;

    my ( $out, $err ) = ( '', '' );
    my $exit;
    {
        local *STDOUT;
        local *STDERR;
        open( STDOUT, '>', \$out ) or die "capture STDOUT: $!";
        open( STDERR, '>', \$err ) or die "capture STDERR: $!";

        # Opened even when nothing was asked to be fed in: open3's parent
        # closes an unused stdin pipe without writing to it, so the child sees
        # a real, open, immediately-EOF handle -- never a plain undef read. A
        # bare `local *STDIN;` here would leave the glob's filehandle slot
        # empty, and a command that touches STDIN without expecting a payload
        # (karr delete's confirmation prompt, answered by nobody) would hit
        # "readline() on unopened filehandle" instead of the EOF it gets from
        # a subprocess.
        local *STDIN;
        my $in = ( defined $stdin_ref && defined $$stdin_ref ) ? $$stdin_ref : '';
        open( STDIN, '<', \$in ) or die "feed STDIN: $!";

        # Swap the delegating override for a throwing one, only here.
        local *CORE::GLOBAL::exit
            = sub { die TestKarr::Exit->new( defined $_[0] ? $_[0] : 0 ) };

        my $ok = eval { dispatch(@octet_argv); 1 };
        if ($ok) {
            $exit = 0;
        }
        else {
            my $e = $@;
            if ( blessed($e) && $e->can('__karr_dispatch_exit') ) {
                $exit = $e->code;
            }
            else {
                # dispatch prints and exits on every error it handles, so this
                # is only reached by a die that escaped it -- mirror bin/karr's
                # exit-code contract rather than leaking 255.
                print STDERR $e if defined $e && length $e;
                $exit = is_usage_error($e) ? 2 : 1;
            }
        }

        # bin/karr flushes armed SyncGuards from an END block (#37), which does
        # not fire between in-process calls. Flush after each dispatch, while
        # STDOUT/STDERR are still captured, so any insurance-push output lands
        # in the capture exactly as it does in a subprocess run.
        eval { App::karr::SyncGuard->flush_armed };
    }

    chdir $old or die "chdir $old: $!";

    return { exit => $exit, stdout => $out, stderr => $err };
}

sub _run_subproc {
    my ( $cwd, $stdin_ref, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $in;
    my $pid = open3(
        ( defined $stdin_ref ? $in : undef ),
        my $stdout_fh,
        $stderr,
        $^X, "-I$ROOT/lib", $BIN, @argv,
    );
    if ( defined $stdin_ref ) {
        print {$in} ( defined $$stdin_ref ? $$stdin_ref : '' );
        close $in;
    }

    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

1;
