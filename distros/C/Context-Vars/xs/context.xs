# Capturing a context, running code in one, and the object that holds one.

MODULE = Context::Vars    PACKAGE = Context::Vars

# What is current now, kept: a Context::Vars::Context.
void
capture(klass)
        SV *klass
    PPCODE:
        PERL_UNUSED_VAR(klass);
        XPUSHs(context_vars_obj_new(aTHX_ context_vars_capture(aTHX)));

# The current context itself, not a copy of it.
void
current(klass)
        SV *klass
    PPCODE:
        PERL_UNUSED_VAR(klass);
        XPUSHs(context_vars_obj_new(aTHX_
            context_vars_retain(aTHX_ context_vars_current(aTHX))));

# A code reference that runs `code` in a fresh copy of what is current now,
# each time it is called.
void
wrap(klass, code)
        SV *klass
        SV *code
    PPCODE:
        PERL_UNUSED_VAR(klass);
        SvGETMAGIC(code);
        if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
            croak("Context::Vars::wrap: not a code reference");
        XPUSHs(context_vars_wrap_new(aTHX_ context_vars_capture(aTHX), code));

MODULE = Context::Vars    PACKAGE = Context::Vars::Context

void
run(self, code, ...)
        SV *self
        SV *code
    PPCODE:
    {
        context_vars_ctx *c = context_vars_obj(aTHX_ self, "Context::Vars::Context::run");
        I32 count;
        SvGETMAGIC(code);
        if (!SvROK(code) || SvTYPE(SvRV(code)) != SVt_PVCV)
            croak("Context::Vars::Context::run: not a code reference");
        PUTBACK;
        count = context_vars_call_in(aTHX_ c, 0, code, &ST(2), items - 2, GIMME_V, ax);
        XSRETURN(count);
    }

# The names set in the context, sorted, without their sigils.
void
names(self)
        SV *self
    PPCODE:
    {
        context_vars_ctx *c = context_vars_obj(aTHX_ self, "Context::Vars::Context::names");
        AV *av = (AV *)sv_2mortal((SV *)newAV());
        I32 i, n;
        (CONTEXT_VARS_HAMT->map_walk)(aTHX_ c->map, context_vars_names_cb, av);
        sortsv(AvARRAY(av), av_len(av) + 1, Perl_sv_cmp);
        n = (I32)(av_len(av) + 1);
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSVsv(AvARRAY(av)[i])));
    }

# The value of one name in the context, without entering it. The name may be
# given with or without its sigil.
void
get(self, name)
        SV *self
        SV *name
    PPCODE:
    {
        context_vars_ctx *c = context_vars_obj(aTHX_ self, "Context::Vars::Context::get");
        STRLEN len;
        const char *p = SvPV(name, len);
        SV *held;
        if (len && p[0] == '$') { p++; len--; }
        /* An array or hash keeps its sigil: it is stored under it. */
        held = (CONTEXT_VARS_HAMT->map_fetch)(aTHX_ c->map, p, len, 0);
        XPUSHs(held ? sv_2mortal(context_vars_plain(aTHX_ held)) : &PL_sv_undef);
    }

int
CLONE_SKIP(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = 1;
    OUTPUT:
        RETVAL
