#ifndef CONTEXT_VARS_HAMT_H
#define CONTEXT_VARS_HAMT_H

/* HAMT's table, resolved once when this module loads and never per call.
 *
 * Where every other consumer in this workspace treats a NULL table as a
 * degrade it always had, this one cannot: a context IS a HAMT map, and with
 * no table there is nothing for a variable to be stored in. So the three
 * ways of not getting one all croak, each saying which it was, and the load
 * of Context::Vars fails with that message.
 *
 * Calls are written (CONTEXT_VARS_HAMT->map_fetch)(aTHX_ ...). The
 * parentheses keep a member's name from being read as a function-like macro
 * on a perl built with PERL_IMPLICIT_SYS. */
static const hamt_abi *CONTEXT_VARS_HAMT = NULL;

static void context_vars_hamt_resolve(pTHX) {
    SV *sv, *err;
    const hamt_abi *t;

    if (CONTEXT_VARS_HAMT) return;

    /* The VALUE eval_pv returns, not the top of the stack. */
    sv  = eval_pv("require HAMT; HAMT::_abi_ptr()", 0);
    err = get_sv("@", 0);
    if (err && SvTRUE(err))
        croak("Context::Vars needs HAMT, with its C ABI at version %d or "
              "later, and could not load it: %" SVf,
              HAMT_ABI_VERSION, SVfARG(err));
    if (!sv || !SvOK(sv) || !SvUV(sv))
        croak("Context::Vars needs HAMT, with its C ABI at version %d or "
              "later: the HAMT that loaded has no C ABI table",
              HAMT_ABI_VERSION);

    t = INT2PTR(const hamt_abi *, SvUV(sv));
    if (t->abi_version < HAMT_ABI_VERSION)
        croak("Context::Vars needs HAMT with its C ABI at version %d or "
              "later: the HAMT that loaded has version %d",
              HAMT_ABI_VERSION, t->abi_version);

    CONTEXT_VARS_HAMT = t;
}

#endif
