/*
*
* Copyright (c) 2018, Nicolas R.
*
* This is free software; you can redistribute it and/or modify it under the
* same terms as Perl itself.
*
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <embed.h>

#if PERL_REVISION >= 5 && PERL_VERSION >= 10
#   define CAN_USE_IX_FOR_PERL_PHASE 1
#else
#   define CAN_USE_IX_FOR_PERL_PHASE 0
#endif

MODULE = Check__GlobalPhase       PACKAGE = Check::GlobalPhase

SV*
in_global_phase_construct()
ALIAS:
  in_global_phase_start      = 1
  in_global_phase_check      = 2
  in_global_phase_init       = 3
  in_global_phase_run        = 4
  in_global_phase_end        = 5
  in_global_phase_destruct   = 6
PPCODE:
{
/* using ix when we can -- probably most/all versions? */
#if CAN_USE_IX_FOR_PERL_PHASE
    int phase = ix;
#else
    int phase = PERL_PHASE_CONSTRUCT;
    if ( ix == 1 ) {
        phase = PERL_PHASE_START;
    } else if ( ix == 2 ) {
        phase = PERL_PHASE_CHECK;
    } else if ( ix == 3 ) {
        phase = PERL_PHASE_INIT;
    } else if ( ix == 4 ) {
        phase = PERL_PHASE_RUN;
    } else if ( ix == 5 ) {
        phase = PERL_PHASE_END;
    } else if ( ix == 6 ) {
        phase = PERL_PHASE_DESTRUCT;
    }
#endif

    if ( PL_phase == phase ) {
        XSRETURN_YES;
    } else {
        XSRETURN_NO;
    }
}

SV*
current_phase()
PPCODE:
{
    XPUSHs(newSViv(PL_phase));
}

BOOT:
    {
         HV *stash;

         stash = gv_stashpvn("Check::GlobalPhase", 18, TRUE);

         newCONSTSUB(stash, "_loaded", &PL_sv_yes );

         newCONSTSUB(stash, "PERL_PHASE_CONSTRUCT",  newSViv(PERL_PHASE_CONSTRUCT) );
         newCONSTSUB(stash, "PERL_PHASE_START",      newSViv(PERL_PHASE_START) );
         newCONSTSUB(stash, "PERL_PHASE_CHECK",      newSViv(PERL_PHASE_CHECK) );
         newCONSTSUB(stash, "PERL_PHASE_INIT",       newSViv(PERL_PHASE_INIT) );
         newCONSTSUB(stash, "PERL_PHASE_RUN",        newSViv(PERL_PHASE_RUN) );
         newCONSTSUB(stash, "PERL_PHASE_END",        newSViv(PERL_PHASE_END) );
         newCONSTSUB(stash, "PERL_PHASE_DESTRUCT",   newSViv(PERL_PHASE_DESTRUCT) );
    }
