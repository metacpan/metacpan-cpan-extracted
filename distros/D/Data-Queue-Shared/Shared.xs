#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "queue.h"

#ifdef HAVE_XS_PARSE_KEYWORD
#include "XSParseKeyword.h"

/* ---- Keyword build functions (compile keywords to direct ENTERSUB ops) ---- */

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

/* Hook definition macro: q_<variant>_<op> */
#define DEFINE_Q_KW(variant, PKG, kw, nargs, builder) \
    static const struct XSParseKeywordHooks hooks_q_##variant##_##kw = { \
        .flags = XPK_FLAG_EXPR, \
        .permit_hintkey = "Data::Queue::Shared::" PKG "/q_" #variant "_" #kw, \
        .pieces = pieces_##nargs##expr, \
        .build = builder, \
    };

/* Int keywords */
DEFINE_Q_KW(int, "Int", push, 2, build_kw_2arg)
DEFINE_Q_KW(int, "Int", pop,  1, build_kw_1arg)
DEFINE_Q_KW(int, "Int", peek, 1, build_kw_1arg)
DEFINE_Q_KW(int, "Int", size, 1, build_kw_1arg)

/* Int32 keywords */
DEFINE_Q_KW(int32, "Int32", push, 2, build_kw_2arg)
DEFINE_Q_KW(int32, "Int32", pop,  1, build_kw_1arg)
DEFINE_Q_KW(int32, "Int32", peek, 1, build_kw_1arg)
DEFINE_Q_KW(int32, "Int32", size, 1, build_kw_1arg)

/* Int16 keywords */
DEFINE_Q_KW(int16, "Int16", push, 2, build_kw_2arg)
DEFINE_Q_KW(int16, "Int16", pop,  1, build_kw_1arg)
DEFINE_Q_KW(int16, "Int16", peek, 1, build_kw_1arg)
DEFINE_Q_KW(int16, "Int16", size, 1, build_kw_1arg)

/* Str keywords */
DEFINE_Q_KW(str, "Str", push, 2, build_kw_2arg)
DEFINE_Q_KW(str, "Str", pop,  1, build_kw_1arg)
DEFINE_Q_KW(str, "Str", peek, 1, build_kw_1arg)
DEFINE_Q_KW(str, "Str", size, 1, build_kw_1arg)

#define REGISTER_Q_KW(variant, kw, func_name) \
    register_xs_parse_keyword("q_" #variant "_" #kw, \
        &hooks_q_##variant##_##kw, (void*)func_name)

#endif /* HAVE_XS_PARSE_KEYWORD */

#define EXTRACT_HANDLE(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    QueueHandle *h = INT2PTR(QueueHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed %s object", classname)

MODULE = Data::Queue::Shared  PACKAGE = Data::Queue::Shared::Int

PROTOTYPES: DISABLE

BOOT:
#ifdef HAVE_XS_PARSE_KEYWORD
    boot_xs_parse_keyword(0.40);
    sv_setiv(get_sv("Data::Queue::Shared::HAVE_KEYWORDS", GV_ADD), 1);
    REGISTER_Q_KW(int, push, "Data::Queue::Shared::Int::push");
    REGISTER_Q_KW(int, pop,  "Data::Queue::Shared::Int::pop");
    REGISTER_Q_KW(int, peek, "Data::Queue::Shared::Int::peek");
    REGISTER_Q_KW(int, size, "Data::Queue::Shared::Int::size");
    REGISTER_Q_KW(int32, push, "Data::Queue::Shared::Int32::push");
    REGISTER_Q_KW(int32, pop,  "Data::Queue::Shared::Int32::pop");
    REGISTER_Q_KW(int32, peek, "Data::Queue::Shared::Int32::peek");
    REGISTER_Q_KW(int32, size, "Data::Queue::Shared::Int32::size");
    REGISTER_Q_KW(int16, push, "Data::Queue::Shared::Int16::push");
    REGISTER_Q_KW(int16, pop,  "Data::Queue::Shared::Int16::pop");
    REGISTER_Q_KW(int16, peek, "Data::Queue::Shared::Int16::peek");
    REGISTER_Q_KW(int16, size, "Data::Queue::Shared::Int16::size");
    REGISTER_Q_KW(str, push, "Data::Queue::Shared::Str::push");
    REGISTER_Q_KW(str, pop,  "Data::Queue::Shared::Str::pop");
    REGISTER_Q_KW(str, peek, "Data::Queue::Shared::Str::peek");
    REGISTER_Q_KW(str, size, "Data::Queue::Shared::Str::size");
#endif
/* XSMARKER: end of BOOT — INCLUDE_COMMAND regex must strip BOOT from generated sections */

SV *
new(class, path, capacity)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[QUEUE_ERR_BUFLEN];
  CODE:
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    QueueHandle *h = queue_create(p, (uint32_t)capacity, QUEUE_MODE_INT, 0, errbuf);
    if (!h) croak("Data::Queue::Shared::Int->new: %s", errbuf);
    SV *obj = newSViv(PTR2IV(h));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[QUEUE_ERR_BUFLEN];
  CODE:
    QueueHandle *h = queue_create_memfd(name, (uint32_t)capacity, QUEUE_MODE_INT, 0, errbuf);
    if (!h) croak("Data::Queue::Shared::Int->new_memfd: %s", errbuf);
    SV *obj = newSViv(PTR2IV(h));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[QUEUE_ERR_BUFLEN];
  CODE:
    QueueHandle *h = queue_open_fd(fd, QUEUE_MODE_INT, errbuf);
    if (!h) croak("Data::Queue::Shared::Int->new_from_fd: %s", errbuf);
    SV *obj = newSViv(PTR2IV(h));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    sv_setiv(SvRV(self), 0);
    queue_destroy(h);

bool
push(self, value)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = queue_int_try_push(h, (int64_t)value);

  OUTPUT:
    RETVAL

SV *
pop(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    int64_t value;
  CODE:
    if (queue_int_try_pop(h, &value))
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

bool
push_wait(self, value, ...)
    SV *self
    IV value
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    double timeout = -1;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    RETVAL = queue_int_push_wait(h, (int64_t)value, timeout);

  OUTPUT:
    RETVAL

SV *
pop_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    double timeout = -1;
    int64_t value;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    if (queue_int_pop_wait(h, &value, timeout))
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

UV
push_multi(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    uint32_t count = items - 1;
    uint32_t pushed = 0;
    for (uint32_t i = 0; i < count; i++) {
        if (!queue_int_try_push(h, (int64_t)SvIV(ST(i + 1)))) break;
        pushed++;
    }

    RETVAL = pushed;
  OUTPUT:
    RETVAL

void
pop_multi(self, count)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    int64_t value;
  PPCODE:
    for (UV i = 0; i < count; i++) {
        if (!queue_int_try_pop(h, &value)) break;
        mXPUSHi((IV)value);
    }

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = (UV)queue_int_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = h->capacity;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = (queue_int_size(h) == 0);
  OUTPUT:
    RETVAL

bool
is_full(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = (queue_int_size(h) >= h->capacity);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    queue_int_clear(h);

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        QueueHandle *h = INT2PTR(QueueHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::Queue::Shared::Int->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd queue");
    if (unlink(path) != 0)
        croak("unlink(%s): %s", path, strerror(errno));

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    HV *hv = newHV();
    QueueHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)queue_int_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv(h->capacity), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "push_ok", 7, newSVuv((UV)hdr->stat_push_ok), 0);
    hv_store(hv, "pop_ok", 6, newSVuv((UV)hdr->stat_pop_ok), 0);
    hv_store(hv, "push_full", 9, newSVuv((UV)hdr->stat_push_full), 0);
    hv_store(hv, "pop_empty", 9, newSVuv((UV)hdr->stat_pop_empty), 0);
    hv_store(hv, "recoveries", 10, newSVuv(hdr->stat_recoveries), 0);
    hv_store(hv, "push_waiters", 12, newSVuv(hdr->push_waiters), 0);
    hv_store(hv, "pop_waiters", 11, newSVuv(hdr->pop_waiters), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
peek(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    int64_t value;
  CODE:
    if (queue_int_peek(h, &value))
        RETVAL = newSViv((IV)value);
    else
        RETVAL = &PL_sv_undef;
  OUTPUT:
    RETVAL

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    int64_t value;
    uint32_t max_count;
  PPCODE:
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    while (max_count-- > 0 && queue_int_try_pop(h, &value))
        mXPUSHi((IV)value);

void
pop_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    double timeout = -1;
    int64_t value;
  PPCODE:
    if (items > 2) timeout = SvNV(ST(2));
    /* Block until at least 1 */
    if (!queue_int_pop_wait(h, &value, timeout)) XSRETURN(0);
    mXPUSHi((IV)value);
    /* Grab up to count-1 more non-blocking */
    for (UV i = 1; i < count; i++) {
        if (!queue_int_try_pop(h, &value)) break;
        mXPUSHi((IV)value);
    }

UV
push_wait_multi(self, timeout, ...)
    SV *self
    double timeout
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    uint32_t nvalues = items - 2;
    RETVAL = 0;
    for (uint32_t i = 0; i < nvalues; i++) {
        if (!queue_int_push_wait(h, (int64_t)SvIV(ST(i + 2)), timeout)) break;
        RETVAL++;
    }
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    if (queue_sync(h) != 0)
        croak("msync: %s", strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = queue_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    queue_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

void
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    queue_eventfd_consume(h);

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    queue_notify(h);

MODULE = Data::Queue::Shared  PACKAGE = Data::Queue::Shared::Str

SV *
new(class, path, capacity, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[QUEUE_ERR_BUFLEN];
    uint64_t arena_cap;
  CODE:
    if (items > 3)
        arena_cap = (uint64_t)SvUV(ST(3));
    else
        arena_cap = (uint64_t)capacity * 256;
    const char *p = SvOK(path) ? SvPV_nolen(path) : NULL;
    QueueHandle *h = queue_create(p, (uint32_t)capacity, QUEUE_MODE_STR, arena_cap, errbuf);
    if (!h) croak("Data::Queue::Shared::Str->new: %s", errbuf);
    SV *obj = newSViv(PTR2IV(h));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
new_memfd(class, name, capacity, ...)
    const char *class
    const char *name
    UV capacity
  PREINIT:
    char errbuf[QUEUE_ERR_BUFLEN];
    uint64_t arena_cap;
  CODE:
    if (items > 3)
        arena_cap = (uint64_t)SvUV(ST(3));
    else
        arena_cap = (uint64_t)capacity * 256;
    QueueHandle *h = queue_create_memfd(name, (uint32_t)capacity, QUEUE_MODE_STR, arena_cap, errbuf);
    if (!h) croak("Data::Queue::Shared::Str->new_memfd: %s", errbuf);
    SV *obj = newSViv(PTR2IV(h));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

SV *
new_from_fd(class, fd)
    const char *class
    int fd
  PREINIT:
    char errbuf[QUEUE_ERR_BUFLEN];
  CODE:
    QueueHandle *h = queue_open_fd(fd, QUEUE_MODE_STR, errbuf);
    if (!h) croak("Data::Queue::Shared::Str->new_from_fd: %s", errbuf);
    SV *obj = newSViv(PTR2IV(h));
    SV *ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(class, GV_ADD));
    RETVAL = ref;
  OUTPUT:
    RETVAL

IV
memfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = h->backing_fd;
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    sv_setiv(SvRV(self), 0);
    queue_destroy(h);

bool
push(self, value)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    STRLEN len;
  CODE:
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = queue_str_try_push(h, str, (uint32_t)len, utf8);
    if (r == -2) croak("Data::Queue::Shared::Str: string too long (max 2GB)");
    RETVAL = (r == 1);

  OUTPUT:
    RETVAL

SV *
pop(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    int r = queue_str_try_pop(h, &str, &len, &utf8);
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else if (r == -1) {
        croak("Data::Queue::Shared::Str: out of memory");
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

bool
push_wait(self, value, ...)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    STRLEN len;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = queue_str_push_wait(h, str, (uint32_t)len, utf8, timeout);
    if (r == -2) croak("Data::Queue::Shared::Str: string too long (max 2GB)");
    RETVAL = (r == 1);

  OUTPUT:
    RETVAL

SV *
pop_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int r = queue_str_pop_wait(h, &str, &len, &utf8, timeout);
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else if (r == -1) {
        croak("Data::Queue::Shared::Str: out of memory");
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

UV
push_multi(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    uint32_t count = items - 1;
    uint32_t pushed = 0;
    queue_mutex_lock(h->hdr);
    for (uint32_t i = 0; i < count; i++) {
        SV *sv = ST(i + 1);
        STRLEN slen;
        const char *str = SvPV(sv, slen);
        bool utf8 = SvUTF8(sv) ? true : false;
        int r = queue_str_push_locked(h, str, (uint32_t)slen, utf8);
        if (r == -2) { queue_mutex_unlock(h->hdr); croak("Data::Queue::Shared::Str: string too long (max 2GB)"); }
        if (r != 1) break;
        pushed++;
    }
    queue_mutex_unlock(h->hdr);
    if (pushed) queue_wake_consumers(h->hdr);
    RETVAL = pushed;
  OUTPUT:
    RETVAL

void
pop_multi(self, count)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str;
    uint32_t len;
    bool utf8;
  PPCODE:
    int last_r = 0;
    queue_mutex_lock(h->hdr);
    for (UV i = 0; i < count; i++) {
        last_r = queue_str_pop_locked(h, &str, &len, &utf8);
        if (last_r <= 0) break;
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }
    queue_mutex_unlock(h->hdr);
    queue_wake_producers(h->hdr);
    if (last_r == -1) croak("Data::Queue::Shared::Str: out of memory");

UV
size(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = (UV)queue_str_size(h);
  OUTPUT:
    RETVAL

UV
capacity(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = h->capacity;
  OUTPUT:
    RETVAL

bool
is_empty(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = (queue_str_size(h) == 0);
  OUTPUT:
    RETVAL

bool
is_full(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = (queue_str_size(h) >= h->capacity);
  OUTPUT:
    RETVAL

void
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    queue_str_clear(h);

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class)) {
        QueueHandle *h = INT2PTR(QueueHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::Queue::Shared::Str->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd queue");
    if (unlink(path) != 0)
        croak("unlink(%s): %s", path, strerror(errno));

SV *
path(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = h->path ? newSVpv(h->path, 0) : &PL_sv_undef;
  OUTPUT:
    RETVAL

SV *
stats(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    HV *hv = newHV();
    QueueHeader *hdr = h->hdr;
    hv_store(hv, "size", 4, newSVuv((UV)queue_str_size(h)), 0);
    hv_store(hv, "capacity", 8, newSVuv(h->capacity), 0);
    hv_store(hv, "mmap_size", 9, newSVuv((UV)h->mmap_size), 0);
    hv_store(hv, "arena_cap", 9, newSVuv((UV)h->arena_cap), 0);
    hv_store(hv, "arena_used", 10, newSVuv(hdr->arena_used), 0);
    hv_store(hv, "push_ok", 7, newSVuv((UV)hdr->stat_push_ok), 0);
    hv_store(hv, "pop_ok", 6, newSVuv((UV)hdr->stat_pop_ok), 0);
    hv_store(hv, "push_full", 9, newSVuv((UV)hdr->stat_push_full), 0);
    hv_store(hv, "pop_empty", 9, newSVuv((UV)hdr->stat_pop_empty), 0);
    hv_store(hv, "recoveries", 10, newSVuv(hdr->stat_recoveries), 0);
    hv_store(hv, "push_waiters", 12, newSVuv(hdr->push_waiters), 0);
    hv_store(hv, "pop_waiters", 11, newSVuv(hdr->pop_waiters), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
peek(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    int r = queue_str_peek(h, &str, &len, &utf8);
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else if (r == -1) {
        croak("Data::Queue::Shared::Str: out of memory");
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

bool
push_front(self, value)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    STRLEN len;
  CODE:
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = queue_str_push_front(h, str, (uint32_t)len, utf8);
    if (r == -2) croak("Data::Queue::Shared::Str: string too long (max 2GB)");
    RETVAL = (r == 1);
  OUTPUT:
    RETVAL

bool
push_front_wait(self, value, ...)
    SV *self
    SV *value
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    STRLEN len;
  CODE:
    if (items > 2) timeout = SvNV(ST(2));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    int r = queue_str_push_front_wait(h, str, (uint32_t)len, utf8, timeout);
    if (r == -2) croak("Data::Queue::Shared::Str: string too long (max 2GB)");
    RETVAL = (r == 1);
  OUTPUT:
    RETVAL

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str;
    uint32_t len;
    bool utf8;
    uint32_t max_count;
  PPCODE:
    max_count = (items > 1) ? (uint32_t)SvUV(ST(1)) : UINT32_MAX;
    int last_r = 0;
    queue_mutex_lock(h->hdr);
    while (max_count-- > 0) {
        last_r = queue_str_pop_locked(h, &str, &len, &utf8);
        if (last_r <= 0) break;
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }
    queue_mutex_unlock(h->hdr);
    queue_wake_producers(h->hdr);
    if (last_r == -1) croak("Data::Queue::Shared::Str: out of memory");

void
pop_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    bool utf8;
  PPCODE:
    if (items > 2) timeout = SvNV(ST(2));
    /* Block until at least 1 */
    {
        int r = queue_str_pop_wait(h, &str, &len, &utf8, timeout);
        if (r == -1) croak("Data::Queue::Shared::Str: out of memory");
        if (r != 1) XSRETURN(0);
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }
    /* Grab up to count-1 more non-blocking */
    for (UV i = 1; i < count; i++) {
        int r = queue_str_try_pop(h, &str, &len, &utf8);
        if (r <= 0) break;
        SV *sv = newSVpvn(str, len);
        if (utf8) SvUTF8_on(sv);
        mXPUSHs(sv);
    }

UV
push_wait_multi(self, timeout, ...)
    SV *self
    double timeout
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    uint32_t nvalues = items - 2;
    RETVAL = 0;
    for (uint32_t i = 0; i < nvalues; i++) {
        SV *sv = ST(i + 2);
        STRLEN len;
        const char *str = SvPV(sv, len);
        bool utf8 = SvUTF8(sv) ? true : false;
        int r = queue_str_push_wait(h, str, (uint32_t)len, utf8, timeout);
        if (r == -2) croak("Data::Queue::Shared::Str: string too long (max 2GB)");
        if (r != 1) break;
        RETVAL++;
    }
  OUTPUT:
    RETVAL

SV *
pop_back(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    int r = queue_str_pop_back(h, &str, &len, &utf8);
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else if (r == -1) {
        croak("Data::Queue::Shared::Str: out of memory");
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

SV *
pop_back_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    const char *str;
    uint32_t len;
    bool utf8;
  CODE:
    if (items > 1) timeout = SvNV(ST(1));
    int r = queue_str_pop_back_wait(h, &str, &len, &utf8, timeout);
    if (r == 1) {
        RETVAL = newSVpvn(str, len);
        if (utf8) SvUTF8_on(RETVAL);
    } else if (r == -1) {
        croak("Data::Queue::Shared::Str: out of memory");
    } else {
        RETVAL = &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

void
sync(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    if (queue_sync(h) != 0)
        croak("msync: %s", strerror(errno));

IV
eventfd(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = queue_eventfd_create(h);
    if (RETVAL < 0) croak("eventfd: %s", strerror(errno));
  OUTPUT:
    RETVAL

void
eventfd_set(self, fd)
    SV *self
    int fd
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    queue_eventfd_set(h, fd);

IV
fileno(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = h->notify_fd;
  OUTPUT:
    RETVAL

void
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    queue_eventfd_consume(h);

void
notify(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    queue_notify(h);

MODULE = Data::Queue::Shared  PACKAGE = Data::Queue::Shared::Int32

PROTOTYPES: DISABLE

INCLUDE_COMMAND: $^X -e "use strict; my \$t = do{local \$/; open my \$f,'<','Shared.xs' or die; <\$f>}; my (\$int_section) = \$t =~ /^(MODULE.*?PACKAGE = Data::Queue::Shared::Int\n.*?)^MODULE/ms; \$int_section =~ s/Data::Queue::Shared::Int(?!\\d)/Data::Queue::Shared::Int32/g; \$int_section =~ s/queue_int_/queue_int32_/g; \$int_section =~ s/QUEUE_MODE_INT(?!\\d)/QUEUE_MODE_INT32/g; \$int_section =~ s/int64_t/int32_t/g; \$int_section =~ s/^MODULE.*\\n//m; \$int_section =~ s/^BOOT:\\n(?:.*\\n)*?\\/\\* XSMARKER.*\\n//m; print \$int_section"

MODULE = Data::Queue::Shared  PACKAGE = Data::Queue::Shared::Int16

PROTOTYPES: DISABLE

INCLUDE_COMMAND: $^X -e "use strict; my \$t = do{local \$/; open my \$f,'<','Shared.xs' or die; <\$f>}; my (\$int_section) = \$t =~ /^(MODULE.*?PACKAGE = Data::Queue::Shared::Int\n.*?)^MODULE/ms; \$int_section =~ s/Data::Queue::Shared::Int(?!\\d)/Data::Queue::Shared::Int16/g; \$int_section =~ s/queue_int_/queue_int16_/g; \$int_section =~ s/QUEUE_MODE_INT(?!\\d)/QUEUE_MODE_INT16/g; \$int_section =~ s/int64_t/int16_t/g; \$int_section =~ s/^MODULE.*\\n//m; \$int_section =~ s/^BOOT:\\n(?:.*\\n)*?\\/\\* XSMARKER.*\\n//m; print \$int_section"
