#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "sync.h"

#define EXTRACT_HANDLE(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed %s object", classname)

#define MAKE_OBJ(class, handle) \
    SV *obj = newSViv(PTR2IV(handle)); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::Sync::Shared  PACKAGE = Data::Sync::Shared::Semaphore

PROTOTYPES: DISABLE

SV *
new(class, path, max, ...)
    const char *class
    SV *path
    UV max
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    uint32_t initial = (items > 3) ? (uint32_t)SvUV(ST(3)) : (uint32_t)max;
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    SyncHandle *h = sync_create(p, SYNC_TYPE_SEMAPHORE, (uint32_t)max, initial, errbuf);
    if (!h) croak("Data::Sync::Shared::Semaphore->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, max, ...)
    const char *class
    const char *name
    UV max
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    uint32_t initial = (items > 3) ? (uint32_t)SvUV(ST(3)) : (uint32_t)max;
    SyncHandle *h = sync_create_memfd(name, SYNC_TYPE_SEMAPHORE, (uint32_t)max, initial, errbuf);
    if (!h) croak("Data::Sync::Shared::Semaphore->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_open_fd(fd, SYNC_TYPE_SEMAPHORE, errbuf);
    if (!h) croak("Data::Sync::Shared::Semaphore->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    sync_destroy(h);

bool
acquire(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    RETVAL = sync_sem_acquire(h, timeout);
  OUTPUT:
    RETVAL

bool
try_acquire(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = sync_sem_try_acquire(h);
  OUTPUT:
    RETVAL

bool
acquire_n(self, n, ...)
    SV *self
    UV n
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    RETVAL = sync_sem_acquire_n(h, (uint32_t)n, timeout);
  OUTPUT:
    RETVAL

bool
try_acquire_n(self, n)
    SV *self
    UV n
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = sync_sem_try_acquire_n(h, (uint32_t)n);
  OUTPUT:
    RETVAL

void
release(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    if (items > 1) {
        uint32_t n = (uint32_t)SvUV(ST(1));
        sync_sem_release_n(h, n);
    } else {
        sync_sem_release(h);
    }

UV
drain(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = sync_sem_drain(h);
  OUTPUT:
    RETVAL

UV
value(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = sync_sem_value(h);
  OUTPUT:
    RETVAL

UV
max(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = h->hdr->param;
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = sync_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    RETVAL = sync_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    int64_t v = sync_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    if (sync_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_HANDLE("Data::Sync::Shared::Semaphore", self);
  CODE:
    HV *hv = newHV();
    SyncHeader *hdr = h->hdr;
    hv_store(hv, "value", 5, newSVuv(sync_sem_value(h)), 0);
    hv_store(hv, "max", 3, newSVuv(hdr->param), 0);
    hv_store(hv, "waiters", 7, newSVuv((UV)__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "acquires", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_acquires, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "releases", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_releases, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

MODULE = Data::Sync::Shared  PACKAGE = Data::Sync::Shared::Barrier

PROTOTYPES: DISABLE

SV *
new(class, path, parties)
    const char *class
    SV *path
    UV parties
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    SyncHandle *h = sync_create(p, SYNC_TYPE_BARRIER, (uint32_t)parties, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::Barrier->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, parties)
    const char *class
    const char *name
    UV parties
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_create_memfd(name, SYNC_TYPE_BARRIER, (uint32_t)parties, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::Barrier->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_open_fd(fd, SYNC_TYPE_BARRIER, errbuf);
    if (!h) croak("Data::Sync::Shared::Barrier->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    sync_destroy(h);

IV
wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    RETVAL = sync_barrier_wait(h, timeout);
  OUTPUT:
    RETVAL

UV
generation(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = sync_barrier_generation(h);
  OUTPUT:
    RETVAL

UV
arrived(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = sync_barrier_arrived(h);
  OUTPUT:
    RETVAL

UV
parties(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = h->hdr->param;
  OUTPUT:
    RETVAL

bool
is_broken(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = sync_barrier_is_broken(h) ? 1 : 0;
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    sync_barrier_reset(h);

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = sync_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    RETVAL = sync_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    int64_t v = sync_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    if (sync_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_HANDLE("Data::Sync::Shared::Barrier", self);
  CODE:
    HV *hv = newHV();
    SyncHeader *hdr = h->hdr;
    hv_store(hv, "parties", 7, newSVuv(hdr->param), 0);
    hv_store(hv, "arrived", 7, newSVuv(sync_barrier_arrived(h)), 0);
    hv_store(hv, "generation", 10, newSVuv(sync_barrier_generation(h)), 0);
    hv_store(hv, "waiters", 7, newSVuv((UV)__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "releases", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_releases, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

MODULE = Data::Sync::Shared  PACKAGE = Data::Sync::Shared::RWLock

PROTOTYPES: DISABLE

SV *
new(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    SyncHandle *h = sync_create(p, SYNC_TYPE_RWLOCK, 0, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::RWLock->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name)
    const char *class
    const char *name
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_create_memfd(name, SYNC_TYPE_RWLOCK, 0, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::RWLock->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_open_fd(fd, SYNC_TYPE_RWLOCK, errbuf);
    if (!h) croak("Data::Sync::Shared::RWLock->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    sync_destroy(h);

void
rdlock(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    if (items > 1) {
        double timeout = SvNV(ST(1));
        if (!sync_rwlock_rdlock_timed(h->hdr, timeout))
            croak("rdlock: timeout");
    } else {
        sync_rwlock_rdlock(h->hdr);
    }
    __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);

bool
try_rdlock(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = sync_rwlock_try_rdlock(h->hdr);
    if (RETVAL)
        __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

bool
rdlock_timed(self, timeout)
    SV *self
    double timeout
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = sync_rwlock_rdlock_timed(h->hdr, timeout);
    if (RETVAL)
        __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

void
rdunlock(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    sync_rwlock_rdunlock(h->hdr);
    __atomic_add_fetch(&h->hdr->stat_releases, 1, __ATOMIC_RELAXED);

void
wrlock(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    if (items > 1) {
        double timeout = SvNV(ST(1));
        if (!sync_rwlock_wrlock_timed(h->hdr, timeout))
            croak("wrlock: timeout");
    } else {
        sync_rwlock_wrlock(h->hdr);
    }
    __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);

bool
try_wrlock(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = sync_rwlock_try_wrlock(h->hdr);
    if (RETVAL)
        __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

bool
wrlock_timed(self, timeout)
    SV *self
    double timeout
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = sync_rwlock_wrlock_timed(h->hdr, timeout);
    if (RETVAL)
        __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

void
wrunlock(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    sync_rwlock_wrunlock(h->hdr);
    __atomic_add_fetch(&h->hdr->stat_releases, 1, __ATOMIC_RELAXED);

void
downgrade(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    sync_rwlock_downgrade(h->hdr);
    __atomic_add_fetch(&h->hdr->stat_releases, 1, __ATOMIC_RELAXED);
    __atomic_add_fetch(&h->hdr->stat_acquires, 1, __ATOMIC_RELAXED);

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = sync_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    RETVAL = sync_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    int64_t v = sync_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    if (sync_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_HANDLE("Data::Sync::Shared::RWLock", self);
  CODE:
    HV *hv = newHV();
    SyncHeader *hdr = h->hdr;
    uint32_t val = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
    const char *state;
    if (val == 0) state = "unlocked";
    else if (val < SYNC_RWLOCK_WRITER_BIT) state = "read_locked";
    else state = "write_locked";
    hv_store(hv, "state", 5, newSVpv(state, 0), 0);
    hv_store(hv, "readers", 7,
        newSVuv(val < SYNC_RWLOCK_WRITER_BIT ? val : 0), 0);
    hv_store(hv, "waiters", 7, newSVuv((UV)__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "acquires", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_acquires, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "releases", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_releases, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

MODULE = Data::Sync::Shared  PACKAGE = Data::Sync::Shared::Condvar

PROTOTYPES: DISABLE

SV *
new(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    SyncHandle *h = sync_create(p, SYNC_TYPE_CONDVAR, 0, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::Condvar->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name)
    const char *class
    const char *name
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_create_memfd(name, SYNC_TYPE_CONDVAR, 0, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::Condvar->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_open_fd(fd, SYNC_TYPE_CONDVAR, errbuf);
    if (!h) croak("Data::Sync::Shared::Condvar->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    sync_destroy(h);

void
lock(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    sync_condvar_lock(h);

bool
try_lock(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    RETVAL = sync_condvar_try_lock(h);
  OUTPUT:
    RETVAL

void
unlock(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    sync_condvar_unlock(h);

bool
wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    RETVAL = sync_condvar_wait(h, timeout);
  OUTPUT:
    RETVAL

void
signal(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    sync_condvar_signal(h);

void
broadcast(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    sync_condvar_broadcast(h);

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    RETVAL = sync_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    RETVAL = sync_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    int64_t v = sync_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    if (sync_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_HANDLE("Data::Sync::Shared::Condvar", self);
  CODE:
    HV *hv = newHV();
    SyncHeader *hdr = h->hdr;
    hv_store(hv, "waiters", 7, newSVuv((UV)__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "signals", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_signals, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "acquires", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_acquires, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "releases", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_releases, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

MODULE = Data::Sync::Shared  PACKAGE = Data::Sync::Shared::Once

PROTOTYPES: DISABLE

SV *
new(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    SyncHandle *h = sync_create(p, SYNC_TYPE_ONCE, 0, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::Once->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name)
    const char *class
    const char *name
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_create_memfd(name, SYNC_TYPE_ONCE, 0, 0, errbuf);
    if (!h) croak("Data::Sync::Shared::Once->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[SYNC_ERR_BUFLEN];
  CODE:
    SyncHandle *h = sync_open_fd(fd, SYNC_TYPE_ONCE, errbuf);
    if (!h) croak("Data::Sync::Shared::Once->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    sync_destroy(h);

bool
enter(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
    double timeout = -1;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    RETVAL = sync_once_enter(h, timeout);
  OUTPUT:
    RETVAL

void
done(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    sync_once_done(h);

bool
is_done(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    RETVAL = sync_once_is_done(h);
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    sync_once_reset(h);

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    RETVAL = sync_create_eventfd(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    if (h->notify_fd >= 0 && h->notify_fd != fd) close(h->notify_fd);
    h->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

bool
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    RETVAL = sync_notify(h);
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    int64_t v = sync_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    if (sync_msync(h) != 0) croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *p;
    if (sv_isobject(self_or_class)) {
        SyncHandle *h = INT2PTR(SyncHandle*, SvIV(SvRV(self_or_class)));
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
    EXTRACT_HANDLE("Data::Sync::Shared::Once", self);
  CODE:
    HV *hv = newHV();
    SyncHeader *hdr = h->hdr;
    const char *state;
    uint32_t val = __atomic_load_n(&hdr->value, __ATOMIC_RELAXED);
    if (val == SYNC_ONCE_INIT) state = "init";
    else if (val == SYNC_ONCE_DONE) state = "done";
    else state = "running";
    hv_store(hv, "state", 5, newSVpv(state, 0), 0);
    hv_store(hv, "is_done", 7, newSVuv(val == SYNC_ONCE_DONE), 0);
    hv_store(hv, "waiters", 7, newSVuv((UV)__atomic_load_n(&hdr->waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "acquires", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_acquires, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "releases", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_releases, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "waits", 5, newSVuv((UV)__atomic_load_n(&hdr->stat_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "timeouts", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL
