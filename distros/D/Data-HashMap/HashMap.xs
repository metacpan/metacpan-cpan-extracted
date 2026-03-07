#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hashmap_i16.h"
#include "hashmap_i16s.h"
#include "hashmap_si16.h"
#include "hashmap_i32.h"
#include "hashmap_ii.h"
#include "hashmap_is.h"
#include "hashmap_si.h"
#include "hashmap_ss.h"
#include "hashmap_i32s.h"
#include "hashmap_si32.h"
#include "hashmap_i32a.h"
#include "hashmap_i16a.h"
#include "hashmap_ia.h"
#include "hashmap_sa.h"

#include "XSParseKeyword.h"

/* ---- Helper macros ---- */

#define EXTRACT_MAP(type, classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    type* self = INT2PTR(type*, SvIV(SvRV(sv))); \
    if (!self) croak("Attempted to use a destroyed %s object", classname)

#define HM_MAX_STR_LEN 0x7FFFFFFFU

/* SV* value free callback for IA/SA variants */
static void hm_sv_free(void* sv) {
    dTHX;
    SvREFCNT_dec((SV*)sv);
}

#define EXTRACT_STR_KEY(sv) \
    STRLEN _klen; \
    const char* _kstr = SvPV(sv, _klen); \
    if (_klen > HM_MAX_STR_LEN) croak("key too long (max 2GB)"); \
    bool _kutf8 = SvUTF8(sv) ? true : false; \
    uint32_t _khash = hm_hash_string(_kstr, (uint32_t)_klen); \
    (void)_kutf8

#define EXTRACT_STR_VAL(sv) \
    STRLEN _vlen; \
    const char* _vstr = SvPV(sv, _vlen); \
    if (_vlen > HM_MAX_STR_LEN) croak("value too long (max 2GB)"); \
    bool _vutf8 = SvUTF8(sv) ? true : false

/* ---- Extract optional (max_size, default_ttl) from new() args ---- */

#define EXTRACT_NEW_ARGS(max_size_var, ttl_var) \
    size_t max_size_var = 0; \
    uint32_t ttl_var = 0; \
    if (items > 1) max_size_var = (size_t)SvUV(ST(1)); \
    if (items > 2) ttl_var = (uint32_t)SvUV(ST(2))

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

/* list-returning variant for keys/values/items */
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


/* ---- Keyword hook definitions ----
 *
 * Macro to define a keyword hook struct.
 * variant = i16, i16a, i16s, i32, i32a, i32s, ia, ii, is, sa, si16, si32, si, ss
 * kw = keyword name (e.g., put, get)
 * nargs = 1, 2, or 3
 * builder = build function (build_kw_1arg, build_kw_2arg, etc.)
 */
#define DEFINE_KW_HOOK(variant, PKG, kw, nargs, builder) \
    static const struct XSParseKeywordHooks hooks_hm_##variant##_##kw = { \
        .flags = XPK_FLAG_EXPR, \
        .permit_hintkey = "Data::HashMap::" PKG "/hm_" #variant "_" #kw, \
        .pieces = pieces_##nargs##expr, \
        .build = builder, \
    };

/* I16 keywords */
DEFINE_KW_HOOK(i16, "I16", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", incr,     2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", decr,     2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", incr_by,  3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16, "I16", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i16, "I16", get_or_set, 3, build_kw_3arg)

/* I16S keywords (int16 -> string) */
DEFINE_KW_HOOK(i16s, "I16S", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i16s, "I16S", get_or_set, 3, build_kw_3arg)

/* SI16 keywords (string -> int16) */
DEFINE_KW_HOOK(si16, "SI16", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", incr,     2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", decr,     2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", incr_by,  3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(si16, "SI16", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(si16, "SI16", get_or_set, 3, build_kw_3arg)

/* I32 keywords */
DEFINE_KW_HOOK(i32, "I32", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", incr,     2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", decr,     2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", incr_by,  3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32, "I32", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i32, "I32", get_or_set, 3, build_kw_3arg)

/* II keywords */
DEFINE_KW_HOOK(ii, "II", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", incr,     2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", decr,     2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", incr_by,  3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(ii, "II", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(ii, "II", get_or_set, 3, build_kw_3arg)

/* IS keywords */
DEFINE_KW_HOOK(is, "IS", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(is, "IS", get_or_set, 3, build_kw_3arg)

/* SI keywords */
DEFINE_KW_HOOK(si, "SI", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", incr,     2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", decr,     2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", incr_by,  3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(si, "SI", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(si, "SI", get_or_set, 3, build_kw_3arg)

/* SS keywords */
DEFINE_KW_HOOK(ss, "SS", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(ss, "SS", get_or_set, 3, build_kw_3arg)

/* I32S keywords (int32 -> string) */
DEFINE_KW_HOOK(i32s, "I32S", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i32s, "I32S", get_or_set, 3, build_kw_3arg)

/* SI32 keywords (string -> int32) */
DEFINE_KW_HOOK(si32, "SI32", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", incr,     2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", decr,     2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", incr_by,  3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(si32, "SI32", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(si32, "SI32", get_or_set, 3, build_kw_3arg)

/* I32A keywords (int32 -> SV*) */
DEFINE_KW_HOOK(i32a, "I32A", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(i32a, "I32A", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32a, "I32A", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32a, "I32A", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32a, "I32A", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32a, "I32A", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i32a, "I32A", get_or_set, 3, build_kw_3arg)

/* I16A keywords (int16 -> SV*) */
DEFINE_KW_HOOK(i16a, "I16A", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(i16a, "I16A", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16a, "I16A", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16a, "I16A", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16a, "I16A", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16a, "I16A", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i16a, "I16A", get_or_set, 3, build_kw_3arg)

/* IA keywords (int64 -> SV*) */
DEFINE_KW_HOOK(ia, "IA", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(ia, "IA", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(ia, "IA", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(ia, "IA", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(ia, "IA", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(ia, "IA", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(ia, "IA", get_or_set, 3, build_kw_3arg)

/* SA keywords (string -> SV*) */
DEFINE_KW_HOOK(sa, "SA", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(sa, "SA", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(sa, "SA", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(sa, "SA", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(sa, "SA", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(sa, "SA", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(sa, "SA", get_or_set, 3, build_kw_3arg)

/* ---- Macro to register a keyword ---- */
#define REGISTER_KW(variant, kw, func_name) \
    register_xs_parse_keyword("hm_" #variant "_" #kw, \
        &hooks_hm_##variant##_##kw, (void*)func_name)

/* ---- Live node checks ---- */
#define I16_NODE_LIVE(n)  ((n).key != INT16_MIN && (n).key != (INT16_MIN + 1))
#define I16S_NODE_LIVE(n) I16_NODE_LIVE(n)  /* I16S keys are int16_t */
#define I32_NODE_LIVE(n)  ((n).key != INT32_MIN && (n).key != (INT32_MIN + 1))
#define I32S_NODE_LIVE(n) I32_NODE_LIVE(n)  /* I32S keys are int32_t */
#define II_NODE_LIVE(n)   ((n).key != INT64_MIN && (n).key != (INT64_MIN + 1))
#define IS_NODE_LIVE(n)   II_NODE_LIVE(n)   /* IS keys are int64_t */
#define STR_NODE_LIVE(n)  ((n).key != NULL && (n).key != &hm_str_tombstone_marker)
#define SI16_NODE_LIVE(n) STR_NODE_LIVE(n)
#define SI32_NODE_LIVE(n) STR_NODE_LIVE(n)
#define SI_NODE_LIVE(n)   STR_NODE_LIVE(n)
#define SS_NODE_LIVE(n)   STR_NODE_LIVE(n)
#define I32A_NODE_LIVE(n) I32_NODE_LIVE(n)  /* I32A keys are int32_t */
#define I16A_NODE_LIVE(n) I16_NODE_LIVE(n) /* I16A keys are int16_t */
#define IA_NODE_LIVE(n)   II_NODE_LIVE(n)   /* IA keys are int64_t */
#define SA_NODE_LIVE(n)   STR_NODE_LIVE(n)

/* ---- TTL-aware iteration helper ---- */
#define HM_TTL_SKIP_EXPIRED(self, i, now) \
    (self->expires_at && self->expires_at[i] && (now) >= self->expires_at[i])


MODULE = Data::HashMap    PACKAGE = Data::HashMap::I32
PROTOTYPES: DISABLE

BOOT:
    boot_xs_parse_keyword(0.40);
    REGISTER_KW(i16, put,      "Data::HashMap::I16::put");
    REGISTER_KW(i16, get,      "Data::HashMap::I16::get");
    REGISTER_KW(i16, remove,   "Data::HashMap::I16::remove");
    REGISTER_KW(i16, exists,   "Data::HashMap::I16::exists");
    REGISTER_KW(i16, incr,     "Data::HashMap::I16::incr");
    REGISTER_KW(i16, decr,     "Data::HashMap::I16::decr");
    REGISTER_KW(i16, incr_by,  "Data::HashMap::I16::incr_by");
    REGISTER_KW(i16, size,     "Data::HashMap::I16::size");
    REGISTER_KW(i16, keys,     "Data::HashMap::I16::keys");
    REGISTER_KW(i16, values,   "Data::HashMap::I16::values");
    REGISTER_KW(i16, items,    "Data::HashMap::I16::items");
    REGISTER_KW(i16, max_size, "Data::HashMap::I16::max_size");
    REGISTER_KW(i16, ttl,      "Data::HashMap::I16::ttl");
    REGISTER_KW(i16, each,       "Data::HashMap::I16::each");
    REGISTER_KW(i16, iter_reset, "Data::HashMap::I16::iter_reset");
    REGISTER_KW(i16, clear,      "Data::HashMap::I16::clear");
    REGISTER_KW(i16, to_hash,    "Data::HashMap::I16::to_hash");
    REGISTER_KW(i16, put_ttl,    "Data::HashMap::I16::put_ttl");
    REGISTER_KW(i16, get_or_set, "Data::HashMap::I16::get_or_set");
    REGISTER_KW(i16s, put,      "Data::HashMap::I16S::put");
    REGISTER_KW(i16s, get,      "Data::HashMap::I16S::get");
    REGISTER_KW(i16s, remove,   "Data::HashMap::I16S::remove");
    REGISTER_KW(i16s, exists,   "Data::HashMap::I16S::exists");
    REGISTER_KW(i16s, size,     "Data::HashMap::I16S::size");
    REGISTER_KW(i16s, keys,     "Data::HashMap::I16S::keys");
    REGISTER_KW(i16s, values,   "Data::HashMap::I16S::values");
    REGISTER_KW(i16s, items,    "Data::HashMap::I16S::items");
    REGISTER_KW(i16s, max_size, "Data::HashMap::I16S::max_size");
    REGISTER_KW(i16s, ttl,      "Data::HashMap::I16S::ttl");
    REGISTER_KW(i16s, each,       "Data::HashMap::I16S::each");
    REGISTER_KW(i16s, iter_reset, "Data::HashMap::I16S::iter_reset");
    REGISTER_KW(i16s, clear,      "Data::HashMap::I16S::clear");
    REGISTER_KW(i16s, to_hash,    "Data::HashMap::I16S::to_hash");
    REGISTER_KW(i16s, put_ttl,    "Data::HashMap::I16S::put_ttl");
    REGISTER_KW(i16s, get_or_set, "Data::HashMap::I16S::get_or_set");
    REGISTER_KW(si16, put,      "Data::HashMap::SI16::put");
    REGISTER_KW(si16, get,      "Data::HashMap::SI16::get");
    REGISTER_KW(si16, remove,   "Data::HashMap::SI16::remove");
    REGISTER_KW(si16, exists,   "Data::HashMap::SI16::exists");
    REGISTER_KW(si16, incr,     "Data::HashMap::SI16::incr");
    REGISTER_KW(si16, decr,     "Data::HashMap::SI16::decr");
    REGISTER_KW(si16, incr_by,  "Data::HashMap::SI16::incr_by");
    REGISTER_KW(si16, size,     "Data::HashMap::SI16::size");
    REGISTER_KW(si16, keys,     "Data::HashMap::SI16::keys");
    REGISTER_KW(si16, values,   "Data::HashMap::SI16::values");
    REGISTER_KW(si16, items,    "Data::HashMap::SI16::items");
    REGISTER_KW(si16, max_size, "Data::HashMap::SI16::max_size");
    REGISTER_KW(si16, ttl,      "Data::HashMap::SI16::ttl");
    REGISTER_KW(si16, each,       "Data::HashMap::SI16::each");
    REGISTER_KW(si16, iter_reset, "Data::HashMap::SI16::iter_reset");
    REGISTER_KW(si16, clear,      "Data::HashMap::SI16::clear");
    REGISTER_KW(si16, to_hash,    "Data::HashMap::SI16::to_hash");
    REGISTER_KW(si16, put_ttl,    "Data::HashMap::SI16::put_ttl");
    REGISTER_KW(si16, get_or_set, "Data::HashMap::SI16::get_or_set");
    REGISTER_KW(i32, put,      "Data::HashMap::I32::put");
    REGISTER_KW(i32, get,      "Data::HashMap::I32::get");
    REGISTER_KW(i32, remove,   "Data::HashMap::I32::remove");
    REGISTER_KW(i32, exists,   "Data::HashMap::I32::exists");
    REGISTER_KW(i32, incr,     "Data::HashMap::I32::incr");
    REGISTER_KW(i32, decr,     "Data::HashMap::I32::decr");
    REGISTER_KW(i32, incr_by,  "Data::HashMap::I32::incr_by");
    REGISTER_KW(i32, size,     "Data::HashMap::I32::size");
    REGISTER_KW(i32, keys,     "Data::HashMap::I32::keys");
    REGISTER_KW(i32, values,   "Data::HashMap::I32::values");
    REGISTER_KW(i32, items,    "Data::HashMap::I32::items");
    REGISTER_KW(i32, max_size, "Data::HashMap::I32::max_size");
    REGISTER_KW(i32, ttl,      "Data::HashMap::I32::ttl");
    REGISTER_KW(i32, each,       "Data::HashMap::I32::each");
    REGISTER_KW(i32, iter_reset, "Data::HashMap::I32::iter_reset");
    REGISTER_KW(i32, clear,      "Data::HashMap::I32::clear");
    REGISTER_KW(i32, to_hash,    "Data::HashMap::I32::to_hash");
    REGISTER_KW(i32, put_ttl,    "Data::HashMap::I32::put_ttl");
    REGISTER_KW(i32, get_or_set, "Data::HashMap::I32::get_or_set");
    REGISTER_KW(ii, put,      "Data::HashMap::II::put");
    REGISTER_KW(ii, get,      "Data::HashMap::II::get");
    REGISTER_KW(ii, remove,   "Data::HashMap::II::remove");
    REGISTER_KW(ii, exists,   "Data::HashMap::II::exists");
    REGISTER_KW(ii, incr,     "Data::HashMap::II::incr");
    REGISTER_KW(ii, decr,     "Data::HashMap::II::decr");
    REGISTER_KW(ii, incr_by,  "Data::HashMap::II::incr_by");
    REGISTER_KW(ii, size,     "Data::HashMap::II::size");
    REGISTER_KW(ii, keys,     "Data::HashMap::II::keys");
    REGISTER_KW(ii, values,   "Data::HashMap::II::values");
    REGISTER_KW(ii, items,    "Data::HashMap::II::items");
    REGISTER_KW(ii, max_size, "Data::HashMap::II::max_size");
    REGISTER_KW(ii, ttl,      "Data::HashMap::II::ttl");
    REGISTER_KW(ii, each,       "Data::HashMap::II::each");
    REGISTER_KW(ii, iter_reset, "Data::HashMap::II::iter_reset");
    REGISTER_KW(ii, clear,      "Data::HashMap::II::clear");
    REGISTER_KW(ii, to_hash,    "Data::HashMap::II::to_hash");
    REGISTER_KW(ii, put_ttl,    "Data::HashMap::II::put_ttl");
    REGISTER_KW(ii, get_or_set, "Data::HashMap::II::get_or_set");
    REGISTER_KW(is, put,      "Data::HashMap::IS::put");
    REGISTER_KW(is, get,      "Data::HashMap::IS::get");
    REGISTER_KW(is, remove,   "Data::HashMap::IS::remove");
    REGISTER_KW(is, exists,   "Data::HashMap::IS::exists");
    REGISTER_KW(is, size,     "Data::HashMap::IS::size");
    REGISTER_KW(is, keys,     "Data::HashMap::IS::keys");
    REGISTER_KW(is, values,   "Data::HashMap::IS::values");
    REGISTER_KW(is, items,    "Data::HashMap::IS::items");
    REGISTER_KW(is, max_size, "Data::HashMap::IS::max_size");
    REGISTER_KW(is, ttl,      "Data::HashMap::IS::ttl");
    REGISTER_KW(is, each,       "Data::HashMap::IS::each");
    REGISTER_KW(is, iter_reset, "Data::HashMap::IS::iter_reset");
    REGISTER_KW(is, clear,      "Data::HashMap::IS::clear");
    REGISTER_KW(is, to_hash,    "Data::HashMap::IS::to_hash");
    REGISTER_KW(is, put_ttl,    "Data::HashMap::IS::put_ttl");
    REGISTER_KW(is, get_or_set, "Data::HashMap::IS::get_or_set");
    REGISTER_KW(si, put,      "Data::HashMap::SI::put");
    REGISTER_KW(si, get,      "Data::HashMap::SI::get");
    REGISTER_KW(si, remove,   "Data::HashMap::SI::remove");
    REGISTER_KW(si, exists,   "Data::HashMap::SI::exists");
    REGISTER_KW(si, incr,     "Data::HashMap::SI::incr");
    REGISTER_KW(si, decr,     "Data::HashMap::SI::decr");
    REGISTER_KW(si, incr_by,  "Data::HashMap::SI::incr_by");
    REGISTER_KW(si, size,     "Data::HashMap::SI::size");
    REGISTER_KW(si, keys,     "Data::HashMap::SI::keys");
    REGISTER_KW(si, values,   "Data::HashMap::SI::values");
    REGISTER_KW(si, items,    "Data::HashMap::SI::items");
    REGISTER_KW(si, max_size, "Data::HashMap::SI::max_size");
    REGISTER_KW(si, ttl,      "Data::HashMap::SI::ttl");
    REGISTER_KW(si, each,       "Data::HashMap::SI::each");
    REGISTER_KW(si, iter_reset, "Data::HashMap::SI::iter_reset");
    REGISTER_KW(si, clear,      "Data::HashMap::SI::clear");
    REGISTER_KW(si, to_hash,    "Data::HashMap::SI::to_hash");
    REGISTER_KW(si, put_ttl,    "Data::HashMap::SI::put_ttl");
    REGISTER_KW(si, get_or_set, "Data::HashMap::SI::get_or_set");
    REGISTER_KW(ss, put,      "Data::HashMap::SS::put");
    REGISTER_KW(ss, get,      "Data::HashMap::SS::get");
    REGISTER_KW(ss, remove,   "Data::HashMap::SS::remove");
    REGISTER_KW(ss, exists,   "Data::HashMap::SS::exists");
    REGISTER_KW(ss, size,     "Data::HashMap::SS::size");
    REGISTER_KW(ss, keys,     "Data::HashMap::SS::keys");
    REGISTER_KW(ss, values,   "Data::HashMap::SS::values");
    REGISTER_KW(ss, items,    "Data::HashMap::SS::items");
    REGISTER_KW(ss, max_size, "Data::HashMap::SS::max_size");
    REGISTER_KW(ss, ttl,      "Data::HashMap::SS::ttl");
    REGISTER_KW(ss, each,       "Data::HashMap::SS::each");
    REGISTER_KW(ss, iter_reset, "Data::HashMap::SS::iter_reset");
    REGISTER_KW(ss, clear,      "Data::HashMap::SS::clear");
    REGISTER_KW(ss, to_hash,    "Data::HashMap::SS::to_hash");
    REGISTER_KW(ss, put_ttl,    "Data::HashMap::SS::put_ttl");
    REGISTER_KW(ss, get_or_set, "Data::HashMap::SS::get_or_set");
    REGISTER_KW(i32s, put,      "Data::HashMap::I32S::put");
    REGISTER_KW(i32s, get,      "Data::HashMap::I32S::get");
    REGISTER_KW(i32s, remove,   "Data::HashMap::I32S::remove");
    REGISTER_KW(i32s, exists,   "Data::HashMap::I32S::exists");
    REGISTER_KW(i32s, size,     "Data::HashMap::I32S::size");
    REGISTER_KW(i32s, keys,     "Data::HashMap::I32S::keys");
    REGISTER_KW(i32s, values,   "Data::HashMap::I32S::values");
    REGISTER_KW(i32s, items,    "Data::HashMap::I32S::items");
    REGISTER_KW(i32s, max_size, "Data::HashMap::I32S::max_size");
    REGISTER_KW(i32s, ttl,      "Data::HashMap::I32S::ttl");
    REGISTER_KW(i32s, each,       "Data::HashMap::I32S::each");
    REGISTER_KW(i32s, iter_reset, "Data::HashMap::I32S::iter_reset");
    REGISTER_KW(i32s, clear,      "Data::HashMap::I32S::clear");
    REGISTER_KW(i32s, to_hash,    "Data::HashMap::I32S::to_hash");
    REGISTER_KW(i32s, put_ttl,    "Data::HashMap::I32S::put_ttl");
    REGISTER_KW(i32s, get_or_set, "Data::HashMap::I32S::get_or_set");
    REGISTER_KW(si32, put,      "Data::HashMap::SI32::put");
    REGISTER_KW(si32, get,      "Data::HashMap::SI32::get");
    REGISTER_KW(si32, remove,   "Data::HashMap::SI32::remove");
    REGISTER_KW(si32, exists,   "Data::HashMap::SI32::exists");
    REGISTER_KW(si32, incr,     "Data::HashMap::SI32::incr");
    REGISTER_KW(si32, decr,     "Data::HashMap::SI32::decr");
    REGISTER_KW(si32, incr_by,  "Data::HashMap::SI32::incr_by");
    REGISTER_KW(si32, size,     "Data::HashMap::SI32::size");
    REGISTER_KW(si32, keys,     "Data::HashMap::SI32::keys");
    REGISTER_KW(si32, values,   "Data::HashMap::SI32::values");
    REGISTER_KW(si32, items,    "Data::HashMap::SI32::items");
    REGISTER_KW(si32, max_size, "Data::HashMap::SI32::max_size");
    REGISTER_KW(si32, ttl,      "Data::HashMap::SI32::ttl");
    REGISTER_KW(si32, each,       "Data::HashMap::SI32::each");
    REGISTER_KW(si32, iter_reset, "Data::HashMap::SI32::iter_reset");
    REGISTER_KW(si32, clear,      "Data::HashMap::SI32::clear");
    REGISTER_KW(si32, to_hash,    "Data::HashMap::SI32::to_hash");
    REGISTER_KW(si32, put_ttl,    "Data::HashMap::SI32::put_ttl");
    REGISTER_KW(si32, get_or_set, "Data::HashMap::SI32::get_or_set");
    REGISTER_KW(i32a, put,      "Data::HashMap::I32A::put");
    REGISTER_KW(i32a, get,      "Data::HashMap::I32A::get");
    REGISTER_KW(i32a, remove,   "Data::HashMap::I32A::remove");
    REGISTER_KW(i32a, exists,   "Data::HashMap::I32A::exists");
    REGISTER_KW(i32a, size,     "Data::HashMap::I32A::size");
    REGISTER_KW(i32a, keys,     "Data::HashMap::I32A::keys");
    REGISTER_KW(i32a, values,   "Data::HashMap::I32A::values");
    REGISTER_KW(i32a, items,    "Data::HashMap::I32A::items");
    REGISTER_KW(i32a, max_size, "Data::HashMap::I32A::max_size");
    REGISTER_KW(i32a, ttl,      "Data::HashMap::I32A::ttl");
    REGISTER_KW(i32a, each,       "Data::HashMap::I32A::each");
    REGISTER_KW(i32a, iter_reset, "Data::HashMap::I32A::iter_reset");
    REGISTER_KW(i32a, clear,      "Data::HashMap::I32A::clear");
    REGISTER_KW(i32a, to_hash,    "Data::HashMap::I32A::to_hash");
    REGISTER_KW(i32a, put_ttl,    "Data::HashMap::I32A::put_ttl");
    REGISTER_KW(i32a, get_or_set, "Data::HashMap::I32A::get_or_set");
    REGISTER_KW(i16a, put,      "Data::HashMap::I16A::put");
    REGISTER_KW(i16a, get,      "Data::HashMap::I16A::get");
    REGISTER_KW(i16a, remove,   "Data::HashMap::I16A::remove");
    REGISTER_KW(i16a, exists,   "Data::HashMap::I16A::exists");
    REGISTER_KW(i16a, size,     "Data::HashMap::I16A::size");
    REGISTER_KW(i16a, keys,     "Data::HashMap::I16A::keys");
    REGISTER_KW(i16a, values,   "Data::HashMap::I16A::values");
    REGISTER_KW(i16a, items,    "Data::HashMap::I16A::items");
    REGISTER_KW(i16a, max_size, "Data::HashMap::I16A::max_size");
    REGISTER_KW(i16a, ttl,      "Data::HashMap::I16A::ttl");
    REGISTER_KW(i16a, each,       "Data::HashMap::I16A::each");
    REGISTER_KW(i16a, iter_reset, "Data::HashMap::I16A::iter_reset");
    REGISTER_KW(i16a, clear,      "Data::HashMap::I16A::clear");
    REGISTER_KW(i16a, to_hash,    "Data::HashMap::I16A::to_hash");
    REGISTER_KW(i16a, put_ttl,    "Data::HashMap::I16A::put_ttl");
    REGISTER_KW(i16a, get_or_set, "Data::HashMap::I16A::get_or_set");
    REGISTER_KW(ia, put,      "Data::HashMap::IA::put");
    REGISTER_KW(ia, get,      "Data::HashMap::IA::get");
    REGISTER_KW(ia, remove,   "Data::HashMap::IA::remove");
    REGISTER_KW(ia, exists,   "Data::HashMap::IA::exists");
    REGISTER_KW(ia, size,     "Data::HashMap::IA::size");
    REGISTER_KW(ia, keys,     "Data::HashMap::IA::keys");
    REGISTER_KW(ia, values,   "Data::HashMap::IA::values");
    REGISTER_KW(ia, items,    "Data::HashMap::IA::items");
    REGISTER_KW(ia, max_size, "Data::HashMap::IA::max_size");
    REGISTER_KW(ia, ttl,      "Data::HashMap::IA::ttl");
    REGISTER_KW(ia, each,       "Data::HashMap::IA::each");
    REGISTER_KW(ia, iter_reset, "Data::HashMap::IA::iter_reset");
    REGISTER_KW(ia, clear,      "Data::HashMap::IA::clear");
    REGISTER_KW(ia, to_hash,    "Data::HashMap::IA::to_hash");
    REGISTER_KW(ia, put_ttl,    "Data::HashMap::IA::put_ttl");
    REGISTER_KW(ia, get_or_set, "Data::HashMap::IA::get_or_set");
    REGISTER_KW(sa, put,      "Data::HashMap::SA::put");
    REGISTER_KW(sa, get,      "Data::HashMap::SA::get");
    REGISTER_KW(sa, remove,   "Data::HashMap::SA::remove");
    REGISTER_KW(sa, exists,   "Data::HashMap::SA::exists");
    REGISTER_KW(sa, size,     "Data::HashMap::SA::size");
    REGISTER_KW(sa, keys,     "Data::HashMap::SA::keys");
    REGISTER_KW(sa, values,   "Data::HashMap::SA::values");
    REGISTER_KW(sa, items,    "Data::HashMap::SA::items");
    REGISTER_KW(sa, max_size, "Data::HashMap::SA::max_size");
    REGISTER_KW(sa, ttl,      "Data::HashMap::SA::ttl");
    REGISTER_KW(sa, each,       "Data::HashMap::SA::each");
    REGISTER_KW(sa, iter_reset, "Data::HashMap::SA::iter_reset");
    REGISTER_KW(sa, clear,      "Data::HashMap::SA::clear");
    REGISTER_KW(sa, to_hash,    "Data::HashMap::SA::to_hash");
    REGISTER_KW(sa, put_ttl,    "Data::HashMap::SA::put_ttl");
    REGISTER_KW(sa, get_or_set, "Data::HashMap::SA::get_or_set");

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapI32* map = hashmap_i32_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::I32");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        hashmap_i32_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int32_t key, int32_t value)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        RETVAL = hashmap_i32_put(self, key, value, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        int32_t value;
        if (!hashmap_i32_get(self, key, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        RETVAL = hashmap_i32_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        RETVAL = hashmap_i32_exists(self, key);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        int32_t val;
        if (!hashmap_i32_increment(self, key, &val))
            croak("HashMap::I32: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        int32_t val;
        if (!hashmap_i32_decrement(self, key, &val))
            croak("HashMap::I32: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, int32_t key, int32_t delta)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        int32_t val;
        if (!hashmap_i32_increment_by(self, key, delta, &val))
            croak("HashMap::I32: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].value);
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                mXPUSHi(self->nodes[i].value);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (I32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                mXPUSHi(self->nodes[i].value);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        hashmap_i32_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* val = newSViv(self->nodes[i].value);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int32_t key, int32_t value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        RETVAL = hashmap_i32_put(self, key, value, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int32_t key, int32_t default_value)
    CODE:
        EXTRACT_MAP(HashMapI32, "Data::HashMap::I32", self_sv);
        int32_t value;
        if (hashmap_i32_get(self, key, &value)) {
            RETVAL = newSViv(value);
        } else {
            if (!hashmap_i32_put(self, key, default_value, 0))
                XSRETURN_UNDEF;
            RETVAL = newSViv(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::II
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapII* map = hashmap_ii_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::II");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        hashmap_ii_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int64_t key, int64_t value)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        RETVAL = hashmap_ii_put(self, key, value, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        int64_t value;
        if (!hashmap_ii_get(self, key, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        RETVAL = hashmap_ii_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        RETVAL = hashmap_ii_exists(self, key);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        int64_t val;
        if (!hashmap_ii_increment(self, key, &val))
            croak("HashMap::II: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        int64_t val;
        if (!hashmap_ii_decrement(self, key, &val))
            croak("HashMap::II: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, int64_t key, int64_t delta)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        int64_t val;
        if (!hashmap_ii_increment_by(self, key, delta, &val))
            croak("HashMap::II: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (II_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (II_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].value);
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (II_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                mXPUSHi(self->nodes[i].value);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (II_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                mXPUSHi(self->nodes[i].value);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        hashmap_ii_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (II_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* val = newSViv(self->nodes[i].value);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int64_t key, int64_t value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        RETVAL = hashmap_ii_put(self, key, value, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int64_t key, int64_t default_value)
    CODE:
        EXTRACT_MAP(HashMapII, "Data::HashMap::II", self_sv);
        int64_t value;
        if (hashmap_ii_get(self, key, &value)) {
            RETVAL = newSViv(value);
        } else {
            if (!hashmap_ii_put(self, key, default_value, 0))
                XSRETURN_UNDEF;
            RETVAL = newSViv(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::IS
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapIS* map = hashmap_is_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::IS");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        hashmap_is_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int64_t key, SV* value)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_is_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        const char* val;
        uint32_t val_len;
        bool val_utf8;
        if (!hashmap_is_get(self, key, &val, &val_len, &val_utf8))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        RETVAL = hashmap_is_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        RETVAL = hashmap_is_exists(self, key);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                if (self->nodes[i].value) {
                    SV* sv = newSVpvn(self->nodes[i].value,
                                      HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                if (self->nodes[i].value) {
                    SV* sv = newSVpvn(self->nodes[i].value,
                                      HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (IS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                if (self->nodes[i].value) {
                    SV* vsv = newSVpvn(self->nodes[i].value,
                                       HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(vsv);
                    mXPUSHs(vsv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        hashmap_is_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t vlen = HM_UNPACK_LEN(self->nodes[i].val_len);
                bool vutf8 = HM_UNPACK_UTF8(self->nodes[i].val_len);
                SV* val = self->nodes[i].value
                    ? newSVpvn(self->nodes[i].value, vlen)
                    : newSV(0);
                if (self->nodes[i].value && vutf8) SvUTF8_on(val);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int64_t key, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_is_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int64_t key, SV* default_sv)
    CODE:
        EXTRACT_MAP(HashMapIS, "Data::HashMap::IS", self_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (hashmap_is_get(self, key, &val, &val_len, &val_utf8)) {
            RETVAL = newSVpvn(val, val_len);
            if (val_utf8) SvUTF8_on(RETVAL);
        } else {
            EXTRACT_STR_VAL(default_sv);
            if (!hashmap_is_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, 0))
                XSRETURN_UNDEF;
            RETVAL = SvREFCNT_inc(default_sv);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::SI
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapSI* map = hashmap_si_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::SI");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        hashmap_si_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, int64_t value)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, value, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t value;
        if (!hashmap_si_get(self, _kstr, (uint32_t)_klen, _khash, &value))
            XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si_remove(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si_exists(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t val;
        if (!hashmap_si_increment(self, _kstr, (uint32_t)_klen, _khash, _kutf8, &val))
            croak("HashMap::SI: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t val;
        if (!hashmap_si_decrement(self, _kstr, (uint32_t)_klen, _khash, _kutf8, &val))
            croak("HashMap::SI: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, SV* key_sv, int64_t delta)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t val;
        if (!hashmap_si_increment_by(self, _kstr, (uint32_t)_klen, _khash, _kutf8, delta, &val))
            croak("HashMap::SI: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].value);
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
                mXPUSHi(self->nodes[i].value);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (SI_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                {
                    uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                    SV* ksv = newSVpvn(self->nodes[i].key, klen);
                    if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(ksv);
                    mXPUSHs(ksv);
                }
                mXPUSHi(self->nodes[i].value);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        hashmap_si_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                bool kutf8 = HM_UNPACK_UTF8(self->nodes[i].key_len);
                SV* val = newSViv(self->nodes[i].value);
                (void)hv_store(hv, self->nodes[i].key, kutf8 ? -(I32)klen : (I32)klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, int64_t value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, value, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, int64_t default_value)
    CODE:
        EXTRACT_MAP(HashMapSI, "Data::HashMap::SI", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int64_t value;
        if (hashmap_si_get(self, _kstr, (uint32_t)_klen, _khash, &value)) {
            RETVAL = newSViv(value);
        } else {
            if (!hashmap_si_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, default_value, 0))
                XSRETURN_UNDEF;
            RETVAL = newSViv(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::SS
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapSS* map = hashmap_ss_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::SS");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        hashmap_ss_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, SV* value)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_ss_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8,
                                _vstr, (uint32_t)_vlen, _vutf8, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char* val;
        uint32_t val_len;
        bool val_utf8;
        if (!hashmap_ss_get(self, _kstr, (uint32_t)_klen, _khash, &val, &val_len, &val_utf8))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_ss_remove(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_ss_exists(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                if (self->nodes[i].value) {
                    SV* sv = newSVpvn(self->nodes[i].value,
                                      HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
                if (self->nodes[i].value) {
                    SV* vsv = newSVpvn(self->nodes[i].value,
                                       HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(vsv);
                    mXPUSHs(vsv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (SS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                {
                    uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                    SV* ksv = newSVpvn(self->nodes[i].key, klen);
                    if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(ksv);
                    mXPUSHs(ksv);
                }
                if (self->nodes[i].value) {
                    SV* vsv = newSVpvn(self->nodes[i].value,
                                       HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(vsv);
                    mXPUSHs(vsv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        hashmap_ss_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SS_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                bool kutf8 = HM_UNPACK_UTF8(self->nodes[i].key_len);
                uint32_t vlen = HM_UNPACK_LEN(self->nodes[i].val_len);
                bool vutf8 = HM_UNPACK_UTF8(self->nodes[i].val_len);
                SV* val = self->nodes[i].value
                    ? newSVpvn(self->nodes[i].value, vlen)
                    : newSV(0);
                if (self->nodes[i].value && vutf8) SvUTF8_on(val);
                (void)hv_store(hv, self->nodes[i].key, kutf8 ? -(I32)klen : (I32)klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_ss_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8,
                                _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, SV* default_sv)
    CODE:
        EXTRACT_MAP(HashMapSS, "Data::HashMap::SS", self_sv);
        EXTRACT_STR_KEY(key_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (hashmap_ss_get(self, _kstr, (uint32_t)_klen, _khash, &val, &val_len, &val_utf8)) {
            RETVAL = newSVpvn(val, val_len);
            if (val_utf8) SvUTF8_on(RETVAL);
        } else {
            EXTRACT_STR_VAL(default_sv);
            if (!hashmap_ss_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8,
                          _vstr, (uint32_t)_vlen, _vutf8, 0))
                XSRETURN_UNDEF;
            RETVAL = SvREFCNT_inc(default_sv);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::I32S
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapI32S* map = hashmap_i32s_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::I32S");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        hashmap_i32s_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int32_t key, SV* value)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_i32s_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        const char* val;
        uint32_t val_len;
        bool val_utf8;
        if (!hashmap_i32s_get(self, key, &val, &val_len, &val_utf8))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        RETVAL = hashmap_i32s_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        RETVAL = hashmap_i32s_exists(self, key);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                if (self->nodes[i].value) {
                    SV* sv = newSVpvn(self->nodes[i].value,
                                      HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                if (self->nodes[i].value) {
                    SV* sv = newSVpvn(self->nodes[i].value,
                                      HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (I32S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                if (self->nodes[i].value) {
                    SV* vsv = newSVpvn(self->nodes[i].value,
                                       HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(vsv);
                    mXPUSHs(vsv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        hashmap_i32s_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t vlen = HM_UNPACK_LEN(self->nodes[i].val_len);
                bool vutf8 = HM_UNPACK_UTF8(self->nodes[i].val_len);
                SV* val = self->nodes[i].value
                    ? newSVpvn(self->nodes[i].value, vlen)
                    : newSV(0);
                if (self->nodes[i].value && vutf8) SvUTF8_on(val);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int32_t key, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_i32s_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int32_t key, SV* default_sv)
    CODE:
        EXTRACT_MAP(HashMapI32S, "Data::HashMap::I32S", self_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (hashmap_i32s_get(self, key, &val, &val_len, &val_utf8)) {
            RETVAL = newSVpvn(val, val_len);
            if (val_utf8) SvUTF8_on(RETVAL);
        } else {
            EXTRACT_STR_VAL(default_sv);
            if (!hashmap_i32s_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, 0))
                XSRETURN_UNDEF;
            RETVAL = SvREFCNT_inc(default_sv);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::SI32
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapSI32* map = hashmap_si32_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::SI32");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        hashmap_si32_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, int32_t value)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si32_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, value, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t value;
        if (!hashmap_si32_get(self, _kstr, (uint32_t)_klen, _khash, &value))
            XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si32_remove(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si32_exists(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t val;
        if (!hashmap_si32_increment(self, _kstr, (uint32_t)_klen, _khash, _kutf8, &val))
            croak("HashMap::SI32: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t val;
        if (!hashmap_si32_decrement(self, _kstr, (uint32_t)_klen, _khash, _kutf8, &val))
            croak("HashMap::SI32: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, SV* key_sv, int32_t delta)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t val;
        if (!hashmap_si32_increment_by(self, _kstr, (uint32_t)_klen, _khash, _kutf8, delta, &val))
            croak("HashMap::SI32: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].value);
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
                mXPUSHi(self->nodes[i].value);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (SI32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                {
                    uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                    SV* ksv = newSVpvn(self->nodes[i].key, klen);
                    if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(ksv);
                    mXPUSHs(ksv);
                }
                mXPUSHi(self->nodes[i].value);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        hashmap_si32_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI32_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                bool kutf8 = HM_UNPACK_UTF8(self->nodes[i].key_len);
                SV* val = newSViv(self->nodes[i].value);
                (void)hv_store(hv, self->nodes[i].key, kutf8 ? -(I32)klen : (I32)klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, int32_t value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si32_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, value, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, int32_t default_value)
    CODE:
        EXTRACT_MAP(HashMapSI32, "Data::HashMap::SI32", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int32_t value;
        if (hashmap_si32_get(self, _kstr, (uint32_t)_klen, _khash, &value)) {
            RETVAL = newSViv(value);
        } else {
            if (!hashmap_si32_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, default_value, 0))
                XSRETURN_UNDEF;
            RETVAL = newSViv(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::I16
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapI16* map = hashmap_i16_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::I16");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        hashmap_i16_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int16_t key, int16_t value)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        RETVAL = hashmap_i16_put(self, key, value, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        int16_t value;
        if (!hashmap_i16_get(self, key, &value)) XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        RETVAL = hashmap_i16_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        RETVAL = hashmap_i16_exists(self, key);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        int16_t val;
        if (!hashmap_i16_increment(self, key, &val))
            croak("HashMap::I16: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        int16_t val;
        if (!hashmap_i16_decrement(self, key, &val))
            croak("HashMap::I16: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, int16_t key, int16_t delta)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        int16_t val;
        if (!hashmap_i16_increment_by(self, key, delta, &val))
            croak("HashMap::I16: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].value);
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                mXPUSHi(self->nodes[i].value);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (I16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                mXPUSHi(self->nodes[i].value);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        hashmap_i16_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* val = newSViv(self->nodes[i].value);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int16_t key, int16_t value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        RETVAL = hashmap_i16_put(self, key, value, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int16_t key, int16_t default_value)
    CODE:
        EXTRACT_MAP(HashMapI16, "Data::HashMap::I16", self_sv);
        int16_t value;
        if (hashmap_i16_get(self, key, &value)) {
            RETVAL = newSViv(value);
        } else {
            if (!hashmap_i16_put(self, key, default_value, 0))
                XSRETURN_UNDEF;
            RETVAL = newSViv(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::I16S
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapI16S* map = hashmap_i16s_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::I16S");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        hashmap_i16s_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int16_t key, SV* value)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_i16s_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        const char* val;
        uint32_t val_len;
        bool val_utf8;
        if (!hashmap_i16s_get(self, key, &val, &val_len, &val_utf8))
            XSRETURN_UNDEF;
        RETVAL = newSVpvn(val, val_len);
        if (val_utf8) SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        RETVAL = hashmap_i16s_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        RETVAL = hashmap_i16s_exists(self, key);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                if (self->nodes[i].value) {
                    SV* sv = newSVpvn(self->nodes[i].value,
                                      HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                if (self->nodes[i].value) {
                    SV* sv = newSVpvn(self->nodes[i].value,
                                      HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(sv);
                    mXPUSHs(sv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (I16S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                if (self->nodes[i].value) {
                    SV* vsv = newSVpvn(self->nodes[i].value,
                                       HM_UNPACK_LEN(self->nodes[i].val_len));
                    if (HM_UNPACK_UTF8(self->nodes[i].val_len)) SvUTF8_on(vsv);
                    mXPUSHs(vsv);
                } else {
                    XPUSHs(&PL_sv_undef);
                }
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        hashmap_i16s_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16S_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t vlen = HM_UNPACK_LEN(self->nodes[i].val_len);
                bool vutf8 = HM_UNPACK_UTF8(self->nodes[i].val_len);
                SV* val = self->nodes[i].value
                    ? newSVpvn(self->nodes[i].value, vlen)
                    : newSV(0);
                if (self->nodes[i].value && vutf8) SvUTF8_on(val);
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int16_t key, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        EXTRACT_STR_VAL(value);
        RETVAL = hashmap_i16s_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int16_t key, SV* default_sv)
    CODE:
        EXTRACT_MAP(HashMapI16S, "Data::HashMap::I16S", self_sv);
        const char* val; uint32_t val_len; bool val_utf8;
        if (hashmap_i16s_get(self, key, &val, &val_len, &val_utf8)) {
            RETVAL = newSVpvn(val, val_len);
            if (val_utf8) SvUTF8_on(RETVAL);
        } else {
            EXTRACT_STR_VAL(default_sv);
            if (!hashmap_i16s_put(self, key, _vstr, (uint32_t)_vlen, _vutf8, 0))
                XSRETURN_UNDEF;
            RETVAL = SvREFCNT_inc(default_sv);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::SI16
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapSI16* map = hashmap_si16_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::SI16");
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        hashmap_si16_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, int16_t value)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si16_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, value, 0);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t value;
        if (!hashmap_si16_get(self, _kstr, (uint32_t)_klen, _khash, &value))
            XSRETURN_UNDEF;
        RETVAL = newSViv(value);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si16_remove(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si16_exists(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

SV*
incr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t val;
        if (!hashmap_si16_increment(self, _kstr, (uint32_t)_klen, _khash, _kutf8, &val))
            croak("HashMap::SI16: increment failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
decr(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t val;
        if (!hashmap_si16_decrement(self, _kstr, (uint32_t)_klen, _khash, _kutf8, &val))
            croak("HashMap::SI16: decrement failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

SV*
incr_by(SV* self_sv, SV* key_sv, int16_t delta)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t val;
        if (!hashmap_si16_increment_by(self, _kstr, (uint32_t)_klen, _khash, _kutf8, delta, &val))
            croak("HashMap::SI16: incr_by failed");
        RETVAL = newSViv(val);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].value);
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
                mXPUSHi(self->nodes[i].value);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (SI16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                {
                    uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                    SV* ksv = newSVpvn(self->nodes[i].key, klen);
                    if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(ksv);
                    mXPUSHs(ksv);
                }
                mXPUSHi(self->nodes[i].value);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        hashmap_si16_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SI16_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                bool kutf8 = HM_UNPACK_UTF8(self->nodes[i].key_len);
                SV* val = newSViv(self->nodes[i].value);
                (void)hv_store(hv, self->nodes[i].key, kutf8 ? -(I32)klen : (I32)klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, int16_t value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_si16_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, value, (uint32_t)ttl);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, int16_t default_value)
    CODE:
        EXTRACT_MAP(HashMapSI16, "Data::HashMap::SI16", self_sv);
        EXTRACT_STR_KEY(key_sv);
        int16_t value;
        if (hashmap_si16_get(self, _kstr, (uint32_t)_klen, _khash, &value)) {
            RETVAL = newSViv(value);
        } else {
            if (!hashmap_si16_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, default_value, 0))
                XSRETURN_UNDEF;
            RETVAL = newSViv(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::I32A
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapI32A* map = hashmap_i32a_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::I32A");
        map->free_value_fn = hm_sv_free;
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        hashmap_i32a_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int32_t key, SV* value)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_i32a_put(self, key, (void*)value, 0);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        void* val;
        if (!hashmap_i32a_get(self, key, &val)) XSRETURN_UNDEF;
        RETVAL = SvREFCNT_inc((SV*)val);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        RETVAL = hashmap_i32a_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int32_t key)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        RETVAL = hashmap_i32a_exists(self, key);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (I32A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        hashmap_i32a_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I32A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* val = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int32_t key, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_i32a_put(self, key, (void*)value, (uint32_t)ttl);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int32_t key, SV* default_value)
    CODE:
        EXTRACT_MAP(HashMapI32A, "Data::HashMap::I32A", self_sv);
        void* val;
        if (hashmap_i32a_get(self, key, &val)) {
            RETVAL = SvREFCNT_inc((SV*)val);
        } else {
            SvREFCNT_inc(default_value);
            if (!hashmap_i32a_put(self, key, (void*)default_value, 0)) {
                SvREFCNT_dec(default_value);
                XSRETURN_UNDEF;
            }
            RETVAL = SvREFCNT_inc(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::I16A
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapI16A* map = hashmap_i16a_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::I16A");
        map->free_value_fn = hm_sv_free;
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        hashmap_i16a_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int16_t key, SV* value)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_i16a_put(self, key, (void*)value, 0);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        void* val;
        if (!hashmap_i16a_get(self, key, &val)) XSRETURN_UNDEF;
        RETVAL = SvREFCNT_inc((SV*)val);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        RETVAL = hashmap_i16a_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int16_t key)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        RETVAL = hashmap_i16a_exists(self, key);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (I16A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        hashmap_i16a_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (I16A_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* val = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int16_t key, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_i16a_put(self, key, (void*)value, (uint32_t)ttl);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int16_t key, SV* default_value)
    CODE:
        EXTRACT_MAP(HashMapI16A, "Data::HashMap::I16A", self_sv);
        void* val;
        if (hashmap_i16a_get(self, key, &val)) {
            RETVAL = SvREFCNT_inc((SV*)val);
        } else {
            SvREFCNT_inc(default_value);
            if (!hashmap_i16a_put(self, key, (void*)default_value, 0)) {
                SvREFCNT_dec(default_value);
                XSRETURN_UNDEF;
            }
            RETVAL = SvREFCNT_inc(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::IA
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapIA* map = hashmap_ia_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::IA");
        map->free_value_fn = hm_sv_free;
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        hashmap_ia_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, int64_t key, SV* value)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_ia_put(self, key, (void*)value, 0);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        void* val;
        if (!hashmap_ia_get(self, key, &val)) XSRETURN_UNDEF;
        RETVAL = SvREFCNT_inc((SV*)val);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        RETVAL = hashmap_ia_remove(self, key);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, int64_t key)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        RETVAL = hashmap_ia_exists(self, key);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now))
                mXPUSHi(self->nodes[i].key);
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                mXPUSHi(self->nodes[i].key);
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (IA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                mXPUSHi(self->nodes[i].key);
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        hashmap_ia_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (IA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* val = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                char kbuf[24];
                int klen = my_snprintf(kbuf, sizeof(kbuf), "%" IVdf, (IV)self->nodes[i].key);
                (void)hv_store(hv, kbuf, klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, int64_t key, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_ia_put(self, key, (void*)value, (uint32_t)ttl);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, int64_t key, SV* default_value)
    CODE:
        EXTRACT_MAP(HashMapIA, "Data::HashMap::IA", self_sv);
        void* val;
        if (hashmap_ia_get(self, key, &val)) {
            RETVAL = SvREFCNT_inc((SV*)val);
        } else {
            SvREFCNT_inc(default_value);
            if (!hashmap_ia_put(self, key, (void*)default_value, 0)) {
                SvREFCNT_dec(default_value);
                XSRETURN_UNDEF;
            }
            RETVAL = SvREFCNT_inc(default_value);
        }
    OUTPUT:
        RETVAL



MODULE = Data::HashMap    PACKAGE = Data::HashMap::SA
PROTOTYPES: DISABLE

SV*
new(char* class, ...)
    CODE:
        EXTRACT_NEW_ARGS(_max_size, _ttl);
        HashMapSA* map = hashmap_sa_create(_max_size, _ttl);
        if (!map) croak("Failed to create HashMap::SA");
        map->free_value_fn = hm_sv_free;
        RETVAL = sv_setref_pv(newSV(0), class, (void*)map);
    OUTPUT:
        RETVAL

void
DESTROY(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        hashmap_sa_destroy(self);
        sv_setiv(SvRV(self_sv), 0);

bool
put(SV* self_sv, SV* key_sv, SV* value)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        EXTRACT_STR_KEY(key_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_sa_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, (void*)value, 0);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        EXTRACT_STR_KEY(key_sv);
        void* val;
        if (!hashmap_sa_get(self, _kstr, (uint32_t)_klen, _khash, &val))
            XSRETURN_UNDEF;
        RETVAL = SvREFCNT_inc((SV*)val);
    OUTPUT:
        RETVAL

bool
remove(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_sa_remove(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

bool
exists(SV* self_sv, SV* key_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        EXTRACT_STR_KEY(key_sv);
        RETVAL = hashmap_sa_exists(self, _kstr, (uint32_t)_klen, _khash);
    OUTPUT:
        RETVAL

size_t
size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        RETVAL = self->size;
    OUTPUT:
        RETVAL

size_t
max_size(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        RETVAL = self->max_size;
    OUTPUT:
        RETVAL

UV
ttl(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        RETVAL = (UV)self->default_ttl;
    OUTPUT:
        RETVAL

void
keys(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* sv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(sv);
                mXPUSHs(sv);
            }
        }

void
values(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                SV* sv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(sv);
            }
        }

void
items(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        EXTEND(SP, self->size * 2);
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                SV* ksv = newSVpvn(self->nodes[i].key, klen);
                if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(ksv);
                mXPUSHs(ksv);
                SV* vsv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(vsv);
            }
        }

void
each(SV* self_sv)
    PPCODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        while (self->iter_pos < self->capacity) {
            size_t i = self->iter_pos++;
            if (SA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                EXTEND(SP, 2);
                {
                    uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                    SV* ksv = newSVpvn(self->nodes[i].key, klen);
                    if (HM_UNPACK_UTF8(self->nodes[i].key_len)) SvUTF8_on(ksv);
                    mXPUSHs(ksv);
                }
                SV* vsv = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                mXPUSHs(vsv);
                XSRETURN(2);
            }
        }
        self->iter_pos = 0;
        XSRETURN_EMPTY;

void
iter_reset(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        self->iter_pos = 0;

void
clear(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        hashmap_sa_clear(self);

SV*
to_hash(SV* self_sv)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        HV* hv = newHV();
        uint32_t now = self->expires_at ? (uint32_t)time(NULL) : 0;
        size_t i;
        for (i = 0; i < self->capacity; i++) {
            if (SA_NODE_LIVE(self->nodes[i]) && !HM_TTL_SKIP_EXPIRED(self, i, now)) {
                uint32_t klen = HM_UNPACK_LEN(self->nodes[i].key_len);
                bool kutf8 = HM_UNPACK_UTF8(self->nodes[i].key_len);
                SV* val = self->nodes[i].value ? SvREFCNT_inc((SV*)self->nodes[i].value) : &PL_sv_undef;
                (void)hv_store(hv, self->nodes[i].key, kutf8 ? -(I32)klen : (I32)klen, val, 0);
            }
        }
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

bool
put_ttl(SV* self_sv, SV* key_sv, SV* value, UV ttl)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        EXTRACT_STR_KEY(key_sv);
        SvREFCNT_inc(value);
        RETVAL = hashmap_sa_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, (void*)value, (uint32_t)ttl);
        if (!RETVAL) SvREFCNT_dec(value);
    OUTPUT:
        RETVAL

SV*
get_or_set(SV* self_sv, SV* key_sv, SV* default_value)
    CODE:
        EXTRACT_MAP(HashMapSA, "Data::HashMap::SA", self_sv);
        EXTRACT_STR_KEY(key_sv);
        void* val;
        if (hashmap_sa_get(self, _kstr, (uint32_t)_klen, _khash, &val)) {
            RETVAL = SvREFCNT_inc((SV*)val);
        } else {
            SvREFCNT_inc(default_value);
            if (!hashmap_sa_put(self, _kstr, (uint32_t)_klen, _khash, _kutf8, (void*)default_value, 0)) {
                SvREFCNT_dec(default_value);
                XSRETURN_UNDEF;
            }
            RETVAL = SvREFCNT_inc(default_value);
        }
    OUTPUT:
        RETVAL

