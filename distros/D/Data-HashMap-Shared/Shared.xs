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
    if (!(h)->expires_at) croak("put_ttl requires a TTL-enabled map (pass ttl > 0 to constructor)")

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
DEFINE_KW_HOOK(i16, "I16", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(i32, "I32", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(ii, "II", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(i16s, "I16S", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(i32s, "I32S", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(is, "IS", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(si16, "SI16", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(si32, "SI32", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(si, "SI", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", stat_recoveries,    1, build_kw_1arg)

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
DEFINE_KW_HOOK(ss, "SS", flush_expired, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", flush_expired_partial, 2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", mmap_size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", touch,           2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", reserve,         2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", stat_evictions,  1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", stat_expired,    1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", stat_recoveries,    1, build_kw_1arg)

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
    REGISTER_KW(i16, flush_expired, "Data::HashMap::Shared::I16::flush_expired");
    REGISTER_KW(i16, flush_expired_partial, "Data::HashMap::Shared::I16::flush_expired_partial");
    REGISTER_KW(i16, mmap_size,     "Data::HashMap::Shared::I16::mmap_size");
    REGISTER_KW(i16, touch,           "Data::HashMap::Shared::I16::touch");
    REGISTER_KW(i16, reserve,         "Data::HashMap::Shared::I16::reserve");
    REGISTER_KW(i16, stat_evictions,  "Data::HashMap::Shared::I16::stat_evictions");
    REGISTER_KW(i16, stat_expired,    "Data::HashMap::Shared::I16::stat_expired");
    REGISTER_KW(i16, stat_recoveries, "Data::HashMap::Shared::I16::stat_recoveries");    
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
    REGISTER_KW(i32, flush_expired, "Data::HashMap::Shared::I32::flush_expired");
    REGISTER_KW(i32, flush_expired_partial, "Data::HashMap::Shared::I32::flush_expired_partial");
    REGISTER_KW(i32, mmap_size,     "Data::HashMap::Shared::I32::mmap_size");
    REGISTER_KW(i32, touch,           "Data::HashMap::Shared::I32::touch");
    REGISTER_KW(i32, reserve,         "Data::HashMap::Shared::I32::reserve");
    REGISTER_KW(i32, stat_evictions,  "Data::HashMap::Shared::I32::stat_evictions");
    REGISTER_KW(i32, stat_expired,    "Data::HashMap::Shared::I32::stat_expired");
    REGISTER_KW(i32, stat_recoveries, "Data::HashMap::Shared::I32::stat_recoveries");    
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
    REGISTER_KW(ii, flush_expired, "Data::HashMap::Shared::II::flush_expired");
    REGISTER_KW(ii, flush_expired_partial, "Data::HashMap::Shared::II::flush_expired_partial");
    REGISTER_KW(ii, mmap_size,     "Data::HashMap::Shared::II::mmap_size");
    REGISTER_KW(ii, touch,           "Data::HashMap::Shared::II::touch");
    REGISTER_KW(ii, reserve,         "Data::HashMap::Shared::II::reserve");
    REGISTER_KW(ii, stat_evictions,  "Data::HashMap::Shared::II::stat_evictions");
    REGISTER_KW(ii, stat_expired,    "Data::HashMap::Shared::II::stat_expired");
    REGISTER_KW(ii, stat_recoveries, "Data::HashMap::Shared::II::stat_recoveries");    
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
    REGISTER_KW(i16s, flush_expired, "Data::HashMap::Shared::I16S::flush_expired");
    REGISTER_KW(i16s, flush_expired_partial, "Data::HashMap::Shared::I16S::flush_expired_partial");
    REGISTER_KW(i16s, mmap_size,     "Data::HashMap::Shared::I16S::mmap_size");
    REGISTER_KW(i16s, touch,           "Data::HashMap::Shared::I16S::touch");
    REGISTER_KW(i16s, reserve,         "Data::HashMap::Shared::I16S::reserve");
    REGISTER_KW(i16s, stat_evictions,  "Data::HashMap::Shared::I16S::stat_evictions");
    REGISTER_KW(i16s, stat_expired,    "Data::HashMap::Shared::I16S::stat_expired");
    REGISTER_KW(i16s, stat_recoveries, "Data::HashMap::Shared::I16S::stat_recoveries");    
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
    REGISTER_KW(i32s, flush_expired, "Data::HashMap::Shared::I32S::flush_expired");
    REGISTER_KW(i32s, flush_expired_partial, "Data::HashMap::Shared::I32S::flush_expired_partial");
    REGISTER_KW(i32s, mmap_size,     "Data::HashMap::Shared::I32S::mmap_size");
    REGISTER_KW(i32s, touch,           "Data::HashMap::Shared::I32S::touch");
    REGISTER_KW(i32s, reserve,         "Data::HashMap::Shared::I32S::reserve");
    REGISTER_KW(i32s, stat_evictions,  "Data::HashMap::Shared::I32S::stat_evictions");
    REGISTER_KW(i32s, stat_expired,    "Data::HashMap::Shared::I32S::stat_expired");
    REGISTER_KW(i32s, stat_recoveries, "Data::HashMap::Shared::I32S::stat_recoveries");    
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
    REGISTER_KW(is, flush_expired, "Data::HashMap::Shared::IS::flush_expired");
    REGISTER_KW(is, flush_expired_partial, "Data::HashMap::Shared::IS::flush_expired_partial");
    REGISTER_KW(is, mmap_size,     "Data::HashMap::Shared::IS::mmap_size");
    REGISTER_KW(is, touch,           "Data::HashMap::Shared::IS::touch");
    REGISTER_KW(is, reserve,         "Data::HashMap::Shared::IS::reserve");
    REGISTER_KW(is, stat_evictions,  "Data::HashMap::Shared::IS::stat_evictions");
    REGISTER_KW(is, stat_expired,    "Data::HashMap::Shared::IS::stat_expired");
    REGISTER_KW(is, stat_recoveries, "Data::HashMap::Shared::IS::stat_recoveries");    
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
    REGISTER_KW(si16, flush_expired, "Data::HashMap::Shared::SI16::flush_expired");
    REGISTER_KW(si16, flush_expired_partial, "Data::HashMap::Shared::SI16::flush_expired_partial");
    REGISTER_KW(si16, mmap_size,     "Data::HashMap::Shared::SI16::mmap_size");
    REGISTER_KW(si16, touch,           "Data::HashMap::Shared::SI16::touch");
    REGISTER_KW(si16, reserve,         "Data::HashMap::Shared::SI16::reserve");
    REGISTER_KW(si16, stat_evictions,  "Data::HashMap::Shared::SI16::stat_evictions");
    REGISTER_KW(si16, stat_expired,    "Data::HashMap::Shared::SI16::stat_expired");
    REGISTER_KW(si16, stat_recoveries, "Data::HashMap::Shared::SI16::stat_recoveries");    
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
    REGISTER_KW(si32, flush_expired, "Data::HashMap::Shared::SI32::flush_expired");
    REGISTER_KW(si32, flush_expired_partial, "Data::HashMap::Shared::SI32::flush_expired_partial");
    REGISTER_KW(si32, mmap_size,     "Data::HashMap::Shared::SI32::mmap_size");
    REGISTER_KW(si32, touch,           "Data::HashMap::Shared::SI32::touch");
    REGISTER_KW(si32, reserve,         "Data::HashMap::Shared::SI32::reserve");
    REGISTER_KW(si32, stat_evictions,  "Data::HashMap::Shared::SI32::stat_evictions");
    REGISTER_KW(si32, stat_expired,    "Data::HashMap::Shared::SI32::stat_expired");
    REGISTER_KW(si32, stat_recoveries, "Data::HashMap::Shared::SI32::stat_recoveries");    
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
    REGISTER_KW(si, flush_expired, "Data::HashMap::Shared::SI::flush_expired");
    REGISTER_KW(si, flush_expired_partial, "Data::HashMap::Shared::SI::flush_expired_partial");
    REGISTER_KW(si, mmap_size,     "Data::HashMap::Shared::SI::mmap_size");
    REGISTER_KW(si, touch,           "Data::HashMap::Shared::SI::touch");
    REGISTER_KW(si, reserve,         "Data::HashMap::Shared::SI::reserve");
    REGISTER_KW(si, stat_evictions,  "Data::HashMap::Shared::SI::stat_evictions");
    REGISTER_KW(si, stat_expired,    "Data::HashMap::Shared::SI::stat_expired");
    REGISTER_KW(si, stat_recoveries, "Data::HashMap::Shared::SI::stat_recoveries");    
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
    REGISTER_KW(ss, flush_expired, "Data::HashMap::Shared::SS::flush_expired");
    REGISTER_KW(ss, flush_expired_partial, "Data::HashMap::Shared::SS::flush_expired_partial");
    REGISTER_KW(ss, mmap_size,     "Data::HashMap::Shared::SS::mmap_size");
    REGISTER_KW(ss, touch,           "Data::HashMap::Shared::SS::touch");
    REGISTER_KW(ss, reserve,         "Data::HashMap::Shared::SS::reserve");
    REGISTER_KW(ss, stat_evictions,  "Data::HashMap::Shared::SS::stat_evictions");
    REGISTER_KW(ss, stat_expired,    "Data::HashMap::Shared::SS::stat_expired");
    REGISTER_KW(ss, stat_recoveries, "Data::HashMap::Shared::SS::stat_recoveries");

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_i16_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::I16: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int16_t key, int16_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = shm_i16_put(h, key, value);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int16_t value;
        if (!shm_i16_get(h, key, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = shm_i16_remove(h, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = shm_i16_exists(h, key);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int ok;
        int16_t val = shm_i16_incr_by(h, key, 1, &ok);
        if (!ok) croak("HashMap::Shared::I16: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int ok;
        int16_t val = shm_i16_incr_by(h, key, -1, &ok);
        if (!ok) croak("HashMap::Shared::I16: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, int16_t key, int16_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int ok;
        int16_t val = shm_i16_incr_by(h, key, delta, &ok);
        if (!ok) croak("HashMap::Shared::I16: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI16 *nodes = (ShmNodeI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI16 *nodes = (ShmNodeI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].value);
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI16 *nodes = (ShmNodeI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                mXPUSHi(nodes[i].key);
                mXPUSHi(nodes[i].value);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int16_t out_key, out_value;
        if (shm_i16_each(h, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_i16_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        shm_i16_iter_reset(h);
        shm_i16_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        shm_i16_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeI16 *nodes = (ShmNodeI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                SV* val = newSViv(nodes[i].value);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)nodes[i].key);
                if (!hv_store(hv, kbuf, klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int16_t key, int16_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int16_t out;
        int rc = shm_i16_get_or_set(h, key, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int16_t key, int16_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_i16_put_ttl(h, key, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_ttl(h);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int16_t out_value;
        if (!shm_i16_take(h, key, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int done = 0;
        uint32_t flushed = shm_i16_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = shm_i16_touch(h, key);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = shm_i16_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::I16 object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::I16->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

SV*
ttl_remaining(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        int64_t remaining = shm_i16_ttl_remaining(h, key);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        RETVAL = (UV)shm_i16_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::I16::Cursor", (void*)c);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I16::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_i16_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I16::Cursor", self_sv);
        int16_t out_key, out_value;
        if (shm_i16_cursor_next(c, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I16::Cursor", self_sv);
        shm_i16_cursor_reset(c);

bool
seek(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I16::Cursor", self_sv);
        RETVAL = shm_i16_cursor_seek(c, key);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I32
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_i32_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::I32: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int32_t key, int32_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = shm_i32_put(h, key, value);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int32_t value;
        if (!shm_i32_get(h, key, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = shm_i32_remove(h, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = shm_i32_exists(h, key);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int ok;
        int32_t val = shm_i32_incr_by(h, key, 1, &ok);
        if (!ok) croak("HashMap::Shared::I32: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int ok;
        int32_t val = shm_i32_incr_by(h, key, -1, &ok);
        if (!ok) croak("HashMap::Shared::I32: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, int32_t key, int32_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int ok;
        int32_t val = shm_i32_incr_by(h, key, delta, &ok);
        if (!ok) croak("HashMap::Shared::I32: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI32 *nodes = (ShmNodeI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].key);
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI32 *nodes = (ShmNodeI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].value);
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI32 *nodes = (ShmNodeI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                mXPUSHi(nodes[i].key);
                mXPUSHi(nodes[i].value);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int32_t out_key, out_value;
        if (shm_i32_each(h, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_i32_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        shm_i32_iter_reset(h);
        shm_i32_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        shm_i32_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeI32 *nodes = (ShmNodeI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                SV* val = newSViv(nodes[i].value);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)nodes[i].key);
                if (!hv_store(hv, kbuf, klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int32_t key, int32_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int32_t out;
        int rc = shm_i32_get_or_set(h, key, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int32_t key, int32_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_i32_put_ttl(h, key, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_ttl(h);
    OUTPUT:
        RETVAL



SV*
take(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int32_t out_value;
        if (!shm_i32_take(h, key, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int done = 0;
        uint32_t flushed = shm_i32_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = shm_i32_touch(h, key);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = shm_i32_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::I32 object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::I32->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

SV*
ttl_remaining(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        int64_t remaining = shm_i32_ttl_remaining(h, key);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        RETVAL = (UV)shm_i32_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::I32::Cursor", (void*)c);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I32::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_i32_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I32::Cursor", self_sv);
        int32_t out_key; int32_t out_value;
        if (shm_i32_cursor_next(c, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I32::Cursor", self_sv);
        shm_i32_cursor_reset(c);

bool
seek(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I32::Cursor", self_sv);
        RETVAL = shm_i32_cursor_seek(c, key);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::II
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_ii_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::II: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int64_t key, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_put(h, key, value);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t value;
        if (!shm_ii_get(h, key, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_remove(h, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_exists(h, key);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int ok;
        int64_t val = shm_ii_incr_by(h, key, 1, &ok);
        if (!ok) croak("HashMap::Shared::II: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int ok;
        int64_t val = shm_ii_incr_by(h, key, -1, &ok);
        if (!ok) croak("HashMap::Shared::II: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, int64_t key, int64_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int ok;
        int64_t val = shm_ii_incr_by(h, key, delta, &ok);
        if (!ok) croak("HashMap::Shared::II: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeII *nodes = (ShmNodeII *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].key);
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeII *nodes = (ShmNodeII *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].value);
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeII *nodes = (ShmNodeII *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                mXPUSHi(nodes[i].key);
                mXPUSHi(nodes[i].value);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out_key, out_value;
        if (shm_ii_each(h, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_ii_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        shm_ii_iter_reset(h);
        shm_ii_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        shm_ii_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeII *nodes = (ShmNodeII *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                SV* val = newSViv(nodes[i].value);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)nodes[i].key);
                if (!hv_store(hv, kbuf, klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int64_t key, int64_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out;
        int rc = shm_ii_get_or_set(h, key, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int64_t key, int64_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_ii_put_ttl(h, key, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_ttl(h);
    OUTPUT:
        RETVAL



SV*
take(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t out_value;
        if (!shm_ii_take(h, key, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int done = 0;
        uint32_t flushed = shm_ii_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_touch(h, key);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = shm_ii_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::II object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::II->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

SV*
ttl_remaining(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        int64_t remaining = shm_ii_ttl_remaining(h, key);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        RETVAL = (UV)shm_ii_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::II", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::II::Cursor", (void*)c);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::II::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_ii_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::II::Cursor", self_sv);
        int64_t out_key; int64_t out_value;
        if (shm_ii_cursor_next(c, &out_key, &out_value)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::II::Cursor", self_sv);
        shm_ii_cursor_reset(c);

bool
seek(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::II::Cursor", self_sv);
        RETVAL = shm_ii_cursor_seek(c, key);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I16S
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_i16s_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::I16S: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int16_t key, SV* value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = shm_i16s_put(h, key, _vstr, (uint32_t)_vlen, _vutf8);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int16_t key, SV* value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        EXTRACT_STR_VAL(value);
        REQUIRE_TTL(h);
        RETVAL = shm_i16s_put_ttl(h, key, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (!shm_i16s_get(h, key, &val, &val_len, &val_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = shm_i16s_remove(h, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = shm_i16s_exists(h, key);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI16S *nodes = (ShmNodeI16S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].key);
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI16S *nodes = (ShmNodeI16S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* sv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI16S *nodes = (ShmNodeI16S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                mXPUSHi(nodes[i].key);
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* sv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        int16_t out_key;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (shm_i16s_each(h, &out_key, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            SV* sv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(sv);
            mXPUSHs(sv);
            XSRETURN(2);
        }
        shm_i16s_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        shm_i16s_iter_reset(h);
        shm_i16s_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        shm_i16s_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeI16S *nodes = (ShmNodeI16S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                bool vutf8 = SHM_UNPACK_UTF8(nodes[i].val_len);
                SV* val = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (vutf8) SvUTF8_on(val);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)nodes[i].key);
                if (!hv_store(hv, kbuf, klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int16_t key, SV* default_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        EXTRACT_STR_VAL(default_sv);
        int rc = shm_i16s_get_or_set(h, key, _vstr, (uint32_t)_vlen, _vutf8, &out_str, &out_len, &out_utf8);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL



SV*
ttl_remaining(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        int64_t remaining = shm_i16s_ttl_remaining(h, key);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::I16S::Cursor", (void*)c);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        if (!shm_i16s_take(h, key, &out_str, &out_len, &out_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        int done = 0;
        uint32_t flushed = shm_i16s_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = shm_i16s_touch(h, key);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = shm_i16s_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = (UV)shm_i16s_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I16S", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::I16S object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::I16S->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I16S::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_i16s_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I16S::Cursor", self_sv);
        int16_t out_key;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (shm_i16s_cursor_next(c, &out_key, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            SV* sv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(sv);
            mXPUSHs(sv);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I16S::Cursor", self_sv);
        shm_i16s_cursor_reset(c);

bool
seek(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I16S::Cursor", self_sv);
        RETVAL = shm_i16s_cursor_seek(c, key);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I32S
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_i32s_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::I32S: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int32_t key, SV* value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = shm_i32s_put(h, key, _vstr, (uint32_t)_vlen, _vutf8);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int32_t key, SV* value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        EXTRACT_STR_VAL(value);
        REQUIRE_TTL(h);
        RETVAL = shm_i32s_put_ttl(h, key, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (!shm_i32s_get(h, key, &val, &val_len, &val_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = shm_i32s_remove(h, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = shm_i32s_exists(h, key);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI32S *nodes = (ShmNodeI32S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].key);
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI32S *nodes = (ShmNodeI32S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* sv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeI32S *nodes = (ShmNodeI32S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                mXPUSHi(nodes[i].key);
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* sv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        int32_t out_key;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (shm_i32s_each(h, &out_key, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            SV* sv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(sv);
            mXPUSHs(sv);
            XSRETURN(2);
        }
        shm_i32s_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        shm_i32s_iter_reset(h);
        shm_i32s_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        shm_i32s_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeI32S *nodes = (ShmNodeI32S *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                bool vutf8 = SHM_UNPACK_UTF8(nodes[i].val_len);
                SV* val = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (vutf8) SvUTF8_on(val);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)nodes[i].key);
                if (!hv_store(hv, kbuf, klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int32_t key, SV* default_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        EXTRACT_STR_VAL(default_sv);
        int rc = shm_i32s_get_or_set(h, key, _vstr, (uint32_t)_vlen, _vutf8, &out_str, &out_len, &out_utf8);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL



SV*
ttl_remaining(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        int64_t remaining = shm_i32s_ttl_remaining(h, key);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::I32S::Cursor", (void*)c);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        if (!shm_i32s_take(h, key, &out_str, &out_len, &out_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        int done = 0;
        uint32_t flushed = shm_i32s_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = shm_i32s_touch(h, key);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = shm_i32s_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = (UV)shm_i32s_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::I32S", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::I32S object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::I32S->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::I32S::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_i32s_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I32S::Cursor", self_sv);
        int32_t out_key;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (shm_i32s_cursor_next(c, &out_key, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            SV* sv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(sv);
            mXPUSHs(sv);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I32S::Cursor", self_sv);
        shm_i32s_cursor_reset(c);

bool
seek(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::I32S::Cursor", self_sv);
        RETVAL = shm_i32s_cursor_seek(c, key);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::IS
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_is_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::IS: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int64_t key, SV* value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = shm_is_put(h, key, _vstr, (uint32_t)_vlen, _vutf8);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int64_t key, SV* value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        EXTRACT_STR_VAL(value);
        REQUIRE_TTL(h);
        RETVAL = shm_is_put_ttl(h, key, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (!shm_is_get(h, key, &val, &val_len, &val_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = shm_is_remove(h, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = shm_is_exists(h, key);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeIS *nodes = (ShmNodeIS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].key);
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeIS *nodes = (ShmNodeIS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* sv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeIS *nodes = (ShmNodeIS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                mXPUSHi(nodes[i].key);
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* sv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        int64_t out_key;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (shm_is_each(h, &out_key, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            SV* sv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(sv);
            mXPUSHs(sv);
            XSRETURN(2);
        }
        shm_is_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        shm_is_iter_reset(h);
        shm_is_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        shm_is_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeIS *nodes = (ShmNodeIS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                bool vutf8 = SHM_UNPACK_UTF8(nodes[i].val_len);
                SV* val = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (vutf8) SvUTF8_on(val);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)nodes[i].key);
                if (!hv_store(hv, kbuf, klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int64_t key, SV* default_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        EXTRACT_STR_VAL(default_sv);
        int rc = shm_is_get_or_set(h, key, _vstr, (uint32_t)_vlen, _vutf8, &out_str, &out_len, &out_utf8);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL



SV*
ttl_remaining(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        int64_t remaining = shm_is_ttl_remaining(h, key);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::IS::Cursor", (void*)c);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        if (!shm_is_take(h, key, &out_str, &out_len, &out_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        int done = 0;
        uint32_t flushed = shm_is_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = shm_is_touch(h, key);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = shm_is_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = (UV)shm_is_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::IS", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::IS object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::IS->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::IS::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_is_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::IS::Cursor", self_sv);
        int64_t out_key;
        const char *out_val; uint32_t out_vlen; bool out_vutf8;
        if (shm_is_cursor_next(c, &out_key, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            mXPUSHi(out_key);
            SV* sv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(sv);
            mXPUSHs(sv);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::IS::Cursor", self_sv);
        shm_is_cursor_reset(c);

bool
seek(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::IS::Cursor", self_sv);
        RETVAL = shm_is_cursor_seek(c, key);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI16
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_si16_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::SI16: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, int16_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si16_put(h, _kstr, (uint32_t)_klen, _kutf8, value);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, int16_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_si16_put_ttl(h, _kstr, (uint32_t)_klen, _kutf8, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t value;
        if (!shm_si16_get(h, _kstr, (uint32_t)_klen, _kutf8, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si16_remove(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si16_exists(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int16_t val = shm_si16_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, 1, &ok);
        if (!ok) croak("HashMap::Shared::SI16: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int16_t val = shm_si16_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, -1, &ok);
        if (!ok) croak("HashMap::Shared::SI16: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, SV* key_sv, int16_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int16_t val = shm_si16_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, delta, &ok);
        if (!ok) croak("HashMap::Shared::SI16: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI16 *nodes = (ShmNodeSI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* sv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI16 *nodes = (ShmNodeSI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].value);
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI16 *nodes = (ShmNodeSI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* sv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
                mXPUSHi(nodes[i].value);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int16_t out_value;
        if (shm_si16_each(h, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_si16_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        shm_si16_iter_reset(h);
        shm_si16_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        shm_si16_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeSI16 *nodes = (ShmNodeSI16 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                bool kutf8 = SHM_UNPACK_UTF8(nodes[i].key_len);
                SV* val = newSViv(nodes[i].value);
                if (!hv_store(hv, h->arena + nodes[i].key_off,
                               kutf8 ? -(I32)klen : (I32)klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, int16_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t out;
        int rc = shm_si16_get_or_set(h, _kstr, (uint32_t)_klen, _kutf8, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL



SV*
take(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t out_value;
        if (!shm_si16_take(h, _kstr, (uint32_t)_klen, _kutf8, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        int done = 0;
        uint32_t flushed = shm_si16_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si16_touch(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = shm_si16_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::SI16 object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::SI16->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

SV*
ttl_remaining(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t remaining = shm_si16_ttl_remaining(h, _kstr, (uint32_t)_klen, _kutf8);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        RETVAL = (UV)shm_si16_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI16", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::SI16::Cursor", (void*)c);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI16::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_si16_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI16::Cursor", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int16_t out_value;
        if (shm_si16_cursor_next(c, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI16::Cursor", self_sv);
        shm_si16_cursor_reset(c);

bool
seek(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI16::Cursor", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si16_cursor_seek(c, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI32
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_si32_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::SI32: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, int32_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si32_put(h, _kstr, (uint32_t)_klen, _kutf8, value);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, int32_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_si32_put_ttl(h, _kstr, (uint32_t)_klen, _kutf8, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t value;
        if (!shm_si32_get(h, _kstr, (uint32_t)_klen, _kutf8, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si32_remove(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si32_exists(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int32_t val = shm_si32_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, 1, &ok);
        if (!ok) croak("HashMap::Shared::SI32: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int32_t val = shm_si32_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, -1, &ok);
        if (!ok) croak("HashMap::Shared::SI32: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, SV* key_sv, int32_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int32_t val = shm_si32_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, delta, &ok);
        if (!ok) croak("HashMap::Shared::SI32: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI32 *nodes = (ShmNodeSI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* sv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI32 *nodes = (ShmNodeSI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].value);
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI32 *nodes = (ShmNodeSI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* sv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
                mXPUSHi(nodes[i].value);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int32_t out_value;
        if (shm_si32_each(h, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_si32_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        shm_si32_iter_reset(h);
        shm_si32_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        shm_si32_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeSI32 *nodes = (ShmNodeSI32 *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                bool kutf8 = SHM_UNPACK_UTF8(nodes[i].key_len);
                SV* val = newSViv(nodes[i].value);
                if (!hv_store(hv, h->arena + nodes[i].key_off,
                               kutf8 ? -(I32)klen : (I32)klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, int32_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t out;
        int rc = shm_si32_get_or_set(h, _kstr, (uint32_t)_klen, _kutf8, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL



SV*
ttl_remaining(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t remaining = shm_si32_ttl_remaining(h, _kstr, (uint32_t)_klen, _kutf8);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::SI32::Cursor", (void*)c);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t out_value;
        if (!shm_si32_take(h, _kstr, (uint32_t)_klen, _kutf8, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        int done = 0;
        uint32_t flushed = shm_si32_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si32_touch(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = shm_si32_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = (UV)shm_si32_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI32", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::SI32 object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::SI32->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI32::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_si32_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI32::Cursor", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int32_t out_value;
        if (shm_si32_cursor_next(c, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI32::Cursor", self_sv);
        shm_si32_cursor_reset(c);

bool
seek(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI32::Cursor", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si32_cursor_seek(c, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_si_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::SI: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, int64_t value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_put(h, _kstr, (uint32_t)_klen, _kutf8, value);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, int64_t value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        REQUIRE_TTL(h);
        RETVAL = shm_si_put_ttl(h, _kstr, (uint32_t)_klen, _kutf8, value, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t value;
        if (!shm_si_get(h, _kstr, (uint32_t)_klen, _kutf8, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_remove(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_exists(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int64_t val = shm_si_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, 1, &ok);
        if (!ok) croak("HashMap::Shared::SI: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int64_t val = shm_si_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, -1, &ok);
        if (!ok) croak("HashMap::Shared::SI: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, SV* key_sv, int64_t delta)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int ok;
        int64_t val = shm_si_incr_by(h, _kstr, (uint32_t)_klen, _kutf8, delta, &ok);
        if (!ok) croak("HashMap::Shared::SI: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI *nodes = (ShmNodeSI *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* sv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI *nodes = (ShmNodeSI *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now))
                mXPUSHi(nodes[i].value);
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSI *nodes = (ShmNodeSI *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* sv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
                mXPUSHi(nodes[i].value);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int64_t out_value;
        if (shm_si_each(h, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        shm_si_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        shm_si_iter_reset(h);
        shm_si_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        shm_si_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeSI *nodes = (ShmNodeSI *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                bool kutf8 = SHM_UNPACK_UTF8(nodes[i].key_len);
                SV* val = newSViv(nodes[i].value);
                if (!hv_store(hv, h->arena + nodes[i].key_off,
                               kutf8 ? -(I32)klen : (I32)klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, int64_t default_value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t out;
        int rc = shm_si_get_or_set(h, _kstr, (uint32_t)_klen, _kutf8, default_value, &out);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSViv(out);
    OUTPUT:
        RETVAL



SV*
ttl_remaining(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t remaining = shm_si_ttl_remaining(h, _kstr, (uint32_t)_klen, _kutf8);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::SI::Cursor", (void*)c);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t out_value;
        if (!shm_si_take(h, _kstr, (uint32_t)_klen, _kutf8, &out_value)) XSRETURN_UNDEF;
        RETVAL = newSViv(out_value);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        int done = 0;
        uint32_t flushed = shm_si_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_touch(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = shm_si_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = (UV)shm_si_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SI", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::SI object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::SI->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SI::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_si_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI::Cursor", self_sv);
        const char *out_key; uint32_t out_klen; bool out_kutf8;
        int64_t out_value;
        if (shm_si_cursor_next(c, &out_key, &out_klen, &out_kutf8, &out_value)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            mXPUSHi(out_value);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI::Cursor", self_sv);
        shm_si_cursor_reset(c);

bool
seek(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SI::Cursor", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_si_cursor_seek(c, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL


MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SS
PROTOTYPES: DISABLE

SV*
new(char* class, char* path, UV max_entries, UV lru_max = 0, UV ttl_default = 0)
    CODE:
        char errbuf[SHM_ERR_BUFLEN]; ShmHandle* map = shm_ss_create(path, (uint32_t)max_entries, (uint32_t)lru_max, (uint32_t)ttl_default, errbuf);
        if (!map) croak("HashMap::Shared::SS: %s", errbuf[0] ? errbuf : "unknown error");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_sv)));
        if (!h) return;
        shm_close_map(h);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, SV* value)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = shm_ss_put(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, SV* value, UV ttl_sec)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(value);
        REQUIRE_TTL(h);
        RETVAL = shm_ss_put_ttl(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl_sec);
    OUTPUT:
        RETVAL

UV
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_max_size(h);
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_ttl(h);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (!shm_ss_get(h, _kstr, (uint32_t)_klen, _kutf8, &val, &val_len, &val_utf8))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_remove(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_exists(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

UV
size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_size(h);
    OUTPUT:
        RETVAL

UV
max_entries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_max_entries(h);
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSS *nodes = (ShmNodeSS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* sv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSS *nodes = (ShmNodeSS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* sv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }
        

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        ShmHeader *hdr = h->hdr;
        ShmNodeSS *nodes = (ShmNodeSS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        EXTEND(SP, hdr->size * 2);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                SV* ksv = newSVpvn(h->arena + nodes[i].key_off, klen);
                if (SHM_UNPACK_UTF8(nodes[i].key_len)) SvUTF8_on(ksv);
                mXPUSHs(ksv);
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                SV* vsv = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (SHM_UNPACK_UTF8(nodes[i].val_len)) SvUTF8_on(vsv);
                mXPUSHs(vsv);
            }
        }
        

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        const char *out_key, *out_val;
        uint32_t out_klen, out_vlen;
        bool out_kutf8, out_vutf8;
        if (shm_ss_each(h, &out_key, &out_klen, &out_kutf8, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            SV* vsv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(vsv);
            mXPUSHs(vsv);
            XSRETURN(2);
        }
        shm_ss_flush_deferred(h);
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        shm_ss_iter_reset(h);
        shm_ss_flush_deferred(h);

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        shm_ss_clear(h);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        HV* hv = newHV();
        ShmHeader *hdr = h->hdr;
        ShmNodeSS *nodes = (ShmNodeSS *)h->nodes;
        uint32_t now = h->expires_at ? (uint32_t)time(NULL) : 0;
        RDLOCK_GUARD(hdr);
        for (uint32_t i = 0; i < hdr->table_cap; i++) {
            if (h->states[i] == SHM_LIVE && !SHM_IS_EXPIRED(h, i, now)) {
                uint32_t klen = SHM_UNPACK_LEN(nodes[i].key_len);
                bool kutf8 = SHM_UNPACK_UTF8(nodes[i].key_len);
                uint32_t vlen = SHM_UNPACK_LEN(nodes[i].val_len);
                bool vutf8 = SHM_UNPACK_UTF8(nodes[i].val_len);
                SV* val = newSVpvn(h->arena + nodes[i].val_off, vlen);
                if (vutf8) SvUTF8_on(val);
                if (!hv_store(hv, h->arena + nodes[i].key_off,
                               kutf8 ? -(I32)klen : (I32)klen, val, 0)) SvREFCNT_dec(val);
            }
        }
        
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, SV* default_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        EXTRACT_STR_VAL(default_sv);
        int rc = shm_ss_get_or_set(h, _kstr, (uint32_t)_klen, _kutf8, _vstr, (uint32_t)_vlen, _vutf8, &out_str, &out_len, &out_utf8);
        if (!rc) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL


SV*
ttl_remaining(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t remaining = shm_ss_ttl_remaining(h, _kstr, (uint32_t)_klen, _kutf8);
        if (remaining < 0) XSRETURN_UNDEF;
        RETVAL = newSViv(remaining);
    OUTPUT:
        RETVAL

UV
capacity(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_capacity(h);
    OUTPUT:
        RETVAL

UV
tombstones(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_tombstones(h);
    OUTPUT:
        RETVAL

SV*
cursor(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        ShmCursor* c = shm_cursor_create(h);
        if (!c) croak("Failed to allocate cursor");
        RETVAL = sv_setref_pv(newSV(0), "Data::HashMap::Shared::SS::Cursor", (void*)c);
    OUTPUT:
        RETVAL

SV*
take(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char *out_str; uint32_t out_len; bool out_utf8;
        if (!shm_ss_take(h, _kstr, (uint32_t)_klen, _kutf8, &out_str, &out_len, &out_utf8)) XSRETURN_UNDEF;
        RETVAL = newSVpvn(out_str, out_len);
        if (out_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

UV
flush_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_flush_expired(h);
    OUTPUT:
        RETVAL


void
flush_expired_partial(SV* self_sv, UV limit)
    PPCODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        int done = 0;
        uint32_t flushed = shm_ss_flush_expired_partial(h, (uint32_t)limit, &done);
        EXTEND(SP, 2);
        mPUSHu(flushed);
        mPUSHi(done);

UV
mmap_size(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_mmap_size(h);
    OUTPUT:
        RETVAL


bool
touch(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_touch(h, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

bool
reserve(SV* self_sv, UV target)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = shm_ss_reserve(h, (uint32_t)target);
    OUTPUT:
        RETVAL

UV
stat_evictions(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_stat_evictions(h);
    OUTPUT:
        RETVAL

UV
stat_expired(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_stat_expired(h);
    OUTPUT:
        RETVAL



UV
stat_recoveries(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = (UV)shm_ss_stat_recoveries(h);
    OUTPUT:
        RETVAL

SV*
path(SV* self_sv)
    CODE:
        EXTRACT_MAP("Data::HashMap::Shared::SS", self_sv);
        RETVAL = newSVpv(h->path, 0);
    OUTPUT:
        RETVAL


bool
unlink(SV* self_or_class, ...)
    CODE:
        const char *p;
        if (SvROK(self_or_class) && SvOBJECT(SvRV(self_or_class))) {
            ShmHandle* h = INT2PTR(ShmHandle*, SvIV(SvRV(self_or_class)));
            if (!h) croak("Attempted to use a destroyed Data::HashMap::Shared::SS object");
            p = h->path;
        } else {
            if (items < 2) croak("Usage: Data::HashMap::Shared::SS->unlink($path)");
            p = SvPV_nolen(ST(1));
        }
        RETVAL = shm_unlink_path(p);
    OUTPUT:
        RETVAL

MODULE = Data::HashMap::Shared    PACKAGE = Data::HashMap::Shared::SS::Cursor
PROTOTYPES: DISABLE

void
DESTROY(SV* self_sv)
    CODE:
        if (!SvROK(self_sv)) return;
        ShmCursor* c = INT2PTR(ShmCursor*, SvIV(SvRV(self_sv)));
        if (!c) return;
        ShmHandle* h = c->handle;
        shm_cursor_destroy(c);
        if (h) shm_ss_flush_deferred(h);
        sv_setiv(SvRV(self_sv), 0);

void
next(SV* self_sv)
    PPCODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SS::Cursor", self_sv);
        const char *out_key, *out_val;
        uint32_t out_klen, out_vlen;
        bool out_kutf8, out_vutf8;
        if (shm_ss_cursor_next(c, &out_key, &out_klen, &out_kutf8, &out_val, &out_vlen, &out_vutf8)) {
            EXTEND(SP, 2);
            SV* ksv = newSVpvn(out_key, out_klen);
            if (out_kutf8) SvUTF8_on(ksv);
            mXPUSHs(ksv);
            SV* vsv = newSVpvn(out_val, out_vlen);
            if (out_vutf8) SvUTF8_on(vsv);
            mXPUSHs(vsv);
            XSRETURN(2);
        }
        XSRETURN_EMPTY;

void
reset(SV* self_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SS::Cursor", self_sv);
        shm_ss_cursor_reset(c);

bool
seek(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_CURSOR("Data::HashMap::Shared::SS::Cursor", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = shm_ss_cursor_seek(c, _kstr, (uint32_t)_klen, _kutf8);
    OUTPUT:
        RETVAL

