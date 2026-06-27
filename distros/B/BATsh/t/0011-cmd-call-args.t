######################################################################
#
# 0011-cmd-call-args.t  CMD CALL :label argument passing, %~N modifiers
#                       on passed arguments, and SHIFT
#
# Subroutine-completeness tests for v0.06.  Each program is written to a
# temporary .batsh file and run through BATsh->run() so that the full
# positional-parameter path (_set_batch_args + call_sub + expand_cmd) is
# exercised, with STDOUT captured at the file-descriptor level.
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

# Run a list of program lines (written to a temp .batsh file) through
# BATsh->run with the given caller arguments, capturing STDOUT.
sub _run_capture {
    my ($lines_ref, $args_ref) = @_;
    $args_ref = [] unless defined $args_ref;
    BATsh::Env::init();
    my $prog = "$FindBin::Bin/_call_prog_$$.batsh";
    my $cap  = "$FindBin::Bin/_call_cap_$$.tmp";
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

    # CA1: CALL :label passes positional arguments to %1..%9
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SHOW alpha beta',
            'GOTO :EOF',
            ':SHOW',
            'ECHO got [%1] [%2]',
            'RET',
        ]);
        _ok($o eq "got [alpha] [beta]\n", 'CA1: CALL passes %1 %2');
    },

    # CA2: %* inside the subroutine is the joined argument list
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SHOW one two three',
            'GOTO :EOF',
            ':SHOW',
            'ECHO star [%*]',
            'RET',
        ]);
        _ok($o eq "star [one two three]\n", 'CA2: %* inside subroutine');
    },

    # CA3: %0 inside the subroutine is the label token
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :MYSUB x',
            'GOTO :EOF',
            ':MYSUB',
            'ECHO label [%0]',
            'RET',
        ]);
        _ok($o eq "label [:MYSUB]\n", 'CA3: %0 is the label inside subroutine');
    },

    # CA4: the caller's positional parameters are restored after CALL
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SHOW inner',
            'ECHO caller [%1] [%2]',
            'GOTO :EOF',
            ':SHOW',
            'ECHO inner [%1]',
            'RET',
        ], ['OUTER1', 'OUTER2']);
        _ok($o eq "inner [inner]\ncaller [OUTER1] [OUTER2]\n",
            'CA4: caller %1/%2 restored after CALL');
    },

    # CA5: a double-quoted argument is passed as a single parameter
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SHOW "a b c" tail',
            'GOTO :EOF',
            ':SHOW',
            'ECHO p1 [%1] p2 [%2]',
            'RET',
        ]);
        _ok($o eq "p1 [a b c] p2 [tail]\n", 'CA5: quoted argument stays one param');
    },

    # CA6: %~ path modifiers operate on a passed path argument
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :PATHS C:\\dir\\sub\\report.txt',
            'GOTO :EOF',
            ':PATHS',
            'ECHO nx [%~nx1] n [%~n1] x [%~x1]',
            'RET',
        ]);
        _ok($o eq "nx [report.txt] n [report] x [.txt]\n",
            'CA6: %~nx1/%~n1/%~x1 on passed argument');
    },

    # CA7: %~dp1 gives drive+directory of a passed path argument
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :PATHS C:\\dir\\sub\\report.txt',
            'GOTO :EOF',
            ':PATHS',
            'ECHO dp [%~dp1]',
            'RET',
        ]);
        # Separator is normalised to "/" by the tilde expander; drive + dir.
        _ok($o =~ /\Adp \[C:.*dir.*sub.\]\n\z/,
            "CA7: %~dp1 drive+dir on passed argument (got [$o])");
    },

    # CA8: SHIFT moves %2 into %1, %3 into %2, ...
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SH a b c',
            'GOTO :EOF',
            ':SH',
            'SHIFT',
            'ECHO after [%1] [%2]',
            'RET',
        ]);
        _ok($o eq "after [b] [c]\n", 'CA8: SHIFT shifts %1..%9 left');
    },

    # CA9: SHIFT /N begins shifting at %N
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SH a b c d',
            'GOTO :EOF',
            ':SH',
            'SHIFT /2',
            'ECHO after [%1] [%2] [%3]',
            'RET',
        ]);
        _ok($o eq "after [a] [c] [d]\n", 'CA9: SHIFT /N starts at %N');
    },

    # CA10: SHIFT rebuilds %*
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SH a b c',
            'GOTO :EOF',
            ':SH',
            'SHIFT',
            'ECHO star [%*]',
            'RET',
        ]);
        _ok($o eq "star [b c]\n", 'CA10: SHIFT rebuilds %*');
    },

    # CA11: nested CALL restores each frame independently
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :OUTER first',
            'GOTO :EOF',
            ':OUTER',
            'ECHO outer-in [%1]',
            'CALL :INNER second',
            'ECHO outer-back [%1]',
            'RET',
            ':INNER',
            'ECHO inner-in [%1]',
            'RET',
        ]);
        _ok($o eq "outer-in [first]\ninner-in [second]\nouter-back [first]\n",
            'CA11: nested CALL frames restored independently');
    },

    # CA12: an SH-mode subroutine body sees the arguments as $1..$9
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SHSUB hello world',
            'GOTO :EOF',
            ':SHSUB',
            'echo "sh args: $1 $2"',
            'RET',
        ]);
        _ok($o eq "sh args: hello world\n",
            'CA12: SH-mode subroutine body sees $1..$9');
    },

    # CA13: CALL arguments are %-expanded before the call
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'SET WHO=planet',
            'CALL :SHOW %WHO%',
            'GOTO :EOF',
            ':SHOW',
            'ECHO hi [%1]',
            'RET',
        ]);
        _ok($o eq "hi [planet]\n", 'CA13: CALL arguments are %-expanded');
    },

    # CA14: a shorter call does not leak the caller's extra arguments
    sub {
        my $o = _run_capture([
            '@ECHO OFF',
            'CALL :SHOW only',
            'GOTO :EOF',
            ':SHOW',
            'ECHO p1 [%1] p2 [%2]',
            'RET',
        ], ['OUTER1', 'OUTER2', 'OUTER3']);
        _ok($o eq "p1 [only] p2 []\n",
            'CA14: unused params are empty, not inherited from caller');
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
