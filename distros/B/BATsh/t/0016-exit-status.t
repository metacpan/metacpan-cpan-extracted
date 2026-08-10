######################################################################
#
# 0016-exit-status.t  Script exit-code propagation and the
#                     $? <-> %ERRORLEVEL% status bridge (v0.07)
#
# ES01-ES05  run()/run_string() return the script's exit status
# ES06-ES08  SH -> CMD bridge ($? visible as %ERRORLEVEL%)
# ES09       CMD -> SH bridge (ERRORLEVEL visible as $?)
# ES10-ES11  execution stops after exit / EXIT
# ES12-ES13  OS process exit code of the modulino (child perl)
# ES14       "batsh -" reads the script from STDIN with arguments
# ES15       exit inside a sourced file terminates the outer script
# ES16       EXIT with no code keeps the current ERRORLEVEL
# ES17       source/. dequotes its operand (0.11)
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
use BATsh_TestOS qw(shell_safe_path);

# Rule R8 (t/lib/BATsh_TestOS.pm): the build directory was named by the
# tester, not by this distribution.  Cases that interpolate it into shell
# or cmd.exe source quote it; where the spelling carries a character that
# quoting cannot survive, they skip with a reason instead of accusing
# BATsh of a defect that lives in the test.
my $PATH_OK = shell_safe_path($FindBin::Bin);
my $PATH_WHY = "build path is not usable in shell source: $FindBin::Bin";

eval { require BATsh } or die "Cannot load BATsh: $@";

# Run source through BATsh->run_string, capturing STDOUT; return (rc, out).
sub _run_capture {
    my ($source) = @_;
    BATsh::Env::init();
    my $cap = "$FindBin::Bin/_es_cap_$$.tmp";
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    my $rc = eval { BATsh->run_string($source) };
    my $err = $@;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($cap);
    $out = '' unless defined $out;
    warn $err if $err;
    return ($rc, $out);
}

# Run a child perl on lib/BATsh.pm with a script file; return ($?>>8, out).
sub _run_child {
    my ($script_source, @args) = @_;
    my $prog = "$FindBin::Bin/_es_prog_$$.batsh";
    my $cap  = "$FindBin::Bin/_es_out_$$.tmp";
    local *PF;
    open(PF, "> $prog") or die "cannot write $prog: $!";
    print PF $script_source;
    close(PF);
    my $lib = File::Spec->catdir($FindBin::Bin, File::Spec->updir(), 'lib');
    my $pm  = File::Spec->catfile($lib, 'BATsh.pm');
    # LIST-form system() bypasses the shell entirely (no cmd.exe re-parsing
    # of nested quotes on Windows, no shell metacharacter issues on Unix).
    # STDOUT redirection is done at the Perl level (dup/reopen) rather than
    # with a shell "> file", since the child inherits our STDOUT handle.
    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    my $rc = system($^X, "-I$lib", $pm, $prog, @args);
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);
    my $code = $rc < 0 ? -1 : ($rc >> 8);
    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($prog);
    unlink($cap);
    $out = '' unless defined $out;
    return ($code, $out);
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

my @tests = (

# ES01: run_string returns 0 on success
sub {
    my ($rc, $out) = _run_capture("echo hello\n");
    ok_is($rc, 0, 'ES01 run_string returns 0 on success');
},

# ES02: SH exit N is returned
sub {
    my ($rc, $out) = _run_capture("exit 7\n");
    ok_is($rc, 7, 'ES02 run_string returns SH exit code');
},

# ES03: status of the last command is returned
sub {
    my ($rc, $out) = _run_capture("false\n");
    ok_is($rc, 1, 'ES03 run_string returns last command status');
},

# ES04: CMD EXIT /B N is returned
sub {
    my ($rc, $out) = _run_capture("EXIT /B 5\n");
    ok_is($rc, 5, 'ES04 run_string returns CMD EXIT /B code');
},

# ES05: CMD EXIT N (no /B) is returned
sub {
    my ($rc, $out) = _run_capture("EXIT 6\n");
    ok_is($rc, 6, 'ES05 run_string returns CMD EXIT code');
},

# ES06: SH failure -> %ERRORLEVEL% in a following CMD section
sub {
    my ($rc, $out) = _run_capture("false\nECHO EL=%ERRORLEVEL%\n");
    ok_is(($out =~ /EL=1/) ? 1 : 0, 1, 'ES06 SH $? bridges to %ERRORLEVEL%');
},

# ES07: SH failure -> IF ERRORLEVEL fires in a following CMD section
sub {
    my ($rc, $out) = _run_capture("false\nIF ERRORLEVEL 1 ECHO el-fired\n");
    ok_is(($out =~ /el-fired/) ? 1 : 0, 1, 'ES07 IF ERRORLEVEL sees SH status');
},

# ES08: SH success resets %ERRORLEVEL% back to 0
sub {
    my ($rc, $out) = _run_capture("false\ntrue\nECHO EL=%ERRORLEVEL%\n");
    ok_is(($out =~ /EL=0/) ? 1 : 0, 1, 'ES08 SH success bridges 0');
},

# ES09: CMD failure -> $? in a following SH section
sub {
    my ($rc, $out) = _run_capture(
        "TYPE _no_such_file_$$.txt\necho sh-status=\$?\n");
    ok_is(($out =~ /sh-status=[1-9]/) ? 1 : 0, 1,
          'ES09 CMD ERRORLEVEL bridges to SH $?');
},

# ES10: lines after SH exit are not executed
sub {
    my ($rc, $out) = _run_capture("echo before\nexit 2\necho after\n");
    ok_is((($out =~ /before/) && ($out !~ /after/)) ? 1 : 0, 1,
          'ES10 execution stops after SH exit');
},

# ES11: lines after CMD EXIT are not executed (SH section as well)
sub {
    my ($rc, $out) = _run_capture("ECHO before\nEXIT /B 2\necho after\n");
    ok_is((($out =~ /before/) && ($out !~ /after/)) ? 1 : 0, 1,
          'ES11 execution stops after CMD EXIT');
},

# ES12: OS process exit code from the modulino (SH exit)
sub {
    my ($code, $out) = _run_child("exit 3\n");
    ok_is($code, 3, 'ES12 modulino process exit code (SH exit 3)');
},

# ES13: OS process exit code from the modulino (CMD EXIT /B)
sub {
    my ($code, $out) = _run_child("EXIT /B 5\n");
    ok_is($code, 5, 'ES13 modulino process exit code (EXIT /B 5)');
},

# ES14: "-" reads the script from STDIN and passes arguments
sub {
    my $lib = File::Spec->catdir($FindBin::Bin, File::Spec->updir(), 'lib');
    my $pm  = File::Spec->catfile($lib, 'BATsh.pm');
    my $src = "$FindBin::Bin/_es_stdin_$$.batsh";
    my $cap = "$FindBin::Bin/_es_sout_$$.tmp";
    local *PF;
    open(PF, "> $src") or die "cannot write $src: $!";
    print PF "echo arg1=\$1\nexit 4\n";
    close(PF);
    # LIST-form system() with Perl-level STDIN/STDOUT redirection (dup),
    # avoiding a shell "<"/">" string that cmd.exe re-parses on Windows.
    local *OLDIN;
    local *OLDOUT;
    open(OLDIN,  "<&STDIN")  or die "cannot dup STDIN: $!";
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDIN);
    open(STDIN, $src)
        or do { open(STDIN, "<&OLDIN"); die "cannot redirect STDIN: $!" };
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDIN,  "<&OLDIN");  open(STDOUT, ">&OLDOUT");
                die "cannot redirect STDOUT: $!" };
    my $rc = system($^X, "-I$lib", $pm, '-', 'AAA');
    close(STDIN);
    close(STDOUT);
    open(STDIN,  "<&OLDIN")  or die "cannot restore STDIN: $!";
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDIN);
    close(OLDOUT);
    my $code = $rc < 0 ? -1 : ($rc >> 8);
    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($src); unlink($cap);
    $out = '' unless defined $out;
    ok_is(((($out =~ /arg1=AAA/) ? 1 : 0) && $code == 4) ? 1 : 0, 1,
          'ES14 "-" reads STDIN, passes args, propagates exit code');
},

# ES15: exit inside a sourced file terminates the outer script
sub {
    return ok_is(1, 1, "ES15 skipped ($PATH_WHY)") unless $PATH_OK;
    my $inner = "$FindBin::Bin/_es_inner_$$.batsh";
    local *PF;
    open(PF, "> $inner") or die "cannot write $inner: $!";
    print PF "exit 9\n";
    close(PF);
    # Quoted, per rule R8: the build directory is the tester's and on
    # Windows commonly contains a space.  Until 0.11 "source" was the one
    # builtin that could not take a quoted operand -- cd dequoted, source
    # did not -- so this line would have failed with the quotes embedded
    # in the file name.  It now dequotes exactly as cd does.
    my ($rc, $out) = _run_capture(
        "echo outer-start\nsource \"$inner\"\necho outer-after\n");
    unlink($inner);
    ok_is((($rc == 9) && ($out !~ /outer-after/)) ? 1 : 0, 1,
          'ES15 exit in sourced file terminates outer (rc=9)');
},


# ES16: EXIT with no code keeps the current ERRORLEVEL
sub {
    my ($rc, $out) = _run_capture("false\nEXIT /B\n");
    ok_is($rc, 1, 'ES16 bare EXIT /B keeps current ERRORLEVEL');
},

# ES17: the source/. operand is dequoted (0.11).  Single quotes as well
# as double, and the "." spelling as well as "source": all four routes
# reach the same file.  An UNQUOTED operand keeps working unchanged --
# this dequotes, it does not word-split -- and that is checked too,
# because the fix must not have turned a plain path into two words.
sub {
    return ok_is(1, 1, "ES17 skipped ($PATH_WHY)") unless $PATH_OK;
    my $inner = "$FindBin::Bin/_es_dq_$$.batsh";
    local *QF;
    open(QF, "> $inner") or die "cannot write $inner: $!";
    print QF "exit 7\n";
    close(QF);
    my @form = ("source $inner", "source \"$inner\"", "source '$inner'",
                ". \"$inner\"");
    my $bad = '';
    for my $f (@form) {
        my ($rc) = _run_capture("$f\necho reached-the-end\n");
        $bad .= "[$f rc=" . (defined $rc ? $rc : 'undef') . ']'
            unless defined($rc) && $rc == 7;
    }
    unlink($inner);
    ok_is($bad, '', 'ES17 source/. accepts a quoted operand (all four forms)');
},

);

$main::fail = 0;
print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END { $? = 1 if $main::fail }

__END__
