######################################################################
#
# 0005-verify_compat.t  cmd.exe compatibility: 6 items
#
# Verifies the 6 compatibility fixes implemented in v0.02:
#   1. Environment variable case-insensitivity
#   2. ^ escape character
#   3. I/O redirection (> >> 2> <)
#   4. SETLOCAL ENABLEDELAYEDEXPANSION / !VAR!
#   5. IF/FOR block %VAR% parse-time expansion
#   6. FOR /F (tokens= delims= skip= eol= usebackq)
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
BATsh::Env::init();

# ----------------------------------------------------------------
# Helpers (Perl 5.005 compatible: bareword FH, no //, no my-open)
# ----------------------------------------------------------------
my $TMPBASE = File::Spec->catfile(File::Spec->tmpdir(), "batsh_vc_$$");

sub _capture_cmd {
    my (@lines) = @_;
    for my $l (@lines) { $l .= "\n" unless $l =~ /\n\z/ }
    BATsh::Env::init();
    my $tmp = "${TMPBASE}_cap.tmp";
    local *VCOLD; local *VCCAP;
    open(VCOLD, '>&STDOUT') or return '';
    open(VCCAP, "> $tmp")   or do { open(STDOUT,'>&VCOLD'); return '' };
    open(STDOUT, '>&VCCAP');
    eval {
        BATsh::CMD::exec_block('BATsh::CMD', \@lines,
            _batsh => 'BATsh', _pushd_stack => []);
    };
    my $err = $@;
    open(STDOUT, '>&VCOLD');
    close(VCCAP); close(VCOLD);
    my $buf = '';
    if (open(VCREAD, "< $tmp")) {
        local $/; $buf = <VCREAD>; close(VCREAD);
    }
    unlink $tmp;
    $buf = '' unless defined $buf;
    warn $err if $err;
    return $buf;
}

sub _tmpfile {
    my ($name, @lines) = @_;
    my $path = "${TMPBASE}_${name}.tmp";
    local *TMPWFH;
    open(TMPWFH, "> $path") or die "Cannot write $path: $!";
    for my $l (@lines) { print TMPWFH $l }
    close(TMPWFH);
    return $path;
}

# ----------------------------------------------------------------
# Test array (Perl 5.005 compatible closure style)
# ----------------------------------------------------------------
my @tests = (

    # ==============================================================
    # Step 1: Environment variable case-insensitivity
    # ==============================================================

    sub {
        my $out = _capture_cmd('SET myvar=lower', 'ECHO %MYVAR%', 'ECHO %myvar%');
        _ok($out eq "lower\nlower\n", '1-1: SET lowercase -> %UPPERCASE% and %lowercase%');
    },

    sub {
        my $out = _capture_cmd('SET UPPER=hello', 'ECHO %upper%');
        _ok($out eq "hello\n", '1-2: SET uppercase -> %lowercase% lookup');
    },

    sub {
        my $out = _capture_cmd('SET A=first', 'SET a=second', 'ECHO %A%');
        _ok($out eq "second\n", '1-3: mixed case refers to same variable');
    },

    # ==============================================================
    # Step 2: ^ escape character
    # ==============================================================

    sub {
        my $out = _capture_cmd('ECHO a^&b');
        _ok($out eq "a&b\n", '2-1: ^& -> literal &');
    },

    sub {
        my $out = _capture_cmd('ECHO a^^b');
        _ok($out eq "a^b\n", '2-2: ^^ -> literal ^');
    },

    sub {
        my $out = _capture_cmd('ECHO hello^', 'world');
        _ok($out eq "helloworld\n", '2-3: ^ line continuation');
    },

    sub {
        my $out = _capture_cmd('ECHO a^>b');
        _ok($out eq "a>b\n", '2-4: ^> -> literal > (not a redirect)');
    },

    # ==============================================================
    # Step 3: I/O redirection
    # ==============================================================

    sub {
        my $tmp = "${TMPBASE}_r1.tmp";
        my $out = _capture_cmd("ECHO redirected_line > $tmp", "TYPE $tmp");
        unlink $tmp;
        _ok($out eq "redirected_line\n", '3-1: > overwrite redirect + TYPE');
    },

    sub {
        my $tmp = "${TMPBASE}_r2.tmp";
        my $out = _capture_cmd(
            "ECHO line1 > $tmp",
            "ECHO line2 >> $tmp",
            "TYPE $tmp",
        );
        unlink $tmp;
        _ok($out eq "line1\nline2\n", '3-2: >> append redirect + TYPE');
    },

    sub {
        my $tmp = _tmpfile('r3', "input_content\n");
        my $out = _capture_cmd("TYPE $tmp");
        unlink $tmp;
        _ok($out eq "input_content\n", '3-3: TYPE reads file content');
    },

    # ==============================================================
    # Step 4: SETLOCAL ENABLEDELAYEDEXPANSION + !VAR!
    # ==============================================================

    sub {
        my $out = _capture_cmd(
            'SETLOCAL ENABLEDELAYEDEXPANSION',
            'SET X=before',
            'IF 1==1 (',
            '    SET X=after',
            '    ECHO !X!',
            ')',
            'ENDLOCAL',
        );
        _ok($out eq "after\n", '4-1: IF block SET -> !VAR! sees new value');
    },

    sub {
        my $out = _capture_cmd(
            'SETLOCAL ENABLEDELAYEDEXPANSION',
            'SET CNT=0',
            'FOR %%i IN (a b c) DO (',
            '    SET /A CNT=CNT+1',
            '    ECHO !CNT!',
            ')',
            'ENDLOCAL',
        );
        _ok($out eq "1\n2\n3\n", '4-2: FOR block counter with !CNT!');
    },

    sub {
        my $out = _capture_cmd(
            'SETLOCAL ENABLEDELAYEDEXPANSION',
            'SET X=inside',
            'ENDLOCAL',
            'ECHO !X!',
        );
        _ok($out eq "!X!\n", '4-3: after ENDLOCAL !VAR! is not expanded');
    },

    sub {
        my $out = _capture_cmd(
            'SETLOCAL ENABLEDELAYEDEXPANSION',
            'SET INNER=inner_val',
            'ECHO !INNER!',
            'ENDLOCAL',
            'ECHO !INNER!',
        );
        _ok($out eq "inner_val\n!INNER!\n", '4-4: nested SETLOCAL/ENDLOCAL scope');
    },

    # ==============================================================
    # Step 5: IF/FOR block %VAR% parse-time expansion
    # ==============================================================

    sub {
        my $out = _capture_cmd(
            'SET X=before',
            'IF 1==1 (',
            '    SET X=after',
            '    ECHO %X%',
            ')',
        );
        _ok($out eq "before\n", '5-1: IF block %VAR% is parse-time value (before)');
    },

    sub {
        my $out = _capture_cmd(
            'SET Y=original',
            'IF 1==2 (',
            '    ECHO then',
            ') ELSE (',
            '    SET Y=changed',
            '    ECHO %Y%',
            ')',
        );
        _ok($out eq "original\n", '5-2: ELSE block %VAR% is parse-time value (original)');
    },

    sub {
        my $out = _capture_cmd(
            'SET CNT=0',
            'FOR %%i IN (a b c) DO (',
            '    SET CNT=%%i',
            '    ECHO %CNT%',
            ')',
        );
        _ok($out eq "0\n0\n0\n", '5-3: FOR block %CNT% locked at FOR-line parse time (0)');
    },

    sub {
        my $out = _capture_cmd('SET Z=first', 'SET Z=second', 'ECHO %Z%');
        _ok($out eq "second\n", '5-4: outside blocks %VAR% is runtime (sees latest SET)');
    },

    # ==============================================================
    # Step 6: FOR /F
    # ==============================================================

    sub {
        my $out = _capture_cmd(
            'FOR /F "tokens=1,2 delims=," %%a IN ("hello,world") DO ECHO %%a / %%b',
        );
        _ok($out eq "hello / world\n", '6-1: FOR /F tokens=1,2 delims=,');
    },

    sub {
        my $out = _capture_cmd(
            'FOR /F "tokens=2" %%a IN ("alpha beta gamma") DO ECHO %%a',
        );
        _ok($out eq "beta\n", '6-2: FOR /F tokens=2 (default delims=space)');
    },

    sub {
        my $tmp = _tmpfile('ff3', "skip_this\n", "use_this\n");
        my $out = _capture_cmd("FOR /F \"skip=1\" %%a IN ($tmp) DO ECHO %%a");
        unlink $tmp;
        _ok($out eq "use_this\n", '6-3: FOR /F skip=1');
    },

    sub {
        my $out = _capture_cmd(
            'FOR /F "tokens=1*" %%a IN ("one two three") DO ECHO [%%a][%%b]',
        );
        _ok($out eq "[one][two three]\n", '6-4: FOR /F tokens=1* (star=remainder)');
    },

    sub {
        my $tmp = _tmpfile('ff5', "#comment\n", "data_line\n");
        my $out = _capture_cmd("FOR /F \"eol=#\" %%a IN ($tmp) DO ECHO %%a");
        unlink $tmp;
        _ok($out eq "data_line\n", '6-5: FOR /F eol=# skips lines');
    },

    sub {
        my $tmp = _tmpfile('ff6', "key1:val1\n", "key2:val2\n");
        my $out = _capture_cmd(
            "FOR /F \"tokens=1,2 delims=:\" %%a IN ($tmp) DO ECHO %%a=%%b",
        );
        unlink $tmp;
        _ok($out eq "key1=val1\nkey2=val2\n", '6-6: FOR /F multi-line file key:value');
    },

    # ==============================================================
    # Additional: ERRORLEVEL / IF /I / compound / SET /A
    # ==============================================================

    sub {
        my $out = _capture_cmd('ECHO a & ECHO b');
        _ok($out eq "a\nb\n", 'A-1: & sequential execution');
    },

    sub {
        my $out = _capture_cmd('IF /I "Hello"=="hello" ECHO match');
        _ok($out eq "match\n", 'A-2: IF /I case-insensitive comparison');
    },

    sub {
        BATsh::Env::init();
        BATsh::CMD::set_errorlevel('BATsh::CMD', 5);
        _capture_cmd('ECHO something');
        my $el = BATsh::CMD::errorlevel('BATsh::CMD');
        _ok($el != 0, 'A-3: ECHO does not reset ERRORLEVEL to 0');
    },

    sub {
        BATsh::Env::init();
        BATsh::CMD::set_errorlevel('BATsh::CMD', 2);
        my $out = _capture_cmd(
            'IF ERRORLEVEL 1 ECHO ge1',
            'IF ERRORLEVEL 2 ECHO ge2',
            'IF ERRORLEVEL 3 ECHO ge3',
        );
        _ok($out eq "ge1\nge2\n", 'A-4: ERRORLEVEL >= n evaluation');
    },

    sub {
        my $out = _capture_cmd(
            'SET /A X=3+4',
            'ECHO %X%',
            'SET /A Y=X*2',
            'ECHO %Y%',
        );
        _ok($out eq "7\n14\n", 'A-5: SET /A arithmetic (3+4=7, 7*2=14)');
    },

    sub {
        my $tmp = "${TMPBASE}_space test.tmp";
        local *SPTMP;
        open(SPTMP, "> $tmp") or do { _ok(1, 'A-6: skip (cannot create space-path)'); return };
        print SPTMP "x\n";
        close(SPTMP);
        my $out = _capture_cmd(qq{IF EXIST "$tmp" ECHO found});
        unlink $tmp;
        _ok($out eq "found\n", 'A-6: IF EXIST with quoted path containing spaces');
    },

    sub {
        my $out = _capture_cmd('IF NOT "a"=="b" ECHO notequal');
        _ok($out eq "notequal\n", 'A-7: IF NOT string comparison');
    },

    sub {
        my $out = _capture_cmd('SET X=ok', 'ECHO %X% && ECHO right');
        _ok($out eq "ok\nright\n", 'A-8: && runs right side only on success');
    },

);

# ----------------------------------------------------------------
# TAP output
# ----------------------------------------------------------------
print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);

sub _ok {
    my ($ok, $name) = @_;
    $run++;
    $fail++ unless $ok;
    $name = '' unless defined $name;
    $name =~ s/\r?\n/ /g;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}

$_->() for @tests;

END { exit 1 if $fail }
