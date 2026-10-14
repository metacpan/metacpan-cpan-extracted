#ifndef CONTEXT_VARS_CTX_SELFTEST_H
#define CONTEXT_VARS_CTX_SELFTEST_H

/* The core, exercised from C with no Perl code in between. Returns 0, or the
 * number of the first check that did not hold. It must be called with
 * nothing entered, and leaves nothing entered. A croak cannot be provoked
 * from here without losing the count, so the checks that need one are in
 * t/02-core.t, through the doors in xs/test.xs. */

#define CONTEXT_VARS_STEP(n, cond) do { if (!(cond)) return (n); } while (0)

static IV context_vars_st_iv(pTHX_ const char *name) {
    SV *sv = context_vars_fetch(aTHX_ name, strlen(name));
    return sv ? SvIV(sv) : -1;
}

static void context_vars_st_put(pTHX_ const char *name, IV v) {
    SV *sv = sv_2mortal(newSViv(v));
    context_vars_writable(aTHX);
    context_vars_store(aTHX_ name, strlen(name), sv);
}

static int context_vars_ctx_selftest(pTHX) {
    dMY_CXT;
    context_vars_ctx *empty = MY_CXT.empty;
    context_vars_ctx *h1, *c;
    IV live0  = MY_CXT.live;
    UV empty0 = empty->refcnt;

    CONTEXT_VARS_STEP(1, MY_CXT.cur == empty);
    CONTEXT_VARS_STEP(2, MY_CXT.depth == 0);
    CONTEXT_VARS_STEP(3, context_vars_fetch(aTHX_ "a", 1) == NULL);

    /* A scope over nothing shares the empty context and allocates nothing,
     * until the first store gives it a holder of its own. Leaving it puts
     * back the very pointer that was current. */
    ENTER;
    context_vars_scope(aTHX);
    CONTEXT_VARS_STEP(10, MY_CXT.cur == empty);
    CONTEXT_VARS_STEP(11, MY_CXT.depth == 1);
    CONTEXT_VARS_STEP(12, MY_CXT.live == live0);
    CONTEXT_VARS_STEP(19, empty->refcnt == empty0 + 1);
    context_vars_st_put(aTHX_ "a", 1);
    CONTEXT_VARS_STEP(9, MY_CXT.cur != empty && MY_CXT.live == live0 + 1);
    CONTEXT_VARS_STEP(8, empty->refcnt == empty0);
    CONTEXT_VARS_STEP(13, context_vars_st_iv(aTHX_ "a") == 1);
    CONTEXT_VARS_STEP(14, context_vars_count(aTHX) == 1);
    LEAVE;
    CONTEXT_VARS_STEP(15, MY_CXT.cur == empty);
    CONTEXT_VARS_STEP(16, MY_CXT.depth == 0);
    CONTEXT_VARS_STEP(17, MY_CXT.live == live0);
    CONTEXT_VARS_STEP(18, context_vars_fetch(aTHX_ "a", 1) == NULL);

    /* Nested scopes: the inner one starts with what the outer holds, its
     * store does not reach the outer, and they unwind in order. */
    ENTER;
    context_vars_scope(aTHX);
    context_vars_st_put(aTHX_ "a", 1);
    context_vars_st_put(aTHX_ "b", 7);
    h1 = MY_CXT.cur;
    ENTER;
    context_vars_scope(aTHX);
    CONTEXT_VARS_STEP(20, MY_CXT.cur != h1);
    CONTEXT_VARS_STEP(21, context_vars_st_iv(aTHX_ "a") == 1);
    context_vars_st_put(aTHX_ "a", 2);
    context_vars_remove(aTHX_ "b", 1);
    CONTEXT_VARS_STEP(22, context_vars_st_iv(aTHX_ "a") == 2);
    CONTEXT_VARS_STEP(23, context_vars_fetch(aTHX_ "b", 1) == NULL);
    CONTEXT_VARS_STEP(24, MY_CXT.depth == 2);
    LEAVE;
    CONTEXT_VARS_STEP(25, MY_CXT.cur == h1);
    CONTEXT_VARS_STEP(26, context_vars_st_iv(aTHX_ "a") == 1);
    CONTEXT_VARS_STEP(27, context_vars_st_iv(aTHX_ "b") == 7);
    context_vars_remove(aTHX_ "nothere", 7);
    CONTEXT_VARS_STEP(28, context_vars_count(aTHX) == 2);
    LEAVE;
    CONTEXT_VARS_STEP(29, MY_CXT.cur == empty && MY_CXT.live == live0);

    /* A capture with nothing entered is the empty context, and costs no
     * holder. */
    c = context_vars_capture(aTHX);
    CONTEXT_VARS_STEP(30, c == empty);
    CONTEXT_VARS_STEP(31, MY_CXT.live == live0);
    CONTEXT_VARS_STEP(32, empty->refcnt == empty0 + 1);
    context_vars_release(aTHX_ c);
    CONTEXT_VARS_STEP(33, empty->refcnt == empty0);

    /* A capture of something is a holder of its own onto the same values.
     * A later store on either side stays on that side. */
    ENTER;
    context_vars_scope(aTHX);
    context_vars_st_put(aTHX_ "a", 1);
    h1 = MY_CXT.cur;
    c  = context_vars_capture(aTHX);
    CONTEXT_VARS_STEP(40, c != h1 && c != empty);
    CONTEXT_VARS_STEP(41, MY_CXT.live == live0 + 2);
    context_vars_st_put(aTHX_ "a", 2);

    ENTER;
    context_vars_enter(aTHX_ c);
    CONTEXT_VARS_STEP(42, MY_CXT.cur == c);
    CONTEXT_VARS_STEP(43, context_vars_st_iv(aTHX_ "a") == 1);
    context_vars_st_put(aTHX_ "c", 5);
    LEAVE;
    CONTEXT_VARS_STEP(44, MY_CXT.cur == h1);
    CONTEXT_VARS_STEP(45, context_vars_st_iv(aTHX_ "a") == 2);
    CONTEXT_VARS_STEP(46, context_vars_fetch(aTHX_ "c", 1) == NULL);

    /* enter makes the holder itself current, so its second run sees what
     * its first stored. */
    ENTER;
    context_vars_enter(aTHX_ c);
    CONTEXT_VARS_STEP(47, context_vars_st_iv(aTHX_ "c") == 5);
    LEAVE;

    /* enter_copy makes a fresh one each time, so a second run does not. */
    ENTER;
    context_vars_enter_copy(aTHX_ c);
    CONTEXT_VARS_STEP(50, MY_CXT.cur != c);
    CONTEXT_VARS_STEP(51, context_vars_st_iv(aTHX_ "c") == 5);
    context_vars_st_put(aTHX_ "d", 9);
    CONTEXT_VARS_STEP(52, MY_CXT.live == live0 + 3);
    LEAVE;
    CONTEXT_VARS_STEP(53, MY_CXT.live == live0 + 2);
    ENTER;
    context_vars_enter_copy(aTHX_ c);
    CONTEXT_VARS_STEP(54, context_vars_fetch(aTHX_ "d", 1) == NULL);
    LEAVE;

    /* A capture outlives the scope it was taken in. */
    LEAVE;
    CONTEXT_VARS_STEP(60, MY_CXT.cur == empty);
    CONTEXT_VARS_STEP(61, MY_CXT.live == live0 + 1);
    ENTER;
    context_vars_enter(aTHX_ c);
    CONTEXT_VARS_STEP(62, context_vars_st_iv(aTHX_ "a") == 1);
    CONTEXT_VARS_STEP(63, context_vars_st_iv(aTHX_ "c") == 5);
    LEAVE;
    context_vars_release(aTHX_ c);

    CONTEXT_VARS_STEP(70, MY_CXT.cur == empty);
    CONTEXT_VARS_STEP(71, MY_CXT.depth == 0);
    CONTEXT_VARS_STEP(72, MY_CXT.live == live0);
    CONTEXT_VARS_STEP(73, empty->refcnt == empty0);
    return 0;
}

#endif
