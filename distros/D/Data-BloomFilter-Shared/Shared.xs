#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "bloom.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::BloomFilter::Shared")) \
        croak("Expected a Data::BloomFilter::Shared object"); \
    BfHandle *h = INT2PTR(BfHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::BloomFilter::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::BloomFilter::Shared  PACKAGE = Data::BloomFilter::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, capacity = 0, fp_rate = 0.01)
    const char *class
    SV *path
    UV capacity
    double fp_rate
  PREINIT:
    char errbuf[BF_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    if (capacity < 1)
        croak("Data::BloomFilter::Shared->new: capacity must be >= 1");
    if (!(fp_rate > 0.0 && fp_rate < 1.0))
        croak("Data::BloomFilter::Shared->new: fp_rate must be between 0 and 1 (exclusive)");
    BfHandle *h = bf_create(p, (uint64_t)capacity, fp_rate, errbuf);
    if (!h) croak("Data::BloomFilter::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, capacity = 0, fp_rate = 0.01)
    const char *class
    SV *name
    UV capacity
    double fp_rate
  PREINIT:
    char errbuf[BF_ERR_BUFLEN];
  CODE:
    const char *nm = SvOK(name) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (capacity < 1)
        croak("Data::BloomFilter::Shared->new_memfd: capacity must be >= 1");
    if (!(fp_rate > 0.0 && fp_rate < 1.0))
        croak("Data::BloomFilter::Shared->new_memfd: fp_rate must be between 0 and 1 (exclusive)");
    BfHandle *h = bf_create_memfd(nm, (uint64_t)capacity, fp_rate, errbuf);
    if (!h) croak("Data::BloomFilter::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[BF_ERR_BUFLEN];
  CODE:
    BfHandle *h = bf_open_fd(fd, errbuf);
    if (!h) croak("Data::BloomFilter::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::BloomFilter::Shared")) {
        BfHandle *h = INT2PTR(BfHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); bf_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
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
    bf_rwlock_wrlock(h);
    RETVAL = bf_add_locked(h, s, n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    bf_rwlock_wrunlock(h);
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
        croak("Data::BloomFilter::Shared->add_many: expected an array reference");
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
        bf_rwlock_wrlock(h);                             /* locked region: NO croak-capable calls */
        for (i = 0; i < cnt; i++) added += (UV)bf_add_locked(h, ps[i], ls[i]);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);  /* a call always counts, even an empty batch */
        bf_rwlock_wrunlock(h);
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
    bf_rwlock_rdlock(h);
    RETVAL = bf_contains_locked(h, s, n);
    bf_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

void
merge(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::BloomFilter::Shared"))
        croak("Data::BloomFilter::Shared->merge: expected a Data::BloomFilter::Shared object");
    BfHandle *o = INT2PTR(BfHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::BloomFilter::Shared object");

    /* m_bits and k are immutable after creation -- compare lock-free, croak
     * BEFORE allocating, so a mismatch holds no lock and leaks no buffer. */
    uint64_t om = o->hdr->m_bits;
    uint32_t ok = o->hdr->k;
    if (om != h->hdr->m_bits || ok != h->hdr->k)
        croak("Data::BloomFilter::Shared->merge: geometry mismatch (%llu bits/k=%u vs %llu bits/k=%u)",
              (unsigned long long)h->hdr->m_bits, h->hdr->k,
              (unsigned long long)om, ok);

    /* Snapshot the other's words under its read lock into a temp buffer, then
     * release before taking self's write lock.  Copying to a temp avoids
     * holding two locks at once (deadlock-free regardless of acquisition
     * order between two processes merging each other). */
    uint64_t words = om / 64;
    uint64_t *tmp;
    Newx(tmp, (size_t)words, uint64_t);
    SAVEFREEPV(tmp);                 /* freed on normal return OR croak unwind */
    bf_rwlock_rdlock(o);
    memcpy(tmp, bf_bits(o), (size_t)words * sizeof(uint64_t));
    bf_rwlock_rdunlock(o);

    bf_rwlock_wrlock(h);
    bf_merge_words(h, tmp);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    bf_rwlock_wrunlock(h);

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    bf_rwlock_wrlock(h);
    bf_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    bf_rwlock_wrunlock(h);

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
bits(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->m_bits;
  OUTPUT:
    RETVAL

UV
hashes(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->k;
  OUTPUT:
    RETVAL

double
fp_rate(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->fp_rate;
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV n;
  CODE:
    bf_rwlock_rdlock(h);
    n = (UV)bf_count_locked(h);
    bf_rwlock_rdunlock(h);
    RETVAL = n;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t X, m_bits, capacity, ops, n_est;
        uint32_t k;
        double   fp_rate;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSVuv can never strand the lock. */
        bf_rwlock_rdlock(h);
        X        = bf_popcount_locked(h);
        n_est    = bf_count_from_popcount(h, X);   /* reuse X -- no second scan */
        m_bits   = h->hdr->m_bits;
        k        = h->hdr->k;
        capacity = h->hdr->capacity;
        fp_rate  = h->hdr->fp_rate;
        ops      = h->hdr->stat_ops;
        bf_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "capacity",   newSVuv((UV)capacity));
        hv_stores(hv, "fp_rate",    newSVnv(fp_rate));
        hv_stores(hv, "bits",       newSVuv((UV)m_bits));
        hv_stores(hv, "hashes",     newSVuv(k));
        hv_stores(hv, "bits_set",   newSVuv((UV)X));
        hv_stores(hv, "count",      newSVuv((UV)n_est));
        hv_stores(hv, "fill_ratio", newSVnv((double)X / (double)m_bits));
        hv_stores(hv, "ops",        newSVuv((UV)ops));
        hv_stores(hv, "mmap_size",  newSVuv((UV)h->mmap_size));
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
    if (bf_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::BloomFilter::Shared")) {
        BfHandle *h = INT2PTR(BfHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && SvOK(ST(1))) {
        unlink(SvPV_nolen(ST(1)));
    }
