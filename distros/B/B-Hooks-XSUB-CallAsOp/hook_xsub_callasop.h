#ifndef __HOOK_XSUB_CALLASOP_H__
#define __HOOK_XSUB_CALLASOP_H__

#include "perl.h"

START_EXTERN_C

#define TRAMPOLINE(hook) PUTBACK, b_hooks_xsub_callasop_setup_trampoline(aTHX_ hook), XSRETURN(0)

#define TRAMPOLINE_HOOK(hook) OP *hook (pTHX)

#define TRAMPOLINE_SAVE_OP      b_hooks_xsub_callasop_trampoline_save_op(aTHX)
#define TRAMPOLINE_RESTORE_OP   b_hooks_xsub_callasop_trampoline_restore_op(aTHX)

#define TRAMPOLINE_SAVE_ARGS    b_hooks_xsub_callasop_trampoline_save_args(aTHX_ &ST(0), items), SPAGAIN
#define TRAMPOLINE_RESTORE_ARGS b_hooks_xsub_callasop_trampoline_restore_args(aTHX), SPAGAIN

typedef OP *(*b_hooks_xsub_callasop_hook_t)(pTHX);

void b_hooks_xsub_callasop_setup_trampoline (pTHX_ b_hooks_xsub_callasop_hook_t hook);

void b_hooks_xsub_callasop_save_op(pTHX);
void b_hooks_xsub_callasop_restore_op(pTHX);
void b_hooks_xsub_callasop_save_args(pTHX_ SV **start, I32 items);
void b_hooks_xsub_callasop_restore_args(pTHX);

END_EXTERN_C

#endif

