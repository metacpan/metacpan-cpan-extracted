#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>

#include "json_kind.h"

const int json_kind_to_lex_pos[JV_KIND_COUNT] = {
    /* JV_ARRAY_BOOL    */ 0,
    /* JV_ARRAY_FLOAT64 */ 1,
    /* JV_ARRAY_INT64   */ 2,
    /* JV_ARRAY_STRING  */ 3,
    /* JV_BOOL          */ 4,
    /* JV_FLOAT64       */ 5,
    /* JV_INT64         */ 6,
    /* JV_STRING        */ 8
};

const char * const json_kind_type_name[JV_KIND_COUNT] = {
    "Array(Bool)", "Array(Float64)", "Array(Int64)", "Array(String)",
    "Bool", "Float64", "Int64", "String"
};

int json_build_lex_table(unsigned mask, int slots[JSON_LEX_SLOTS]) {
    int n = 0, lex;
    for (lex = 0; lex < JSON_LEX_SLOTS; lex++) {
        if (lex == JSON_SHAREDVARIANT_LEX_POS) { slots[n++] = -1; continue; }
        int k;
        for (k = 0; k < JV_KIND_COUNT; k++) {
            if (json_kind_to_lex_pos[k] == lex && (mask & (1u << k))) {
                slots[n++] = k;
                break;
            }
        }
    }
    return n;
}

int json_kind_disc_in(int kind, const int slots[JSON_LEX_SLOTS], int n) {
    int i;
    for (i = 0; i < n; i++) if (slots[i] == kind) return i;
    return -1;  /* unreachable when kind is in mask */
}

int json_kind_from_type_name(const char *ts, STRLEN tl) {
    if (tl == 4  && memcmp(ts, "Bool",            4)  == 0) return JV_BOOL;
    if (tl == 7  && memcmp(ts, "Float64",         7)  == 0) return JV_FLOAT64;
    if (tl == 5  && memcmp(ts, "Int64",           5)  == 0) return JV_INT64;
    if (tl == 6  && memcmp(ts, "String",          6)  == 0) return JV_STRING;
    if (tl == 11 && memcmp(ts, "Array(Bool)",     11) == 0) return JV_ARRAY_BOOL;
    if (tl == 14 && memcmp(ts, "Array(Float64)",  14) == 0) return JV_ARRAY_FLOAT64;
    if (tl == 12 && memcmp(ts, "Array(Int64)",    12) == 0) return JV_ARRAY_INT64;
    if (tl == 13 && memcmp(ts, "Array(String)",   13) == 0) return JV_ARRAY_STRING;
    return -1;
}
