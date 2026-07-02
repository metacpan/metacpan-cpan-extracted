#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "cms.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::CountMinSketch::Shared")) \
        croak("Expected a Data::CountMinSketch::Shared object"); \
    CmsHandle *h = INT2PTR(CmsHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::CountMinSketch::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::CountMinSketch::Shared  PACKAGE = Data::CountMinSketch::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, epsilon = 0.001, delta = 0.001)
    const char *class
    SV *path
    double epsilon
    double delta
  PREINIT:
    char errbuf[CMS_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    CmsHandle *h = cms_create(p, epsilon, delta, errbuf);   /* validates epsilon/delta into errbuf */
    if (!h) croak("Data::CountMinSketch::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, epsilon = 0.001, delta = 0.001)
    const char *class
    SV *name
    double epsilon
    double delta
  PREINIT:
    char errbuf[CMS_ERR_BUFLEN];
  CODE:
    const char *nm = SvOK(name) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    CmsHandle *h = cms_create_memfd(nm, epsilon, delta, errbuf);   /* validates epsilon/delta into errbuf */
    if (!h) croak("Data::CountMinSketch::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[CMS_ERR_BUFLEN];
  CODE:
    CmsHandle *h = cms_open_fd(fd, errbuf);
    if (!h) croak("Data::CountMinSketch::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::CountMinSketch::Shared")) {
        CmsHandle *h = INT2PTR(CmsHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); cms_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
add(self, item, n = 1)
    SV *self
    SV *item
    UV n
  PREINIT:
    EXTRACT(self);
    STRLEN len;
    const char *s;
    UV total;
  CODE:
    s = SvPVbyte(item, len);               /* may croak (wide char) -- BEFORE the lock */
    cms_rwlock_wrlock(h);
    cms_add_locked(h, s, len, (uint64_t)n);
    total = (UV)h->hdr->total;
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cms_rwlock_wrunlock(h);
    RETVAL = total;
  OUTPUT:
    RETVAL

UV
add_many(self, items)
    SV *self
    SV *items
  PREINIT:
    EXTRACT(self);
    AV *av;
    IV  top;
  CODE:
    if (!SvROK(items) || SvTYPE(SvRV(items)) != SVt_PVAV)
        croak("Data::CountMinSketch::Shared->add_many: expected an array reference");
    av = (AV *)SvRV(items);
    top = av_len(av);                     /* last index, -1 if empty */
    {
        STRLEN cnt = (top >= 0) ? (STRLEN)(top + 1) : 0, i;
        const char **ps = NULL; STRLEN *ls = NULL;
        if (cnt) {                                       /* resolve all bytes BEFORE locking */
            Newx(ps, cnt, const char *); SAVEFREEPV(ps); /* freed on return OR unwind */
            Newx(ls, cnt, STRLEN);       SAVEFREEPV(ls);
            for (i = 0; i < cnt; i++) {                  /* a croak here holds NO lock; SAVEFREEPV cleans up */
                SV **el = av_fetch(av, (SSize_t)i, 0);
                if (el && *el) ps[i] = SvPVbyte(*el, ls[i]);
                else { ps[i] = ""; ls[i] = 0; }
            }
        }
        cms_rwlock_wrlock(h);                            /* locked region: NO croak-capable calls */
        for (i = 0; i < cnt; i++) cms_add_locked(h, ps[i], ls[i], 1);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);  /* a call always counts, even an empty batch */
        cms_rwlock_wrunlock(h);
        RETVAL = (UV)cnt;                                /* every element is added (CMS add never fails) */
    }
  OUTPUT:
    RETVAL

UV
estimate(self, item)
    SV *self
    SV *item
  PREINIT:
    EXTRACT(self);
    STRLEN len;
    const char *s;
    UV est;
  CODE:
    s = SvPVbyte(item, len);               /* may croak (wide char) -- BEFORE the lock */
    cms_rwlock_rdlock(h);
    est = (UV)cms_estimate_locked(h, s, len);
    cms_rwlock_rdunlock(h);
    RETVAL = est;
  OUTPUT:
    RETVAL

void
merge(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::CountMinSketch::Shared"))
        croak("Data::CountMinSketch::Shared->merge: expected a Data::CountMinSketch::Shared object");
    CmsHandle *o = INT2PTR(CmsHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::CountMinSketch::Shared object");

    /* w and d are immutable after creation -- compare lock-free, croak BEFORE
     * allocating, so a mismatch holds no lock and leaks no buffer. */
    uint64_t ow = o->hdr->w;
    uint32_t od = o->hdr->d;
    if (ow != h->hdr->w || od != h->hdr->d)
        croak("Data::CountMinSketch::Shared->merge: geometry mismatch (w=%llu/d=%u vs w=%llu/d=%u)",
              (unsigned long long)h->hdr->w, h->hdr->d,
              (unsigned long long)ow, od);

    /* Snapshot the other's cells (+ its total) under its read lock into a temp
     * buffer, then release before taking self's write lock.  Copying to a temp
     * avoids holding two locks at once (deadlock-free regardless of acquisition
     * order between two processes merging each other). */
    uint64_t cells = (uint64_t)od * ow;
    uint64_t other_total;
    uint64_t *tmp;
    Newx(tmp, (size_t)cells, uint64_t);
    SAVEFREEPV(tmp);                 /* freed on normal return OR croak unwind */
    cms_rwlock_rdlock(o);
    memcpy(tmp, cms_counters(o), (size_t)cells * sizeof(uint64_t));
    other_total = o->hdr->total;
    cms_rwlock_rdunlock(o);

    cms_rwlock_wrlock(h);
    cms_merge_counters(cms_counters(h), tmp, cells);
    if (h->hdr->total > UINT64_MAX - other_total) h->hdr->total = UINT64_MAX;
    else h->hdr->total += other_total;
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cms_rwlock_wrunlock(h);

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    cms_rwlock_wrlock(h);
    cms_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cms_rwlock_wrunlock(h);

UV
total(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV t;
  CODE:
    cms_rwlock_rdlock(h);
    t = (UV)h->hdr->total;
    cms_rwlock_rdunlock(h);
    RETVAL = t;
  OUTPUT:
    RETVAL

UV
width(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->w;
  OUTPUT:
    RETVAL

UV
depth(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->d;
  OUTPUT:
    RETVAL

UV
cells(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)((uint64_t)h->hdr->d * h->hdr->w);
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t w, total, ops, cells;
        uint32_t d;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSVuv can never strand the lock. */
        cms_rwlock_rdlock(h);
        w     = h->hdr->w;
        d     = h->hdr->d;
        total = h->hdr->total;
        ops   = h->hdr->stat_ops;
        cms_rwlock_rdunlock(h);
        cells = (uint64_t)d * w;

        HV *hv = newHV();
        hv_stores(hv, "width",     newSVuv((UV)w));
        hv_stores(hv, "depth",     newSVuv((UV)d));
        hv_stores(hv, "total",     newSVuv((UV)total));
        hv_stores(hv, "cells",     newSVuv((UV)cells));
        hv_stores(hv, "epsilon",   newSVnv(M_E / (double)w));   /* achieved error factor */
        hv_stores(hv, "delta",     newSVnv(exp(-(double)d)));   /* achieved failure prob  */
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
    if (cms_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::CountMinSketch::Shared")) {
        CmsHandle *h = INT2PTR(CmsHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && SvOK(ST(1))) {
        unlink(SvPV_nolen(ST(1)));
    }
