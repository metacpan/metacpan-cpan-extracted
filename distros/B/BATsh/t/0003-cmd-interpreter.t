######################################################################
#
# 0003-cmd-interpreter.t  BATsh::CMD pure Perl interpreter tests
#
# Tests CMD execution without any external cmd.exe.
# All tests run via BATsh::CMD directly (no system() calls needed).
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

my @tests = (

    # CMD1: SET stores variable in Env store
    sub {
        delete $BATsh::Env::STORE{'CMD_T1'};
        BATsh->run_string("SET CMD_T1=hello_cmd");
        _ok(( defined( $BATsh::Env::STORE{'CMD_T1'} ) ? $BATsh::Env::STORE{'CMD_T1'} : '' ) eq 'hello_cmd',
            'CMD1: SET stores variable');
    },

    # CMD2: ECHO expands %VAR%
    sub {
        $BATsh::Env::STORE{'CMD_T2'} = 'world';
        my $out = _capture(sub { BATsh->run_string('ECHO %CMD_T2%') });
        _ok($out =~ /world/, 'CMD2: ECHO expands %VAR%');
    },

    # CMD3: IF condition true
    sub {
        delete $BATsh::Env::STORE{'CMD_T3'};
        BATsh->run_string(join("\n",
            'SET CMD_T3=before',
            'IF "1"=="1" SET CMD_T3=if_true',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T3'} ) ? $BATsh::Env::STORE{'CMD_T3'} : '' ) eq 'if_true',
            'CMD3: IF condition true');
    },

    # CMD4: IF condition false
    sub {
        delete $BATsh::Env::STORE{'CMD_T4'};
        BATsh->run_string(join("\n",
            'SET CMD_T4=before',
            'IF "1"=="2" SET CMD_T4=should_not_set',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T4'} ) ? $BATsh::Env::STORE{'CMD_T4'} : '' ) eq 'before',
            'CMD4: IF condition false');
    },

    # CMD5: IF ... ( ... ) ELSE ( ... ) multiline
    sub {
        delete $BATsh::Env::STORE{'CMD_T5'};
        BATsh->run_string(join("\n",
            'IF "x"=="y" (',
            '    SET CMD_T5=wrong',
            ') ELSE (',
            '    SET CMD_T5=else_ok',
            ')',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T5'} ) ? $BATsh::Env::STORE{'CMD_T5'} : '' ) eq 'else_ok',
            'CMD5: IF/ELSE multiline block');
    },

    # CMD6: FOR %%V IN (list) DO
    sub {
        delete $BATsh::Env::STORE{'CMD_T6'};
        BATsh->run_string(join("\n",
            'SET CMD_T6=',
            'FOR %%I IN (A B C) DO SET CMD_T6=%CMD_T6%%%I',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T6'} ) ? $BATsh::Env::STORE{'CMD_T6'} : '' ) eq 'ABC',
            'CMD6: FOR %%V IN (list) DO accumulates');
    },

    # CMD7: FOR /L %%N IN (1,1,5) DO
    sub {
        delete $BATsh::Env::STORE{'CMD_T7'};
        BATsh->run_string(join("\n",
            'SET CMD_T7=0',
            'FOR /L %%N IN (1,1,5) DO SET /A CMD_T7=%CMD_T7%+1',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T7'} ) ? $BATsh::Env::STORE{'CMD_T7'} : '' ) eq '5',
            'CMD7: FOR /L counts 5 iterations');
    },

    # CMD8: SET /A arithmetic
    sub {
        delete $BATsh::Env::STORE{'CMD_T8'};
        BATsh->run_string("SET /A CMD_T8=6*7");
        _ok(( defined( $BATsh::Env::STORE{'CMD_T8'} ) ? $BATsh::Env::STORE{'CMD_T8'} : '' ) eq '42',
            'CMD8: SET /A 6*7 = 42');
    },

    # CMD9: GOTO skips lines until label
    sub {
        delete $BATsh::Env::STORE{'CMD_T9'};
        BATsh->run_string(join("\n",
            'SET CMD_T9=before',
            'GOTO :SKIP9',
            'SET CMD_T9=should_skip',
            ':SKIP9',
            'SET CMD_T9=%CMD_T9%_after',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T9'} ) ? $BATsh::Env::STORE{'CMD_T9'} : '' ) eq 'before_after',
            'CMD9: GOTO skips to label');
    },

    # CMD10: SETLOCAL / ENDLOCAL restores scope
    sub {
        $BATsh::Env::STORE{'CMD_T10'} = 'outer';
        BATsh->run_string(join("\n",
            'SETLOCAL',
            'SET CMD_T10=inner',
            'ENDLOCAL',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T10'} ) ? $BATsh::Env::STORE{'CMD_T10'} : '' ) eq 'outer',
            'CMD10: SETLOCAL/ENDLOCAL restores variable');
    },

    # CMD11: IF DEFINED
    sub {
        $BATsh::Env::STORE{'CMD_T11_DEFINED'} = 'yes';
        delete $BATsh::Env::STORE{'CMD_T11_RESULT'};
        BATsh->run_string(join("\n",
            'IF DEFINED CMD_T11_DEFINED SET CMD_T11_RESULT=defined_ok',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T11_RESULT'} ) ? $BATsh::Env::STORE{'CMD_T11_RESULT'} : '' ) eq 'defined_ok',
            'CMD11: IF DEFINED');
    },

    # CMD12: IF NOT
    sub {
        delete $BATsh::Env::STORE{'CMD_T12'};
        BATsh->run_string(join("\n",
            'IF NOT "a"=="b" SET CMD_T12=not_ok',
        ));
        _ok(( defined( $BATsh::Env::STORE{'CMD_T12'} ) ? $BATsh::Env::STORE{'CMD_T12'} : '' ) eq 'not_ok',
            'CMD12: IF NOT condition');
    },

    # CMD13: SETLOCAL nested
    # CMD_T13_L1 is set BETWEEN the two ENDLOCALs.
    # The outer SETLOCAL was taken before CMD_T13_L1 existed, so ENDLOCAL
    # will remove it (same as real cmd.exe behaviour).
    # We verify the nested depth by checking CMD_T13 restores to L0.
    sub {
        $BATsh::Env::STORE{'CMD_T13'} = 'L0';
        delete $BATsh::Env::STORE{'CMD_T13_INNER'};
        BATsh->run_string(join("\n",
            'SETLOCAL',
            'SET CMD_T13=L1',
            'SETLOCAL',
            'SET CMD_T13=L2',
            'ENDLOCAL',
            'SET CMD_T13_INNER=%CMD_T13%',
        ));
        my $inner = defined($BATsh::Env::STORE{'CMD_T13_INNER'}) ? $BATsh::Env::STORE{'CMD_T13_INNER'} : '';
        BATsh->run_string('ENDLOCAL');
        _ok($inner eq 'L1' && ( defined( $BATsh::Env::STORE{'CMD_T13'} ) ? $BATsh::Env::STORE{'CMD_T13'} : '' ) eq 'L0',
            'CMD13: nested SETLOCAL/ENDLOCAL (inner=L1, outer restored to L0)');
    },

    # CMD14: @ECHO OFF silences echo
    sub {
        my $out = _capture(sub {
            BATsh->run_string(join("\n",
                '@ECHO OFF',
                'ECHO visible_line',
            ));
        });
        _ok($out =~ /visible_line/, 'CMD14: ECHO output after @ECHO OFF');
    },

    # CMD15: IF EXIST (file that exists)
    sub {
        delete $BATsh::Env::STORE{'CMD_T15'};
        # Use this test file itself -- always present when tests run
        my $me = $FindBin::Bin . '/0003-cmd-interpreter.t';
        # Normalise slashes for cmd.exe compatibility
        (my $safe = $me) =~ s/\\/\//g;
        BATsh->run_string("IF EXIST $safe SET CMD_T15=exist_ok");
        _ok((-f $me) ? (( defined( $BATsh::Env::STORE{'CMD_T15'} ) ? $BATsh::Env::STORE{'CMD_T15'} : '' ) eq 'exist_ok') : 1,
            'CMD15: IF EXIST finds an existing file');
    },

);

# Capture stdout helper
sub _capture {
    my ($code) = @_;
    my $tmpfile = File::Spec->catfile(
        File::Spec->tmpdir(), "batsh_tst_$$.tmp");
    local *OLD_STDOUT;
    open(OLD_STDOUT, '>&STDOUT') or return '';
    local *CAPFH;
    open(CAPFH, "> $tmpfile") or do { open(STDOUT,'>&OLD_STDOUT'); return '' };
    open(STDOUT, '>&CAPFH');
    eval { $code->() };
    open(STDOUT, '>&OLD_STDOUT');
    close(CAPFH); close(OLD_STDOUT);
    my $buf = '';
    if (open(READFH, "< $tmpfile")) {
        local $/;
        $buf = <READFH>;
        close(READFH);
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
END { exit 1 if $fail }
