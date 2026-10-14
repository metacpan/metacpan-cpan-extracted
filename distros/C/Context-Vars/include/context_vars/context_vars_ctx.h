#ifndef CONTEXT_VARS_CTX_H
#define CONTEXT_VARS_CTX_H

/* The context core: what a context is, which one is current, and how one is
 * made current for a stretch of code and put back afterwards.
 *
 * A context is a HOLDER: one HAMT map struct that the holder owns, and a
 * count. HAMT's map struct is a small thing onto a tree of shared nodes; a
 * second struct onto the same nodes costs one small allocation, and the
 * first store through either copies the few nodes it touches and leaves the
 * other exactly as it was. That is the whole of why this is cheap: making a
 * context for a sub call, or keeping one for a callback, is map_copy.
 *
 * Two holders never share a struct. They share nodes.
 *
 * ---- the current context ------------------------------------------------
 *
 * One pointer for each interpreter, in MY_CXT. It is changed in exactly two
 * ways: something is entered, which puts the restore on the save stack, and
 * that restore runs. Nothing sets it and walks away. A croak between the two
 * runs the restore as a return does, and what goes back is the PREVIOUS
 * context, not the empty one, so that nesting works.
 *
 * ---- the empty context --------------------------------------------------
 *
 * One holder for each interpreter, current when nothing has been entered. It
 * is what every piece of code with no context of its own sees, all at once,
 * so NOTHING IS EVER STORED INTO IT: a value there would be read by whatever
 * ran next, which is the mistake this module exists to make impossible.
 * context_vars_store and context_vars_remove croak when it is current. */

struct context_vars_ctx {
    hamt_map                *map;
    UV                       refcnt;
    struct context_vars_ctx *next;      /* on the freelist */
};
/* Also declared, as an opaque type, by the public context_vars_abi.h. */
#ifndef CONTEXT_VARS_CTX_FWD
#define CONTEXT_VARS_CTX_FWD
typedef struct context_vars_ctx context_vars_ctx;
#endif

/* Holders kept for reuse, for each interpreter. A scoped sub call takes one
 * and gives it back, so past the first few calls nothing is allocated. */
#define CONTEXT_VARS_FREE_MAX 64

typedef struct {
    context_vars_ctx *cur;
    context_vars_ctx *empty;
    context_vars_ctx *free_list;
    IV                free_n;
    IV                live;         /* holders handed out and not given back */
    IV                depth;        /* enters whose restore has not run */
    IV                scopes;       /* scopes opened, for the tests */
    context_vars_ctx *program;      /* see context_vars_writable */
    AV               *locals;       /* what `local` displaced, newest last */
} my_cxt_t;

START_MY_CXT

/* ---- holders ------------------------------------------------------------ */

/* A new holder that owns `map`, with a count of one. Takes over the struct,
 * including when it fails: the caller never releases `map` itself. */
static context_vars_ctx *context_vars_ctx_new(pTHX_ hamt_map *map) {
    dMY_CXT;
    context_vars_ctx *c;

    if (!map) croak("Context::Vars: out of memory");

    if (MY_CXT.free_list) {
        c = MY_CXT.free_list;
        MY_CXT.free_list = c->next;
        MY_CXT.free_n--;
    }
    else {
        Newx(c, 1, context_vars_ctx);
    }
    c->map    = map;
    c->refcnt = 1;
    c->next   = NULL;
    MY_CXT.live++;
    return c;
}

static context_vars_ctx *context_vars_retain(pTHX_ context_vars_ctx *c) {
    PERL_UNUSED_CONTEXT;
    c->refcnt++;
    return c;
}

static void context_vars_release(pTHX_ context_vars_ctx *c) {
    dMY_CXT;
    if (--c->refcnt) return;

    (CONTEXT_VARS_HAMT->map_release)(aTHX_ c->map);
    c->map = NULL;
    MY_CXT.live--;
    if (MY_CXT.free_n < CONTEXT_VARS_FREE_MAX) {
        c->next = MY_CXT.free_list;
        MY_CXT.free_list = c;
        MY_CXT.free_n++;
    }
    else {
        Safefree(c);
    }
}

/* ---- the current context ------------------------------------------------ */

/* Borrowed. Never NULL. */
static context_vars_ctx *context_vars_current(pTHX) {
    dMY_CXT;
    return MY_CXT.cur;
}

static int context_vars_is_empty(pTHX_ const context_vars_ctx *c) {
    dMY_CXT;
    return c == MY_CXT.empty;
}

/* What the current context holds, kept for later: a new holder onto the same
 * nodes, owned by the caller. With nothing entered it is the empty context
 * itself with its count raised, and nothing is allocated. */
static context_vars_ctx *context_vars_capture(pTHX) {
    dMY_CXT;
    if (MY_CXT.cur == MY_CXT.empty)
        return context_vars_retain(aTHX_ MY_CXT.empty);
    return context_vars_ctx_new(aTHX_
        (CONTEXT_VARS_HAMT->map_copy)(aTHX_ MY_CXT.cur->map));
}

/* The save-stack destructor. `p` is the context to put back. */
static void context_vars_restore(pTHX_ void *p) {
    dMY_CXT;
    context_vars_ctx *leaving = MY_CXT.cur;
    MY_CXT.cur = (context_vars_ctx *)p;
    MY_CXT.depth--;
    context_vars_release(aTHX_ leaving);
}

/* Makes `c` itself current until the caller's LEAVE. The caller must be
 * inside an ENTER of its own. A store while it is current changes `c`, and
 * the next enter of `c` sees it. */
static void context_vars_enter(pTHX_ context_vars_ctx *c) {
    dMY_CXT;
    context_vars_retain(aTHX_ c);
    SAVEDESTRUCTOR_X(context_vars_restore, (void *)MY_CXT.cur);
    MY_CXT.cur = c;
    MY_CXT.depth++;
}

/* Makes a NEW holder current, onto the nodes `c` holds, until the caller's
 * LEAVE. A store while it is current changes nothing anybody else can see.
 *
 * A copy of the EMPTY context is the empty context itself, entered: nothing
 * is allocated, which is what lets a loop capture and enter for every
 * callback at almost no cost when no variable is ever assigned. The first
 * store there gives the frame a holder of its own (context_vars_writable),
 * so the empty context is still never written. */
static void context_vars_enter_copy(pTHX_ const context_vars_ctx *c) {
    dMY_CXT;
    context_vars_ctx *fresh;
    if (c == MY_CXT.empty) {
        context_vars_enter(aTHX_ MY_CXT.empty);
        return;
    }
    fresh = context_vars_ctx_new(aTHX_
        (CONTEXT_VARS_HAMT->map_copy)(aTHX_ c->map));
    SAVEDESTRUCTOR_X(context_vars_restore, (void *)MY_CXT.cur);
    MY_CXT.cur = fresh;
    MY_CXT.depth++;
}

/* A fresh context onto what is current now, until the caller's LEAVE. */
static void context_vars_scope(pTHX) {
    dMY_CXT;
    MY_CXT.scopes++;
    context_vars_enter_copy(aTHX_ MY_CXT.cur);
}

/* ---- variables ---------------------------------------------------------- */

/* The stored scalar, borrowed and read-only, or NULL when the name is not
 * set. It is valid until the current context is next stored into or left. */
static SV *context_vars_fetch(pTHX_ const char *name, STRLEN len) {
    dMY_CXT;
    return (CONTEXT_VARS_HAMT->map_fetch)(aTHX_ MY_CXT.cur->map, name, len, 0);
}

/* Makes sure the current context is one that may be stored into, which the
 * empty context never is.
 *
 * With nothing entered, the empty context is replaced as the current one,
 * for the rest of the interpreter's life, by the PROGRAM CONTEXT: a holder
 * that code outside any scope shares. It is made the first time such code
 * assigns a variable, and a program that never does that never has one.
 *
 * With something entered and the empty context current - a capture taken
 * with nothing set was entered - the entered frame gets a fresh holder of
 * its own in the empty one's place, and its restore lets go of that. */
static void context_vars_writable(pTHX) {
    dMY_CXT;
    context_vars_ctx *fresh;

    if (MY_CXT.cur != MY_CXT.empty) return;

    fresh = context_vars_ctx_new(aTHX_
        (CONTEXT_VARS_HAMT->map_copy)(aTHX_ MY_CXT.empty->map));
    if (MY_CXT.depth == 0) {
        MY_CXT.program = fresh;
        /* Not a holder a test counts: it is never given back. */
        MY_CXT.live--;
    }
    else {
        /* The enter that made the empty context current took a reference
         * to it, which the restore would have given back. */
        MY_CXT.empty->refcnt--;
    }
    MY_CXT.cur = fresh;
}

static void context_vars_refuse_empty(pTHX_ const char *what) {
    dMY_CXT;
    if (MY_CXT.cur == MY_CXT.empty)
        croak("Context::Vars: internal error: %s with no context entered", what);
}

/* Stores a copy of `value`. The caller's scalar is not kept. */
static void context_vars_store(pTHX_ const char *name, STRLEN len, SV *value) {
    dMY_CXT;
    context_vars_refuse_empty(aTHX_ "a store");
    if ((CONTEXT_VARS_HAMT->map_store)(aTHX_ MY_CXT.cur->map, name, len, 0, value)
            != HAMT_ABI_OK)
        croak("Context::Vars: out of memory");
}

/* Removing a name that is not set is not an error. */
static void context_vars_remove(pTHX_ const char *name, STRLEN len) {
    dMY_CXT;
    context_vars_refuse_empty(aTHX_ "a remove");
    if ((CONTEXT_VARS_HAMT->map_remove)(aTHX_ MY_CXT.cur->map, name, len, 0)
            != HAMT_ABI_OK)
        croak("Context::Vars: out of memory");
}

static size_t context_vars_count(pTHX) {
    dMY_CXT;
    return (CONTEXT_VARS_HAMT->map_count)(aTHX_ MY_CXT.cur->map);
}

/* ---- one interpreter's state --------------------------------------------- */

/* Called with MY_CXT already made, at BOOT and in a new thread. A new thread
 * starts with its own empty context and nothing else: a holder's nodes own
 * scalars of the interpreter that made them. */
static void context_vars_ctx_init(pTHX) {
    dMY_CXT;
    MY_CXT.free_list = NULL;
    MY_CXT.free_n    = 0;
    MY_CXT.live      = 0;
    MY_CXT.depth     = 0;
    MY_CXT.scopes    = 0;
    MY_CXT.empty     = NULL;
    MY_CXT.cur       = NULL;
    MY_CXT.program   = NULL;
    MY_CXT.locals    = newAV();
    MY_CXT.empty     = context_vars_ctx_new(aTHX_ (CONTEXT_VARS_HAMT->map_new)(aTHX));
    MY_CXT.cur       = MY_CXT.empty;
    /* The empty context is not one of the holders a test counts. */
    MY_CXT.live      = 0;
}

#endif
