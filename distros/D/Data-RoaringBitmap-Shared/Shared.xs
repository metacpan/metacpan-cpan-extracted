#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "roaring.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::RoaringBitmap::Shared")) \
        croak("Expected a Data::RoaringBitmap::Shared object"); \
    RbHandle *h = INT2PTR(RbHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::RoaringBitmap::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define RB_UINT32_MAX_UV ((UV)0xFFFFFFFF)

/* Acquire the receiver `a`'s WRITE lock and the other `b`'s READ lock in a
 * globally-consistent order keyed on each bitmap's shared-memory identity
 * (hdr->bitmap_id), NOT the process-local handle pointer.  Two unrelated
 * processes mapping the same pair X,Y therefore agree on order, so a
 * concurrent X.union(Y) / Y.union(X) cannot deadlock.  The receiver always
 * gets the write lock and the other the read lock regardless of which is
 * acquired first.  a and b must refer to DISTINCT underlying bitmaps (the
 * caller has already ruled out a == b and equal bitmap_id). */
static void rb_lock_pair(RbHandle *a, RbHandle *b) {
    if (a->hdr->bitmap_id < b->hdr->bitmap_id) {
        rb_rwlock_wrlock(a);
        rb_rwlock_rdlock(b);
    } else {
        rb_rwlock_rdlock(b);
        rb_rwlock_wrlock(a);
    }
}
static void rb_unlock_pair(RbHandle *a, RbHandle *b) {
    if (a->hdr->bitmap_id < b->hdr->bitmap_id) {
        rb_rwlock_rdunlock(b);
        rb_rwlock_wrunlock(a);
    } else {
        rb_rwlock_wrunlock(a);
        rb_rwlock_rdunlock(b);
    }
}

MODULE = Data::RoaringBitmap::Shared  PACKAGE = Data::RoaringBitmap::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, container_capacity = 256, file_mode = 0600)
    const char *class
    SV *path
    UV container_capacity
    UV file_mode
  PREINIT:
    char errbuf[RB_ERR_BUFLEN];
  CODE:
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    RbHandle *h = rb_create(p, (uint64_t)container_capacity, (mode_t)file_mode, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::RoaringBitmap::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, container_capacity = 256)
    const char *class
    SV *name
    UV container_capacity
  PREINIT:
    char errbuf[RB_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    RbHandle *h = rb_create_memfd(nm, (uint64_t)container_capacity, errbuf);   /* validates args into errbuf */
    if (!h) croak("Data::RoaringBitmap::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[RB_ERR_BUFLEN];
  CODE:
    RbHandle *h = rb_open_fd(fd, errbuf);
    if (!h) croak("Data::RoaringBitmap::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::RoaringBitmap::Shared")) {
        RbHandle *h = INT2PTR(RbHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); rb_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

IV
add(self, x)
    SV *self
    UV x
  PREINIT:
    EXTRACT(self);
    int added;
    uint32_t hi;
  CODE:
    /* Range-check BEFORE locking: a croak must never happen under the lock. */
    if (x > RB_UINT32_MAX_UV)
        croak("Data::RoaringBitmap::Shared->add: value %" UVuf " exceeds uint32 (max 4294967295)", x);
    hi = (uint32_t)(x >> 16);
    rb_rwlock_wrlock(h);
    /* Need a free container slot only if this value touches an empty bucket. */
    if (rb_buckets(h)[hi].type == RB_TYPE_NONE && rb_avail_slots(h) == 0) {
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);   /* a call that took the write lock counts (matches add_many) */
        rb_rwlock_wrunlock(h);   /* release BEFORE croak */
        croak("Data::RoaringBitmap::Shared->add: container pool exhausted "
              "(grow container_capacity)");
    }
    added = rb_add_locked(h, (uint32_t)x);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rb_rwlock_wrunlock(h);
    RETVAL = (IV)added;
  OUTPUT:
    RETVAL

IV
add_many(self, ints)
    SV *self
    SV *ints
  PREINIT:
    EXTRACT(self);
    AV *av;
    SSize_t n, i;
    UV *vals;
    IV total_added;
  CODE:
    if (!SvROK(ints) || SvTYPE(SvRV(ints)) != SVt_PVAV)
        croak("Data::RoaringBitmap::Shared->add_many: expected an array reference");
    av = (AV *)SvRV(ints);
    n = av_len(av) + 1;
    /* Resolve + range-check every value BEFORE the lock (croak-free section). */
    Newx(vals, n > 0 ? n : 1, UV);
    SAVEFREEPV(vals);
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        UV v = (e && SvOK(*e)) ? SvUV(*e) : 0;
        if (v > RB_UINT32_MAX_UV) {
            croak("Data::RoaringBitmap::Shared->add_many: value %" UVuf
                  " exceeds uint32 (max 4294967295)", v);
        }
        vals[i] = v;
    }
    total_added = 0;
    rb_rwlock_wrlock(h);
    for (i = 0; i < n; i++) {
        uint32_t hi = (uint32_t)(vals[i] >> 16);
        if (rb_buckets(h)[hi].type == RB_TYPE_NONE && rb_avail_slots(h) == 0) {
            __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
            rb_rwlock_wrunlock(h);   /* release BEFORE croak; partial adds remain (documented non-atomic) */
            croak("Data::RoaringBitmap::Shared->add_many: container pool exhausted "
                  "after adding %" IVdf " element(s) (grow container_capacity)", total_added);
        }
        total_added += rb_add_locked(h, (uint32_t)vals[i]);
    }
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rb_rwlock_wrunlock(h);
    RETVAL = total_added;
  OUTPUT:
    RETVAL

bool
contains(self, x)
    SV *self
    UV x
  PREINIT:
    EXTRACT(self);
  CODE:
    if (x > RB_UINT32_MAX_UV) { RETVAL = 0; }   /* a value out of range is simply absent */
    else {
        rb_rwlock_rdlock(h);
        RETVAL = rb_contains_locked(h, (uint32_t)x) ? 1 : 0;
        rb_rwlock_rdunlock(h);
    }
  OUTPUT:
    RETVAL

IV
remove(self, x)
    SV *self
    UV x
  PREINIT:
    EXTRACT(self);
    int removed;
  CODE:
    if (x > RB_UINT32_MAX_UV) { RETVAL = 0; }   /* out of range -> nothing to remove */
    else {
        rb_rwlock_wrlock(h);
        removed = rb_remove_locked(h, (uint32_t)x);
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        rb_rwlock_wrunlock(h);
        RETVAL = (IV)removed;
    }
  OUTPUT:
    RETVAL

UV
cardinality(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    rb_rwlock_rdlock(h);
    RETVAL = (UV)h->hdr->cardinality;
    rb_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    rb_rwlock_rdlock(h);
    RETVAL = (h->hdr->cardinality == 0) ? 1 : 0;
    rb_rwlock_rdunlock(h);
  OUTPUT:
    RETVAL

SV *
min(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    uint32_t v;
    int found;
  CODE:
    rb_rwlock_rdlock(h);
    found = rb_min_locked(h, &v);
    rb_rwlock_rdunlock(h);
    RETVAL = found ? newSVuv((UV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
max(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    uint32_t v;
    int found;
  CODE:
    rb_rwlock_rdlock(h);
    found = rb_max_locked(h, &v);
    rb_rwlock_rdunlock(h);
    RETVAL = found ? newSVuv((UV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
to_array(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    AV *av;
    UV card;
  CODE:
    /* Pre-size the AV to the cardinality BEFORE the lock (av_extend can croak
       on OOM; av_store afterward cannot).  The cardinality may grow between
       this read and the fill, but to_array is a best-effort snapshot; we cap
       the fill at the pre-sized length so we never store past the extent. */
    rb_rwlock_rdlock(h);
    card = (UV)h->hdr->cardinality;
    rb_rwlock_rdunlock(h);

    av = newAV();
    if (card) av_extend(av, (SSize_t)card - 1);   /* room for indices 0..card-1 */

    {
        RbBucket *bt;
        UV idx = 0;
        rb_rwlock_rdlock(h);
        bt = rb_buckets(h);
        for (uint32_t hi = 0; hi < RB_NUM_BUCKETS && idx < card; hi++) {
            if (bt[hi].type == RB_TYPE_NONE) continue;
            if (bt[hi].type == RB_TYPE_ARRAY) {
                uint16_t *vals = rb_array(h, bt[hi].container_off);
                uint32_t ac = rb_array_card(&bt[hi]);
                for (uint32_t i = 0; i < ac && idx < card; i++)
                    av_store(av, (SSize_t)idx++, newSVuv(((UV)hi << 16) | vals[i]));
            } else {
                uint64_t *bits = rb_bitmap(h, bt[hi].container_off);
                for (uint32_t w = 0; w < 1024 && idx < card; w++) {
                    uint64_t word = bits[w];
                    while (word && idx < card) {
                        uint32_t lo = (w << 6) + (uint32_t)__builtin_ctzll(word);
                        av_store(av, (SSize_t)idx++, newSVuv(((UV)hi << 16) | lo));
                        word &= word - 1;   /* clear lowest set bit */
                    }
                }
            }
        }
        rb_rwlock_rdunlock(h);
    }
    RETVAL = newRV_noinc((SV *)av);
  OUTPUT:
    RETVAL

SV *
union(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::RoaringBitmap::Shared"))
        croak("Data::RoaringBitmap::Shared->union: expected a Data::RoaringBitmap::Shared object");
    {
        RbHandle *o = INT2PTR(RbHandle*, SvIV(SvRV(other)));
        if (!o) croak("Attempted to use a destroyed Data::RoaringBitmap::Shared object");
        /* Same underlying bitmap (same handle, or two handles to one mapping
         * sharing a bitmap_id) -> a |= a is a no-op.  Must short-circuit before
         * locking: taking the write lock and the read lock on the SAME rwlock
         * would self-deadlock. */
        if (o == h || o->hdr->bitmap_id == h->hdr->bitmap_id) {
            __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
            SvREFCNT_inc(self);
            RETVAL = self;
        } else {
            uint32_t need;
            rb_lock_pair(h, o);
            need = rb_union_new_slots_needed(h, o);
            if (rb_avail_slots(h) < need) {
                __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
                rb_unlock_pair(h, o);       /* release BEFORE croak */
                croak("Data::RoaringBitmap::Shared->union: container pool exhausted "
                      "(needs %u more container(s); grow container_capacity)", need);
            }
            rb_union_locked(h, o);
            __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
            rb_unlock_pair(h, o);
            SvREFCNT_inc(self);             /* return the receiver for chaining */
            RETVAL = self;
        }
    }
  OUTPUT:
    RETVAL

SV *
intersect(self, other)
    SV *self
    SV *other
  PREINIT:
    EXTRACT(self);
  CODE:
    if (!sv_isobject(other) || !sv_derived_from(other, "Data::RoaringBitmap::Shared"))
        croak("Data::RoaringBitmap::Shared->intersect: expected a Data::RoaringBitmap::Shared object");
    {
        RbHandle *o = INT2PTR(RbHandle*, SvIV(SvRV(other)));
        if (!o) croak("Attempted to use a destroyed Data::RoaringBitmap::Shared object");
        /* Same underlying bitmap (same handle, or two handles to one mapping
         * sharing a bitmap_id) -> a &= a is a no-op.  Short-circuit before
         * locking to avoid self-deadlocking on the one shared rwlock. */
        if (o == h || o->hdr->bitmap_id == h->hdr->bitmap_id) {
            __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
            SvREFCNT_inc(self);
            RETVAL = self;
        } else {
            rb_lock_pair(h, o);             /* intersect never needs new slots */
            rb_intersect_locked(h, o);
            __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
            rb_unlock_pair(h, o);
            SvREFCNT_inc(self);
            RETVAL = self;
        }
    }
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    rb_rwlock_wrlock(h);
    rb_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    rb_rwlock_wrunlock(h);

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t card, ops;
        uint32_t cont_used, cont_cap, bkts_used;
        /* Snapshot under the lock; do all (croak-capable) Perl allocation after
           releasing it -- so an OOM in newHV/newSV* can never strand the lock. */
        rb_rwlock_rdlock(h);
        card      = h->hdr->cardinality;
        cont_used = h->hdr->container_used;
        cont_cap  = h->hdr->container_cap;
        ops       = h->hdr->stat_ops;
        bkts_used = rb_buckets_used(h);
        rb_rwlock_rdunlock(h);

        HV *hv = newHV();
        hv_stores(hv, "cardinality",         newSVuv((UV)card));
        hv_stores(hv, "containers_used",     newSVuv((UV)cont_used));
        hv_stores(hv, "containers_capacity", newSVuv((UV)cont_cap));
        hv_stores(hv, "buckets_used",        newSVuv((UV)bkts_used));
        hv_stores(hv, "ops",                 newSVuv((UV)ops));
        hv_stores(hv, "mmap_size",           newSVuv((UV)h->mmap_size));
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
    if (rb_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::RoaringBitmap::Shared")) {
        RbHandle *h = INT2PTR(RbHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
