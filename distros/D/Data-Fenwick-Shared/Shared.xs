#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "fenwick.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Fenwick::Shared")) \
        croak("Expected a Data::Fenwick::Shared object"); \
    FenHandle *h = INT2PTR(FenHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Fenwick::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))


/* Re-read the handle after a call that can run Perl code. EXTRACT's
 * sv_2mortal(SvREFCNT_inc(...)) pin only blocks REFCOUNT-driven destruction;
 * an explicit $obj->DESTROY frees the handle regardless and zeroes the IV.
 * sv_isobject/sv_derived_from both BEGIN with SvGETMAGIC, so a tied argument
 * runs Perl there. The same Perl can also REPLACE the invocant ($obj = 42
 * mutates ST(0), because Perl passes aliases), hence the SvROK re-check. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::Fenwick::Shared object was replaced during the call"); \
    h = INT2PTR(FenHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::Fenwick::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

/* 1-based position bounds check (croaks with a clear message) */
#define CHECK_POS(i) \
    do { if ((i) < 1 || (i) > h->hdr->n) \
        croak("Data::Fenwick::Shared: position %" UVuf " out of range 1..%" UVuf, \
              (UV)(i), (UV)h->hdr->n); } while (0)

MODULE = Data::Fenwick::Shared  PACKAGE = Data::Fenwick::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, n = 0, ...)
    const char *class
    SV *path
    UV n
  PREINIT:
    char errbuf[FEN_ERR_BUFLEN];
  CODE:
    if (n < 1)
        croak("Data::Fenwick::Shared->new: n (number of positions) must be >= 1");
    /* Optional 4th arg: file mode for a newly-created file-backed segment
     * (default 0600, owner-only). Pass e.g. 0660 to opt into cross-user
     * sharing. Ignored for anonymous segments and existing files. */
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    /* Capture the path PV last: the get-magic on ST(3) above may run code
     * that reallocs/frees the path SV's buffer, dangling an earlier pointer. */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    FenHandle *hh = fen_create(p, (uint64_t)n, FEN_MODE_POINT, mode, errbuf);
    if (!hh) croak("Data::Fenwick::Shared->new: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, n = 0)
    const char *class
    SV *name
    UV n
  PREINIT:
    char errbuf[FEN_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (n < 1)
        croak("Data::Fenwick::Shared->new_memfd: n must be >= 1");
    FenHandle *hh = fen_create_memfd(nm, (uint64_t)n, FEN_MODE_POINT, errbuf);
    if (!hh) croak("Data::Fenwick::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_range(class, path = &PL_sv_undef, n = 0, ...)
    const char *class
    SV *path
    UV n
  PREINIT:
    char errbuf[FEN_ERR_BUFLEN];
  CODE:
    if (n < 1) croak("Data::Fenwick::Shared->new_range: n must be >= 1");
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    /* Capture the path PV last: the get-magic on ST(3) above may run code
     * that reallocs/frees the path SV's buffer, dangling an earlier pointer. */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    FenHandle *hh = fen_create(p, (uint64_t)n, FEN_MODE_RANGE, mode, errbuf);
    if (!hh) croak("Data::Fenwick::Shared->new_range: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_range_memfd(class, name = &PL_sv_undef, n = 0)
    const char *class
    SV *name
    UV n
  PREINIT:
    char errbuf[FEN_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;
    if (n < 1) croak("Data::Fenwick::Shared->new_range_memfd: n must be >= 1");
    FenHandle *hh = fen_create_memfd(nm, (uint64_t)n, FEN_MODE_RANGE, errbuf);
    if (!hh) croak("Data::Fenwick::Shared->new_range_memfd: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[FEN_ERR_BUFLEN];
  CODE:
    FenHandle *hh = fen_open_fd(fd, errbuf);
    if (!hh) croak("Data::Fenwick::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Fenwick::Shared")) {
        FenHandle *h = INT2PTR(FenHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); fen_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

# ---- mutation ----

void
update(self, i, delta)
    SV *self
    UV i
    IV delta
  PREINIT:
    EXTRACT(self);
  CODE:
    CHECK_POS(i);
    fen_rwlock_wrlock(h);
    fen_add1_locked(h, (uint64_t)i, (int64_t)delta);   /* point add (range mode: range_add(i,i)) */
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    fen_rwlock_wrunlock(h);

void
range_add(self, l, r, delta)
    SV *self
    UV l
    UV r
    IV delta
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->mode != FEN_MODE_RANGE)
        croak("Data::Fenwick::Shared->range_add: requires a range-mode tree (new_range); a point tree only supports update()");
    if (l < 1 || r > h->hdr->n || l > r)
        croak("Data::Fenwick::Shared->range_add: bad range %" UVuf "..%" UVuf " (valid 1..%" UVuf ")", (UV)l, (UV)r, (UV)h->hdr->n);
    fen_rwlock_wrlock(h);
    fen_range_add_locked(h, (uint64_t)l, (uint64_t)r, (int64_t)delta);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    fen_rwlock_wrunlock(h);

IV
set(self, i, value)
    SV *self
    UV i
    IV value
  PREINIT:
    EXTRACT(self);
    int64_t cur;
  CODE:
    CHECK_POS(i);
    fen_rwlock_wrlock(h);
    cur = fen_rng_locked(h, (uint64_t)i, (uint64_t)i);         /* current value at i */
    fen_add1_locked(h, (uint64_t)i, (int64_t)value - cur);     /* set to the absolute value */
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    fen_rwlock_wrunlock(h);
    RETVAL = (IV)cur;                                          /* return the previous value */
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    fen_rwlock_wrlock(h);
    fen_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    fen_rwlock_wrunlock(h);

# ---- query ----

IV
prefix(self, i)
    SV *self
    UV i
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    if (i > h->hdr->n)
        croak("Data::Fenwick::Shared->prefix: position %" UVuf " out of range 0..%" UVuf, (UV)i, (UV)h->hdr->n);
    fen_rwlock_rdlock(h);
    s = fen_pref_locked(h, (uint64_t)i);
    fen_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

IV
range(self, l, r)
    SV *self
    UV l
    UV r
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    if (l < 1 || r > h->hdr->n || l > r)
        croak("Data::Fenwick::Shared->range: bad range %" UVuf "..%" UVuf " (valid 1..%" UVuf ")", (UV)l, (UV)r, (UV)h->hdr->n);
    fen_rwlock_rdlock(h);
    s = fen_rng_locked(h, (uint64_t)l, (uint64_t)r);
    fen_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

IV
point(self, i)
    SV *self
    UV i
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    CHECK_POS(i);
    fen_rwlock_rdlock(h);
    s = fen_rng_locked(h, (uint64_t)i, (uint64_t)i);
    fen_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

IV
total(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    int64_t s;
  CODE:
    fen_rwlock_rdlock(h);
    s = fen_pref_locked(h, h->hdr->n);
    fen_rwlock_rdunlock(h);
    RETVAL = (IV)s;
  OUTPUT:
    RETVAL

UV
find(self, target)
    SV *self
    IV target
  PREINIT:
    EXTRACT(self);
    uint64_t pos;
  CODE:
    /* smallest position whose prefix sum >= target; n+1 if none. Meaningful when
     * all stored values are non-negative (rank / weighted lookup). */
    if (h->mode == FEN_MODE_RANGE)
        croak("Data::Fenwick::Shared->find: not supported on a range-mode tree (no single-BIT binary lift); use a point tree");
    fen_rwlock_rdlock(h);
    pos = fen_lower_bound_locked(h, (int64_t)target);
    fen_rwlock_rdunlock(h);
    RETVAL = (UV)pos;
  OUTPUT:
    RETVAL

void
merge(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::Fenwick::Shared"))
        croak("Data::Fenwick::Shared->merge: expected a Data::Fenwick::Shared object");
    FenHandle *o = INT2PTR(FenHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::Fenwick::Shared object");
    /* sv_isobject/sv_derived_from above begin with SvGETMAGIC(other), so a
     * tied `other` can have destroyed self before h is used below. `o` was
     * read after that magic and needs no re-read. */
    REEXTRACT(self);

    /* n is immutable after creation -- compare lock-free, croak BEFORE allocating */
    if (h->mode == FEN_MODE_RANGE || o->mode == FEN_MODE_RANGE)
        croak("Data::Fenwick::Shared->merge: not supported for range-mode trees");
    uint64_t on = o->hdr->n;
    if (on != h->hdr->n)
        croak("Data::Fenwick::Shared->merge: size mismatch (n=%" UVuf " vs n=%" UVuf ")",
              (UV)h->hdr->n, (UV)on);

    /* Snapshot the other's tree slots under its read lock into a temp buffer,
     * then release before taking self's write lock (deadlock-free). */
    uint64_t slots = on + 1;
    uint64_t o_slots_max = fen_tree_slots_max(o);     /* Layer B: never read past o's mapping */
    if (slots > o_slots_max) slots = o_slots_max;
    int64_t *tmp;
    Newx(tmp, (size_t)slots, int64_t);
    SAVEFREEPV(tmp);                 /* freed on normal return OR croak unwind */
    fen_rwlock_rdlock(o);
    memcpy(tmp, fen_tree(o), (size_t)slots * sizeof(int64_t));
    fen_rwlock_rdunlock(o);

    fen_rwlock_wrlock(h);
    fen_merge_locked(h, tmp, slots);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    fen_rwlock_wrunlock(h);

# ---- introspection ----

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->n;
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

int
is_range(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (h->mode == FEN_MODE_RANGE) ? 1 : 0;   /* cached mode, no lock */
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t nn, ops, mmap_size;
        int64_t  tot;
        fen_rwlock_rdlock(h);
        nn        = h->hdr->n;
        tot       = fen_pref_locked(h, nn);
        ops       = h->hdr->stat_ops;
        fen_rwlock_rdunlock(h);
        mmap_size = (uint64_t)h->mmap_size;

        HV *hv = newHV();
        hv_stores(hv, "size",      newSVuv((UV)nn));
        hv_stores(hv, "total",     newSViv((IV)tot));
        hv_stores(hv, "ops",       newSVuv((UV)ops));
        hv_stores(hv, "mmap_size", newSVuv((UV)mmap_size));
        hv_stores(hv, "range",     newSViv(h->mode == FEN_MODE_RANGE ? 1 : 0));
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
    if (fen_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Fenwick::Shared")) {
        FenHandle *h = INT2PTR(FenHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
