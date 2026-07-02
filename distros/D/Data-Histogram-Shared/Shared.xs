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
    if (!h) croak("Attempted to use a destroyed Data::Histogram::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Histogram::Shared  PACKAGE = Data::Histogram::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, lowest = 1, highest = 3600000000LL, sig_figs = 3)
    const char *class
    SV *path
    IV lowest
    IV highest
    int sig_figs
  PREINIT:
    char errbuf[HIST_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    HistHandle *h = hist_create(p, (int64_t)lowest, (int64_t)highest,
                                (int32_t)sig_figs, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::Histogram::Shared->new: %s", errbuf);
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
    const char *nm = SvOK(name) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    HistHandle *h = hist_create_memfd(nm, (int64_t)lowest, (int64_t)highest,
                                      (int32_t)sig_figs, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::Histogram::Shared->new_memfd: %s", errbuf);
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
    if (!h) croak("Data::Histogram::Shared->new_from_fd: %s", errbuf);
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
record(self, value, count = 1)
    SV *self
    IV value
    UV count
  PREINIT:
    EXTRACT(self);
    int64_t idx;
    IV total;
  CODE:
    /* Range-check + index-compute BEFORE locking so a croak holds no lock. */
    if (value < 0)
        croak("Data::Histogram::Shared->record: negative value (%lld)", (long long)value);
    idx = hist_index_for(h, (int64_t)value);
    if (idx < 0)
        croak("Data::Histogram::Shared->record: value %lld exceeds highest_trackable_value (%lld)",
              (long long)value, (long long)h->hdr->highest);
    hist_rwlock_wrlock(h);
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
    if (!SvROK(values) || SvTYPE(SvRV(values)) != SVt_PVAV)
        croak("Data::Histogram::Shared->record_many: expected an array reference");
    av = (AV *)SvRV(values);
    top = av_len(av);                     /* last index, -1 if empty */
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
                if (hist_index_for(h, (int64_t)v) < 0)
                    croak("Data::Histogram::Shared->record_many: value %lld exceeds highest_trackable_value (%lld)",
                          (long long)v, (long long)h->hdr->highest);
                vals[i] = (int64_t)v;
            }
        }
        hist_rwlock_wrlock(h);                            /* locked region: NO croak-capable calls */
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
    hist_rwlock_rdlock(h);
    v = (IV)hist_value_at_percentile_locked(h, p);
    hist_rwlock_rdunlock(h);
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
    hist_rwlock_rdlock(h);
    c = (IV)hist_counts(h)[idx];
    hist_rwlock_rdunlock(h);
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
    hist_rwlock_rdlock(h);
    total = h->hdr->total_count;
    mn    = h->hdr->min_value;
    hist_rwlock_rdunlock(h);
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
    hist_rwlock_rdlock(h);
    mx = (IV)h->hdr->max_value;
    hist_rwlock_rdunlock(h);
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
    hist_rwlock_rdlock(h);
    m = hist_mean_locked(h);
    hist_rwlock_rdunlock(h);
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
    hist_rwlock_rdlock(h);
    t = (UV)h->hdr->total_count;
    hist_rwlock_rdunlock(h);
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
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::Histogram::Shared"))
        croak("Data::Histogram::Shared->merge: expected a Data::Histogram::Shared object");
    HistHandle *o = INT2PTR(HistHandle*, SvIV(SvRV(other)));
    if (!o) croak("Attempted to use a destroyed Data::Histogram::Shared object");

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
        int64_t other_total, other_min, other_max;
        int64_t *tmp;
        Newx(tmp, (size_t)counts_len, int64_t);
        SAVEFREEPV(tmp);                 /* freed on normal return OR croak unwind */
        hist_rwlock_rdlock(o);
        memcpy(tmp, hist_counts(o), (size_t)counts_len * sizeof(int64_t));
        other_total = o->hdr->total_count;
        other_min   = o->hdr->min_value;
        other_max   = o->hdr->max_value;
        hist_rwlock_rdunlock(o);

        hist_rwlock_wrlock(h);
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
    hist_rwlock_wrlock(h);
    hist_reset_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    hist_rwlock_wrunlock(h);

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
        hist_rwlock_rdlock(h);
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
        hist_rwlock_rdunlock(h);

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
    if (hist_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::Histogram::Shared")) {
        HistHandle *h = INT2PTR(HistHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && SvOK(ST(1))) {
        unlink(SvPV_nolen(ST(1)));
    }
