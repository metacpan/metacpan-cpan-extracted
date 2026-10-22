#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

static int pool_wait_interrupted(void) { dTHX; return PL_sig_pending != 0; }
#define POOL_WAIT_INTERRUPTED() pool_wait_interrupted()
#include "pool.h"

static XS(XS_Data__Pool__Shared_alloc);
static XS(XS_Data__Pool__Shared_try_alloc);
static XS(XS_Data__Pool__Shared_set);
static XS(XS_Data__Pool__Shared__I64_set);
static XS(XS_Data__Pool__Shared__I32_set);
static XS(XS_Data__Pool__Shared__F64_set);
static XS(XS_Data__Pool__Shared__Str_set);

static int pool_native_set(CV *cv) {
    if (!cv || !CvISXSUB(cv)) return -1;
    XSUBADDR_t fn = CvXSUB(cv);
    if (fn == XS_Data__Pool__Shared_set)      return POOL_VAR_RAW;
    if (fn == XS_Data__Pool__Shared__I64_set) return POOL_VAR_I64;
    if (fn == XS_Data__Pool__Shared__I32_set) return POOL_VAR_I32;
    if (fn == XS_Data__Pool__Shared__F64_set) return POOL_VAR_F64;
    if (fn == XS_Data__Pool__Shared__Str_set) return POOL_VAR_STR;
    return -1;
}

/* slot_sv lifetime magic: returned scalar pins the pool object alive by
 * holding an incremented refcount, released when the scalar is freed. */
static int pool_scalar_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    if (mg->mg_obj) SvREFCNT_dec(mg->mg_obj);
    return 0;
}

static const MGVTBL pool_scalar_magic_vtbl = {
    NULL, NULL, NULL, NULL, pool_scalar_magic_free, NULL, NULL, NULL
};

typedef struct {
    SV *object;
    SV *slot;
    int committed;
} PoolAllocation;

static void pool_allocation_cleanup(pTHX_ void *offset) {
    PoolAllocation *allocation = SSPTRt(PTR2IV(offset), PoolAllocation);
    SV *object = allocation->object, *slot = allocation->slot;
    if (!allocation->committed) {
        dSP;
        ENTER;
        SAVETMPS;
        save_scalar(PL_errgv);
        PUSHMARK(SP);
        XPUSHs(object);
        XPUSHs(slot);
        PUTBACK;
        call_method("free", G_DISCARD | G_EVAL);
        FREETMPS;
        LEAVE;
    }
    SvREFCNT_dec(slot);
    SvREFCNT_dec(object);
}

#define EXTRACT_POOL(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Pool::Shared")) \
        croak("Expected a Data::Pool::Shared object"); \
    PoolHandle *h = INT2PTR(PoolHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Pool::Shared object"); \
    PoolHandle *h0 = h; PERL_UNUSED_VAR(h0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT's mortal
 * pins the referent only against refcount-driven destruction, not an
 * explicit DESTROY, so the local `h` would dangle.  Used only where magic
 * can actually intervene between EXTRACT and the first use of h. */
/* The same Perl can also REPLACE the invocant ($obj = 42 from an overload
 * handler mutates ST(0), because Perl passes aliases), so SvROK is re-checked
 * before SvRV -- otherwise SvRV would run on a non-reference. */
#define REEXTRACT_POOL(sv) \
    if (!SvROK(sv)) \
        croak("Data::Pool::Shared object was replaced during the call"); \
    h = INT2PTR(PoolHandle*, SvIV(SvRV(sv))); \
    if (h != h0) croak("Data::Pool::Shared object replaced or destroyed during the call")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define CHECK_SLOT(h, slot) \
    if ((UV)(slot) >= (h)->capacity) \
        croak("slot %" UVuf " out of range (capacity %" UVuf ")", \
              (UV)(slot), (UV)(h)->capacity)

#define CHECK_ALLOCATED(h, slot) \
    if (!pool_is_allocated(h, slot)) \
        croak("slot %" UVuf " is not allocated", (UV)(slot))


static int64_t pool_perl_alloc(pTHX_ SV *self, PoolHandle *h, double timeout) {
    PoolHandle *h0 = h;
    struct timespec deadline, remaining;
    if (timeout > 0) pool_make_deadline(timeout, &deadline);
    double seconds = timeout;
    for (;;) {
        int64_t result = pool_alloc(h, seconds);
        if (result != -2) return result;
        PERL_ASYNC_CHECK();
        REEXTRACT_POOL(self);
        if (timeout > 0) {
            if (!pool_remaining_time(&deadline, &remaining)) return -1;
            seconds = (double)remaining.tv_sec + (double)remaining.tv_nsec / 1e9;
        }
    }
}

static int pool_perl_alloc_n(pTHX_ SV *self, PoolHandle *h, uint64_t *out, uint32_t count, double timeout) {
    PoolHandle *h0 = h;
    struct timespec deadline, remaining;
    if (timeout > 0) pool_make_deadline(timeout, &deadline);
    double seconds = timeout;
    for (;;) {
        int result = pool_alloc_n(h, out, count, seconds);
        if (result >= 0) return result;
        PERL_ASYNC_CHECK();
        REEXTRACT_POOL(self);
        if (timeout > 0) {
            if (!pool_remaining_time(&deadline, &remaining)) return 0;
            seconds = (double)remaining.tv_sec + (double)remaining.tv_nsec / 1e9;
        }
    }
}

MODULE = Data::Pool::Shared  PACKAGE = Data::Pool::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, elem_size, ...)
    const char *class
    SV *path
    UV capacity
    UV elem_size
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, (uint32_t)elem_size, POOL_VAR_RAW, mode, errbuf);
    if (!h) croak("Data::Pool::Shared->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity, elem_size)
    const char *class
    const char *name
    UV capacity
    UV elem_size
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_create_memfd(name, capacity, (uint32_t)elem_size, POOL_VAR_RAW, errbuf);
    if (!h) croak("Data::Pool::Shared->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_open_fd(fd, POOL_VAR_RAW, errbuf);
    if (!h) croak("Data::Pool::Shared->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::Pool::Shared")) return;
    PoolHandle *h = INT2PTR(PoolHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    pool_destroy(h);

SV *
alloc(self, ...)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
    double timeout = -1;
  CODE:
    if (items > 1 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) timeout = SvNV(ST(1));
    REEXTRACT_POOL(self);
    int64_t slot = pool_perl_alloc(aTHX_ self, h, timeout);
    RETVAL = (slot >= 0) ? newSViv((IV)slot) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
try_alloc(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    int64_t slot = pool_try_alloc(h);
    RETVAL = (slot >= 0) ? newSViv((IV)slot) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
alloc_set(self, value, ...)
    SV *self
    SV *value
  ALIAS:
    try_alloc_set = 1
  CODE:
    ENTER;
    SAVETMPS;
    SV *object = sv_2mortal(newSVsv(self));
    SV *val = sv_2mortal(newSVsv(value));
    SV *timeout = NULL;
    if (!ix) {
        timeout = sv_2mortal(items > 2 ? newSVsv(ST(2)) : newSViv(-1));
        if (!SvOK(timeout)) sv_setiv(timeout, -1);
    }
    EXTRACT_POOL(object);
    GV *alloc_gv = gv_fetchmethod_autoload(SvSTASH(SvRV(object)), ix ? "try_alloc" : "alloc", 0);
    GV *set_gv = gv_fetchmethod_autoload(SvSTASH(SvRV(object)), "set", 0);
    CV *alloc_cv = alloc_gv ? GvCV(alloc_gv) : NULL;
    int variant = set_gv ? pool_native_set(GvCV(set_gv)) : -1;
    int native = variant >= 0 && alloc_cv && CvISXSUB(alloc_cv)
        && CvXSUB(alloc_cv) == (ix ? XS_Data__Pool__Shared_try_alloc : XS_Data__Pool__Shared_alloc);
    dSP;
    SV *slot;
    if (native) {
        double seconds = ix ? 0 : SvNV(timeout);
        REEXTRACT_POOL(object);
        int64_t index = ix ? pool_try_alloc(h) : pool_perl_alloc(aTHX_ object, h, seconds);
        SPAGAIN;
        slot = index >= 0 ? sv_2mortal(newSViv((IV)index)) : &PL_sv_undef;
    } else {
        PUSHMARK(SP);
        XPUSHs(object);
        if (!ix) XPUSHs(timeout);
        PUTBACK;
        call_method(ix ? "try_alloc" : "alloc", G_SCALAR);
        SPAGAIN;
        slot = POPs;
    }
    if (SvOK(slot)) {
        SSize_t offset = SSNEWt(1, PoolAllocation);
        PoolAllocation *allocation = SSPTRt(offset, PoolAllocation);
        allocation->object = SvREFCNT_inc(object);
        allocation->slot = SvREFCNT_inc(slot);
        allocation->committed = 0;
        SAVEDESTRUCTOR_X(pool_allocation_cleanup, INT2PTR(void *, offset));
        if (native) {
            UV index = SvUV(slot);
            IV integer = 0;
            NV number = 0;
            STRLEN len = 0;
            const char *bytes = NULL;
            if (variant == POOL_VAR_I64 || variant == POOL_VAR_I32) integer = SvIV(val);
            else if (variant == POOL_VAR_F64) number = SvNV(val);
            else bytes = SvPV(val, len);
            SPAGAIN;
            REEXTRACT_POOL(object);
            CHECK_SLOT(h, index);
            CHECK_ALLOCATED(h, index);
            switch (variant) {
                case POOL_VAR_I64: pool_set_i64(h, index, (int64_t)integer); break;
                case POOL_VAR_I32: pool_set_i32(h, index, (int32_t)integer); break;
                case POOL_VAR_F64: pool_set_f64(h, index, (double)number); break;
                case POOL_VAR_STR: pool_set_str(h, index, bytes, (uint32_t)len); break;
                default:
                    if (len > h->elem_size) len = h->elem_size;
                    memcpy(pool_slot_ptr(h, index), bytes, len);
                    if (len < h->elem_size)
                        memset(pool_slot_ptr(h, index) + len, 0, h->elem_size - len);
            }
        } else {
            PUSHMARK(SP);
            XPUSHs(object);
            XPUSHs(slot);
            XPUSHs(val);
            PUTBACK;
            call_method("set", G_DISCARD);
            SPAGAIN;
        }
        RETVAL = newSVsv(slot);
        SSPTRt(offset, PoolAllocation)->committed = 1;
    } else {
        RETVAL = &PL_sv_undef;
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    if (!SvOK(RETVAL) && GIMME_V == G_ARRAY) XSRETURN_EMPTY;
  OUTPUT:
    RETVAL

bool
free(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    RETVAL = pool_free_slot(h, slot);
  OUTPUT:
    RETVAL

SV *
get(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = newSVpvn((const char *)pool_slot_ptr(h, slot), h->elem_size);
  OUTPUT:
    RETVAL

void
set(self, slot, data)
    SV *self
    UV slot
    SV *data
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    STRLEN len;
    const char *bytes = SvPV(data, len);
    /* SvPV on a bare SV arg runs overload/tie magic = arbitrary Perl, which can
     * have destroyed self before h is used below. (CHECK_SLOT/CHECK_ALLOCATED
     * above ran on the pre-magic handle; re-validate against the current one.) */
    REEXTRACT_POOL(self);
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    if (len > h->elem_size)
        len = h->elem_size;
    memcpy(pool_slot_ptr(h, slot), bytes, len);
    if (len < h->elem_size)
        memset(pool_slot_ptr(h, slot) + len, 0, h->elem_size - len);

bool
is_allocated(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    RETVAL = pool_is_allocated(h, slot);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = (UV)h->hdr->capacity;
  OUTPUT:
    RETVAL

UV
elem_size(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = h->hdr->elem_size;
  OUTPUT:
    RETVAL

UV
used(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = __atomic_load_n(&h->hdr->used, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

UV
available(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = (UV)pool_available(h);
  OUTPUT:
    RETVAL

UV
owner(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    RETVAL = __atomic_load_n(&h->owners[slot], __ATOMIC_RELAXED) & ~POOL_OWNER_RECOVERING;
  OUTPUT:
    RETVAL

UV
recover_stale(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = pool_recover_stale(h);
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    pool_reset(h);

void
scan_from(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    pool_scan_from(h, (uint64_t)slot);

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = pool_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = pool_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    int64_t v = pool_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    if (pool_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class) && sv_derived_from(self_or_class, "Data::Pool::Shared")) {
        PoolHandle *h = INT2PTR(PoolHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        p = h->path;
    } else {
        if (items < 2) croak("Usage: ...->unlink($path)");
        p = SvPV_nolen(ST(1));
    }
    if (!p) croak("cannot unlink anonymous or memfd object");
    if (unlink(p) != 0 && errno != ENOENT)
        croak("unlink(%s): %s", p, strerror(errno));

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    HV *hv = newHV();
    PoolHeader *hdr = h->hdr;
    hv_store(hv, "capacity", 8, newSVuv((UV)hdr->capacity), 0);
    hv_store(hv, "elem_size", 9, newSVuv(hdr->elem_size), 0);
    hv_store(hv, "used", 4, newSVuv((UV)__atomic_load_n(&hdr->used, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "available", 9,
        newSVuv((UV)pool_available(h)), 0);
    hv_store(hv, "waiters", 7, newSVuv((UV)__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "allocs", 6, newSVuv((UV)__atomic_load_n(&hdr->stat_allocs, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "frees", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_frees, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL


SV *
alloc_n(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_POOL(self);
    double timeout = -1;
  CODE:
    if (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) timeout = SvNV(ST(2));
    if (count == 0) {
        RETVAL = newRV_noinc((SV *)newAV());
    } else if (count > 0xFFFFFFFFU) {
        croak("Data::Pool::Shared->alloc_n: count exceeds 2^32");   /* would truncate to uint32 for pool_alloc_n */
    } else {
        uint64_t *buf;
        Newx(buf, count, uint64_t);
        SAVEFREEPV(buf);  /* freed on scope exit, incl. a croak from newSViv/av_push */
        REEXTRACT_POOL(self);
        if (pool_perl_alloc_n(aTHX_ self, h, buf, (uint32_t)count, timeout)) {
            AV *av = newAV();
            av_extend(av, count - 1);
            for (UV i = 0; i < count; i++)
                av_push(av, newSViv((IV)buf[i]));
            RETVAL = newRV_noinc((SV *)av);
        } else {
            RETVAL = &PL_sv_undef;
        }
    }
  OUTPUT:
    RETVAL

UV
free_n(self, slots_av)
    SV *self
    SV *slots_av
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    SvGETMAGIC(slots_av);   /* a tied/overloaded scalar may FETCH to an arrayref */
    if (!SvROK(slots_av) || SvTYPE(SvRV(slots_av)) != SVt_PVAV)
        croak("free_n: expected arrayref");
    AV *av = (AV *)SvRV(slots_av);
    sv_2mortal(SvREFCNT_inc((SV *)av));   /* pin the arrayref: element magic below cannot free it mid-loop */
    SSize_t len = av_top_index(av) + 1;
    if (len <= 0) {
        RETVAL = 0;
    } else {
        uint64_t *buf;
        Newx(buf, len, uint64_t);
        SAVEFREEPV(buf);  /* freed on scope exit, incl. a croak from SvUV magic */
        for (SSize_t i = 0; i < len; i++) {
            SV **svp = av_fetch(av, i, 0);
            if (svp && *svp) SvGETMAGIC(*svp);   /* a tied-array element is a deferred-magic PVLV */
            if (!svp || !SvOK(*svp))
                croak("free_n: undef slot at index %ld", (long)i);
            buf[i] = (uint64_t)SvUV(*svp);
        }
        REEXTRACT_POOL(self);
        RETVAL = pool_free_n(h, buf, (uint32_t)len);
    }
  OUTPUT:
    RETVAL

SV *
allocated_slots(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    AV *av = newAV();
    uint64_t cap = h->capacity;
    uint32_t nwords = h->bitmap_words;
    for (uint32_t widx = 0; widx < nwords; widx++) {
        uint64_t word = __atomic_load_n(&h->bitmap[widx], __ATOMIC_RELAXED);
        while (word) {
            int bit = __builtin_ctzll(word);
            uint64_t slot = (uint64_t)widx * 64 + bit;
            if (slot < cap)
                av_push(av, newSViv((IV)slot));
            word &= word - 1;
        }
    }
    RETVAL = newRV_noinc((SV *)av);
  OUTPUT:
    RETVAL

UV
ptr(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = PTR2UV(pool_slot_ptr(h, slot));
  OUTPUT:
    RETVAL

UV
data_ptr(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = PTR2UV(h->data);
  OUTPUT:
    RETVAL

SV *
slot_sv(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = newSV(0);
    sv_upgrade(RETVAL, SVt_PV);
    SvPV_set(RETVAL, (char *)pool_slot_ptr(h, slot));
    SvLEN_set(RETVAL, 0);
    SvCUR_set(RETVAL, h->elem_size);
    SvPOK_on(RETVAL);
    /* Pin pool alive while this SV is referenced -- magic before READONLY */
    MAGIC *mg = sv_magicext(RETVAL, NULL, PERL_MAGIC_ext, &pool_scalar_magic_vtbl, NULL, 0);
    /* Pin the REFERENT (the blessed handle), not the container RV: pinning self
     * lets `$pool = undef` still drop the referent -> DESTROY munmaps -> the
     * view SV's PV into the mapping dangles (SEGV).  Guard SvRV(self). */
    mg->mg_obj = SvREFCNT_inc_simple_NN(SvRV(self));
    SvREADONLY_on(RETVAL);
  OUTPUT:
    RETVAL


MODULE = Data::Pool::Shared  PACKAGE = Data::Pool::Shared::I64

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, sizeof(int64_t), POOL_VAR_I64, mode, errbuf);
    if (!h) croak("Data::Pool::Shared::I64->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_create_memfd(name, capacity, sizeof(int64_t), POOL_VAR_I64, errbuf);
    if (!h) croak("Data::Pool::Shared::I64->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_open_fd(fd, POOL_VAR_I64, errbuf);
    if (!h) croak("Data::Pool::Shared::I64->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
get(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_get_i64(h, slot);
  OUTPUT:
    RETVAL

void
set(self, slot, val)
    SV *self
    UV slot
    IV val
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    pool_set_i64(h, slot, (int64_t)val);

bool
cas(self, slot, expected, desired)
    SV *self
    UV slot
    IV expected
    IV desired
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = pool_cas_i64(h, slot, (int64_t)expected, (int64_t)desired);
  OUTPUT:
    RETVAL

IV
cmpxchg(self, slot, expected, desired)
    SV *self
    UV slot
    IV expected
    IV desired
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_cmpxchg_i64(h, slot, (int64_t)expected, (int64_t)desired);
  OUTPUT:
    RETVAL

IV
xchg(self, slot, val)
    SV *self
    UV slot
    IV val
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_xchg_i64(h, slot, (int64_t)val);
  OUTPUT:
    RETVAL

IV
add(self, slot, delta)
    SV *self
    UV slot
    IV delta
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_add_i64(h, slot, (int64_t)delta);
  OUTPUT:
    RETVAL

IV
incr(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_add_i64(h, slot, 1);
  OUTPUT:
    RETVAL

IV
decr(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_add_i64(h, slot, -1);
  OUTPUT:
    RETVAL


MODULE = Data::Pool::Shared  PACKAGE = Data::Pool::Shared::F64

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, sizeof(double), POOL_VAR_F64, mode, errbuf);
    if (!h) croak("Data::Pool::Shared::F64->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_create_memfd(name, capacity, sizeof(double), POOL_VAR_F64, errbuf);
    if (!h) croak("Data::Pool::Shared::F64->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_open_fd(fd, POOL_VAR_F64, errbuf);
    if (!h) croak("Data::Pool::Shared::F64->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

NV
get(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = pool_get_f64(h, slot);
  OUTPUT:
    RETVAL

void
set(self, slot, val)
    SV *self
    UV slot
    NV val
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    pool_set_f64(h, slot, (double)val);


MODULE = Data::Pool::Shared  PACKAGE = Data::Pool::Shared::I32

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    mode_t mode = (items > 3 && (SvGETMAGIC(ST(3)), SvOK(ST(3)))) ? (mode_t)SvUV(ST(3)) : 0600;
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, sizeof(int32_t), POOL_VAR_I32, mode, errbuf);
    if (!h) croak("Data::Pool::Shared::I32->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_create_memfd(name, capacity, sizeof(int32_t), POOL_VAR_I32, errbuf);
    if (!h) croak("Data::Pool::Shared::I32->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_open_fd(fd, POOL_VAR_I32, errbuf);
    if (!h) croak("Data::Pool::Shared::I32->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
get(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_get_i32(h, slot);
  OUTPUT:
    RETVAL

void
set(self, slot, val)
    SV *self
    UV slot
    IV val
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    pool_set_i32(h, slot, (int32_t)val);

bool
cas(self, slot, expected, desired)
    SV *self
    UV slot
    IV expected
    IV desired
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = pool_cas_i32(h, slot, (int32_t)expected, (int32_t)desired);
  OUTPUT:
    RETVAL

IV
cmpxchg(self, slot, expected, desired)
    SV *self
    UV slot
    IV expected
    IV desired
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_cmpxchg_i32(h, slot, (int32_t)expected, (int32_t)desired);
  OUTPUT:
    RETVAL

IV
xchg(self, slot, val)
    SV *self
    UV slot
    IV val
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_xchg_i32(h, slot, (int32_t)val);
  OUTPUT:
    RETVAL

IV
add(self, slot, delta)
    SV *self
    UV slot
    IV delta
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_add_i32(h, slot, (int32_t)delta);
  OUTPUT:
    RETVAL

IV
incr(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_add_i32(h, slot, 1);
  OUTPUT:
    RETVAL

IV
decr(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    RETVAL = (IV)pool_add_i32(h, slot, -1);
  OUTPUT:
    RETVAL


MODULE = Data::Pool::Shared  PACKAGE = Data::Pool::Shared::Str

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, max_len, ...)
    const char *class
    SV *path
    UV capacity
    UV max_len
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    mode_t mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? (mode_t)SvUV(ST(4)) : 0600;
    if (max_len == 0) croak("Data::Pool::Shared::Str->new: max_len must be > 0");
    if (max_len > (UV)(UINT32_MAX - sizeof(uint32_t)))
        croak("Data::Pool::Shared::Str->new: max_len too large");
    uint32_t elem_size = (uint32_t)(sizeof(uint32_t) + max_len);
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, elem_size, POOL_VAR_STR, mode, errbuf);
    if (!h) croak("Data::Pool::Shared::Str->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity, max_len)
    const char *class
    const char *name
    UV capacity
    UV max_len
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    if (max_len == 0) croak("Data::Pool::Shared::Str->new_memfd: max_len must be > 0");
    if (max_len > (UV)(UINT32_MAX - sizeof(uint32_t)))
        croak("Data::Pool::Shared::Str->new_memfd: max_len too large");
    uint32_t elem_size = (uint32_t)(sizeof(uint32_t) + max_len);
    PoolHandle *h = pool_create_memfd(name, capacity, elem_size, POOL_VAR_STR, errbuf);
    if (!h) croak("Data::Pool::Shared::Str->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    PoolHandle *h = pool_open_fd(fd, POOL_VAR_STR, errbuf);
    if (!h) croak("Data::Pool::Shared::Str->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
get(self, slot)
    SV *self
    UV slot
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    uint32_t len = pool_get_str_len(h, slot);
    RETVAL = newSVpvn(pool_get_str_ptr(h, slot), len);
  OUTPUT:
    RETVAL

void
set(self, slot, val)
    SV *self
    UV slot
    SV *val
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    STRLEN len;
    const char *str = SvPV(val, len);
    /* SvPV on a bare SV arg runs overload/tie magic = arbitrary Perl, which can
     * have destroyed self before h is used below. (CHECK_SLOT/CHECK_ALLOCATED
     * above ran on the pre-magic handle; re-validate against the current one.) */
    REEXTRACT_POOL(self);
    CHECK_SLOT(h, slot);
    CHECK_ALLOCATED(h, slot);
    pool_set_str(h, slot, str, (uint32_t)len);

UV
max_len(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = h->hdr->elem_size > sizeof(uint32_t) ? h->hdr->elem_size - sizeof(uint32_t) : 0;
  OUTPUT:
    RETVAL
