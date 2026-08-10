######################################################################
#
# 0033-cli-and-repl.t  bin/batsh.pl command-line interface and the
#                      interactive REPL (v0.11)
#
# CL01-CL02  --version / --help
# CL03       -e 'source' (space-free source)
# CL04       script file with arguments ($1..)
# CL05       "-" reads the script from STDIN
# CL06-CL07  diagnosed failures (missing file, unknown encoding)
# CL08-CL11  REPL: SH line, CMD line, mode switch, exit status
# CL12       REPL start-up is silent (no interpreter warnings)
# CL13       -e 'source' where the source carries a space (rule R9)
#
# Until 0.11 nothing in t/ ran bin/batsh.pl or BATsh->repl() at all, and
# a defect lived there undetected: repl() initialised its state with
# "my (@buf, $depth, $cur_mode) = ((), 0, '')", in which the array is
# greedy and takes the whole right-hand side.  @buf therefore started as
# (0, ''), so the FIRST line typed at the prompt was executed with two
# junk lines in front of it and the session opened with
# "Can't exec \"0\"" plus four uninitialized-value warnings.  CL08-CL12
# exist to keep that whole surface exercised.
#
# The child perl's STDIN is supplied by reopening the handle at the Perl
# level (as t/0016 does for STDOUT) rather than with a shell "< file",
# so no shell is involved on either platform.
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
use File::Spec ();
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";
use BATsh_TestOS qw(argv_space_safe);

eval { require BATsh } or die "Cannot load BATsh: $@";

my $LIB = File::Spec->catdir($FindBin::Bin, File::Spec->updir(), 'lib');
my $BIN = File::Spec->catfile($FindBin::Bin, File::Spec->updir(),
                              'bin', 'batsh.pl');

my $SEQ = 0;
sub _scratch {
    my ($tag) = @_;
    $SEQ++;
    return File::Spec->catfile($FindBin::Bin, "_cli_${tag}_$$" . "_$SEQ.tmp");
}

# Write @lines (each newline-terminated already) to $path.
sub _write_file {
    my ($path, $text) = @_;
    local *WF;
    open(WF, "> $path") or die "cannot write $path: $!";
    print WF $text;
    close(WF);
    return $path;
}

sub _slurp {
    my ($path) = @_;
    my $text = '';
    local *RF;
    if (open(RF, $path)) { local $/; $text = <RF>; close(RF) }
    $text = '' unless defined $text;
    return $text;
}

# Run bin/batsh.pl in a child perl with @args, feeding $stdin (which may
# be undef for "no input at all").  Returns (exit_code, stdout, stderr).
sub _run_cli {
    my ($stdin, @args) = @_;
    my $out_file = _scratch('out');
    my $err_file = _scratch('err');
    my $in_file  = _scratch('in');
    _write_file($in_file, defined($stdin) ? $stdin : '');

    local (*OLDOUT, *OLDERR, *OLDIN);
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    open(OLDERR, ">&STDERR") or die "cannot dup STDERR: $!";
    open(OLDIN,  "<&STDIN")  or die "cannot dup STDIN: $!";

    my $rc = -1;
    my $err = '';
    {
        close(STDOUT);
        if (!open(STDOUT, "> $out_file")) {
            open(STDOUT, ">&OLDOUT");
            $err = "cannot redirect STDOUT: $!";
            last;
        }
        close(STDERR);
        if (!open(STDERR, "> $err_file")) {
            open(STDERR, ">&OLDERR");
            $err = "cannot redirect STDERR";
            last;
        }
        close(STDIN);
        if (!open(STDIN, "< $in_file")) {
            open(STDIN, "<&OLDIN");
            $err = "cannot redirect STDIN";
            last;
        }
        # LIST-form system(): no shell re-parsing of the arguments.
        $rc = system($^X, "-I$LIB", $BIN, @args);
    }

    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(STDERR);
    open(STDERR, ">&OLDERR") or die "cannot restore STDERR: $!";
    close(STDIN);
    open(STDIN, "<&OLDIN") or die "cannot restore STDIN: $!";
    close(OLDOUT);
    close(OLDERR);
    close(OLDIN);
    die $err if $err ne '';

    my $out = _slurp($out_file);
    my $bad = _slurp($err_file);
    unlink($out_file);
    unlink($err_file);
    unlink($in_file);
    my $code = $rc < 0 ? -1 : ($rc >> 8);
    return ($code, $out, $bad);
}

my $test = 0;
sub ok_is {
    my ($got, $expected, $name) = @_;
    $test++;
    $got      = '(undef)' unless defined $got;
    $expected = '(undef)' unless defined $expected;
    if ($got eq $expected) { print "ok $test - $name\n"; return 1 }
    print "not ok $test - $name (got [$got] expected [$expected])\n";
    $main::fail++;
    return 0;
}

# Print the captured streams on failure only.  Rule R3 of
# t/lib/BATsh_TestOS.pm: an assertion that says nothing when it fails
# cannot be diagnosed from a CPAN Testers report.
sub _diag {
    my ($tag, $code, $out, $bad) = @_;
    my @line = ("$tag: exit=" . (defined $code ? $code : 'undef'));
    push @line, "$tag: stdout=[" . _oneline($out) . ']';
    push @line, "$tag: stderr=[" . _oneline($bad) . ']';
    for my $l (@line) { print "# $l\n" }
    return;
}

sub _oneline {
    my ($text) = @_;
    $text = '' unless defined $text;
    $text =~ s/\r?\n/ | /g;
    $text = substr($text, 0, 400) . '...' if length($text) > 400;
    return $text;
}

my @tests = (

# CL01: --version prints the distribution version and exits 0
sub {
    my ($code, $out, $bad) = _run_cli(undef, '--version');
    my $good = ($code == 0 && $out =~ /\ABATsh\s+\Q$BATsh::VERSION\E\b/) ? 1 : 0;
    _diag('CL01', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL01 --version reports the version and exits 0');
},

# CL02: --help prints the usage banner under the installed name
sub {
    my ($code, $out, $bad) = _run_cli(undef, '--help');
    my $good = ($code == 0 && $out =~ /usage:\s*batsh\.pl/) ? 1 : 0;
    _diag('CL02', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL02 --help prints usage and exits 0');
},

# CL03: -e runs inline source.  The source is deliberately a single
# space-free word: on Win32 a space inside one argument survives only if
# perl's command-line quoting and the child's splitting agree, and this
# case has to run everywhere (rule R9).  CL13 covers the space form.
sub {
    my ($code, $out, $bad) = _run_cli(undef, '-e', 'pwd');
    my $good = ($code == 0 && $out =~ /\S/ && $bad eq '') ? 1 : 0;
    _diag('CL03', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL03 -e runs inline source');
},

# CL04: a script file receives the remaining arguments as $1..
sub {
    my $script = _scratch('prog');
    _write_file($script, "echo arg1=\$1 arg2=\$2\nexit 4\n");
    my ($code, $out, $bad) = _run_cli(undef, $script, 'alpha', 'beta');
    unlink($script);
    my $good = ($code == 4 && $out =~ /arg1=alpha arg2=beta/) ? 1 : 0;
    _diag('CL04', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL04 script file receives arguments and exit status');
},

# CL05: "-" reads the script from STDIN
sub {
    my ($code, $out, $bad) = _run_cli("echo cl05-stdin\n", '-');
    my $good = ($code == 0 && $out =~ /cl05-stdin/) ? 1 : 0;
    _diag('CL05', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL05 "-" reads the script from STDIN');
},

# CL06: a missing script file is a diagnosed failure, not a silent success
sub {
    my $missing = _scratch('gone');
    my ($code, $out, $bad) = _run_cli(undef, $missing);
    my $good = ($code != 0 && $code != -1 && $bad ne '') ? 1 : 0;
    _diag('CL06', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL06 missing script file fails with a diagnostic');
},

# CL07: an unknown --encoding is a diagnosed failure
sub {
    my ($code, $out, $bad) =
        _run_cli(undef, '--encoding=no-such-encoding', '-e', 'echo x');
    my $good = ($code != 0 && $code != -1 && $bad ne '') ? 1 : 0;
    _diag('CL07', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL07 unknown --encoding fails with a diagnostic');
},

# CL08: the REPL runs the FIRST line typed at the prompt, and nothing
# else.  Before 0.11 the leading junk in @buf made this line run as
# "0" + "" + the real command.
sub {
    my ($code, $out, $bad) = _run_cli("echo cl08-first\nexit\n");
    my $good = ($out =~ /cl08-first/ && $out !~ /Can't exec/
                && $bad !~ /Can't exec/) ? 1 : 0;
    _diag('CL08', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL08 REPL runs the first line with nothing prepended');
},

# CL09: the same for a CMD line, including the process exit code
sub {
    my ($code, $out, $bad) = _run_cli("ECHO CL09-FIRST\nEXIT\n");
    my $good = ($code == 0 && $out =~ /CL09-FIRST/ && $out !~ /Can't exec/
                && $bad !~ /Can't exec/) ? 1 : 0;
    _diag('CL09', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL09 REPL runs a first CMD line and exits 0');
},

# CL10: sections switch mode line by line in the REPL as they do in a file
sub {
    my ($code, $out, $bad) =
        _run_cli("echo cl10-sh\nECHO CL10-CMD\necho cl10-sh2\nexit\n");
    my $good = ($out =~ /cl10-sh.*CL10-CMD.*cl10-sh2/s) ? 1 : 0;
    _diag('CL10', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL10 REPL switches between SH and CMD lines');
},

# CL11: "exit N" in the REPL becomes the process exit code
sub {
    my ($code, $out, $bad) = _run_cli("echo cl11\nexit 3\n");
    my $good = ($code == 3) ? 1 : 0;
    _diag('CL11', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL11 REPL "exit N" sets the process exit code');
},

# CL12: starting the REPL and closing STDIN at once must be silent.
# The four uninitialized-value warnings that 0.10 emitted here appeared
# before any user input, so they were the very first thing a new user
# saw.  Perl's own warnings are matched, not any OS text (rule R2).
sub {
    my ($code, $out, $bad) = _run_cli('');
    my $good = ($code == 0 && $bad !~ /Use of uninitialized value/
                && $bad !~ /Can't exec/) ? 1 : 0;
    _diag('CL12', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL12 REPL start-up emits no interpreter warnings');
},

# CL13: -e with a source that contains a space.  This is what a user
# actually types -- batsh.pl -e 'echo hi' -- but getting it there from
# inside a test needs one argument to survive with its space intact,
# which on Win32 depends on perl's quoting and the child's splitting
# agreeing.  BATsh-0.11 first shipped this as CL03 and a Windows smoker
# received it as two arguments, so the case reported a shell defect that
# did not exist.  Where the platform cannot carry the argument, the
# platform is reported and the case is skipped (rules R4 and R9).
sub {
    return ok_is(1, 1, 'CL13 skipped (system(LIST) splits an argument '
                     . 'containing a space on this perl)')
        unless argv_space_safe();
    my ($code, $out, $bad) = _run_cli(undef, '-e', 'echo cl13-inline');
    my $good = ($code == 0 && $out =~ /cl13-inline/) ? 1 : 0;
    _diag('CL13', $code, $out, $bad) unless $good;
    ok_is($good, 1, 'CL13 -e runs inline source containing a space');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
