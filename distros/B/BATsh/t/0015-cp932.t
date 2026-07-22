######################################################################
#
# 0015-cp932.t  CP932 (Shift_JIS) multibyte-safe execution tests
#
# Verifies that .batsh scripts written in CP932 -- the encoding of
# Japanese Windows -- execute correctly even when characters contain
# trail bytes that collide with ASCII shell metacharacters (the
# classic "dame-moji" / 0x5C problem):
#
#   SO   0x83 0x5C   trail = \   (backslash)
#   HYOU 0x95 0x5C   trail = \
#   PO   0x83 0x7C   trail = |   (pipe)
#   CHI  0x83 0x60   trail = `   (backtick)
#   DA   0x83 0x5E   trail = ^   (cmd.exe escape)
#   PI   0x83 0x73   trail = s   (corrupted by uc/lc)
#
# All CP932 bytes are written as \xNN escapes so this source file
# itself remains US-ASCII.
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
BATsh->set_encoding('cp932');

my $TMPDIR = File::Spec->tmpdir();

# Common CP932 characters whose trail byte is an ASCII metacharacter
my $SO    = "\x83\x5C";                    # katakana SO   (trail \)
my $FU    = "\x83\x74";                    # katakana FU
my $TO    = "\x83\x67";                    # katakana TO
my $HYOU  = "\x95\x5C";                    # kanji HYOU    (trail \)
my $PO    = "\x83\x7C";                    # katakana PO   (trail |)
my $CHI   = "\x83\x60";                    # katakana CHI  (trail `)
my $DA    = "\x83\x5E";                    # katakana DA   (trail ^)
my $PI    = "\x83\x73";                    # katakana PI   (trail s)
my $SOFT  = $SO . $FU . $TO;               # "SOFUTO" (software)

# Capture STDOUT of a code block into a string (5.005_03-compatible)
sub _capture {
    my ($code) = @_;
    my $tmp = File::Spec->catfile($TMPDIR, "batsh_cp932_$$.out");
    local *SAVOUT; local *CAPFH;
    open(SAVOUT, '>&STDOUT') or return '';
    open(CAPFH, "> $tmp")    or do { close(SAVOUT); return '' };
    open(STDOUT, '>&CAPFH')  or do { close(CAPFH); close(SAVOUT); return '' };
    close(CAPFH);
    eval { &{$code}() };
    open(STDOUT, '>&SAVOUT');
    close(SAVOUT);
    my $out = '';
    local *RFH;
    if (open(RFH, "< $tmp")) { local $/; $out = <RFH>; close(RFH) }
    unlink $tmp;
    return defined $out ? $out : '';
}

my @tests = (

    # CP1: SH echo keeps the 0x5C trail byte of SO intact
    sub {
        my $out = _capture(sub { BATsh->run_string("echo $SOFT") });
        _ok($out eq "$SOFT\n", 'CP1: sh echo of SO-FU-TO survives 0x5C');
    },

    # CP2: CMD ECHO keeps the 0x5E (caret) trail byte of DA intact
    sub {
        my $out = _capture(sub { BATsh->run_string("ECHO $DA${SO}X") });
        _ok($out eq "$DA${SO}X\n", 'CP2: CMD ECHO of DA survives caret unescaping');
    },

    # CP3: CMD SET / %VAR% round-trips a value ending in 0x5C (HYOU)
    sub {
        my $out = _capture(sub {
            BATsh->run_string("SET CPV=$HYOU\nECHO [%CPV%]");
        });
        _ok($out eq "[$HYOU]\n", 'CP3: %VAR% round-trip of HYOU (0x5C trail)');
    },

    # CP4: a value containing PO (0x7C trail) is not split as a pipeline
    sub {
        delete $BATsh::Env::STORE{'CP4'};
        BATsh->run_string(join("\n",
            "X=${PO}abc",
            'if [ "$X" = "' . $PO . 'abc" ]; then',
            '    export CP4=ok',
            'fi',
        ));
        my $v = defined $BATsh::Env::STORE{'CP4'} ? $BATsh::Env::STORE{'CP4'} : '';
        _ok($v eq 'ok', 'CP4: PO (0x7C trail) not mistaken for a pipeline');
    },

    # CP5: CHI (0x60 trail) does not trigger backtick command substitution
    sub {
        my $out = _capture(sub { BATsh->run_string("echo $CHI$CHI") });
        _ok($out eq "$CHI$CHI\n", 'CP5: CHI (backtick trail) is literal text');
    },

    # CP6: uc()-safety -- PI (trail 0x73 = "s") survives variable handling
    sub {
        my $out = _capture(sub {
            BATsh->run_string("SET CPU=$PI\nECHO %CPU%");
        });
        _ok($out eq "$PI\n", 'CP6: PI (a-z trail) not corrupted by uc()');
    },

    # CP7: ${#VAR} counts CP932 characters, not bytes
    sub {
        delete $BATsh::Env::STORE{'CP7'};
        BATsh->run_string("X=$SOFT\nexport CP7=\${#X}");
        my $v = defined $BATsh::Env::STORE{'CP7'} ? $BATsh::Env::STORE{'CP7'} : '';
        _ok($v eq '3', 'CP7: ${#VAR} is 3 characters for SO-FU-TO');
    },

    # CP8: ${VAR:1:1} slices by character
    sub {
        my $out = _capture(sub {
            BATsh->run_string("X=$SOFT\necho \${X:1:1}");
        });
        _ok($out eq "$FU\n", 'CP8: ${VAR:1:1} yields the middle character FU');
    },

    # CP9: CMD %VAR:~n,m% slices by character
    sub {
        my $out = _capture(sub {
            BATsh->run_string("SET CPX=$SOFT\nECHO %CPX:~2,1%");
        });
        _ok($out eq "$TO\n", 'CP9: %VAR:~2,1% yields the last character TO');
    },

    # CP10: SH case with a CP932 glob pattern
    sub {
        delete $BATsh::Env::STORE{'CP10'};
        BATsh->run_string(join("\n",
            "X=$SOFT",
            'case $X in',
            "    $SO*) export CP10=matched ;;",
            '    *) export CP10=fallthrough ;;',
            'esac',
        ));
        my $v = defined $BATsh::Env::STORE{'CP10'} ? $BATsh::Env::STORE{'CP10'} : '';
        _ok($v eq 'matched', 'CP10: case pattern "SO*" matches SO-FU-TO');
    },

    # CP11: redirect writes raw CP932 bytes to the file
    sub {
        my $orig = eval { Cwd::cwd() };
        chdir($TMPDIR) if defined $orig;
        my $fname = "batsh_cp11_$$.tmp";
        BATsh->run_string("echo $HYOU$SO > $fname");
        my $data = '';
        local *RF;
        if (open(RF, "< $fname")) { local $/; $data = <RF>; close(RF) }
        unlink($fname);
        chdir($orig) if defined $orig;
        _ok($data eq "$HYOU$SO\n", 'CP11: > redirect writes un-guarded CP932');
    },

    # CP12: a CP932 filename works through redirect, test -f, and IF EXIST
    sub {
        delete $BATsh::Env::STORE{'CP12A'};
        delete $BATsh::Env::STORE{'CP12B'};
        my $orig = eval { Cwd::cwd() };
        chdir($TMPDIR) if defined $orig;
        my $fname = $SO . "_$$.tmp";
        BATsh->run_string(join("\n",
            "echo naka > $fname",
            "if [ -f $fname ]; then",
            '    export CP12A=found',
            'fi',
            "IF EXIST $fname SET CP12B=exists",
        ));
        unlink($fname);
        chdir($orig) if defined $orig;
        my $a = defined $BATsh::Env::STORE{'CP12A'} ? $BATsh::Env::STORE{'CP12A'} : '';
        my $b = defined $BATsh::Env::STORE{'CP12B'} ? $BATsh::Env::STORE{'CP12B'} : '';
        _ok($a eq 'found' && $b eq 'exists',
            'CP12: CP932 filename via redirect + test -f + IF EXIST');
    },

    # CP13: FOR /F reads a CP932 file and preserves the tokens
    sub {
        my $orig = eval { Cwd::cwd() };
        chdir($TMPDIR) if defined $orig;
        my $fname = "batsh_cp13_$$.tmp";
        local *WF;
        my $ok13 = 0;
        if (open(WF, "> $fname")) {
            print WF "$SO $HYOU\n";
            close(WF);
            my $out = _capture(sub {
                BATsh->run_string(
                    "FOR /F \"tokens=1,2\" %%a IN ($fname) DO ECHO %%b-%%a");
            });
            $ok13 = ($out eq "$HYOU-$SO\n");
            unlink($fname);
        }
        chdir($orig) if defined $orig;
        _ok($ok13, 'CP13: FOR /F tokenizes a CP932 file safely');
    },

    # CP14: ${VAR^^} uppercases ASCII but leaves CP932 characters intact
    sub {
        my $out = _capture(sub {
            BATsh->run_string("X=a${SO}b\necho \${X^^}");
        });
        _ok($out eq "A${SO}B\n", 'CP14: ${VAR^^} is CP932-safe');
    },

    # CP15: CMD IF string comparison of CP932 values
    sub {
        delete $BATsh::Env::STORE{'CP15'};
        BATsh->run_string(join("\n",
            "SET L=$HYOU$DA",
            "IF \"%L%\"==\"$HYOU$DA\" SET CP15=equal",
        ));
        my $v = defined $BATsh::Env::STORE{'CP15'} ? $BATsh::Env::STORE{'CP15'} : '';
        _ok($v eq 'equal', 'CP15: IF "%VAR%"=="literal" compares CP932 equal');
    },

    # CP16: sync_to_env exports raw CP932 and skips %-pseudo keys
    sub {
        BATsh::Env->set('CP16V', BATsh::MB::enc($SOFT));
        BATsh::Env->sync_to_env();
        my $raw   = defined $ENV{'CP16V'} ? $ENV{'CP16V'} : '';
        my $nopct = 1;
        for my $k (keys %ENV) { $nopct = 0 if index($k, '%') >= 0 }
        _ok($raw eq $SOFT && $nopct,
            'CP16: %ENV gets raw CP932 values, no %-pseudo keys');
    },

    # CP17: auto-detection activates the guard for CP932 sources
    sub {
        BATsh::MB::set_encoding('none');    # deactivate
        BATsh::MB::set_encoding('auto');    # re-arm detection
        my $out = _capture(sub { BATsh->run_string("echo $SOFT") });
        my $ok17 = ($out eq "$SOFT\n") && (BATsh::MB::active() eq 'cp932');
        BATsh->set_encoding('cp932');       # restore for remaining tests
        _ok($ok17, 'CP17: encoding auto-detection catches CP932');
    },

    # CP18: auto mode passes well-formed UTF-8 through untouched
    sub {
        BATsh::MB::set_encoding('none');
        BATsh::MB::set_encoding('auto');
        my $u  = "\xe3\x81\x82\xe3\x81\x84";   # HIRAGANA A I in UTF-8
        my $out = _capture(sub { BATsh->run_string("echo $u") });
        my $ok18 = ($out eq "$u\n") && (BATsh::MB::active() eq '');
        BATsh->set_encoding('cp932');
        _ok($ok18, 'CP18: UTF-8 source needs no guard and is unchanged');
    },

    # CP19: guard transform is bijective on mixed content
    sub {
        my $mix = "A$SO B$PO C$CHI D$DA E$PI \x01 F$HYOU";
        my $g   = BATsh::MB::enc($mix);
        my $ok19 = (BATsh::MB::dec($g) eq $mix)
                && ($g !~ /[\\\|\`\^\{\}\[\]]/);
        _ok($ok19, 'CP19: enc/dec round-trip; no metacharacter leaks');
    },

    # CP20: mixed CMD + SH sections share a CP932 value via the Env bridge
    sub {
        my $out = _capture(sub {
            BATsh->run_string(join("\n",
                "SET BRIDGE=$SOFT",
                'echo sh:$BRIDGE',
                'ECHO CMD:%BRIDGE%',
            ));
        });
        _ok($out eq "sh:$SOFT\nCMD:$SOFT\n",
            'CP20: CMD<->SH bridge carries CP932 both ways');
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
