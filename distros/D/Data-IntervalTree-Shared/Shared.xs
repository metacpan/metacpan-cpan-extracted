#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "intervaltree.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::IntervalTree::Shared")) \
        croak("Expected a Data::IntervalTree::Shared object"); \
    ItHandle *h = INT2PTR(ItHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::IntervalTree::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT's mortal
 * pins the referent only against refcount-driven destruction, not an
 * explicit DESTROY, so the local `h` would dangle.  Used only where magic
 * can actually intervene between EXTRACT and the first use of h. */
#define REEXTRACT(sv) \
    h = INT2PTR(ItHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::IntervalTree::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

/* Take a lock suitable for a query: read lock if the tree is already built,
 * otherwise upgrade to the write lock and (re)build a balanced tree.  Returns 1
 * if holding the write lock, 0 if holding the read lock. */
static int it_query_lock(ItHandle *h) {
    it_rwlock_rdlock(h);
    if (!h->hdr->dirty) return 0;
    it_rwlock_rdunlock(h);
    it_rwlock_wrlock(h);
    if (h->hdr->dirty) it_build_locked(h);
    return 1;
}
static void it_query_unlock(ItHandle *h, int wr) {
    if (wr) it_rwlock_wrunlock(h); else it_rwlock_rdunlock(h);
}

/* sort matching intervals by lo ascending (tiebreak hi, then id) */
static int it_res_cmp(const void *pa, const void *pb) {
    const ItRes *a = (const ItRes *)pa, *b = (const ItRes *)pb;
    if (a->lo != b->lo) return a->lo < b->lo ? -1 : 1;
    if (a->hi != b->hi) return a->hi < b->hi ? -1 : 1;
    return (a->id < b->id) ? -1 : (a->id > b->id ? 1 : 0);
}

/* push the matched intervals (sorted) as { id, lo, hi } hashrefs; must run after
 * the query lock is released (builds Perl values). */
#define PUSH_RESULTS(res, got) STMT_START {                        \
    uint64_t _i;                                                   \
    if (got) qsort(res, (size_t)(got), sizeof(ItRes), it_res_cmp); \
    EXTEND(SP, (SSize_t)(got));                                    \
    for (_i = 0; _i < (got); _i++) {                              \
        HV *hv = newHV();                                          \
        hv_stores(hv, "id", newSVuv((UV)(res)[_i].id));            \
        hv_stores(hv, "lo", newSViv((IV)(res)[_i].lo));            \
        hv_stores(hv, "hi", newSViv((IV)(res)[_i].hi));            \
        PUSHs(sv_2mortal(newRV_noinc((SV *)hv)));                  \
    }                                                              \
} STMT_END

MODULE = Data::IntervalTree::Shared  PACKAGE = Data::IntervalTree::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, capacity = 0, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[IT_ERR_BUFLEN];
  CODE:
    if (capacity < 1)
        croak("Data::IntervalTree::Shared->new: capacity must be >= 1");
    /* Optional 4th arg: file mode for a newly-created file-backed segment
     * (default 0600, owner-only). Pass e.g. 0660 for cross-user sharing.
     * Resolved BEFORE the path PV is captured: this get-magic runs arbitrary
     * Perl that could realloc/free that PV, so the path is captured last. */
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    ItHandle *h = it_create(p, (uint64_t)capacity, mode, errbuf);
    if (!h) croak("Data::IntervalTree::Shared->new: %s", errbuf);
    /* Re-read the class PV from ST(0) now that all argument magic (capacity,
     * mode, path) has run: xsubpp captured `class` in the INPUT section,
     * before that magic, and the magic can realloc or free the PV it points
     * into.  SvPV_nolen, NOT SvPV_nomg: an overloaded class must stringify
     * through its '""' overload. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, capacity = 0)
    const char *class
    SV *name
    UV capacity
  PREINIT:
    char errbuf[IT_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (capacity < 1)
        croak("Data::IntervalTree::Shared->new_memfd: capacity must be >= 1");
    ItHandle *h = it_create_memfd(nm, (uint64_t)capacity, errbuf);
    if (!h) croak("Data::IntervalTree::Shared->new_memfd: %s", errbuf);
    class = SvPV_nolen(ST(0));   /* re-read after argument magic; see new() */
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[IT_ERR_BUFLEN];
  CODE:
    ItHandle *h = it_open_fd(fd, errbuf);
    if (!h) croak("Data::IntervalTree::Shared->new_from_fd: %s", errbuf);
    class = SvPV_nolen(ST(0));   /* re-read after argument magic; see new() */
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::IntervalTree::Shared")) {
        ItHandle *h = INT2PTR(ItHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); it_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
add(self, lo, hi, id = &PL_sv_undef)
    SV *self
    IV lo
    IV hi
    SV *id
  PREINIT:
    EXTRACT(self);
    int64_t slot;
    uint64_t payload;
  CODE:
    if (lo > hi) croak("Data::IntervalTree::Shared->add: lo (%" IVdf ") > hi (%" IVdf ")", (IV)lo, (IV)hi);
    /* resolve the id BEFORE locking: SvUV on a tied/overloaded SV can run Perl
     * code that dies, and a longjmp past the wrlock would strand it on a live PID. */
    int have_id = (SvGETMAGIC(id), SvOK(id));
    uint64_t id_val = have_id ? (uint64_t)SvUV(id) : 0;
    REEXTRACT(self);
    it_rwlock_wrlock(h);
    payload = have_id ? id_val : h->hdr->count;   /* default id = insertion index */
    slot = it_add_locked(h, (int64_t)lo, (int64_t)hi, payload);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    it_rwlock_wrunlock(h);
    if (slot < 0) croak("Data::IntervalTree::Shared->add: tree is full (capacity %u)", (unsigned)h->capacity);
    RETVAL = (UV)slot;
  OUTPUT:
    RETVAL

void
build(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    it_rwlock_wrlock(h);
    if (h->hdr->dirty) it_build_locked(h);
    it_rwlock_wrunlock(h);

void
stab(self, point)
    SV *self
    IV point
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        ItRes *res = NULL;
        uint64_t got = 0, cap = h->capacity;
        if (cap) { Newx(res, (size_t)cap, ItRes); SAVEFREEPV(res); }   /* alloc BEFORE the lock */
        {
            int wr = it_query_lock(h);
            got = cap ? it_overlaps_locked(h, (int64_t)point, (int64_t)point, res, cap) : 0;
            it_query_unlock(h, wr);
        }
        PUSH_RESULTS(res, got);
    }

void
overlaps(self, lo, hi)
    SV *self
    IV lo
    IV hi
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        ItRes *res = NULL;
        uint64_t got = 0, cap = h->capacity;
        if (lo > hi) croak("Data::IntervalTree::Shared->overlaps: lo (%" IVdf ") > hi (%" IVdf ")", (IV)lo, (IV)hi);
        if (cap) { Newx(res, (size_t)cap, ItRes); SAVEFREEPV(res); }   /* alloc BEFORE the lock */
        {
            int wr = it_query_lock(h);
            got = cap ? it_overlaps_locked(h, (int64_t)lo, (int64_t)hi, res, cap) : 0;
            it_query_unlock(h, wr);
        }
        PUSH_RESULTS(res, got);
    }

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    it_rwlock_wrlock(h);
    it_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    it_rwlock_wrunlock(h);

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV n;
  CODE:
    it_rwlock_rdlock(h);
    n = (UV)h->hdr->count;
    it_rwlock_rdunlock(h);
    RETVAL = n;
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->capacity;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t count, ops;
        uint32_t cap, dirty;
        it_rwlock_rdlock(h);
        count = h->hdr->count;
        cap   = h->hdr->capacity;
        dirty = h->hdr->dirty;
        ops   = h->hdr->stat_ops;
        it_rwlock_rdunlock(h);
        HV *hv = newHV();
        hv_stores(hv, "count",     newSVuv((UV)count));
        hv_stores(hv, "capacity",  newSVuv((UV)cap));
        hv_stores(hv, "dirty",     newSVuv((UV)dirty));
        hv_stores(hv, "ops",       newSVuv((UV)ops));
        hv_stores(hv, "mmap_size", newSVuv((UV)h->mmap_size));
        RETVAL = newRV_noinc((SV *)hv);
    }
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

int
memfd(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (it_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::IntervalTree::Shared")) {
        ItHandle *h = INT2PTR(ItHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
