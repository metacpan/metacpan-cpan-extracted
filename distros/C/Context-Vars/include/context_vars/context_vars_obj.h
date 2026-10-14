#ifndef CONTEXT_VARS_OBJ_H
#define CONTEXT_VARS_OBJ_H

/* Context::Vars::Context, the object a loop author or a test holds, and the
 * calls that run code in one.
 *
 * The object is a blessed reference to a scalar that carries magic,
 * recognised by the address of the vtable below, with the holder as the
 * magic's private data. The holder is released by the magic's free hook, so
 * there is no DESTROY to call twice or to shadow in a subclass. A hash or a
 * number blessed into the class, or one restored by a serialiser, has no such
 * magic and is refused by every method, by name, instead of being
 * dereferenced. That is HAMT's choice for its own objects, made for the same
 * reason.
 *
 * A new thread does not get the object: CLONE_SKIP keeps it from being
 * cloned, and if a clone is made some other way the dup hook empties it, so
 * it is dead rather than a second owner of another interpreter's scalars. */

static int context_vars_obj_free(pTHX_ SV *sv, MAGIC *mg) {
    context_vars_ctx *c = (context_vars_ctx *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (c) {
        mg->mg_ptr = NULL;
        context_vars_release(aTHX_ c);
    }
    return 0;
}

static int context_vars_obj_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(param);
    mg->mg_ptr = NULL;
    return 0;
}

static MGVTBL context_vars_obj_vtbl = {
    NULL, NULL, NULL, NULL, context_vars_obj_free, NULL, context_vars_obj_dup, NULL
};

/* A new object, mortal, that TAKES OVER one reference to `c`. */
static SV *context_vars_obj_new(pTHX_ context_vars_ctx *c) {
    SV *inner = newSV(0);
    SV *rv;
    MAGIC *mg = sv_magicext(inner, NULL, PERL_MAGIC_ext, &context_vars_obj_vtbl,
                            (const char *)c, 0);
    mg->mg_flags |= MGf_DUP;
    rv = sv_2mortal(newRV_noinc(inner));
    sv_bless(rv, gv_stashpvs("Context::Vars::Context", GV_ADD));
    return rv;
}

/* The holder behind an object, borrowed, or NULL when `sv` is not one. */
static context_vars_ctx *context_vars_obj_try(pTHX_ SV *sv) {
    MAGIC *mg;
    PERL_UNUSED_CONTEXT;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) < SVt_PVMG) return NULL;
    for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &context_vars_obj_vtbl)
            return (context_vars_ctx *)mg->mg_ptr;
    return NULL;
}

/* The same, or a croak that names the method. */
static context_vars_ctx *context_vars_obj(pTHX_ SV *sv, const char *what) {
    MAGIC *mg;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) >= SVt_PVMG) {
        for (mg = SvMAGIC(SvRV(sv)); mg; mg = mg->mg_moremagic) {
            if (mg->mg_type != PERL_MAGIC_ext || mg->mg_virtual != &context_vars_obj_vtbl)
                continue;
            if (!mg->mg_ptr)
                croak("%s: this context belongs to another thread", what);
            return (context_vars_ctx *)mg->mg_ptr;
        }
    }
    croak("%s: not a Context::Vars::Context", what);
    return NULL;
}

/* ---- running code in a context --------------------------------------------- */

/* Calls `code` with the `n` arguments at `args` in context `c` - `c` itself
 * when `copy` is 0, a fresh copy of it when 1 - in the caller's `gimme`, and
 * puts what it returned on the stack from position `ax` up. Returns how many.
 *
 * A die in the code is not caught: it goes up through here, and the save
 * stack puts the previous context back on its way. */
static I32 context_vars_call_in(pTHX_ context_vars_ctx *c, int copy, SV *code,
                                SV **args, I32 n, I32 gimme, I32 ax) {
    dSP;
    SV **argv = NULL;
    I32 i, count;

    ENTER;
    if (n > 0) {
        /* The arguments live on the stack, which the call may move. */
        Newx(argv, n, SV *);
        SAVEFREEPV(argv);
        Copy(args, argv, n, SV *);
    }
    if (copy) context_vars_enter_copy(aTHX_ c);
    else      context_vars_enter(aTHX_ c);

    PUSHMARK(SP);
    EXTEND(SP, n);
    for (i = 0; i < n; i++) PUSHs(argv[i]);
    PUTBACK;

    count = call_sv(code, gimme);

    SPAGAIN;
    for (i = 0; i < count; i++) {
        SV *r = SP[i - count + 1];
        PL_stack_base[ax + i] = SvTEMP(r) ? r : sv_mortalcopy(r);
    }
    PL_stack_sp = PL_stack_base + ax + count - 1;
    LEAVE;
    return count;
}

/* ---- wrap ------------------------------------------------------------------- */

/* A wrapped callback is an XSUB with no name, carrying the capture and the
 * code as the private data of magic on itself, let go when it is freed. */
typedef struct {
    context_vars_ctx *ctx;
    SV               *code;
} context_vars_wrap;

static int context_vars_wrap_free(pTHX_ SV *sv, MAGIC *mg) {
    context_vars_wrap *w = (context_vars_wrap *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (w) {
        mg->mg_ptr = NULL;
        context_vars_release(aTHX_ w->ctx);
        SvREFCNT_dec(w->code);
        Safefree(w);
    }
    return 0;
}

static MGVTBL context_vars_wrap_vtbl = {
    NULL, NULL, NULL, NULL, context_vars_wrap_free, NULL, context_vars_obj_dup, NULL
};

static XS(context_vars_wrapped) {
    dXSARGS;
    context_vars_wrap *w = NULL;
    MAGIC *mg;
    I32 count;

    for (mg = SvMAGIC((SV *)cv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &context_vars_wrap_vtbl) {
            w = (context_vars_wrap *)mg->mg_ptr;
            break;
        }
    if (!w) croak("Context::Vars: this wrapped callback belongs to another thread");

    count = context_vars_call_in(aTHX_ w->ctx, 1, w->code, &ST(0), items, GIMME_V, ax);
    XSRETURN(count);
}

/* A code reference that runs `code` in a fresh copy of what is current now,
 * every time it is called. TAKES OVER `c`. */
static SV *context_vars_wrap_new(pTHX_ context_vars_ctx *c, SV *code) {
    CV *xcv = newXS(NULL, context_vars_wrapped, __FILE__);
    context_vars_wrap *w;
    MAGIC *mg;

    Newx(w, 1, context_vars_wrap);
    w->ctx  = c;
    w->code = SvREFCNT_inc_simple_NN(code);
    mg = sv_magicext((SV *)xcv, NULL, PERL_MAGIC_ext, &context_vars_wrap_vtbl,
                     (const char *)w, 0);
    mg->mg_flags |= MGf_DUP;
    return sv_2mortal(newRV_noinc((SV *)xcv));
}

/* ---- names ------------------------------------------------------------------ */

static int context_vars_names_cb(pTHX_ void *ud, const char *key, STRLEN klen,
                                 int utf8, SV *value) {
    PERL_UNUSED_ARG(utf8);
    PERL_UNUSED_ARG(value);
    av_push((AV *)ud, newSVpvn(key, klen));
    return 0;
}

#endif
