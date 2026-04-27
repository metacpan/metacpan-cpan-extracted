######################################################################
#
# 0004-bridge.t  CMD/SH variable bridge and mixed-mode tests
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

    # BR1: CMD sets var, SH reads it
    sub {
        delete $BATsh::Env::STORE{'BR_T1'};
        BATsh->run_string(join("\n",
            'SET BR_T1=from_cmd',
            'export BR_T1_SH=$BR_T1',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T1_SH'} ) ? $BATsh::Env::STORE{'BR_T1_SH'} : '' ) eq 'from_cmd',
            'BR1: CMD sets BR_T1, SH reads via $BR_T1');
    },

    # BR2: SH sets var, CMD reads it
    sub {
        delete $BATsh::Env::STORE{'BR_T2'};
        BATsh->run_string(join("\n",
            'export BR_T2=from_sh',
            'SET BR_T2_CMD=%BR_T2%',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T2_CMD'} ) ? $BATsh::Env::STORE{'BR_T2_CMD'} : '' ) eq 'from_sh',
            'BR2: SH sets BR_T2, CMD reads via %BR_T2%');
    },

    # BR3: Multiple round trips
    sub {
        delete $BATsh::Env::STORE{'BR_T3'};
        BATsh->run_string(join("\n",
            'SET BR_T3=step1',
            'export BR_T3=step2',
            'SET BR_T3=%BR_T3%_step3',
            'export BR_T3_FINAL=$BR_T3',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T3_FINAL'} ) ? $BATsh::Env::STORE{'BR_T3_FINAL'} : '' ) eq 'step2_step3',
            'BR3: multi-step round-trip bridge');
    },

    # BR4: SH for loop, CMD reads result
    sub {
        delete $BATsh::Env::STORE{'BR_T4'};
        BATsh->run_string(join("\n",
            'R=""',
            'for i in X Y Z; do',
            '    R="${R}${i}"',
            'done',
            'export BR_T4=$R',
            'SET BR_T4_CMD=%BR_T4%_done',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T4_CMD'} ) ? $BATsh::Env::STORE{'BR_T4_CMD'} : '' ) eq 'XYZ_done',
            'BR4: SH for loop result read by CMD');
    },

    # BR5: CMD FOR /L, SH reads result
    sub {
        delete $BATsh::Env::STORE{'BR_T5'};
        BATsh->run_string(join("\n",
            'SET BR_T5=0',
            'FOR /L %%N IN (1,1,4) DO SET /A BR_T5=%BR_T5%+1',
            'export BR_T5_SH=$BR_T5',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T5_SH'} ) ? $BATsh::Env::STORE{'BR_T5_SH'} : '' ) eq '4',
            'BR5: CMD FOR /L result read by SH');
    },

    # BR6: CMD SETLOCAL does not leak to SH
    sub {
        $BATsh::Env::STORE{'BR_T6'} = 'original';
        BATsh->run_string(join("\n",
            'SETLOCAL',
            'SET BR_T6=inside_setlocal',
            'ENDLOCAL',
            'export BR_T6_SH=$BR_T6',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T6_SH'} ) ? $BATsh::Env::STORE{'BR_T6_SH'} : '' ) eq 'original',
            'BR6: SETLOCAL/ENDLOCAL restores, SH sees original');
    },

    # BR7: SH if/else, CMD reads result
    sub {
        delete $BATsh::Env::STORE{'BR_T7'};
        BATsh->run_string(join("\n",
            'V=42',
            'if [ $V -gt 10 ]; then',
            '    export BR_T7=gt10',
            'else',
            '    export BR_T7=le10',
            'fi',
            'SET BR_T7_CMD=%BR_T7%_from_cmd',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T7_CMD'} ) ? $BATsh::Env::STORE{'BR_T7_CMD'} : '' ) eq 'gt10_from_cmd',
            'BR7: SH if/else result read by CMD');
    },

    # BR8: Subroutine defined, called from CMD section
    sub {
        delete $BATsh::Env::STORE{'BR_T8'};
        BATsh->run_string(join("\n",
            ':SET_BR8',
            'export BR_T8=sub_ran',
            'RET',
            'CALL :SET_BR8',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T8'} ) ? $BATsh::Env::STORE{'BR_T8'} : '' ) eq 'sub_ran',
            'BR8: BATsh subroutine called from CMD section');
    },

    # BR9: sh_available is always 1 (built-in)
    sub {
        _ok(BATsh->sh_available() == 1,
            'BR9: sh_available() always 1 (no external shell needed)');
    },

    # BR10: Mixed section boundary detection
    sub {
        delete $BATsh::Env::STORE{'BR_T10A'};
        delete $BATsh::Env::STORE{'BR_T10B'};
        BATsh->run_string(join("\n",
            'SET BR_T10A=cmd_section',
            'export BR_T10B=sh_section',
        ));
        _ok(( defined( $BATsh::Env::STORE{'BR_T10A'} ) ? $BATsh::Env::STORE{'BR_T10A'} : '' ) eq 'cmd_section'
         && ( defined( $BATsh::Env::STORE{'BR_T10B'} ) ? $BATsh::Env::STORE{'BR_T10B'} : '' ) eq 'sh_section',
            'BR10: CMD and SH sections both execute');
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
