#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "hist.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Histogram::Shared")) \
        croak("Expected a Data::Histogram::Shared object"); \
    HistHandle *h = INT2PTR(HistHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Histogram::Shared object"); \
    HistHandle *h0 = h; PERL_UNUSED_VAR(h0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT's mortal
 * pins the referent only against refcount-driven destruction, not an
 * explicit DESTROY, so the local `h` would dangle.  Used only where magic
 * can actually intervene between EXTRACT and the first use of h. */
/* The same Perl that can destroy the handle can also REPLACE the invocant
 * ($obj = 42 from an overload handler mutates ST(0), because Perl passes
 * aliases), so SvROK must be re-checked before SvRV -- otherwise SvRV would
 * run on a non-reference. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::Histogram::Shared object was replaced during the call"); \
    h = INT2PTR(HistHandle*, SvIV(SvRV(sv))); \
    if (h != h0) croak("Data::Histogram::Shared object replaced or destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Histogram::Shared  PACKAGE = Data::Histogram::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, lowest = 1, highest = 3600000000LL, sig_figs = 3, ...)
    const char *class
    SV *path
    IV lowest
    IV highest
    int sig_figs
  PREINIT:
    char errbuf[HIST_ERR_BUFLEN];
  CODE:
    /* Optional trailing mode arg (ST(5)) sets the create permissions; default
     * 0600 (owner-only). Pass e.g. 0660 to opt in to group sharing. */
    mode_t mode = (items > 5 && (SvGETMAGIC(ST(5)), SvOK(ST(5)))) ? (mode_t)SvUV(ST(5)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    HistHandle *h = hist_create(p, (int64_t)lowest, (int64_t)highest,
                                (int32_t)sig_figs, mode, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::Histogram::Shared->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, lowest = 1, highest = 3600000000LL, sig_figs = 3)
    const char *class
    SV *name
    IV lowest
    IV highest
    int sig_figs
  PREINIT:
    char errbuf[HIST_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    HistHandle *h = hist_create_memfd(nm, (int64_t)lowest, (int64_t)highest,
                                      (int32_t)sig_figs, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::Histogram::Shared->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[HIST_ERR_BUFLEN];
  CODE:
    HistHandle *h = hist_open_fd(fd, errbuf);
    if (!h) croak("Data::Histogram::Shared->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_readonly(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[HIST_ERR_BUFLEN];
  CODE:
    /* Open a FROZEN (sealed) file read-only: O_RDONLY + PROT_READ, no lock
       ever.  A sealed file is immutable and no read path writes the mapping,
       so queries take no reader-slot / rwlock traffic and any number of
       processes can share one PROT_READ mapping (same architecture; the
       magic rejects a wrong-endian file). */
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    if (!p) croak("Data::Histogram::Shared->new_readonly: path is required");
    HistHandle *h = hist_open_readonly(p, errbuf);
    if (!h) croak("Data::Histogram::Shared->new_readonly: %s", errbuf);
    /* Re-read the class-name PV immediately before blessing: SvGETMAGIC(path)
     * above can run arbitrary Perl (tied/overloaded path) that reallocs or
     * frees ST(0)'s PV, dangling the `class` pointer captured by the typemap. */
    class = SvPV_nolen(ST(0));
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Histogram::Shared")) {
        HistHandle *h = INT2PTR(HistHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); hist_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

IV
record(self, value, ...)
    SV *self
    IV value
  PREINIT:
    EXTRACT(self);
    int64_t idx;
    IV total;
  CODE:
    if (h->readonly) croak("Data::Histogram::Shared->record: histogram is frozen (read-only)");
    /* optional count (default 1); read here so an explicit undef falls through to
     * the default instead of warning "uninitialized value". */
    int has_count = (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2))));
    UV count = has_count ? SvUV(ST(2)) : 1;
    /* Range-check + index-compute BEFORE locking so a croak holds no lock. */
    if (value < 0)
        croak("Data::Histogram::Shared->record: negative value (%lld)", (long long)value);
    /* count is a UV: a negative arg wraps to a huge unsigned and would silently
     * inflate the bucket.  Reject it via a signed check on the raw SV. */
    if (has_count && SvNV(ST(2)) < 0)
        croak("Data::Histogram::Shared->record: negative count (%lld)", (long long)SvIV(ST(2)));
    /* A huge positive count (>= 2^63) passes the signed check above but wraps to a
     * negative int64_t below, corrupting the bucket/total.  Reject it too. */
    if (count > (UV)INT64_MAX)
        croak("Data::Histogram::Shared->record: count too large (%llu)", (unsigned long long)count);
    REEXTRACT(self);
    idx = hist_index_for(h, (int64_t)value);
    if (idx < 0)
        croak("Data::Histogram::Shared->record: value %lld exceeds highest_trackable_value (%lld)",
              (long long)value, (long long)h->hdr->highest);
    hist_rwlock_wrlock(h);
    if (h->hdr->sealed) { hist_rwlock_wrunlock(h); croak("Data::Histogram::Shared->record: histogram is frozen (read-only)"); }
    hist_record_locked(h, (int64_t)value, (int64_t)count);
    total = (IV)h->hdr->total_count;
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    hist_rwlock_wrunlock(h);
    RETVAL = total;
  OUTPUT:
    RETVAL

UV
record_many(self, values)
    SV *self
    SV *values
  PREINIT:
    EXTRACT(self);
    AV *av;
    IV  top;
  CODE:
    if (h->readonly) croak("Data::Histogram::Shared->record_many: histogram is frozen (read-only)");
    SvGETMAGIC(values);   /* a tied/overloaded scalar may FETCH to an arrayref */
    if (!SvROK(values) || SvTYPE(SvRV(values)) != SVt_PVAV)
        croak("Data::Histogram::Shared->record_many: expected an array reference");
    av = (AV *)SvRV(values);
    sv_2mortal(SvREFCNT_inc((SV *)av));   /* pin the arrayref: element magic below cannot free it mid-loop */
    top = av_len(av);                     /* last index, -1 if empty */
    /* SvGETMAGIC(values) above, and av_len on a tied array (AvFILL -> mg_size
     * -> FETCHSIZE), both run Perl that can have destroyed self. */
    REEXTRACT(self);
    {
        STRLEN cnt = (top >= 0) ? (STRLEN)(top + 1) : 0, i;
        int64_t *vals = NULL;
        if (cnt) {                                       /* resolve + range-check ALL before locking */
            Newx(vals, cnt, int64_t); SAVEFREEPV(vals);  /* freed on return OR unwind */
            for (i = 0; i < cnt; i++) {                  /* a croak here holds NO lock; SAVEFREEPV cleans up */
                SV **el = av_fetch(av, (SSize_t)i, 0);
                IV v = (el && *el) ? SvIV(*el) : 0;
                if (v < 0)
                    croak("Data::Histogram::Shared->record_many: negative value (%lld)", (long long)v);
                REEXTRACT(self);
                if (hist_index_for(h, (int64_t)v) < 0)
                    croak("Data::Histogram::Shared->record_many: value %lld exceeds highest_trackable_value (%lld)",
                          (long long)v, (long long)h->hdr->highest);
                vals[i] = (int64_t)v;
            }
        }
        /* The REEXTRACT inside the loop above only runs when cnt > 0; a tied
         * FETCHSIZE reporting 0 skips the loop entirely and lands straight
         * here, so re-check outside the `if (cnt)` block as well. */
        REEXTRACT(self);
        hist_rwlock_wrlock(h);                            /* locked region: NO croak-capable calls */
        if (h->hdr->sealed) { hist_rwlock_wrunlock(h); croak("Data::Histogram::Shared->record_many: histogram is frozen (read-only)"); }
        for (i = 0; i < cnt; i++) hist_record_locked(h, vals[i], 1);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);  /* a call always counts, even an empty batch */
        hist_rwlock_wrunlock(h);
        RETVAL = (UV)cnt;
    }
  OUTPUT:
    RETVAL

IV
value_at_percentile(self, p)
    SV *self
    double p
  PREINIT:
    EXTRACT(self);
    IV v;
  CODE:
    if (h->readonly) {                     /* frozen: immutable counts, no lock needed */
        v = (IV)hist_value_at_percentile_locked(h, p);
    } else {
        hist_rwlock_rdlock(h);
        v = (IV)hist_value_at_percentile_locked(h, p);
        hist_rwlock_rdunlock(h);
    }
    RETVAL = v;
  OUTPUT:
    RETVAL

IV
count_at_value(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT(self);
    int64_t idx;
    IV c;
  CODE:
    if (value < 0)
        croak("Data::Histogram::Shared->count_at_value: negative value (%lld)", (long long)value);
    idx = hist_index_for(h, (int64_t)value);
    if (idx < 0)
        croak("Data::Histogram::Shared->count_at_value: value %lld exceeds highest_trackable_value (%lld)",
              (long long)value, (long long)h->hdr->highest);
    if (h->readonly) {                     /* frozen: immutable counts, no lock needed */
        c = (idx < hist_counts_capacity(h)) ? (IV)hist_counts(h)[idx] : 0;  /* Layer B: reject OOB idx (untrusted geometry) */
    } else {
        hist_rwlock_rdlock(h);
        c = (idx < hist_counts_capacity(h)) ? (IV)hist_counts(h)[idx] : 0;  /* Layer B: reject OOB idx (untrusted geometry) */
        hist_rwlock_rdunlock(h);
    }
    RETVAL = c;
  OUTPUT:
    RETVAL

IV
min(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    int64_t mn, total;
  CODE:
    if (h->readonly) {                     /* frozen: immutable, no lock needed */
        total = h->hdr->total_count;
        mn    = h->hdr->min_value;
    } else {
        hist_rwlock_rdlock(h);
        total = h->hdr->total_count;
        mn    = h->hdr->min_value;
        hist_rwlock_rdunlock(h);
    }
    RETVAL = (IV)(total == 0 ? 0 : mn);
  OUTPUT:
    RETVAL

IV
max(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    IV mx;
  CODE:
    if (h->readonly) {                     /* frozen: immutable, no lock needed */
        mx = (IV)h->hdr->max_value;
    } else {
        hist_rwlock_rdlock(h);
        mx = (IV)h->hdr->max_value;
        hist_rwlock_rdunlock(h);
    }
    RETVAL = mx;
  OUTPUT:
    RETVAL

double
mean(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    double m;
  CODE:
    if (h->readonly) {                     /* frozen: immutable counts, no lock needed */
        m = hist_mean_locked(h);
    } else {
        hist_rwlock_rdlock(h);
        m = hist_mean_locked(h);
        hist_rwlock_rdunlock(h);
    }
    RETVAL = m;
  OUTPUT:
    RETVAL

UV
total_count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV t;
  CODE:
    if (h->readonly) {                     /* frozen: immutable, no lock needed */
        t = (UV)h->hdr->total_count;
    } else {
        hist_rwlock_rdlock(h);
        t = (UV)h->hdr->total_count;
        hist_rwlock_rdunlock(h);
    }
    RETVAL = t;
  OUTPUT:
    RETVAL

void
merge(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::Histogram::Shared->merge: histogram is frozen (read-only)");
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::Histogram::Shared"))
        croak("Data::Histogram::Shared->merge: expected a Data::Histogram::Shared object");
    HistHandle *o = INT2PTR(HistHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::Histogram::Shared object");
    /* sv_isobject/sv_derived_from above begin with SvGETMAGIC(other), so a tied
     * `other` can have run Perl that destroyed self before h is used below.
     * `o` was read after that magic and needs no re-read. */
    REEXTRACT(self);

    /* Geometry is immutable after creation -- compare lock-free, croak BEFORE
     * allocating, so a mismatch holds no lock and leaks no buffer. */
    if (o->hdr->lowest != h->hdr->lowest ||
        o->hdr->highest != h->hdr->highest ||
        o->hdr->sig_figs != h->hdr->sig_figs ||
        o->hdr->counts_len != h->hdr->counts_len ||
        o->hdr->unit_magnitude != h->hdr->unit_magnitude ||
        o->hdr->sub_bucket_mask != h->hdr->sub_bucket_mask)
        croak("Data::Histogram::Shared->merge: geometry mismatch "
              "(lowest=%lld/highest=%lld/sig=%d vs lowest=%lld/highest=%lld/sig=%d)",
              (long long)h->hdr->lowest, (long long)h->hdr->highest, (int)h->hdr->sig_figs,
              (long long)o->hdr->lowest, (long long)o->hdr->highest, (int)o->hdr->sig_figs);

    /* Snapshot the other's counts (+ total/min/max) under its read lock into a
     * temp buffer, then release before taking self's write lock.  Copying to a
     * temp avoids holding two locks at once (deadlock-free regardless of
     * acquisition order between two processes merging each other). */
    {
        int64_t counts_len = h->hdr->counts_len;
        /* Layer B: never read from o's mapping nor write to h's past what each
         * actually maps (file-stored counts_off/counts_len are untrusted). For a
         * valid pair this is a no-op: counts_len == both capacities. */
        int64_t h_cap = hist_counts_capacity(h), o_cap = hist_counts_capacity(o);
        if (counts_len < 0) counts_len = 0;
        if (counts_len > h_cap) counts_len = h_cap;
        if (counts_len > o_cap) counts_len = o_cap;
        int64_t other_total, other_min, other_max;
        int64_t *tmp;
        Newx(tmp, (size_t)(counts_len ? counts_len : 1), int64_t);
        SAVEFREEPV(tmp);                 /* freed on normal return OR croak unwind */
        if (o->readonly) {                     /* frozen other: immutable counts, no lock */
            if (counts_len > 0) memcpy(tmp, hist_counts(o), (size_t)counts_len * sizeof(int64_t));
            other_total = o->hdr->total_count;
            other_min   = o->hdr->min_value;
            other_max   = o->hdr->max_value;
        } else {
            hist_rwlock_rdlock(o);
            if (counts_len > 0) memcpy(tmp, hist_counts(o), (size_t)counts_len * sizeof(int64_t));
            other_total = o->hdr->total_count;
            other_min   = o->hdr->min_value;
            other_max   = o->hdr->max_value;
            hist_rwlock_rdunlock(o);
        }

        hist_rwlock_wrlock(h);
        if (h->hdr->sealed) { hist_rwlock_wrunlock(h); croak("Data::Histogram::Shared->merge: histogram is frozen (read-only)"); }
        if (other_total > 0) hist_merge_counts(hist_counts(h), tmp, counts_len);   /* empty other -> nothing to add */
        if (h->hdr->total_count > INT64_MAX - other_total) h->hdr->total_count = INT64_MAX;
        else h->hdr->total_count += other_total;
        if (other_total > 0) {  /* only adopt min/max if other actually recorded something */
            if (other_min < h->hdr->min_value) h->hdr->min_value = other_min;
            if (other_max > h->hdr->max_value) h->hdr->max_value = other_max;
        }
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        hist_rwlock_wrunlock(h);
    }

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::Histogram::Shared->reset: histogram is frozen (read-only)");
    hist_rwlock_wrlock(h);
    if (h->hdr->sealed) { hist_rwlock_wrunlock(h); croak("Data::Histogram::Shared->reset: histogram is frozen (read-only)"); }
    hist_reset_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    hist_rwlock_wrunlock(h);

void
freeze(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    if (h->readonly) croak("Data::Histogram::Shared->freeze: cannot freeze a read-only handle");
    if (hist_freeze(h) != 0) croak("Data::Histogram::Shared->freeze: msync: %s", strerror(errno));
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

IV
lowest(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (IV)h->hdr->lowest;
  OUTPUT:
    RETVAL

IV
highest(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (IV)h->hdr->highest;
  OUTPUT:
    RETVAL

int
sig_figs(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (int)h->hdr->sig_figs;
  OUTPUT:
    RETVAL

IV
counts_len(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (IV)h->hdr->counts_len;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        int64_t total, mn, mx, counts_len, lowest, highest;
        int32_t sig_figs, bucket_count, sub_bucket_count;
        uint64_t ops;
        double mean;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSV* can never strand the lock. */
        if (!h->readonly) hist_rwlock_rdlock(h);   /* frozen: immutable, no lock */
        total            = h->hdr->total_count;
        mn               = h->hdr->min_value;
        mx               = h->hdr->max_value;
        counts_len       = h->hdr->counts_len;
        lowest           = h->hdr->lowest;
        highest          = h->hdr->highest;
        sig_figs         = h->hdr->sig_figs;
        bucket_count     = h->hdr->bucket_count;
        sub_bucket_count = h->hdr->sub_bucket_count;
        ops              = h->hdr->stat_ops;
        mean             = hist_mean_locked(h);
        if (!h->readonly) hist_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "lowest",           newSViv((IV)lowest));
        hv_stores(hv, "highest",          newSViv((IV)highest));
        hv_stores(hv, "sig_figs",         newSViv((IV)sig_figs));
        hv_stores(hv, "count",            newSViv((IV)total));
        hv_stores(hv, "min",              newSViv((IV)(total == 0 ? 0 : mn)));
        hv_stores(hv, "max",              newSViv((IV)mx));
        hv_stores(hv, "mean",             newSVnv(mean));
        hv_stores(hv, "counts_len",       newSViv((IV)counts_len));
        hv_stores(hv, "bucket_count",     newSViv((IV)bucket_count));
        hv_stores(hv, "sub_bucket_count", newSViv((IV)sub_bucket_count));
        hv_stores(hv, "ops",              newSVuv((UV)ops));
        hv_stores(hv, "mmap_size",        newSVuv((UV)h->mmap_size));
        hv_stores(hv, "frozen",           newSVuv(h->hdr->sealed ? 1 : 0));
        hv_stores(hv, "readonly",         newSVuv(h->readonly ? 1 : 0));
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
    if (!h->readonly && hist_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Histogram::Shared")) {
        HistHandle *h = INT2PTR(HistHandle*, SvIV(SvRV(self)));
        if (h && h->path && unlink(h->path) != 0 && errno != ENOENT)
            croak("Data::Histogram::Shared->unlink(%s): %s", h->path, strerror(errno));
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        {
            const char *up = SvPV_nolen(ST(1));
            if (unlink(up) != 0 && errno != ENOENT)
                croak("Data::Histogram::Shared->unlink(%s): %s", up, strerror(errno));
        }
    }
