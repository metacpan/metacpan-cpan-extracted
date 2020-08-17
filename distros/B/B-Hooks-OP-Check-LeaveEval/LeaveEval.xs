#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "hook_op_check.h"

STATIC OP*
execute_callback (pTHX_ OP* op, void *user_data) {
    dSP;
    PUSHMARK (SP);
    call_sv((SV *) user_data, G_VOID | G_DISCARD | G_NOARGS);
    return op;
}

MODULE = B::Hooks::OP::Check::LeaveEval         PACKAGE = B::Hooks::OP::Check::LeaveEval

PROTOTYPES: ENABLED

UV
register (SV* cb)
    CODE:
        SvREFCNT_inc(cb);
        RETVAL = hook_op_check(OP_LEAVEEVAL, execute_callback, cb);
    OUTPUT:
        RETVAL

void
unregister (UV id)
    CODE:
        SV* cb = hook_op_check_remove(OP_LEAVEEVAL, id);
        if (cb)
            SvREFCNT_inc(cb);
