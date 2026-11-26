#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "queue.h"

/* Narrow a Perl string length to the uint32 wire width WITHOUT silent truncation:
 * a length that doesn't fit maps to UINT32_MAX so the downstream < 2 GiB size
 * check croaks, instead of the value wrapping to a small, wrongly-accepted length.
 * Defined unconditionally (NOT inside the XS::Parse::Keyword guard) so it exists
 * even where that optional dependency is absent. */
#define LEN32(len) ((len) > (STRLEN)0xFFFFFFFFU ? 0xFFFFFFFFU : (uint32_t)(len))

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
    if (!h) croak("Attempted to use a destroyed %s object", classname); \
    QueueHandle *h0 = h; PERL_UNUSED_VAR(h0); \
    sv_2mortal(SvREFCNT_inc(SvRV(sv)))

/* Re-read the handle after a call that can run Perl code (tied/overloaded
 * argument magic, tied-array fetches).  That code may call $obj->DESTROY
 * explicitly, which frees the handle and zeroes the IV; EXTRACT_HANDLE's
 * mortal pins the referent only against refcount-driven destruction, not an
 * explicit DESTROY, so the local h would dangle.  Used only where magic
 * can actually intervene between EXTRACT_HANDLE and the first use of h. */
#define REEXTRACT_HANDLE(classname, sv) \
    if (!SvROK(sv)) \
        croak("%s object was replaced during the call", classname); \
    h = INT2PTR(QueueHandle*, SvIV(SvRV(sv))); \
    if (h != h0) croak("%s object replaced or destroyed during the call", classname)

#define MAKE_OBJ(class, ptr) \
    SV *ref = newRV_noinc(newSViv(PTR2IV(ptr))); \
    sv_bless(ref, gv_stashpv(class, GV_ADD)); \
    RETVAL = ref

#define OPT_ARG(n) (items > (n) && (SvGETMAGIC(ST(n)), SvOK(ST(n))))
#define STR_TOO_BIG "Data::Queue::Shared::Str: string too big (exceeds arena capacity or 2GB limit)"
#define STR_OOM "Data::Queue::Shared::Str: out of memory"

/* $! after a Str operation that did nothing: its reason, or 0 for a plain full or empty queue. */
static void str_errno(QueueHandle *h, int r) {
    errno = r == QUEUE_FAILED ? h->fail_errno : 0;
}

static bool str_ok(pTHX_ QueueHandle *h, int r) {
    if (r == -2) croak(STR_TOO_BIG);
    if (r != 1) str_errno(h, r);
    return r == 1;
}

static SV *str_sv(pTHX_ QueueHandle *h, int r, const char *str, uint32_t len, bool utf8) {
    if (r == -1) croak(STR_OOM);
    if (r != 1) { str_errno(h, r); return &PL_sv_undef; }
    SV *sv = newSVpvn(str, len);
    if (utf8) SvUTF8_on(sv);
    return sv;
}

typedef struct { char *buf; uint32_t len; bool utf8; } StrItem;

/* Pops up to count values under one hold of the lock, ending before one that would take the
 * batch past max_bytes; unless a value was taken before, the first one always comes. Copies
 * them out so that no Perl allocation, which can croak, happens under the lock. */
static StrItem *str_pop_batch(pTHX_ QueueHandle *h, UV count, uint64_t max_bytes,
                              uint64_t bytes, int taken, UV *n_out) {
    *n_out = 0;
    if (count > h->capacity) count = h->capacity;
    if (!count) return NULL;
    StrItem *it = (StrItem *)malloc((size_t)count * sizeof *it);
    if (!it) croak(STR_OOM);
    if (!queue_str_lock(h)) { free(it); str_errno(h, QUEUE_FAILED); return NULL; }
    UV n = 0;
    int r = 1;
    while (n < count && !((n || taken) && bytes + queue_str_front_len(h) > max_bytes)) {
        const char *str; uint32_t len; bool utf8;
        r = queue_str_pop_locked(h, &str, &len, &utf8);
        if (r != 1) break;
        char *c = (char *)malloc(len ? len : 1);
        if (!c) { r = -1; break; }
        memcpy(c, str, len);
        it[n].buf = c; it[n].len = len; it[n].utf8 = utf8;
        n++;
        bytes += len;
    }
    uint32_t wake = n ? queue_str_producer_wake_count(h->hdr, (uint32_t)n) : 0;
    queue_mutex_unlock(h->hdr);
    if (wake) queue_wake_producers_n(h->hdr, wake);
    if (r == -1) {
        while (n) free(it[--n].buf);
        free(it);
        croak(STR_OOM);
    }
    if (!n) errno = 0;
    *n_out = n;
    return it;
}

static SV **str_push_items(pTHX_ SV **sp, StrItem *it, UV n) {
    EXTEND(sp, (SSize_t)n);
    for (UV i = 0; i < n; i++) {
        SV *sv = newSVpvn(it[i].buf, it[i].len);
        if (it[i].utf8) SvUTF8_on(sv);
        PUSHs(sv_2mortal(sv));
        free(it[i].buf);
    }
    free(it);
    return sp;
}

MODULE = Data::Queue::Shared  PACKAGE = Data::Queue::Shared::Int

PROTOTYPES: DISABLE

BOOT:
#ifdef HAVE_XS_PARSE_KEYWORD
    boot_xs_parse_keyword(0.50);
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
/* XSMARKER: end of BOOT -- INCLUDE_COMMAND regex must strip BOOT from generated sections */

SV *
new(class, path, capacity, ...)
    const char *class
    SV *path
    UV capacity
  PREINIT:
    char errbuf[QUEUE_ERR_BUFLEN];
  CODE:
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    /* Optional 4th arg: file mode for a new file-backed segment (default 0600,
     * owner-only); pass e.g. 0660 to opt into cross-user sharing. */
    mode_t fmode = OPT_ARG(3) ? (mode_t)SvUV_nomg(ST(3)) : 0600;
    QueueHandle *h = queue_create(p, (uint32_t)capacity, QUEUE_MODE_INT, 0, fmode, errbuf);
    if (!h) croak("Data::Queue::Shared::Int->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
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
    if (!h) croak("Data::Queue::Shared::Int->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
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
    if (!h) croak("Data::Queue::Shared::Int->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
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
  CODE:
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::Queue::Shared::Int")) return;
    QueueHandle *h = INT2PTR(QueueHandle*, SvIV(SvRV(self)));
    if (!h) return;
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
    if (OPT_ARG(2)) timeout = SvNV_nomg(ST(2));
    REEXTRACT_HANDLE("Data::Queue::Shared::Int", self);
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
    if (OPT_ARG(1)) timeout = SvNV_nomg(ST(1));
    REEXTRACT_HANDLE("Data::Queue::Shared::Int", self);
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
        int64_t v = (int64_t)SvIV(ST(i + 1));
        REEXTRACT_HANDLE("Data::Queue::Shared::Int", self);
        if (!queue_int_try_push(h, v)) break;
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
    if (count > h->capacity) count = h->capacity;
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
    if (sv_isobject(self_or_class) && sv_derived_from(self_or_class, "Data::Queue::Shared::Int")) {
        QueueHandle *h = INT2PTR(QueueHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::Queue::Shared::Int->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd queue");
    if (unlink(path) != 0 && errno != ENOENT)
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
    hv_store(hv, "push_ok", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_push_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pop_ok", 6, newSVuv((UV)__atomic_load_n(&hdr->stat_pop_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "push_full", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_push_full, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pop_empty", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_pop_empty, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "push_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->push_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pop_waiters", 11, newSVuv((UV)__atomic_load_n(&hdr->pop_waiters, __ATOMIC_RELAXED)), 0);
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
    max_count = OPT_ARG(1) ? (uint32_t)SvUV_nomg(ST(1)) : UINT32_MAX;
    REEXTRACT_HANDLE("Data::Queue::Shared::Int", self);
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
    if (OPT_ARG(2)) timeout = SvNV_nomg(ST(2));
    REEXTRACT_HANDLE("Data::Queue::Shared::Int", self);
    if (count > h->capacity) count = h->capacity;
    if (count == 0) XSRETURN(0);
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
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) queue_make_deadline(timeout, &dl);
    RETVAL = 0;
    for (uint32_t i = 0; i < nvalues; i++) {
        double t = timeout;
        if (has_dl) {
            t = queue_remaining_time(&dl, &rem)
                ? (double)rem.tv_sec + (double)rem.tv_nsec * 1e-9 : 0;
        }
        int64_t v = (int64_t)SvIV(ST(i + 2));
        REEXTRACT_HANDLE("Data::Queue::Shared::Int", self);
        if (!queue_int_push_wait(h, v, t)) break;
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

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Int", self);
  CODE:
    IV v = (IV)queue_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

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
    const char *p = (SvGETMAGIC(path), SvOK(path)) ? SvPV_nolen(path) : NULL;
    /* Optional 5th arg: file mode (default 0600); arena_cap is the optional 4th. */
    mode_t fmode = OPT_ARG(4) ? (mode_t)SvUV_nomg(ST(4)) : 0600;
    QueueHandle *h = queue_create(p, (uint32_t)capacity, QUEUE_MODE_STR, arena_cap, fmode, errbuf);
    if (!h) croak("Data::Queue::Shared::Str->new: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
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
    if (!h) croak("Data::Queue::Shared::Str->new_memfd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
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
    if (!h) croak("Data::Queue::Shared::Str->new_from_fd: %s", errbuf[0] ? errbuf : "out of memory");
    MAKE_OBJ(class, h);
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
  CODE:
    if (!sv_isobject(self) || !sv_derived_from(self, "Data::Queue::Shared::Str")) return;
    QueueHandle *h = INT2PTR(QueueHandle*, SvIV(SvRV(self)));
    if (!h) return;
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
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    int r = queue_str_try_push(h, str, LEN32(len), utf8);
    RETVAL = str_ok(aTHX_ h, r);
  OUTPUT:
    RETVAL

SV *
pop(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str = NULL;
    uint32_t len = 0;
    bool utf8 = false;
  CODE:
    int r = queue_str_try_pop(h, &str, &len, &utf8);
    RETVAL = str_sv(aTHX_ h, r, str, len, utf8);
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
    if (OPT_ARG(2)) timeout = SvNV_nomg(ST(2));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    int r = queue_str_push_wait(h, str, LEN32(len), utf8, timeout);
    RETVAL = str_ok(aTHX_ h, r);
  OUTPUT:
    RETVAL

SV *
pop_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    const char *str = NULL;
    uint32_t len = 0;
    bool utf8 = false;
  CODE:
    if (OPT_ARG(1)) timeout = SvNV_nomg(ST(1));
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    int r = queue_str_pop_wait(h, &str, &len, &utf8, timeout);
    RETVAL = str_sv(aTHX_ h, r, str, len, utf8);
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
    if (count > h->capacity) count = h->capacity;
    /* Extract SV data BEFORE locking: SvPV can run magic (tied/overloaded
     * stringification) that longjmps; doing it under the process-shared
     * mutex would abandon the lock and deadlock peers. Newx+SAVEFREEPV so a
     * die during extraction (or the too-long croak) cannot leak args. */
    struct qsm_arg { const char *str; STRLEN len; bool utf8; };
    struct qsm_arg *args = NULL;
    if (count > 0) {
        Newx(args, count, struct qsm_arg);
        SAVEFREEPV(args);
        for (uint32_t i = 0; i < count; i++) {
            SV *sv = ST(i + 1);
            STRLEN len;
            const char *src = SvPV(sv, len); /* may run overload/tie/get-magic = arbitrary Perl */
            bool utf8 = SvUTF8(sv) ? true : false;
            /* Copy bytes into a private mortal SV NOW: a LATER element's SvPV
             * can grow/free THIS element's PV (or reassign this scalar),
             * dangling src before the locked loop memcpy's from it. */
            SV *copy = sv_2mortal(newSVpvn(src, len));
            args[i].str = SvPVX_const(copy);
            args[i].len = len;
            args[i].utf8 = utf8;
        }
    }
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    if (!queue_str_lock(h)) {
        str_errno(h, QUEUE_FAILED);
        XSRETURN_UV(0);
    }
    int r = 1;
    for (uint32_t i = 0; i < count; i++) {
        r = queue_str_push_locked(h, args[i].str, LEN32(args[i].len), args[i].utf8);
        if (r == -2) {
            if (pushed) queue_wake_consumers_n(h->hdr, pushed);
            queue_mutex_unlock(h->hdr);
            croak(STR_TOO_BIG);
        }
        if (r != 1) break;
        pushed++;
    }
    queue_mutex_unlock(h->hdr);
    if (pushed) queue_wake_consumers_n(h->hdr, pushed);
    if (r != 1) str_errno(h, r);
    RETVAL = pushed;
  OUTPUT:
    RETVAL

void
pop_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    UV n;
  PPCODE:
    uint64_t max_bytes = OPT_ARG(2) ? SvUV_nomg(ST(2)) : UINT64_MAX;
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    StrItem *it = str_pop_batch(aTHX_ h, count, max_bytes, 0, 0, &n);
    SP = str_push_items(aTHX_ SP, it, n);

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

bool
clear(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    RETVAL = str_ok(aTHX_ h, queue_str_clear(h));
  OUTPUT:
    RETVAL

SV *
lock_timeout(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    if (items > 1) {
        double v = OPT_ARG(1) ? SvNV_nomg(ST(1)) : -1;
        REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
        h->lock_timeout = v >= 0 ? v : -1;
    }
    RETVAL = h->lock_timeout < 0 ? &PL_sv_undef : newSVnv(h->lock_timeout);
  OUTPUT:
    RETVAL

void
unlink(self_or_class, ...)
    SV *self_or_class
  CODE:
    const char *path;
    if (sv_isobject(self_or_class) && sv_derived_from(self_or_class, "Data::Queue::Shared::Str")) {
        QueueHandle *h = INT2PTR(QueueHandle*, SvIV(SvRV(self_or_class)));
        if (!h) croak("Attempted to use a destroyed object");
        path = h->path;
    } else {
        if (items < 2) croak("Usage: Data::Queue::Shared::Str->unlink($path)");
        path = SvPV_nolen(ST(1));
    }
    if (!path) croak("cannot unlink anonymous or memfd queue");
    if (unlink(path) != 0 && errno != ENOENT)
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
    hv_store(hv, "arena_used", 10, newSVuv(__atomic_load_n(&hdr->arena_used, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "push_ok", 7, newSVuv((UV)__atomic_load_n(&hdr->stat_push_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pop_ok", 6, newSVuv((UV)__atomic_load_n(&hdr->stat_pop_ok, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "push_full", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_push_full, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pop_empty", 9, newSVuv((UV)__atomic_load_n(&hdr->stat_pop_empty, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "recoveries", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_recoveries, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "push_waiters", 12, newSVuv((UV)__atomic_load_n(&hdr->push_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "pop_waiters", 11, newSVuv((UV)__atomic_load_n(&hdr->pop_waiters, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "lock_waits", 10, newSVuv((UV)__atomic_load_n(&hdr->stat_lock_waits, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "lock_wait_time", 14, newSVnv(__atomic_load_n(&hdr->stat_lock_wait_ns, __ATOMIC_RELAXED) / 1e9), 0);
    hv_store(hv, "lock_wait_max", 13, newSVnv(__atomic_load_n(&hdr->stat_lock_wait_max_ns, __ATOMIC_RELAXED) / 1e9), 0);
    hv_store(hv, "lock_timeouts", 13, newSVuv((UV)__atomic_load_n(&hdr->stat_lock_timeouts, __ATOMIC_RELAXED)), 0);
    hv_store(hv, "last_recovery", 13, newSVuv((UV)__atomic_load_n(&hdr->stat_last_recovery, __ATOMIC_RELAXED)), 0);
    RETVAL = newRV_noinc((SV *)hv);
  OUTPUT:
    RETVAL

SV *
peek(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str = NULL;
    uint32_t len = 0;
    bool utf8 = false;
  CODE:
    int r = queue_str_peek(h, &str, &len, &utf8);
    RETVAL = str_sv(aTHX_ h, r, str, len, utf8);
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
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    int r = queue_str_push_front(h, str, LEN32(len), utf8);
    RETVAL = str_ok(aTHX_ h, r);
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
    if (OPT_ARG(2)) timeout = SvNV_nomg(ST(2));
    const char *str = SvPV(value, len);
    bool utf8 = SvUTF8(value) ? true : false;
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    int r = queue_str_push_front_wait(h, str, LEN32(len), utf8, timeout);
    RETVAL = str_ok(aTHX_ h, r);
  OUTPUT:
    RETVAL

void
drain(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    UV n;
  PPCODE:
    UV max_count = OPT_ARG(1) ? SvUV_nomg(ST(1)) : UINT32_MAX;
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    StrItem *it = str_pop_batch(aTHX_ h, max_count, UINT64_MAX, 0, 0, &n);
    SP = str_push_items(aTHX_ SP, it, n);

void
pop_wait_multi(self, count, ...)
    SV *self
    UV count
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    const char *str = NULL;
    uint32_t len = 0;
    bool utf8 = false;
    UV n;
  PPCODE:
    if (OPT_ARG(2)) timeout = SvNV_nomg(ST(2));
    uint64_t max_bytes = OPT_ARG(3) ? SvUV_nomg(ST(3)) : UINT64_MAX;
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    if (count == 0) XSRETURN(0);
    int r = queue_str_pop_wait(h, &str, &len, &utf8, timeout);
    SV *first = str_sv(aTHX_ h, r, str, len, utf8);
    if (r != 1) XSRETURN(0);
    XPUSHs(sv_2mortal(first));
    StrItem *it = str_pop_batch(aTHX_ h, count - 1, max_bytes, len, 1, &n);
    SP = str_push_items(aTHX_ SP, it, n);

UV
push_wait_multi(self, timeout, ...)
    SV *self
    double timeout
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    uint32_t nvalues = items - 2;
    struct timespec dl, rem;
    int has_dl = (timeout > 0);
    if (has_dl) queue_make_deadline(timeout, &dl);
    RETVAL = 0;
    for (uint32_t i = 0; i < nvalues; i++) {
        double t = timeout;
        if (has_dl) {
            t = queue_remaining_time(&dl, &rem)
                ? (double)rem.tv_sec + (double)rem.tv_nsec * 1e-9 : 0;
        }
        SV *sv = ST(i + 2);
        STRLEN len;
        const char *str = SvPV(sv, len);
        bool utf8 = SvUTF8(sv) ? true : false;
        REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
        if (!str_ok(aTHX_ h, queue_str_push_wait(h, str, LEN32(len), utf8, t))) break;
        RETVAL++;
    }
  OUTPUT:
    RETVAL

SV *
pop_back(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    const char *str = NULL;
    uint32_t len = 0;
    bool utf8 = false;
  CODE:
    int r = queue_str_pop_back(h, &str, &len, &utf8);
    RETVAL = str_sv(aTHX_ h, r, str, len, utf8);
  OUTPUT:
    RETVAL

SV *
pop_back_wait(self, ...)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    double timeout = -1;
    const char *str = NULL;
    uint32_t len = 0;
    bool utf8 = false;
  CODE:
    if (OPT_ARG(1)) timeout = SvNV_nomg(ST(1));
    REEXTRACT_HANDLE("Data::Queue::Shared::Str", self);
    int r = queue_str_pop_back_wait(h, &str, &len, &utf8, timeout);
    RETVAL = str_sv(aTHX_ h, r, str, len, utf8);
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

SV *
eventfd_consume(self)
    SV *self
  PREINIT:
    EXTRACT_HANDLE("Data::Queue::Shared::Str", self);
  CODE:
    int64_t v = queue_eventfd_consume(h);
    RETVAL = (v >= 0) ? newSViv((IV)v) : &PL_sv_undef;
  OUTPUT:
    RETVAL

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
