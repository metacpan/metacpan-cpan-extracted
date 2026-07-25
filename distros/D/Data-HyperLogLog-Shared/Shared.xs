#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "hll.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::HyperLogLog::Shared")) \
        croak("Expected a Data::HyperLogLog::Shared object"); \
    HllHandle *h = INT2PTR(HllHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::HyperLogLog::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT's mortal
 * pins the referent only against refcount-driven destruction, not an
 * explicit DESTROY, so the local `h` would dangle.  Used only where magic
 * can actually intervene between EXTRACT and the first use of h. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::HyperLogLog::Shared object was replaced during the call"); \
    h = INT2PTR(HllHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::HyperLogLog::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::HyperLogLog::Shared  PACKAGE = Data::HyperLogLog::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, precision = 14, ...)
    const char *class
    SV *path
    UV precision
  PREINIT:
    char errbuf[HLL_ERR_BUFLEN];
  CODE:
    /* optional 4th arg = file mode for the exclusive create of a NEW backing
       file (opt-in cross-user sharing); default 0600 (owner-only).  Ignored
       for anonymous/undef path and when attaching an existing file. */
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    if (precision < HLL_MIN_PRECISION || precision > HLL_MAX_PRECISION)
        croak("Data::HyperLogLog::Shared->new: precision must be between %d and %d",
              HLL_MIN_PRECISION, HLL_MAX_PRECISION);
    /* capture the path PV LAST: the get-magic on ST(3) above can run
       arbitrary Perl code that reallocs/frees path's PV, dangling p */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    HllHandle *h = hll_create(p, (uint32_t)precision, mode, errbuf);
    if (!h) croak("Data::HyperLogLog::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, precision = 14)
    const char *class
    SV *name
    UV precision
  PREINIT:
    char errbuf[HLL_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (precision < HLL_MIN_PRECISION || precision > HLL_MAX_PRECISION)
        croak("Data::HyperLogLog::Shared->new_memfd: precision must be between %d and %d",
              HLL_MIN_PRECISION, HLL_MAX_PRECISION);
    HllHandle *h = hll_create_memfd(nm, (uint32_t)precision, errbuf);
    if (!h) croak("Data::HyperLogLog::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[HLL_ERR_BUFLEN];
  CODE:
    HllHandle *h = hll_open_fd(fd, errbuf);
    if (!h) croak("Data::HyperLogLog::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::HyperLogLog::Shared")) {
        HllHandle *h = INT2PTR(HllHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); hll_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
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
    s = SvPVbyte(item, n);
    REEXTRACT(self);
    hll_rwlock_wrlock(h);
    RETVAL = hll_add_locked(h, s, n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    hll_rwlock_wrunlock(h);
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
        croak("Data::HyperLogLog::Shared->add_many: expected an array reference");
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
                if (el && *el) {
                    STRLEN len;
                    const char *src = SvPVbyte(*el, len); /* may run overload/tie/get-magic = arbitrary Perl */
                    /* Copy bytes into a private mortal SV NOW: a LATER element SvPVbyte can
                     * grow/free THIS element PV, dangling src before the locked loop uses it. */
                    SV *copy = sv_2mortal(newSVpvn(src, len));
                    ps[i] = SvPVX_const(copy);
                    ls[i] = len;
                } else { ps[i] = ""; ls[i] = 0; }
            }
        }
        REEXTRACT(self);
        hll_rwlock_wrlock(h);                            /* locked region: NO croak-capable calls */
        for (i = 0; i < cnt; i++) added += (UV)hll_add_locked(h, ps[i], ls[i]);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);  /* a call always counts, even an empty batch */
        hll_rwlock_wrunlock(h);
    }
    RETVAL = added;
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    double E;
  CODE:
    hll_rwlock_rdlock(h);
    E = hll_count_locked(h);
    hll_rwlock_rdunlock(h);
    RETVAL = (UV)(E + 0.5);
  OUTPUT:
    RETVAL

void
merge(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::HyperLogLog::Shared"))
        croak("Data::HyperLogLog::Shared->merge: expected a Data::HyperLogLog::Shared object");
    HllHandle *o = INT2PTR(HllHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::HyperLogLog::Shared object");
    /* sv_isobject/sv_derived_from above begin with SvGETMAGIC(other), so a
     * tied `other` can have destroyed self before h is used below. `o` was
     * read after that magic and needs no re-read. */
    REEXTRACT(self);

    /* Snapshot the other's registers under its read lock into a temp
     * buffer, then release before taking self's write lock.  Copying to
     * a temp avoids holding two locks at once (deadlock-free regardless
     * of acquisition order between two processes merging each other). */
    uint32_t dm = 0;
    if (!hll_regs_checked(h, &dm, NULL))   /* validate self + bound the scratch size */
        croak("Data::HyperLogLog::Shared->merge: invalid destination header");
    uint32_t om = o->hdr->m;               /* m is immutable after creation -- compare lock-free */
    if (om != dm)
        croak("Data::HyperLogLog::Shared->merge: precision mismatch (%u vs %u registers)",
              dm, om);

    uint8_t *tmp;
    Newxz(tmp, (size_t)dm, uint8_t);       /* dm bounded to 2^HLL_MAX_PRECISION by the check above */
    SAVEFREEPV(tmp);                       /* freed on normal return OR croak unwind */
    uint32_t copied = 0;
    hll_rwlock_rdlock(o);
    {
        uint32_t sm = 0;
        uint8_t *src = hll_regs_checked(o, &sm, NULL);  /* bound the memcpy against o's mapping */
        if (src) {
            uint32_t n = (sm < dm) ? sm : dm;           /* never overflow tmp (dm bytes) */
            memcpy(tmp, src, (size_t)n);
            copied = n;
        }
    }
    hll_rwlock_rdunlock(o);

    hll_rwlock_wrlock(h);
    hll_merge_regs(h, tmp, copied);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    hll_rwlock_wrunlock(h);

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    hll_rwlock_wrlock(h);
    hll_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    hll_rwlock_wrunlock(h);

UV
precision(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->precision;
  OUTPUT:
    RETVAL

UV
registers(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->m;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        double   E;
        uint64_t ops;
        uint32_t precision, m;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSVuv can never strand the lock. */
        hll_rwlock_rdlock(h);
        E         = hll_count_locked(h);
        ops       = h->hdr->stat_ops;
        precision = h->hdr->precision;
        m         = h->hdr->m;
        hll_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "precision",  newSVuv(precision));
        hv_stores(hv, "registers",  newSVuv(m));
        hv_stores(hv, "count",      newSVuv((UV)(E + 0.5)));
        hv_stores(hv, "ops",        newSVuv(ops));
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
    if (hll_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::HyperLogLog::Shared")) {
        HllHandle *h = INT2PTR(HllHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
