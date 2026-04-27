######################################################################
#
# 0002-sh-interpreter.t  BATsh::SH pure Perl interpreter tests
#
# Tests SH execution without any external shell.
# All tests run via BATsh::SH directly (no system() calls needed).
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
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";
BATsh::Env::init();

my @tests = (

    # SH1: simple export, ENV bridge
    sub {
        delete $BATsh::Env::STORE{'SH_T1'};
        BATsh->run_string("export SH_T1=ok");
        _ok(( defined( $BATsh::Env::STORE{'SH_T1'} ) ? $BATsh::Env::STORE{'SH_T1'} : '' ) eq 'ok',
            'SH1: export propagates to Env store');
    },

    # SH2: variable assignment
    sub {
        delete $BATsh::Env::STORE{'SH_T2'};
        BATsh->run_string("SH_T2=assigned\nexport SH_T2");
        _ok(( defined( $BATsh::Env::STORE{'SH_T2'} ) ? $BATsh::Env::STORE{'SH_T2'} : '' ) eq 'assigned',
            'SH2: VAR=value assignment');
    },

    # SH3: for loop accumulates correctly
    sub {
        delete $BATsh::Env::STORE{'SH_T3'};
        BATsh->run_string(join("\n",
            'R=""',
            'for x in A B C; do',
            '    R="${R}${x}"',
            'done',
            'export SH_T3=$R',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T3'} ) ? $BATsh::Env::STORE{'SH_T3'} : '' ) eq 'ABC',
            'SH3: for loop accumulates correctly');
    },

    # SH4: if/then/fi true branch
    sub {
        delete $BATsh::Env::STORE{'SH_T4'};
        BATsh->run_string(join("\n",
            'if true; then',
            '    export SH_T4=true_branch',
            'fi',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T4'} ) ? $BATsh::Env::STORE{'SH_T4'} : '' ) eq 'true_branch',
            'SH4: if/then/fi true branch');
    },

    # SH5: if/then/else/fi false branch
    sub {
        delete $BATsh::Env::STORE{'SH_T5'};
        BATsh->run_string(join("\n",
            'if false; then',
            '    export SH_T5=wrong',
            'else',
            '    export SH_T5=else_branch',
            'fi',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T5'} ) ? $BATsh::Env::STORE{'SH_T5'} : '' ) eq 'else_branch',
            'SH5: if/then/else/fi false branch');
    },

    # SH6: while loop
    sub {
        delete $BATsh::Env::STORE{'SH_T6'};
        BATsh->run_string(join("\n",
            'N=0',
            'while [ $N -lt 5 ]; do',
            '    N=$(( N + 1 ))',
            'done',
            'export SH_T6=$N',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T6'} ) ? $BATsh::Env::STORE{'SH_T6'} : '' ) eq '5',
            'SH6: while loop counts to 5');
    },

    # SH7: case/esac
    sub {
        delete $BATsh::Env::STORE{'SH_T7'};
        BATsh->run_string(join("\n",
            'W=banana',
            'case $W in',
            '    apple)  export SH_T7=apple ;;',
            '    banana) export SH_T7=banana ;;',
            '    *)      export SH_T7=other ;;',
            'esac',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T7'} ) ? $BATsh::Env::STORE{'SH_T7'} : '' ) eq 'banana',
            'SH7: case/esac matches banana');
    },

    # SH8: arithmetic $(( ))
    sub {
        delete $BATsh::Env::STORE{'SH_T8'};
        BATsh->run_string('export SH_T8=$(( 3 + 4 * 2 ))');
        _ok(( defined( $BATsh::Env::STORE{'SH_T8'} ) ? $BATsh::Env::STORE{'SH_T8'} : '' ) eq '11',
            'SH8: arithmetic $(( 3 + 4 * 2 )) = 11');
    },

    # SH9: test [ -n "$VAR" ]
    sub {
        delete $BATsh::Env::STORE{'SH_T9'};
        BATsh->run_string(join("\n",
            'V=nonempty',
            'if [ -n "$V" ]; then',
            '    export SH_T9=nonempty_ok',
            'fi',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T9'} ) ? $BATsh::Env::STORE{'SH_T9'} : '' ) eq 'nonempty_ok',
            'SH9: test [ -n "$V" ] nonempty string');
    },

    # SH10: test [ -z "" ]
    sub {
        delete $BATsh::Env::STORE{'SH_T10'};
        BATsh->run_string(join("\n",
            'V=""',
            'if [ -z "$V" ]; then',
            '    export SH_T10=empty_ok',
            'fi',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T10'} ) ? $BATsh::Env::STORE{'SH_T10'} : '' ) eq 'empty_ok',
            'SH10: test [ -z "" ] empty string');
    },

    # SH11: integer comparison [ $N -gt 0 ]
    sub {
        delete $BATsh::Env::STORE{'SH_T11'};
        BATsh->run_string(join("\n",
            'N=42',
            'if [ $N -gt 10 ]; then',
            '    export SH_T11=gt10',
            'fi',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T11'} ) ? $BATsh::Env::STORE{'SH_T11'} : '' ) eq 'gt10',
            'SH11: integer comparison [ $N -gt 10 ]');
    },

    # SH12: unset variable
    sub {
        $BATsh::Env::STORE{'SH_T12'} = 'before';
        BATsh->run_string("unset SH_T12");
        _ok(!exists $BATsh::Env::STORE{'SH_T12'},
            'SH12: unset removes variable from store');
    },

    # SH13: until loop
    sub {
        delete $BATsh::Env::STORE{'SH_T13'};
        BATsh->run_string(join("\n",
            'N=0',
            'until [ $N -ge 3 ]; do',
            '    N=$(( N + 1 ))',
            'done',
            'export SH_T13=$N',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T13'} ) ? $BATsh::Env::STORE{'SH_T13'} : '' ) eq '3',
            'SH13: until loop');
    },

    # SH14: elif
    sub {
        delete $BATsh::Env::STORE{'SH_T14'};
        BATsh->run_string(join("\n",
            'N=2',
            'if [ $N -eq 1 ]; then',
            '    export SH_T14=one',
            'elif [ $N -eq 2 ]; then',
            '    export SH_T14=two',
            'else',
            '    export SH_T14=other',
            'fi',
        ));
        _ok(( defined( $BATsh::Env::STORE{'SH_T14'} ) ? $BATsh::Env::STORE{'SH_T14'} : '' ) eq 'two',
            'SH14: elif branch');
    },

    # SH15: variable expansion ${VAR:-default}
    sub {
        delete $BATsh::Env::STORE{'SH_T15'};
        delete $BATsh::Env::STORE{'UNDEF_VAR'};
        BATsh->run_string('export SH_T15=${UNDEF_VAR:-fallback}');
        _ok(( defined( $BATsh::Env::STORE{'SH_T15'} ) ? $BATsh::Env::STORE{'SH_T15'} : '' ) eq 'fallback',
            'SH15: ${VAR:-default} expansion');
    },

    # SH16: sh_available always returns 1 (built-in interpreter)
    sub {
        _ok(BATsh::sh_available() == 1,
            'SH16: sh_available() returns 1 (built-in interpreter)');
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
