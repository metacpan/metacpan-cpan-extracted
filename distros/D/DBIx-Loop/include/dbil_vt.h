#ifndef DBIL_VT_H
#define DBIL_VT_H

/* The pure-C loop seam. A loop adapter that can dispatch entirely in C (the
 * Hyperman adapter, via Hyperman's hm_abi table) stores a dbil_vt pointer in
 * its "_vt" hash slot; backends check dbil_vt_of() and, when present, call
 * these instead of the Perl seam methods (add_reader/add_writer/remove/...).
 * Readiness then reaches the backend with no Perl call frame. Nothing
 * loop-specific appears here - backends see dbil_vt, never hm_abi. */

typedef void (*dbil_io_fn)(pTHX_ int fd, int mask, void *ud);
typedef void (*dbil_timer_fn)(pTHX_ void *ud);

typedef struct dbil_vt {
    void *ctx;                       /* adapter-owned; pass to every call */

    /* persistent fd watchers; ud must outlive the watcher */
    void  (*add_reader)(pTHX_ void *ctx, int fd, dbil_io_fn fn, void *ud);
    void  (*add_writer)(pTHX_ void *ctx, int fd, dbil_io_fn fn, void *ud);
    void  (*remove)(pTHX_ void *ctx, int fd);     /* both directions */

    /* one-shot timer; cancel only before it fires (handle freed on fire) */
    void *(*timer)(pTHX_ void *ctx, double secs, dbil_timer_fn fn, void *ud);
    void  (*timer_cancel)(pTHX_ void *ctx, void *timer);

    /* ecosystem-native pending future (+1, caller owns) */
    SV   *(*new_future)(pTHX_ void *ctx);

    /* pump the loop until the future (native or DBIx::Loop::Future) settles */
    void  (*await)(pTHX_ void *ctx, SV *future);
} dbil_vt;

/* the C vtable of a loop adapter object, or NULL (a Perl-seam adapter) */
static dbil_vt *dbil_vt_of(pTHX_ SV *adapter) {
    HV *h;
    SV **e;
    if (!(adapter && SvROK(adapter) && SvTYPE(SvRV(adapter)) == SVt_PVHV))
        return NULL;
    h = (HV *)SvRV(adapter);
    e = hv_fetchs(h, "_vt", 0);
    return (e && *e && SvIOK(*e)) ? INT2PTR(dbil_vt *, SvIV(*e)) : NULL;
}

#endif /* DBIL_VT_H */
