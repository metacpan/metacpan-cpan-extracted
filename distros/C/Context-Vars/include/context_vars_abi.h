#ifndef CONTEXT_VARS_ABI_H
#define CONTEXT_VARS_ABI_H

/* Public C ABI for Context::Vars: what an event loop, a future or a queue
 * written in C needs to run each callback with the variables of the moment
 * it was registered, with no Perl call in between; and what C code needs to
 * read and assign a variable an application imported.
 *
 * It is resolved at RUNTIME through Context::Vars::_abi_ptr - a versioned
 * table of function pointers - so there is no link-time coupling: each dist
 * builds and upgrades by itself. A consumer reaches this header through
 * ExtUtils::Depends, or vendors a copy pinned at CONTEXT_VARS_ABI_VERSION,
 * and checks abi_version once when it loads.
 *
 * This is the only header a consumer needs. Nothing from HAMT, which
 * Context::Vars is built on, appears in it.
 *
 * The table only ever grows at the end. CONTEXT_VARS_ABI_VERSION bumps on
 * any append, and a consumer requires abi_version >= the version it was
 * written against. NOT ==.
 *
 * ---- THIS HEADER NEEDS PERL ---------------------------------------------
 *
 * Every entry takes pTHX_: a context holds Perl scalars, and letting go of
 * one has to reach the interpreter. Include perl's headers first.
 *
 * ---- resolving the table ------------------------------------------------
 *
 * At BOOT, once, never per call:
 *
 *     static const context_vars_abi *VARS = NULL;
 *
 *     BOOT:
 *     {
 *         SV *err;
 *         SV *sv = eval_pv("require Context::Vars; Context::Vars::_abi_ptr()", 0);
 *         err = get_sv("@", 0);
 *         if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
 *             const context_vars_abi *t = INT2PTR(const context_vars_abi *, SvUV(sv));
 *             if (t && t->abi_version >= CONTEXT_VARS_ABI_VERSION) VARS = t;
 *         }
 *     }
 *
 * The VALUE eval_pv returns, not the top of the stack. A NULL table means
 * Context::Vars is absent or too old; a loop then runs its callbacks as it
 * always did, which is the behaviour before Context::Vars existed.
 *
 * Calls are written (VARS->capture)(aTHX). The parentheses cost nothing and
 * keep a member's name from ever being read as a function-like macro, which
 * is how XSUB.h redefines a number of ordinary names on a perl built with
 * PERL_IMPLICIT_SYS.
 *
 * ---- what a loop does ---------------------------------------------------
 *
 *     cb->ctx = (VARS->capture)(aTHX);           when the callback is registered
 *
 *     ENTER;                                      when it is run
 *     (VARS->enter_copy)(aTHX_ cb->ctx);
 *     call_sv(cb->code, G_DISCARD | G_EVAL);
 *     LEAVE;
 *
 *     (VARS->release)(aTHX_ cb->ctx);             when the callback is dropped
 *
 * enter_copy runs the callback in a fresh copy of what was captured, so a
 * callback that runs more than once - a handler for every message on a
 * socket - starts from the same values every time. enter runs it in the
 * captured context itself, so that what one run leaves there the next one
 * sees; that is what Context::Vars::Context::run does.
 *
 * ---- the rules ----------------------------------------------------------
 *
 * - A context_vars_ctx is opaque and counted. capture, retain and ctx_from_sv
 *   aside, nothing hands one out. capture's and retain's are the caller's to
 *   give back, exactly once, to release; current's and ctx_from_sv's are
 *   borrowed.
 *
 * - enter, enter_copy and scope put what is current back on the SAVE STACK:
 *   the caller must be inside an ENTER of its own, and the previous context
 *   comes back at the matching LEAVE, whether the code in between returned or
 *   died. Called outside an ENTER, the previous context comes back whenever
 *   some outer scope ends, which is a bug in the caller that nothing here can
 *   detect.
 *
 * - capture with nothing set anywhere returns the one shared empty context
 *   and allocates nothing. It is still released.
 *
 * - var_fetch returns the stored scalar, BORROWED and read-only, valid until
 *   the current context is next assigned to or left; NULL when the name has
 *   no value. To keep it, copy it.
 *
 * - var_store stores a copy of `value`; the caller's scalar is not kept. NULL
 *   or an undefined value unsets the name. A store from C has no sub to be
 *   scoped to: it changes whatever context is current. A caller that wants
 *   its store to end with its own frame calls scope first, inside its ENTER
 *   and LEAVE.
 *
 * - A name is the variable's name without its sigil, in ASCII bytes:
 *   "request_id" for $request_id. One name is one variable, whichever
 *   package imported it.
 *
 * - ctx_to_sv makes a Context::Vars::Context object, TAKING OVER the
 *   caller's reference to the context. The object comes back with one
 *   reference count, which is the caller's.
 *
 * - Everything here belongs to one interpreter. A context made in one thread
 *   must not be used in another. */

#define CONTEXT_VARS_ABI_VERSION 1

#ifndef CONTEXT_VARS_CTX_FWD
#define CONTEXT_VARS_CTX_FWD
typedef struct context_vars_ctx context_vars_ctx;       /* opaque */
#endif

typedef struct context_vars_abi {
    int abi_version;

    /* ---- contexts ------------------------------------------------------ */

    /* The context code is running in now. Borrowed; never NULL. */
    context_vars_ctx *(*current)(pTHX);
    /* What is current now, kept: the caller's, to release. */
    context_vars_ctx *(*capture)(pTHX);
    /* One more reference to a context; returns it. */
    context_vars_ctx *(*retain)(pTHX_ context_vars_ctx *c);
    /* Gives one reference back. The pointer may be dead afterwards. */
    void              (*release)(pTHX_ context_vars_ctx *c);

    /* ---- running code in one: the caller is inside its own ENTER --------- */

    /* Makes `c` itself current until the caller's LEAVE. */
    void              (*enter)(pTHX_ context_vars_ctx *c);
    /* Makes a fresh copy of `c` current until the caller's LEAVE. */
    void              (*enter_copy)(pTHX_ context_vars_ctx *c);
    /* Makes a fresh copy of what is current now current, until the caller's
     * LEAVE: what a Perl sub that assigns a variable gets. */
    void              (*scope)(pTHX);

    /* ---- variables, by name without the sigil ---------------------------- */

    /* The value in the current context, borrowed, or NULL. */
    SV               *(*var_fetch)(pTHX_ const char *name, STRLEN len);
    /* Stores a copy of `value` in the current context; NULL or undef unsets. */
    void              (*var_store)(pTHX_ const char *name, STRLEN len, SV *value);

    /* ---- objects ------------------------------------------------------- */

    /* The context inside a Context::Vars::Context object, borrowed. NULL if
     * `obj` is not one, or is one that belongs to another thread. */
    context_vars_ctx *(*ctx_from_sv)(pTHX_ SV *obj);
    /* A new Context::Vars::Context object. TAKES OVER the reference. */
    SV               *(*ctx_to_sv)(pTHX_ context_vars_ctx *c);
} context_vars_abi;

#endif
