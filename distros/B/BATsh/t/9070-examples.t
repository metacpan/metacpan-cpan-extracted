######################################################################
#
# 9070-examples.t  eg/ example script checks
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;
use BATsh_TestOS qw(shell_safe_path);

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

# Rule R8 (t/lib/BATsh_TestOS.pm).  The examples print their own script
# path (%0, %~dp0 and friends), and BATsh re-reads the result of an
# expansion exactly as cmd.exe and bash do.  When the tester's build
# directory is spelled with a shell metacharacter -- "C:\Foo & Bar\" --
# that re-reading splits the expanded path and the example emits a
# diagnostic through no fault of its own.  E4 is about the example, not
# about the directory it happens to sit in, so report the spelling and
# skip rather than fail.  E1-E3 read the file directly and are unaffected.
my $ROOT_OK = shell_safe_path($ROOT);

my @manifest  = _manifest_files($ROOT);
my @eg_files  = sort grep { m{^eg/.*\.batsh$} && -f "$ROOT/$_" } @manifest;

plan_skip('no eg/*.batsh files found') unless @eg_files;
plan_tests(scalar(@eg_files) * 4);

# Maximum stdout lines an example may emit.  A correctly-terminating
# example stays well under this; a runaway loop would blow past it.
my $MAX_OUT_LINES = 5000;

for my $rel (@eg_files) {
    my $path  = "$ROOT/$rel";
    my @lines = _slurp_lines($path);

    ok(-f $path, "E1: $rel exists");

    my $bad = 0;
    for my $line (@lines) {
        if ($line =~ /[^\x0A\x0D\x20-\x7E]/) { $bad++; last }
    }
    ok($bad == 0, "E2: $rel US-ASCII only");

    my $last = @lines ? $lines[-1] : '';
    ok($last =~ /\n\z/, "E3: $rel ends with newline");

    # E4: run the example through BATsh in a child process and guard
    # against (a) runaway loops (bounded stdout) and (b) broken escape
    # handling that would make piped 'perl -e' choke with a syntax error.
    if (!$ROOT_OK) {
        ok(1, "E4: $rel skipped (build path not usable in shell source: $ROOT)");
    }
    else {
        my($out_lines, $err_text) = _run_example($ROOT, $path);
        my $ok_run = ($out_lines <= $MAX_OUT_LINES)
                  && ($err_text !~ /syntax error/i)
                  && ($err_text !~ /aborted/i);
        ok($ok_run, "E4: $rel runs cleanly ($out_lines lines)");
    }
}

# Run an eg/*.batsh file via the same perl, capturing child STDOUT/STDERR
# at the file-descriptor level (so output from system()/pipes is caught).
# Returns (number_of_stdout_lines, stderr_text).
sub _run_example {
    my($root, $path) = @_;
    my $tmp     = File::Spec->tmpdir;
    my $out     = File::Spec->catfile($tmp, "batsh_o_$$.txt");
    my $err     = File::Spec->catfile($tmp, "batsh_e_$$.txt");

    # Rule R9.  This used to run
    #
    #     system($^X, (map { "-I$_" } @INC), '-MBATsh',
    #            '-e', 'BATsh->run($ARGV[0])', $path);
    #
    # and it failed on MSWin32 in every matrix cell whose BUILD PATH
    # contained a space or parentheses -- 30 of 90 cells -- while passing
    # in all 30 cells built at a plain path.  The reason is not @INC and
    # not the pathname: it is the "-e" operand.  It contains '>', which
    # is a cmd.exe redirection character, and once another argument on
    # that command line has to be quoted, Windows can route the whole
    # line through cmd.exe, which then reads the '>' and cuts the program
    # text in half.  The child perl reported a syntax error and printed
    # nothing, so even eg/01_hello.batsh was recorded as producing 0
    # lines -- a FAIL with nothing whatever wrong in lib/.
    #
    # The cure is to stop sending program text through argv at all.
    # bin/batsh.pl is the distribution's own entry point, does exactly
    # what the -e code did, and carries no metacharacter; this is the
    # same invocation shape as t/0033, which passed in the very cells
    # where this file failed.  '-I' still carries the build path, and
    # that is fine: a pathname needs quoting, not shell escaping.
    my $lib = File::Spec->catdir($root, 'lib');
    my $bin = File::Spec->catfile($root, 'bin', 'batsh.pl');

    # Examples document their helper interpreter as the bareword "perl"
    # (correct for an end user), and some shell out to it -- e.g. a
    # pipeline "echo X | perl ..." or a command substitution
    # "VAR=$(perl -e ...)" whose empty result then feeds a redirect.
    # On a CPAN smoker the perl under test is frequently NOT on PATH as
    # "perl" (perlbrew/plenv, or perl invoked by absolute path); the
    # example's external "perl" would then fail and, via the empty
    # substitution + redirect chain, can block.  Put the directory of the
    # running interpreter ($^X) first on PATH for the child so "perl"
    # always resolves to the very perl now running the suite.
    my ($pvol, $pdirs) = File::Spec->splitpath($^X);
    my $perldir = File::Spec->catpath($pvol, $pdirs, '');
    my $sep = ($^O =~ /^(?:MSWin32|dos|os2)$/) ? ';' : ':';
    local $ENV{PATH} = (defined($ENV{PATH}) && length($ENV{PATH}) && length($perldir))
                     ? "$perldir$sep$ENV{PATH}"
                     : (length($perldir) ? $perldir : $ENV{PATH});

    local(*SAVE_OUT, *SAVE_ERR);
    open(SAVE_OUT, ">&STDOUT") or return (0, '');
    open(SAVE_ERR, ">&STDERR") or do { close(SAVE_OUT); return (0, '') };
    open(STDOUT, "> $out")     or do { close(SAVE_OUT); close(SAVE_ERR); return (0, '') };
    open(STDERR, "> $err")     or do { open(STDOUT, ">&SAVE_OUT"); close(SAVE_OUT); close(SAVE_ERR); return (0, '') };

    system($^X, "-I$lib", $bin, $path);

    open(STDOUT, ">&SAVE_OUT"); close(SAVE_OUT);
    open(STDERR, ">&SAVE_ERR"); close(SAVE_ERR);

    my $n = 0;
    if (open(FH_O, "< $out")) { while (<FH_O>) { $n++ } close(FH_O) }
    my $e = '';
    if (open(FH_E, "< $err")) { local $/; $e = <FH_E>; close(FH_E) }
    $e = '' unless defined $e;

    unlink($out, $err);
    return ($n, $e);
}

END { end_testing() }
