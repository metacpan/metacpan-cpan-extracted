######################################################################
#
# 0006-new-features.t  Tests for new features in BATsh-0.02
#
#   1. pmake.bat copyright year (2026 added)
#   2. SET /P  (interactive prompt input via STDIN)
#   3. CMD pipeline (|) via temporary file
#   4. Batch-parameter tilde modifiers (%~dp0, %~nx1, etc.)
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

# Portability: the commands below shell out to a bareword "perl".  On a
# CPAN smoker the perl under test is frequently NOT on PATH as "perl"
# (perlbrew/plenv, or perl invoked by absolute path), so the bareword
# would yield "perl: not found" and an empty result.  Prepend the
# directory of the running interpreter ($^X) to PATH so "perl" always
# resolves to the very perl now running the suite.  This is done by
# environment (not by embedding $^X in the command string), so a Win32
# path with backslashes never reaches SH-mode quote/escape processing.
# Must run BEFORE the first init(), because init() snapshots %ENV into
# BATsh's STORE and sync_to_env() later copies STORE back to %ENV.
{
    my ($pvol, $pdirs) = File::Spec->splitpath($^X);
    my $perldir = File::Spec->catpath($pvol, $pdirs, '');
    if (length $perldir) {
        my $sep = ($^O =~ /^(?:MSWin32|dos|os2)$/) ? ';' : ':';
        $ENV{'PATH'} = (defined($ENV{'PATH'}) && length($ENV{'PATH'}))
                     ? "$perldir$sep$ENV{'PATH'}" : $perldir;
    }
}
BATsh::Env::init();

my @tests = (

    ##################################################################
    # 1. pmake.bat copyright year
    ##################################################################

    # NF01: pmake.bat contains "2026" in copyright line
    sub {
        my $pmake = File::Spec->catfile($FindBin::Bin, '..', 'pmake.bat');
        my $found = 0;
        if (open(PMFH, $pmake)) {
            while (<PMFH>) {
                if (/Copyright.*2026/) { $found = 1; last }
            }
            close(PMFH);
        }
        _ok($found, 'NF01: pmake.bat copyright contains 2026');
    },

    # NF02: pmake.bat copyright matches required format
    sub {
        my $pmake = File::Spec->catfile($FindBin::Bin, '..', 'pmake.bat');
        my $found = 0;
        if (open(PMFH2, $pmake)) {
            while (<PMFH2>) {
                if (/Copyright \(c\) 2008, 2009, 2010, 2018, 2019, 2020, 2021, 2026 INABA Hitoshi/) {
                    $found = 1; last;
                }
            }
            close(PMFH2);
        }
        _ok($found, 'NF02: pmake.bat copyright format correct');
    },

    ##################################################################
    # 2. SET /P -- interactive prompt input
    ##################################################################

    # NF03: SET /P reads from STDIN and stores in variable
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'NF03_VAR'};
        my $prompt_seen = '';
        # Redirect STDIN from a string via a temp file
        my $tmpf = File::Spec->catfile(File::Spec->tmpdir(), "batsh_t6_$$\.tmp");
        local *WFHP;
        open(WFHP, ">$tmpf") or do { _ok(0, 'NF03: SET /P - cannot write tmpfile'); return };
        print WFHP "testvalue\n";
        close(WFHP);
        local *OLDIN;
        open(OLDIN, '<&STDIN') or do { unlink $tmpf; _ok(0, 'NF03: SET /P - cannot save STDIN'); return };
        local *INFH;
        open(INFH, $tmpf) or do { open(STDIN, '<&OLDIN'); close(OLDIN); unlink $tmpf; _ok(0, 'NF03: SET /P - cannot open tmpfile'); return };
        open(STDIN, '<&INFH');
        close(INFH);
        # Also capture stdout to avoid prompt bleeding to terminal
        my $out = _capture(sub {
            BATsh->run_string('SET /P NF03_VAR=Enter value: ');
        });
        open(STDIN, '<&OLDIN');
        close(OLDIN);
        unlink $tmpf;
        my $v = defined($BATsh::Env::STORE{'NF03_VAR'}) ? $BATsh::Env::STORE{'NF03_VAR'} : '';
        _ok($v eq 'testvalue', "NF03: SET /P stores STDIN input (got [$v])");
    },

    # NF04: SET /P prints prompt string to stdout (no trailing newline)
    sub {
        BATsh::Env::init();
        my $tmpf = File::Spec->catfile(File::Spec->tmpdir(), "batsh_t6b_$$\.tmp");
        local *WFHP2;
        open(WFHP2, ">$tmpf") or do { _ok(0, 'NF04: cannot write tmpfile'); return };
        print WFHP2 "answer\n";
        close(WFHP2);
        local *OLDIN2;
        open(OLDIN2, '<&STDIN');
        local *INFH2;
        open(INFH2, $tmpf);
        open(STDIN, '<&INFH2');
        close(INFH2);
        my $out = _capture(sub {
            BATsh->run_string('SET /P NF04_VAR=MyPrompt: ');
        });
        open(STDIN, '<&OLDIN2');
        close(OLDIN2);
        unlink $tmpf;
        _ok($out eq 'MyPrompt:', "NF04: SET /P prints prompt without newline (got [$out])");
    },

    # NF05: SET /P with empty input stores empty string
    sub {
        BATsh::Env::init();
        my $tmpf = File::Spec->catfile(File::Spec->tmpdir(), "batsh_t6c_$$\.tmp");
        local *WFHP3;
        open(WFHP3, ">$tmpf") or do { _ok(0, 'NF05: cannot write tmpfile'); return };
        print WFHP3 "\n";
        close(WFHP3);
        local *OLDIN3;
        open(OLDIN3, '<&STDIN');
        local *INFH3;
        open(INFH3, $tmpf);
        open(STDIN, '<&INFH3');
        close(INFH3);
        _capture(sub { BATsh->run_string('SET /P NF05_VAR=P: ') });
        open(STDIN, '<&OLDIN3');
        close(OLDIN3);
        unlink $tmpf;
        my $v = defined($BATsh::Env::STORE{'NF05_VAR'}) ? $BATsh::Env::STORE{'NF05_VAR'} : 'NOTSET';
        _ok($v eq '', "NF05: SET /P with empty input stores empty string (got [$v])");
    },

    ##################################################################
    # 3. CMD pipeline (|)
    ##################################################################

    # NF06: ECHO foo | TYPE (pipeline: left output becomes right input)
    # We use a BATsh::CMD pipeline where left side ECHOs a known string
    # and right side uses TYPE on stdin (not supported) -- instead we
    # test via a known pattern: left writes to pipe tmp, right reads it.
    # Simplest test: verify _split_compound now returns '|' op.
    sub {
        my @parts = BATsh::CMD::_split_compound('ECHO hello | TYPE');
        my $has_pipe = 0;
        for my $p (@parts) {
            $has_pipe = 1 if ref($p) eq 'HASH' && defined($p->{op}) && $p->{op} eq '|';
        }
        _ok($has_pipe, 'NF06: _split_compound recognises | as pipe op');
    },

    # NF07: pipeline output via SET stores chained result
    # Test: ECHO value written by left side appears as input to right side.
    # We exercise _exec_pipe indirectly through run_string.
    # Since TYPE on STDIN is platform-dependent, we use an external Perl
    # one-liner as the right-hand side to echo stdin back.
    # On systems where perl is available in PATH:
    sub {
        BATsh::Env::init();
        # Write a helper script to capture stdin
        my $helper = File::Spec->catfile(File::Spec->tmpdir(), "batsh_rhs_$$\.pl");
        local *HFHW;
        open(HFHW, ">$helper") or do { _ok(0, 'NF07: cannot write helper'); return };
        print HFHW "while(<STDIN>){chomp;print \"GOT:\$_\n\"}\n";
        close(HFHW);
        my $out = _capture(sub {
            BATsh->run_string("ECHO pipetest | perl $helper");
        });
        unlink $helper;
        $out =~ s/\r//g;
        _ok($out =~ /GOT:pipetest/, "NF07: pipeline passes left stdout to right stdin (got [$out])");
    },

    # NF08: multiple pipes (cmd1 | cmd2 | cmd3)
    sub {
        my @parts = BATsh::CMD::_split_compound('ECHO a | ECHO b | ECHO c');
        my $pipe_count = 0;
        for my $p (@parts) {
            $pipe_count++ if ref($p) eq 'HASH' && defined($p->{op}) && $p->{op} eq '|';
        }
        _ok($pipe_count == 2, "NF08: _split_compound finds 2 pipe ops in triple pipeline (got $pipe_count)");
    },

    ##################################################################
    # 4. Batch-parameter tilde modifiers
    ##################################################################

    # NF09: %~0 strips double-quotes
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%0'} = '"C:\\scripts\\run.bat"';
        my $r = BATsh::Env->expand_cmd('%~0');
        _ok($r eq 'C:\\scripts\\run.bat', "NF09: %~0 strips quotes (got [$r])");
    },

    # NF10: %~x1 gives extension
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%1'} = 'report.txt';
        my $r = BATsh::Env->expand_cmd('%~x1');
        _ok($r eq '.txt', "NF10: %~x1 gives extension (got [$r])");
    },

    # NF11: %~n1 gives basename without extension
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%1'} = 'report.txt';
        my $r = BATsh::Env->expand_cmd('%~n1');
        _ok($r eq 'report', "NF11: %~n1 gives basename (got [$r])");
    },

    # NF12: %~nx1 gives name + extension
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%1'} = '/home/user/report.txt';
        my $r = BATsh::Env->expand_cmd('%~nx1');
        _ok($r eq 'report.txt', "NF12: %~nx1 gives name+ext (got [$r])");
    },

    # NF13: %~p1 gives directory path
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%1'} = File::Spec->catfile('home', 'user', 'report.txt');
        my $r = BATsh::Env->expand_cmd('%~p1');
        # p returns the directory component; should not be empty
        _ok(length($r) > 0, "NF13: %~p1 gives directory path (got [$r])");
    },

    # NF14: %~f1 gives absolute path (non-empty)
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%1'} = 'somefile.txt';
        my $r = BATsh::Env->expand_cmd('%~f1');
        _ok(length($r) > length('somefile.txt'), "NF14: %~f1 gives absolute path (got [$r])");
    },

    # NF15: %~dp0 gives drive+directory of %0 (non-empty)
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%0'} = File::Spec->catfile(File::Spec->tmpdir(), 'myscript.bat');
        my $r = BATsh::Env->expand_cmd('%~dp0');
        _ok(length($r) > 0, "NF15: %~dp0 gives drive+dir (got [$r])");
    },

    # NF16: %~1 with quoted value strips quotes only
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%1'} = '"hello world"';
        my $r = BATsh::Env->expand_cmd('%~1');
        _ok($r eq 'hello world', "NF16: %~1 strips quotes (got [$r])");
    },

    # NF17: %~n0 gives script basename without extension
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%0'} = File::Spec->catfile('scripts', 'deploy.bat');
        my $r = BATsh::Env->expand_cmd('%~n0');
        _ok($r eq 'deploy', "NF17: %~n0 gives script name (got [$r])");
    },

    # NF18: %~x0 gives script extension
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'%0'} = 'deploy.bat';
        my $r = BATsh::Env->expand_cmd('%~x0');
        _ok($r eq '.bat', "NF18: %~x0 gives script extension (got [$r])");
    },

    # NF19: %~2 on unset variable returns empty string
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'%2'};
        my $r = BATsh::Env->expand_cmd('%~2');
        _ok($r eq '', "NF19: %~2 on unset variable returns empty string (got [$r])");
    },

    # NF20: mixed expansion -- normal %VAR% and %~n1 in same string
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'MYDIR'} = 'output';
        $BATsh::Env::STORE{'%1'}    = 'data.csv';
        my $r = BATsh::Env->expand_cmd('%MYDIR%\%~n1');
        _ok($r eq 'output\data', "NF20: mixed %VAR% and %~n1 expansion (got [$r])");
    },


    ##################################################################
    # SH pipeline (|)
    ##################################################################

    # NF21: SH pipeline: left stdout captured, right receives it via stdin
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string(
                "echo pipetest | perl -ne \"print uc\""
            );
        });
        $out =~ s/\r//g;
        _ok($out =~ /PIPETEST/, "NF21: SH pipeline left->right (got [$out])");
    },

    # NF22: SH pipeline does NOT leak left-side output to terminal
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string(
                "echo leftside | perl -ne \"print uc\""
            );
        });
        $out =~ s/\r//g;
        # Only uppercased output should appear; raw "leftside" must not
        _ok($out !~ /leftside/ && $out =~ /LEFTSIDE/,
            "NF22: SH pipeline left output not leaked (got [$out])");
    },

    # NF23: SH multi-stage pipeline (cmd1 | cmd2 | cmd3)
    sub {
        BATsh::Env::init();
        my $helper1 = File::Spec->catfile(File::Spec->tmpdir(), "bsh_h1_$$.pl");
        my $helper2 = File::Spec->catfile(File::Spec->tmpdir(), "bsh_h2_$$.pl");
        local *HF1;
        open(HF1, ">$helper1") or do { _ok(0, 'NF23: write helper1'); return };
        print HF1 "while(<STDIN>){chomp;print uc(\$_).chr(10)}\n";
        close(HF1);
        local *HF2;
        open(HF2, ">$helper2") or do { unlink $helper1; _ok(0, 'NF23: write helper2'); return };
        print HF2 "while(<STDIN>){chomp;print scalar(reverse(\$_)).chr(10)}\n";
        close(HF2);
        my $out = _capture(sub {
            BATsh->run_string("echo hello | perl $helper1 | perl $helper2");
        });
        unlink $helper1; unlink $helper2;
        $out =~ s/\r//g; $out =~ s/\n//g;
        _ok($out eq 'OLLEH', "NF23: SH 3-stage pipeline (got [$out])");
    },

    # NF24: SH ${VAR} bracket expansion
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string("x=hello\necho \${x}world\n");
        });
        $out =~ s/\r?\n\z//;
        _ok($out eq 'helloworld', 'NF24: SH ${VAR} bracket expansion (got [' . $out . '])');
    },

    # NF25: SH ${VAR:-default} when VAR is unset
    sub {
        BATsh::Env::init();
        BATsh::Env->unset('UNDEF_VAR25');
        my $out = _capture(sub {
            BATsh->run_string('echo ${UNDEF_VAR25:-fallback}');
        });
        $out =~ s/\r?\n\z//;
        _ok($out eq 'fallback', "NF25: SH \${VAR:-default} (got [$out])");
    },

    # NF26: SH read VAR reads from STDIN
    sub {
        BATsh::Env::init();
        my $tmpf = File::Spec->catfile(File::Spec->tmpdir(), "bsh_rd_$$.tmp");
        local *RDWF;
        open(RDWF, ">$tmpf") or do { _ok(0, 'NF26: write tmpfile'); return };
        print RDWF "readvalue\n";
        close(RDWF);
        local *RDOLDIN;
        open(RDOLDIN, '<&STDIN');
        local *RDINFH;
        open(RDINFH, $tmpf);
        open(STDIN, '<&RDINFH');
        close(RDINFH);
        _capture(sub { BATsh->run_string('read NF26_VAR') });
        open(STDIN, '<&RDOLDIN');
        close(RDOLDIN);
        unlink $tmpf;
        my $v = defined($BATsh::Env::STORE{'NF26_VAR'}) ? $BATsh::Env::STORE{'NF26_VAR'} : '';
        _ok($v eq 'readvalue', "NF26: SH read VAR from STDIN (got [$v])");
    },


    ##################################################################
    # SH variable expansion (${var%pat}, ${var#pat}, ${#var}, etc.)
    ##################################################################

    # NF27: ${VAR%suffix} removes shortest suffix
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF27V'} = 'hello.tar.gz';
        my $r = BATsh::SH::_expand(undef, '${NF27V%.*}');
        _ok($r eq 'hello.tar', "NF27: \${VAR%.*} shortest suffix removal (got [$r])");
    },

    # NF28: ${VAR%%suffix} removes longest suffix
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF28V'} = 'hello.tar.gz';
        my $r = BATsh::SH::_expand(undef, '${NF28V%%.*}');
        _ok($r eq 'hello', "NF28: \${VAR%%.*} longest suffix removal (got [$r])");
    },

    # NF29: ${VAR#prefix} removes shortest prefix
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF29V'} = 'hello.tar.gz';
        my $r = BATsh::SH::_expand(undef, '${NF29V#*.}');
        _ok($r eq 'tar.gz', "NF29: \${VAR#*.} shortest prefix removal (got [$r])");
    },

    # NF30: ${VAR##prefix} removes longest prefix
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF30V'} = 'hello.tar.gz';
        my $r = BATsh::SH::_expand(undef, '${NF30V##*.}');
        _ok($r eq 'gz', "NF30: \${VAR##*.} longest prefix removal (got [$r])");
    },

    # NF31: ${#VAR} string length
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF31V'} = 'hello';
        my $r = BATsh::SH::_expand(undef, '${#NF31V}');
        _ok($r == 5, "NF31: \${#VAR} string length (got [$r])");
    },

    # NF32: ${VAR^^} uppercase
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF32V'} = 'hello world';
        my $r = BATsh::SH::_expand(undef, '${NF32V^^}');
        _ok($r eq 'HELLO WORLD', "NF32: \${VAR^^} uppercase (got [$r])");
    },

    # NF33: ${VAR,,} lowercase
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF33V'} = 'HELLO WORLD';
        my $r = BATsh::SH::_expand(undef, '${NF33V,,}');
        _ok($r eq 'hello world', "NF33: \${VAR,,} lowercase (got [$r])");
    },

    # NF34: ${VAR:offset:length} substring
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF34V'} = 'abcdefgh';
        my $r = BATsh::SH::_expand(undef, '${NF34V:2:4}');
        _ok($r eq 'cdef', "NF34: \${VAR:2:4} substring (got [$r])");
    },

    # NF35: ${VAR/pat/rep} replace first occurrence
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF35V'} = 'aabbcc';
        my $r = BATsh::SH::_expand(undef, '${NF35V/bb/XX}');
        _ok($r eq 'aaXXcc', "NF35: \${VAR/pat/rep} (got [$r])");
    },

    # NF36: ${VAR//pat/rep} replace all occurrences
    sub {
        BATsh::Env::init();
        $BATsh::Env::STORE{'NF36V'} = 'aabbccbb';
        my $r = BATsh::SH::_expand(undef, '${NF36V//bb/XX}');
        _ok($r eq 'aaXXccXX', "NF36: \${VAR//pat/rep} global replace (got [$r])");
    },

    # NF37: SH function definition and call with $1 argument
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string("greet() {\necho hello \$1\n}\ngreet world\n");
        });
        $out =~ s/\r?\n\z//;
        _ok($out eq 'hello world', "NF37: SH function def and call with \$1 (got [$out])");
    },

    # NF38: SH function with arithmetic using positional params
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string("add() {\necho \$(( \$1 + \$2 ))\n}\nadd 3 4\n");
        });
        $out =~ s/\r?\n\z//;
        _ok($out == 7, "NF38: SH function arithmetic \$1+\$2 (got [$out])");
    },

    # NF39: SH inline function definition: name() { cmd; }
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string("double() { echo \$(( \$1 * 2 )); }\ndouble 7\n");
        });
        $out =~ s/\r?\n\z//;
        _ok($out == 14, "NF39: SH inline function (got [$out])");
    },

    # NF40: SH function name() args restored after call
    sub {
        BATsh::Env::init();
        BATsh::Env->set('%1', 'outer');
        my $out = _capture(sub {
            BATsh->run_string(
                "show() {\necho in:\$1\n}\nshow inner\necho after:\$1\n"
            );
        });
        $out =~ s/\r//g;
        my @lines_got = split /\n/, $out;
        _ok($lines_got[0] eq 'in:inner' && $lines_got[1] eq 'after:outer',
            "NF40: SH function restores caller args (got [" . join('|', @lines_got) . "])");
    },

    # NF41: backtick command substitution
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string('x=`echo hello`' . "\necho \$x\n");
        });
        $out =~ s/\r?\n\z//;
        _ok($out eq 'hello', "NF41: backtick substitution (got [$out])");
    },

    # NF42: $1..$9 inside $(( )) arithmetic
    sub {
        BATsh::Env::init();
        BATsh::Env->set('%1', '5');
        BATsh::Env->set('%2', '3');
        my $r = BATsh::SH::_expand(undef, '$(( $1 * $2 ))');
        _ok($r == 15, "NF42: \$1*\$2 inside \$(( )) (got [$r])");
    },


    ##################################################################
    # SH compound: && / || / ;
    ##################################################################

    # NF43: true && cmd runs cmd
    sub {
        BATsh::Env::init();
        my $out = _capture(sub { BATsh->run_string('true && echo yes') });
        $out =~ s/\r?\n\z//;
        _ok($out eq 'yes', "NF43: true && echo yes (got [$out])");
    },

    # NF44: false && cmd skips cmd
    sub {
        BATsh::Env::init();
        my $out = _capture(sub { BATsh->run_string('false && echo no') });
        $out =~ s/\r?\n\z//;
        _ok($out eq '', "NF44: false && echo skipped (got [$out])");
    },

    # NF45: false || cmd runs cmd
    sub {
        BATsh::Env::init();
        my $out = _capture(sub { BATsh->run_string('false || echo fallback') });
        $out =~ s/\r?\n\z//;
        _ok($out eq 'fallback', "NF45: false || echo (got [$out])");
    },

    # NF46: semicolon chains two commands
    sub {
        BATsh::Env::init();
        my $out = _capture(sub { BATsh->run_string('echo a; echo b') });
        $out =~ s/\r//g; my @g = split /\n/, $out;
        _ok(@g == 2 && $g[0] eq 'a' && $g[1] eq 'b',
            "NF46: semicolon chain (got [" . join('|', @g) . "])");
    },

    # NF47: false && X || Y gives Y
    sub {
        BATsh::Env::init();
        my $out = _capture(sub { BATsh->run_string('false && echo X || echo Y') });
        $out =~ s/\r?\n\z//;
        _ok($out eq 'Y', "NF47: false && X || Y chain (got [$out])");
    },

    ##################################################################
    # SH shift
    ##################################################################

    # NF48: shift moves $2 into $1
    sub {
        BATsh::Env::init();
        BATsh::_set_batch_args('s.sh', 'one', 'two', 'three');
        my $out = _capture(sub { BATsh->run_string("echo \$1\nshift\necho \$1\n") });
        $out =~ s/\r//g; my @g = split /\n/, $out;
        _ok($g[0] eq 'one' && $g[1] eq 'two',
            "NF48: shift updates \$1 (got [" . join('|', @g) . "])");
    },

    # NF49: shift rebuilds $*
    sub {
        BATsh::Env::init();
        BATsh::_set_batch_args('s.sh', 'a', 'b', 'c');
        BATsh->run_string('shift');
        my $star = BATsh::Env->get('%*'); $star = '' unless defined $star;
        _ok($star eq 'b c', "NF49: shift rebuilds %* (got [$star])");
    },

    ##################################################################
    # SH local variable scope
    ##################################################################

    # NF50: local is restored after function returns
    sub {
        BATsh::Env::init();
        BATsh::Env->set('NFVAR50', 'outer');
        my $out = _capture(sub {
            BATsh->run_string(
                "f50() {\n  local NFVAR50=inner\n  echo \$NFVAR50\n}\nf50\necho \$NFVAR50\n"
            );
        });
        $out =~ s/\r//g; my @g = split /\n/, $out;
        _ok(@g == 2 && $g[0] eq 'inner' && $g[1] eq 'outer',
            "NF50: local scope restored (got [" . join('|', @g) . "])");
    },

    # NF51: local without =value still restores original
    sub {
        BATsh::Env::init();
        BATsh::Env->set('NFVAR51', 'keep');
        my $out = _capture(sub {
            BATsh->run_string(
                "g51() {\n  local NFVAR51\n  NFVAR51=changed\n  echo \$NFVAR51\n}\ng51\necho \$NFVAR51\n"
            );
        });
        $out =~ s/\r//g; my @g = split /\n/, $out;
        _ok(@g == 2 && $g[0] eq 'changed' && $g[1] eq 'keep',
            "NF51: local var restores after return (got [" . join('|', @g) . "])");
    },

    ##################################################################
    # $0 absolute path
    ##################################################################

    # NF52: _set_batch_args makes $0 absolute
    sub {
        BATsh::Env::init();
        BATsh::_set_batch_args('relative.sh');
        my $v = BATsh::Env->get('%0'); $v = '' unless defined $v;
        _ok(File::Spec->file_name_is_absolute($v),
            "NF52: \$0 is absolute (got [$v])");
    },

    # NF53: _set_batch_args preserves already-absolute $0
    sub {
        BATsh::Env::init();
        my $abs = File::Spec->catfile(File::Spec->tmpdir(), 'test.sh');
        BATsh::_set_batch_args($abs);
        my $v = BATsh::Env->get('%0'); $v = '' unless defined $v;
        _ok($v eq $abs, "NF53: absolute \$0 preserved (got [$v])");
    },

    ##################################################################
    # Here-document (<<)
    ##################################################################

    # NF54: here-document feeds STDIN to a builtin (read)
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'NF54_V'};
        BATsh->run_string("read NF54_V <<EOF\nfromheredoc\nEOF");
        my $v = $BATsh::Env::STORE{'NF54_V'};
        $v = '' unless defined $v;
        _ok($v eq 'fromheredoc', "NF54: heredoc feeds builtin read (got [$v])");
    },

    # NF55: unquoted delimiter expands variables in body
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'NF55_V'};
        BATsh->run_string("NF55_N=ina\nread NF55_V <<EOF\nhi \$NF55_N\nEOF");
        my $v = $BATsh::Env::STORE{'NF55_V'};
        $v = '' unless defined $v;
        _ok($v eq 'hi ina', "NF55: unquoted heredoc expands (got [$v])");
    },

    # NF56: quoted delimiter suppresses expansion
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'NF56_V'};
        BATsh->run_string("NF56_N=ina\nread NF56_V <<'EOF'\nhi \$NF56_N\nEOF");
        my $v = $BATsh::Env::STORE{'NF56_V'};
        $v = '' unless defined $v;
        _ok($v eq 'hi $NF56_N', "NF56: quoted heredoc no expansion (got [$v])");
    },

    # NF57: <<- strips leading tabs from body and delimiter
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'NF57_V'};
        BATsh->run_string("read NF57_V <<-EOF\n\t\tindented\n\tEOF");
        my $v = $BATsh::Env::STORE{'NF57_V'};
        $v = '' unless defined $v;
        _ok($v eq 'indented', "NF57: <<- strips leading tabs (got [$v])");
    },

    # NF58: an uppercase body line is NOT reclassified to CMD mode
    #       (top-level classification protection); it stays literal text.
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'NF58_V'};
        BATsh->run_string("read NF58_V <<EOF\nECHO LITERAL TEXT\nEOF");
        my $v = $BATsh::Env::STORE{'NF58_V'};
        $v = '' unless defined $v;
        _ok($v eq 'ECHO LITERAL TEXT',
            "NF58: uppercase body line stays literal (got [$v])");
    },

    # NF59: a section after a heredoc still executes (no section break)
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string("read NF59_V <<EOF\nbody\nEOF\necho after=\$NF59_V");
        });
        $out =~ s/\r//g;
        _ok($out =~ /after=body/, "NF59: command after heredoc runs (got [$out])");
    },

    # NF60: heredoc feeds STDIN to an external command (portable perl)
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string(
                "perl -ne \"print uc\" <<EOF\nhello\nworld\nEOF"
            );
        });
        $out =~ s/\r//g;
        _ok($out =~ /HELLO/ && $out =~ /WORLD/,
            "NF60: heredoc feeds external command stdin (got [$out])");
    },

    # NF61: empty body yields EOF immediately, following command runs
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string("read NF61_V <<EOF\nEOF\necho done61");
        });
        $out =~ s/\r//g;
        _ok($out =~ /done61/, "NF61: empty heredoc body ok (got [$out])");
    },

    # NF62: unterminated here-document sets non-zero status
    sub {
        BATsh::Env::init();
        _capture(sub {
            local $SIG{'__WARN__'} = sub { };   # silence expected warning
            BATsh->run_string("read NF62_V <<EOF\nno terminator");
        });
        _ok(BATsh::SH::last_status() != 0,
            "NF62: unterminated heredoc => non-zero status (got ["
            . BATsh::SH::last_status() . "])");
    },

    # NF63: << inside quotes is NOT treated as a here-document opener
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string('echo "a << b"');
        });
        $out =~ s/\r//g;
        _ok($out =~ /a << b/, "NF63: quoted << not a heredoc (got [$out])");
    },

    ##################################################################
    # 5. Background execution (trailing &)  -- SH mode, v1
    ##################################################################

    # NF64: trailing & is detected and stripped
    sub {
        my ($bg, $s) = BATsh::SH::_split_trailing_bg('echo hi &');
        _ok($bg == 1 && $s eq 'echo hi',
            "NF64: trailing & stripped (bg=$bg strip=[$s])");
    },

    # NF65: && compound operator is NOT background
    sub {
        my ($bg, $s) = BATsh::SH::_split_trailing_bg('echo a && echo b');
        _ok($bg == 0 && $s eq 'echo a && echo b',
            "NF65: && is not background (bg=$bg)");
    },

    # NF66: internal & of 2>&1 preserved, only trailing & removed
    sub {
        my ($bg, $s) = BATsh::SH::_split_trailing_bg('cmd 2>&1 &');
        _ok($bg == 1 && $s eq 'cmd 2>&1',
            "NF66: 2>&1 not mis-split (bg=$bg strip=[$s])");
    },

    # NF67: fd-duplication >&2 preserved, only trailing & removed
    sub {
        my ($bg, $s) = BATsh::SH::_split_trailing_bg('cmd >&2 &');
        _ok($bg == 1 && $s eq 'cmd >&2',
            "NF67: >&2 not mis-split (bg=$bg strip=[$s])");
    },

    # NF68: & inside quotes is NOT background
    sub {
        my ($bg, $s) = BATsh::SH::_split_trailing_bg('echo "a & b"');
        _ok($bg == 0, "NF68: quoted & not background (bg=$bg)");
    },

    # NF69: a bare & (nothing to run) is NOT background
    sub {
        my ($bg, $s) = BATsh::SH::_split_trailing_bg('&');
        _ok($bg == 0, "NF69: bare & not background (bg=$bg)");
    },

    # NF70: foreground-word predicate (builtin / assignment vs external)
    sub {
        my $b1 = BATsh::SH::_sh_word_is_foreground('echo');     # builtin
        my $b2 = BATsh::SH::_sh_word_is_foreground('NF70_V=1'); # assignment
        my $b3 = BATsh::SH::_sh_word_is_foreground('myextprog');# external
        _ok($b1 && $b2 && !$b3,
            "NF70: fg predicate (echo=$b1 assign=$b2 ext=$b3)");
    },

    # NF71: $! expands to the last background PID (empty before any job)
    sub {
        BATsh::Env::init();
        $BATsh::SH::_LAST_BG_PID = '';
        my $empty = BATsh::SH::_expand('BATsh::SH', '[$!]');
        $BATsh::SH::_LAST_BG_PID = 4242;
        my $set   = BATsh::SH::_expand('BATsh::SH', 'pid=$!');
        $BATsh::SH::_LAST_BG_PID = '';
        _ok($empty eq '[]' && $set eq 'pid=4242',
            "NF71: \$! expansion (empty=[$empty] set=[$set])");
    },

    # NF72: builtin echo with trailing & runs in the foreground
    sub {
        BATsh::Env::init();
        my $out = _capture(sub {
            BATsh->run_string('echo fgbuiltin &');
        });
        $out =~ s/\r//g;
        _ok($out =~ /fgbuiltin/,
            "NF72: builtin & runs foreground (got [$out])");
    },

    # NF73: assignment with trailing & still runs in the foreground
    sub {
        BATsh::Env::init();
        delete $BATsh::Env::STORE{'NF73_V'};
        BATsh->run_string('NF73_V=fgvalue &');
        my $v = $BATsh::Env::STORE{'NF73_V'};
        $v = '' unless defined $v;
        _ok($v eq 'fgvalue',
            "NF73: assignment & runs foreground (got [$v])");
    },

    # NF74: launching an external in the background sets $? = 0 and a
    # numeric (or empty) $!, without blocking.  Uses $^X (the running
    # perl) so the test is portable.
    sub {
        BATsh::Env::init();
        $BATsh::SH::_LAST_BG_PID = '';
        my $perl = $^X;
        my $pid;
        _capture(sub {
            BATsh->run_string("\"$perl\" -e 1 &\necho st=\$?");
        });
        $pid = $BATsh::SH::_LAST_BG_PID;
        $pid = '' unless defined $pid;
        _ok($pid =~ /\A\d*\z/,
            "NF74: background launch records numeric/empty PID (pid=[$pid])");
    },

    # NF75: a backslash-escaped trailing & is NOT background
    sub {
        my ($bg, $s) = BATsh::SH::_split_trailing_bg('cmd \\&');
        _ok($bg == 0, "NF75: escaped \\& not background (bg=$bg)");
    },

);

######################################################################
# Stdout capture helper (Perl 5.005_03 compatible)
######################################################################
use vars qw(*_CAP_OLD *_CAP_FH *_CAP_RFH);
sub _capture {
    my ($code) = @_;
    my $tmpfile = File::Spec->catfile(
        File::Spec->tmpdir(), "batsh_cap6_$$\.tmp");
    open(_CAP_OLD, '>&STDOUT') or return '';
    open(_CAP_FH,  ">$tmpfile") or do { open(STDOUT, '>&_CAP_OLD'); return '' };
    open(STDOUT, '>&_CAP_FH');
    close(_CAP_FH);
    eval { $code->() };
    open(STDOUT, '>&_CAP_OLD');
    close(_CAP_OLD);
    my $buf = '';
    if (open(_CAP_RFH, "< $tmpfile")) {
        local $/;
        $buf = <_CAP_RFH>;
        close(_CAP_RFH);
    }
    unlink $tmpfile;
    $buf = '' unless defined $buf;
    return $buf;
}

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    $name = '' unless defined $name;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { $? = 1 if $fail }
