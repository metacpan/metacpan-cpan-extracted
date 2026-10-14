#ifndef CONTEXT_VARS_ABI_IMPL_H
#define CONTEXT_VARS_ABI_IMPL_H

/* The table behind context_vars_abi.h, and the selftest that walks it. Each
 * entry is the core function itself where the signatures already agree, and
 * a small adapter where they do not. */

static void context_vars_abi_enter_copy(pTHX_ context_vars_ctx *c) {
    context_vars_enter_copy(aTHX_ c);
}

static void context_vars_abi_var_store(pTHX_ const char *name, STRLEN len, SV *value) {
    context_vars_var_put(aTHX_ name, len, value);
}

/* The object is made first and counted after: the SvREFCNT_inc macros may
 * expand their argument more than once, which here would make two objects. */
static SV *context_vars_abi_ctx_to_sv(pTHX_ context_vars_ctx *c) {
    SV *obj = context_vars_obj_new(aTHX_ c);
    SvREFCNT_inc_simple_void_NN(obj);
    return obj;
}

static const context_vars_abi CONTEXT_VARS_ABI = {
    CONTEXT_VARS_ABI_VERSION,
    context_vars_current,
    context_vars_capture,
    context_vars_retain,
    context_vars_release,
    context_vars_enter,
    context_vars_abi_enter_copy,
    context_vars_scope,
    context_vars_fetch,
    context_vars_abi_var_store,
    context_vars_obj_try,
    context_vars_abi_ctx_to_sv
};

/* ---- the selftest ----------------------------------------------------------- */

#define CONTEXT_VARS_ABI_STEP(n, cond) do { if (!(cond)) { *step = (n); goto done; } } while (0)

static IV context_vars_abi_iv(pTHX_ const context_vars_abi *A, const char *name) {
    SV *sv = (A->var_fetch)(aTHX_ name, strlen(name));
    return sv ? SvIV(sv) : -1;
}

static void context_vars_abi_put(pTHX_ const context_vars_abi *A, const char *name, IV v) {
    SV *sv = newSViv(v);
    (A->var_store)(aTHX_ name, strlen(name), sv);
    SvREFCNT_dec(sv);
}

/* Every entry, through the table, as a consumer would call it. Sets *step to
 * 0, or to the number of the first check that did not hold. Returns an object
 * for a context the checks built, for the Perl side to read with the Perl
 * surface: a table can be consistently wrong with itself, and the Perl
 * surface is what cannot be wrong in the same direction. */
static SV *context_vars_abi_selftest(pTHX_ int *step) {
    const context_vars_abi *A = &CONTEXT_VARS_ABI;
    context_vars_ctx *outer, *cap = NULL, *got;
    SV *obj = NULL, *bad;
    IV live0;

    *step = 0;
    {
        dMY_CXT;
        live0 = MY_CXT.live;
    }

    CONTEXT_VARS_ABI_STEP(1, A->abi_version == CONTEXT_VARS_ABI_VERSION);
    CONTEXT_VARS_ABI_STEP(2, (A->current)(aTHX) != NULL);

    ENTER;
    (A->scope)(aTHX);

    /* store, fetch, unset. The first store may give the scope a context of
     * its own, so `outer` is taken after it. */
    context_vars_abi_put(aTHX_ A, "a", 1);
    outer = (A->current)(aTHX);
    CONTEXT_VARS_ABI_STEP(10, context_vars_abi_iv(aTHX_ A, "a") == 1);
    (A->var_store)(aTHX_ "b", 1, NULL);
    CONTEXT_VARS_ABI_STEP(11, (A->var_fetch)(aTHX_ "b", 1) == NULL);
    context_vars_abi_put(aTHX_ A, "b", 2);
    (A->var_store)(aTHX_ "b", 1, &PL_sv_undef);
    CONTEXT_VARS_ABI_STEP(12, (A->var_fetch)(aTHX_ "b", 1) == NULL);

    /* capture holds the values of its moment */
    cap = (A->capture)(aTHX);
    CONTEXT_VARS_ABI_STEP(20, cap != NULL && cap != outer);
    context_vars_abi_put(aTHX_ A, "a", 2);

    ENTER;
    (A->enter)(aTHX_ cap);
    CONTEXT_VARS_ABI_STEP(21, (A->current)(aTHX) == cap);
    CONTEXT_VARS_ABI_STEP(22, context_vars_abi_iv(aTHX_ A, "a") == 1);
    context_vars_abi_put(aTHX_ A, "c", 3);
    LEAVE;
    CONTEXT_VARS_ABI_STEP(23, (A->current)(aTHX) == outer);
    CONTEXT_VARS_ABI_STEP(24, context_vars_abi_iv(aTHX_ A, "a") == 2);
    CONTEXT_VARS_ABI_STEP(25, (A->var_fetch)(aTHX_ "c", 1) == NULL);

    /* enter shares the context between runs; enter_copy does not */
    ENTER;
    (A->enter)(aTHX_ cap);
    CONTEXT_VARS_ABI_STEP(30, context_vars_abi_iv(aTHX_ A, "c") == 3);
    LEAVE;
    ENTER;
    (A->enter_copy)(aTHX_ cap);
    CONTEXT_VARS_ABI_STEP(31, (A->current)(aTHX) != cap);
    CONTEXT_VARS_ABI_STEP(32, context_vars_abi_iv(aTHX_ A, "c") == 3);
    context_vars_abi_put(aTHX_ A, "d", 4);
    LEAVE;
    ENTER;
    (A->enter_copy)(aTHX_ cap);
    CONTEXT_VARS_ABI_STEP(33, (A->var_fetch)(aTHX_ "d", 1) == NULL);
    LEAVE;

    /* scope: a store inside ends with it */
    ENTER;
    (A->scope)(aTHX);
    context_vars_abi_put(aTHX_ A, "a", 9);
    CONTEXT_VARS_ABI_STEP(40, context_vars_abi_iv(aTHX_ A, "a") == 9);
    LEAVE;
    CONTEXT_VARS_ABI_STEP(41, context_vars_abi_iv(aTHX_ A, "a") == 2);

    /* retain and release balance */
    CONTEXT_VARS_ABI_STEP(50, (A->retain)(aTHX_ cap) == cap);
    (A->release)(aTHX_ cap);

    /* objects: the object takes over a reference, and gives the same context
     * back */
    (A->retain)(aTHX_ cap);
    obj = (A->ctx_to_sv)(aTHX_ cap);
    CONTEXT_VARS_ABI_STEP(60, obj && SvROK(obj) && sv_derived_from(obj, "Context::Vars::Context"));
    got = (A->ctx_from_sv)(aTHX_ obj);
    CONTEXT_VARS_ABI_STEP(61, got == cap);

    /* and refuses what is not one */
    bad = sv_2mortal(newRV_noinc((SV *)newHV()));
    CONTEXT_VARS_ABI_STEP(62, (A->ctx_from_sv)(aTHX_ bad) == NULL);
    sv_bless(bad, gv_stashpvs("Context::Vars::Context", GV_ADD));
    CONTEXT_VARS_ABI_STEP(63, (A->ctx_from_sv)(aTHX_ bad) == NULL);
    bad = sv_2mortal(newSVpvs("Context::Vars::Context"));
    CONTEXT_VARS_ABI_STEP(64, (A->ctx_from_sv)(aTHX_ bad) == NULL);
    CONTEXT_VARS_ABI_STEP(65, (A->ctx_from_sv)(aTHX_ &PL_sv_undef) == NULL);

    LEAVE;
    CONTEXT_VARS_ABI_STEP(70, (A->current)(aTHX) != outer);

    (A->release)(aTHX_ cap);
    cap = NULL;
    {
        dMY_CXT;
        /* The object still holds the one context the Perl side will read. */
        CONTEXT_VARS_ABI_STEP(71, MY_CXT.live == live0 + 1);
        CONTEXT_VARS_ABI_STEP(72, MY_CXT.depth == 0);
    }

done:
    if (*step) {
        if (cap) (A->release)(aTHX_ cap);
        if (obj) { SvREFCNT_dec(obj); obj = NULL; }
    }
    return obj ? sv_2mortal(obj) : &PL_sv_undef;
}

#endif
