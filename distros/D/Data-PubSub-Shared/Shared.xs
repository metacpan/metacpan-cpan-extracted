#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "pubsub.h"

#include "XSParseKeyword.h"

static int build_kw_1arg(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *q_op = args[0]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED,
        op_append_elem(OP_LIST, q_op, cvref));
    return KEYWORD_PLUGIN_EXPR;
}

static int build_kw_2arg(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *q_op = args[0]->op;
    OP *val_op = args[1]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, q_op, val_op);
    arglist = op_append_elem(OP_LIST, arglist, cvref);
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED, arglist);
    return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordPieceType pieces_1expr[] = {
    XPK_TERMEXPR, {0}
};

static const struct XSParseKeywordPieceType pieces_2expr[] = {
    XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, {0}
};

#define DEFINE_PS_KW(variant, PKG, kw, nargs, builder) \
    static const struct XSParseKeywordHooks hooks_ps_##variant##_##kw = { \
        .flags = XPK_FLAG_EXPR, \
        .permit_hintkey = "Data::PubSub::Shared::" PKG "/ps_" #variant "_" #kw, \
        .pieces = pieces_##nargs##expr, \
        .build = builder, \
    };

/* Publisher keywords */
DEFINE_PS_KW(int, "Int", publish, 2, build_kw_2arg)

/* Subscriber keywords */
DEFINE_PS_KW(int, "Int", poll,    1, build_kw_1arg)
DEFINE_PS_KW(int, "Int", lag,     1, build_kw_1arg)

/* Str publisher keywords */
DEFINE_PS_KW(str, "Str", publish, 2, build_kw_2arg)

/* Int32 keywords */
DEFINE_PS_KW(int32, "Int32", publish, 2, build_kw_2arg)
DEFINE_PS_KW(int32, "Int32", poll,    1, build_kw_1arg)
DEFINE_PS_KW(int32, "Int32", lag,     1, build_kw_1arg)

/* Int16 keywords */
DEFINE_PS_KW(int16, "Int16", publish, 2, build_kw_2arg)
DEFINE_PS_KW(int16, "Int16", poll,    1, build_kw_1arg)
DEFINE_PS_KW(int16, "Int16", lag,     1, build_kw_1arg)

/* Str subscriber keywords */
DEFINE_PS_KW(str, "Str", poll,    1, build_kw_1arg)
DEFINE_PS_KW(str, "Str", lag,     1, build_kw_1arg)

#define REGISTER_PS_KW(variant, kw, func_name) \
    register_xs_parse_keyword("ps_" #variant "_" #kw, \
        &hooks_ps_##variant##_##kw, (void*)func_name)

#define EXTRACT_HANDLE(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed %s object", classname)

#define MAKE_OBJ(class, ptr) \
    SV *ref = newRV_noinc(newSViv(PTR2IV(ptr))); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define EXTRACT_SUB(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    PubSubSub *sub = INT2PTR(PubSubSub*, SvIV(SvRV(sv))); \
    if (!sub) croak("Attempted to use a destroyed %s object", classname)

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Int

PROTOTYPES: DISABLE

BOOT:
    boot_xs_parse_keyword(0.40);
    REGISTER_PS_KW(int, publish, "Data::PubSub::Shared::Int::publish");
    REGISTER_PS_KW(int, poll,    "Data::PubSub::Shared::Int::Sub::poll");
    REGISTER_PS_KW(int, lag,     "Data::PubSub::Shared::Int::Sub::lag");
    REGISTER_PS_KW(int32, publish, "Data::PubSub::Shared::Int32::publish");
    REGISTER_PS_KW(int32, poll,    "Data::PubSub::Shared::Int32::Sub::poll");
    REGISTER_PS_KW(int32, lag,     "Data::PubSub::Shared::Int32::Sub::lag");
    REGISTER_PS_KW(int16, publish, "Data::PubSub::Shared::Int16::publish");
    REGISTER_PS_KW(int16, poll,    "Data::PubSub::Shared::Int16::Sub::poll");
    REGISTER_PS_KW(int16, lag,     "Data::PubSub::Shared::Int16::Sub::lag");
    REGISTER_PS_KW(str, publish, "Data::PubSub::Shared::Str::publish");
    REGISTER_PS_KW(str, poll,    "Data::PubSub::Shared::Str::Sub::poll");
    REGISTER_PS_KW(str, lag,     "Data::PubSub::Shared::Str::Sub::lag");

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PubSubHandle *h = pubsub_create(p, (uint32_t)capacity, PUBSUB_MODE_INT, 0, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    PubSubHandle *h = pubsub_create_memfd(name, (uint32_t)capacity, PUBSUB_MODE_INT, 0, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    PubSubHandle *h = pubsub_open_fd(fd, PUBSUB_MODE_INT, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    pubsub_destroy(h);

bool
publish(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    RETVAL = pubsub_int_publish(h, (int64_t)value);
  OUTPUT:
    RETVAL

UV
publish_multi(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    uint32_t count = items - 1;
    if (count == 0) { RETVAL = 0; }
    else {
        if (count > 8192) croak("publish_multi: too many values (%u > 8192)", count);
        int64_t *vals = (int64_t *)alloca(count * sizeof(int64_t));
        for (uint32_t i = 0; i < count; i++)
            vals[i] = (int64_t)SvIV(ST(i + 1));
        RETVAL = pubsub_int_publish_multi(h, vals, count);
    }
  OUTPUT:
    RETVAL

void
publish_notify(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    pubsub_int_publish(h, (int64_t)value);
    pubsub_notify(h);

SV *
subscribe(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 0);
    if (!sub) croak("subscribe: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Int::Sub", sub);
  OUTPUT:
    RETVAL

SV *
subscribe_all(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 1);
    if (!sub) croak("subscribe_all: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Int::Sub", sub);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    RETVAL = h->capacity;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&h->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    HV *hv = newHV();
    PubSubHeader *hdr = h->hdr;
    hv_store(hv, "capacity", 8, newSVuv(h->capacity), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "write_pos", 9,
        newSVuv((UV)__atomic_load_n(&hdr->write_pos, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "publish_ok", 10,
        newSVuv((UV)__atomic_load_n(&hdr->stat_publish_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10,
        newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "sub_waiters", 11,
        newSVuv(__atomic_load_n(&hdr->sub_waiters, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    pubsub_clear(h);

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    if (pubsub_sync(h) != 0)
        croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::PubSub::Shared::Int->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd pubsub");
    if (unlink(path) != 0)
        croak("unlink(%s): %s", path, strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    RETVAL = pubsub_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    pubsub_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    int64_t v = pubsub_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int", self);
  CODE:
    pubsub_notify(h);

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Int::Sub

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubSub *sub = INT2PTR(PubSubSub*, SvIV(SvRV(self)));
    if (!sub) return;
    sv_setiv(SvRV(self), 0);
    if (sub->userdata) SvREFCNT_dec((SV *)sub->userdata);
    pubsub_sub_destroy(sub);

SV *
poll(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
    int64_t value;
  CODE:
    int r = pubsub_int_poll(sub, &value);
    if (r == 1)
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
poll_multi(self, count)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
    int64_t value;
  PPCODE:
    for (UV i = 0; i < count; i++) {
        int r = pubsub_int_poll(sub, &value);
        if (r != 1) break;
        mXPUSHi((IV)value);
    }

SV *
poll_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
    double timeout = -1;
    int64_t value;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int r = pubsub_int_poll_wait(sub, &value, timeout);
    if (r == 1)
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
    int64_t value;
    uint32_t max_count;
  PPCODE:
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_int_poll(sub, &value))
        mXPUSHi((IV)value);

void
poll_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
    double timeout = -1;
    int64_t value;
  PPCODE:
    if (count == 0) XSRETURN(0);
    if (items > 2) timeout = SvNV(ST(2));
    if (!pubsub_int_poll_wait(sub, &value, timeout)) XSRETURN(0);
    mXPUSHi((IV)value);
    for (UV i = 1; i < count; i++) {
        if (!pubsub_int_poll(sub, &value)) break;
        mXPUSHi((IV)value);
    }

UV
lag(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    RETVAL = (UV)pubsub_lag(sub);
  OUTPUT:
    RETVAL

UV
overflow_count(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    RETVAL = (UV)sub->overflow_count;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

bool
has_overflow(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
    RETVAL = (sub->cursor < wp && wp - sub->cursor > sub->capacity);
  OUTPUT:
    RETVAL

UV
cursor(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    if (items > 1) sub->cursor = (uint64_t)SvUV(ST(1));
    RETVAL = (UV)sub->cursor;
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    sub->cursor = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);

void
reset_oldest(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);
    sub->cursor = (wp > sub->capacity) ? wp - sub->capacity : 0;

UV
poll_cb(self, cb)
    SV *self
    SV *cb
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
    int64_t value;
  CODE:
    RETVAL = 0;
    while (pubsub_int_poll(sub, &value)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi((IV)value);
        PUTBACK;
        call_sv(cb, G_DISCARD);
        FREETMPS; LEAVE;
        RETVAL++;
    }
  OUTPUT:
    RETVAL

void
drain_notify(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
    int64_t value;
    uint32_t max_count;
  PPCODE:
    pubsub_sub_eventfd_consume(sub);
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_int_poll(sub, &value))
        mXPUSHi((IV)value);

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    sub->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int::Sub", self);
  CODE:
    RETVAL = sub->notify_fd;
  OUTPUT:
    RETVAL

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Str

SV *
new(class, path, capacity, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
    uint32_t msg_size;
  CODE:
    msg_size = (items > 3) ? (uint32_t)SvUV(ST(3)) : 0;
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PubSubHandle *h = pubsub_create(p, (uint32_t)capacity, PUBSUB_MODE_STR, msg_size, errbuf);
    if (!h) croak("Data::PubSub::Shared::Str->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity, ...)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
    uint32_t msg_size;
  CODE:
    msg_size = (items > 3) ? (uint32_t)SvUV(ST(3)) : 0;
    PubSubHandle *h = pubsub_create_memfd(name, (uint32_t)capacity, PUBSUB_MODE_STR, msg_size, errbuf);
    if (!h) croak("Data::PubSub::Shared::Str->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    PubSubHandle *h = pubsub_open_fd(fd, PUBSUB_MODE_STR, errbuf);
    if (!h) croak("Data::PubSub::Shared::Str->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    pubsub_destroy(h);

SV *
publish(self, value)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    STRLEN len;
    bool utf8 = SvUTF8(value) ? true : false;
    const char *str;
    if (utf8)
        str = SvPVutf8(value, len);
    else
        str = SvPV(value, len);
    int r = pubsub_str_publish(h, str, (uint32_t)len, utf8);
    if (r == -1) croak("publish: message too long (%u > %u)", (unsigned)len, h->msg_size);
    RETVAL = &PL_sv_yes;
  OUTPUT:
    RETVAL

UV
publish_multi(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = 0;
    uint32_t count = items - 1;
    if (count > 0) {
        pubsub_mutex_lock(h->hdr);
        for (uint32_t i = 0; i < count; i++) {
            SV *val = ST(i + 1);
            STRLEN len;
            bool utf8 = SvUTF8(val) ? true : false;
            const char *str;
            if (utf8)
                str = SvPVutf8(val, len);
            else
                str = SvPV(val, len);
            int r = pubsub_str_publish_locked(h, str, (uint32_t)len, utf8);
            if (r == -1) {
                pubsub_mutex_unlock(h->hdr);
                croak("publish_multi: message too long (%u > %u)", (unsigned)len, h->msg_size);
            }
            RETVAL++;
        }
        pubsub_mutex_unlock(h->hdr);
        pubsub_wake_subscribers(h->hdr);
    }
  OUTPUT:
    RETVAL

void
publish_notify(self, value)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    STRLEN len;
    bool utf8 = SvUTF8(value) ? true : false;
    const char *str;
    if (utf8)
        str = SvPVutf8(value, len);
    else
        str = SvPV(value, len);
    int r = pubsub_str_publish(h, str, (uint32_t)len, utf8);
    if (r == -1) croak("publish_notify: message too long (%u > %u)", (unsigned)len, h->msg_size);
    pubsub_notify(h);

SV *
subscribe(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 0);
    if (!sub) croak("subscribe: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Str::Sub", sub);
  OUTPUT:
    RETVAL

SV *
subscribe_all(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 1);
    if (!sub) croak("subscribe_all: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Str::Sub", sub);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = h->capacity;
  OUTPUT:
    RETVAL

UV
msg_size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = h->msg_size;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&h->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    HV *hv = newHV();
    PubSubHeader *hdr = h->hdr;
    hv_store(hv, "capacity", 8, newSVuv(h->capacity), 0);
    hv_store(hv, "msg_size", 8, newSVuv(h->msg_size), 0);
    hv_store(hv, "arena_cap", 9, newSVuv((UV)h->arena_cap), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "write_pos", 9,
        newSVuv((UV)__atomic_load_n(&hdr->write_pos, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "publish_ok", 10,
        newSVuv((UV)__atomic_load_n(&hdr->stat_publish_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10,
        newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "sub_waiters", 11,
        newSVuv(__atomic_load_n(&hdr->sub_waiters, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    pubsub_clear(h);

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    if (pubsub_sync(h) != 0)
        croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::PubSub::Shared::Str->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd pubsub");
    if (unlink(path) != 0)
        croak("unlink(%s): %s", path, strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = pubsub_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    pubsub_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    int64_t v = pubsub_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Str", self);
  CODE:
    pubsub_notify(h);

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Str::Sub

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubSub *sub = INT2PTR(PubSubSub*, SvIV(SvRV(self)));
    if (!sub) return;
    sv_setiv(SvRV(self), 0);
    if (sub->userdata) SvREFCNT_dec((SV *)sub->userdata);
    pubsub_sub_destroy(sub);

SV *
poll(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    int r = pubsub_str_poll(sub, &str, &len, &utf8);
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
poll_multi(self, count)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
    const char *str;
    uint32_t len;
    bool utf8;
  PPCODE:
    for (UV i = 0; i < count; i++) {
        int r = pubsub_str_poll(sub, &str, &len, &utf8);
        if (r != 1) break;
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }

SV *
poll_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int r = pubsub_str_poll_wait(sub, &str, &len, &utf8, timeout);
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
    const char *str;
    uint32_t len;
    bool utf8;
    uint32_t max_count;
  PPCODE:
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_str_poll(sub, &str, &len, &utf8) == 1) {
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }

void
poll_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    bool utf8;
  PPCODE:
    if (count == 0) XSRETURN(0);
    if (items > 2) timeout = SvNV(ST(2));
    if (pubsub_str_poll_wait(sub, &str, &len, &utf8, timeout) != 1) XSRETURN(0);
    {
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }
    for (UV i = 1; i < count; i++) {
        if (pubsub_str_poll(sub, &str, &len, &utf8) != 1) break;
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }

UV
lag(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    RETVAL = (UV)pubsub_lag(sub);
  OUTPUT:
    RETVAL

UV
overflow_count(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    RETVAL = (UV)sub->overflow_count;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

bool
has_overflow(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
    RETVAL = (sub->cursor < wp && wp - sub->cursor > sub->capacity);
  OUTPUT:
    RETVAL

UV
cursor(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    if (items > 1) sub->cursor = (uint64_t)SvUV(ST(1));
    RETVAL = (UV)sub->cursor;
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    sub->cursor = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);

void
reset_oldest(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);
    sub->cursor = (wp > sub->capacity) ? wp - sub->capacity : 0;

UV
poll_cb(self, cb)
    SV *self
    SV *cb
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    RETVAL = 0;
    while (pubsub_str_poll(sub, &str, &len, &utf8) == 1) {
        dSP;
        ENTER; SAVETMPS;
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        PUSHMARK(SP);
        mXPUSHs(sv);
        PUTBACK;
        call_sv(cb, G_DISCARD);
        FREETMPS; LEAVE;
        RETVAL++;
    }
  OUTPUT:
    RETVAL

void
drain_notify(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
    const char *str;
    uint32_t len;
    bool utf8;
    uint32_t max_count;
  PPCODE:
    pubsub_sub_eventfd_consume(sub);
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_str_poll(sub, &str, &len, &utf8) == 1) {
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    sub->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Str::Sub", self);
  CODE:
    RETVAL = sub->notify_fd;
  OUTPUT:
    RETVAL

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Int32

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PubSubHandle *h = pubsub_create(p, (uint32_t)capacity, PUBSUB_MODE_INT32, 0, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int32->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    PubSubHandle *h = pubsub_create_memfd(name, (uint32_t)capacity, PUBSUB_MODE_INT32, 0, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int32->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    PubSubHandle *h = pubsub_open_fd(fd, PUBSUB_MODE_INT32, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int32->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    pubsub_destroy(h);

bool
publish(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    RETVAL = pubsub_int32_publish(h, (int32_t)value);
  OUTPUT:
    RETVAL

UV
publish_multi(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    uint32_t count = items - 1;
    if (count == 0) { RETVAL = 0; }
    else {
        if (count > 8192) croak("publish_multi: too many values (%u > 8192)", count);
        int32_t *vals = (int32_t *)alloca(count * sizeof(int32_t));
        for (uint32_t i = 0; i < count; i++)
            vals[i] = (int32_t)SvIV(ST(i + 1));
        RETVAL = pubsub_int32_publish_multi(h, vals, count);
    }
  OUTPUT:
    RETVAL

void
publish_notify(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    pubsub_int32_publish(h, (int32_t)value);
    pubsub_notify(h);

SV *
subscribe(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 0);
    if (!sub) croak("subscribe: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Int32::Sub", sub);
  OUTPUT:
    RETVAL

SV *
subscribe_all(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 1);
    if (!sub) croak("subscribe_all: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Int32::Sub", sub);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    RETVAL = h->capacity;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&h->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    HV *hv = newHV();
    PubSubHeader *hdr = h->hdr;
    hv_store(hv, "capacity", 8, newSVuv(h->capacity), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "write_pos", 9,
        newSVuv((UV)__atomic_load_n(&hdr->write_pos, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "publish_ok", 10,
        newSVuv((UV)__atomic_load_n(&hdr->stat_publish_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10,
        newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "sub_waiters", 11,
        newSVuv(__atomic_load_n(&hdr->sub_waiters, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    pubsub_clear(h);

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    if (pubsub_sync(h) != 0)
        croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::PubSub::Shared::Int32->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd pubsub");
    if (unlink(path) != 0)
        croak("unlink(%s): %s", path, strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    RETVAL = pubsub_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    pubsub_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    int64_t v = pubsub_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int32", self);
  CODE:
    pubsub_notify(h);

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Int32::Sub

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubSub *sub = INT2PTR(PubSubSub*, SvIV(SvRV(self)));
    if (!sub) return;
    sv_setiv(SvRV(self), 0);
    if (sub->userdata) SvREFCNT_dec((SV *)sub->userdata);
    pubsub_sub_destroy(sub);

SV *
poll(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
    int32_t value;
  CODE:
    int r = pubsub_int32_poll(sub, &value);
    if (r == 1)
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
poll_multi(self, count)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
    int32_t value;
  PPCODE:
    for (UV i = 0; i < count; i++) {
        int r = pubsub_int32_poll(sub, &value);
        if (r != 1) break;
        mXPUSHi((IV)value);
    }

SV *
poll_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
    double timeout = -1;
    int32_t value;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int r = pubsub_int32_poll_wait(sub, &value, timeout);
    if (r == 1)
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
    int32_t value;
    uint32_t max_count;
  PPCODE:
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_int32_poll(sub, &value))
        mXPUSHi((IV)value);

void
poll_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
    double timeout = -1;
    int32_t value;
  PPCODE:
    if (count == 0) XSRETURN(0);
    if (items > 2) timeout = SvNV(ST(2));
    if (!pubsub_int32_poll_wait(sub, &value, timeout)) XSRETURN(0);
    mXPUSHi((IV)value);
    for (UV i = 1; i < count; i++) {
        if (!pubsub_int32_poll(sub, &value)) break;
        mXPUSHi((IV)value);
    }

UV
lag(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    RETVAL = (UV)pubsub_lag(sub);
  OUTPUT:
    RETVAL

UV
overflow_count(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    RETVAL = (UV)sub->overflow_count;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

bool
has_overflow(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
    RETVAL = (sub->cursor < wp && wp - sub->cursor > sub->capacity);
  OUTPUT:
    RETVAL

UV
cursor(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    if (items > 1) sub->cursor = (uint64_t)SvUV(ST(1));
    RETVAL = (UV)sub->cursor;
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    sub->cursor = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);

void
reset_oldest(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);
    sub->cursor = (wp > sub->capacity) ? wp - sub->capacity : 0;

UV
poll_cb(self, cb)
    SV *self
    SV *cb
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
    int32_t value;
  CODE:
    RETVAL = 0;
    while (pubsub_int32_poll(sub, &value)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi((IV)value);
        PUTBACK;
        call_sv(cb, G_DISCARD);
        FREETMPS; LEAVE;
        RETVAL++;
    }
  OUTPUT:
    RETVAL

void
drain_notify(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
    int32_t value;
    uint32_t max_count;
  PPCODE:
    pubsub_sub_eventfd_consume(sub);
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_int32_poll(sub, &value))
        mXPUSHi((IV)value);

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    sub->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int32::Sub", self);
  CODE:
    RETVAL = sub->notify_fd;
  OUTPUT:
    RETVAL

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Int16

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    PubSubHandle *h = pubsub_create(p, (uint32_t)capacity, PUBSUB_MODE_INT16, 0, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int16->new: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    PubSubHandle *h = pubsub_create_memfd(name, (uint32_t)capacity, PUBSUB_MODE_INT16, 0, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int16->new_memfd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[PUBSUB_ERR_BUFLEN];
  CODE:
    PubSubHandle *h = pubsub_open_fd(fd, PUBSUB_MODE_INT16, errbuf);
    if (!h) croak("Data::PubSub::Shared::Int16->new_from_fd: %s", errbuf);
    MAKE_OBJ(class, h);
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self)));
    if (!h) return;
    sv_setiv(SvRV(self), 0);
    pubsub_destroy(h);

bool
publish(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    RETVAL = pubsub_int16_publish(h, (int16_t)value);
  OUTPUT:
    RETVAL

UV
publish_multi(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    uint32_t count = items - 1;
    if (count == 0) { RETVAL = 0; }
    else {
        if (count > 8192) croak("publish_multi: too many values (%u > 8192)", count);
        int16_t *vals = (int16_t *)alloca(count * sizeof(int16_t));
        for (uint32_t i = 0; i < count; i++)
            vals[i] = (int16_t)SvIV(ST(i + 1));
        RETVAL = pubsub_int16_publish_multi(h, vals, count);
    }
  OUTPUT:
    RETVAL

void
publish_notify(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    pubsub_int16_publish(h, (int16_t)value);
    pubsub_notify(h);

SV *
subscribe(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 0);
    if (!sub) croak("subscribe: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Int16::Sub", sub);
  OUTPUT:
    RETVAL

SV *
subscribe_all(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    PubSubSub *sub = pubsub_subscribe(h, 1);
    if (!sub) croak("subscribe_all: out of memory");
    sub->userdata = (void *)newSVsv(self);
    MAKE_OBJ("Data::PubSub::Shared::Int16::Sub", sub);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    RETVAL = h->capacity;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&h->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    HV *hv = newHV();
    PubSubHeader *hdr = h->hdr;
    hv_store(hv, "capacity", 8, newSVuv(h->capacity), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "write_pos", 9,
        newSVuv((UV)__atomic_load_n(&hdr->write_pos, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "publish_ok", 10,
        newSVuv((UV)__atomic_load_n(&hdr->stat_publish_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10,
        newSVuv(__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "sub_waiters", 11,
        newSVuv(__atomic_load_n(&hdr->sub_waiters, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    pubsub_clear(h);

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    if (pubsub_sync(h) != 0)
        croak("msync: %s", strerror(errno));

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        PubSubHandle *h = INT2PTR(PubSubHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::PubSub::Shared::Int16->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd pubsub");
    if (unlink(path) != 0)
        croak("unlink(%s): %s", path, strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    RETVAL = pubsub_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    pubsub_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    int64_t v = pubsub_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::PubSub::Shared::Int16", self);
  CODE:
    pubsub_notify(h);

MODULE = Data::PubSub::Shared  PACKAGE = Data::PubSub::Shared::Int16::Sub

void
DESTROY(self)
    SV *self
  CODE:
    if (!SvROK(self)) return;
    PubSubSub *sub = INT2PTR(PubSubSub*, SvIV(SvRV(self)));
    if (!sub) return;
    sv_setiv(SvRV(self), 0);
    if (sub->userdata) SvREFCNT_dec((SV *)sub->userdata);
    pubsub_sub_destroy(sub);

SV *
poll(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
    int16_t value;
  CODE:
    int r = pubsub_int16_poll(sub, &value);
    if (r == 1)
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
poll_multi(self, count)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
    int16_t value;
  PPCODE:
    for (UV i = 0; i < count; i++) {
        int r = pubsub_int16_poll(sub, &value);
        if (r != 1) break;
        mXPUSHi((IV)value);
    }

SV *
poll_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
    double timeout = -1;
    int16_t value;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int r = pubsub_int16_poll_wait(sub, &value, timeout);
    if (r == 1)
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
    int16_t value;
    uint32_t max_count;
  PPCODE:
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_int16_poll(sub, &value))
        mXPUSHi((IV)value);

void
poll_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
    double timeout = -1;
    int16_t value;
  PPCODE:
    if (count == 0) XSRETURN(0);
    if (items > 2) timeout = SvNV(ST(2));
    if (!pubsub_int16_poll_wait(sub, &value, timeout)) XSRETURN(0);
    mXPUSHi((IV)value);
    for (UV i = 1; i < count; i++) {
        if (!pubsub_int16_poll(sub, &value)) break;
        mXPUSHi((IV)value);
    }

UV
lag(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    RETVAL = (UV)pubsub_lag(sub);
  OUTPUT:
    RETVAL

UV
overflow_count(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    RETVAL = (UV)sub->overflow_count;
  OUTPUT:
    RETVAL

UV
write_pos(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    RETVAL = (UV)__atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
  OUTPUT:
    RETVAL

bool
has_overflow(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_RELAXED);
    RETVAL = (sub->cursor < wp && wp - sub->cursor > sub->capacity);
  OUTPUT:
    RETVAL

UV
cursor(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    if (items > 1) sub->cursor = (uint64_t)SvUV(ST(1));
    RETVAL = (UV)sub->cursor;
  OUTPUT:
    RETVAL

void
reset(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    sub->cursor = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);

void
reset_oldest(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    uint64_t wp = __atomic_load_n(&sub->hdr->write_pos, __ATOMIC_ACQUIRE);
    sub->cursor = (wp > sub->capacity) ? wp - sub->capacity : 0;

UV
poll_cb(self, cb)
    SV *self
    SV *cb
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
    int16_t value;
  CODE:
    RETVAL = 0;
    while (pubsub_int16_poll(sub, &value)) {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP);
        mXPUSHi((IV)value);
        PUTBACK;
        call_sv(cb, G_DISCARD);
        FREETMPS; LEAVE;
        RETVAL++;
    }
  OUTPUT:
    RETVAL

void
drain_notify(self, ...)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
    int16_t value;
    uint32_t max_count;
  PPCODE:
    pubsub_sub_eventfd_consume(sub);
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && pubsub_int16_poll(sub, &value))
        mXPUSHi((IV)value);

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    sub->notify_fd = fd;

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_SUB("Data::PubSub::Shared::Int16::Sub", self);
  CODE:
    RETVAL = sub->notify_fd;
  OUTPUT:
    RETVAL
