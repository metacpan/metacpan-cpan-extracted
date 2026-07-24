#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "cbf.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::CountingBloomFilter::Shared")) \
        croak("Expected a Data::CountingBloomFilter::Shared object"); \
    CbfHandle *h = INT2PTR(CbfHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::CountingBloomFilter::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT's mortal pins
 * the referent only against refcount-driven destruction, not an explicit
 * DESTROY, so the local `h` would dangle.  Used only where magic can actually
 * intervene between EXTRACT and the first use of h. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::CountingBloomFilter::Shared object was replaced during the call"); \
    h = INT2PTR(CbfHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::CountingBloomFilter::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::CountingBloomFilter::Shared  PACKAGE = Data::CountingBloomFilter::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, capacity = 0, fp_rate = 0.01, ...)
    const char *class
    SV *path
    UV capacity
    double fp_rate
  PREINIT:
    char errbuf[CBF_ERR_BUFLEN];
  CODE:
    if (capacity < 1)
        croak("Data::CountingBloomFilter::Shared->new: capacity must be >= 1");
    if (!(fp_rate > 0.0 && fp_rate < 1.0))
        croak("Data::CountingBloomFilter::Shared->new: fp_rate must be between 0 and 1 (exclusive)");
    /* Optional 5th arg: file mode for a newly-created file-backed segment
     * (default 0600, owner-only). Pass e.g. 0660 to opt into cross-user
     * sharing. Ignored for anonymous segments and existing files. */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    /* Capture the path PV LAST, after ST(4) get-magic above: that magic can run
     * arbitrary Perl that reallocs/frees path's PV, dangling the pointer before
     * cbf_create() uses it. */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    CbfHandle *h = cbf_create(p, (uint64_t)capacity, fp_rate, mode, errbuf);
    if (!h) croak("Data::CountingBloomFilter::Shared->new: %s", errbuf);
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
    char errbuf[CBF_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (capacity < 1)
        croak("Data::CountingBloomFilter::Shared->new_memfd: capacity must be >= 1");
    if (!(fp_rate > 0.0 && fp_rate < 1.0))
        croak("Data::CountingBloomFilter::Shared->new_memfd: fp_rate must be between 0 and 1 (exclusive)");
    CbfHandle *h = cbf_create_memfd(nm, (uint64_t)capacity, fp_rate, errbuf);
    if (!h) croak("Data::CountingBloomFilter::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[CBF_ERR_BUFLEN];
  CODE:
    CbfHandle *h = cbf_open_fd(fd, errbuf);
    if (!h) croak("Data::CountingBloomFilter::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::CountingBloomFilter::Shared")) {
        CbfHandle *h = INT2PTR(CbfHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); cbf_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
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
    REEXTRACT(self);
    cbf_rwlock_wrlock(h);
    RETVAL = cbf_add_locked(h, s, n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cbf_rwlock_wrunlock(h);
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
    SvGETMAGIC(items);
    if (!SvROK(items) || SvTYPE(SvRV(items)) != SVt_PVAV)
        croak("Data::CountingBloomFilter::Shared->add_many: expected an array reference");
    av = (AV *)SvRV(items);
    top = av_len(av);                     /* last index, -1 if empty */
    {
        STRLEN cnt = (top >= 0) ? (STRLEN)(top + 1) : 0, i;
        const char **ps = NULL; STRLEN *ls = NULL;
        if (cnt) {                                       /* resolve all bytes BEFORE locking */
            Newx(ps, cnt, const char *); SAVEFREEPV(ps); /* freed on return OR unwind */
            Newx(ls, cnt, STRLEN);       SAVEFREEPV(ls);
            for (i = 0; i < cnt; i++) {                  /* a croak here holds NO lock; SAVEFREEPV + mortals clean up */
                SV **el = av_fetch(av, (SSize_t)i, 0);
                if (el && *el) {
                    STRLEN len;
                    const char *src = SvPVbyte(*el, len); /* may run overload/tie/get-magic = arbitrary Perl */
                    /* Copy the bytes into a private mortal SV NOW.  SvPVbyte on a
                     * LATER element can run Perl that grows/frees THIS element's
                     * PV buffer, dangling `src` before the locked loop hashes it
                     * (heap-use-after-free).  The mortal copy is immune and is
                     * freed on normal return or croak unwind. */
                    SV *copy = sv_2mortal(newSVpvn(src, len));
                    ps[i] = SvPVX_const(copy);
                    ls[i] = len;
                } else { ps[i] = ""; ls[i] = 0; }
            }
        }
        REEXTRACT(self);
        cbf_rwlock_wrlock(h);                             /* locked region: NO croak-capable calls */
        for (i = 0; i < cnt; i++) added += (UV)cbf_add_locked(h, ps[i], ls[i]);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);  /* a call always counts, even an empty batch */
        cbf_rwlock_wrunlock(h);
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
    REEXTRACT(self);
    cbf_rwlock_rdlock(h);
    RETVAL = cbf_contains_locked(h, s, n);
    cbf_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

int
count_of(self, item)
    SV *self
    SV *item
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
  CODE:
    s = SvPVbyte(item, n);                 /* may croak (wide char) -- BEFORE the lock */
    REEXTRACT(self);
    cbf_rwlock_rdlock(h);
    RETVAL = cbf_count_of_locked(h, s, n);
    cbf_rwlock_rdunlock(h);
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
    REEXTRACT(self);
    cbf_rwlock_wrlock(h);
    RETVAL = cbf_remove_locked(h, s, n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cbf_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

void
merge(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::CountingBloomFilter::Shared"))
        croak("Data::CountingBloomFilter::Shared->merge: expected a Data::CountingBloomFilter::Shared object");
    CbfHandle *o = INT2PTR(CbfHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::CountingBloomFilter::Shared object");
    /* sv_isobject/sv_derived_from above begin with SvGETMAGIC(other), so a
     * tied `other` can have destroyed self before h is used below. `o` was
     * read after that magic and needs no re-read. */
    REEXTRACT(self);

    /* m_ctr and k are immutable after creation -- compare lock-free, croak
     * BEFORE allocating, so a mismatch holds no lock and leaks no buffer. */
    uint64_t om = o->hdr->m_ctr;
    uint32_t ok = o->hdr->k;
    if (om != h->hdr->m_ctr || ok != h->hdr->k)
        croak("Data::CountingBloomFilter::Shared->merge: geometry mismatch (%llu counters/k=%u vs %llu counters/k=%u)",
              (unsigned long long)h->hdr->m_ctr, h->hdr->k,
              (unsigned long long)om, ok);

    /* Snapshot the other's counter bytes under its read lock into a temp buffer,
     * then release before taking self's write lock.  Copying to a temp avoids
     * holding two locks at once (deadlock-free regardless of acquisition order
     * between two processes merging each other). */
    uint64_t bytes = om / 2;
    /* Layer B: never read past o's real mapping when snapshotting -- o->hdr->m_ctr
     * is in the shared segment and a peer could widen it after validation.
     * Equals m_ctr/2 for a valid filter, so no behavior change. */
    uint64_t o_bytes_max = cbf_ctr_bytes_max(o);
    if (bytes > o_bytes_max) bytes = o_bytes_max;
    uint8_t *tmp;
    Newx(tmp, (size_t)bytes, uint8_t);
    SAVEFREEPV(tmp);                 /* freed on normal return OR croak unwind */
    cbf_rwlock_rdlock(o);
    memcpy(tmp, cbf_counters(o), (size_t)bytes);
    cbf_rwlock_rdunlock(o);

    cbf_rwlock_wrlock(h);
    cbf_merge_counters(h, tmp, bytes);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cbf_rwlock_wrunlock(h);

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    cbf_rwlock_wrlock(h);
    cbf_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    cbf_rwlock_wrunlock(h);

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
counters(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->m_ctr;
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
    cbf_rwlock_rdlock(h);
    n = (UV)cbf_count_locked(h);
    cbf_rwlock_rdunlock(h);
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
        uint64_t X, m_ctr, capacity, ops, n_est;
        uint32_t k;
        double   fp_rate;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSVuv can never strand the lock. */
        cbf_rwlock_rdlock(h);
        X        = cbf_nonzero_count_locked(h);
        n_est    = cbf_count_from_nonzero(h, X);   /* reuse X -- no second scan */
        m_ctr   = h->hdr->m_ctr;
        k        = h->hdr->k;
        capacity = h->hdr->capacity;
        fp_rate  = h->hdr->fp_rate;
        ops      = h->hdr->stat_ops;
        cbf_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "capacity",   newSVuv((UV)capacity));
        hv_stores(hv, "fp_rate",    newSVnv(fp_rate));
        hv_stores(hv, "counters",     newSVuv((UV)m_ctr));
        hv_stores(hv, "hashes",       newSVuv(k));
        hv_stores(hv, "counters_set", newSVuv((UV)X));
        hv_stores(hv, "count",      newSVuv((UV)n_est));
        hv_stores(hv, "fill_ratio", newSVnv((double)X / (double)m_ctr));
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
    if (cbf_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::CountingBloomFilter::Shared")) {
        CbfHandle *h = INT2PTR(CbfHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
