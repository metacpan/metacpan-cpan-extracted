#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "timingwheel.h"

#define EXTRACT(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::TimingWheel::Shared")) \
        croak("Expected a Data::TimingWheel::Shared object"); \
    TwHandle *h = INT2PTR(TwHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::TimingWheel::Shared object"); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code. EXTRACT's
 * sv_2mortal(SvREFCNT_inc(...)) pin only blocks REFCOUNT-driven destruction;
 * an explicit $obj->DESTROY frees the handle regardless and zeroes the IV.
 * NOTE: a typed parameter with a DEFAULT (e.g. `ticks = 1`) is converted by
 * xsubpp AFTER the PREINIT block, not in INPUT -- so its magic runs after
 * EXTRACT captured the handle, unlike a typed parameter with no default.
 * The same Perl can also REPLACE the invocant ($obj = 42 mutates ST(0),
 * because Perl passes aliases), hence the SvROK re-check before SvRV. */
#define REEXTRACT(sv) \
    if (!SvROK(sv)) \
        croak("Data::TimingWheel::Shared object was replaced during the call"); \
    h = INT2PTR(TwHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Data::TimingWheel::Shared object destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::TimingWheel::Shared  PACKAGE = Data::TimingWheel::Shared

PROTOTYPES: DISABLE

SV *
new(class, path = &PL_sv_undef, num_slots = 512, capacity = 0, ...)
    const char *class
    SV *path
    UV num_slots
    UV capacity
  PREINIT:
    char errbuf[TW_ERR_BUFLEN];
  CODE:
    /* Optional 5th arg: file mode for a newly-created file-backed segment
     * (default 0600, owner-only). Pass e.g. 0660 for cross-user sharing.
     * Resolve it BEFORE capturing the path PV: its get-magic can run Perl
     * code that may realloc/free that PV, so capture p last, right before
     * tw_create(). */
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    if (capacity < 1)
        croak("Data::TimingWheel::Shared->new: capacity must be >= 1");
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    TwHandle *h = tw_create(p, (uint64_t)num_slots, (uint64_t)capacity, mode, errbuf);
    if (!h) croak("Data::TimingWheel::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name = &PL_sv_undef, num_slots = 512, capacity = 0)
    const char *class
    SV *name
    UV num_slots
    UV capacity
  PREINIT:
    char errbuf[TW_ERR_BUFLEN];
  CODE:
    const char *nm = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nolen(name) : NULL;   /* undef -> default label */
    if (capacity < 1)
        croak("Data::TimingWheel::Shared->new_memfd: capacity must be >= 1");
    TwHandle *h = tw_create_memfd(nm, (uint64_t)num_slots, (uint64_t)capacity, errbuf);
    if (!h) croak("Data::TimingWheel::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[TW_ERR_BUFLEN];
  CODE:
    TwHandle *h = tw_open_fd(fd, errbuf);
    if (!h) croak("Data::TimingWheel::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::TimingWheel::Shared")) {
        TwHandle *h = INT2PTR(TwHandle*, SvIV(SvRV(self)));
        if (h) { sv_setiv(SvRV(self), 0); tw_destroy(h); }   /* null first: activates EXTRACT's use-after-destroy croak + makes a double DESTROY a no-op */
    }

UV
add(self, delay, payload)
    SV *self
    IV delay
    UV payload
  PREINIT:
    EXTRACT(self);
    int64_t id;
  CODE:
    /* signed delay: a negative value (e.g. from clock skew) clamps to 1 tick per
     * the POD, instead of UV-wrapping to a ~2^64 delay that never fires (slot leak) */
    tw_rwlock_wrlock(h);
    id = tw_add_locked(h, delay < 1 ? 1 : (uint64_t)delay, (uint64_t)payload);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    tw_rwlock_wrunlock(h);
    if (id < 0) croak("Data::TimingWheel::Shared->add: timer pool is full (capacity %u)", (unsigned)h->capacity);
    RETVAL = (UV)id;
  OUTPUT:
    RETVAL

int
cancel(self, timer_id)
    SV *self
    UV timer_id
  PREINIT:
    EXTRACT(self);
  CODE:
    tw_rwlock_wrlock(h);
    RETVAL = tw_cancel_locked(h, (uint64_t)timer_id);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    tw_rwlock_wrunlock(h);
  OUTPUT:
    RETVAL

void
advance(self, ticks = 1)
    SV *self
    IV ticks
  PREINIT:
    EXTRACT(self);
  PPCODE:
    {
        REEXTRACT(self);   /* `ticks = 1` is converted after PREINIT, so its magic already ran */
        uint64_t *out = NULL, fired = 0, i, cap = h->capacity;
        /* signed: reject a negative tick count (would UV-wrap to ~2^64 and spin the
         * per-tick loop under the write lock, wedging every sharer) */
        if (ticks < 0) croak("Data::TimingWheel::Shared->advance: ticks must be >= 0");
        if (cap) { Newx(out, (size_t)cap, uint64_t); SAVEFREEPV(out); }   /* alloc BEFORE the lock */
        tw_rwlock_wrlock(h);
        fired = cap ? tw_advance_locked(h, (uint64_t)ticks, out, cap) : 0;
        __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
        tw_rwlock_wrunlock(h);
        EXTEND(SP, (SSize_t)fired);
        for (i = 0; i < fired; i++) PUSHs(sv_2mortal(newSVuv((UV)out[i])));   /* Perl alloc AFTER unlock */
    }

UV
now(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV v;
  CODE:
    tw_rwlock_rdlock(h);
    v = (UV)h->hdr->now;
    tw_rwlock_rdunlock(h);
    RETVAL = v;
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT(self);
    UV v;
  CODE:
    tw_rwlock_rdlock(h);
    v = (UV)h->hdr->count;
    tw_rwlock_rdunlock(h);
    RETVAL = v;
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
num_slots(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    RETVAL = (UV)h->hdr->num_slots;
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    tw_rwlock_wrlock(h);
    tw_clear_locked(h);
    __atomic_fetch_add(&h->hdr->stat_ops, 1, __ATOMIC_RELAXED);
    tw_rwlock_wrunlock(h);

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT(self);
  CODE:
    {
        uint64_t now, count, ops;
        uint32_t num_slots, cap, cur;
        tw_rwlock_rdlock(h);
        now       = h->hdr->now;
        count     = h->hdr->count;
        num_slots = h->hdr->num_slots;
        cap       = h->hdr->capacity;
        cur       = h->hdr->cur;
        ops       = h->hdr->stat_ops;
        tw_rwlock_rdunlock(h);
        HV *hv = newHV();
        hv_stores(hv, "now",       newSVuv((UV)now));
        hv_stores(hv, "count",     newSVuv((UV)count));
        hv_stores(hv, "num_slots", newSVuv((UV)num_slots));
        hv_stores(hv, "capacity",  newSVuv((UV)cap));
        hv_stores(hv, "cur",       newSVuv((UV)cur));
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
    if (tw_msync(h) != 0) croak("sync: %s", strerror(errno));

void
unlink(self, ...)
    SV *self
  CODE:
    if (sv_isobject(self) && sv_derived_from(self, "Data::TimingWheel::Shared")) {
        TwHandle *h = INT2PTR(TwHandle*, SvIV(SvRV(self)));
        if (h && h->path) unlink(h->path);
    } else if (items >= 2 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        unlink(SvPV_nolen(ST(1)));
    }
