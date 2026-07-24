#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <math.h>
#include "ddsketch.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::DDSketch::Shared")) \
        croak("Expected a Data::DDSketch::Shared object"); \
    DdHandle *h = INT2PTR(DdHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::DDSketch::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))   /* pin the referent so a reentrant DESTROY (from overload/tie on an arg) can't free the handle mid-method */

/* The pin above only blocks REFCOUNT-driven destruction. Perl run from argument
 * magic can still call $obj->DESTROY explicitly, which frees the handle and
 * zeroes the IV, leaving the local `h` dangling. Re-read it wherever such magic
 * can intervene before `h` is used. Sources of that magic here: SvGETMAGIC on an
 * argument, av_len on a TIED array (AvFILL -> mg_size -> FETCHSIZE), element
 * fetches, and sv_isobject/sv_derived_from (both begin with SvGETMAGIC).
 * The same Perl can also REPLACE the invocant ($obj = 42 mutates ST(0), because
 * Perl passes aliases), hence the SvROK re-check before SvRV. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::DDSketch::Shared object was replaced during the call"); \
    h = INT2PTR(DdHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::DDSketch::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::DDSketch::Shared  PACKAGE = Data::DDSketch::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, alpha = 0.01, num_buckets = 2048, ...)
    const char *class
    SV *path
    double alpha
    UV num_buckets
  PREINIT:
    char errbuf[DD_ERR_BUFLEN];
  CODE:
    /* Optional 5th arg: file mode for a newly-created file-backed segment
     * (default 0600, owner-only). Pass e.g. 0660 for cross-user sharing.
     * Resolve it FIRST: its get-magic runs arbitrary Perl that can realloc or
     * free the path PV, so capture the path LAST, immediately before use. */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    DdHandle *h = dd_create(p, alpha, (uint64_t)num_buckets, mode, errbuf);
    if (!h) croak("Data::DDSketch::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, alpha = 0.01, num_buckets = 2048)
    const char *class
    SV *name
    double alpha
    UV num_buckets
  PREINIT:
    char errbuf[DD_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    DdHandle *h = dd_create_memfd(nm, alpha, (uint64_t)num_buckets, errbuf);
    if (!h) croak("Data::DDSketch::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[DD_ERR_BUFLEN];
  CODE:
    DdHandle *h = dd_open_fd(fd, errbuf);
    if (!h) croak("Data::DDSketch::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::DDSketch::Shared")) {
        DdHandle *h = INT2PTR(DdHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); dd_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
add(self, value)
    SV *self
    double value
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!isfinite(value))                  /* reject NaN/Inf BEFORE the lock */
        croak("Data::DDSketch::Shared->add: value must be finite");
    dd_rwlock_wrlock(h);
    dd_insert_locked(h, value, 1);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    RETVAL = (UV)h->hdr->total_count;
    dd_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

UV
add_many(self, values)
    SV *self
    SV *values
  PREINIT:
    EXTRACT(self);
    AV *av;
    IV  top;
    UV  added = 0;
  CODE:
    SvGETMAGIC(values);
    if (!SvROK(values) || SvTYPE(SvRV(values)) != SVt_PVAV)
        croak("Data::DDSketch::Shared->add_many: expected an array reference");
    av = (AV *)SvRV(values);
    top = av_len(av);                     /* last index, -1 if empty */
    {
        STRLEN cnt = (top >= 0) ? (STRLEN)(top + 1) : 0, i;
        double *vs = NULL;
        if (cnt) {                                       /* resolve + validate all values BEFORE locking */
            Newx(vs, cnt, double); SAVEFREEPV(vs);       /* freed on return OR unwind */
            for (i = 0; i < cnt; i++) {
                SV **el = av_fetch(av, (SSize_t)i, 0);
                double v = (el && *el) ? SvNV(*el) : 0.0;
                if (!isfinite(v))                        /* a croak here holds NO lock */
                    croak("Data::DDSketch::Shared->add_many: value at index %u is not finite", (unsigned)i);
                vs[i] = v;
            }
        }
        /* SvGETMAGIC(values), av_len (tied FETCHSIZE) and the element SvNV
         * above all run Perl that can have destroyed self. This must sit
         * OUTSIDE the `if (cnt)` block: an empty (or tied, size-0) array
         * skips the loop but still reaches the lock below. */
        REEXTRACT(self);
        dd_rwlock_wrlock(h);                             /* locked region: NO croak-capable calls */
        for (i = 0; i < cnt; i++) { dd_insert_locked(h, vs[i], 1); added++; }
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        dd_rwlock_wrunlock(h);
    }
    RETVAL = added;
  OUTPUT:
    RETVAL

SV *
quantile(self, q)
    SV *self
    double q
  PREINIT:
    EXTRACT(self);
    double val;
    int found;
    uint64_t total;
  CODE:
    if (!(q >= 0.0 && q <= 1.0))
        croak("Data::DDSketch::Shared->quantile: q must be between 0 and 1");
    dd_rwlock_rdlock(h);
    total = h->hdr->total_count;
    if (total == 0) { found = 0; val = 0.0; }
    else val = dd_value_at_rank(h, q * (double)(total - 1), &found);
    dd_rwlock_rdunlock(h);
    RETVAL = found ? newSVnv(val) : &PL_sv_undef;   /* undef on an empty sketch */
  OUTPUT:
    RETVAL

SV *
min(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    double v;
    uint64_t total;
  CODE:
    dd_rwlock_rdlock(h);
    total = h->hdr->total_count;
    v = h->hdr->min_value;
    dd_rwlock_rdunlock(h);
    RETVAL = total ? newSVnv(v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
max(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    double v;
    uint64_t total;
  CODE:
    dd_rwlock_rdlock(h);
    total = h->hdr->total_count;
    v = h->hdr->max_value;
    dd_rwlock_rdunlock(h);
    RETVAL = total ? newSVnv(v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
mean(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    double sum;
    uint64_t total;
  CODE:
    dd_rwlock_rdlock(h);
    total = h->hdr->total_count;
    sum = h->hdr->sum;
    dd_rwlock_rdunlock(h);
    RETVAL = total ? newSVnv(sum / (double)total) : &PL_sv_undef;
  OUTPUT:
    RETVAL

NV
sum(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    double v;
  CODE:
    dd_rwlock_rdlock(h);
    v = h->hdr->sum;
    dd_rwlock_rdunlock(h);
    RETVAL = v;
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV n;
  CODE:
    dd_rwlock_rdlock(h);
    n = (UV)h->hdr->total_count;
    dd_rwlock_rdunlock(h);
    RETVAL = n;
  OUTPUT:
    RETVAL

UV
zero_count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV n;
  CODE:
    dd_rwlock_rdlock(h);
    n = (UV)h->hdr->zero_count;
    dd_rwlock_rdunlock(h);
    RETVAL = n;
  OUTPUT:
    RETVAL

void
merge(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::DDSketch::Shared"))
        croak("Data::DDSketch::Shared->merge: expected a Data::DDSketch::Shared object");
    DdHandle *o = INT2PTR(DdHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::DDSketch::Shared object");
    /* sv_isobject/sv_derived_from above begin with SvGETMAGIC(other), so a tied
     * `other` can have run Perl that destroyed self before h is used below.
     * `o` was read after that magic and needs no re-read. */
    REEXTRACT(self);

    /* geometry is immutable after creation -- compare the attach-time-cached
     * copies (the same values the merge math uses), not the peer-writable header,
     * and croak BEFORE allocating so a mismatch holds no lock and leaks no buffer. */
    if (o->num_buckets != h->num_buckets || o->gamma != h->gamma)
        croak("Data::DDSketch::Shared->merge: geometry mismatch (num_buckets/alpha differ)");

    /* Snapshot the other's stores + scalars under its read lock into temp
     * buffers, then release before taking self's write lock (deadlock-free,
     * two processes can merge each other). */
    uint64_t nb = o->num_buckets;
    uint64_t o_nmax = dd_store_max(o, o->neg_off);   /* Layer B: never read past o's mapping */
    uint64_t o_pmax = dd_store_max(o, o->pos_off);
    if (nb > o_nmax) nb = o_nmax;
    if (nb > o_pmax) nb = o_pmax;
    uint64_t *tneg, *tpos, o_total, o_zero;
    double o_sum, o_min, o_max;
    Newx(tneg, (size_t)(nb ? nb : 1), uint64_t); SAVEFREEPV(tneg);
    Newx(tpos, (size_t)(nb ? nb : 1), uint64_t); SAVEFREEPV(tpos);
    dd_rwlock_rdlock(o);
    memcpy(tneg, dd_neg(o), (size_t)nb * sizeof(uint64_t));
    memcpy(tpos, dd_pos(o), (size_t)nb * sizeof(uint64_t));
    o_total = o->hdr->total_count; o_zero = o->hdr->zero_count;
    o_sum = o->hdr->sum; o_min = o->hdr->min_value; o_max = o->hdr->max_value;
    dd_rwlock_rdunlock(o);

    dd_rwlock_wrlock(h);
    dd_merge_locked(h, tneg, tpos, nb, o_total, o_zero, o_sum, o_min, o_max);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    dd_rwlock_wrunlock(h);

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    dd_rwlock_wrlock(h);
    dd_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    dd_rwlock_wrunlock(h);

NV
alpha(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->hdr->alpha;
  OUTPUT:
    RETVAL

NV
gamma(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = h->gamma;                 /* cached, not the peer-writable header */
  OUTPUT:
    RETVAL

UV
num_buckets(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->num_buckets;       /* cached */
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t total, zero, ops;
        uint32_t nb;
        double alpha, gamma, sum, mn, mx;
        dd_rwlock_rdlock(h);
        total = h->hdr->total_count;
        zero  = h->hdr->zero_count;
        ops   = h->hdr->stat_ops;
        nb    = h->num_buckets;        /* cached geometry */
        alpha = h->hdr->alpha;         /* reported-only (no math/bounds depend on it) */
        gamma = h->gamma;              /* cached */
        sum   = h->hdr->sum;
        mn    = h->hdr->min_value;
        mx    = h->hdr->max_value;
        dd_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "alpha",       newSVnv(alpha));
        hv_stores(hv, "gamma",       newSVnv(gamma));
        hv_stores(hv, "num_buckets", newSVuv((UV)nb));
        hv_stores(hv, "count",       newSVuv((UV)total));
        hv_stores(hv, "zero_count",  newSVuv((UV)zero));
        hv_stores(hv, "sum",         newSVnv(sum));
        hv_stores(hv, "min",         total ? newSVnv(mn) : newSV(0));
        hv_stores(hv, "max",         total ? newSVnv(mx) : newSV(0));
        hv_stores(hv, "mean",        total ? newSVnv(sum / (double)total) : newSV(0));
        hv_stores(hv, "ops",         newSVuv((UV)ops));
        hv_stores(hv, "mmap_size",   newSVuv((UV)h->mmap_size));
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
    if (dd_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::DDSketch::Shared")) {
        DdHandle *h = INT2PTR(DdHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
