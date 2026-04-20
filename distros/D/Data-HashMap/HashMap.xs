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

/* ---- Cached stash pointers for fast type checking ---- */

static HV* stash_i16;
static HV* stash_i16a;
static HV* stash_i16s;
static HV* stash_i32;
static HV* stash_i32a;
static HV* stash_i32s;
static HV* stash_ia;
static HV* stash_ii;
static HV* stash_is;
static HV* stash_sa;
static HV* stash_si16;
static HV* stash_si32;
static HV* stash_si;
static HV* stash_ss;

/* ---- Helper macros ---- */

#define EXTRACT_MAP(type, stash_var, classname, sv) \
    if (!SvROK(sv) || !SvOBJECT(SvRV(sv)) || SvSTASH(SvRV(sv)) != stash_var) \
        croak("Expected a %s object", classname); \
    type* self = INT2PTR(type*, SvIV(SvRV(sv))); \
    if (!self) croak("Attempted to use a destroyed %s object", classname)

#define HM_MAX_STR_LEN 0x7FFFFFFFU

/* Range-check helpers for typemap (called from generated INPUT code) */
static void croak_i16(IV val) {
    dTHX;
    Perl_croak(aTHX_ "%" IVdf " out of int16 range [-32768, 32767]", val);
}
static void croak_i32(IV val) {
    dTHX;
    Perl_croak(aTHX_ "%" IVdf " out of int32 range [-2147483648, 2147483647]", val);
}

/* SV* value free callback for IA/SA variants */
static void hm_sv_free(void* sv) {
    dTHX;
    SvREFCNT_dec((SV*)sv);
}

/* Zero-copy SV from internal string buffer (opt-in via get_direct).
 * Returns a read-only SV pointing directly at the map's internal buffer.
 * SvLEN=0 tells Perl not to free the buffer; SvREADONLY prevents writes.
 * Caller must not hold the SV past any map mutation (put/remove/clear). */
static inline SV* hm_zerocopy_sv(pTHX_ const char* buf, uint32_t len, bool is_utf8) {
    SV* sv = newSV_type(SVt_PV);
    SvPV_set(sv, (char*)buf);
    SvCUR_set(sv, len);
    SvLEN_set(sv, 0);
    SvPOK_on(sv);
    SvREADONLY_on(sv);
    if (is_utf8) SvUTF8_on(sv);
    return sv;
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

#define EXTRACT_NEW_ARGS(max_size_var, ttl_var, lru_skip_var) \
    size_t max_size_var = 0; \
    uint32_t ttl_var = 0; \
    uint32_t lru_skip_var = 0; \
    if (items > 1) max_size_var = (size_t)SvUV(ST(1)); \
    if (items > 2) ttl_var = (uint32_t)SvUV(ST(2)); \
    if (items > 3) lru_skip_var = (uint32_t)SvUV(ST(3))

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
DEFINE_KW_HOOK(i16, "I16", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16, "I16", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(i16, "I16", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(i16, "I16", cas,     4, build_kw_4arg)
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
DEFINE_KW_HOOK(i16, "I16", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(i16s, "I16S", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16s, "I16S", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", lru_skip, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16s, "I16S", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i16s, "I16S", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i16s, "I16S", get_or_set, 3, build_kw_3arg)
DEFINE_KW_HOOK(i16s, "I16S", get_direct, 2, build_kw_2arg)

/* SI16 keywords (string -> int16) */
DEFINE_KW_HOOK(si16, "SI16", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(si16, "SI16", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(si16, "SI16", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(si16, "SI16", cas,     4, build_kw_4arg)
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
DEFINE_KW_HOOK(si16, "SI16", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(i32, "I32", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32, "I32", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(i32, "I32", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(i32, "I32", cas,     4, build_kw_4arg)
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
DEFINE_KW_HOOK(i32, "I32", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(ii, "II", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(ii, "II", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(ii, "II", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(ii, "II", cas,     4, build_kw_4arg)
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
DEFINE_KW_HOOK(ii, "II", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(is, "IS", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(is, "IS", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", lru_skip, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(is, "IS", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(is, "IS", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(is, "IS", get_or_set, 3, build_kw_3arg)
DEFINE_KW_HOOK(is, "IS", get_direct, 2, build_kw_2arg)

/* SI keywords */
DEFINE_KW_HOOK(si, "SI", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(si, "SI", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(si, "SI", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(si, "SI", cas,     4, build_kw_4arg)
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
DEFINE_KW_HOOK(si, "SI", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(ss, "SS", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(ss, "SS", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", lru_skip, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(ss, "SS", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(ss, "SS", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(ss, "SS", get_or_set, 3, build_kw_3arg)
DEFINE_KW_HOOK(ss, "SS", get_direct, 2, build_kw_2arg)

/* I32S keywords (int32 -> string) */
DEFINE_KW_HOOK(i32s, "I32S", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32s, "I32S", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", lru_skip, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", each,       1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32s, "I32S", iter_reset, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", clear,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", to_hash,    1, build_kw_1arg)
DEFINE_KW_HOOK(i32s, "I32S", put_ttl,    4, build_kw_4arg)
DEFINE_KW_HOOK(i32s, "I32S", get_or_set, 3, build_kw_3arg)
DEFINE_KW_HOOK(i32s, "I32S", get_direct, 2, build_kw_2arg)

/* SI32 keywords (string -> int32) */
DEFINE_KW_HOOK(si32, "SI32", put,      3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", get,      2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", remove,   2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(si32, "SI32", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(si32, "SI32", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(si32, "SI32", cas,     4, build_kw_4arg)
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
DEFINE_KW_HOOK(si32, "SI32", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(i32a, "I32A", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(i32a, "I32A", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i32a, "I32A", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32a, "I32A", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32a, "I32A", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i32a, "I32A", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i32a, "I32A", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(i16a, "I16A", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(i16a, "I16A", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(i16a, "I16A", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16a, "I16A", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16a, "I16A", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(i16a, "I16A", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(i16a, "I16A", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(ia, "IA", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(ia, "IA", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(ia, "IA", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(ia, "IA", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(ia, "IA", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(ia, "IA", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(ia, "IA", lru_skip, 1, build_kw_1arg)
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
DEFINE_KW_HOOK(sa, "SA", take,    2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", drain,   2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", pop,     1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", shift,   1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", reserve, 2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", purge,   1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", capacity, 1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", persist,  2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", swap,    3, build_kw_3arg)
DEFINE_KW_HOOK(sa, "SA", exists,   2, build_kw_2arg)
DEFINE_KW_HOOK(sa, "SA", size,     1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", keys,     1, build_kw_1arg_list)
DEFINE_KW_HOOK(sa, "SA", values,   1, build_kw_1arg_list)
DEFINE_KW_HOOK(sa, "SA", items,    1, build_kw_1arg_list)
DEFINE_KW_HOOK(sa, "SA", max_size, 1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", ttl,      1, build_kw_1arg)
DEFINE_KW_HOOK(sa, "SA", lru_skip, 1, build_kw_1arg)
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
    (self->expires_at && self->expires_at[i] && (now) > self->expires_at[i])

/* Compaction policy after drain/pop/shift in XS. Variant-agnostic: caller
 * supplies the variant-prefixed compact function. Mirrors the C-template's
 * HM_MAYBE_COMPACT macro so the threshold lives in one place per layer. */
#define HM_MAYBE_COMPACT_XS(self, compact_fn) do { \
    if ((self)->tombstones > (self)->capacity / 4 || \
        ((self)->size > 0 && (self)->tombstones > (self)->size)) \
        compact_fn(self); \
} while (0)


MODULE = Data::HashMap    PACKAGE = Data::HashMap::I32
PROTOTYPES: DISABLE

BOOT:
    boot_xs_parse_keyword(0.40);
    stash_i16  = gv_stashpvn("Data::HashMap::I16",  18, GV_ADD);
    stash_i16a = gv_stashpvn("Data::HashMap::I16A", 19, GV_ADD);
    stash_i16s = gv_stashpvn("Data::HashMap::I16S", 19, GV_ADD);
    stash_i32  = gv_stashpvn("Data::HashMap::I32",  18, GV_ADD);
    stash_i32a = gv_stashpvn("Data::HashMap::I32A", 19, GV_ADD);
    stash_i32s = gv_stashpvn("Data::HashMap::I32S", 19, GV_ADD);
    stash_ia   = gv_stashpvn("Data::HashMap::IA",   17, GV_ADD);
    stash_ii   = gv_stashpvn("Data::HashMap::II",   17, GV_ADD);
    stash_is   = gv_stashpvn("Data::HashMap::IS",   17, GV_ADD);
    stash_sa   = gv_stashpvn("Data::HashMap::SA",   17, GV_ADD);
    stash_si16 = gv_stashpvn("Data::HashMap::SI16", 19, GV_ADD);
    stash_si32 = gv_stashpvn("Data::HashMap::SI32", 19, GV_ADD);
    stash_si   = gv_stashpvn("Data::HashMap::SI",   17, GV_ADD);
    stash_ss   = gv_stashpvn("Data::HashMap::SS",   17, GV_ADD);
    REGISTER_KW(i16, put,      "Data::HashMap::I16::put");
    REGISTER_KW(i16, get,      "Data::HashMap::I16::get");
    REGISTER_KW(i16, remove,   "Data::HashMap::I16::remove");
    REGISTER_KW(i16, take,   "Data::HashMap::I16::take");
    REGISTER_KW(i16, drain,  "Data::HashMap::I16::drain");
    REGISTER_KW(i16, pop,    "Data::HashMap::I16::pop");
    REGISTER_KW(i16, shift,  "Data::HashMap::I16::shift");
    REGISTER_KW(i16, reserve, "Data::HashMap::I16::reserve");
    REGISTER_KW(i16, purge,   "Data::HashMap::I16::purge");
    REGISTER_KW(i16, capacity, "Data::HashMap::I16::capacity");
    REGISTER_KW(i16, persist,  "Data::HashMap::I16::persist");
    REGISTER_KW(i16, swap,    "Data::HashMap::I16::swap");
    REGISTER_KW(i16, cas,     "Data::HashMap::I16::cas");
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
    REGISTER_KW(i16, lru_skip, "Data::HashMap::I16::lru_skip");
    REGISTER_KW(i16, each,       "Data::HashMap::I16::each");
    REGISTER_KW(i16, iter_reset, "Data::HashMap::I16::iter_reset");
    REGISTER_KW(i16, clear,      "Data::HashMap::I16::clear");
    REGISTER_KW(i16, to_hash,    "Data::HashMap::I16::to_hash");
    REGISTER_KW(i16, put_ttl,    "Data::HashMap::I16::put_ttl");
    REGISTER_KW(i16, get_or_set, "Data::HashMap::I16::get_or_set");
    REGISTER_KW(i16s, put,      "Data::HashMap::I16S::put");
    REGISTER_KW(i16s, get,      "Data::HashMap::I16S::get");
    REGISTER_KW(i16s, remove,   "Data::HashMap::I16S::remove");
    REGISTER_KW(i16s, take,   "Data::HashMap::I16S::take");
    REGISTER_KW(i16s, drain,  "Data::HashMap::I16S::drain");
    REGISTER_KW(i16s, pop,    "Data::HashMap::I16S::pop");
    REGISTER_KW(i16s, shift,  "Data::HashMap::I16S::shift");
    REGISTER_KW(i16s, reserve, "Data::HashMap::I16S::reserve");
    REGISTER_KW(i16s, purge,   "Data::HashMap::I16S::purge");
    REGISTER_KW(i16s, capacity, "Data::HashMap::I16S::capacity");
    REGISTER_KW(i16s, persist,  "Data::HashMap::I16S::persist");
    REGISTER_KW(i16s, swap,    "Data::HashMap::I16S::swap");
    REGISTER_KW(i16s, exists,   "Data::HashMap::I16S::exists");
    REGISTER_KW(i16s, size,     "Data::HashMap::I16S::size");
    REGISTER_KW(i16s, keys,     "Data::HashMap::I16S::keys");
    REGISTER_KW(i16s, values,   "Data::HashMap::I16S::values");
    REGISTER_KW(i16s, items,    "Data::HashMap::I16S::items");
    REGISTER_KW(i16s, max_size, "Data::HashMap::I16S::max_size");
    REGISTER_KW(i16s, ttl,      "Data::HashMap::I16S::ttl");
    REGISTER_KW(i16s, lru_skip, "Data::HashMap::I16S::lru_skip");
    REGISTER_KW(i16s, each,       "Data::HashMap::I16S::each");
    REGISTER_KW(i16s, iter_reset, "Data::HashMap::I16S::iter_reset");
    REGISTER_KW(i16s, clear,      "Data::HashMap::I16S::clear");
    REGISTER_KW(i16s, to_hash,    "Data::HashMap::I16S::to_hash");
    REGISTER_KW(i16s, put_ttl,    "Data::HashMap::I16S::put_ttl");
    REGISTER_KW(i16s, get_or_set, "Data::HashMap::I16S::get_or_set");
    REGISTER_KW(i16s, get_direct, "Data::HashMap::I16S::get_direct");
    REGISTER_KW(si16, put,      "Data::HashMap::SI16::put");
    REGISTER_KW(si16, get,      "Data::HashMap::SI16::get");
    REGISTER_KW(si16, remove,   "Data::HashMap::SI16::remove");
    REGISTER_KW(si16, take,   "Data::HashMap::SI16::take");
    REGISTER_KW(si16, drain,  "Data::HashMap::SI16::drain");
    REGISTER_KW(si16, pop,    "Data::HashMap::SI16::pop");
    REGISTER_KW(si16, shift,  "Data::HashMap::SI16::shift");
    REGISTER_KW(si16, reserve, "Data::HashMap::SI16::reserve");
    REGISTER_KW(si16, purge,   "Data::HashMap::SI16::purge");
    REGISTER_KW(si16, capacity, "Data::HashMap::SI16::capacity");
    REGISTER_KW(si16, persist,  "Data::HashMap::SI16::persist");
    REGISTER_KW(si16, swap,    "Data::HashMap::SI16::swap");
    REGISTER_KW(si16, cas,     "Data::HashMap::SI16::cas");
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
    REGISTER_KW(si16, lru_skip, "Data::HashMap::SI16::lru_skip");
    REGISTER_KW(si16, each,       "Data::HashMap::SI16::each");
    REGISTER_KW(si16, iter_reset, "Data::HashMap::SI16::iter_reset");
    REGISTER_KW(si16, clear,      "Data::HashMap::SI16::clear");
    REGISTER_KW(si16, to_hash,    "Data::HashMap::SI16::to_hash");
    REGISTER_KW(si16, put_ttl,    "Data::HashMap::SI16::put_ttl");
    REGISTER_KW(si16, get_or_set, "Data::HashMap::SI16::get_or_set");
    REGISTER_KW(i32, put,      "Data::HashMap::I32::put");
    REGISTER_KW(i32, get,      "Data::HashMap::I32::get");
    REGISTER_KW(i32, remove,   "Data::HashMap::I32::remove");
    REGISTER_KW(i32, take,   "Data::HashMap::I32::take");
    REGISTER_KW(i32, drain,  "Data::HashMap::I32::drain");
    REGISTER_KW(i32, pop,    "Data::HashMap::I32::pop");
    REGISTER_KW(i32, shift,  "Data::HashMap::I32::shift");
    REGISTER_KW(i32, reserve, "Data::HashMap::I32::reserve");
    REGISTER_KW(i32, purge,   "Data::HashMap::I32::purge");
    REGISTER_KW(i32, capacity, "Data::HashMap::I32::capacity");
    REGISTER_KW(i32, persist,  "Data::HashMap::I32::persist");
    REGISTER_KW(i32, swap,    "Data::HashMap::I32::swap");
    REGISTER_KW(i32, cas,     "Data::HashMap::I32::cas");
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
    REGISTER_KW(i32, lru_skip, "Data::HashMap::I32::lru_skip");
    REGISTER_KW(i32, each,       "Data::HashMap::I32::each");
    REGISTER_KW(i32, iter_reset, "Data::HashMap::I32::iter_reset");
    REGISTER_KW(i32, clear,      "Data::HashMap::I32::clear");
    REGISTER_KW(i32, to_hash,    "Data::HashMap::I32::to_hash");
    REGISTER_KW(i32, put_ttl,    "Data::HashMap::I32::put_ttl");
    REGISTER_KW(i32, get_or_set, "Data::HashMap::I32::get_or_set");
    REGISTER_KW(ii, put,      "Data::HashMap::II::put");
    REGISTER_KW(ii, get,      "Data::HashMap::II::get");
    REGISTER_KW(ii, remove,   "Data::HashMap::II::remove");
    REGISTER_KW(ii, take,   "Data::HashMap::II::take");
    REGISTER_KW(ii, drain,  "Data::HashMap::II::drain");
    REGISTER_KW(ii, pop,    "Data::HashMap::II::pop");
    REGISTER_KW(ii, shift,  "Data::HashMap::II::shift");
    REGISTER_KW(ii, reserve, "Data::HashMap::II::reserve");
    REGISTER_KW(ii, purge,   "Data::HashMap::II::purge");
    REGISTER_KW(ii, capacity, "Data::HashMap::II::capacity");
    REGISTER_KW(ii, persist,  "Data::HashMap::II::persist");
    REGISTER_KW(ii, swap,    "Data::HashMap::II::swap");
    REGISTER_KW(ii, cas,     "Data::HashMap::II::cas");
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
    REGISTER_KW(ii, lru_skip, "Data::HashMap::II::lru_skip");
    REGISTER_KW(ii, each,       "Data::HashMap::II::each");
    REGISTER_KW(ii, iter_reset, "Data::HashMap::II::iter_reset");
    REGISTER_KW(ii, clear,      "Data::HashMap::II::clear");
    REGISTER_KW(ii, to_hash,    "Data::HashMap::II::to_hash");
    REGISTER_KW(ii, put_ttl,    "Data::HashMap::II::put_ttl");
    REGISTER_KW(ii, get_or_set, "Data::HashMap::II::get_or_set");
    REGISTER_KW(is, put,      "Data::HashMap::IS::put");
    REGISTER_KW(is, get,      "Data::HashMap::IS::get");
    REGISTER_KW(is, remove,   "Data::HashMap::IS::remove");
    REGISTER_KW(is, take,   "Data::HashMap::IS::take");
    REGISTER_KW(is, drain,  "Data::HashMap::IS::drain");
    REGISTER_KW(is, pop,    "Data::HashMap::IS::pop");
    REGISTER_KW(is, shift,  "Data::HashMap::IS::shift");
    REGISTER_KW(is, reserve, "Data::HashMap::IS::reserve");
    REGISTER_KW(is, purge,   "Data::HashMap::IS::purge");
    REGISTER_KW(is, capacity, "Data::HashMap::IS::capacity");
    REGISTER_KW(is, persist,  "Data::HashMap::IS::persist");
    REGISTER_KW(is, swap,    "Data::HashMap::IS::swap");
    REGISTER_KW(is, exists,   "Data::HashMap::IS::exists");
    REGISTER_KW(is, size,     "Data::HashMap::IS::size");
    REGISTER_KW(is, keys,     "Data::HashMap::IS::keys");
    REGISTER_KW(is, values,   "Data::HashMap::IS::values");
    REGISTER_KW(is, items,    "Data::HashMap::IS::items");
    REGISTER_KW(is, max_size, "Data::HashMap::IS::max_size");
    REGISTER_KW(is, ttl,      "Data::HashMap::IS::ttl");
    REGISTER_KW(is, lru_skip, "Data::HashMap::IS::lru_skip");
    REGISTER_KW(is, each,       "Data::HashMap::IS::each");
    REGISTER_KW(is, iter_reset, "Data::HashMap::IS::iter_reset");
    REGISTER_KW(is, clear,      "Data::HashMap::IS::clear");
    REGISTER_KW(is, to_hash,    "Data::HashMap::IS::to_hash");
    REGISTER_KW(is, put_ttl,    "Data::HashMap::IS::put_ttl");
    REGISTER_KW(is, get_or_set, "Data::HashMap::IS::get_or_set");
    REGISTER_KW(is, get_direct, "Data::HashMap::IS::get_direct");
    REGISTER_KW(si, put,      "Data::HashMap::SI::put");
    REGISTER_KW(si, get,      "Data::HashMap::SI::get");
    REGISTER_KW(si, remove,   "Data::HashMap::SI::remove");
    REGISTER_KW(si, take,   "Data::HashMap::SI::take");
    REGISTER_KW(si, drain,  "Data::HashMap::SI::drain");
    REGISTER_KW(si, pop,    "Data::HashMap::SI::pop");
    REGISTER_KW(si, shift,  "Data::HashMap::SI::shift");
    REGISTER_KW(si, reserve, "Data::HashMap::SI::reserve");
    REGISTER_KW(si, purge,   "Data::HashMap::SI::purge");
    REGISTER_KW(si, capacity, "Data::HashMap::SI::capacity");
    REGISTER_KW(si, persist,  "Data::HashMap::SI::persist");
    REGISTER_KW(si, swap,    "Data::HashMap::SI::swap");
    REGISTER_KW(si, cas,     "Data::HashMap::SI::cas");
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
    REGISTER_KW(si, lru_skip, "Data::HashMap::SI::lru_skip");
    REGISTER_KW(si, each,       "Data::HashMap::SI::each");
    REGISTER_KW(si, iter_reset, "Data::HashMap::SI::iter_reset");
    REGISTER_KW(si, clear,      "Data::HashMap::SI::clear");
    REGISTER_KW(si, to_hash,    "Data::HashMap::SI::to_hash");
    REGISTER_KW(si, put_ttl,    "Data::HashMap::SI::put_ttl");
    REGISTER_KW(si, get_or_set, "Data::HashMap::SI::get_or_set");
    REGISTER_KW(ss, put,      "Data::HashMap::SS::put");
    REGISTER_KW(ss, get,      "Data::HashMap::SS::get");
    REGISTER_KW(ss, remove,   "Data::HashMap::SS::remove");
    REGISTER_KW(ss, take,   "Data::HashMap::SS::take");
    REGISTER_KW(ss, drain,  "Data::HashMap::SS::drain");
    REGISTER_KW(ss, pop,    "Data::HashMap::SS::pop");
    REGISTER_KW(ss, shift,  "Data::HashMap::SS::shift");
    REGISTER_KW(ss, reserve, "Data::HashMap::SS::reserve");
    REGISTER_KW(ss, purge,   "Data::HashMap::SS::purge");
    REGISTER_KW(ss, capacity, "Data::HashMap::SS::capacity");
    REGISTER_KW(ss, persist,  "Data::HashMap::SS::persist");
    REGISTER_KW(ss, swap,    "Data::HashMap::SS::swap");
    REGISTER_KW(ss, exists,   "Data::HashMap::SS::exists");
    REGISTER_KW(ss, size,     "Data::HashMap::SS::size");
    REGISTER_KW(ss, keys,     "Data::HashMap::SS::keys");
    REGISTER_KW(ss, values,   "Data::HashMap::SS::values");
    REGISTER_KW(ss, items,    "Data::HashMap::SS::items");
    REGISTER_KW(ss, max_size, "Data::HashMap::SS::max_size");
    REGISTER_KW(ss, ttl,      "Data::HashMap::SS::ttl");
    REGISTER_KW(ss, lru_skip, "Data::HashMap::SS::lru_skip");
    REGISTER_KW(ss, each,       "Data::HashMap::SS::each");
    REGISTER_KW(ss, iter_reset, "Data::HashMap::SS::iter_reset");
    REGISTER_KW(ss, clear,      "Data::HashMap::SS::clear");
    REGISTER_KW(ss, to_hash,    "Data::HashMap::SS::to_hash");
    REGISTER_KW(ss, put_ttl,    "Data::HashMap::SS::put_ttl");
    REGISTER_KW(ss, get_or_set, "Data::HashMap::SS::get_or_set");
    REGISTER_KW(ss, get_direct, "Data::HashMap::SS::get_direct");
    REGISTER_KW(i32s, put,      "Data::HashMap::I32S::put");
    REGISTER_KW(i32s, get,      "Data::HashMap::I32S::get");
    REGISTER_KW(i32s, remove,   "Data::HashMap::I32S::remove");
    REGISTER_KW(i32s, take,   "Data::HashMap::I32S::take");
    REGISTER_KW(i32s, drain,  "Data::HashMap::I32S::drain");
    REGISTER_KW(i32s, pop,    "Data::HashMap::I32S::pop");
    REGISTER_KW(i32s, shift,  "Data::HashMap::I32S::shift");
    REGISTER_KW(i32s, reserve, "Data::HashMap::I32S::reserve");
    REGISTER_KW(i32s, purge,   "Data::HashMap::I32S::purge");
    REGISTER_KW(i32s, capacity, "Data::HashMap::I32S::capacity");
    REGISTER_KW(i32s, persist,  "Data::HashMap::I32S::persist");
    REGISTER_KW(i32s, swap,    "Data::HashMap::I32S::swap");
    REGISTER_KW(i32s, exists,   "Data::HashMap::I32S::exists");
    REGISTER_KW(i32s, size,     "Data::HashMap::I32S::size");
    REGISTER_KW(i32s, keys,     "Data::HashMap::I32S::keys");
    REGISTER_KW(i32s, values,   "Data::HashMap::I32S::values");
    REGISTER_KW(i32s, items,    "Data::HashMap::I32S::items");
    REGISTER_KW(i32s, max_size, "Data::HashMap::I32S::max_size");
    REGISTER_KW(i32s, ttl,      "Data::HashMap::I32S::ttl");
    REGISTER_KW(i32s, lru_skip, "Data::HashMap::I32S::lru_skip");
    REGISTER_KW(i32s, each,       "Data::HashMap::I32S::each");
    REGISTER_KW(i32s, iter_reset, "Data::HashMap::I32S::iter_reset");
    REGISTER_KW(i32s, clear,      "Data::HashMap::I32S::clear");
    REGISTER_KW(i32s, to_hash,    "Data::HashMap::I32S::to_hash");
    REGISTER_KW(i32s, put_ttl,    "Data::HashMap::I32S::put_ttl");
    REGISTER_KW(i32s, get_or_set, "Data::HashMap::I32S::get_or_set");
    REGISTER_KW(i32s, get_direct, "Data::HashMap::I32S::get_direct");
    REGISTER_KW(si32, put,      "Data::HashMap::SI32::put");
    REGISTER_KW(si32, get,      "Data::HashMap::SI32::get");
    REGISTER_KW(si32, remove,   "Data::HashMap::SI32::remove");
    REGISTER_KW(si32, take,   "Data::HashMap::SI32::take");
    REGISTER_KW(si32, drain,  "Data::HashMap::SI32::drain");
    REGISTER_KW(si32, pop,    "Data::HashMap::SI32::pop");
    REGISTER_KW(si32, shift,  "Data::HashMap::SI32::shift");
    REGISTER_KW(si32, reserve, "Data::HashMap::SI32::reserve");
    REGISTER_KW(si32, purge,   "Data::HashMap::SI32::purge");
    REGISTER_KW(si32, capacity, "Data::HashMap::SI32::capacity");
    REGISTER_KW(si32, persist,  "Data::HashMap::SI32::persist");
    REGISTER_KW(si32, swap,    "Data::HashMap::SI32::swap");
    REGISTER_KW(si32, cas,     "Data::HashMap::SI32::cas");
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
    REGISTER_KW(si32, lru_skip, "Data::HashMap::SI32::lru_skip");
    REGISTER_KW(si32, each,       "Data::HashMap::SI32::each");
    REGISTER_KW(si32, iter_reset, "Data::HashMap::SI32::iter_reset");
    REGISTER_KW(si32, clear,      "Data::HashMap::SI32::clear");
    REGISTER_KW(si32, to_hash,    "Data::HashMap::SI32::to_hash");
    REGISTER_KW(si32, put_ttl,    "Data::HashMap::SI32::put_ttl");
    REGISTER_KW(si32, get_or_set, "Data::HashMap::SI32::get_or_set");
    REGISTER_KW(i32a, put,      "Data::HashMap::I32A::put");
    REGISTER_KW(i32a, get,      "Data::HashMap::I32A::get");
    REGISTER_KW(i32a, remove,   "Data::HashMap::I32A::remove");
    REGISTER_KW(i32a, take,   "Data::HashMap::I32A::take");
    REGISTER_KW(i32a, drain,  "Data::HashMap::I32A::drain");
    REGISTER_KW(i32a, pop,    "Data::HashMap::I32A::pop");
    REGISTER_KW(i32a, shift,  "Data::HashMap::I32A::shift");
    REGISTER_KW(i32a, reserve, "Data::HashMap::I32A::reserve");
    REGISTER_KW(i32a, purge,   "Data::HashMap::I32A::purge");
    REGISTER_KW(i32a, capacity, "Data::HashMap::I32A::capacity");
    REGISTER_KW(i32a, persist,  "Data::HashMap::I32A::persist");
    REGISTER_KW(i32a, swap,    "Data::HashMap::I32A::swap");
    REGISTER_KW(i32a, exists,   "Data::HashMap::I32A::exists");
    REGISTER_KW(i32a, size,     "Data::HashMap::I32A::size");
    REGISTER_KW(i32a, keys,     "Data::HashMap::I32A::keys");
    REGISTER_KW(i32a, values,   "Data::HashMap::I32A::values");
    REGISTER_KW(i32a, items,    "Data::HashMap::I32A::items");
    REGISTER_KW(i32a, max_size, "Data::HashMap::I32A::max_size");
    REGISTER_KW(i32a, ttl,      "Data::HashMap::I32A::ttl");
    REGISTER_KW(i32a, lru_skip, "Data::HashMap::I32A::lru_skip");
    REGISTER_KW(i32a, each,       "Data::HashMap::I32A::each");
    REGISTER_KW(i32a, iter_reset, "Data::HashMap::I32A::iter_reset");
    REGISTER_KW(i32a, clear,      "Data::HashMap::I32A::clear");
    REGISTER_KW(i32a, to_hash,    "Data::HashMap::I32A::to_hash");
    REGISTER_KW(i32a, put_ttl,    "Data::HashMap::I32A::put_ttl");
    REGISTER_KW(i32a, get_or_set, "Data::HashMap::I32A::get_or_set");
    REGISTER_KW(i16a, put,      "Data::HashMap::I16A::put");
    REGISTER_KW(i16a, get,      "Data::HashMap::I16A::get");
    REGISTER_KW(i16a, remove,   "Data::HashMap::I16A::remove");
    REGISTER_KW(i16a, take,   "Data::HashMap::I16A::take");
    REGISTER_KW(i16a, drain,  "Data::HashMap::I16A::drain");
    REGISTER_KW(i16a, pop,    "Data::HashMap::I16A::pop");
    REGISTER_KW(i16a, shift,  "Data::HashMap::I16A::shift");
    REGISTER_KW(i16a, reserve, "Data::HashMap::I16A::reserve");
    REGISTER_KW(i16a, purge,   "Data::HashMap::I16A::purge");
    REGISTER_KW(i16a, capacity, "Data::HashMap::I16A::capacity");
    REGISTER_KW(i16a, persist,  "Data::HashMap::I16A::persist");
    REGISTER_KW(i16a, swap,    "Data::HashMap::I16A::swap");
    REGISTER_KW(i16a, exists,   "Data::HashMap::I16A::exists");
    REGISTER_KW(i16a, size,     "Data::HashMap::I16A::size");
    REGISTER_KW(i16a, keys,     "Data::HashMap::I16A::keys");
    REGISTER_KW(i16a, values,   "Data::HashMap::I16A::values");
    REGISTER_KW(i16a, items,    "Data::HashMap::I16A::items");
    REGISTER_KW(i16a, max_size, "Data::HashMap::I16A::max_size");
    REGISTER_KW(i16a, ttl,      "Data::HashMap::I16A::ttl");
    REGISTER_KW(i16a, lru_skip, "Data::HashMap::I16A::lru_skip");
    REGISTER_KW(i16a, each,       "Data::HashMap::I16A::each");
    REGISTER_KW(i16a, iter_reset, "Data::HashMap::I16A::iter_reset");
    REGISTER_KW(i16a, clear,      "Data::HashMap::I16A::clear");
    REGISTER_KW(i16a, to_hash,    "Data::HashMap::I16A::to_hash");
    REGISTER_KW(i16a, put_ttl,    "Data::HashMap::I16A::put_ttl");
    REGISTER_KW(i16a, get_or_set, "Data::HashMap::I16A::get_or_set");
    REGISTER_KW(ia, put,      "Data::HashMap::IA::put");
    REGISTER_KW(ia, get,      "Data::HashMap::IA::get");
    REGISTER_KW(ia, remove,   "Data::HashMap::IA::remove");
    REGISTER_KW(ia, take,   "Data::HashMap::IA::take");
    REGISTER_KW(ia, drain,  "Data::HashMap::IA::drain");
    REGISTER_KW(ia, pop,    "Data::HashMap::IA::pop");
    REGISTER_KW(ia, shift,  "Data::HashMap::IA::shift");
    REGISTER_KW(ia, reserve, "Data::HashMap::IA::reserve");
    REGISTER_KW(ia, purge,   "Data::HashMap::IA::purge");
    REGISTER_KW(ia, capacity, "Data::HashMap::IA::capacity");
    REGISTER_KW(ia, persist,  "Data::HashMap::IA::persist");
    REGISTER_KW(ia, swap,    "Data::HashMap::IA::swap");
    REGISTER_KW(ia, exists,   "Data::HashMap::IA::exists");
    REGISTER_KW(ia, size,     "Data::HashMap::IA::size");
    REGISTER_KW(ia, keys,     "Data::HashMap::IA::keys");
    REGISTER_KW(ia, values,   "Data::HashMap::IA::values");
    REGISTER_KW(ia, items,    "Data::HashMap::IA::items");
    REGISTER_KW(ia, max_size, "Data::HashMap::IA::max_size");
    REGISTER_KW(ia, ttl,      "Data::HashMap::IA::ttl");
    REGISTER_KW(ia, lru_skip, "Data::HashMap::IA::lru_skip");
    REGISTER_KW(ia, each,       "Data::HashMap::IA::each");
    REGISTER_KW(ia, iter_reset, "Data::HashMap::IA::iter_reset");
    REGISTER_KW(ia, clear,      "Data::HashMap::IA::clear");
    REGISTER_KW(ia, to_hash,    "Data::HashMap::IA::to_hash");
    REGISTER_KW(ia, put_ttl,    "Data::HashMap::IA::put_ttl");
    REGISTER_KW(ia, get_or_set, "Data::HashMap::IA::get_or_set");
    REGISTER_KW(sa, put,      "Data::HashMap::SA::put");
    REGISTER_KW(sa, get,      "Data::HashMap::SA::get");
    REGISTER_KW(sa, remove,   "Data::HashMap::SA::remove");
    REGISTER_KW(sa, take,   "Data::HashMap::SA::take");
    REGISTER_KW(sa, drain,  "Data::HashMap::SA::drain");
    REGISTER_KW(sa, pop,    "Data::HashMap::SA::pop");
    REGISTER_KW(sa, shift,  "Data::HashMap::SA::shift");
    REGISTER_KW(sa, reserve, "Data::HashMap::SA::reserve");
    REGISTER_KW(sa, purge,   "Data::HashMap::SA::purge");
    REGISTER_KW(sa, capacity, "Data::HashMap::SA::capacity");
    REGISTER_KW(sa, persist,  "Data::HashMap::SA::persist");
    REGISTER_KW(sa, swap,    "Data::HashMap::SA::swap");
    REGISTER_KW(sa, exists,   "Data::HashMap::SA::exists");
    REGISTER_KW(sa, size,     "Data::HashMap::SA::size");
    REGISTER_KW(sa, keys,     "Data::HashMap::SA::keys");
    REGISTER_KW(sa, values,   "Data::HashMap::SA::values");
    REGISTER_KW(sa, items,    "Data::HashMap::SA::items");
    REGISTER_KW(sa, max_size, "Data::HashMap::SA::max_size");
    REGISTER_KW(sa, ttl,      "Data::HashMap::SA::ttl");
    REGISTER_KW(sa, lru_skip, "Data::HashMap::SA::lru_skip");
    REGISTER_KW(sa, each,       "Data::HashMap::SA::each");
    REGISTER_KW(sa, iter_reset, "Data::HashMap::SA::iter_reset");
    REGISTER_KW(sa, clear,      "Data::HashMap::SA::clear");
    REGISTER_KW(sa, to_hash,    "Data::HashMap::SA::to_hash");
    REGISTER_KW(sa, put_ttl,    "Data::HashMap::SA::put_ttl");
    REGISTER_KW(sa, get_or_set, "Data::HashMap::SA::get_or_set");



INCLUDE: xs/i32.xsi

INCLUDE: xs/ii.xsi

INCLUDE: xs/is.xsi

INCLUDE: xs/si.xsi

INCLUDE: xs/ss.xsi

INCLUDE: xs/i32s.xsi

INCLUDE: xs/si32.xsi

INCLUDE: xs/i16.xsi

INCLUDE: xs/i16s.xsi

INCLUDE: xs/si16.xsi

INCLUDE: xs/i32a.xsi

INCLUDE: xs/i16a.xsi

INCLUDE: xs/ia.xsi

INCLUDE: xs/sa.xsi
