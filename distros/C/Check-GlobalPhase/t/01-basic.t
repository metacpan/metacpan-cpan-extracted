#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 35;

use Check::GlobalPhase;

note 'PERL_PHASE_CONSTRUCT => ', Check::GlobalPhase::PERL_PHASE_CONSTRUCT;
note 'PERL_PHASE_START => ',     Check::GlobalPhase::PERL_PHASE_START;
note 'PERL_PHASE_CHECK => ',     Check::GlobalPhase::PERL_PHASE_CHECK;
note 'PERL_PHASE_INIT => ',      Check::GlobalPhase::PERL_PHASE_INIT;
note 'PERL_PHASE_RUN => ',       Check::GlobalPhase::PERL_PHASE_RUN;
note 'PERL_PHASE_END => ',       Check::GlobalPhase::PERL_PHASE_END;
note 'PERL_PHASE_DESTRUCT => ',  Check::GlobalPhase::PERL_PHASE_DESTRUCT;

my %begin;

BEGIN {
    $begin{in_global_phase_start}
        = Check::GlobalPhase::in_global_phase_start();
    $begin{in_global_phase_check}
        = Check::GlobalPhase::in_global_phase_check();
    $begin{in_global_phase_init} = Check::GlobalPhase::in_global_phase_init();
    $begin{in_global_phase_run}  = Check::GlobalPhase::in_global_phase_run();
    $begin{in_global_phase_end}  = Check::GlobalPhase::in_global_phase_end();
    $begin{in_global_phase_destruct}
        = Check::GlobalPhase::in_global_phase_destruct();

    $begin{phase} = Check::GlobalPhase::current_phase();
}

my %init;
INIT {
    $init{in_global_phase_start}
        = Check::GlobalPhase::in_global_phase_start();
    $init{in_global_phase_check}
        = Check::GlobalPhase::in_global_phase_check();
    $init{in_global_phase_init} = Check::GlobalPhase::in_global_phase_init();
    $init{in_global_phase_run}  = Check::GlobalPhase::in_global_phase_run();
    $init{in_global_phase_end}  = Check::GlobalPhase::in_global_phase_end();
    $init{in_global_phase_destruct}
        = Check::GlobalPhase::in_global_phase_destruct();

    $init{phase} = Check::GlobalPhase::current_phase();
}

my %check;
CHECK {
    $check{in_global_phase_start}
        = Check::GlobalPhase::in_global_phase_start();
    $check{in_global_phase_check}
        = Check::GlobalPhase::in_global_phase_check();
    $check{in_global_phase_init} = Check::GlobalPhase::in_global_phase_init();
    $check{in_global_phase_run}  = Check::GlobalPhase::in_global_phase_run();
    $check{in_global_phase_end}  = Check::GlobalPhase::in_global_phase_end();
    $check{in_global_phase_destruct}
        = Check::GlobalPhase::in_global_phase_destruct();

    $check{phase} = Check::GlobalPhase::current_phase();
}

{    # run
    note "run...";

    ok !Check::GlobalPhase::in_global_phase_start();
    ok !Check::GlobalPhase::in_global_phase_check();
    ok !Check::GlobalPhase::in_global_phase_init();
    ok Check::GlobalPhase::in_global_phase_run();
    ok !Check::GlobalPhase::in_global_phase_end();
    ok !Check::GlobalPhase::in_global_phase_destruct();

    is Check::GlobalPhase::current_phase(),
        Check::GlobalPhase::PERL_PHASE_RUN,
        'Check::GlobalPhase::PERL_PHASE_RUN';

    1;
}

ok $begin{in_global_phase_start}, 'begin{in_global_phase_start}';
ok !$begin{in_global_phase_check},    'begin{in_global_phase_check}';
ok !$begin{in_global_phase_init},     'begin{in_global_phase_init}';
ok !$begin{in_global_phase_run},      'begin{in_global_phase_run}';
ok !$begin{in_global_phase_end},      'begin{in_global_phase_end}';
ok !$begin{in_global_phase_destruct}, 'begin{in_global_phase_destruct}';

is $begin{phase}, Check::GlobalPhase::PERL_PHASE_START, 'begin current_phase';

ok !$init{in_global_phase_start}, 'init{in_global_phase_start}';
ok !$init{in_global_phase_check}, 'init{in_global_phase_check}';
ok $init{in_global_phase_init}, 'init{in_global_phase_init}';
ok !$init{in_global_phase_run},      'init{in_global_phase_run}';
ok !$init{in_global_phase_end},      'init{in_global_phase_end}';
ok !$init{in_global_phase_destruct}, 'begin{in_global_phase_destruct}';

is $init{phase}, Check::GlobalPhase::PERL_PHASE_INIT, 'init current_phase';

ok !$check{in_global_phase_start}, 'check{in_global_phase_start}';
ok $check{in_global_phase_check}, 'check{in_global_phase_check}';
ok !$check{in_global_phase_init},     'check{in_global_phase_init}';
ok !$check{in_global_phase_run},      'check{in_global_phase_run}';
ok !$check{in_global_phase_end},      'check{in_global_phase_end}';
ok !$check{in_global_phase_destruct}, 'begin{in_global_phase_destruct}';

is $check{phase}, Check::GlobalPhase::PERL_PHASE_CHECK, 'check current_phase';

END {
    note "END block...";

    my %end;
    $end{in_global_phase_start} = Check::GlobalPhase::in_global_phase_start();
    $end{in_global_phase_check} = Check::GlobalPhase::in_global_phase_check();
    $end{in_global_phase_init}  = Check::GlobalPhase::in_global_phase_init();
    $end{in_global_phase_run}   = Check::GlobalPhase::in_global_phase_run();

    $end{in_global_phase_end} = Check::GlobalPhase::in_global_phase_end();
    $end{in_global_phase_destruct}
        = Check::GlobalPhase::in_global_phase_destruct();

    ok !$end{in_global_phase_start}, 'end{in_global_phase_start}';
    ok !$end{in_global_phase_check}, 'end{in_global_phase_check}';
    ok !$end{in_global_phase_init},  'end{in_global_phase_init}';
    ok !$end{in_global_phase_run},   'end{in_global_phase_run}';
    ok $end{in_global_phase_end}, 'end{in_global_phase_end}';
    ok !$end{in_global_phase_destruct}, 'end{in_global_phase_destruct}';

    $end{phase} = Check::GlobalPhase::current_phase();

    is $end{phase}, Check::GlobalPhase::PERL_PHASE_END, 'end current_phase';

    done_testing;

}
