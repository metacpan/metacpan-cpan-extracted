#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "reqrep.h"

/* Saturates, so an oversized length fails the size check instead of wrapping. */
#define LEN32(len) ((len) > (STRLEN)0xFFFFFFFFU ? 0xFFFFFFFFU : (uint32_t)(len))

/* The handle lives in ext magic: a Storable or Clone copy carries none, so cannot free it. */
static MGVTBL reqrep_vtbl;

static ReqRepHandle *reqrep_handle(pTHX_ SV *obj, MAGIC **mgp) {
    MAGIC *mg = SvTYPE(obj) >= SVt_PVMG ? mg_findext(obj, PERL_MAGIC_ext, &reqrep_vtbl) : NULL;
    if (mgp) *mgp = mg;
    return mg ? (ReqRepHandle *)mg->mg_ptr : NULL;
}

#define EXTRACT_HANDLE(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    MAGIC *h_mg; \
    SV *h_obj = SvRV(sv); \
    ReqRepHandle *h = reqrep_handle(aTHX_ h_obj, &h_mg); \
    if (!h_mg) croak("%s object is a copy (Storable, Clone), not a usable handle", classname); \
    if (!h) croak("Attempted to use a destroyed %s object", classname); \
    ReqRepHandle *h0 = h; PERL_UNUSED_VAR(h0); \
    sv_2mortal(SvREFCNT_inc_simple_NN(h_obj))

/* After Perl code ran (argument magic, signal handlers): an explicit DESTROY frees the handle
 * despite EXTRACT_HANDLE's pin, and the stack slot itself may have been freed. */
#define REEXTRACT_HANDLE(classname, sv) \
    h = reqrep_handle(aTHX_ h_obj, NULL); \
    if (h != h0) croak("%s object destroyed during the call", classname)

#define MAKE_OBJ(stash, ptr) \
    (ptr)->sig_pending = (volatile int *)&PL_sig_pending; \
    SV *obj = newSV(0); \
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &reqrep_vtbl, (const char *)(ptr), 0); \
    SV *ref = newRV_noinc(obj); \
    sv_bless(ref, stash); \
    RETVAL = ref

/* Before the channel exists: code a tied or overloaded class runs could die and leak it. */
static HV *reqrep_stash(pTHX_ SV *class) {
    if (sv_isobject(class)) return SvSTASH(SvRV(class));
    return gv_stashsv(class, GV_ADD);
}

/* Every syscall would cut a path short at an embedded NUL. The caller has run sv's get-magic. */
static const char *reqrep_path_arg(pTHX_ SV *sv, const char *what) {
    STRLEN len;
    const char *p = SvPV_nomg(sv, len);
    if (memchr(p, '\0', len)) croak("%s: path contains a NUL byte", what);
    return p;
}

/* A defined integer in int range: undef, "3x" or 2**32+1 is not fd 0, 3 or 1. */
static int reqrep_fd_arg(pTHX_ SV *sv, const char *what) {
    SvGETMAGIC(sv);
    if (SvOK(sv) && !SvROK(sv) && looks_like_number(sv)) {
        NV nv = SvNV_nomg(sv);
        if (nv >= 0 && nv <= INT_MAX && nv == (NV)(int)nv) return (int)nv;
    }
    croak("%s: not a file descriptor", what);
    return -1;
}

/* notify() writes 8 bytes into it, which corrupts anything but an eventfd. */
static void reqrep_check_eventfd(pTHX_ int fd, const char *what) {
    char link[64], target[64];
    snprintf(link, sizeof link, "/proc/self/fd/%d", fd);
    ssize_t len = readlink(link, target, sizeof target - 1);
    if (len < 0) return;    /* not open (the dup reports it), or no /proc to ask */
    target[len] = '\0';
    if (strcmp(target, "anon_inode:[eventfd]") != 0) croak("%s: fd %d is not an eventfd", what, fd);
}

static double reqrep_monotime(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + (double)t.tv_nsec / 1e9;
}

/* Handlers may die or destroy the handle. Returns the time left, -1 for no deadline. */
static double reqrep_after_signal(pTHX_ double deadline) {
    PERL_ASYNC_CHECK();
    if (deadline <= 0) return -1;
    double left = deadline - reqrep_monotime();
    return left > 1e-9 ? left : 1e-9;
}

/* A handler died while a reply was owed: the caller never saw the id, so cancel here. A child
 * forked in a handler unwinds a copy of this on exit, so only the caller's process acts. */
struct reqrep_inflight { ReqRepHandle *h; SV *obj; uint64_t id; int reserving; uint32_t pid; };

static void reqrep_cancel_inflight(pTHX_ void *p) {
    struct reqrep_inflight *f = (struct reqrep_inflight *)p;
    if (f->pid != reqrep_self_pid()) return;
    if ((f->id || f->reserving) && reqrep_handle(aTHX_ f->obj, NULL) == f->h) {
        if (f->id) {
            reqrep_cancel(f->h, f->id);
            reqrep_drop_reply(f->h, f->id);
        }
        reqrep_send_done(f->h, 0);
    }
}

/* Messages queued right now; a batch sized by it takes what is there and leaves later arrivals. */
static UV reqrep_queued_hint(ReqRepHandle *h) {
    uint64_t head = __atomic_load_n(&h->hdr->req_head, __ATOMIC_RELAXED);
    uint64_t tail = __atomic_load_n(&h->hdr->req_tail, __ATOMIC_RELAXED);
    return tail > head ? (UV)(tail - head) : 0;
}

MODULE = Data::ReqRep::Shared  PACKAGE = Data::ReqRep::Shared

PROTOTYPES: DISABLE

SV *
new(class, path, req_cap, resp_slots, resp_size, ...)
    SV *class
    SV *path
    UV req_cap
    UV resp_slots
    UV resp_size
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
    uint64_t arena_cap;
  CODE:
    arena_cap = (items > 5 && (SvGETMAGIC(ST(5)), SvOK(ST(5)))) ? (uint64_t)SvUV_nomg(ST(5)) : 0;
    UV mode = (items > 6 && (SvGETMAGIC(ST(6)), SvOK(ST(6)))) ? SvUV_nomg(ST(6)) : 0600;
    if ((mode & ~(UV)07777) || (mode & 0600) != 0600)
        croak("Data::ReqRep::Shared->new: mode %#" UVof " is not a permission mode the owner can read and write", mode);
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? reqrep_path_arg(aTHX_ path, "Data::ReqRep::Shared->new") : NULL;
    if (req_cap > 0xFFFFFFFFU || resp_slots > 0xFFFFFFFFU || resp_size > 0xFFFFFFFFU) croak("Data::ReqRep::Shared->new: a capacity/size argument is negative or exceeds 2^32");
    /* An anonymous channel is an unnamed memfd, so forked clients can attach by descriptor. */
    ReqRepHandle *h = p ? reqrep_create(p, (uint32_t)req_cap, (uint32_t)resp_slots,
                                         (uint32_t)resp_size, arena_cap, mode, errbuf)
                        : reqrep_create_memfd("reqrep", (uint32_t)req_cap, (uint32_t)resp_slots,
                                              (uint32_t)resp_size, arena_cap, errbuf);
    if (!h) croak("Data::ReqRep::Shared->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, req_cap, resp_slots, resp_size, ...)
    SV *class
    SV *name
    UV req_cap
    UV resp_slots
    UV resp_size
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
    uint64_t arena_cap;
  CODE:
    arena_cap = (items > 5 && (SvGETMAGIC(ST(5)), SvOK(ST(5)))) ? (uint64_t)SvUV_nomg(ST(5)) : 0;
    if (req_cap > 0xFFFFFFFFU || resp_slots > 0xFFFFFFFFU || resp_size > 0xFFFFFFFFU) croak("Data::ReqRep::Shared->new_memfd: a capacity/size argument is negative or exceeds 2^32");
    const char *label = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nomg_nolen(name) : NULL;
    ReqRepHandle *h = reqrep_create_memfd(label, (uint32_t)req_cap, (uint32_t)resp_slots,
                                           (uint32_t)resp_size, arena_cap, errbuf);
    if (!h) croak("Data::ReqRep::Shared->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    SV *class
    SV *fd
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared->new_from_fd"), REQREP_MODE_STR, errbuf);
    if (!h) croak("Data::ReqRep::Shared->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
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
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::ReqRep::Shared")) return;
    MAGIC *mg;
    ReqRepHandle *h = reqrep_handle(aTHX_ SvRV(self), &mg);
    if (!h) return;
    mg->mg_ptr = NULL;
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
    if (items > 1 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) timeout = SvNV_nomg(ST(1));
    REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    while ((r = reqrep_recv_wait(h, &str, &len, &utf8, &id, timeout)) == REQREP_EINTR) {
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    }
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
    /* SVs are built only after the process-shared mutex is released. */
    struct { char *buf; uint32_t len; uint64_t id; bool utf8; } *items_buf = NULL;
    UV n = 0;
    int last_r = 0;
    /* A consumed message whose copy cannot be allocated is still intact in copy_buf. */
    const char *tail = NULL; uint32_t tail_len = 0; uint64_t tail_id = 0; bool tail_utf8 = 0;
    /* Also keeps the malloc size below from wrapping. */
    if (count > (UV)h->req_cap) count = (UV)h->req_cap;
    UV queued = reqrep_queued_hint(h);
    if (count > queued) count = queued;
    if (count > 0) {
        items_buf = (void *)malloc((size_t)count * sizeof(*items_buf));
        if (!items_buf) croak("Data::ReqRep::Shared: out of memory");
    }
    /* Behind a stopped lock holder, return nothing rather than block. */
    int locked = reqrep_mutex_lock_until(h, NULL, 0) == 1;
    for (UV i = 0; locked && i < count; i++) {
        last_r = reqrep_recv_locked(h, &str, &len, &utf8, &id);
        if (last_r <= 0) break;
        char *c = (char *)malloc(len ? len : 1);
        if (!c) { tail = str; tail_len = len; tail_id = id; tail_utf8 = utf8; break; }
        if (len) memcpy(c, str, len);
        items_buf[n].buf = c;
        items_buf[n].len = len;
        items_buf[n].id = id;
        items_buf[n].utf8 = utf8;
        n++;
    }
    if (locked) reqrep_mutex_unlock(h);
    for (UV j = 0; j < n; j++) reqrep_slot_dispatch(h, items_buf[j].id);
    if (tail) reqrep_slot_dispatch(h, tail_id);
    reqrep_wake_producers(h, (uint32_t)(n + (tail ? 1 : 0)));
    EXTEND(SP, (SSize_t)(2 * (n + (tail ? 1 : 0))));
    for (UV j = 0; j < n; j++) {
        SV *sv = newSVpvn(items_buf[j].buf, items_buf[j].len);
        if (items_buf[j].utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)items_buf[j].id)));
        free(items_buf[j].buf);
    }
    free(items_buf);
    if (tail) {
        SV *sv = newSVpvn(tail, tail_len);
        if (tail_utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)tail_id)));
    }
    /* Croak only when no message taken would be lost with it. */
    if (last_r == -1 && n == 0 && !tail) croak("Data::ReqRep::Shared: out of memory");

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
    if (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) timeout = SvNV_nomg(ST(2));
    REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    /* "Up to count": the blocking receive below would otherwise take one. */
    if (count == 0) XSRETURN(0);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    while ((r = reqrep_recv_wait(h, &str, &len, &utf8, &id, timeout)) == REQREP_EINTR) {
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    }
    if (r == -1) croak("Data::ReqRep::Shared: out of memory");
    if (r != 1) XSRETURN(0);
    {
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
        mXPUSHu((UV)id);
    }
    struct { char *buf; uint32_t len; uint64_t id; bool utf8; } *items_buf = NULL;
    UV n = 0;
    int last_r2 = 0;
    /* See recv_multi: an already-consumed message is delivered from copy_buf. */
    const char *tail = NULL; uint32_t tail_len = 0; uint64_t tail_id = 0; bool tail_utf8 = 0;
    /* Also keeps the malloc size below from wrapping. */
    if (count > (UV)h->req_cap + 1) count = (UV)h->req_cap + 1;
    UV queued = 1 + reqrep_queued_hint(h);
    if (count > queued) count = queued;
    if (count > 1) {
        items_buf = (void *)malloc((size_t)(count - 1) * sizeof(*items_buf));
        /* The first message is already on the stack: a croak would lose it. */
        if (!items_buf) count = 1;
    }
    int locked = reqrep_mutex_lock_until(h, NULL, 0) == 1;
    for (UV i = 1; locked && i < count; i++) {
        last_r2 = reqrep_recv_locked(h, &str, &len, &utf8, &id);
        if (last_r2 <= 0) break;
        char *c = (char *)malloc(len ? len : 1);
        if (!c) { tail = str; tail_len = len; tail_id = id; tail_utf8 = utf8; break; }
        if (len) memcpy(c, str, len);
        items_buf[n].buf = c;
        items_buf[n].len = len;
        items_buf[n].id = id;
        items_buf[n].utf8 = utf8;
        n++;
    }
    if (locked) reqrep_mutex_unlock(h);
    for (UV j = 0; j < n; j++) reqrep_slot_dispatch(h, items_buf[j].id);
    if (tail) reqrep_slot_dispatch(h, tail_id);
    reqrep_wake_producers(h, (uint32_t)(n + (tail ? 1 : 0)));
    EXTEND(SP, (SSize_t)(2 * (n + (tail ? 1 : 0))));
    for (UV j = 0; j < n; j++) {
        SV *sv = newSVpvn(items_buf[j].buf, items_buf[j].len);
        if (items_buf[j].utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)items_buf[j].id)));
        free(items_buf[j].buf);
    }
    free(items_buf);
    if (tail) {
        SV *sv = newSVpvn(tail, tail_len);
        if (tail_utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)tail_id)));
    }
    /* No OOM croak: the first message is on the stack and would be lost. */

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
    max_count = UINT32_MAX;
    if (items > 1 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) {
        UV m = SvUV_nomg(ST(1));
        if (m < UINT32_MAX) max_count = (uint32_t)m;
    }
    struct drain_item { char *buf; uint32_t len; uint64_t id; bool utf8; struct drain_item *next; } *drained_head = NULL, *drained_tail = NULL;
    UV drained_n = 0;
    int last_r = 0;
    /* See recv_multi: an already-consumed message is delivered from copy_buf. */
    const char *tail = NULL; uint32_t tail_len = 0; uint64_t tail_id = 0; bool tail_utf8 = 0;
    REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    int locked = reqrep_mutex_lock_until(h, NULL, 0) == 1;
    while (locked && max_count-- > 0) {
        last_r = reqrep_recv_locked(h, &str, &len, &utf8, &id);
        if (last_r <= 0) break;
        struct drain_item *it = (struct drain_item *)malloc(sizeof(*it));
        char *c = (char *)malloc(len ? len : 1);
        if (!it || !c) {
            free(it); free(c);
            tail = str; tail_len = len; tail_id = id; tail_utf8 = utf8;
            break;
        }
        if (len) memcpy(c, str, len);
        it->buf = c; it->len = len; it->id = id; it->utf8 = utf8; it->next = NULL;
        if (drained_tail) drained_tail->next = it; else drained_head = it;
        drained_tail = it;
        drained_n++;
    }
    if (locked) reqrep_mutex_unlock(h);
    for (struct drain_item *it = drained_head; it; it = it->next) reqrep_slot_dispatch(h, it->id);
    if (tail) reqrep_slot_dispatch(h, tail_id);
    reqrep_wake_producers(h, (uint32_t)(drained_n + (tail ? 1 : 0)));
    EXTEND(SP, (SSize_t)(2 * (drained_n + (tail ? 1 : 0))));
    while (drained_head) {
        struct drain_item *it = drained_head; drained_head = it->next;
        SV *sv = newSVpvn(it->buf, it->len);
        if (it->utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)it->id)));
        free(it->buf);
        free(it);
    }
    if (tail) {
        SV *sv = newSVpvn(tail, tail_len);
        if (tail_utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        PUSHs(sv_2mortal(newSVuv((UV)tail_id)));
    }
    /* See recv_multi: croak only when there is nothing on the stack to lose. */
    if (last_r == -1 && drained_n == 0 && !tail) croak("Data::ReqRep::Shared: out of memory");

bool
reply(self, id, value)
    SV *self
    UV id
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
    STRLEN len;
  CODE:
    sv_2mortal(SvREFCNT_inc_simple_NN(value));   /* a handler may drop the caller's last reference */
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    int r = reqrep_reply(h, (uint64_t)id, str, LEN32(len), utf8);
    /* A bad id came from the request itself: unanswerable, not fatal to the server. */
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
    while (reqrep_clear(h) == REQREP_EINTR) {
        PERL_ASYNC_CHECK();
        REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    }

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class) && sv_derived_from(self_or_class, "Data::ReqRep::Shared")) {
        MAGIC *mg;
        ReqRepHandle *h = reqrep_handle(aTHX_ SvRV(self_or_class), &mg);
        if (!mg) croak("Data::ReqRep::Shared object is a copy (Storable, Clone), not a usable handle");
        if (!h) croak("Attempted to use a destroyed Data::ReqRep::Shared object");
        path = h->path;
        struct stat st;
        /* A newer instance may have replaced the file: leave that one alone. */
        if (path && lstat(path, &st) == 0 && (st.st_dev != h->file_dev || st.st_ino != h->file_ino))
            XSRETURN_EMPTY;
    } else {
        if (items < 2) croak("Usage: Data::ReqRep::Shared->unlink($path)");
        path = (SvGETMAGIC(ST(1)), reqrep_path_arg(aTHX_ ST(1), "Data::ReqRep::Shared->unlink"));
    }
    if (!path) croak("cannot unlink anonymous or memfd channel");
    if (unlink(path) != 0 && errno != ENOENT)
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
    hv_store(hv, "recv_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "send_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "slot_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED))), 0);
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
        croak("Data::ReqRep::Shared->sync: msync: %s", strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    RETVAL = reqrep_eventfd_create(h);
    if (RETVAL < 0) croak("Data::ReqRep::Shared->eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared->eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared->eventfd_set");
    if (reqrep_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared->eventfd_set: %s", strerror(errno));

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
    if (RETVAL < 0) croak("Data::ReqRep::Shared->reply_eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
reply_eventfd_set(self, fd)
    SV *self
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared->reply_eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared->reply_eventfd_set");
    if (reqrep_reply_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared->reply_eventfd_set: %s", strerror(errno));

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
    SV *class
    SV *path
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    const char *p = (SvGETMAGIC(path), reqrep_path_arg(aTHX_ path, "Data::ReqRep::Shared::Client->new"));
    ReqRepHandle *h = reqrep_open(p, REQREP_MODE_STR, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Client->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    SV *class
    SV *fd
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Client->new_from_fd"), REQREP_MODE_STR, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Client->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
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
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::ReqRep::Shared::Client")) return;
    MAGIC *mg;
    ReqRepHandle *h = reqrep_handle(aTHX_ SvRV(self), &mg);
    if (!h) return;
    mg->mg_ptr = NULL;
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
    sv_2mortal(SvREFCNT_inc_simple_NN(value));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    int r = reqrep_try_send(h, str, LEN32(len), utf8, &id);
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
    if (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) timeout = SvNV_nomg(ST(2));
    sv_2mortal(SvREFCNT_inc_simple_NN(value));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    struct reqrep_inflight held = { h, h_obj, 0, 0, reqrep_self_pid() };
    while ((r = reqrep_send_wait(h, str, LEN32(len), utf8, &id, timeout)) == REQREP_EINTR) {
        if (h->reserving && !held.reserving) {
            ENTER;
            SvREFCNT_inc_simple_void_NN(h_obj);
            SAVEFREESV(h_obj);
            SAVEDESTRUCTOR_X(reqrep_cancel_inflight, &held);
            SAVEI32(reqrep_handler_tag);
            reqrep_handler_tag = h->tag;
            held.reserving = 1;
        }
        if (SvGMAGICAL(value)) value = sv_2mortal(newSVpvn_flags(str, len, utf8 ? SVf_UTF8 : 0));
        timeout = reqrep_after_signal(aTHX_ deadline);
        str = SvPV_nomg(value, len);
        utf8 = SvUTF8(value) ? true : false;
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    }
    if (held.reserving) { held.reserving = 0; LEAVE; }
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
    sv_2mortal(SvREFCNT_inc_simple_NN(value));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    int r = reqrep_try_send(h, str, LEN32(len), utf8, &id);
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
    if (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) timeout = SvNV_nomg(ST(2));
    sv_2mortal(SvREFCNT_inc_simple_NN(value));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    struct reqrep_inflight held = { h, h_obj, 0, 0, reqrep_self_pid() };
    while ((r = reqrep_send_wait(h, str, LEN32(len), utf8, &id, timeout)) == REQREP_EINTR) {
        if (h->reserving && !held.reserving) {
            ENTER;
            SvREFCNT_inc_simple_void_NN(h_obj);
            SAVEFREESV(h_obj);
            SAVEDESTRUCTOR_X(reqrep_cancel_inflight, &held);
            SAVEI32(reqrep_handler_tag);
            reqrep_handler_tag = h->tag;
            held.reserving = 1;
        }
        if (SvGMAGICAL(value)) value = sv_2mortal(newSVpvn_flags(str, len, utf8 ? SVf_UTF8 : 0));
        timeout = reqrep_after_signal(aTHX_ deadline);
        str = SvPV_nomg(value, len);
        utf8 = SvUTF8(value) ? true : false;
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    }
    if (held.reserving) { held.reserving = 0; LEAVE; }
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
    if (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) timeout = SvNV_nomg(ST(2));
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    while ((r = reqrep_get_wait(h, (uint64_t)id, &str, &len, &utf8, timeout)) == REQREP_EINTR) {
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    }
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
    sv_2mortal(SvREFCNT_inc_simple_NN(value));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double timeout = -1;
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    uint64_t inflight = 0;
    struct reqrep_inflight owed = { h, h_obj, 0, 0, reqrep_self_pid() };
    int r;
    ENTER;
    SvREFCNT_inc_simple_void_NN(h_obj);
    SAVEFREESV(h_obj);    /* unwinding frees mortals first; this ref outlives the destructor */
    SAVEDESTRUCTOR_X(reqrep_cancel_inflight, &owed);
    while ((r = reqrep_request_step(h, str, LEN32(len), utf8, &out_str, &out_len, &out_utf8, timeout, &inflight)) == REQREP_EINTR) {
        owed.id = inflight;
        owed.reserving = h->reserving;
        if (owed.reserving && reqrep_handler_tag != h->tag) { SAVEI32(reqrep_handler_tag); reqrep_handler_tag = h->tag; }
        if (SvGMAGICAL(value)) value = sv_2mortal(newSVpvn_flags(str, len, utf8 ? SVf_UTF8 : 0));
        timeout = reqrep_after_signal(aTHX_ deadline);
        str = SvPV_nomg(value, len);
        utf8 = SvUTF8(value) ? true : false;
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    }
    owed.id = 0;
    owed.reserving = 0;
    LEAVE;
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    if (r == -5) croak("Data::ReqRep::Shared::Client: out of memory");
    if (r == 1) {
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
req_wait(self, value, timeout_sv)
    SV *self
    SV *value
    SV *timeout_sv
  PREINIT:
    double timeout = (SvGETMAGIC(timeout_sv), SvOK(timeout_sv)) ? SvNV_nomg(timeout_sv) : 0;
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    STRLEN len;
    const char *out_str;
    uint32_t out_len;
    bool out_utf8;
  CODE:
    sv_2mortal(SvREFCNT_inc_simple_NN(value));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    uint64_t inflight = 0;
    struct reqrep_inflight owed = { h, h_obj, 0, 0, reqrep_self_pid() };
    int r;
    ENTER;
    SvREFCNT_inc_simple_void_NN(h_obj);
    SAVEFREESV(h_obj);
    SAVEDESTRUCTOR_X(reqrep_cancel_inflight, &owed);
    while ((r = reqrep_request_step(h, str, LEN32(len), utf8, &out_str, &out_len, &out_utf8, timeout, &inflight)) == REQREP_EINTR) {
        owed.id = inflight;
        owed.reserving = h->reserving;
        if (owed.reserving && reqrep_handler_tag != h->tag) { SAVEI32(reqrep_handler_tag); reqrep_handler_tag = h->tag; }
        if (SvGMAGICAL(value)) value = sv_2mortal(newSVpvn_flags(str, len, utf8 ? SVf_UTF8 : 0));
        timeout = reqrep_after_signal(aTHX_ deadline);
        str = SvPV_nomg(value, len);
        utf8 = SvUTF8(value) ? true : false;
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    }
    owed.id = 0;
    owed.reserving = 0;
    LEAVE;
    if (r == -2) croak("Data::ReqRep::Shared::Client: request too long (exceeds arena capacity or 2GB mask)");
    if (r == -5) croak("Data::ReqRep::Shared::Client: out of memory");
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
    reqrep_drop_reply(h, (uint64_t)id);

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
    hv_store(hv, "recv_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "send_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "slot_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED))), 0);
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
    if (RETVAL < 0) croak("Data::ReqRep::Shared::Client->eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Client->eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared::Client->eventfd_set");
    if (reqrep_reply_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared::Client->eventfd_set: %s", strerror(errno));

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
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Client->req_eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared::Client->req_eventfd_set");
    if (reqrep_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared::Client->req_eventfd_set: %s", strerror(errno));

IV
req_fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

IV
ready_fd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  CODE:
    RETVAL = reqrep_ready_fd(h);
    if (RETVAL < 0) croak("Data::ReqRep::Shared::Client->ready_fd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
ready(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Client", self);
  PPCODE:
    uint32_t cap = h->resp_slots < REQREP_READY_MAX ? h->resp_slots : REQREP_READY_MAX;
    uint64_t *ids = (uint64_t *)malloc((size_t)cap * sizeof *ids);
    if (!ids) croak("Data::ReqRep::Shared::Client: out of memory");
    uint32_t n = reqrep_ready_ids(h, ids, cap);
    EXTEND(SP, (SSize_t)n);
    for (uint32_t i = 0; i < n; i++) mPUSHu((UV)ids[i]);
    free(ids);


MODULE = Data::ReqRep::Shared  PACKAGE = Data::ReqRep::Shared::Int

SV *
new(class, path, req_cap, resp_slots, ...)
    SV *class
    SV *path
    UV req_cap
    UV resp_slots
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    UV mode = (items > 4 && (SvGETMAGIC(ST(4)), SvOK(ST(4)))) ? SvUV_nomg(ST(4)) : 0600;
    if ((mode & ~(UV)07777) || (mode & 0600) != 0600)
        croak("Data::ReqRep::Shared::Int->new: mode %#" UVof " is not a permission mode the owner can read and write", mode);
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? reqrep_path_arg(aTHX_ path, "Data::ReqRep::Shared::Int->new") : NULL;
    if (req_cap > 0xFFFFFFFFU || resp_slots > 0xFFFFFFFFU) croak("Data::ReqRep::Shared::Int->new: req_cap/resp_slots is negative or exceeds 2^32");
    ReqRepHandle *h = p ? reqrep_create_int(p, (uint32_t)req_cap, (uint32_t)resp_slots, mode, errbuf)
                        : reqrep_create_int_memfd("reqrep", (uint32_t)req_cap, (uint32_t)resp_slots, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, req_cap, resp_slots)
    SV *class
    SV *name
    UV req_cap
    UV resp_slots
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    if (req_cap > 0xFFFFFFFFU || resp_slots > 0xFFFFFFFFU) croak("Data::ReqRep::Shared::Int->new_memfd: req_cap/resp_slots is negative or exceeds 2^32");
    const char *label = (SvGETMAGIC(name), SvOK(name)) ? SvPV_nomg_nolen(name) : NULL;
    ReqRepHandle *h = reqrep_create_int_memfd(label, (uint32_t)req_cap, (uint32_t)resp_slots, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    SV *class
    SV *fd
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Int->new_from_fd"), REQREP_MODE_INT, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
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
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::ReqRep::Shared::Int")) return;
    MAGIC *mg;
    ReqRepHandle *h = reqrep_handle(aTHX_ SvRV(self), &mg);
    if (!h) return;
    mg->mg_ptr = NULL;
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
    if (items > 1 && (SvGETMAGIC(ST(1)), SvOK(ST(1)))) timeout = SvNV_nomg(ST(1));
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    while ((r = reqrep_int_recv_wait(h, &value, &id, timeout)) == REQREP_EINTR) {
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
    }
    if (r == 1) {
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
    /* See Data::ReqRep::Shared::reply: an unanswerable id is false, not fatal. */
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
    hv_store(hv, "resp_data_max", 13, newSVuv(h->resp_data_max), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "requests", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_requests, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "replies", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_replies, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_full", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_send_full, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_empty", 10, newSVuv(__atomic_load_n(&hdr->stat_recv_empty, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "recv_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "slot_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED))), 0);
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
    if (reqrep_sync(h) != 0) croak("Data::ReqRep::Shared::Int->sync: msync: %s", strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    RETVAL = reqrep_eventfd_create(h);
    if (RETVAL < 0) croak("Data::ReqRep::Shared::Int->eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Int->eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared::Int->eventfd_set");
    if (reqrep_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared::Int->eventfd_set: %s", strerror(errno));

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
    if (RETVAL < 0) croak("Data::ReqRep::Shared::Int->reply_eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
reply_eventfd_set(self, fd)
    SV *self
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Int->reply_eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Int", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared::Int->reply_eventfd_set");
    if (reqrep_reply_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared::Int->reply_eventfd_set: %s", strerror(errno));

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
    if (sv_isobject(self_or_class) && sv_derived_from(self_or_class, "Data::ReqRep::Shared::Int")) {
        MAGIC *mg;
        ReqRepHandle *h = reqrep_handle(aTHX_ SvRV(self_or_class), &mg);
        if (!mg) croak("Data::ReqRep::Shared::Int object is a copy (Storable, Clone), not a usable handle");
        if (!h) croak("Attempted to use a destroyed Data::ReqRep::Shared::Int object");
        path = h->path;
        struct stat st;
        if (path && lstat(path, &st) == 0 && (st.st_dev != h->file_dev || st.st_ino != h->file_ino))
            XSRETURN_EMPTY;
    } else {
        if (items < 2) croak("Usage: Data::ReqRep::Shared::Int->unlink($path)");
        path = (SvGETMAGIC(ST(1)), reqrep_path_arg(aTHX_ ST(1), "Data::ReqRep::Shared::Int->unlink"));
    }
    if (!path) croak("cannot unlink anonymous or memfd channel");
    if (unlink(path) != 0 && errno != ENOENT) croak("unlink(%s): %s", path, strerror(errno));


MODULE = Data::ReqRep::Shared  PACKAGE = Data::ReqRep::Shared::Int::Client

SV *
new(class, path)
    SV *class
    SV *path
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    const char *p = (SvGETMAGIC(path), reqrep_path_arg(aTHX_ path, "Data::ReqRep::Shared::Int::Client->new"));
    ReqRepHandle *h = reqrep_open(p, REQREP_MODE_INT, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int::Client->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    SV *class
    SV *fd
  PREINIT:
    HV *stash = reqrep_stash(aTHX_ class);
    char errbuf[REQREP_ERR_BUFLEN];
  CODE:
    ReqRepHandle *h = reqrep_open_fd(reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Int::Client->new_from_fd"), REQREP_MODE_INT, errbuf);
    if (!h) croak("Data::ReqRep::Shared::Int::Client->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(stash, h);
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
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::ReqRep::Shared::Int::Client")) return;
    MAGIC *mg;
    ReqRepHandle *h = reqrep_handle(aTHX_ SvRV(self), &mg);
    if (!h) return;
    mg->mg_ptr = NULL;
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
    if (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) timeout = SvNV_nomg(ST(2));
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    while ((r = reqrep_int_send_wait(h, (int64_t)value, &id, timeout)) == REQREP_EINTR) {
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    }
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
    if (items > 2 && (SvGETMAGIC(ST(2)), SvOK(ST(2)))) timeout = SvNV_nomg(ST(2));
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    int r;
    while ((r = reqrep_int_get_wait(h, (uint64_t)id, &value, timeout)) == REQREP_EINTR) {
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    }
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
    double timeout = -1;
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    uint64_t inflight = 0;
    struct reqrep_inflight owed = { h, h_obj, 0, 0, reqrep_self_pid() };
    int r;
    ENTER;
    SvREFCNT_inc_simple_void_NN(h_obj);
    SAVEFREESV(h_obj);
    SAVEDESTRUCTOR_X(reqrep_cancel_inflight, &owed);
    while ((r = reqrep_int_request_step(h, (int64_t)value, &out, timeout, &inflight)) == REQREP_EINTR) {
        owed.id = inflight;
        owed.reserving = h->reserving;
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    }
    owed.id = 0;
    owed.reserving = 0;
    LEAVE;
    RETVAL = (r == 1) ? newSViv((IV)out) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
req_wait(self, value, timeout_sv)
    SV *self
    IV value
    SV *timeout_sv
  PREINIT:
    double timeout = (SvGETMAGIC(timeout_sv), SvOK(timeout_sv)) ? SvNV_nomg(timeout_sv) : 0;
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    int64_t out;
  CODE:
    double deadline = timeout > 0 ? reqrep_monotime() + timeout : 0;
    uint64_t inflight = 0;
    struct reqrep_inflight owed = { h, h_obj, 0, 0, reqrep_self_pid() };
    int r;
    ENTER;
    SvREFCNT_inc_simple_void_NN(h_obj);
    SAVEFREESV(h_obj);
    SAVEDESTRUCTOR_X(reqrep_cancel_inflight, &owed);
    while ((r = reqrep_int_request_step(h, (int64_t)value, &out, timeout, &inflight)) == REQREP_EINTR) {
        owed.id = inflight;
        owed.reserving = h->reserving;
        timeout = reqrep_after_signal(aTHX_ deadline);
        REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    }
    owed.id = 0;
    owed.reserving = 0;
    LEAVE;
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
    reqrep_drop_reply(h, (uint64_t)id);

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
    hv_store(hv, "resp_data_max", 13, newSVuv(h->resp_data_max), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "requests", 8, newSVuv((UV)__atomic_load_n(&hdr->stat_requests, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "replies", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_replies, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_full", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_send_full, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recv_empty", 10, newSVuv(__atomic_load_n(&hdr->stat_recv_empty, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "send_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->send_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "recv_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->recv_waiters, __ATOMIC_RELAXED))), 0);
    hv_store(hv, "slot_waiters", 12, newSVuv((UV)REQREP_WAITERS(__atomic_load_n(&hdr->slot_waiters, __ATOMIC_RELAXED))), 0);
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
    if (RETVAL < 0) croak("Data::ReqRep::Shared::Int::Client->eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Int::Client->eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared::Int::Client->eventfd_set");
    if (reqrep_reply_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared::Int::Client->eventfd_set: %s", strerror(errno));

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
    SV *fd
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    int n = reqrep_fd_arg(aTHX_ fd, "Data::ReqRep::Shared::Int::Client->req_eventfd_set");
    REEXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
    reqrep_check_eventfd(aTHX_ n, "Data::ReqRep::Shared::Int::Client->req_eventfd_set");
    if (reqrep_eventfd_set(h, n) < 0)
        croak("Data::ReqRep::Shared::Int::Client->req_eventfd_set: %s", strerror(errno));

IV
req_fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

IV
ready_fd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  CODE:
    RETVAL = reqrep_ready_fd(h);
    if (RETVAL < 0) croak("Data::ReqRep::Shared::Int::Client->ready_fd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
ready(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::ReqRep::Shared::Int::Client", self);
  PPCODE:
    uint32_t cap = h->resp_slots < REQREP_READY_MAX ? h->resp_slots : REQREP_READY_MAX;
    uint64_t *ids = (uint64_t *)malloc((size_t)cap * sizeof *ids);
    if (!ids) croak("Data::ReqRep::Shared::Int::Client: out of memory");
    uint32_t n = reqrep_ready_ids(h, ids, cap);
    EXTEND(SP, (SSize_t)n);
    for (uint32_t i = 0; i < n; i++) mPUSHu((UV)ids[i]);
    free(ids);
