######################################################################
#
# 0012-cmd-sub-labels.t  GOTO labels inside CMD subroutines
#
# A subroutine body may contain its own :labels as GOTO targets (loops,
# forward skips, early GOTO :EOF return).  These internal labels must
# travel with the body and resolve when the subroutine runs, while
# top-level GOTO labels stay in the main stream.
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

eval { require BATsh } or die "Cannot load BATsh: $@";

sub _run_capture {
    my ($lines_ref, $args_ref) = @_;
    $args_ref = [] unless defined $args_ref;
    BATsh::Env::init();
    my $prog = "$FindBin::Bin/_sublbl_prog_$$.batsh";
    my $cap  = "$FindBin::Bin/_sublbl_cap_$$.tmp";
    local *PF;
    open(PF, "> $prog") or die "cannot write $prog: $!";
    print PF map { "$_\n" } @{$lines_ref};
    close(PF);

    local *OLDOUT;
    open(OLDOUT, ">&STDOUT") or die "cannot dup STDOUT: $!";
    close(STDOUT);
    open(STDOUT, "> $cap")
        or do { open(STDOUT, ">&OLDOUT"); die "cannot redirect STDOUT: $!" };
    eval { BATsh->run($prog, args => [@{$args_ref}]) };
    my $err = $@;
    close(STDOUT);
    open(STDOUT, ">&OLDOUT") or die "cannot restore STDOUT: $!";
    close(OLDOUT);

    my $out = '';
    local *RF;
    if (open(RF, $cap)) { local $/; $out = <RF>; close(RF) }
    unlink($prog);
    unlink($cap);
    $out = '' unless defined $out;
    warn $err if $err;
    return $out;
}

my @tests = (

    # SL1: internal GOTO loop -- sum a variable-length argument list
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SUM 10 20 30 40',
            'GOTO :EOF',
            ':SUM',
            'SET /A TOTAL=0',
            ':SUM_LOOP',
            'IF "%1"=="" GOTO :SUM_DONE',
            'SET /A TOTAL=%TOTAL% + %1',
            'SHIFT',
            'GOTO :SUM_LOOP',
            ':SUM_DONE',
            'ECHO total=%TOTAL%',
            'RET',
        ]);
        _ok($o eq "total=100\n", 'SL1: internal GOTO loop with SHIFT');
    },

    # SL2: the same subroutine works on a second call (fresh frame)
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SUM 1 2 3',
            'CALL :SUM 5 5',
            'GOTO :EOF',
            ':SUM',
            'SET /A TOTAL=0',
            ':SUM_LOOP',
            'IF "%1"=="" GOTO :SUM_DONE',
            'SET /A TOTAL=%TOTAL% + %1',
            'SHIFT',
            'GOTO :SUM_LOOP',
            ':SUM_DONE',
            'ECHO total=%TOTAL%',
            'RET',
        ]);
        _ok($o eq "total=6\ntotal=10\n", 'SL2: internal-label sub reusable');
    },

    # SL3: internal forward GOTO (skip a block inside the subroutine)
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :CHECK ok',
            'CALL :CHECK',
            'GOTO :EOF',
            ':CHECK',
            'IF "%1"=="" GOTO :CHECK_EMPTY',
            'ECHO have [%1]',
            'GOTO :CHECK_END',
            ':CHECK_EMPTY',
            'ECHO empty',
            ':CHECK_END',
            'RET',
        ]);
        _ok($o eq "have [ok]\nempty\n", 'SL3: internal forward GOTO skip');
    },

    # SL4: top-level GOTO labels still work alongside subs with internals
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'GOTO :MAIN',
            ':SKIPPED',
            'ECHO should-not-print',
            ':MAIN',
            'ECHO main',
            'CALL :LOOP3',
            'GOTO :EOF',
            ':LOOP3',
            'SET /A N=3',
            ':LOOP3_TOP',
            'IF %N%==0 GOTO :LOOP3_END',
            'ECHO n=%N%',
            'SET /A N=%N% - 1',
            'GOTO :LOOP3_TOP',
            ':LOOP3_END',
            'RET',
        ]);
        _ok($o eq "main\nn=3\nn=2\nn=1\n",
            'SL4: top-level GOTO label coexists with internal-label sub');
    },

    # SL5: two subroutines, each with its own internal labels
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :A 2',
            'CALL :B 2',
            'GOTO :EOF',
            ':A',
            'SET /A I=0',
            ':A_LOOP',
            'IF %I%==%1 GOTO :A_END',
            'ECHO A%I%',
            'SET /A I=%I% + 1',
            'GOTO :A_LOOP',
            ':A_END',
            'RET',
            ':B',
            'SET /A J=0',
            ':B_LOOP',
            'IF %J%==%1 GOTO :B_END',
            'ECHO B%J%',
            'SET /A J=%J% + 1',
            'GOTO :B_LOOP',
            ':B_END',
            'RET',
        ]);
        _ok($o eq "A0\nA1\nB0\nB1\n",
            'SL5: two subs each with internal labels');
    },

    # SL6: GOTO :EOF inside a subroutine returns early from the body
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :EARLY skip',
            'CALL :EARLY go',
            'GOTO :EOF',
            ':EARLY',
            'IF "%1"=="skip" GOTO :EOF',
            'ECHO ran [%1]',
            'RET',
        ]);
        _ok($o eq "ran [go]\n", 'SL6: GOTO :EOF returns early from subroutine');
    },

    # SL7: nested CALL, each subroutine using internal labels
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :OUTER 2',
            'GOTO :EOF',
            ':OUTER',
            'SET /A K=0',
            ':OUTER_LOOP',
            'IF %K%==%1 GOTO :OUTER_END',
            'CALL :INNER %K%',
            'SET /A K=%K% + 1',
            'GOTO :OUTER_LOOP',
            ':OUTER_END',
            'RET',
            ':INNER',
            'IF "%1"=="" GOTO :INNER_END',
            'ECHO inner=%1',
            ':INNER_END',
            'RET',
        ]);
        _ok($o eq "inner=0\ninner=1\n",
            'SL7: nested CALL with internal labels in both subs');
    },

);

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { exit 1 if $fail }
