#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "shm_i16.h"
#include "shm_i32.h"
#include "shm_ii.h"
#include "shm_i16s.h"
#include "shm_i32s.h"
#include "shm_is.h"
#include "shm_si16.h"
#include "shm_si32.h"
#include "shm_si.h"
#include "shm_ss.h"

#include "XSParseKeyword.h"

/* ---- Exception-safe lock guard for rdlock held across Perl API calls ---- */

static void shm_rdunlock_cleanup(pTHX_ void *ptr) {
    ShmHeader *hdr = (ShmHeader *)ptr;
    shm_rwlock_rdunlock(hdr);
}

#define RDLOCK_GUARD(hdr) \
    shm_rwlock_rdlock(hdr); \
    SAVEDESTRUCTOR_X(shm_rdunlock_cleanup, (void*)(hdr))

/* ---- Helper macros ---- */

#define EXTRACT_MAP(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed %s object", classname)

#define EXTRACT_STR_KEY(sv) \
    STRLEN _klen; \
    const char* _kstr = SvPV(sv, _klen); \
    if (_klen > SHM_MAX_STR_LEN) croak("key too long (max 2GB)"); \
    bool _kutf8 = SvUTF8(sv) ? true : false

#define EXTRACT_STR_VAL(sv) \
    STRLEN _vlen; \
    const char* _vstr = SvPV(sv, _vlen); \
    if (_vlen > SHM_MAX_STR_LEN) croak("value too long (max 2GB)"); \
    bool _vutf8 = SvUTF8(sv) ? true : false

#define REQUIRE_TTL(h) \
    { ShmHandle *_th = (h)->shard_handles ? (h)->shard_handles[0] : (h); \
      if (!_th->expires_at) croak("put_ttl requires a TTL-enabled map (pass ttl > 0 to constructor)"); }

#define EXTRACT_CURSOR(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(sv))); \
    if (!c) croak("Attempted to use a destroyed %s cursor", classname)

/* ---- Generic keyword build functions ---- */

static int build_kw_1arg(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *map_op = args[0]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, map_op, cvref);
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED, arglist);
    return KEYWORD_PLUGIN_EXPR;
}

static int build_kw_2arg(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *map_op = args[0]->op;
    OP *key_op = args[1]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, map_op, key_op);
    arglist = op_append_elem(OP_LIST, arglist, cvref);
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED, arglist);
    return KEYWORD_PLUGIN_EXPR;
}

static int build_kw_3arg(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *map_op = args[0]->op;
    OP *key_op = args[1]->op;
    OP *val_op = args[2]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, map_op, key_op);
    arglist = op_append_elem(OP_LIST, arglist, val_op);
    arglist = op_append_elem(OP_LIST, arglist, cvref);
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED, arglist);
    return KEYWORD_PLUGIN_EXPR;
}

static int build_kw_4arg(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *map_op = args[0]->op;
    OP *key_op = args[1]->op;
    OP *val_op = args[2]->op;
    OP *ttl_op = args[3]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, map_op, key_op);
    arglist = op_append_elem(OP_LIST, arglist, val_op);
    arglist = op_append_elem(OP_LIST, arglist, ttl_op);
    arglist = op_append_elem(OP_LIST, arglist, cvref);
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED, arglist);
    return KEYWORD_PLUGIN_EXPR;
}

static int build_kw_1arg_list(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *map_op = args[0]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, map_op, cvref);
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED | OPf_WANT_LIST, arglist);
    return KEYWORD_PLUGIN_EXPR;
}

/* ---- Keyword pieces ---- */

static const struct XSParseKeywordPieceType pieces_1expr[] = {
    XPK_TERMEXPR, {0}
};

static const struct XSParseKeywordPieceType pieces_2expr[] = {
    XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, {0}
};

static const struct XSParseKeywordPieceType pieces_3expr[] = {
    XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, {0}
};

static const struct XSParseKeywordPieceType pieces_4expr[] = {
    XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, XPK_COMMA, XPK_TERMEXPR, {0}
};

/* ---- Keyword hook definitions ---- */

#define DEFINE_KW_HOOK(variant, PKG, kw, nargs, builder) \
    static const struct XSParseKeywordHooks hooks_shm_##variant##_##kw = { \
        .flags = XPK_FLAG_EXPR, \
        .permit_hintkey = "Data::HashMap::Shared::" PKG "/shm_" #variant "_" #kw, \
        .pieces = pieces_##nargs##expr, \
        .build = builder, \
    };

/* I16 (int16 -> int16, counters) */
DEFINE_KW_HOOK(i16, "I16", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", incr,        2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", decr,        2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", incr_by,     3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i16, "I16", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", cas,             4, build_kw_4arg)
DEFINE_KW_HOOK(i16, "I16", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", set_ttl,         3, build_kw_3arg)

/* I32 (int32 -> int32, counters) */
DEFINE_KW_HOOK(i32, "I32", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", incr,        2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", decr,        2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", incr_by,     3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i32, "I32", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", cas,             4, build_kw_4arg)
DEFINE_KW_HOOK(i32, "I32", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", set_ttl,         3, build_kw_3arg)

/* II (int64 -> int64, counters) */
DEFINE_KW_HOOK(ii, "II", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", incr,        2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", decr,        2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", incr_by,     3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(ii, "II", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", cas,             4, build_kw_4arg)
DEFINE_KW_HOOK(ii, "II", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", set_ttl,         3, build_kw_3arg)

/* I16S (int16 -> string, no counters) */
DEFINE_KW_HOOK(i16s, "I16S", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i16s, "I16S", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", set_ttl,         3, build_kw_3arg)

/* I32S (int32 -> string, no counters) */
DEFINE_KW_HOOK(i32s, "I32S", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i32s, "I32S", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", set_ttl,         3, build_kw_3arg)

/* IS (int64 -> string, no counters) */
DEFINE_KW_HOOK(is, "IS", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(is, "IS", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", set_ttl,         3, build_kw_3arg)

/* SI16 (string -> int16, counters) */
DEFINE_KW_HOOK(si16, "SI16", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", incr,        2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", decr,        2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", incr_by,     3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(si16, "SI16", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", cas,             4, build_kw_4arg)
DEFINE_KW_HOOK(si16, "SI16", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", set_ttl,         3, build_kw_3arg)

/* SI32 (string -> int32, counters) */
DEFINE_KW_HOOK(si32, "SI32", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", incr,        2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", decr,        2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", incr_by,     3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(si32, "SI32", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", cas,             4, build_kw_4arg)
DEFINE_KW_HOOK(si32, "SI32", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", set_ttl,         3, build_kw_3arg)

/* SI (string -> int64, counters) */
DEFINE_KW_HOOK(si, "SI", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", incr,        2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", decr,        2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", incr_by,     3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(si, "SI", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", cas,             4, build_kw_4arg)
DEFINE_KW_HOOK(si, "SI", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", set_ttl,         3, build_kw_3arg)

/* SS (string -> string, no counters) */
DEFINE_KW_HOOK(ss, "SS", put,         3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", get,         2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", remove,      2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", exists,      2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", size,        1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", keys,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", values,      1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", items,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", each,        1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", iter_reset,  1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", clear,       1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", to_hash,     1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", max_entries, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", get_or_set,  3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(ss, "SS", max_size,   1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", ttl,        1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", cursor,       1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", cursor_next,  1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", cursor_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", cursor_seek,  2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", ttl_remaining, 2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", capacity,     1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", tombstones,   1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", take,          2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", pop,            1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", shift,            1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", drain,          2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", stat_recoveries,    1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", arena_used,       1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", arena_cap,        1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", add,              3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", update,           3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", swap,             3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", persist,         2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", set_ttl,         3, build_kw_3arg)

/* ---- Register keyword macro ---- */

#define REGISTER_KW(variant, kw, func_name) \
    register_xs_parse_keyword("shm_" #variant "_" #kw, \
        &hooks_shm_##variant##_##kw, (void*)func_name)


/* ============================================================
 * MODULE/PACKAGE sections
 * ============================================================ */


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I16
PROTOTYPES: DISABLE

BOOT:
    boot_xs_parse_keyword(0.40);
    /* I16 */
    REGISTER_KW(i16, put,         "Data::HashMap::Shared::I16::put");
    REGISTER_KW(i16, get,         "Data::HashMap::Shared::I16::get");
    REGISTER_KW(i16, remove,      "Data::HashMap::Shared::I16::remove");
    REGISTER_KW(i16, exists,      "Data::HashMap::Shared::I16::exists");
    REGISTER_KW(i16, incr,        "Data::HashMap::Shared::I16::incr");
    REGISTER_KW(i16, decr,        "Data::HashMap::Shared::I16::decr");
    REGISTER_KW(i16, incr_by,     "Data::HashMap::Shared::I16::incr_by");
    REGISTER_KW(i16, size,        "Data::HashMap::Shared::I16::size");
    REGISTER_KW(i16, keys,        "Data::HashMap::Shared::I16::keys");
    REGISTER_KW(i16, values,      "Data::HashMap::Shared::I16::values");
    REGISTER_KW(i16, items,       "Data::HashMap::Shared::I16::items");
    REGISTER_KW(i16, each,        "Data::HashMap::Shared::I16::each");
    REGISTER_KW(i16, iter_reset,  "Data::HashMap::Shared::I16::iter_reset");
    REGISTER_KW(i16, clear,       "Data::HashMap::Shared::I16::clear");
    REGISTER_KW(i16, to_hash,     "Data::HashMap::Shared::I16::to_hash");
    REGISTER_KW(i16, max_entries, "Data::HashMap::Shared::I16::max_entries");
    REGISTER_KW(i16, get_or_set,  "Data::HashMap::Shared::I16::get_or_set");
    REGISTER_KW(i16, put_ttl,    "Data::HashMap::Shared::I16::put_ttl");
    REGISTER_KW(i16, max_size,   "Data::HashMap::Shared::I16::max_size");
    REGISTER_KW(i16, ttl,        "Data::HashMap::Shared::I16::ttl");
    REGISTER_KW(i16, cursor,       "Data::HashMap::Shared::I16::cursor");
    REGISTER_KW(i16, cursor_next,  "Data::HashMap::Shared::I16::Cursor::next");
    REGISTER_KW(i16, cursor_reset, "Data::HashMap::Shared::I16::Cursor::reset");
    REGISTER_KW(i16, cursor_seek,  "Data::HashMap::Shared::I16::Cursor::seek");
    REGISTER_KW(i16, ttl_remaining, "Data::HashMap::Shared::I16::ttl_remaining");
    REGISTER_KW(i16, capacity,     "Data::HashMap::Shared::I16::capacity");
    REGISTER_KW(i16, tombstones,   "Data::HashMap::Shared::I16::tombstones");
    REGISTER_KW(i16, take,          "Data::HashMap::Shared::I16::take");
    REGISTER_KW(i16, pop,   "Data::HashMap::Shared::I16::pop");
    REGISTER_KW(i16, shift, "Data::HashMap::Shared::I16::shift");
    REGISTER_KW(i16, drain, "Data::HashMap::Shared::I16::drain");
    REGISTER_KW(i16, flush_expired, "Data::HashMap::Shared::I16::flush_expired");
    REGISTER_KW(i16, flush_expired_partial, "Data::HashMap::Shared::I16::flush_expired_partial");
    REGISTER_KW(i16, mmap_size,     "Data::HashMap::Shared::I16::mmap_size");
    REGISTER_KW(i16, touch,           "Data::HashMap::Shared::I16::touch");
    REGISTER_KW(i16, reserve,         "Data::HashMap::Shared::I16::reserve");
    REGISTER_KW(i16, stat_evictions,  "Data::HashMap::Shared::I16::stat_evictions");
    REGISTER_KW(i16, stat_expired,    "Data::HashMap::Shared::I16::stat_expired");
    REGISTER_KW(i16, stat_recoveries, "Data::HashMap::Shared::I16::stat_recoveries");    
    REGISTER_KW(i16, arena_used,       "Data::HashMap::Shared::I16::arena_used");
    REGISTER_KW(i16, arena_cap,        "Data::HashMap::Shared::I16::arena_cap");
    REGISTER_KW(i16, add,              "Data::HashMap::Shared::I16::add");
    REGISTER_KW(i16, update,           "Data::HashMap::Shared::I16::update");
    REGISTER_KW(i16, swap,             "Data::HashMap::Shared::I16::swap");
    REGISTER_KW(i16, cas,             "Data::HashMap::Shared::I16::cas");
    REGISTER_KW(i16, persist,         "Data::HashMap::Shared::I16::persist");
    REGISTER_KW(i16, set_ttl,         "Data::HashMap::Shared::I16::set_ttl");
    REGISTER_KW(i32, put,         "Data::HashMap::Shared::I32::put");
    REGISTER_KW(i32, get,         "Data::HashMap::Shared::I32::get");
    REGISTER_KW(i32, remove,      "Data::HashMap::Shared::I32::remove");
    REGISTER_KW(i32, exists,      "Data::HashMap::Shared::I32::exists");
    REGISTER_KW(i32, incr,        "Data::HashMap::Shared::I32::incr");
    REGISTER_KW(i32, decr,        "Data::HashMap::Shared::I32::decr");
    REGISTER_KW(i32, incr_by,     "Data::HashMap::Shared::I32::incr_by");
    REGISTER_KW(i32, size,        "Data::HashMap::Shared::I32::size");
    REGISTER_KW(i32, keys,        "Data::HashMap::Shared::I32::keys");
    REGISTER_KW(i32, values,      "Data::HashMap::Shared::I32::values");
    REGISTER_KW(i32, items,       "Data::HashMap::Shared::I32::items");
    REGISTER_KW(i32, each,        "Data::HashMap::Shared::I32::each");
    REGISTER_KW(i32, iter_reset,  "Data::HashMap::Shared::I32::iter_reset");
    REGISTER_KW(i32, clear,       "Data::HashMap::Shared::I32::clear");
    REGISTER_KW(i32, to_hash,     "Data::HashMap::Shared::I32::to_hash");
    REGISTER_KW(i32, max_entries, "Data::HashMap::Shared::I32::max_entries");
    REGISTER_KW(i32, get_or_set,  "Data::HashMap::Shared::I32::get_or_set");
    REGISTER_KW(i32, put_ttl,    "Data::HashMap::Shared::I32::put_ttl");
    REGISTER_KW(i32, max_size,   "Data::HashMap::Shared::I32::max_size");
    REGISTER_KW(i32, ttl,        "Data::HashMap::Shared::I32::ttl");
    REGISTER_KW(i32, cursor,       "Data::HashMap::Shared::I32::cursor");
    REGISTER_KW(i32, cursor_next,  "Data::HashMap::Shared::I32::Cursor::next");
    REGISTER_KW(i32, cursor_reset, "Data::HashMap::Shared::I32::Cursor::reset");
    REGISTER_KW(i32, cursor_seek,  "Data::HashMap::Shared::I32::Cursor::seek");
    REGISTER_KW(i32, ttl_remaining, "Data::HashMap::Shared::I32::ttl_remaining");
    REGISTER_KW(i32, capacity,     "Data::HashMap::Shared::I32::capacity");
    REGISTER_KW(i32, tombstones,   "Data::HashMap::Shared::I32::tombstones");
    REGISTER_KW(i32, take,          "Data::HashMap::Shared::I32::take");
    REGISTER_KW(i32, pop,   "Data::HashMap::Shared::I32::pop");
    REGISTER_KW(i32, shift, "Data::HashMap::Shared::I32::shift");
    REGISTER_KW(i32, drain, "Data::HashMap::Shared::I32::drain");
    REGISTER_KW(i32, flush_expired, "Data::HashMap::Shared::I32::flush_expired");
    REGISTER_KW(i32, flush_expired_partial, "Data::HashMap::Shared::I32::flush_expired_partial");
    REGISTER_KW(i32, mmap_size,     "Data::HashMap::Shared::I32::mmap_size");
    REGISTER_KW(i32, touch,           "Data::HashMap::Shared::I32::touch");
    REGISTER_KW(i32, reserve,         "Data::HashMap::Shared::I32::reserve");
    REGISTER_KW(i32, stat_evictions,  "Data::HashMap::Shared::I32::stat_evictions");
    REGISTER_KW(i32, stat_expired,    "Data::HashMap::Shared::I32::stat_expired");
    REGISTER_KW(i32, stat_recoveries, "Data::HashMap::Shared::I32::stat_recoveries");    
    REGISTER_KW(i32, arena_used,       "Data::HashMap::Shared::I32::arena_used");
    REGISTER_KW(i32, arena_cap,        "Data::HashMap::Shared::I32::arena_cap");
    REGISTER_KW(i32, add,              "Data::HashMap::Shared::I32::add");
    REGISTER_KW(i32, update,           "Data::HashMap::Shared::I32::update");
    REGISTER_KW(i32, swap,             "Data::HashMap::Shared::I32::swap");
    REGISTER_KW(i32, cas,             "Data::HashMap::Shared::I32::cas");
    REGISTER_KW(i32, persist,         "Data::HashMap::Shared::I32::persist");
    REGISTER_KW(i32, set_ttl,         "Data::HashMap::Shared::I32::set_ttl");
    REGISTER_KW(ii, put,         "Data::HashMap::Shared::II::put");
    REGISTER_KW(ii, get,         "Data::HashMap::Shared::II::get");
    REGISTER_KW(ii, remove,      "Data::HashMap::Shared::II::remove");
    REGISTER_KW(ii, exists,      "Data::HashMap::Shared::II::exists");
    REGISTER_KW(ii, incr,        "Data::HashMap::Shared::II::incr");
    REGISTER_KW(ii, decr,        "Data::HashMap::Shared::II::decr");
    REGISTER_KW(ii, incr_by,     "Data::HashMap::Shared::II::incr_by");
    REGISTER_KW(ii, size,        "Data::HashMap::Shared::II::size");
    REGISTER_KW(ii, keys,        "Data::HashMap::Shared::II::keys");
    REGISTER_KW(ii, values,      "Data::HashMap::Shared::II::values");
    REGISTER_KW(ii, items,       "Data::HashMap::Shared::II::items");
    REGISTER_KW(ii, each,        "Data::HashMap::Shared::II::each");
    REGISTER_KW(ii, iter_reset,  "Data::HashMap::Shared::II::iter_reset");
    REGISTER_KW(ii, clear,       "Data::HashMap::Shared::II::clear");
    REGISTER_KW(ii, to_hash,     "Data::HashMap::Shared::II::to_hash");
    REGISTER_KW(ii, max_entries, "Data::HashMap::Shared::II::max_entries");
    REGISTER_KW(ii, get_or_set,  "Data::HashMap::Shared::II::get_or_set");
    REGISTER_KW(ii, put_ttl,    "Data::HashMap::Shared::II::put_ttl");
    REGISTER_KW(ii, max_size,   "Data::HashMap::Shared::II::max_size");
    REGISTER_KW(ii, ttl,        "Data::HashMap::Shared::II::ttl");
    REGISTER_KW(ii, cursor,       "Data::HashMap::Shared::II::cursor");
    REGISTER_KW(ii, cursor_next,  "Data::HashMap::Shared::II::Cursor::next");
    REGISTER_KW(ii, cursor_reset, "Data::HashMap::Shared::II::Cursor::reset");
    REGISTER_KW(ii, cursor_seek,  "Data::HashMap::Shared::II::Cursor::seek");
    REGISTER_KW(ii, ttl_remaining, "Data::HashMap::Shared::II::ttl_remaining");
    REGISTER_KW(ii, capacity,     "Data::HashMap::Shared::II::capacity");
    REGISTER_KW(ii, tombstones,   "Data::HashMap::Shared::II::tombstones");
    REGISTER_KW(ii, take,          "Data::HashMap::Shared::II::take");
    REGISTER_KW(ii, pop,   "Data::HashMap::Shared::II::pop");
    REGISTER_KW(ii, shift, "Data::HashMap::Shared::II::shift");
    REGISTER_KW(ii, drain, "Data::HashMap::Shared::II::drain");
    REGISTER_KW(ii, flush_expired, "Data::HashMap::Shared::II::flush_expired");
    REGISTER_KW(ii, flush_expired_partial, "Data::HashMap::Shared::II::flush_expired_partial");
    REGISTER_KW(ii, mmap_size,     "Data::HashMap::Shared::II::mmap_size");
    REGISTER_KW(ii, touch,           "Data::HashMap::Shared::II::touch");
    REGISTER_KW(ii, reserve,         "Data::HashMap::Shared::II::reserve");
    REGISTER_KW(ii, stat_evictions,  "Data::HashMap::Shared::II::stat_evictions");
    REGISTER_KW(ii, stat_expired,    "Data::HashMap::Shared::II::stat_expired");
    REGISTER_KW(ii, stat_recoveries, "Data::HashMap::Shared::II::stat_recoveries");    
    REGISTER_KW(ii, arena_used,       "Data::HashMap::Shared::II::arena_used");
    REGISTER_KW(ii, arena_cap,        "Data::HashMap::Shared::II::arena_cap");
    REGISTER_KW(ii, add,              "Data::HashMap::Shared::II::add");
    REGISTER_KW(ii, update,           "Data::HashMap::Shared::II::update");
    REGISTER_KW(ii, swap,             "Data::HashMap::Shared::II::swap");
    REGISTER_KW(ii, cas,             "Data::HashMap::Shared::II::cas");
    REGISTER_KW(ii, persist,         "Data::HashMap::Shared::II::persist");
    REGISTER_KW(ii, set_ttl,         "Data::HashMap::Shared::II::set_ttl");
    REGISTER_KW(i16s, put,         "Data::HashMap::Shared::I16S::put");
    REGISTER_KW(i16s, get,         "Data::HashMap::Shared::I16S::get");
    REGISTER_KW(i16s, remove,      "Data::HashMap::Shared::I16S::remove");
    REGISTER_KW(i16s, exists,      "Data::HashMap::Shared::I16S::exists");
    REGISTER_KW(i16s, size,        "Data::HashMap::Shared::I16S::size");
    REGISTER_KW(i16s, keys,        "Data::HashMap::Shared::I16S::keys");
    REGISTER_KW(i16s, values,      "Data::HashMap::Shared::I16S::values");
    REGISTER_KW(i16s, items,       "Data::HashMap::Shared::I16S::items");
    REGISTER_KW(i16s, each,        "Data::HashMap::Shared::I16S::each");
    REGISTER_KW(i16s, iter_reset,  "Data::HashMap::Shared::I16S::iter_reset");
    REGISTER_KW(i16s, clear,       "Data::HashMap::Shared::I16S::clear");
    REGISTER_KW(i16s, to_hash,     "Data::HashMap::Shared::I16S::to_hash");
    REGISTER_KW(i16s, max_entries, "Data::HashMap::Shared::I16S::max_entries");
    REGISTER_KW(i16s, get_or_set,  "Data::HashMap::Shared::I16S::get_or_set");
    REGISTER_KW(i16s, put_ttl,    "Data::HashMap::Shared::I16S::put_ttl");
    REGISTER_KW(i16s, max_size,   "Data::HashMap::Shared::I16S::max_size");
    REGISTER_KW(i16s, ttl,        "Data::HashMap::Shared::I16S::ttl");
    REGISTER_KW(i16s, cursor,       "Data::HashMap::Shared::I16S::cursor");
    REGISTER_KW(i16s, cursor_next,  "Data::HashMap::Shared::I16S::Cursor::next");
    REGISTER_KW(i16s, cursor_reset, "Data::HashMap::Shared::I16S::Cursor::reset");
    REGISTER_KW(i16s, cursor_seek,  "Data::HashMap::Shared::I16S::Cursor::seek");
    REGISTER_KW(i16s, ttl_remaining, "Data::HashMap::Shared::I16S::ttl_remaining");
    REGISTER_KW(i16s, capacity,     "Data::HashMap::Shared::I16S::capacity");
    REGISTER_KW(i16s, tombstones,   "Data::HashMap::Shared::I16S::tombstones");
    REGISTER_KW(i16s, take,          "Data::HashMap::Shared::I16S::take");
    REGISTER_KW(i16s, pop,   "Data::HashMap::Shared::I16S::pop");
    REGISTER_KW(i16s, shift, "Data::HashMap::Shared::I16S::shift");
    REGISTER_KW(i16s, drain, "Data::HashMap::Shared::I16S::drain");
    REGISTER_KW(i16s, flush_expired, "Data::HashMap::Shared::I16S::flush_expired");
    REGISTER_KW(i16s, flush_expired_partial, "Data::HashMap::Shared::I16S::flush_expired_partial");
    REGISTER_KW(i16s, mmap_size,     "Data::HashMap::Shared::I16S::mmap_size");
    REGISTER_KW(i16s, touch,           "Data::HashMap::Shared::I16S::touch");
    REGISTER_KW(i16s, reserve,         "Data::HashMap::Shared::I16S::reserve");
    REGISTER_KW(i16s, stat_evictions,  "Data::HashMap::Shared::I16S::stat_evictions");
    REGISTER_KW(i16s, stat_expired,    "Data::HashMap::Shared::I16S::stat_expired");
    REGISTER_KW(i16s, stat_recoveries, "Data::HashMap::Shared::I16S::stat_recoveries");    
    REGISTER_KW(i16s, arena_used,       "Data::HashMap::Shared::I16S::arena_used");
    REGISTER_KW(i16s, arena_cap,        "Data::HashMap::Shared::I16S::arena_cap");
    REGISTER_KW(i16s, add,              "Data::HashMap::Shared::I16S::add");
    REGISTER_KW(i16s, update,           "Data::HashMap::Shared::I16S::update");
    REGISTER_KW(i16s, swap,             "Data::HashMap::Shared::I16S::swap");
    REGISTER_KW(i16s, persist,         "Data::HashMap::Shared::I16S::persist");
    REGISTER_KW(i16s, set_ttl,         "Data::HashMap::Shared::I16S::set_ttl");
    REGISTER_KW(i32s, put,         "Data::HashMap::Shared::I32S::put");
    REGISTER_KW(i32s, get,         "Data::HashMap::Shared::I32S::get");
    REGISTER_KW(i32s, remove,      "Data::HashMap::Shared::I32S::remove");
    REGISTER_KW(i32s, exists,      "Data::HashMap::Shared::I32S::exists");
    REGISTER_KW(i32s, size,        "Data::HashMap::Shared::I32S::size");
    REGISTER_KW(i32s, keys,        "Data::HashMap::Shared::I32S::keys");
    REGISTER_KW(i32s, values,      "Data::HashMap::Shared::I32S::values");
    REGISTER_KW(i32s, items,       "Data::HashMap::Shared::I32S::items");
    REGISTER_KW(i32s, each,        "Data::HashMap::Shared::I32S::each");
    REGISTER_KW(i32s, iter_reset,  "Data::HashMap::Shared::I32S::iter_reset");
    REGISTER_KW(i32s, clear,       "Data::HashMap::Shared::I32S::clear");
    REGISTER_KW(i32s, to_hash,     "Data::HashMap::Shared::I32S::to_hash");
    REGISTER_KW(i32s, max_entries, "Data::HashMap::Shared::I32S::max_entries");
    REGISTER_KW(i32s, get_or_set,  "Data::HashMap::Shared::I32S::get_or_set");
    REGISTER_KW(i32s, put_ttl,    "Data::HashMap::Shared::I32S::put_ttl");
    REGISTER_KW(i32s, max_size,   "Data::HashMap::Shared::I32S::max_size");
    REGISTER_KW(i32s, ttl,        "Data::HashMap::Shared::I32S::ttl");
    REGISTER_KW(i32s, cursor,       "Data::HashMap::Shared::I32S::cursor");
    REGISTER_KW(i32s, cursor_next,  "Data::HashMap::Shared::I32S::Cursor::next");
    REGISTER_KW(i32s, cursor_reset, "Data::HashMap::Shared::I32S::Cursor::reset");
    REGISTER_KW(i32s, cursor_seek,  "Data::HashMap::Shared::I32S::Cursor::seek");
    REGISTER_KW(i32s, ttl_remaining, "Data::HashMap::Shared::I32S::ttl_remaining");
    REGISTER_KW(i32s, capacity,     "Data::HashMap::Shared::I32S::capacity");
    REGISTER_KW(i32s, tombstones,   "Data::HashMap::Shared::I32S::tombstones");
    REGISTER_KW(i32s, take,          "Data::HashMap::Shared::I32S::take");
    REGISTER_KW(i32s, pop,   "Data::HashMap::Shared::I32S::pop");
    REGISTER_KW(i32s, shift, "Data::HashMap::Shared::I32S::shift");
    REGISTER_KW(i32s, drain, "Data::HashMap::Shared::I32S::drain");
    REGISTER_KW(i32s, flush_expired, "Data::HashMap::Shared::I32S::flush_expired");
    REGISTER_KW(i32s, flush_expired_partial, "Data::HashMap::Shared::I32S::flush_expired_partial");
    REGISTER_KW(i32s, mmap_size,     "Data::HashMap::Shared::I32S::mmap_size");
    REGISTER_KW(i32s, touch,           "Data::HashMap::Shared::I32S::touch");
    REGISTER_KW(i32s, reserve,         "Data::HashMap::Shared::I32S::reserve");
    REGISTER_KW(i32s, stat_evictions,  "Data::HashMap::Shared::I32S::stat_evictions");
    REGISTER_KW(i32s, stat_expired,    "Data::HashMap::Shared::I32S::stat_expired");
    REGISTER_KW(i32s, stat_recoveries, "Data::HashMap::Shared::I32S::stat_recoveries");    
    REGISTER_KW(i32s, arena_used,       "Data::HashMap::Shared::I32S::arena_used");
    REGISTER_KW(i32s, arena_cap,        "Data::HashMap::Shared::I32S::arena_cap");
    REGISTER_KW(i32s, add,              "Data::HashMap::Shared::I32S::add");
    REGISTER_KW(i32s, update,           "Data::HashMap::Shared::I32S::update");
    REGISTER_KW(i32s, swap,             "Data::HashMap::Shared::I32S::swap");
    REGISTER_KW(i32s, persist,         "Data::HashMap::Shared::I32S::persist");
    REGISTER_KW(i32s, set_ttl,         "Data::HashMap::Shared::I32S::set_ttl");
    REGISTER_KW(is, put,         "Data::HashMap::Shared::IS::put");
    REGISTER_KW(is, get,         "Data::HashMap::Shared::IS::get");
    REGISTER_KW(is, remove,      "Data::HashMap::Shared::IS::remove");
    REGISTER_KW(is, exists,      "Data::HashMap::Shared::IS::exists");
    REGISTER_KW(is, size,        "Data::HashMap::Shared::IS::size");
    REGISTER_KW(is, keys,        "Data::HashMap::Shared::IS::keys");
    REGISTER_KW(is, values,      "Data::HashMap::Shared::IS::values");
    REGISTER_KW(is, items,       "Data::HashMap::Shared::IS::items");
    REGISTER_KW(is, each,        "Data::HashMap::Shared::IS::each");
    REGISTER_KW(is, iter_reset,  "Data::HashMap::Shared::IS::iter_reset");
    REGISTER_KW(is, clear,       "Data::HashMap::Shared::IS::clear");
    REGISTER_KW(is, to_hash,     "Data::HashMap::Shared::IS::to_hash");
    REGISTER_KW(is, max_entries, "Data::HashMap::Shared::IS::max_entries");
    REGISTER_KW(is, get_or_set,  "Data::HashMap::Shared::IS::get_or_set");
    REGISTER_KW(is, put_ttl,    "Data::HashMap::Shared::IS::put_ttl");
    REGISTER_KW(is, max_size,   "Data::HashMap::Shared::IS::max_size");
    REGISTER_KW(is, ttl,        "Data::HashMap::Shared::IS::ttl");
    REGISTER_KW(is, cursor,       "Data::HashMap::Shared::IS::cursor");
    REGISTER_KW(is, cursor_next,  "Data::HashMap::Shared::IS::Cursor::next");
    REGISTER_KW(is, cursor_reset, "Data::HashMap::Shared::IS::Cursor::reset");
    REGISTER_KW(is, cursor_seek,  "Data::HashMap::Shared::IS::Cursor::seek");
    REGISTER_KW(is, ttl_remaining, "Data::HashMap::Shared::IS::ttl_remaining");
    REGISTER_KW(is, capacity,     "Data::HashMap::Shared::IS::capacity");
    REGISTER_KW(is, tombstones,   "Data::HashMap::Shared::IS::tombstones");
    REGISTER_KW(is, take,          "Data::HashMap::Shared::IS::take");
    REGISTER_KW(is, pop,   "Data::HashMap::Shared::IS::pop");
    REGISTER_KW(is, shift, "Data::HashMap::Shared::IS::shift");
    REGISTER_KW(is, drain, "Data::HashMap::Shared::IS::drain");
    REGISTER_KW(is, flush_expired, "Data::HashMap::Shared::IS::flush_expired");
    REGISTER_KW(is, flush_expired_partial, "Data::HashMap::Shared::IS::flush_expired_partial");
    REGISTER_KW(is, mmap_size,     "Data::HashMap::Shared::IS::mmap_size");
    REGISTER_KW(is, touch,           "Data::HashMap::Shared::IS::touch");
    REGISTER_KW(is, reserve,         "Data::HashMap::Shared::IS::reserve");
    REGISTER_KW(is, stat_evictions,  "Data::HashMap::Shared::IS::stat_evictions");
    REGISTER_KW(is, stat_expired,    "Data::HashMap::Shared::IS::stat_expired");
    REGISTER_KW(is, stat_recoveries, "Data::HashMap::Shared::IS::stat_recoveries");    
    REGISTER_KW(is, arena_used,       "Data::HashMap::Shared::IS::arena_used");
    REGISTER_KW(is, arena_cap,        "Data::HashMap::Shared::IS::arena_cap");
    REGISTER_KW(is, add,              "Data::HashMap::Shared::IS::add");
    REGISTER_KW(is, update,           "Data::HashMap::Shared::IS::update");
    REGISTER_KW(is, swap,             "Data::HashMap::Shared::IS::swap");
    REGISTER_KW(is, persist,         "Data::HashMap::Shared::IS::persist");
    REGISTER_KW(is, set_ttl,         "Data::HashMap::Shared::IS::set_ttl");
    REGISTER_KW(si16, put,         "Data::HashMap::Shared::SI16::put");
    REGISTER_KW(si16, get,         "Data::HashMap::Shared::SI16::get");
    REGISTER_KW(si16, remove,      "Data::HashMap::Shared::SI16::remove");
    REGISTER_KW(si16, exists,      "Data::HashMap::Shared::SI16::exists");
    REGISTER_KW(si16, incr,        "Data::HashMap::Shared::SI16::incr");
    REGISTER_KW(si16, decr,        "Data::HashMap::Shared::SI16::decr");
    REGISTER_KW(si16, incr_by,     "Data::HashMap::Shared::SI16::incr_by");
    REGISTER_KW(si16, size,        "Data::HashMap::Shared::SI16::size");
    REGISTER_KW(si16, keys,        "Data::HashMap::Shared::SI16::keys");
    REGISTER_KW(si16, values,      "Data::HashMap::Shared::SI16::values");
    REGISTER_KW(si16, items,       "Data::HashMap::Shared::SI16::items");
    REGISTER_KW(si16, each,        "Data::HashMap::Shared::SI16::each");
    REGISTER_KW(si16, iter_reset,  "Data::HashMap::Shared::SI16::iter_reset");
    REGISTER_KW(si16, clear,       "Data::HashMap::Shared::SI16::clear");
    REGISTER_KW(si16, to_hash,     "Data::HashMap::Shared::SI16::to_hash");
    REGISTER_KW(si16, max_entries, "Data::HashMap::Shared::SI16::max_entries");
    REGISTER_KW(si16, get_or_set,  "Data::HashMap::Shared::SI16::get_or_set");
    REGISTER_KW(si16, put_ttl,    "Data::HashMap::Shared::SI16::put_ttl");
    REGISTER_KW(si16, max_size,   "Data::HashMap::Shared::SI16::max_size");
    REGISTER_KW(si16, ttl,        "Data::HashMap::Shared::SI16::ttl");
    REGISTER_KW(si16, cursor,       "Data::HashMap::Shared::SI16::cursor");
    REGISTER_KW(si16, cursor_next,  "Data::HashMap::Shared::SI16::Cursor::next");
    REGISTER_KW(si16, cursor_reset, "Data::HashMap::Shared::SI16::Cursor::reset");
    REGISTER_KW(si16, cursor_seek,  "Data::HashMap::Shared::SI16::Cursor::seek");
    REGISTER_KW(si16, ttl_remaining, "Data::HashMap::Shared::SI16::ttl_remaining");
    REGISTER_KW(si16, capacity,     "Data::HashMap::Shared::SI16::capacity");
    REGISTER_KW(si16, tombstones,   "Data::HashMap::Shared::SI16::tombstones");
    REGISTER_KW(si16, take,          "Data::HashMap::Shared::SI16::take");
    REGISTER_KW(si16, pop,   "Data::HashMap::Shared::SI16::pop");
    REGISTER_KW(si16, shift, "Data::HashMap::Shared::SI16::shift");
    REGISTER_KW(si16, drain, "Data::HashMap::Shared::SI16::drain");
    REGISTER_KW(si16, flush_expired, "Data::HashMap::Shared::SI16::flush_expired");
    REGISTER_KW(si16, flush_expired_partial, "Data::HashMap::Shared::SI16::flush_expired_partial");
    REGISTER_KW(si16, mmap_size,     "Data::HashMap::Shared::SI16::mmap_size");
    REGISTER_KW(si16, touch,           "Data::HashMap::Shared::SI16::touch");
    REGISTER_KW(si16, reserve,         "Data::HashMap::Shared::SI16::reserve");
    REGISTER_KW(si16, stat_evictions,  "Data::HashMap::Shared::SI16::stat_evictions");
    REGISTER_KW(si16, stat_expired,    "Data::HashMap::Shared::SI16::stat_expired");
    REGISTER_KW(si16, stat_recoveries, "Data::HashMap::Shared::SI16::stat_recoveries");    
    REGISTER_KW(si16, arena_used,       "Data::HashMap::Shared::SI16::arena_used");
    REGISTER_KW(si16, arena_cap,        "Data::HashMap::Shared::SI16::arena_cap");
    REGISTER_KW(si16, add,              "Data::HashMap::Shared::SI16::add");
    REGISTER_KW(si16, update,           "Data::HashMap::Shared::SI16::update");
    REGISTER_KW(si16, swap,             "Data::HashMap::Shared::SI16::swap");
    REGISTER_KW(si16, cas,             "Data::HashMap::Shared::SI16::cas");
    REGISTER_KW(si16, persist,         "Data::HashMap::Shared::SI16::persist");
    REGISTER_KW(si16, set_ttl,         "Data::HashMap::Shared::SI16::set_ttl");
    REGISTER_KW(si32, put,         "Data::HashMap::Shared::SI32::put");
    REGISTER_KW(si32, get,         "Data::HashMap::Shared::SI32::get");
    REGISTER_KW(si32, remove,      "Data::HashMap::Shared::SI32::remove");
    REGISTER_KW(si32, exists,      "Data::HashMap::Shared::SI32::exists");
    REGISTER_KW(si32, incr,        "Data::HashMap::Shared::SI32::incr");
    REGISTER_KW(si32, decr,        "Data::HashMap::Shared::SI32::decr");
    REGISTER_KW(si32, incr_by,     "Data::HashMap::Shared::SI32::incr_by");
    REGISTER_KW(si32, size,        "Data::HashMap::Shared::SI32::size");
    REGISTER_KW(si32, keys,        "Data::HashMap::Shared::SI32::keys");
    REGISTER_KW(si32, values,      "Data::HashMap::Shared::SI32::values");
    REGISTER_KW(si32, items,       "Data::HashMap::Shared::SI32::items");
    REGISTER_KW(si32, each,        "Data::HashMap::Shared::SI32::each");
    REGISTER_KW(si32, iter_reset,  "Data::HashMap::Shared::SI32::iter_reset");
    REGISTER_KW(si32, clear,       "Data::HashMap::Shared::SI32::clear");
    REGISTER_KW(si32, to_hash,     "Data::HashMap::Shared::SI32::to_hash");
    REGISTER_KW(si32, max_entries, "Data::HashMap::Shared::SI32::max_entries");
    REGISTER_KW(si32, get_or_set,  "Data::HashMap::Shared::SI32::get_or_set");
    REGISTER_KW(si32, put_ttl,    "Data::HashMap::Shared::SI32::put_ttl");
    REGISTER_KW(si32, max_size,   "Data::HashMap::Shared::SI32::max_size");
    REGISTER_KW(si32, ttl,        "Data::HashMap::Shared::SI32::ttl");
    REGISTER_KW(si32, cursor,       "Data::HashMap::Shared::SI32::cursor");
    REGISTER_KW(si32, cursor_next,  "Data::HashMap::Shared::SI32::Cursor::next");
    REGISTER_KW(si32, cursor_reset, "Data::HashMap::Shared::SI32::Cursor::reset");
    REGISTER_KW(si32, cursor_seek,  "Data::HashMap::Shared::SI32::Cursor::seek");
    REGISTER_KW(si32, ttl_remaining, "Data::HashMap::Shared::SI32::ttl_remaining");
    REGISTER_KW(si32, capacity,     "Data::HashMap::Shared::SI32::capacity");
    REGISTER_KW(si32, tombstones,   "Data::HashMap::Shared::SI32::tombstones");
    REGISTER_KW(si32, take,          "Data::HashMap::Shared::SI32::take");
    REGISTER_KW(si32, pop,   "Data::HashMap::Shared::SI32::pop");
    REGISTER_KW(si32, shift, "Data::HashMap::Shared::SI32::shift");
    REGISTER_KW(si32, drain, "Data::HashMap::Shared::SI32::drain");
    REGISTER_KW(si32, flush_expired, "Data::HashMap::Shared::SI32::flush_expired");
    REGISTER_KW(si32, flush_expired_partial, "Data::HashMap::Shared::SI32::flush_expired_partial");
    REGISTER_KW(si32, mmap_size,     "Data::HashMap::Shared::SI32::mmap_size");
    REGISTER_KW(si32, touch,           "Data::HashMap::Shared::SI32::touch");
    REGISTER_KW(si32, reserve,         "Data::HashMap::Shared::SI32::reserve");
    REGISTER_KW(si32, stat_evictions,  "Data::HashMap::Shared::SI32::stat_evictions");
    REGISTER_KW(si32, stat_expired,    "Data::HashMap::Shared::SI32::stat_expired");
    REGISTER_KW(si32, stat_recoveries, "Data::HashMap::Shared::SI32::stat_recoveries");    
    REGISTER_KW(si32, arena_used,       "Data::HashMap::Shared::SI32::arena_used");
    REGISTER_KW(si32, arena_cap,        "Data::HashMap::Shared::SI32::arena_cap");
    REGISTER_KW(si32, add,              "Data::HashMap::Shared::SI32::add");
    REGISTER_KW(si32, update,           "Data::HashMap::Shared::SI32::update");
    REGISTER_KW(si32, swap,             "Data::HashMap::Shared::SI32::swap");
    REGISTER_KW(si32, cas,             "Data::HashMap::Shared::SI32::cas");
    REGISTER_KW(si32, persist,         "Data::HashMap::Shared::SI32::persist");
    REGISTER_KW(si32, set_ttl,         "Data::HashMap::Shared::SI32::set_ttl");
    REGISTER_KW(si, put,         "Data::HashMap::Shared::SI::put");
    REGISTER_KW(si, get,         "Data::HashMap::Shared::SI::get");
    REGISTER_KW(si, remove,      "Data::HashMap::Shared::SI::remove");
    REGISTER_KW(si, exists,      "Data::HashMap::Shared::SI::exists");
    REGISTER_KW(si, incr,        "Data::HashMap::Shared::SI::incr");
    REGISTER_KW(si, decr,        "Data::HashMap::Shared::SI::decr");
    REGISTER_KW(si, incr_by,     "Data::HashMap::Shared::SI::incr_by");
    REGISTER_KW(si, size,        "Data::HashMap::Shared::SI::size");
    REGISTER_KW(si, keys,        "Data::HashMap::Shared::SI::keys");
    REGISTER_KW(si, values,      "Data::HashMap::Shared::SI::values");
    REGISTER_KW(si, items,       "Data::HashMap::Shared::SI::items");
    REGISTER_KW(si, each,        "Data::HashMap::Shared::SI::each");
    REGISTER_KW(si, iter_reset,  "Data::HashMap::Shared::SI::iter_reset");
    REGISTER_KW(si, clear,       "Data::HashMap::Shared::SI::clear");
    REGISTER_KW(si, to_hash,     "Data::HashMap::Shared::SI::to_hash");
    REGISTER_KW(si, max_entries, "Data::HashMap::Shared::SI::max_entries");
    REGISTER_KW(si, get_or_set,  "Data::HashMap::Shared::SI::get_or_set");
    REGISTER_KW(si, put_ttl,    "Data::HashMap::Shared::SI::put_ttl");
    REGISTER_KW(si, max_size,   "Data::HashMap::Shared::SI::max_size");
    REGISTER_KW(si, ttl,        "Data::HashMap::Shared::SI::ttl");
    REGISTER_KW(si, cursor,       "Data::HashMap::Shared::SI::cursor");
    REGISTER_KW(si, cursor_next,  "Data::HashMap::Shared::SI::Cursor::next");
    REGISTER_KW(si, cursor_reset, "Data::HashMap::Shared::SI::Cursor::reset");
    REGISTER_KW(si, cursor_seek,  "Data::HashMap::Shared::SI::Cursor::seek");
    REGISTER_KW(si, ttl_remaining, "Data::HashMap::Shared::SI::ttl_remaining");
    REGISTER_KW(si, capacity,     "Data::HashMap::Shared::SI::capacity");
    REGISTER_KW(si, tombstones,   "Data::HashMap::Shared::SI::tombstones");
    REGISTER_KW(si, take,          "Data::HashMap::Shared::SI::take");
    REGISTER_KW(si, pop,   "Data::HashMap::Shared::SI::pop");
    REGISTER_KW(si, shift, "Data::HashMap::Shared::SI::shift");
    REGISTER_KW(si, drain, "Data::HashMap::Shared::SI::drain");
    REGISTER_KW(si, flush_expired, "Data::HashMap::Shared::SI::flush_expired");
    REGISTER_KW(si, flush_expired_partial, "Data::HashMap::Shared::SI::flush_expired_partial");
    REGISTER_KW(si, mmap_size,     "Data::HashMap::Shared::SI::mmap_size");
    REGISTER_KW(si, touch,           "Data::HashMap::Shared::SI::touch");
    REGISTER_KW(si, reserve,         "Data::HashMap::Shared::SI::reserve");
    REGISTER_KW(si, stat_evictions,  "Data::HashMap::Shared::SI::stat_evictions");
    REGISTER_KW(si, stat_expired,    "Data::HashMap::Shared::SI::stat_expired");
    REGISTER_KW(si, stat_recoveries, "Data::HashMap::Shared::SI::stat_recoveries");    
    REGISTER_KW(si, arena_used,       "Data::HashMap::Shared::SI::arena_used");
    REGISTER_KW(si, arena_cap,        "Data::HashMap::Shared::SI::arena_cap");
    REGISTER_KW(si, add,              "Data::HashMap::Shared::SI::add");
    REGISTER_KW(si, update,           "Data::HashMap::Shared::SI::update");
    REGISTER_KW(si, swap,             "Data::HashMap::Shared::SI::swap");
    REGISTER_KW(si, cas,             "Data::HashMap::Shared::SI::cas");
    REGISTER_KW(si, persist,         "Data::HashMap::Shared::SI::persist");
    REGISTER_KW(si, set_ttl,         "Data::HashMap::Shared::SI::set_ttl");
    REGISTER_KW(ss, put,         "Data::HashMap::Shared::SS::put");
    REGISTER_KW(ss, get,         "Data::HashMap::Shared::SS::get");
    REGISTER_KW(ss, remove,      "Data::HashMap::Shared::SS::remove");
    REGISTER_KW(ss, exists,      "Data::HashMap::Shared::SS::exists");
    REGISTER_KW(ss, size,        "Data::HashMap::Shared::SS::size");
    REGISTER_KW(ss, keys,        "Data::HashMap::Shared::SS::keys");
    REGISTER_KW(ss, values,      "Data::HashMap::Shared::SS::values");
    REGISTER_KW(ss, items,       "Data::HashMap::Shared::SS::items");
    REGISTER_KW(ss, each,        "Data::HashMap::Shared::SS::each");
    REGISTER_KW(ss, iter_reset,  "Data::HashMap::Shared::SS::iter_reset");
    REGISTER_KW(ss, clear,       "Data::HashMap::Shared::SS::clear");
    REGISTER_KW(ss, to_hash,     "Data::HashMap::Shared::SS::to_hash");
    REGISTER_KW(ss, max_entries, "Data::HashMap::Shared::SS::max_entries");
    REGISTER_KW(ss, get_or_set,  "Data::HashMap::Shared::SS::get_or_set");
    REGISTER_KW(ss, put_ttl,    "Data::HashMap::Shared::SS::put_ttl");
    REGISTER_KW(ss, max_size,   "Data::HashMap::Shared::SS::max_size");
    REGISTER_KW(ss, ttl,        "Data::HashMap::Shared::SS::ttl");
    REGISTER_KW(ss, cursor,       "Data::HashMap::Shared::SS::cursor");
    REGISTER_KW(ss, cursor_next,  "Data::HashMap::Shared::SS::Cursor::next");
    REGISTER_KW(ss, cursor_reset, "Data::HashMap::Shared::SS::Cursor::reset");
    REGISTER_KW(ss, cursor_seek,  "Data::HashMap::Shared::SS::Cursor::seek");
    REGISTER_KW(ss, ttl_remaining, "Data::HashMap::Shared::SS::ttl_remaining");
    REGISTER_KW(ss, capacity,     "Data::HashMap::Shared::SS::capacity");
    REGISTER_KW(ss, tombstones,   "Data::HashMap::Shared::SS::tombstones");
    REGISTER_KW(ss, take,          "Data::HashMap::Shared::SS::take");
    REGISTER_KW(ss, pop,   "Data::HashMap::Shared::SS::pop");
    REGISTER_KW(ss, shift, "Data::HashMap::Shared::SS::shift");
    REGISTER_KW(ss, drain, "Data::HashMap::Shared::SS::drain");
    REGISTER_KW(ss, flush_expired, "Data::HashMap::Shared::SS::flush_expired");
    REGISTER_KW(ss, flush_expired_partial, "Data::HashMap::Shared::SS::flush_expired_partial");
    REGISTER_KW(ss, mmap_size,     "Data::HashMap::Shared::SS::mmap_size");
    REGISTER_KW(ss, touch,           "Data::HashMap::Shared::SS::touch");
    REGISTER_KW(ss, reserve,         "Data::HashMap::Shared::SS::reserve");
    REGISTER_KW(ss, stat_evictions,  "Data::HashMap::Shared::SS::stat_evictions");
    REGISTER_KW(ss, stat_expired,    "Data::HashMap::Shared::SS::stat_expired");
    REGISTER_KW(ss, stat_recoveries, "Data::HashMap::Shared::SS::stat_recoveries");
    REGISTER_KW(ss, arena_used,       "Data::HashMap::Shared::SS::arena_used");
    REGISTER_KW(ss, arena_cap,        "Data::HashMap::Shared::SS::arena_cap");
    REGISTER_KW(ss, add,              "Data::HashMap::Shared::SS::add");
    REGISTER_KW(ss, update,           "Data::HashMap::Shared::SS::update");
    REGISTER_KW(ss, swap,             "Data::HashMap::Shared::SS::swap");
    REGISTER_KW(ss, persist,         "Data::HashMap::Shared::SS::persist");
    REGISTER_KW(ss, set_ttl,         "Data::HashMap::Shared::SS::set_ttl");


INCLUDE: xs/i16.xs
INCLUDE: xs/i32.xs
INCLUDE: xs/ii.xs
INCLUDE: xs/i16s.xs
INCLUDE: xs/i32s.xs
INCLUDE: xs/is.xs
INCLUDE: xs/si16.xs
INCLUDE: xs/si32.xs
INCLUDE: xs/si.xs
INCLUDE: xs/ss.xs
