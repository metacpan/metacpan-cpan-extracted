#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "ring.h"

#define EXTRACT_RING(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::RingBuffer::Shared")) \
        croak("Expected a Data::RingBuffer::Shared object"); \
    RingHandle *h = INT2PTR(RingHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::RingBuffer::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::RingBuffer::Shared  PACKAGE = Data::RingBuffer::Shared

PROTOTYPES: DISABLE

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    RingHandle *h = INT2PTR(RingHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    ring_destroy(h);

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = (UV)ring_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = (UV)h->hdr->capacity;
  OUTPUT:
    RETVAL

UV
head(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = (UV)ring_head(h);
  OUTPUT:
    RETVAL

UV
count(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&h->hdr->count, __ATOMIC_ACQUIRE);
  OUTPUT:
    RETVAL

bool
wait_for(self, expected_count, ...)
    SV *self
    UV expected_count
  PREINIT:
    EXTRACT_RING(self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    RETVAL = ring_wait(h, expected_count, timeout);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    ring_clear(h);

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = ring_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    RETVAL = ring_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    int64_t v = ring_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    if (ring_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        RingHandle *h = INT2PTR(RingHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        p = h->path;
    } else {
        if (items < 2) croak("Usage: ...->unlink($path)");
        p = SvPV_nolen(ST(1));
    }
    if (!p) croak("cannot unlink anonymous or memfd object");
    if (unlink(p) != 0) croak("unlink(%s): %s", p, strerror(errno));

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    HV *hv = newHV();
    RingHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)ring_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv((UV)hdr->capacity), 0);
    hv_store(hv, "head", 4, newSVuv((UV)ring_head(h)), 0);
    hv_store(hv, "count", 5, newSVuv((UV)__atomic_load_n(&hdr->count, __ATOMIC_ACQUIRE)), 0);
    hv_store(hv, "writes", 6, newSVuv((UV)__atomic_load_n(&hdr->stat_writes, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "overwrites", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_overwrites, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL


MODULE = Data::RingBuffer::Shared  PACKAGE = Data::RingBuffer::Shared::Int

PROTOTYPES: DISABLE

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[RING_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    RingHandle *h = ring_create(p, capacity, sizeof(int64_t), RING_VAR_INT, errbuf);
    if (!h) croak("Data::RingBuffer::Shared::Int->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[RING_ERR_BUFLEN];
  CODE:
    RingHandle *h = ring_create_memfd(name, capacity, sizeof(int64_t), RING_VAR_INT, errbuf);
    if (!h) croak("Data::RingBuffer::Shared::Int->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[RING_ERR_BUFLEN];
  CODE:
    RingHandle *h = ring_open_fd(fd, RING_VAR_INT, errbuf);
    if (!h) croak("Data::RingBuffer::Shared::Int->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

UV
write(self, val)
    SV *self
    IV val
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    int64_t v = (int64_t)val;
    RETVAL = (UV)ring_write(h, &v, sizeof(v));
  OUTPUT:
    RETVAL

SV *
latest(self, ...)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    uint32_t n = (items > 1) ? (uint32_t)SvUV(ST(1)) : 0;
    int64_t v;
    RETVAL = ring_read_latest(h, n, &v) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
read_seq(self, seq)
    SV *self
    UV seq
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    int64_t v;
    RETVAL = ring_read_seq(h, seq, &v) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL


MODULE = Data::RingBuffer::Shared  PACKAGE = Data::RingBuffer::Shared::F64

PROTOTYPES: DISABLE

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[RING_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    RingHandle *h = ring_create(p, capacity, sizeof(double), RING_VAR_F64, errbuf);
    if (!h) croak("Data::RingBuffer::Shared::F64->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[RING_ERR_BUFLEN];
  CODE:
    RingHandle *h = ring_create_memfd(name, capacity, sizeof(double), RING_VAR_F64, errbuf);
    if (!h) croak("Data::RingBuffer::Shared::F64->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[RING_ERR_BUFLEN];
  CODE:
    RingHandle *h = ring_open_fd(fd, RING_VAR_F64, errbuf);
    if (!h) croak("Data::RingBuffer::Shared::F64->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

UV
write(self, val)
    SV *self
    NV val
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    double v = (double)val;
    RETVAL = (UV)ring_write(h, &v, sizeof(v));
  OUTPUT:
    RETVAL

SV *
latest(self, ...)
    SV *self
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    uint32_t n = (items > 1) ? (uint32_t)SvUV(ST(1)) : 0;
    double v;
    RETVAL = ring_read_latest(h, n, &v) ? newSVnv(v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
read_seq(self, seq)
    SV *self
    UV seq
  PREINIT:
    EXTRACT_RING(self);
  CODE:
    double v;
    RETVAL = ring_read_seq(h, seq, &v) ? newSVnv(v) : &PL_sv_undef;
  OUTPUT:
    RETVAL
