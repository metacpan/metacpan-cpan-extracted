#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "reqrep.h"

#define EXTRACT_HANDLE(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    ReqRepHandle *h = INT2PTR(ReqRepHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed %s object", classname)

#define MAKE_OBJ(class, ptr) \
    SV *ref = newRV_noinc(newSViv(PTR2IV(ptr))); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

MODULE = Data::ReqRep::Shared  PACKAGE = Data::ReqRep::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, req_cap, resp_slots, resp_size, ...)
    const char *class
    SV *path
    UV req_cap
    UV resp_slots
    UV resp_size
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
    uint64_t arena_cap;
  CODE:
    arena_cap = (items > 5) ? (uint64_t)SvUV(ST(5)) : 0;
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    ReqRepHandle *h = reqrep_create(p, (uint32_t)req_cap, (uint32_t)resp_slots,
                                     (uint32_t)resp_size, arena_cap, errbuf);
    if (!h) croak("Data::ReqRep::Shared->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, req_cap, resp_slots, resp_size, ...)
    const char *class
    const char *name
    UV req_cap
    UV resp_slots
    UV resp_size
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
    uint64_t arena_cap;
  CODE:
    arena_cap = (items > 5) ? (uint64_t)SvUV(ST(5)) : 0;
    ReqRepHandle *h = reqrep_create_memfd(name, (uint32_t)req_cap, (uint32_t)resp_slots,
                                           (uint32_t)resp_size, arena_cap, errbuf);
    if (!h) croak("Data::ReqRep::Shared->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(fd, REQREP_MODE_STR, errbuf);
    if (!h) croak("Data::ReqRep::Shared->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    ReqRepHandle *h = INT2PTR(ReqRepHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    reqrep_destroy(h);

void
recv(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
    const char *str;
    uint32_t len;
    uint64_t id;
    bool utf8;
  PPCODE:
    int r = reqrep_try_recv(h, &str, &len, &utf8, &id);
    if (r == -1) croak("Data::ReqRep::Shared: out of memory");
    if (r == 1) {
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
        mXPUSHu((UV)id);
    }

void
recv_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    uint64_t id;
    bool utf8;
  PPCODE:
    if (items > 1) timeout = SvNV(ST(1));
    int r = reqrep_recv_wait(h, &str, &len, &utf8, &id, timeout);
    if (r == -1) croak("Data::ReqRep::Shared: out of memory");
    if (r == 1) {
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
        mXPUSHu((UV)id);
    }

void
recv_multi(self, count)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
    const char *str;
    uint32_t len;
    uint64_t id;
    bool utf8;
  PPCODE:
    /* Hoist Perl SV construction out of process-shared futex mutex. */
    struct { char *buf; uint32_t len; uint64_t id; bool utf8; } *items_buf = NULL;
    UV n = 0;
    int last_r = 0;
    int oom = 0;
    if (count > 0) {
        items_buf = (void *)malloc((size_t)count * sizeof(*items_buf));
        if (!items_buf) croak("Data::ReqRep::Shared: out of memory");
    }
    reqrep_mutex_lock(h->hdr);
    for (UV i = 0; i < count; i++) {
        last_r = reqrep_recv_locked(h, &str, &len, &utf8, &id);
        if (last_r <= 0) break;
        char *c = (char *)malloc(len ? len : 1);
        if (!c) { oom = 1; break; }
        if (len) memcpy(c, str, len);
        items_buf[n].buf = c;
        items_buf[n].len = len;
        items_buf[n].id = id;
        items_buf[n].utf8 = utf8;
        n++;
    }
    reqrep_mutex_unlock(h->hdr);
    reqrep_wake_producers(h->hdr);
    EXTEND(SP, (SSize_t)(2 * n));
    for (UV j = 0; j < n; j++) {
        SV *sv = newSVpvn(items_buf[j].buf, items_buf[j].len);
        if (items_buf[j].utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)items_buf[j].id)));
        free(items_buf[j].buf);
    }
    free(items_buf);
    if (last_r == -1 || oom) croak("Data::ReqRep::Shared: out of memory");

void
recv_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    uint64_t id;
    bool utf8;
  PPCODE:
    if (items > 2) timeout = SvNV(ST(2));
    /* Block until at least 1 */
    int r = reqrep_recv_wait(h, &str, &len, &utf8, &id, timeout);
    if (r == -1) croak("Data::ReqRep::Shared: out of memory");
    if (r != 1) XSRETURN(0);
    {
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
        mXPUSHu((UV)id);
    }
    /* Grab up to count-1 more non-blocking — hoist SV construction out of lock. */
    struct { char *buf; uint32_t len; uint64_t id; bool utf8; } *items_buf = NULL;
    UV n = 0;
    int last_r2 = 0;
    int oom = 0;
    if (count > 1) {
        items_buf = (void *)malloc((size_t)(count - 1) * sizeof(*items_buf));
        if (!items_buf) croak("Data::ReqRep::Shared: out of memory");
    }
    reqrep_mutex_lock(h->hdr);
    for (UV i = 1; i < count; i++) {
        last_r2 = reqrep_recv_locked(h, &str, &len, &utf8, &id);
        if (last_r2 <= 0) break;
        char *c = (char *)malloc(len ? len : 1);
        if (!c) { oom = 1; break; }
        if (len) memcpy(c, str, len);
        items_buf[n].buf = c;
        items_buf[n].len = len;
        items_buf[n].id = id;
        items_buf[n].utf8 = utf8;
        n++;
    }
    reqrep_mutex_unlock(h->hdr);
    reqrep_wake_producers(h->hdr);
    EXTEND(SP, (SSize_t)(2 * n));
    for (UV j = 0; j < n; j++) {
        SV *sv = newSVpvn(items_buf[j].buf, items_buf[j].len);
        if (items_buf[j].utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)items_buf[j].id)));
        free(items_buf[j].buf);
    }
    free(items_buf);
    if (last_r2 == -1 || oom) croak("Data::ReqRep::Shared: out of memory");

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
    const char *str;
    uint32_t len;
    uint64_t id;
    bool utf8;
    uint32_t max_count;
  PPCODE:
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    /* Hoist SV construction out of the mutex (see recv_multi). */
    struct drain_item { char *buf; uint32_t len; uint64_t id; bool utf8; struct drain_item *next; } *drained_head = NULL, *drained_tail = NULL;
    UV drained_n = 0;
    int last_r = 0;
    int oom = 0;
    reqrep_mutex_lock(h->hdr);
    while (max_count-- > 0) {
        last_r = reqrep_recv_locked(h, &str, &len, &utf8, &id);
        if (last_r <= 0) break;
        struct drain_item *it = (struct drain_item *)malloc(sizeof(*it));
        char *c = (char *)malloc(len ? len : 1);
        if (!it || !c) { free(it); free(c); oom = 1; break; }
        if (len) memcpy(c, str, len);
        it->buf = c; it->len = len; it->id = id; it->utf8 = utf8; it->next = NULL;
        if (drained_tail) drained_tail->next = it; else drained_head = it;
        drained_tail = it;
        drained_n++;
    }
    reqrep_mutex_unlock(h->hdr);
    reqrep_wake_producers(h->hdr);
    EXTEND(SP, (SSize_t)(2 * drained_n));
    while (drained_head) {
        struct drain_item *it = drained_head; drained_head = it->next;
        SV *sv = newSVpvn(it->buf, it->len);
        if (it->utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)it->id)));
        free(it->buf);
        free(it);
    }
    if (last_r == -1 || oom) croak("Data::ReqRep::Shared: out of memory");

bool
reply(self, id, value)
    SV *self
    UV id
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
    STRLEN len;
  CODE:
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = reqrep_reply(h, (uint64_t)id, str, (uint32_t)len, utf8);
    if (r == -1) croak("Data::ReqRep::Shared: invalid slot index");
    if (r == -3) croak("Data::ReqRep::Shared: response too long (max %u bytes)", h->resp_data_max);
    RETVAL = (r == 1);
  OUTPUT:
    RETVAL

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = (UV)reqrep_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = h->req_cap;
  OUTPUT:
    RETVAL

UV
resp_slots(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = h->resp_slots;
  OUTPUT:
    RETVAL

UV
resp_size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = h->resp_data_max;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = (reqrep_size(h) == 0);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    reqrep_clear(h);

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        ReqRepHandle *h = INT2PTR(ReqRepHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::ReqRep::Shared->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd channel");
    if (unlink(path) != 0)
        croak("unlink(%s): %s", path, strerror(errno));

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    HV *hv = newHV();
    ReqRepHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)reqrep_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv(h->req_cap), 0);
    hv_store(hv, "resp_slots", 10, newSVuv(h->resp_slots), 0);
    hv_store(hv, "resp_data_max", 13, newSVuv(h->resp_data_max), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "arena_cap", 9, newSVuv(h->req_arena_cap), 0);
    hv_store(hv, "arena_used", 10, newSVuv((UV)__atomic_load_n(&hdr->arena_used, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "requests", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_requests, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "replies", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_replies, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_full", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_send_full, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_empty", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recv_empty, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "slot_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    if (reqrep_sync(h) != 0)
        croak("msync: %s", strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = reqrep_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    reqrep_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    int64_t v = reqrep_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    reqrep_notify(h);

IV
reply_eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = reqrep_reply_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
reply_eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    reqrep_reply_eventfd_set(h, fd);

IV
reply_fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = h->reply_fd;
  OUTPUT:
    RETVAL

SV *
reply_eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    int64_t v = reqrep_reply_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
reply_notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    reqrep_reply_notify(h);


MODULE = Data::ReqRep::Shared  PACKAGE = Data::ReqRep::Shared::Client

SV *
new(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    const char *p = SvPV_nolen(path);
    ReqRepHandle *h = reqrep_open(p, REQREP_MODE_STR, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Client->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(fd, REQREP_MODE_STR, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Client->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    ReqRepHandle *h = INT2PTR(ReqRepHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    reqrep_destroy(h);

SV *
send(self, value)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    STRLEN len;
    uint64_t id;
  CODE:
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = reqrep_try_send(h, str, (uint32_t)len, utf8, &id);
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    RETVAL = (r == 1) ? newSVuv((UV)id) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
send_wait(self, value, ...)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double timeout = -1;
    STRLEN len;
    uint64_t id;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = reqrep_send_wait(h, str, (uint32_t)len, utf8, &id, timeout);
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    RETVAL = (r == 1) ? newSVuv((UV)id) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
send_notify(self, value)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    STRLEN len;
    uint64_t id;
  CODE:
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = reqrep_try_send(h, str, (uint32_t)len, utf8, &id);
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    if (r == 1) {
        reqrep_notify(h);
        RETVAL = newSVuv((UV)id);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
send_wait_notify(self, value, ...)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double timeout = -1;
    STRLEN len;
    uint64_t id;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = reqrep_send_wait(h, str, (uint32_t)len, utf8, &id, timeout);
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    if (r == 1) {
        reqrep_notify(h);
        RETVAL = newSVuv((UV)id);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
get(self, id)
    SV *self
    UV id
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    int r = reqrep_try_get(h, (uint64_t)id, &str, &len, &utf8);
    if (r == -1) croak("Data::ReqRep::Shared::Client: invalid slot index");
    if (r == -2) croak("Data::ReqRep::Shared::Client: out of memory");
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
get_wait(self, id, ...)
    SV *self
    UV id
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    int r = reqrep_get_wait(h, (uint64_t)id, &str, &len, &utf8, timeout);
    if (r == -1) croak("Data::ReqRep::Shared::Client: invalid slot index");
    if (r == -2) croak("Data::ReqRep::Shared::Client: out of memory");
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
req(self, value)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    STRLEN len;
    const char *out_str;
    uint32_t out_len;
    bool out_utf8;
  CODE:
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = reqrep_request(h, str, (uint32_t)len, utf8, &out_str, &out_len, &out_utf8, -1);
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    if (r == 1) {
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
req_wait(self, value, timeout)
    SV *self
    SV *value
    double timeout
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    STRLEN len;
    const char *out_str;
    uint32_t out_len;
    bool out_utf8;
  CODE:
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = reqrep_request(h, str, (uint32_t)len, utf8, &out_str, &out_len, &out_utf8, timeout);
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    if (r == 1) {
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
cancel(self, id)
    SV *self
    UV id
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    reqrep_cancel(h, (uint64_t)id);

UV
pending(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = (UV)reqrep_pending(h);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    HV *hv = newHV();
    ReqRepHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)reqrep_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv(h->req_cap), 0);
    hv_store(hv, "resp_slots", 10, newSVuv(h->resp_slots), 0);
    hv_store(hv, "resp_data_max", 13, newSVuv(h->resp_data_max), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "arena_cap", 9, newSVuv(h->req_arena_cap), 0);
    hv_store(hv, "arena_used", 10, newSVuv((UV)__atomic_load_n(&hdr->arena_used, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "requests", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_requests, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "replies", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_replies, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_full", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_send_full, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_empty", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recv_empty, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "slot_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = (UV)reqrep_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->req_cap;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = (reqrep_size(h) == 0);
  OUTPUT:
    RETVAL

UV
resp_slots(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->resp_slots;
  OUTPUT:
    RETVAL

UV
resp_size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->resp_data_max;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = reqrep_reply_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    reqrep_reply_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->reply_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    int64_t v = reqrep_reply_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    reqrep_notify(h);

void
req_eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    reqrep_eventfd_set(h, fd);

IV
req_fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL


MODULE = Data::ReqRep::Shared  PACKAGE = Data::ReqRep::Shared::Int

SV *
new(class, path, req_cap, resp_slots)
    const char *class
    SV *path
    UV req_cap
    UV resp_slots
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    ReqRepHandle *h = reqrep_create_int(p, (uint32_t)req_cap, (uint32_t)resp_slots, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, req_cap, resp_slots)
    const char *class
    const char *name
    UV req_cap
    UV resp_slots
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_create_int_memfd(name, (uint32_t)req_cap, (uint32_t)resp_slots, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(fd, REQREP_MODE_INT, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    ReqRepHandle *h = INT2PTR(ReqRepHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    reqrep_destroy(h);

void
recv(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
    int64_t value;
    uint64_t id;
  PPCODE:
    if (reqrep_int_try_recv(h, &value, &id)) {
        mXPUSHi((IV)value);
        mXPUSHu((UV)id);
    }

void
recv_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
    double timeout = -1;
    int64_t value;
    uint64_t id;
  PPCODE:
    if (items > 1) timeout = SvNV(ST(1));
    if (reqrep_int_recv_wait(h, &value, &id, timeout)) {
        mXPUSHi((IV)value);
        mXPUSHu((UV)id);
    }

bool
reply(self, id, value)
    SV *self
    UV id
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    int r = reqrep_int_reply(h, (uint64_t)id, (int64_t)value);
    if (r == -1) croak("Data::ReqRep::Shared::Int: invalid slot index");
    RETVAL = (r == 1);
  OUTPUT:
    RETVAL

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = (UV)reqrep_int_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = h->req_cap;
  OUTPUT:
    RETVAL

UV
resp_slots(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = h->resp_slots;
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = (reqrep_int_size(h) == 0);
  OUTPUT:
    RETVAL

UV
resp_size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = h->resp_data_max;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    HV *hv = newHV();
    ReqRepHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)reqrep_int_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv(h->req_cap), 0);
    hv_store(hv, "resp_slots", 10, newSVuv(h->resp_slots), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "requests", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_requests, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "replies", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_replies, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_full", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_send_full, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_empty", 10, newSVuv(__atomic_load_n(&hdr->stat_recv_empty, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_waiters", 12, newSVuv(__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_waiters", 12, newSVuv(__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "slot_waiters", 12, newSVuv(__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    reqrep_int_clear(h);

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    if (reqrep_sync(h) != 0) croak("msync: %s", strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = reqrep_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    reqrep_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    int64_t v = reqrep_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    reqrep_notify(h);

IV
reply_eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = reqrep_reply_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
reply_eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    reqrep_reply_eventfd_set(h, fd);

IV
reply_fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = h->reply_fd;
  OUTPUT:
    RETVAL

SV *
reply_eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    int64_t v = reqrep_reply_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
reply_notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    reqrep_reply_notify(h);

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        ReqRepHandle *h = INT2PTR(ReqRepHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: ...->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd channel");
    if (unlink(path) != 0) croak("unlink(%s): %s", path, strerror(errno));


MODULE = Data::ReqRep::Shared  PACKAGE = Data::ReqRep::Shared::Int::Client

SV *
new(class, path)
    const char *class
    SV *path
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    const char *p = SvPV_nolen(path);
    ReqRepHandle *h = reqrep_open(p, REQREP_MODE_INT, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int::Client->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(fd, REQREP_MODE_INT, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int::Client->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    ReqRepHandle *h = INT2PTR(ReqRepHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    reqrep_destroy(h);

SV *
send(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    uint64_t id;
  CODE:
    int r = reqrep_int_try_send(h, (int64_t)value, &id);
    RETVAL = (r == 1) ? newSVuv((UV)id) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
send_wait(self, value, ...)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    double timeout = -1;
    uint64_t id;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    int r = reqrep_int_send_wait(h, (int64_t)value, &id, timeout);
    RETVAL = (r == 1) ? newSVuv((UV)id) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
get(self, id)
    SV *self
    UV id
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    int64_t value;
  CODE:
    int r = reqrep_int_try_get(h, (uint64_t)id, &value);
    if (r == -1) croak("Data::ReqRep::Shared::Int::Client: invalid slot index");
    RETVAL = (r == 1) ? newSViv((IV)value) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
get_wait(self, id, ...)
    SV *self
    UV id
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    double timeout = -1;
    int64_t value;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    int r = reqrep_int_get_wait(h, (uint64_t)id, &value, timeout);
    if (r == -1) croak("Data::ReqRep::Shared::Int::Client: invalid slot index");
    RETVAL = (r == 1) ? newSViv((IV)value) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
req(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    int64_t out;
  CODE:
    int r = reqrep_int_request(h, (int64_t)value, &out, -1);
    RETVAL = (r == 1) ? newSViv((IV)out) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
req_wait(self, value, timeout)
    SV *self
    IV value
    double timeout
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    int64_t out;
  CODE:
    int r = reqrep_int_request(h, (int64_t)value, &out, timeout);
    RETVAL = (r == 1) ? newSViv((IV)out) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
cancel(self, id)
    SV *self
    UV id
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    reqrep_cancel(h, (uint64_t)id);

UV
pending(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = (UV)reqrep_pending(h);
  OUTPUT:
    RETVAL

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = (UV)reqrep_int_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->req_cap;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = (reqrep_int_size(h) == 0);
  OUTPUT:
    RETVAL

UV
resp_slots(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->resp_slots;
  OUTPUT:
    RETVAL

UV
resp_size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->resp_data_max;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    HV *hv = newHV();
    ReqRepHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)reqrep_int_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv(h->req_cap), 0);
    hv_store(hv, "resp_slots", 10, newSVuv(h->resp_slots), 0);
    hv_store(hv, "requests", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_requests, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "replies", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_replies, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = reqrep_reply_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    reqrep_reply_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->reply_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    int64_t v = reqrep_reply_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    reqrep_notify(h);

void
req_eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    reqrep_eventfd_set(h, fd);

IV
req_fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL
