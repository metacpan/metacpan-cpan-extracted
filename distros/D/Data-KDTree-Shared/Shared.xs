#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <math.h>
#include "kdtree.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::KDTree::Shared")) \
        croak("Expected a Data::KDTree::Shared object"); \
    KdHandle *h = INT2PTR(KdHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::KDTree::Shared object"); \
    KdHandle *h0 = h; PERL_UNUSED_VAR(h0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code. EXTRACT's
 * sv_2mortal(SvREFCNT_inc(...)) pin only blocks REFCOUNT-driven destruction;
 * an explicit $obj->DESTROY frees the handle regardless and zeroes the IV.
 * Magic reaches us through kd_read_point: SvGETMAGIC on the arrayref, av_len
 * on a TIED array (AvFILL -> mg_size -> FETCHSIZE), and SvNV on each element.
 * The same Perl can also REPLACE the invocant ($obj = 42 mutates ST(0),
 * because Perl passes aliases), hence the SvROK re-check before SvRV. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::KDTree::Shared object was replaced during the call"); \
    h = INT2PTR(KdHandle*, SvIV(SvRV(sv))); \
    if (h != h0) croak("Data::KDTree::Shared object replaced or destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

/* Take a lock suitable for a query: read lock if the tree is already built,
 * otherwise upgrade to the write lock and (re)build a balanced tree.  Returns 1
 * if holding the write lock, 0 if holding the read lock. */
static int kd_query_lock(KdHandle *h) {
    kd_rwlock_rdlock(h);
    if (!h->hdr->dirty) return 0;
    kd_rwlock_rdunlock(h);
    kd_rwlock_wrlock(h);
    if (h->hdr->dirty) kd_build_locked(h);
    return 1;
}
static void kd_query_unlock(KdHandle *h, int wr) {
    if (wr) kd_rwlock_wrunlock(h); else kd_rwlock_rdunlock(h);
}

/* read an arrayref of exactly dims finite coordinates into buf (croaks on error) */
/* `dims` is immutable geometry, so it is snapshotted ONCE up front rather than
 * re-read from the handle after each magic-capable step: the arrayref's
 * get-magic, a tied array's FETCHSIZE, and every element's SvNV can all run
 * Perl that destroys the object. The caller re-reads its own handle after this
 * returns (see REEXTRACT at each call site) -- `h` here is by value, so a
 * re-read inside this function would not reach the caller's copy. */
static void kd_read_point(pTHX_ KdHandle *h, SV *aref, double *buf, const char *what) {
    uint32_t dims = h->dims;
    SvGETMAGIC(aref);   /* a tied/overloaded container FETCHes its arrayref here */
    if (!SvROK(aref) || SvTYPE(SvRV(aref)) != SVt_PVAV)
        croak("Data::KDTree::Shared->%s: expected an array reference of %u coordinates", what, (unsigned)dims);
    AV *av = (AV *)SvRV(aref);
    sv_2mortal(SvREFCNT_inc((SV *)av));   /* pin the arrayref: element magic below cannot free it mid-loop */
    if (av_len(av) + 1 != (IV)dims)
        croak("Data::KDTree::Shared->%s: expected %u coordinates, got %ld", what, (unsigned)dims, (long)(av_len(av) + 1));
    for (uint32_t d = 0; d < dims; d++) {
        SV **el = av_fetch(av, (SSize_t)d, 0);
        double v = (el && *el) ? SvNV(*el) : 0.0;
        if (!isfinite(v)) croak("Data::KDTree::Shared->%s: coordinate %u is not finite", what, (unsigned)d);
        buf[d] = v;
    }
}

/* sort KdRes ascending by distance (tiebreak by id) for knn/radius results */
static int kd_res_cmp(const void *pa, const void *pb) {
    const KdRes *a = (const KdRes *)pa, *b = (const KdRes *)pb;
    if (a->dist2 < b->dist2) return -1;
    if (a->dist2 > b->dist2) return  1;
    return (a->id < b->id) ? -1 : (a->id > b->id ? 1 : 0);
}

MODULE = Data::KDTree::Shared  PACKAGE = Data::KDTree::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, dims = 2, capacity = 0, ...)
    const char *class
    SV *path
    UV dims
    UV capacity
  PREINIT:
    char errbuf[KD_ERR_BUFLEN];
  CODE:
    if (capacity < 1)
        croak("Data::KDTree::Shared->new: capacity must be >= 1");
    /* Optional 5th arg: file mode for a newly-created file-backed segment
     * (default 0600, owner-only). Pass e.g. 0660 for cross-user sharing. */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    /* Capture the path PV only after every trailing arg is resolved: the
     * get-magic above can run Perl code that reallocs/frees path's PV. */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    KdHandle *h = kd_create(p, (uint64_t)dims, (uint64_t)capacity, mode, errbuf);
    if (!h) croak("Data::KDTree::Shared->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, dims = 2, capacity = 0)
    const char *class
    SV *name
    UV dims
    UV capacity
  PREINIT:
    char errbuf[KD_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (capacity < 1)
        croak("Data::KDTree::Shared->new_memfd: capacity must be >= 1");
    KdHandle *h = kd_create_memfd(nm, (uint64_t)dims, (uint64_t)capacity, errbuf);
    if (!h) croak("Data::KDTree::Shared->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[KD_ERR_BUFLEN];
  CODE:
    KdHandle *h = kd_open_fd(fd, errbuf);
    if (!h) croak("Data::KDTree::Shared->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_readonly(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[KD_ERR_BUFLEN];
  CODE:
    /* Open a FROZEN (sealed) file read-only: O_RDONLY + PROT_READ, no lock
       ever.  A sealed file is immutable and no read path writes the mapping,
       so queries take no reader-slot / rwlock traffic and any number of
       processes can share one PROT_READ mapping (same architecture; the
       magic rejects a wrong-endian file). */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    if (!p) croak("Data::KDTree::Shared->new_readonly: path is required");
    KdHandle *h = kd_open_readonly(p, errbuf);
    if (!h) croak("Data::KDTree::Shared->new_readonly: %s", errbuf);
    class = SvPV_nolen(ST(0));   /* re-read the class PV after path's get-magic (may realloc ST(0)) */
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::KDTree::Shared")) {
        KdHandle *h = INT2PTR(KdHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); kd_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
add(self, coords, id = &PL_sv_undef)
    SV *self
    SV *coords
    SV *id
  PREINIT:
    EXTRACT(self);
    double buf[KD_MAX_DIMS];
    int64_t slot;
    uint64_t payload;
  CODE:
    if (h->readonly) croak("Data::KDTree::Shared->add: tree is frozen (read-only)");
    kd_read_point(aTHX_ h, coords, buf, "add");     /* may croak -- BEFORE the lock */
    REEXTRACT(self);   /* kd_read_point ran arbitrary Perl */
    /* Resolve the id BEFORE locking: SvUV on a tied/overloaded SV can run Perl
     * code that dies, and a longjmp past the wrlock would strand it on a live
     * PID (dead-owner recovery never fires) -- a permanent shared-segment deadlock. */
    int have_id = (SvGETMAGIC(id), SvOK(id));
    uint64_t id_val = have_id ? (uint64_t)SvUV(id) : 0;
    REEXTRACT(self);   /* the id's get-magic is a second window */
    kd_rwlock_wrlock(h);
    if (h->hdr->sealed) { kd_rwlock_wrunlock(h); croak("Data::KDTree::Shared->add: tree is frozen (read-only)"); }
    payload = have_id ? id_val : h->hdr->count;     /* default id = insertion index */
    slot = kd_add_locked(h, buf, payload);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    kd_rwlock_wrunlock(h);
    if (slot < 0) croak("Data::KDTree::Shared->add: tree is full (capacity %u)", (unsigned)h->capacity);
    RETVAL = (UV)slot;
  OUTPUT:
    RETVAL

void
build(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::KDTree::Shared->build: tree is frozen (read-only)");
    kd_rwlock_wrlock(h);
    if (h->hdr->sealed) { kd_rwlock_wrunlock(h); croak("Data::KDTree::Shared->build: tree is frozen (read-only)"); }
    if (h->hdr->dirty) kd_build_locked(h);
    kd_rwlock_wrunlock(h);

SV *
nearest(self, coords)
    SV *self
    SV *coords
  PREINIT:
    EXTRACT(self);
    double buf[KD_MAX_DIMS];
    KdRes best;
    uint64_t found;
  CODE:
    kd_read_point(aTHX_ h, coords, buf, "nearest");
    REEXTRACT(self);   /* kd_read_point ran arbitrary Perl */
    if (h->readonly) {   /* frozen: freeze() force-built the tree, so it is never dirty here -- lock-free, no build */
        found = kd_knn_locked(h, buf, 1, &best);
    } else {
        int wr = kd_query_lock(h);
        found = kd_knn_locked(h, buf, 1, &best);
        kd_query_unlock(h, wr);
    }
    if (found) {
        HV *hv = newHV();
        hv_stores(hv, "id",   newSVuv((UV)best.id));
        hv_stores(hv, "dist", newSVnv(sqrt(best.dist2)));
        RETVAL = newRV_noinc((SV *)hv);
    } else {
        RETVAL = &PL_sv_undef;      /* empty tree */
    }
  OUTPUT:
    RETVAL

void
knn(self, coords, m)
    SV *self
    SV *coords
    UV m
  PREINIT:
    EXTRACT(self);
    double buf[KD_MAX_DIMS];
  PPCODE:
    kd_read_point(aTHX_ h, coords, buf, "knn");
    REEXTRACT(self);   /* kd_read_point ran arbitrary Perl */
    {
        KdRes *res = NULL;
        uint64_t got = 0, i;
        if (m > h->capacity) m = h->capacity;   /* at most all points */
        if (m) { Newx(res, (size_t)m, KdRes); SAVEFREEPV(res); }   /* alloc BEFORE the lock */
        if (h->readonly) {   /* frozen: never dirty -- lock-free, no build */
            got = m ? kd_knn_locked(h, buf, m, res) : 0;
        } else {
            int wr = kd_query_lock(h);
            got = m ? kd_knn_locked(h, buf, m, res) : 0;
            kd_query_unlock(h, wr);
        }
        if (got) qsort(res, (size_t)got, sizeof(KdRes), kd_res_cmp);
        EXTEND(SP, (SSize_t)got);
        for (i = 0; i < got; i++) {
            HV *hv = newHV();
            hv_stores(hv, "id",   newSVuv((UV)res[i].id));
            hv_stores(hv, "dist", newSVnv(sqrt(res[i].dist2)));
            PUSHs(sv_2mortal(newRV_noinc((SV *)hv)));
        }
    }

void
range(self, lo, hi)
    SV *self
    SV *lo
    SV *hi
  PREINIT:
    EXTRACT(self);
    double blo[KD_MAX_DIMS], bhi[KD_MAX_DIMS];
  PPCODE:
    kd_read_point(aTHX_ h, lo, blo, "range");
    REEXTRACT(self);   /* kd_read_point ran arbitrary Perl */
    kd_read_point(aTHX_ h, hi, bhi, "range");
    REEXTRACT(self);   /* kd_read_point ran arbitrary Perl */
    {
        uint64_t *ids = NULL, got = 0, i, cap = h->capacity;
        if (cap) { Newx(ids, (size_t)cap, uint64_t); SAVEFREEPV(ids); }   /* alloc BEFORE the lock */
        if (h->readonly) {   /* frozen: never dirty -- lock-free, no build */
            got = cap ? kd_range_locked(h, blo, bhi, ids, cap) : 0;
        } else {
            int wr = kd_query_lock(h);
            got = cap ? kd_range_locked(h, blo, bhi, ids, cap) : 0;
            kd_query_unlock(h, wr);
        }
        EXTEND(SP, (SSize_t)got);
        for (i = 0; i < got; i++) PUSHs(sv_2mortal(newSVuv((UV)ids[i])));
    }

void
radius(self, coords, r)
    SV *self
    SV *coords
    double r
  PREINIT:
    EXTRACT(self);
    double buf[KD_MAX_DIMS];
  PPCODE:
    if (r < 0) croak("Data::KDTree::Shared->radius: radius must be >= 0");
    kd_read_point(aTHX_ h, coords, buf, "radius");
    REEXTRACT(self);   /* kd_read_point ran arbitrary Perl */
    {
        KdRes *res = NULL;
        uint64_t got = 0, i, cap = h->capacity;
        if (cap) { Newx(res, (size_t)cap, KdRes); SAVEFREEPV(res); }   /* alloc BEFORE the lock */
        if (h->readonly) {   /* frozen: never dirty -- lock-free, no build */
            got = cap ? kd_radius_locked(h, buf, r, res, cap) : 0;
        } else {
            int wr = kd_query_lock(h);
            got = cap ? kd_radius_locked(h, buf, r, res, cap) : 0;
            kd_query_unlock(h, wr);
        }
        if (got) qsort(res, (size_t)got, sizeof(KdRes), kd_res_cmp);
        EXTEND(SP, (SSize_t)got);
        for (i = 0; i < got; i++) {
            HV *hv = newHV();
            hv_stores(hv, "id",   newSVuv((UV)res[i].id));
            hv_stores(hv, "dist", newSVnv(sqrt(res[i].dist2)));
            PUSHs(sv_2mortal(newRV_noinc((SV *)hv)));
        }
    }

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::KDTree::Shared->clear: tree is frozen (read-only)");
    kd_rwlock_wrlock(h);
    if (h->hdr->sealed) { kd_rwlock_wrunlock(h); croak("Data::KDTree::Shared->clear: tree is frozen (read-only)"); }
    kd_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    kd_rwlock_wrunlock(h);

void
freeze(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::KDTree::Shared->freeze: cannot freeze a read-only handle");
    if (kd_freeze(h) != 0) croak("Data::KDTree::Shared->freeze: msync: %s", strerror(errno));
    h->readonly = 1;   /* this handle now rejects mutation too (the file is sealed) */

UV
frozen(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->sealed ? 1 : 0;
  OUTPUT:
    RETVAL

UV
readonly(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->readonly ? 1 : 0;
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV n;
  CODE:
    if (h->readonly) {                     /* frozen: immutable, no lock needed */
        n = (UV)h->hdr->count;
    } else {
        kd_rwlock_rdlock(h);
        n = (UV)h->hdr->count;
        kd_rwlock_rdunlock(h);
    }
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

UV
dims(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->dims;
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
        uint32_t dims, cap, dirty;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSVuv can never strand the lock. */
        if (!h->readonly) kd_rwlock_rdlock(h);   /* frozen: immutable, no lock */
        count = h->hdr->count;
        dims  = h->hdr->dims;
        cap   = h->hdr->capacity;
        dirty = h->hdr->dirty;
        ops   = h->hdr->stat_ops;
        if (!h->readonly) kd_rwlock_rdunlock(h);
        HV *hv = newHV();
        hv_stores(hv, "count",     newSVuv((UV)count));
        hv_stores(hv, "dims",      newSVuv((UV)dims));
        hv_stores(hv, "capacity",  newSVuv((UV)cap));
        hv_stores(hv, "dirty",     newSVuv((UV)dirty));
        hv_stores(hv, "ops",       newSVuv((UV)ops));
        hv_stores(hv, "mmap_size", newSVuv((UV)h->mmap_size));
        hv_stores(hv, "frozen",    newSVuv(h->hdr->sealed ? 1 : 0));
        hv_stores(hv, "readonly",  newSVuv(h->readonly ? 1 : 0));
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
    if (!h->readonly && kd_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::KDTree::Shared")) {
        KdHandle *h = INT2PTR(KdHandle*, SvIV(SvRV(self)));
        if (h && h->path && unlink(h->path) != 0 && errno != ENOENT)
            croak("Data::KDTree::Shared->unlink(%s): %s", h->path, strerror(errno));
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        {
            const char *up = SvPV_nolen(ST(1));
            if (unlink(up) != 0 && errno != ENOENT)
                croak("Data::KDTree::Shared->unlink(%s): %s", up, strerror(errno));
        }
    }
