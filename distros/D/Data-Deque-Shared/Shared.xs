#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "deque.h"

#define EXTRACT_DEQ(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Deque::Shared")) \
        croak("Expected a Data::Deque::Shared object"); \
    DeqHandle *h = INT2PTR(DeqHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Deque::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Deque::Shared  PACKAGE = Data::Deque::Shared

PROTOTYPES: DISABLE

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    DeqHandle *h = INT2PTR(DeqHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    deq_destroy(h);

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = (UV)deq_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = (UV)h->hdr->capacity;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = deq_size(h) == 0;
  OUTPUT:
    RETVAL

bool
is_full(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = deq_size(h) >= h->hdr->capacity;
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    deq_clear(h);

UV
drain(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = (UV)deq_drain(h);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = deq_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    RETVAL = deq_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    int64_t v = deq_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    if (deq_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        DeqHandle *h = INT2PTR(DeqHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_DEQ(self);
  CODE:
    HV *hv = newHV();
    DeqHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)deq_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv((UV)hdr->capacity), 0);
    hv_store(hv, "pushes", 6, newSVuv((UV)__atomic_load_n(&hdr->stat_pushes, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pops", 4, newSVuv((UV)__atomic_load_n(&hdr->stat_pops, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL


MODULE = Data::Deque::Shared  PACKAGE = Data::Deque::Shared::Int

PROTOTYPES: DISABLE

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[DEQ_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    DeqHandle *h = deq_create(p, capacity, sizeof(int64_t), DEQ_VAR_INT, errbuf);
    if (!h) croak("Data::Deque::Shared::Int->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[DEQ_ERR_BUFLEN];
  CODE:
    DeqHandle *h = deq_create_memfd(name, capacity, sizeof(int64_t), DEQ_VAR_INT, errbuf);
    if (!h) croak("Data::Deque::Shared::Int->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[DEQ_ERR_BUFLEN];
  CODE:
    DeqHandle *h = deq_open_fd(fd, DEQ_VAR_INT, errbuf);
    if (!h) croak("Data::Deque::Shared::Int->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

bool
push_back(self, val)
    SV *self
    IV val
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    int64_t v = (int64_t)val;
    RETVAL = deq_try_push_back(h, &v, sizeof(v));
  OUTPUT:
    RETVAL

bool
push_front(self, val)
    SV *self
    IV val
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    int64_t v = (int64_t)val;
    RETVAL = deq_try_push_front(h, &v, sizeof(v));
  OUTPUT:
    RETVAL

bool
push_back_wait(self, val, ...)
    SV *self
    IV val
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    int64_t v = (int64_t)val;
    RETVAL = deq_push_wait(h, &v, sizeof(v), 0, timeout);
  OUTPUT:
    RETVAL

bool
push_front_wait(self, val, ...)
    SV *self
    IV val
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    int64_t v = (int64_t)val;
    RETVAL = deq_push_wait(h, &v, sizeof(v), 1, timeout);
  OUTPUT:
    RETVAL

SV *
pop_front(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    int64_t v;
    RETVAL = deq_try_pop_front(h, &v) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
pop_back(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    int64_t v;
    RETVAL = deq_try_pop_back(h, &v) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
pop_front_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int64_t v;
    RETVAL = deq_pop_wait(h, &v, 0, timeout) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
pop_back_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int64_t v;
    RETVAL = deq_pop_wait(h, &v, 1, timeout) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

MODULE = Data::Deque::Shared  PACKAGE = Data::Deque::Shared::Str

PROTOTYPES: DISABLE

SV *
new(class, path, capacity, max_len)
    const char *class
    SV *path
    UV capacity
    UV max_len
  PREINIT:
    char errbuf[DEQ_ERR_BUFLEN];
  CODE:
    if (max_len == 0) croak("max_len must be > 0");
    if (max_len > (UV)(UINT32_MAX - sizeof(uint32_t)))
        croak("max_len too large");
    uint32_t elem_size = (uint32_t)(sizeof(uint32_t) + max_len);
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    DeqHandle *h = deq_create(p, capacity, elem_size, DEQ_VAR_STR, errbuf);
    if (!h) croak("Data::Deque::Shared::Str->new: %s", errbuf);
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
    char errbuf[DEQ_ERR_BUFLEN];
  CODE:
    if (max_len == 0) croak("max_len must be > 0");
    if (max_len > (UV)(UINT32_MAX - sizeof(uint32_t)))
        croak("max_len too large");
    uint32_t elem_size = (uint32_t)(sizeof(uint32_t) + max_len);
    DeqHandle *h = deq_create_memfd(name, capacity, elem_size, DEQ_VAR_STR, errbuf);
    if (!h) croak("Data::Deque::Shared::Str->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[DEQ_ERR_BUFLEN];
  CODE:
    DeqHandle *h = deq_open_fd(fd, DEQ_VAR_STR, errbuf);
    if (!h) croak("Data::Deque::Shared::Str->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

bool
push_back(self, val)
    SV *self
    SV *val
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    STRLEN slen;
    const char *s = SvPV(val, slen);
    uint32_t max_len = h->elem_size - sizeof(uint32_t);
    if (slen > max_len) slen = max_len;
    uint8_t *buf;
    Newxz(buf, h->elem_size, uint8_t);
    uint32_t l32 = (uint32_t)slen;
    memcpy(buf, &l32, sizeof(uint32_t));
    memcpy(buf + sizeof(uint32_t), s, slen);
    RETVAL = deq_try_push_back(h, buf, h->elem_size);
    Safefree(buf);
  OUTPUT:
    RETVAL

bool
push_front(self, val)
    SV *self
    SV *val
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    STRLEN slen;
    const char *s = SvPV(val, slen);
    uint32_t max_len = h->elem_size - sizeof(uint32_t);
    if (slen > max_len) slen = max_len;
    uint8_t *buf;
    Newxz(buf, h->elem_size, uint8_t);
    uint32_t l32 = (uint32_t)slen;
    memcpy(buf, &l32, sizeof(uint32_t));
    memcpy(buf + sizeof(uint32_t), s, slen);
    RETVAL = deq_try_push_front(h, buf, h->elem_size);
    Safefree(buf);
  OUTPUT:
    RETVAL

bool
push_back_wait(self, val, ...)
    SV *self
    SV *val
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    STRLEN slen;
    const char *s = SvPV(val, slen);
    uint32_t max_len = h->elem_size - sizeof(uint32_t);
    if (slen > max_len) slen = max_len;
    uint8_t *buf;
    Newxz(buf, h->elem_size, uint8_t);
    uint32_t l32 = (uint32_t)slen;
    memcpy(buf, &l32, sizeof(uint32_t));
    memcpy(buf + sizeof(uint32_t), s, slen);
    RETVAL = deq_push_wait(h, buf, h->elem_size, 0, timeout);
    Safefree(buf);
  OUTPUT:
    RETVAL

bool
push_front_wait(self, val, ...)
    SV *self
    SV *val
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    STRLEN slen;
    const char *s = SvPV(val, slen);
    uint32_t max_len = h->elem_size - sizeof(uint32_t);
    if (slen > max_len) slen = max_len;
    uint8_t *buf;
    Newxz(buf, h->elem_size, uint8_t);
    uint32_t l32 = (uint32_t)slen;
    memcpy(buf, &l32, sizeof(uint32_t));
    memcpy(buf + sizeof(uint32_t), s, slen);
    RETVAL = deq_push_wait(h, buf, h->elem_size, 1, timeout);
    Safefree(buf);
  OUTPUT:
    RETVAL

SV *
pop_front(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    uint8_t *buf;
    Newx(buf, h->elem_size, uint8_t);
    if (deq_try_pop_front(h, buf)) {
        uint32_t len;
        memcpy(&len, buf, sizeof(uint32_t));
        uint32_t max_len = h->elem_size - sizeof(uint32_t);
        if (len > max_len) len = max_len;
        RETVAL = newSVpvn((char *)buf + sizeof(uint32_t), len);
    } else {
        RETVAL = &PL_sv_undef;
    }
    Safefree(buf);
  OUTPUT:
    RETVAL

SV *
pop_back(self)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
  CODE:
    uint8_t *buf;
    Newx(buf, h->elem_size, uint8_t);
    if (deq_try_pop_back(h, buf)) {
        uint32_t len;
        memcpy(&len, buf, sizeof(uint32_t));
        uint32_t max_len = h->elem_size - sizeof(uint32_t);
        if (len > max_len) len = max_len;
        RETVAL = newSVpvn((char *)buf + sizeof(uint32_t), len);
    } else {
        RETVAL = &PL_sv_undef;
    }
    Safefree(buf);
  OUTPUT:
    RETVAL

SV *
pop_front_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    uint8_t *buf;
    Newx(buf, h->elem_size, uint8_t);
    if (deq_pop_wait(h, buf, 0, timeout)) {
        uint32_t len;
        memcpy(&len, buf, sizeof(uint32_t));
        uint32_t max_len = h->elem_size - sizeof(uint32_t);
        if (len > max_len) len = max_len;
        RETVAL = newSVpvn((char *)buf + sizeof(uint32_t), len);
    } else {
        RETVAL = &PL_sv_undef;
    }
    Safefree(buf);
  OUTPUT:
    RETVAL

SV *
pop_back_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_DEQ(self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    uint8_t *buf;
    Newx(buf, h->elem_size, uint8_t);
    if (deq_pop_wait(h, buf, 1, timeout)) {
        uint32_t len;
        memcpy(&len, buf, sizeof(uint32_t));
        uint32_t max_len = h->elem_size - sizeof(uint32_t);
        if (len > max_len) len = max_len;
        RETVAL = newSVpvn((char *)buf + sizeof(uint32_t), len);
    } else {
        RETVAL = &PL_sv_undef;
    }
    Safefree(buf);
  OUTPUT:
    RETVAL
