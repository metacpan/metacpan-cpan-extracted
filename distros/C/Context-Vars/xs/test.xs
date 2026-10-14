# Test doors onto the context core. Each begins with an underscore and is
# documented nowhere: they are how t/ reaches the core before there is a
# public way to, and how it counts what a leak would leave behind.
#
# A context is handed to Perl here as a bare address. That is safe only
# because a test holds it for a few lines and gives it back; the public
# object arrives with its own class.

MODULE = Context::Vars    PACKAGE = Context::Vars

IV
_selftest_core()
    CODE:
        RETVAL = (IV)context_vars_ctx_selftest(aTHX);
    OUTPUT:
        RETVAL

# Holders handed out and not yet given back. The empty context is not one.
IV
_live_holders()
    CODE:
    {
        dMY_CXT;
        RETVAL = MY_CXT.live;
    }
    OUTPUT:
        RETVAL

# Enters whose restore has not run.
IV
_depth()
    CODE:
    {
        dMY_CXT;
        RETVAL = MY_CXT.depth;
    }
    OUTPUT:
        RETVAL

# References held on the empty context. Each capture taken with nothing
# entered is one.
UV
_empty_refcnt()
    CODE:
    {
        dMY_CXT;
        RETVAL = MY_CXT.empty->refcnt;
    }
    OUTPUT:
        RETVAL

IV
_free_holders()
    CODE:
    {
        dMY_CXT;
        RETVAL = MY_CXT.free_n;
    }
    OUTPUT:
        RETVAL

UV
_t_current()
    CODE:
        RETVAL = PTR2UV(context_vars_current(aTHX));
    OUTPUT:
        RETVAL

int
_t_is_empty()
    CODE:
        RETVAL = context_vars_is_empty(aTHX_ context_vars_current(aTHX));
    OUTPUT:
        RETVAL

UV
_t_count()
    CODE:
        RETVAL = (UV)context_vars_count(aTHX);
    OUTPUT:
        RETVAL

# A copy of the stored value, or undef when the name is not set. The second
# return says which, since a stored undef and no value read the same.
void
_t_fetch(name)
        SV *name
    PPCODE:
    {
        STRLEN len;
        const char *p = SvPV(name, len);
        SV *sv = context_vars_fetch(aTHX_ p, len);
        EXTEND(SP, 2);
        PUSHs(sv ? sv_2mortal(newSVsv(sv)) : &PL_sv_undef);
        PUSHs(sv ? &PL_sv_yes : &PL_sv_no);
    }

void
_t_store(name, value)
        SV *name
        SV *value
    CODE:
    {
        STRLEN len;
        const char *p = SvPV(name, len);
        dMY_CXT;
        if (MY_CXT.depth > 0) context_vars_writable(aTHX);
        context_vars_store(aTHX_ p, len, value);
    }

void
_t_remove(name)
        SV *name
    CODE:
    {
        STRLEN len;
        const char *p = SvPV(name, len);
        dMY_CXT;
        if (MY_CXT.depth > 0) context_vars_writable(aTHX);
        context_vars_remove(aTHX_ p, len);
    }

# Runs the code in a fresh context onto the current one. A die in the code
# goes straight through this frame: nothing here catches it, so the only
# thing that can put the context back is the save stack.
void
_t_scope(code)
        SV *code
    CODE:
    {
        dSP;
        ENTER;
        context_vars_scope(aTHX);
        PUSHMARK(SP);
        PUTBACK;
        call_sv(code, G_DISCARD | G_VOID);
        LEAVE;
    }

# What the current context holds, kept. The caller gives it back to
# _t_release exactly once.
UV
_t_capture()
    CODE:
        RETVAL = PTR2UV(context_vars_capture(aTHX));
    OUTPUT:
        RETVAL

void
_t_release(addr)
        UV addr
    CODE:
        context_vars_release(aTHX_ INT2PTR(context_vars_ctx *, addr));

# Runs the code with the kept context itself current.
void
_t_enter(addr, code)
        UV  addr
        SV *code
    CODE:
    {
        dSP;
        ENTER;
        context_vars_enter(aTHX_ INT2PTR(context_vars_ctx *, addr));
        PUSHMARK(SP);
        PUTBACK;
        call_sv(code, G_DISCARD | G_VOID);
        LEAVE;
    }

# Runs the code in a fresh context onto the kept one.
void
_t_enter_copy(addr, code)
        UV  addr
        SV *code
    CODE:
    {
        dSP;
        ENTER;
        context_vars_enter_copy(aTHX_ INT2PTR(context_vars_ctx *, addr));
        PUSHMARK(SP);
        PUTBACK;
        call_sv(code, G_DISCARD | G_VOID);
        LEAVE;
    }

# 1 when the sub opens a scope with its first statement, 2 when with an op of
# its own, 0 when it opens none.
int
_scope_kind(code)
        SV *code
    CODE:
        RETVAL = (SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV)
               ? context_vars_scope_kind((CV *)SvRV(code)) : 0;
    OUTPUT:
        RETVAL

# Scopes opened in this interpreter, by any means.
IV
_scopes()
    CODE:
    {
        dMY_CXT;
        RETVAL = MY_CXT.scopes;
    }
    OUTPUT:
        RETVAL

# True once the async hooks are registered with Future::AsyncAwait.
int
_async_hooks()
    CODE:
        RETVAL = context_vars_faa_registered;
    OUTPUT:
        RETVAL

# For bench/: `n` turns of what a loop does for one callback, in C, with no
# Perl call: capture, enter a copy inside ENTER and LEAVE, release. With
# `kind` 0, only the ENTER and LEAVE, to subtract.
void
_bench_cycle(n, kind)
        IV n
        int kind
    CODE:
    {
        IV i;
        if (kind == 0) {
            for (i = 0; i < n; i++) { ENTER; LEAVE; }
        }
        else {
            for (i = 0; i < n; i++) {
                context_vars_ctx *c = context_vars_capture(aTHX);
                ENTER;
                context_vars_enter_copy(aTHX_ c);
                LEAVE;
                context_vars_release(aTHX_ c);
            }
        }
    }
