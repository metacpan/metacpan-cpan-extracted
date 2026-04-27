#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "heap.h"

#define EXTRACT_HEAP(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Heap::Shared")) \
        croak("Expected a Data::Heap::Shared object"); \
    HeapHandle *h = INT2PTR(HeapHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Heap::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Heap::Shared  PACKAGE = Data::Heap::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[HEAP_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    HeapHandle *h = heap_create(p, capacity, errbuf);
    if (!h) croak("Data::Heap::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[HEAP_ERR_BUFLEN];
  CODE:
    HeapHandle *h = heap_create_memfd(name, capacity, errbuf);
    if (!h) croak("Data::Heap::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[HEAP_ERR_BUFLEN];
  CODE:
    HeapHandle *h = heap_open_fd(fd, errbuf);
    if (!h) croak("Data::Heap::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    HeapHandle *h = INT2PTR(HeapHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    heap_destroy(h);

bool
push(self, priority, value)
    SV *self
    IV priority
    IV value
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = heap_push(h, (int64_t)priority, (int64_t)value);
  OUTPUT:
    RETVAL

void
pop(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  PPCODE:
    int64_t p, v;
    if (heap_pop(h, &p, &v)) {
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv((IV)p)));
        PUSHs(sv_2mortal(newSViv((IV)v)));
    }

void
pop_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
    double timeout = -1;
  PPCODE:
    if (items > 1) timeout = SvNV(ST(1));
    int64_t p, v;
    if (heap_pop_wait(h, &p, &v, timeout)) {
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv((IV)p)));
        PUSHs(sv_2mortal(newSViv((IV)v)));
    }

void
peek(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  PPCODE:
    int64_t p, v;
    if (heap_peek(h, &p, &v)) {
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv((IV)p)));
        PUSHs(sv_2mortal(newSViv((IV)v)));
    }

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = heap_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = (UV)h->hdr->capacity;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = heap_size(h) == 0;
  OUTPUT:
    RETVAL

bool
is_full(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = heap_size(h) >= (UV)h->hdr->capacity;
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    heap_clear(h);

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = heap_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    RETVAL = heap_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    int64_t v = heap_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HEAP(self);
  CODE:
    if (heap_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        HeapHandle *h = INT2PTR(HeapHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_HEAP(self);
  CODE:
    HV *hv = newHV();
    HeapHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv(heap_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv((UV)hdr->capacity), 0);
    hv_store(hv, "pushes", 6, newSVuv((UV)__atomic_load_n(&hdr->stat_pushes, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pops", 4, newSVuv((UV)__atomic_load_n(&hdr->stat_pops, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL
