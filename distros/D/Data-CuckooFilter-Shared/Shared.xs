#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "cuckoo.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::CuckooFilter::Shared")) \
        croak("Expected a Data::CuckooFilter::Shared object"); \
    CfHandle *h = INT2PTR(CfHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::CuckooFilter::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::CuckooFilter::Shared  PACKAGE = Data::CuckooFilter::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, capacity = 0)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[CF_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    if (capacity < 1)
        croak("Data::CuckooFilter::Shared->new: capacity must be >= 1");
    CfHandle *h = cf_create(p, (uint64_t)capacity, errbuf);
    if (!h) croak("Data::CuckooFilter::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, capacity = 0)
    const char *class
    SV *name
    UV capacity
  PREINIT:
    char errbuf[CF_ERR_BUFLEN];
  CODE:
    const char *nm = SvOK(name) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (capacity < 1)
        croak("Data::CuckooFilter::Shared->new_memfd: capacity must be >= 1");
    CfHandle *h = cf_create_memfd(nm, (uint64_t)capacity, errbuf);
    if (!h) croak("Data::CuckooFilter::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[CF_ERR_BUFLEN];
  CODE:
    CfHandle *h = cf_open_fd(fd, errbuf);
    if (!h) croak("Data::CuckooFilter::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::CuckooFilter::Shared")) {
        CfHandle *h = INT2PTR(CfHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); cf_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

int
add(self, item)
    SV *self
    SV *item
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
  CODE:
    s = SvPVbyte(item, n);                 /* may croak (wide char) -- BEFORE the lock */
    cf_rwlock_wrlock(h);
    RETVAL = cf_add_locked(h, s, n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cf_rwlock_wrunlock(h);
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
    UV  added = 0;
  CODE:
    if (!SvROK(items) || SvTYPE(SvRV(items)) != SVt_PVAV)
        croak("Data::CuckooFilter::Shared->add_many: expected an array reference");
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
        cf_rwlock_wrlock(h);                             /* locked region: NO croak-capable calls */
        for (i = 0; i < cnt; i++) added += (UV)cf_add_locked(h, ps[i], ls[i]);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);  /* a call always counts, even an empty batch */
        cf_rwlock_wrunlock(h);
    }
    RETVAL = added;
  OUTPUT:
    RETVAL

int
contains(self, item)
    SV *self
    SV *item
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
  CODE:
    s = SvPVbyte(item, n);                 /* may croak (wide char) -- BEFORE the lock */
    cf_rwlock_rdlock(h);
    RETVAL = cf_contains_locked(h, s, n);
    cf_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

int
remove(self, item)
    SV *self
    SV *item
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
  CODE:
    s = SvPVbyte(item, n);                 /* may croak (wide char) -- BEFORE the lock */
    cf_rwlock_wrlock(h);
    RETVAL = cf_remove_locked(h, s, n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cf_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    cf_rwlock_wrlock(h);
    cf_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cf_rwlock_wrunlock(h);

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV n;
  CODE:
    cf_rwlock_rdlock(h);
    n = (UV)h->hdr->count;
    cf_rwlock_rdunlock(h);
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
buckets(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->num_buckets;
  OUTPUT:
    RETVAL

UV
slots(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)(h->hdr->num_buckets * (uint64_t)CF_SLOTS);
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t count, capacity, num_buckets, slots_total, ops, mmap_size;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSVuv can never strand the lock. */
        cf_rwlock_rdlock(h);
        count       = h->hdr->count;
        capacity    = h->hdr->capacity;
        num_buckets = h->hdr->num_buckets;
        ops         = h->hdr->stat_ops;
        cf_rwlock_rdunlock(h);
        slots_total = num_buckets * (uint64_t)CF_SLOTS;
        mmap_size   = (uint64_t)h->mmap_size;

        HV *hv = newHV();
        hv_stores(hv, "capacity",   newSVuv((UV)capacity));
        hv_stores(hv, "buckets",    newSVuv((UV)num_buckets));
        hv_stores(hv, "slots",      newSVuv((UV)slots_total));
        hv_stores(hv, "count",      newSVuv((UV)count));
        hv_stores(hv, "fill_ratio", newSVnv((double)count / (double)slots_total));   /* slots_total >= CF_MIN_BUCKETS*CF_SLOTS, never 0 */
        hv_stores(hv, "ops",        newSVuv((UV)ops));
        hv_stores(hv, "mmap_size",  newSVuv((UV)mmap_size));
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
    if (cf_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::CuckooFilter::Shared")) {
        CfHandle *h = INT2PTR(CfHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && SvOK(ST(1))) {
        unlink(SvPV_nolen(ST(1)));
    }
