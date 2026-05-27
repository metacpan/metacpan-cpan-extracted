#ifndef CHE_TYPES_H
#define CHE_TYPES_H

#include <stdint.h>

/* Type codes - matched 1:1 with the wire types ClickHouse Native
 * understands. New types append at the end so existing decoders that
 * key off the numeric value stay stable. */
enum {
    T_INT8, T_INT16, T_INT32, T_INT64,
    T_UINT8, T_UINT16, T_UINT32, T_UINT64,
    T_FLOAT32, T_FLOAT64, T_BFLOAT16,
    T_STRING, T_FIXEDSTRING,
    T_ARRAY, T_TUPLE, T_NULLABLE,
    T_ENUM8, T_ENUM16,
    T_DECIMAL32, T_DECIMAL64, T_DECIMAL128, T_DECIMAL256,
    T_DATE, T_DATE32, T_DATETIME, T_DATETIME64,
    T_BOOL, T_UUID, T_IPV4, T_IPV6,
    T_MAP, T_LOWCARDINALITY, T_VARIANT,
    T_JSON, T_DYNAMIC
};

typedef struct EnumEntry EnumEntry;
struct EnumEntry {
    char *name;
    STRLEN name_len;
    int16_t value;
};

typedef struct TypeInfo TypeInfo;
struct TypeInfo {
    int code;
    int param;             /* FixedString(N), DateTime64 precision, Decimal scale */
    TypeInfo *inner;       /* Array, Nullable */
    TypeInfo **tuple;      /* Tuple */
    int tuple_len;
    EnumEntry *enum_entries;
    int enum_count;
    HV *enum_lookup;       /* name -> value, for O(1) string lookup */
    /* Variant only: ClickHouse stores sub-columns and discriminators in
     * alphabetical order of variant type names, not declaration order.
     * variant_decl_to_wire[d] = wire idx of declared variant d.
     * variant_wire_to_decl[w] = decl idx of variant at wire pos w. */
    int *variant_decl_to_wire;
    int *variant_wire_to_decl;
    /* Named-Tuple element names (NULL for unnamed tuples). When the
     * declaration is `Tuple(a Int32, b String)` we record "a","b" here
     * so encode_column can accept either an arrayref [1,"x"] or a
     * hashref {a=>1, b=>"x"}. tuple_names[i] is NUL-terminated. */
    char **tuple_names;
};

/* Recursively free a TypeInfo tree (including any owned strings, AVs,
 * enum lookup HV, etc.). NULL-safe. */
void free_typeinfo(pTHX_ TypeInfo *t);

/* Parse a ClickHouse type expression ("Array(Tuple(Int32, String))",
 * "JSON(a Int32, b String)", etc.) into a freshly allocated TypeInfo.
 * Croaks on malformed input. Caller owns the result and must call
 * free_typeinfo() on it. */
TypeInfo* parse_type(pTHX_ const char *type, STRLEN len);

#endif
