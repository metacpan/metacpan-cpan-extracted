#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "dsu.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::DisjointSet::Shared")) \
        croak("Expected a Data::DisjointSet::Shared object"); \
    DsuHandle *h = INT2PTR(DsuHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::DisjointSet::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::DisjointSet::Shared  PACKAGE = Data::DisjointSet::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, n = 0)
    const char *class
    SV *path
    UV n
  PREINIT:
    char errbuf[DSU_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    DsuHandle *h = dsu_create(p, (uint64_t)n, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::DisjointSet::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, n = 0)
    const char *class
    SV *name
    UV n
  PREINIT:
    char errbuf[DSU_ERR_BUFLEN];
  CODE:
    const char *nm = SvOK(name) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    DsuHandle *h = dsu_create_memfd(nm, (uint64_t)n, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::DisjointSet::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[DSU_ERR_BUFLEN];
  CODE:
    DsuHandle *h = dsu_open_fd(fd, errbuf);
    if (!h) croak("Data::DisjointSet::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::DisjointSet::Shared")) {
        DsuHandle *h = INT2PTR(DsuHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); dsu_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
find(self, x)
    SV *self
    UV x
  PREINIT:
    EXTRACT(self);
  CODE:
    /* Range-check BEFORE locking so a croak holds no lock. */
    if (x >= h->hdr->n)
        croak("Data::DisjointSet::Shared->find: index %" UVuf " out of range (n=%u)",
              x, h->hdr->n);
    /* find performs path compression -> it MUTATES -> take the write lock. */
    dsu_rwlock_wrlock(h);
    RETVAL = (UV)dsu_find(h, (uint32_t)x);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    dsu_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

IV
union(self, a, b)
    SV *self
    UV a
    UV b
  PREINIT:
    EXTRACT(self);
  CODE:
    if (a >= h->hdr->n)
        croak("Data::DisjointSet::Shared->union: index %" UVuf " out of range (n=%u)",
              a, h->hdr->n);
    if (b >= h->hdr->n)
        croak("Data::DisjointSet::Shared->union: index %" UVuf " out of range (n=%u)",
              b, h->hdr->n);
    dsu_rwlock_wrlock(h);
    RETVAL = (IV)dsu_union_locked(h, (uint32_t)a, (uint32_t)b);   /* 1 = newly merged, 0 = already together */
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    dsu_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

bool
connected(self, a, b)
    SV *self
    UV a
    UV b
  PREINIT:
    EXTRACT(self);
  CODE:
    if (a >= h->hdr->n)
        croak("Data::DisjointSet::Shared->connected: index %" UVuf " out of range (n=%u)",
              a, h->hdr->n);
    if (b >= h->hdr->n)
        croak("Data::DisjointSet::Shared->connected: index %" UVuf " out of range (n=%u)",
              b, h->hdr->n);
    /* connected compresses paths via dsu_find -> it MUTATES -> write lock. */
    dsu_rwlock_wrlock(h);
    RETVAL = dsu_connected_locked(h, (uint32_t)a, (uint32_t)b);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    dsu_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

UV
union_many(self, pairs)
    SV *self
    SV *pairs
  PREINIT:
    EXTRACT(self);
    AV *av;
    IV  top;
  CODE:
    if (!SvROK(pairs) || SvTYPE(SvRV(pairs)) != SVt_PVAV)
        croak("Data::DisjointSet::Shared->union_many: expected an array reference");
    av = (AV *)SvRV(pairs);
    top = av_len(av);                     /* last index, -1 if empty */
    {
        STRLEN cnt = (top >= 0) ? (STRLEN)(top + 1) : 0, i;
        STRLEN npairs;
        uint32_t *vals = NULL;
        UV merged = 0;
        uint32_t n = h->hdr->n;
        if (cnt & 1)
            croak("Data::DisjointSet::Shared->union_many: expected an even number of elements (flat [a0,b0,a1,b1,...]), got %" UVuf,
                  (UV)cnt);
        npairs = cnt / 2;
        if (cnt) {                                       /* resolve + range-check ALL before locking */
            Newx(vals, cnt, uint32_t); SAVEFREEPV(vals); /* freed on return OR unwind */
            for (i = 0; i < cnt; i++) {                  /* a croak here holds NO lock; SAVEFREEPV cleans up */
                SV **el = av_fetch(av, (SSize_t)i, 0);
                UV v = (el && *el) ? SvUV(*el) : 0;
                if (v >= n)
                    croak("Data::DisjointSet::Shared->union_many: index %" UVuf " out of range (n=%u)",
                          v, n);
                vals[i] = (uint32_t)v;
            }
        }
        dsu_rwlock_wrlock(h);                            /* locked region: NO croak-capable calls */
        for (i = 0; i < npairs; i++)
            merged += (UV)dsu_union_locked(h, vals[2*i], vals[2*i + 1]);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);  /* a call always counts, even an empty batch */
        dsu_rwlock_wrunlock(h);
        RETVAL = merged;
    }
  OUTPUT:
    RETVAL

UV
set_size(self, x)
    SV *self
    UV x
  PREINIT:
    EXTRACT(self);
  CODE:
    if (x >= h->hdr->n)
        croak("Data::DisjointSet::Shared->set_size: index %" UVuf " out of range (n=%u)",
              x, h->hdr->n);
    /* set_size compresses paths via dsu_find -> it MUTATES -> write lock. */
    dsu_rwlock_wrlock(h);
    RETVAL = (UV)dsu_set_size_locked(h, (uint32_t)x);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    dsu_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

UV
num_sets(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    dsu_rwlock_rdlock(h);
    RETVAL = (UV)h->hdr->num_sets;
    dsu_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->n;   /* immutable after creation -- lock-free */
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    dsu_rwlock_wrlock(h);
    dsu_reset_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    dsu_rwlock_wrunlock(h);

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint32_t n, num_sets;
        uint64_t ops;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSV* can never strand the lock. */
        dsu_rwlock_rdlock(h);
        n        = h->hdr->n;
        num_sets = h->hdr->num_sets;
        ops      = h->hdr->stat_ops;
        dsu_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "capacity",  newSVuv((UV)n));
        hv_stores(hv, "sets",      newSVuv((UV)num_sets));
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
    if (dsu_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::DisjointSet::Shared")) {
        DsuHandle *h = INT2PTR(DsuHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && SvOK(ST(1))) {
        unlink(SvPV_nolen(ST(1)));
    }
