#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include "types.h"

void free_typeinfo(pTHX_ TypeInfo *t) {
    if (!t) return;
    if (t->inner) free_typeinfo(aTHX_ t->inner);
    if (t->tuple) {
        int i;
        for (i = 0; i < t->tuple_len; i++) free_typeinfo(aTHX_ t->tuple[i]);
        Safefree(t->tuple);
    }
    if (t->enum_entries) {
        int i;
        for (i = 0; i < t->enum_count; i++) Safefree(t->enum_entries[i].name);
        Safefree(t->enum_entries);
    }
    if (t->enum_lookup) SvREFCNT_dec((SV*)t->enum_lookup);
    if (t->variant_decl_to_wire) Safefree(t->variant_decl_to_wire);
    if (t->variant_wire_to_decl) Safefree(t->variant_wire_to_decl);
    if (t->tuple_names) {
        int i;
        for (i = 0; i < t->tuple_len; i++)
            if (t->tuple_names[i]) Safefree(t->tuple_names[i]);
        Safefree(t->tuple_names);
    }
    Safefree(t);
}

static void parse_enum_entries(pTHX_ TypeInfo *t, const char *s, STRLEN len, int code) {
    int cap = 0;
    long min_val = (code == T_ENUM8) ? -128 : -32768;
    long max_val = (code == T_ENUM8) ? 127 : 32767;
    t->enum_entries = NULL;
    t->enum_count = 0;
    t->enum_lookup = newHV();

    STRLEN i = 0;
    while (i < len) {
        while (i < len && (s[i] == ' ' || s[i] == ',')) i++;
        if (i >= len) break;

        if (s[i] != '\'')
            croak("Invalid enum format: expected single quote at position %d", (int)i);
        i++;

        /* Scan the name and unescape backslash-escapes (\\, \') so the
         * stored name matches the unescaped form ClickHouse emits in
         * describe table output and that the user passes to encode(). */
        STRLEN name_start = i;
        STRLEN name_raw_len = 0;  /* raw bytes consumed (incl. backslashes) */
        while (i < len && s[i] != '\'') {
            if (s[i] == '\\' && i + 1 < len) { i++; name_raw_len++; }
            i++; name_raw_len++;
        }
        if (i >= len)
            croak("Invalid enum format: unterminated quote");

        /* Build the unescaped name into a freshly-allocated buffer. The
         * unescaped length is at most name_raw_len; allocate that bound. */
        char *name_buf;
        Newx(name_buf, name_raw_len + 1, char);
        STRLEN name_len = 0;
        STRLEN j = name_start;
        while (j < i) {
            if (s[j] == '\\' && j + 1 < i) j++;
            name_buf[name_len++] = s[j++];
        }
        name_buf[name_len] = 0;
        if (name_len == 0) {
            Safefree(name_buf);
            croak("Invalid enum format: empty name at position %d", (int)name_start);
        }
        i++;  /* closing quote */

        while (i < len && (s[i] == ' ' || s[i] == '=')) i++;

        int neg = 0;
        if (i < len && s[i] == '-') { neg = 1; i++; }
        if (i >= len || s[i] < '0' || s[i] > '9') {
            Safefree(name_buf);
            croak("Invalid enum format: expected digit at position %d", (int)i);
        }
        long val = 0;
        while (i < len && s[i] >= '0' && s[i] <= '9') {
            val = val * 10 + (s[i] - '0');
            i++;
        }
        if (neg) val = -val;
        if (val < min_val || val > max_val) {
            Safefree(name_buf);
            croak("Enum value %ld out of range for %s",
                  val, code == T_ENUM8 ? "Enum8" : "Enum16");
        }

        if (t->enum_count >= cap) {
            cap = cap ? cap * 2 : 8;
            Renew(t->enum_entries, cap, EnumEntry);
        }
        t->enum_entries[t->enum_count].name     = name_buf;
        t->enum_entries[t->enum_count].name_len = name_len;
        t->enum_entries[t->enum_count].value    = (int16_t)val;
        t->enum_count++;

        hv_store(t->enum_lookup, name_buf, name_len, newSViv(val), 0);
    }
}

/* Heap-allocated cleanup slot for a TypeInfo*. Disarmed by setting *slot=NULL. */
static void cleanup_typeinfo_slot(pTHX_ void *p) {
    TypeInfo **slot = (TypeInfo **)p;
    if (*slot) free_typeinfo(aTHX_ *slot);
    Safefree(slot);
}

/* Cleanup for a partially-built Tuple types array. The struct owns the array
 * directly so the destructor never dereferences stack memory after a longjmp
 * out of parse_tuple_types. Disarm by setting slot->types = NULL. */
typedef struct {
    TypeInfo **types;
    int count;
} TupleSlot;

static void cleanup_tuple_slot(pTHX_ void *p) {
    TupleSlot *s = (TupleSlot *)p;
    if (s->types) {
        int i;
        for (i = 0; i < s->count; i++)
            if (s->types[i]) free_typeinfo(aTHX_ s->types[i]);
        Safefree(s->types);
    }
    Safefree(s);
}

/* Bound of one entry in a comma-separated type list, after outer-WS strip
 * and optional "field-name<ws>" prefix removal. Both Tuple/Map/Variant
 * parsing and Variant alphabetical sorting need these post-strip bounds. */
typedef struct {
    STRLEN start;       /* offset of the trimmed type expression */
    STRLEN len;         /* length of the trimmed type expression */
    STRLEN name_start;  /* offset of the field-name prefix (or 0 if absent) */
    STRLEN name_len;    /* length of the field-name prefix (0 = no name) */
} TypeBound;

/* Split a comma-separated type list at depth-0 commas, trim outer
 * whitespace, strip any leading "name<ws>" field-name prefix (Tuple
 * named-element form). When a field-name is found, name_start/name_len
 * record it so callers (e.g. T_TUPLE) can keep the names; when absent,
 * name_len is 0. bounds must have at least len+1 slots. Returns the
 * count of non-empty entries. */
static int split_type_list(const char *s, STRLEN len, TypeBound *bounds) {
    int count = 0;
    int depth = 0;
    STRLEN start = 0, i;
    #define IS_WS(c) ((c)==' '||(c)=='\t'||(c)=='\n'||(c)=='\r')
    for (i = 0; i <= len; i++) {
        char c = (i < len) ? s[i] : ',';
        if (c == '(') depth++;
        else if (c == ')') depth--;
        else if ((c == ',' && depth == 0) || i == len) {
            STRLEN tstart = start, tend = i;
            STRLEN nstart = 0, nlen = 0;
            while (tstart < tend && IS_WS(s[tstart])) tstart++;
            while (tend > tstart && IS_WS(s[tend-1])) tend--;
            if (tend > tstart) {
                STRLEN id_end = tstart;
                if (id_end < tend
                    && ((s[id_end] >= 'A' && s[id_end] <= 'Z')
                     || (s[id_end] >= 'a' && s[id_end] <= 'z')
                     ||  s[id_end] == '_')) {
                    id_end++;
                    while (id_end < tend
                        && ((s[id_end] >= 'A' && s[id_end] <= 'Z')
                         || (s[id_end] >= 'a' && s[id_end] <= 'z')
                         || (s[id_end] >= '0' && s[id_end] <= '9')
                         ||  s[id_end] == '_'))
                        id_end++;
                    if (id_end < tend && IS_WS(s[id_end])) {
                        nstart = tstart;
                        nlen   = id_end - tstart;
                        STRLEN ts = id_end;
                        while (ts < tend && IS_WS(s[ts])) ts++;
                        if (ts < tend) tstart = ts;
                    }
                }
                bounds[count].start      = tstart;
                bounds[count].len        = tend - tstart;
                bounds[count].name_start = nstart;
                bounds[count].name_len   = nlen;
                count++;
            }
            start = i + 1;
        }
    }
    #undef IS_WS
    return count;
}

/* parse_tuple_types_with_bounds: caller already split the list and wants
 * to reuse the bounds (e.g. Variant alphabetical sort). For convenience,
 * parse_tuple_types is a thin wrapper that splits internally. */
static TypeInfo** parse_tuple_types_with_bounds(pTHX_ const char *s,
                                                TypeBound *bounds,
                                                int n) {
    TupleSlot *slot;
    Newxz(slot, 1, TupleSlot);
    SAVEDESTRUCTOR_X(cleanup_tuple_slot, slot);
    if (n > 0) Newxz(slot->types, n, TypeInfo*);

    int i;
    for (i = 0; i < n; i++) {
        slot->types[i] = parse_type(aTHX_ s + bounds[i].start, bounds[i].len);
        slot->count = i + 1;
    }
    {
        TypeInfo **result = slot->types;
        slot->types = NULL;  /* Disarm: caller now owns the array. */
        return result;
    }
}

static TypeInfo** parse_tuple_types(pTHX_ const char *s, STRLEN len, int *count) {
    TypeBound *bounds;
    Newx(bounds, len + 1, TypeBound);
    SAVEFREEPV(bounds);
    *count = split_type_list(s, len, bounds);
    return parse_tuple_types_with_bounds(aTHX_ s, bounds, *count);
}

/* Return 1 if this type can be used as a JSON typed path. CH writes
 * typed paths as a regular column; types whose serialization has a
 * non-empty state-prefix stream (Variant: mode byte; LC: version +
 * flags + dict; JSON/Dynamic: their own prefix) would interleave
 * incorrectly with other paths' prefixes in the Object prefix
 * section. Composites recursively check. */
static int type_can_be_typed_path(TypeInfo *t) {
    switch (t->code) {
        case T_VARIANT:
        case T_LOWCARDINALITY:
        case T_JSON:
        case T_DYNAMIC:
            return 0;
        case T_ARRAY:
        case T_NULLABLE:
            return type_can_be_typed_path(t->inner);
        case T_TUPLE:
        case T_MAP: {
            int i;
            for (i = 0; i < t->tuple_len; i++)
                if (!type_can_be_typed_path(t->tuple[i]))
                    return 0;
            return 1;
        }
        default:
            return 1;
    }
}

/* Parse "name Type, name Type, ..." inside JSON(...). Names may include
 * dots (CH typed paths are dotted, like JSON(user.id UInt64)); type is
 * a full type expression. Stores parsed entries on t in name-sorted
 * order via tuple_names + tuple. Empty body (JSON()) is a no-op. */
static void parse_json_typed_paths(pTHX_ TypeInfo *t,
                                   const char *body, STRLEN body_len) {
    TypeBound *bounds;
    Newxz(bounds, body_len + 1, TypeBound);
    SAVEFREEPV(bounds);

    int idx = 0;
    int depth = 0;
    STRLEN start = 0, i;
    for (i = 0; i <= body_len; i++) {
        char c = (i < body_len) ? body[i] : ',';
        if      (c == '(') depth++;
        else if (c == ')') depth--;
        else if ((c == ',' && depth == 0) || i == body_len) {
            STRLEN ts = start, te = i;
            #define J_WS(c2) ((c2)==' '||(c2)=='\t'||(c2)=='\n'||(c2)=='\r')
            while (ts < te && J_WS(body[ts])) ts++;
            while (te > ts && J_WS(body[te-1])) te--;
            if (te > ts) {
                STRLEN id = ts;
                if (body[id] == '_'
                    || (body[id] >= 'A' && body[id] <= 'Z')
                    || (body[id] >= 'a' && body[id] <= 'z')) {
                    id++;
                    while (id < te
                        && (body[id] == '_' || body[id] == '.'
                         || (body[id] >= 'A' && body[id] <= 'Z')
                         || (body[id] >= 'a' && body[id] <= 'z')
                         || (body[id] >= '0' && body[id] <= '9')))
                        id++;
                }
                if (id == ts)
                    croak("JSON(...): missing path name in '%.*s'",
                          (int)(te - ts), body + ts);
                /* Reject trailing dot and consecutive dots in path names:
                 * "a.", "a..b", ".a" (the leading dot is already caught
                 * by the start-char rule). CH itself allows only well-
                 * formed dotted identifiers; mirror that. */
                if (body[id - 1] == '.')
                    croak("JSON(...): path name must not end with '.' "
                          "in '%.*s'",
                          (int)(id - ts), body + ts);
                STRLEN dk;
                for (dk = ts + 1; dk < id; dk++) {
                    if (body[dk] == '.' && body[dk - 1] == '.')
                        croak("JSON(...): path name must not contain "
                              "consecutive dots in '%.*s'",
                              (int)(id - ts), body + ts);
                }
                STRLEN ws = id;
                while (ws < te && J_WS(body[ws])) ws++;
                if (ws == id || ws == te)
                    croak("JSON(...): expected 'name Type' but got '%.*s'",
                          (int)(te - ts), body + ts);
                bounds[idx].name_start = ts;
                bounds[idx].name_len   = id - ts;
                bounds[idx].start      = ws;
                bounds[idx].len        = te - ws;
                idx++;
            }
            #undef J_WS
            start = i + 1;
        }
    }
    if (idx == 0) return;
    int n = idx;

    int j, ii;
    for (ii = 1; ii < n; ii++) {
        TypeBound key = bounds[ii];
        j = ii - 1;
        while (j >= 0) {
            STRLEN m = bounds[j].name_len < key.name_len
                     ? bounds[j].name_len : key.name_len;
            int cmp = memcmp(body + bounds[j].name_start,
                             body + key.name_start, m);
            if (cmp == 0)
                cmp = (int)bounds[j].name_len - (int)key.name_len;
            if (cmp <= 0) break;
            bounds[j+1] = bounds[j];
            j--;
        }
        bounds[j+1] = key;
    }

    for (ii = 1; ii < n; ii++) {
        if (bounds[ii].name_len == bounds[ii-1].name_len
            && memcmp(body + bounds[ii].name_start,
                      body + bounds[ii-1].name_start,
                      bounds[ii].name_len) == 0)
            croak("JSON(...): duplicate typed path name '%.*s'",
                  (int)bounds[ii].name_len, body + bounds[ii].name_start);
    }

    t->tuple_len = n;
    Newxz(t->tuple_names, n, char*);
    for (ii = 0; ii < n; ii++) {
        Newx(t->tuple_names[ii], bounds[ii].name_len + 1, char);
        memcpy(t->tuple_names[ii], body + bounds[ii].name_start,
               bounds[ii].name_len);
        t->tuple_names[ii][bounds[ii].name_len] = '\0';
    }
    t->tuple = parse_tuple_types_with_bounds(aTHX_ body, bounds, n);

    for (ii = 0; ii < n; ii++) {
        if (!type_can_be_typed_path(t->tuple[ii]))
            croak("JSON(%s ...): typed path inner type cannot include "
                  "Variant, LowCardinality, JSON, or Dynamic (those have "
                  "wire prefixes that would interleave incorrectly)",
                  t->tuple_names[ii]);
    }
}

TypeInfo* parse_type(pTHX_ const char *type, STRLEN len) {
    TypeInfo *t;
    /* Slot lives on the heap so its address is stable across the XSUB lifetime. */
    TypeInfo **slot;
    Newx(slot, 1, TypeInfo*);
    *slot = NULL;
    SAVEDESTRUCTOR_X(cleanup_typeinfo_slot, slot);
    Newxz(t, 1, TypeInfo);
    *slot = t;

    if (len == 4 && strncmp(type, "Int8", 4) == 0) {
        t->code = T_INT8;
    } else if (len == 5 && strncmp(type, "Int16", 5) == 0) {
        t->code = T_INT16;
    } else if (len == 5 && strncmp(type, "Int32", 5) == 0) {
        t->code = T_INT32;
    } else if (len == 5 && strncmp(type, "Int64", 5) == 0) {
        t->code = T_INT64;
    } else if (len == 5 && strncmp(type, "UInt8", 5) == 0) {
        t->code = T_UINT8;
    } else if (len == 6 && strncmp(type, "UInt16", 6) == 0) {
        t->code = T_UINT16;
    } else if (len == 6 && strncmp(type, "UInt32", 6) == 0) {
        t->code = T_UINT32;
    } else if (len == 6 && strncmp(type, "UInt64", 6) == 0) {
        t->code = T_UINT64;
    } else if (len == 7 && strncmp(type, "Float32", 7) == 0) {
        t->code = T_FLOAT32;
    } else if (len == 7 && strncmp(type, "Float64", 7) == 0) {
        t->code = T_FLOAT64;
    } else if (len == 8 && strncmp(type, "BFloat16", 8) == 0) {
        t->code = T_BFLOAT16;
    } else if (len == 6 && strncmp(type, "String", 6) == 0) {
        t->code = T_STRING;
    } else if (len > 12 && strncmp(type, "FixedString(", 12) == 0) {
        t->code = T_FIXEDSTRING;
        t->param = atoi(type + 12);
        if (t->param <= 0) croak("FixedString needs positive length");
    } else if (len > 6 && strncmp(type, "Array(", 6) == 0) {
        t->code = T_ARRAY;
        t->inner = parse_type(aTHX_ type + 6, len - 7);
    } else if (len > 6 && strncmp(type, "Tuple(", 6) == 0) {
        t->code = T_TUPLE;
        const char *body = type + 6;
        STRLEN body_len = len - 7;
        TypeBound *bounds;
        Newx(bounds, body_len + 1, TypeBound);
        SAVEFREEPV(bounds);
        t->tuple_len = split_type_list(body, body_len, bounds);
        t->tuple = parse_tuple_types_with_bounds(aTHX_ body, bounds, t->tuple_len);
        /* If at least one element carries a field-name, capture all of
         * them so encode_column can accept hashrefs for this tuple. A
         * mix of named and unnamed elements isn't legal in ClickHouse;
         * we accept any element having a name as "named tuple". */
        int has_names = 0;
        int j;
        for (j = 0; j < t->tuple_len; j++) {
            if (bounds[j].name_len > 0) { has_names = 1; break; }
        }
        if (has_names) {
            Newxz(t->tuple_names, t->tuple_len, char *);
            for (j = 0; j < t->tuple_len; j++) {
                if (bounds[j].name_len > 0) {
                    Newx(t->tuple_names[j], bounds[j].name_len + 1, char);
                    memcpy(t->tuple_names[j],
                           body + bounds[j].name_start, bounds[j].name_len);
                    t->tuple_names[j][bounds[j].name_len] = '\0';
                }
                /* else: leave NULL -- mixed named/unnamed not really
                 * supported; encode will croak if hashref is used. */
            }
        }
    } else if (len > 9 && strncmp(type, "Nullable(", 9) == 0) {
        if (len > 18 && strncmp(type + 9, "Nullable(", 9) == 0)
            croak("Nullable(Nullable(...)) is not allowed");
        t->code = T_NULLABLE;
        t->inner = parse_type(aTHX_ type + 9, len - 10);
    } else if (len > 6 && strncmp(type, "Enum8(", 6) == 0) {
        t->code = T_ENUM8;
        parse_enum_entries(aTHX_ t, type + 6, len - 7, T_ENUM8);
    } else if (len > 7 && strncmp(type, "Enum16(", 7) == 0) {
        t->code = T_ENUM16;
        parse_enum_entries(aTHX_ t, type + 7, len - 8, T_ENUM16);
    } else if (len > 10 && strncmp(type, "Decimal32(", 10) == 0) {
        t->code = T_DECIMAL32;
        t->param = atoi(type + 10);
        if (t->param < 0 || t->param > 9)
            croak("Decimal32 scale must be 0..9, got %d", t->param);
    } else if (len > 10 && strncmp(type, "Decimal64(", 10) == 0) {
        t->code = T_DECIMAL64;
        t->param = atoi(type + 10);
        if (t->param < 0 || t->param > 18)
            croak("Decimal64 scale must be 0..18, got %d", t->param);
    } else if (len > 11 && strncmp(type, "Decimal128(", 11) == 0) {
        t->code = T_DECIMAL128;
        t->param = atoi(type + 11);
        if (t->param < 0 || t->param > 38)
            croak("Decimal128 scale must be 0..38, got %d", t->param);
    } else if (len > 11 && strncmp(type, "Decimal256(", 11) == 0) {
        t->code = T_DECIMAL256;
        t->param = atoi(type + 11);
        if (t->param < 0 || t->param > 76)
            croak("Decimal256 scale must be 0..76, got %d", t->param);
    } else if (len > 8 && strncmp(type, "Decimal(", 8) == 0) {
        int precision = atoi(type + 8);
        const char *comma = memchr(type + 8, ',', len - 8);
        if (!comma) croak("Decimal(P, S) requires precision and scale");
        int scale = atoi(comma + 1);
        if (precision < 1 || precision > 38)
            croak("Decimal(P, S) precision must be 1..38, got %d (use Decimal256(S) explicitly for P > 38)", precision);
        if (scale < 0 || scale > precision)
            croak("Decimal scale must be 0..precision, got %d", scale);
        t->param = scale;
        if (precision <= 9) t->code = T_DECIMAL32;
        else if (precision <= 18) t->code = T_DECIMAL64;
        else t->code = T_DECIMAL128;
    } else if (len == 4 && strncmp(type, "Date", 4) == 0) {
        t->code = T_DATE;
    } else if (len == 6 && strncmp(type, "Date32", 6) == 0) {
        t->code = T_DATE32;
    } else if (len == 8 && strncmp(type, "DateTime", 8) == 0) {
        t->code = T_DATETIME;
    } else if (len > 9 && strncmp(type, "DateTime(", 9) == 0) {
        t->code = T_DATETIME;
    } else if (len > 11 && strncmp(type, "DateTime64(", 11) == 0) {
        t->code = T_DATETIME64;
        t->param = atoi(type + 11);
        if (t->param < 0 || t->param > 9)
            croak("DateTime64 precision must be 0..9, got %d", t->param);
    } else if (len == 4 && strncmp(type, "Bool", 4) == 0) {
        t->code = T_BOOL;
    } else if (len == 7 && strncmp(type, "Boolean", 7) == 0) {
        t->code = T_BOOL;
    } else if (len == 4 && strncmp(type, "UUID", 4) == 0) {
        t->code = T_UUID;
    } else if (len == 4 && strncmp(type, "IPv4", 4) == 0) {
        t->code = T_IPV4;
    } else if (len == 4 && strncmp(type, "IPv6", 4) == 0) {
        t->code = T_IPV6;
    } else if (len > 24 && strncmp(type, "SimpleAggregateFunction(", 24) == 0) {
        /* SimpleAggregateFunction(func, T) is wire-equivalent to T -- the
         * func name only affects how readers aggregate on read, not how
         * values are stored. Strip it and parse the rest as the inner type. */
        const char *body = type + 24;
        STRLEN body_len = len - 25;
        const char *comma = memchr(body, ',', body_len);
        if (!comma) croak("SimpleAggregateFunction requires (func, T)");
        STRLEN inner_off = (comma - body) + 1;
        while (inner_off < body_len && body[inner_off] == ' ') inner_off++;
        TypeInfo *inner = parse_type(aTHX_ body + inner_off, body_len - inner_off);
        /* Steal inner's contents in one shot. The outer slot still owns t; the
         * inner's slot was already disarmed before parse_type returned, so we
         * can free the now-redundant inner struct directly. */
        *t = *inner;
        Safefree(inner);
    } else if (len > 8 && strncmp(type, "Variant(", 8) == 0) {
        /* Variant(T1, T2, ...) - tagged union. Each input row is either
         * undef (NULL) or [$variant_idx, $value]. ClickHouse stores
         * Variant sub-columns and per-row discriminators in alphabetical
         * order of variant type names, not declaration order, so build
         * a permutation that maps the user's declaration index to the
         * wire (alphabetical) position. */
        t->code = T_VARIANT;
        const char *body = type + 8;
        STRLEN body_len = len - 9;

        /* Split once, then share the bounds with parse_tuple_types_with_bounds
         * (the alphabetical sort and the parsed TypeInfo entries reference
         * the same ranges). */
        TypeBound *bounds;
        Newx(bounds, body_len + 1, TypeBound);
        SAVEFREEPV(bounds);
        t->tuple_len = split_type_list(body, body_len, bounds);
        if (t->tuple_len < 1)
            croak("Variant requires at least one type argument");
        if (t->tuple_len > 254)
            croak("Variant supports at most 254 types (got %d)", t->tuple_len);
        t->tuple = parse_tuple_types_with_bounds(aTHX_ body, bounds, t->tuple_len);

        /* Sort declaration indices alphabetically by their type bytes.
         * Selection sort -- nvar is at most 254. */
        Newx(t->variant_wire_to_decl, t->tuple_len, int);
        Newx(t->variant_decl_to_wire, t->tuple_len, int);
        int j, k;
        for (j = 0; j < t->tuple_len; j++) t->variant_wire_to_decl[j] = j;
        for (j = 0; j < t->tuple_len - 1; j++) {
            int min_idx = j;
            for (k = j + 1; k < t->tuple_len; k++) {
                int a = t->variant_wire_to_decl[min_idx];
                int b = t->variant_wire_to_decl[k];
                STRLEN la = bounds[a].len, lb = bounds[b].len;
                STRLEN cmp_len = la < lb ? la : lb;
                int cmp = memcmp(body + bounds[a].start,
                                 body + bounds[b].start, cmp_len);
                if (cmp > 0 || (cmp == 0 && la > lb)) min_idx = k;
            }
            if (min_idx != j) {
                int tmp = t->variant_wire_to_decl[j];
                t->variant_wire_to_decl[j] = t->variant_wire_to_decl[min_idx];
                t->variant_wire_to_decl[min_idx] = tmp;
            }
        }
        for (j = 0; j < t->tuple_len; j++)
            t->variant_decl_to_wire[t->variant_wire_to_decl[j]] = j;
    } else if (len > 4 && strncmp(type, "Map(", 4) == 0) {
        /* Map(K, V) is wire-equivalent to Array(Tuple(K, V)). Build the
         * synthetic structure so encode_column can reuse Array+Tuple paths. */
        t->code = T_MAP;
        t->tuple = parse_tuple_types(aTHX_ type + 4, len - 5, &t->tuple_len);
        if (t->tuple_len != 2)
            croak("Map type requires exactly 2 type arguments, got %d", t->tuple_len);
    } else if (len > 7 && strncmp(type, "Nested(", 7) == 0) {
        /* On the wire, ClickHouse splits a Nested(a T1, b T2) column into
         * flat columns "<name>.a Array(T1)" and "<name>.b Array(T2)" -- this
         * encoder does not perform that expansion. Use the flat form
         * directly in your column spec. */
        croak("Nested(...) is not supported directly; declare flat columns "
              "like 'name.field' Array(T) instead (CH stores Nested that way "
              "on the wire). describe table / for_table() returns the flat form.");
    } else if (len == 7 && strncmp(type, "Dynamic", 7) == 0) {
        /* Standalone Dynamic column: same wire machinery as a single
         * JSON path's Dynamic sub-column. Each row is a scalar leaf
         * (Bool/Float64/Int64/String), an Array(T) of those, or
         * undef (NULL). Hashrefs aren't accepted here - use JSON for
         * object-shaped values. */
        t->code = T_DYNAMIC;
    } else if ((len == 4 && strncmp(type, "JSON", 4) == 0)
            || (len > 5 && strncmp(type, "JSON(", 5) == 0
                && type[len-1] == ')')
            || (len > 7 && strncmp(type, "Object(", 7) == 0)) {
        /* ClickHouse's stable JSON type (24.8+). Wire layout (V1 over
         * Native, validated byte-for-byte against the server in
         * doc/json-research/): Object structure prefix, then for each
         * path a Dynamic prefix + Variant mode byte, then per-path
         * Variant data, then a shared-data Array(Tuple(String,String))
         * trailer. The per-row schema is determined at encode time by
         * inspecting each value's Perl type. The JSON(name Type, ...)
         * form pins specific paths to concrete inner types; those
         * paths skip the Dynamic+Variant wrapping. */
        t->code = T_JSON;
        if (len > 5 && type[4] == '(') {
            parse_json_typed_paths(aTHX_ t, type + 5, len - 6);
        }
    } else if (len == 5 && strncmp(type, "Point", 5) == 0) {
        /* Point = Tuple(Float64, Float64) */
        t->code = T_TUPLE;
        t->tuple = parse_tuple_types(aTHX_ "Float64, Float64", 16, &t->tuple_len);
    } else if (len == 4 && strncmp(type, "Ring", 4) == 0) {
        /* Ring = Array(Point) */
        t->code = T_ARRAY;
        t->inner = parse_type(aTHX_ "Point", 5);
    } else if (len == 10 && strncmp(type, "LineString", 10) == 0) {
        /* LineString = Array(Point) */
        t->code = T_ARRAY;
        t->inner = parse_type(aTHX_ "Point", 5);
    } else if (len == 15 && strncmp(type, "MultiLineString", 15) == 0) {
        /* MultiLineString = Array(Array(Point)) */
        t->code = T_ARRAY;
        t->inner = parse_type(aTHX_ "Array(Point)", 12);
    } else if (len == 7 && strncmp(type, "Polygon", 7) == 0) {
        /* Polygon = Array(Ring) */
        t->code = T_ARRAY;
        t->inner = parse_type(aTHX_ "Ring", 4);
    } else if (len == 12 && strncmp(type, "MultiPolygon", 12) == 0) {
        /* MultiPolygon = Array(Polygon) */
        t->code = T_ARRAY;
        t->inner = parse_type(aTHX_ "Polygon", 7);
    } else if (len > 15 && strncmp(type, "LowCardinality(", 15) == 0) {
        t->code = T_LOWCARDINALITY;
        t->inner = parse_type(aTHX_ type + 15, len - 16);
        if (t->inner->code != T_STRING && t->inner->code != T_FIXEDSTRING
                && (t->inner->code != T_NULLABLE
                    || (t->inner->inner->code != T_STRING
                        && t->inner->inner->code != T_FIXEDSTRING)))
            croak("LowCardinality(T) currently supports T = String / FixedString / Nullable(String) / Nullable(FixedString)");
    } else {
        croak("Unknown type: %.*s", (int)len, type);
    }

    /* Disarm the slot: caller now owns t. */
    *slot = NULL;
    return t;
}
