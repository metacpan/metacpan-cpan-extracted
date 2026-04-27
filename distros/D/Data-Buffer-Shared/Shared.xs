#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "buf_i8.h"
#include "buf_u8.h"
#include "buf_i16.h"
#include "buf_u16.h"
#include "buf_i32.h"
#include "buf_u32.h"
#include "buf_i64.h"
#include "buf_u64.h"
#include "buf_f32.h"
#include "buf_f64.h"
#include "buf_str.h"

#include "XSParseKeyword.h"

/* ---- as_scalar magic: prevent use-after-free by preventing buffer DESTROY
 * while the returned scalar ref is alive. We attach magic to the inner SV
 * that holds a reference to the buffer object. When the inner SV is freed,
 * the magic destructor releases the reference. ---- */

static int buf_scalar_magic_free(pTHX_ SV *sv, MAGIC *mg) {
    PERL_UNUSED_ARG(sv);
    if (mg->mg_obj) SvREFCNT_dec(mg->mg_obj);
    return 0;
}

static const MGVTBL buf_scalar_magic_vtbl = {
    NULL, NULL, NULL, NULL, buf_scalar_magic_free, NULL, NULL, NULL
};

/* ---- Helper macros ---- */

#define EXTRACT_BUF(classname, sv) \
    if (!sv_isobject(sv) || !sv_derived_from(sv, classname)) \
        croak("Expected a %s object", classname); \
    BufHandle* h = INT2PTR(BufHandle*, SvIV(SvRV(sv))); \
    if (!h) croak("Attempted to use a destroyed %s object", classname)

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
    OP *a1 = args[1]->op;
    OP *a2 = args[2]->op;
    OP *a3 = args[3]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, map_op, a1);
    arglist = op_append_elem(OP_LIST, arglist, a2);
    arglist = op_append_elem(OP_LIST, arglist, a3);
    arglist = op_append_elem(OP_LIST, arglist, cvref);
    *out = op_convert_list(OP_ENTERSUB, OPf_STACKED, arglist);
    return KEYWORD_PLUGIN_EXPR;
}

static int build_kw_3arg_list(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata) {
    (void)nargs;
    const char *func = (const char *)hookdata;
    OP *map_op = args[0]->op;
    OP *a1 = args[1]->op;
    OP *a2 = args[2]->op;
    OP *cvref = newCVREF(0, newGVOP(OP_GV, 0, gv_fetchpv(func, GV_ADD, SVt_PVCV)));
    OP *arglist = op_append_elem(OP_LIST, map_op, a1);
    arglist = op_append_elem(OP_LIST, arglist, a2);
    arglist = op_append_elem(OP_LIST, arglist, cvref);
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
    static const struct XSParseKeywordHooks hooks_buf_##variant##_##kw = { \
        .flags = XPK_FLAG_EXPR, \
        .permit_hintkey = "Data::Buffer::Shared::" PKG "/buf_" #variant "_" #kw, \
        .pieces = pieces_##nargs##expr, \
        .build = builder, \
    };

#define REGISTER_KW(variant, kw, funcname) \
    register_xs_parse_keyword("buf_" #variant "_" #kw, \
        &hooks_buf_##variant##_##kw, (void*)(funcname))

/* Integer variant keywords (set_slice is method-only due to variadic args) */
#define DEFINE_INT_KW_HOOKS(variant, PKG) \
    DEFINE_KW_HOOK(variant, PKG, get,       2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, set,       3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, slice,     3, build_kw_3arg_list) \
    DEFINE_KW_HOOK(variant, PKG, fill,      2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, incr,      2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, decr,      2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, add,       3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, cas,       4, build_kw_4arg) \
    DEFINE_KW_HOOK(variant, PKG, capacity,  1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, mmap_size, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, elem_size, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, lock_wr,   1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, unlock_wr, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, lock_rd,   1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, unlock_rd, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, ptr,        1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, ptr_at,     2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, clear,      1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, get_raw,    3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, set_raw,    3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, cmpxchg,    4, build_kw_4arg) \
    DEFINE_KW_HOOK(variant, PKG, atomic_and, 3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, atomic_or,  3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, atomic_xor, 3, build_kw_3arg)

/* Float variants: no incr/decr/add/cas/cmpxchg/bitwise */
#define DEFINE_FLOAT_KW_HOOKS(variant, PKG) \
    DEFINE_KW_HOOK(variant, PKG, get,       2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, set,       3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, slice,     3, build_kw_3arg_list) \
    DEFINE_KW_HOOK(variant, PKG, fill,      2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, capacity,  1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, mmap_size, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, elem_size, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, lock_wr,   1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, unlock_wr, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, lock_rd,   1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, unlock_rd, 1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, ptr,       1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, ptr_at,    2, build_kw_2arg) \
    DEFINE_KW_HOOK(variant, PKG, clear,     1, build_kw_1arg) \
    DEFINE_KW_HOOK(variant, PKG, get_raw,   3, build_kw_3arg) \
    DEFINE_KW_HOOK(variant, PKG, set_raw,   3, build_kw_3arg)

DEFINE_INT_KW_HOOKS(i8,  "I8")
DEFINE_INT_KW_HOOKS(u8,  "U8")
DEFINE_INT_KW_HOOKS(i16, "I16")
DEFINE_INT_KW_HOOKS(u16, "U16")
DEFINE_INT_KW_HOOKS(i32, "I32")
DEFINE_INT_KW_HOOKS(u32, "U32")
DEFINE_INT_KW_HOOKS(i64, "I64")
DEFINE_INT_KW_HOOKS(u64, "U64")

DEFINE_FLOAT_KW_HOOKS(f32, "F32")
DEFINE_FLOAT_KW_HOOKS(f64, "F64")

/* Str variant: same as float (no counters) but set takes string */
DEFINE_FLOAT_KW_HOOKS(str, "Str")

/* ---- Registration macros ---- */

#define REGISTER_INT_KWS(variant, PKG) \
    REGISTER_KW(variant, get,       PKG "::get"); \
    REGISTER_KW(variant, set,       PKG "::set"); \
    REGISTER_KW(variant, slice,     PKG "::slice"); \
    REGISTER_KW(variant, fill,      PKG "::fill"); \
    REGISTER_KW(variant, incr,      PKG "::incr"); \
    REGISTER_KW(variant, decr,      PKG "::decr"); \
    REGISTER_KW(variant, add,       PKG "::add"); \
    REGISTER_KW(variant, cas,       PKG "::cas"); \
    REGISTER_KW(variant, capacity,  PKG "::capacity"); \
    REGISTER_KW(variant, mmap_size, PKG "::mmap_size"); \
    REGISTER_KW(variant, elem_size, PKG "::elem_size"); \
    REGISTER_KW(variant, lock_wr,   PKG "::lock_wr"); \
    REGISTER_KW(variant, unlock_wr, PKG "::unlock_wr"); \
    REGISTER_KW(variant, lock_rd,   PKG "::lock_rd"); \
    REGISTER_KW(variant, unlock_rd, PKG "::unlock_rd"); \
    REGISTER_KW(variant, ptr,        PKG "::ptr"); \
    REGISTER_KW(variant, ptr_at,     PKG "::ptr_at"); \
    REGISTER_KW(variant, clear,      PKG "::clear"); \
    REGISTER_KW(variant, get_raw,    PKG "::get_raw"); \
    REGISTER_KW(variant, set_raw,    PKG "::set_raw"); \
    REGISTER_KW(variant, cmpxchg,    PKG "::cmpxchg"); \
    REGISTER_KW(variant, atomic_and, PKG "::atomic_and"); \
    REGISTER_KW(variant, atomic_or,  PKG "::atomic_or"); \
    REGISTER_KW(variant, atomic_xor, PKG "::atomic_xor");

#define REGISTER_FLOAT_KWS(variant, PKG) \
    REGISTER_KW(variant, get,       PKG "::get"); \
    REGISTER_KW(variant, set,       PKG "::set"); \
    REGISTER_KW(variant, slice,     PKG "::slice"); \
    REGISTER_KW(variant, fill,      PKG "::fill"); \
    REGISTER_KW(variant, capacity,  PKG "::capacity"); \
    REGISTER_KW(variant, mmap_size, PKG "::mmap_size"); \
    REGISTER_KW(variant, elem_size, PKG "::elem_size"); \
    REGISTER_KW(variant, lock_wr,   PKG "::lock_wr"); \
    REGISTER_KW(variant, unlock_wr, PKG "::unlock_wr"); \
    REGISTER_KW(variant, lock_rd,   PKG "::lock_rd"); \
    REGISTER_KW(variant, unlock_rd, PKG "::unlock_rd"); \
    REGISTER_KW(variant, ptr,       PKG "::ptr"); \
    REGISTER_KW(variant, ptr_at,    PKG "::ptr_at"); \
    REGISTER_KW(variant, clear,     PKG "::clear"); \
    REGISTER_KW(variant, get_raw,   PKG "::get_raw"); \
    REGISTER_KW(variant, set_raw,   PKG "::set_raw");

MODULE = Data::Buffer::Shared    PACKAGE = Data::Buffer::Shared::I8
PROTOTYPES: DISABLE

BOOT:
    boot_xs_parse_keyword(0.40);
    REGISTER_INT_KWS(i8,  "Data::Buffer::Shared::I8")
    REGISTER_INT_KWS(u8,  "Data::Buffer::Shared::U8")
    REGISTER_INT_KWS(i16, "Data::Buffer::Shared::I16")
    REGISTER_INT_KWS(u16, "Data::Buffer::Shared::U16")
    REGISTER_INT_KWS(i32, "Data::Buffer::Shared::I32")
    REGISTER_INT_KWS(u32, "Data::Buffer::Shared::U32")
    REGISTER_INT_KWS(i64, "Data::Buffer::Shared::I64")
    REGISTER_INT_KWS(u64, "Data::Buffer::Shared::U64")
    REGISTER_FLOAT_KWS(f32, "Data::Buffer::Shared::F32")
    REGISTER_FLOAT_KWS(f64, "Data::Buffer::Shared::F64")
    REGISTER_FLOAT_KWS(str, "Data::Buffer::Shared::Str")

INCLUDE: xs/i8.xs
INCLUDE: xs/u8.xs
INCLUDE: xs/i16.xs
INCLUDE: xs/u16.xs
INCLUDE: xs/i32.xs
INCLUDE: xs/u32.xs
INCLUDE: xs/i64.xs
INCLUDE: xs/u64.xs
INCLUDE: xs/f32.xs
INCLUDE: xs/f64.xs
INCLUDE: xs/str.xs
