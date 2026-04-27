#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "pool.h"

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

#define EXTRACT_POOL(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Pool::Shared")) \
        croak("Expected a Data::Pool::Shared object"); \
    PoolHandle *h = INT2PTR(PoolHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Pool::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define CHECK_SLOT(h, slot) \
    if ((UV)(slot) >= (h)->hdr->capacity) \
        croak("slot %" UVuf " out of range (capacity %" UVuf ")", \
              (UV)(slot), (UV)(h)->hdr->capacity)

#define CHECK_ALLOCATED(h, slot) \
    if (!pool_is_allocated(h, slot)) \
        croak("slot %" UVuf " is not allocated", (UV)(slot))


MODULE = Data::Pool::Shared  PACKAGE = Data::Pool::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, elem_size)
    const char *class
    SV *path
    UV capacity
    UV elem_size
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, (uint32_t)elem_size, POOL_VAR_RAW, errbuf);
    if (!h) croak("Data::Pool::Shared->new: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared->new_memfd: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
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
    if (items > 1) timeout = SvNV(ST(1));
    int64_t slot = pool_alloc(h, timeout);
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
    RETVAL = newSVpvn((const char *)pool_slot_ptr(h, slot), h->hdr->elem_size);
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
    if (len > h->hdr->elem_size)
        len = h->hdr->elem_size;
    memcpy(pool_slot_ptr(h, slot), bytes, len);
    if (len < h->hdr->elem_size)
        memset(pool_slot_ptr(h, slot) + len, 0, h->hdr->elem_size - len);

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
    RETVAL = (UV)h->hdr->capacity - __atomic_load_n(&h->hdr->used, __ATOMIC_RELAXED);
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
    RETVAL = __atomic_load_n(&h->owners[slot], __ATOMIC_RELAXED);
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
    if (sv_isobject(self_or_class)) {
        PoolHandle *h = INT2PTR(PoolHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        p = h->path;
    } else {
        if (items < 2) croak("Usage: ...->unlink($path)");
        p = SvPV_nolen(ST(1));
    }
    if (!p) croak("cannot unlink anonymous or memfd object");
    if (unlink(p) != 0)
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
        newSVuv((UV)hdr->capacity - (UV)__atomic_load_n(&hdr->used, __ATOMIC_RELAXED)), 0);
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
    if (items > 2) timeout = SvNV(ST(2));
    if (count == 0) {
        RETVAL = newRV_noinc((SV *)newAV());
    } else {
        uint64_t *buf;
        Newx(buf, count, uint64_t);
        if (pool_alloc_n(h, buf, (uint32_t)count, timeout)) {
            AV *av = newAV();
            av_extend(av, count - 1);
            for (UV i = 0; i < count; i++)
                av_push(av, newSViv((IV)buf[i]));
            RETVAL = newRV_noinc((SV *)av);
        } else {
            RETVAL = &PL_sv_undef;
        }
        Safefree(buf);
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
    if (!SvROK(slots_av) || SvTYPE(SvRV(slots_av)) != SVt_PVAV)
        croak("free_n: expected arrayref");
    AV *av = (AV *)SvRV(slots_av);
    SSize_t len = av_top_index(av) + 1;
    if (len <= 0) {
        RETVAL = 0;
    } else {
        uint64_t *buf;
        Newx(buf, len, uint64_t);
        for (SSize_t i = 0; i < len; i++) {
            SV **svp = av_fetch(av, i, 0);
            if (!svp || !SvOK(*svp)) {
                Safefree(buf);
                croak("free_n: undef slot at index %ld", (long)i);
            }
            buf[i] = (uint64_t)SvUV(*svp);
        }
        RETVAL = pool_free_n(h, buf, (uint32_t)len);
        Safefree(buf);
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
    uint64_t cap = h->hdr->capacity;
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
    SvCUR_set(RETVAL, h->hdr->elem_size);
    SvPOK_on(RETVAL);
    /* Pin pool alive while this SV is referenced — magic before READONLY */
    MAGIC *mg = sv_magicext(RETVAL, NULL, PERL_MAGIC_ext, &pool_scalar_magic_vtbl, NULL, 0);
    mg->mg_obj = SvREFCNT_inc_simple_NN(self);
    SvREADONLY_on(RETVAL);
  OUTPUT:
    RETVAL


MODULE = Data::Pool::Shared  PACKAGE = Data::Pool::Shared::I64

PROTOTYPES: DISABLE

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, sizeof(int64_t), POOL_VAR_I64, errbuf);
    if (!h) croak("Data::Pool::Shared::I64->new: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::I64->new_memfd: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::I64->new_from_fd: %s", errbuf);
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
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, sizeof(double), POOL_VAR_F64, errbuf);
    if (!h) croak("Data::Pool::Shared::F64->new: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::F64->new_memfd: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::F64->new_from_fd: %s", errbuf);
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
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, sizeof(int32_t), POOL_VAR_I32, errbuf);
    if (!h) croak("Data::Pool::Shared::I32->new: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::I32->new_memfd: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::I32->new_from_fd: %s", errbuf);
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
new(class, path, capacity, max_len)
    const char *class
    SV *path
    UV capacity
    UV max_len
  PREINIT:
    char errbuf[POOL_ERR_BUFLEN];
  CODE:
    if (max_len == 0) croak("Data::Pool::Shared::Str->new: max_len must be > 0");
    if (max_len > (UV)(UINT32_MAX - sizeof(uint32_t)))
        croak("Data::Pool::Shared::Str->new: max_len too large");
    uint32_t elem_size = (uint32_t)(sizeof(uint32_t) + max_len);
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PoolHandle *h = pool_create(p, capacity, elem_size, POOL_VAR_STR, errbuf);
    if (!h) croak("Data::Pool::Shared::Str->new: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::Str->new_memfd: %s", errbuf);
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
    if (!h) croak("Data::Pool::Shared::Str->new_from_fd: %s", errbuf);
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
    pool_set_str(h, slot, str, (uint32_t)len);

UV
max_len(self)
    SV *self
  PREINIT:
    EXTRACT_POOL(self);
  CODE:
    RETVAL = h->hdr->elem_size - sizeof(uint32_t);
  OUTPUT:
    RETVAL
