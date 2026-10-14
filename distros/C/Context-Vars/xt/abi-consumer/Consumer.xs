#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* The only thing this file knows about Context::Vars. */
#include "context_vars_abi.h"

static const context_vars_abi *VARS = NULL;

/* A callback queue, as an event loop keeps one: the three calls the header
 * shows are all it takes to run each callback with the values of the moment
 * it was queued. */
typedef struct { SV *code; context_vars_ctx *ctx; } queued;

#define QMAX 4096
static queued Q[QMAX];
static int    QN = 0;

static void run_one(pTHX_ queued *q) {
    dSP;
    ENTER;
    if (q->ctx) (VARS->enter_copy)(aTHX_ q->ctx);
    PUSHMARK(SP);
    PUTBACK;
    call_sv(q->code, G_DISCARD | G_EVAL | G_VOID);
    LEAVE;
    if (q->ctx) (VARS->release)(aTHX_ q->ctx);
    SvREFCNT_dec(q->code);
}

MODULE = Context::Vars::ABI::Consumer    PACKAGE = Context::Vars::ABI::Consumer

PROTOTYPES: DISABLE

BOOT:
{
    SV *err;
    SV *sv = eval_pv("require Context::Vars; Context::Vars::_abi_ptr()", 0);
    err = get_sv("@", 0);
    if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
        const context_vars_abi *t = INT2PTR(const context_vars_abi *, SvUV(sv));
        if (t && t->abi_version >= CONTEXT_VARS_ABI_VERSION) VARS = t;
    }
}

IV
abi_version()
    CODE:
        RETVAL = VARS ? VARS->abi_version : 0;
    OUTPUT:
        RETVAL

void
later(code)
        SV *code
    CODE:
        if (QN >= QMAX) croak("queue full");
        Q[QN].code = newSVsv(code);
        Q[QN].ctx  = VARS ? (VARS->capture)(aTHX) : NULL;
        QN++;

# Runs everything queued, last first when `backwards` is true.
IV
run_all(backwards)
        int backwards
    CODE:
    {
        int i, n = QN;
        QN = 0;
        for (i = 0; i < n; i++)
            run_one(aTHX_ &Q[backwards ? n - 1 - i : i]);
        RETVAL = n;
    }
    OUTPUT:
        RETVAL

# A copy of the value in the current context, or undef.
SV *
fetch(name)
        SV *name
    CODE:
    {
        STRLEN len;
        const char *p = SvPV(name, len);
        SV *held = (VARS->var_fetch)(aTHX_ p, len);
        RETVAL = held ? newSVsv(held) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# Stores a value inside a scope of its own and runs the code there: the code
# sees the value and the caller, afterwards, does not.
void
store_scoped(name, value, code)
        SV *name
        SV *value
        SV *code
    CODE:
    {
        STRLEN len;
        const char *p = SvPV(name, len);
        dSP;
        ENTER;
        (VARS->scope)(aTHX);
        (VARS->var_store)(aTHX_ p, len, value);
        PUSHMARK(SP);
        PUTBACK;
        call_sv(code, G_DISCARD | G_VOID);
        LEAVE;
    }

# Stores a value in whatever context is current, with no scope of its own.
void
store(name, value)
        SV *name
        SV *value
    CODE:
    {
        STRLEN len;
        const char *p = SvPV(name, len);
        (VARS->var_store)(aTHX_ p, len, value);
    }

# What is current, as an object, through ctx_to_sv; and back, through
# ctx_from_sv, as a yes or no.
SV *
current_object()
    CODE:
        RETVAL = (VARS->ctx_to_sv)(aTHX_ (VARS->retain)(aTHX_ (VARS->current)(aTHX)));
    OUTPUT:
        RETVAL

int
is_context(obj)
        SV *obj
    CODE:
        RETVAL = (VARS->ctx_from_sv)(aTHX_ obj) ? 1 : 0;
    OUTPUT:
        RETVAL
