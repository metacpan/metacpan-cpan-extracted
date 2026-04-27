#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "log.h"

#define EXTRACT_LOG(sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, "Data::Log::Shared")) \
        croak("Expected a Data::Log::Shared object"); \
    LogHandle *h = INT2PTR(LogHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed Data::Log::Shared object")

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Log::Shared  PACKAGE = Data::Log::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, data_size)
    const char *class
    SV *path
    UV data_size
  PREINIT:
    char errbuf[LOG_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    LogHandle *h = log_create(p, data_size, errbuf);
    if (!h) croak("Data::Log::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, data_size)
    const char *class
    const char *name
    UV data_size
  PREINIT:
    char errbuf[LOG_ERR_BUFLEN];
  CODE:
    LogHandle *h = log_create_memfd(name, data_size, errbuf);
    if (!h) croak("Data::Log::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[LOG_ERR_BUFLEN];
  CODE:
    LogHandle *h = log_open_fd(fd, errbuf);
    if (!h) croak("Data::Log::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    LogHandle *h = INT2PTR(LogHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    log_destroy(h);

SV *
append(self, data)
    SV *self
    SV *data
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    STRLEN len;
    const char *buf = SvPV(data, len);
    if (len == 0) croak("append: data must not be empty");
    if (len > (STRLEN)(UINT32_MAX - LOG_ENTRY_HDR - 3))
        croak("append: data too large");
    int64_t off = log_append(h, buf, (uint32_t)len);
    RETVAL = (off >= 0) ? newSViv((IV)off) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
read_entry(self, offset)
    SV *self
    UV offset
  PREINIT:
    EXTRACT_LOG(self);
  PPCODE:
    const uint8_t *out_data;
    uint32_t out_len;
    uint64_t next_off;
    if (log_read(h, offset, &out_data, &out_len, &next_off)) {
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVpvn((const char *)out_data, out_len)));
        PUSHs(sv_2mortal(newSVuv((UV)next_off)));
    }

UV
tail_offset(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = (UV)log_tail_offset(h);
  OUTPUT:
    RETVAL

UV
entry_count(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = (UV)log_entry_count(h);
  OUTPUT:
    RETVAL

UV
data_size(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = (UV)log_data_size(h);
  OUTPUT:
    RETVAL

UV
available(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = (UV)log_available(h);
  OUTPUT:
    RETVAL

bool
wait_for(self, expected_count, ...)
    SV *self
    UV expected_count
  PREINIT:
    EXTRACT_LOG(self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    RETVAL = log_wait(h, expected_count, timeout);
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    log_reset(h);

void
truncate(self, offset)
    SV *self
    UV offset
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    log_truncate(h, (uint64_t)offset);

UV
truncation(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = (UV)log_truncation(h);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = log_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    RETVAL = log_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    int64_t v = log_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_LOG(self);
  CODE:
    if (log_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        LogHandle *h = INT2PTR(LogHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_LOG(self);
  CODE:
    HV *hv = newHV();
    LogHeader *hdr = h->hdr;
    hv_store(hv, "data_size", 9, newSVuv((UV)hdr->data_size), 0);
    hv_store(hv, "tail", 4, newSVuv((UV)log_tail_offset(h)), 0);
    hv_store(hv, "count", 5, newSVuv((UV)log_entry_count(h)), 0);
    hv_store(hv, "available", 9, newSVuv((UV)log_available(h)), 0);
    hv_store(hv, "waiters", 7, newSVuv(__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "appends", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_appends, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL
