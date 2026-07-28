#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "reservoir.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Reservoir::Shared")) \
        croak("Expected a Data::Reservoir::Shared object"); \
    RsvHandle *h = INT2PTR(RsvHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Reservoir::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* The pin above only blocks REFCOUNT-driven destruction. Perl run from argument
 * magic can still call $obj->DESTROY explicitly, which frees the handle and
 * zeroes the IV, leaving the local `h` dangling. Re-read it wherever such magic
 * can intervene before `h` is used: SvGETMAGIC on an argument, av_len on a TIED
 * array (AvFILL -> mg_size -> FETCHSIZE), and element fetches.
 * The same Perl can also REPLACE the invocant ($obj = 42 mutates ST(0), because
 * Perl passes aliases), hence the SvROK re-check before SvRV. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::Reservoir::Shared object was replaced during the call"); \
    h = INT2PTR(RsvHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::Reservoir::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Reservoir::Shared  PACKAGE = Data::Reservoir::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, ...)
    const char *class
    SV *path
  PREINIT:
    char errbuf[RSV_ERR_BUFLEN];
  CODE:
    /* k / item_size read here (not as typemap params) so an explicit undef falls
     * through to the default instead of warning "uninitialized value". */
    UV k = (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) ? SvUV(ST(2)) : 0;
    UV item_size = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? SvUV(ST(3)) : 256;
    if (k < 1) croak("Data::Reservoir::Shared->new: reservoir size (k) must be >= 1");
    /* Optional 5th arg: file mode for a newly-created file-backed segment.
     * Resolve its magic (tied/overloaded) BEFORE capturing path's PV: a FETCH
     * here could realloc/free path's buffer, dangling p before rsv_create. */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    RsvHandle *hh = rsv_create(p, (uint64_t)k, (uint64_t)item_size, RSV_MODE_UNIFORM, mode, errbuf);
    if (!hh) croak("Data::Reservoir::Shared->new: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, ...)
    const char *class
    SV *name
  PREINIT:
    char errbuf[RSV_ERR_BUFLEN];
  CODE:
    /* k / item_size read here (not as typemap params) so an explicit undef falls
     * through to the default instead of warning "uninitialized value". */
    UV k = (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) ? SvUV(ST(2)) : 0;
    UV item_size = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? SvUV(ST(3)) : 256;
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;
    if (k < 1) croak("Data::Reservoir::Shared->new_memfd: reservoir size (k) must be >= 1");
    RsvHandle *hh = rsv_create_memfd(nm, (uint64_t)k, (uint64_t)item_size, RSV_MODE_UNIFORM, errbuf);
    if (!hh) croak("Data::Reservoir::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_weighted(class, path = &PL_sv_undef, ...)
    const char *class
    SV *path
  PREINIT:
    char errbuf[RSV_ERR_BUFLEN];
  CODE:
    /* k / item_size read here (not as typemap params) so an explicit undef falls
     * through to the default instead of warning "uninitialized value". */
    UV k = (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) ? SvUV(ST(2)) : 0;
    UV item_size = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? SvUV(ST(3)) : 256;
    if (k < 1) croak("Data::Reservoir::Shared->new_weighted: reservoir size (k) must be >= 1");
    /* Optional 5th arg: file mode for a newly-created file-backed segment.
     * Resolve its magic (tied/overloaded) BEFORE capturing path's PV: a FETCH
     * here could realloc/free path's buffer, dangling p before rsv_create. */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    RsvHandle *hh = rsv_create(p, (uint64_t)k, (uint64_t)item_size, RSV_MODE_WEIGHTED, mode, errbuf);
    if (!hh) croak("Data::Reservoir::Shared->new_weighted: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_weighted_memfd(class, name = &PL_sv_undef, ...)
    const char *class
    SV *name
  PREINIT:
    char errbuf[RSV_ERR_BUFLEN];
  CODE:
    /* k / item_size read here (not as typemap params) so an explicit undef falls
     * through to the default instead of warning "uninitialized value". */
    UV k = (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) ? SvUV(ST(2)) : 0;
    UV item_size = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? SvUV(ST(3)) : 256;
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;
    if (k < 1) croak("Data::Reservoir::Shared->new_weighted_memfd: reservoir size (k) must be >= 1");
    RsvHandle *hh = rsv_create_memfd(nm, (uint64_t)k, (uint64_t)item_size, RSV_MODE_WEIGHTED, errbuf);
    if (!hh) croak("Data::Reservoir::Shared->new_weighted_memfd: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[RSV_ERR_BUFLEN];
  CODE:
    RsvHandle *hh = rsv_open_fd(fd, errbuf);
    if (!hh) croak("Data::Reservoir::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, hh);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Reservoir::Shared")) {
        RsvHandle *h = INT2PTR(RsvHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); rsv_destroy(h); }
    }

int
add(self, item, weight = &PL_sv_undef)
    SV *self
    SV *item
    SV *weight
  PREINIT:
    EXTRACT(self);
    STRLEN n;
    const char *s;
    double w = 0;
  CODE:
    if (h->mode == RSV_MODE_WEIGHTED) {
        /* Resolve + validate the weight BEFORE capturing the item PV. SvNV(weight)
         * can run the weight's numeric overload/tie = arbitrary Perl that may
         * realloc or free the item SV, dangling a PV captured earlier. Do all the
         * weight magic first, THEN grab the item bytes so nothing runs between the
         * SvPVbyte and its use. (Also keeps any croak out from under the lock.) */
        if (!(SvGETMAGIC(weight), SvOK(weight)))
            croak("Data::Reservoir::Shared: weighted add(item, weight) requires a weight");
        w = SvNV(weight);
        if (!(w > 0.0) || !isfinite(w))
            croak("Data::Reservoir::Shared: weight must be a finite number > 0");
    }
    s = SvPVbyte(item, n);                 /* may croak (wide char) -- BEFORE the lock, AFTER weight magic */
    /* SvNV(weight) above and SvPVbyte(item) just now both run magic = arbitrary
     * Perl that can have destroyed self -- re-check before the first use of h. */
    REEXTRACT(self);
    rsv_rwlock_wrlock(h);
    RETVAL = (h->mode == RSV_MODE_WEIGHTED)
        ? rsv_add_weighted_locked(h, s, (uint64_t)n, w)
        : rsv_add_locked(h, s, (uint64_t)n);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rsv_rwlock_wrunlock(h);
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
    UV  stored = 0;
  CODE:
    SvGETMAGIC(items);
    if (!SvROK(items) || SvTYPE(SvRV(items)) != SVt_PVAV)
        croak("Data::Reservoir::Shared->add_many: expected an array reference");
    av = (AV *)SvRV(items);
    /* Pin the array for the whole loop: an element's magic can drop the caller's
     * last reference (undef $aref), freeing av and dangling later av_fetch calls. */
    SvREFCNT_inc((SV *)av); sv_2mortal((SV *)av);
    top = av_len(av);
    /* SvGETMAGIC(items) above, and av_len on a tied array, both run Perl that
     * can have destroyed self -- re-check before the first use of h below. */
    REEXTRACT(self);
    {
        STRLEN cnt = (top >= 0) ? (STRLEN)(top + 1) : 0, i;
        const char **ps = NULL; STRLEN *ls = NULL; double *ws = NULL;
        int weighted = (h->mode == RSV_MODE_WEIGHTED);
        if (cnt) {
            Newx(ps, cnt, const char *); SAVEFREEPV(ps);
            Newx(ls, cnt, STRLEN);       SAVEFREEPV(ls);
            if (weighted) { Newx(ws, cnt, double); SAVEFREEPV(ws); }
            for (i = 0; i < cnt; i++) {
                SV **el = av_fetch(av, (SSize_t)i, 0);
                if (weighted) {
                    /* weighted mode: each element is a [item, weight] pair,
                     * validated here (before the lock; no croak while locked) */
                    if (el && *el) SvGETMAGIC(*el);   /* a tied-array element is a deferred-magic PVLV */
                    if (!el || !*el || !SvROK(*el) || SvTYPE(SvRV(*el)) != SVt_PVAV)
                        croak("Data::Reservoir::Shared->add_many: weighted reservoir expects [item, weight] pairs");
                    AV *pair = (AV *)SvRV(*el);
                    SV **iv = av_fetch(pair, 0, 0);
                    SV **wv = av_fetch(pair, 1, 0);
                    if (!iv || !*iv || !wv || !*wv)
                        croak("Data::Reservoir::Shared->add_many: each element must be [item, weight]");
                    /* Pin both element SVs by value BEFORE any magic runs: the item's
                     * SvPVbyte (or the weight's get-magic) can free or reassign the
                     * pair AV, dangling the other's raw SV** slot. The mortal INC
                     * keeps both alive for this branch even if the pair AV is freed. */
                    SV *isv = *iv, *wsv = *wv;
                    SvREFCNT_inc(isv); sv_2mortal(isv);
                    SvREFCNT_inc(wsv); sv_2mortal(wsv);
                    {
                        STRLEN len;
                        const char *src = SvPVbyte(isv, len); /* may run overload/tie/get-magic = arbitrary Perl */
                        /* Copy bytes into a private mortal SV NOW: a LATER element SvPVbyte can
                         * grow/free THIS element PV, dangling src before the locked loop uses it. */
                        SV *copy = sv_2mortal(newSVpvn(src, len));
                        ps[i] = SvPVX_const(copy);
                        ls[i] = len;
                    }
                    SvGETMAGIC(wsv);
                    { double w = SvOK(wsv) ? SvNV(wsv) : 0.0;  /* undef -> 0 -> clean croak below, no warning */
                      if (!(w > 0.0) || !isfinite(w))
                          croak("Data::Reservoir::Shared->add_many: weight must be a finite number > 0");
                      ws[i] = w; }
                } else if (el && *el) {
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
        /* Element get-magic in the resolve loop above (SvPVbyte / SvGETMAGIC on
         * the weight) can also have destroyed self. Outside the `if (cnt)`
         * block: an empty or tied size-0 array skips the loop but still
         * reaches this lock. */
        REEXTRACT(self);
        rsv_rwlock_wrlock(h);
        if (weighted)
            for (i = 0; i < cnt; i++) stored += (UV)rsv_add_weighted_locked(h, ps[i], (uint64_t)ls[i], ws[i]);
        else
            for (i = 0; i < cnt; i++) stored += (UV)rsv_add_locked(h, ps[i], (uint64_t)ls[i]);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        rsv_rwlock_wrunlock(h);
    }
    RETVAL = stored;
  OUTPUT:
    RETVAL

# ---- reading the sample ----

SV *
get(self, i)
    SV *self
    UV i
  PREINIT:
    EXTRACT(self);
    const uint8_t *ptr; uint64_t len; int ok;
    uint8_t *tmp = NULL;
  CODE:
    /* copy the item out under the read lock, then build the SV (no croak-capable
     * Perl allocation while the lock is held) */
    Newx(tmp, (size_t)h->item_size, uint8_t); SAVEFREEPV(tmp);   /* cached: matches rsv_get_locked's clamp */
    rsv_rwlock_rdlock(h);
    ok = rsv_get_locked(h, (uint64_t)i, &ptr, &len);
    if (ok) memcpy(tmp, ptr, (size_t)len);
    rsv_rwlock_rdunlock(h);
    RETVAL = ok ? newSVpvn((char *)tmp, (STRLEN)len) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sample(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        uint64_t k = h->k, isz = h->stride, cnt, i;   /* cached geometry: alloc + copy agree */
        uint8_t *buf;
        /* worst-case snapshot buffer (k slots) allocated BEFORE the lock */
        Newx(buf, (size_t)(k * isz), uint8_t); SAVEFREEPV(buf);
        rsv_rwlock_rdlock(h);
        cnt = rsv_count_locked(h);
        {
            uint64_t smax = rsv_slots_max(h);
            if (cnt > smax) cnt = smax;
            memcpy(buf, rsv_slots(h), (size_t)(cnt * isz));   /* snapshot filled slots */
        }
        rsv_rwlock_rdunlock(h);
        EXTEND(SP, (SSize_t)cnt);
        for (i = 0; i < cnt; i++) {
            uint8_t *slot = buf + i * isz;
            uint64_t len; memcpy(&len, slot, sizeof(uint64_t));
            if (len > h->item_size) len = h->item_size;   /* cached clamp */
            PUSHs(sv_2mortal(newSVpvn((char *)(slot + 8), (STRLEN)len)));
        }
    }

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV c;
  CODE:
    rsv_rwlock_rdlock(h);
    c = (UV)rsv_count_locked(h);
    rsv_rwlock_rdunlock(h);
    RETVAL = c;
  OUTPUT:
    RETVAL

UV
seen(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV s;
  CODE:
    rsv_rwlock_rdlock(h);
    s = (UV)h->hdr->seen;
    rsv_rwlock_rdunlock(h);
    RETVAL = s;
  OUTPUT:
    RETVAL

# ---- mutation / introspection ----

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    rsv_rwlock_wrlock(h);
    rsv_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rsv_rwlock_wrunlock(h);

void
seed(self, s)
    SV *self
    UV s
  PREINIT:
    EXTRACT(self);
  CODE:
    /* set the RNG state (nonzero) -- for reproducible sampling in tests */
    rsv_rwlock_wrlock(h);
    h->hdr->rng_state = (uint64_t)s ? (uint64_t)s : 0x9E3779B97F4A7C15ULL;
    rsv_rwlock_wrunlock(h);

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->k;                 /* cached: capacity == k, kept off the peer-writable header */
  OUTPUT:
    RETVAL

UV
item_size(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->item_size;
  OUTPUT:
    RETVAL

int
is_weighted(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (h->mode == RSV_MODE_WEIGHTED) ? 1 : 0;   /* cached mode, no lock */
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t k, isz, seen, cnt, ops, mmap_size;
        k    = h->k;                            /* cached geometry (no lock needed) */
        isz  = h->item_size;
        rsv_rwlock_rdlock(h);
        seen = h->hdr->seen;
        cnt  = rsv_count_locked(h);
        ops  = h->hdr->stat_ops;
        rsv_rwlock_rdunlock(h);
        mmap_size = (uint64_t)h->mmap_size;

        HV *hv = newHV();
        hv_stores(hv, "size",      newSVuv((UV)k));
        hv_stores(hv, "item_size", newSVuv((UV)isz));
        hv_stores(hv, "count",     newSVuv((UV)cnt));
        hv_stores(hv, "seen",      newSVuv((UV)seen));
        hv_stores(hv, "ops",       newSVuv((UV)ops));
        hv_stores(hv, "mmap_size", newSVuv((UV)mmap_size));
        hv_stores(hv, "weighted",  newSViv(h->mode == RSV_MODE_WEIGHTED ? 1 : 0));
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
    if (rsv_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Reservoir::Shared")) {
        RsvHandle *h = INT2PTR(RsvHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
