#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <stdint.h>

#include "types.h"

/* Cap on type-expression nesting. parse_type recurses once per level, as
 * do free_typeinfo / encode_column / decode_column over the tree it
 * builds, so an unbounded depth overflows the C stack - and type strings
 * are not always trusted: decode_block parses whatever a Native block
 * carries. Real schemas nest a handful of levels (MultiPolygon, the
 * deepest built-in alias, is 4). Capping the parse bounds every other
 * recursive walk, since they all follow this tree. */
#define CHE_MAX_TYPE_DEPTH 100

static TypeInfo* parse_type_at(pTHX_ const char *type, STRLEN len, int depth);

/* Bounded stand-in for atoi() on a slice that is not NUL-terminated at
 * `maxlen`, whose behaviour on an over-long digit run is undefined.
 * Returns -1 when no digit is present or the value would not fit an int,
 * leaving each caller's range check to report it. The ceiling is INT_MAX
 * rather than anything tighter: FixedString(N) is legal up to CH's
 * MAX_FIXED_STRING_SIZE and this parser also runs on wire type strings.
 * Overflow is checked before the multiply, so `long`'s width is moot. */
static int parse_int_param(const char *s, STRLEN maxlen, int allow_comma) {
    STRLEN i = 0;
    long v = 0;
    while (i < maxlen && (s[i] == ' ' || s[i] == '\t'
                       || s[i] == '\n' || s[i] == '\r')) i++;
    if (i >= maxlen || s[i] < '0' || s[i] > '9') return -1;
    for (; i < maxlen && s[i] >= '0' && s[i] <= '9'; i++) {
        int digit = s[i] - '0';
        if (v > (INT_MAX - digit) / 10) return -1;
        v = v * 10 + digit;
    }
    while (i < maxlen && isSPACE(s[i])) i++;
    if (i == maxlen || (s[i] != ')' && !(allow_comma && s[i] == ','))) return -1;
    if (s[i] == ')' && i + 1 != maxlen) return -1;
    return (int)v;
}

static STRLEN skip_type_quote(pTHX_ const char *s, STRLEN len, STRLEN pos) {
    char quote = s[pos++];
    while (pos < len) {
        if (s[pos] == '\\') { pos += 2; continue; }
        if (s[pos++] == quote) {
            if (pos < len && s[pos] == quote) { pos++; continue; }
            return pos;
        }
    }
    croak("Unterminated quote in type expression");
    return len;
}

static char *copy_type_name(pTHX_ const char *s, STRLEN len) {
    char *out;
    Newx(out, len + 1, char);
    STRLEN i = 0, n = 0;
    if (len && s[0] == '`') { i = 1; len--; }
    for (; i < len; i++) {
        if (s[i] == '\\' && i + 1 < len) i++;
        else if (s[i] == '`' && i + 1 < len && s[i+1] == '`') i++;
        out[n++] = s[i];
    }
    out[n] = 0;
    return out;
}

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
        int overflow = 0;
        while (i < len && s[i] >= '0' && s[i] <= '9') {
            /* Stop well before `long` wraps: signed overflow is undefined
             * and a wrapped value could land back inside the range check
             * below. 100000 is past every Enum16 bound. */
            if (val > 100000) overflow = 1;
            else val = val * 10 + (s[i] - '0');
            i++;
        }
        if (overflow) {
            Safefree(name_buf);
            croak("Enum value out of range for %s (must be %ld..%ld)",
                  code == T_ENUM8 ? "Enum8" : "Enum16", min_val, max_val);
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

/* Cleanup for a caller-owned TypeInfo*. parse_type disarms its own slot on
 * return, so a later croak would otherwise leak the tree. Frees the type,
 * not the slot, so the slot can be a local. Disarm by setting it NULL. */
void cleanup_typeinfo_ptr(pTHX_ void *p) {
    TypeInfo **slot = (TypeInfo **)p;
    if (*slot) {
        free_typeinfo(aTHX_ *slot);
        *slot = NULL;
    }
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
    char *name;         /* unquoted JSON path name */
} TypeBound;

/* Split a comma-separated type list at depth-0 commas, trim outer
 * whitespace, strip any leading "name<ws>" field-name prefix (Tuple
 * named-element form). When a field-name is found, name_start/name_len
 * record it so callers (e.g. T_TUPLE) can keep the names; when absent,
 * name_len is 0. bounds holds type_list_capacity(s, len) slots. */
static STRLEN type_list_capacity(const char *s, STRLEN len) {
    STRLEN n = 1;
    const char *end = s + len, *comma;
    while ((comma = memchr(s, ',', end - s))) { n++; s = comma + 1; }
    return n;
}

static int split_type_list(pTHX_ const char *s, STRLEN len, TypeBound *bounds) {
    int count = 0;
    int depth = 0;
    STRLEN start = 0, i;
    #define IS_WS(c) ((c)==' '||(c)=='\t'||(c)=='\n'||(c)=='\r')
    for (i = 0; i <= len; i++) {
        char c = (i < len) ? s[i] : ',';
        if (c == '\'' || c == '`') { i = skip_type_quote(aTHX_ s, len, i) - 1; continue; }
        if (c == '(') depth++;
        else if (c == ')') depth--;
        else if ((c == ',' && depth == 0) || i == len) {
            STRLEN tstart = start, tend = i;
            STRLEN nstart = 0, nlen = 0;
            while (tstart < tend && IS_WS(s[tstart])) tstart++;
            while (tend > tstart && IS_WS(s[tend-1])) tend--;
            if (tend > tstart) {
                STRLEN id_end = tstart;
                if (id_end < tend && s[id_end] == '`') {
                    id_end = skip_type_quote(aTHX_ s, tend, id_end);
                    if (id_end < tend && IS_WS(s[id_end])) {
                        nstart = tstart;
                        nlen = id_end - tstart;
                        while (id_end < tend && IS_WS(s[id_end])) id_end++;
                        tstart = id_end;
                    }
                } else if (id_end < tend
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
                                                int n, int depth) {
    TupleSlot *slot;
    Newxz(slot, 1, TupleSlot);
    SAVEDESTRUCTOR_X(cleanup_tuple_slot, slot);
    if (n > 0) Newxz(slot->types, n, TypeInfo*);

    int i;
    for (i = 0; i < n; i++) {
        slot->types[i] = parse_type_at(aTHX_ s + bounds[i].start,
                                       bounds[i].len, depth);
        slot->count = i + 1;
    }
    {
        TypeInfo **result = slot->types;
        slot->types = NULL;  /* Disarm: caller now owns the array. */
        return result;
    }
}

static TypeInfo** parse_tuple_types(pTHX_ const char *s, STRLEN len, int *count,
                                    int depth) {
    TypeBound *bounds;
    Newx(bounds, type_list_capacity(s, len), TypeBound);
    SAVEFREEPV(bounds);
    *count = split_type_list(aTHX_ s, len, bounds);
    return parse_tuple_types_with_bounds(aTHX_ s, bounds, *count, depth);
}

static SV *canonical_variant_type(pTHX_ const char *s, STRLEN len, TypeInfo *t) {
    while (len && isSPACE(*s)) { s++; len--; }
    while (len && isSPACE(s[len-1])) len--;
    const char *open = memchr(s, '(', len);
    STRLEN base_len = open ? (STRLEN)(open - s) : len;
    if (base_len == 7 && memcmp(s, "Boolean", 7) == 0)
        return sv_2mortal(newSVpvs("Bool"));
    if (base_len >= 7 && base_len <= 10 && memcmp(s, "Decimal", 7) == 0) {
        int precision = t->code == T_DECIMAL32 ? 9 : t->code == T_DECIMAL64 ? 18
                      : t->code == T_DECIMAL128 ? 38 : 76;
        if (base_len == 7) precision = parse_int_param(open + 1, len - base_len - 1, 1);
        return sv_2mortal(newSVpvf("Decimal(%d, %d)", precision, t->param));
    }
    SV *out = sv_2mortal(newSVpvn(s, base_len));
    if (!open) return out;
    if (base_len == 8 && memcmp(s, "DateTime", 8) == 0 && t->code == T_DATETIME64)
        sv_setpvs(out, "DateTime64");
    sv_catpvs(out, "(");
    const char *body = open + 1;
    STRLEN body_len = len - base_len - 2;
    if (t->inner && (t->code == T_ARRAY || t->code == T_NULLABLE || t->code == T_LOWCARDINALITY)) {
        sv_catsv(out, canonical_variant_type(aTHX_ body, body_len, t->inner));
    } else if (t->code == T_TUPLE || t->code == T_MAP) {
        /* Geo aliases have no '(' and retain their public name. */
        TypeBound *bounds;
        Newx(bounds, type_list_capacity(body, body_len), TypeBound);
        SAVEFREEPV(bounds);
        int n = split_type_list(aTHX_ body, body_len, bounds), i;
        for (i = 0; i < n; i++) {
            if (i) sv_catpvs(out, ", ");
            if (bounds[i].name_len) {
                sv_catpvn(out, body + bounds[i].name_start, bounds[i].name_len);
                sv_catpvs(out, " ");
            }
            sv_catsv(out, canonical_variant_type(aTHX_ body + bounds[i].start,
                                                bounds[i].len, t->tuple[i]));
        }
    } else {
        STRLEN i;
        for (i = 0; i < body_len; i++) {
            char c = body[i];
            if (c == '\'' || c == '`') {
                STRLEN end = skip_type_quote(aTHX_ body, body_len, i);
                sv_catpvn(out, body + i, end - i); i = end - 1;
            } else if (!isSPACE(c)) {
                sv_catpvn(out, &c, 1);
                if (c == ',') sv_catpvs(out, " ");
            }
        }
    }
    sv_catpvs(out, ")");
    return out;
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
                                   const char *body, STRLEN body_len,
                                   int depth) {
    TypeBound *bounds;
    Newxz(bounds, type_list_capacity(body, body_len), TypeBound);
    SAVEFREEPV(bounds);

    int idx = 0;
    int paren_depth = 0;   /* not `depth`, which is the type-nesting level */
    STRLEN start = 0, i;
    for (i = 0; i <= body_len; i++) {
        char c = (i < body_len) ? body[i] : ',';
        if (c == '\'' || c == '`') { i = skip_type_quote(aTHX_ body, body_len, i) - 1; continue; }
        if      (c == '(') paren_depth++;
        else if (c == ')') paren_depth--;
        else if ((c == ',' && paren_depth == 0) || i == body_len) {
            STRLEN ts = start, te = i;
            #define J_WS(c2) ((c2)==' '||(c2)=='\t'||(c2)=='\n'||(c2)=='\r')
            while (ts < te && J_WS(body[ts])) ts++;
            while (te > ts && J_WS(body[te-1])) te--;
            if (te > ts) {
                STRLEN id = ts;
                if (body[id] == '`') {
                    id = skip_type_quote(aTHX_ body, te, id);
                } else if (body[id] == '_'
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
    int n = idx, ii, j;
    for (ii = 0; ii < n; ii++) {
        bounds[ii].name = copy_type_name(aTHX_ body + bounds[ii].name_start,
                                         bounds[ii].name_len);
        SAVEFREEPV(bounds[ii].name);
    }
    for (ii = 1; ii < n; ii++) {
        TypeBound key = bounds[ii];
        j = ii - 1;
        while (j >= 0 && strcmp(bounds[j].name, key.name) > 0) {
            bounds[j+1] = bounds[j];
            j--;
        }
        bounds[j+1] = key;
    }
    for (ii = 1; ii < n; ii++) {
        if (strcmp(bounds[ii].name, bounds[ii-1].name) == 0)
            croak("JSON(...): duplicate typed path name '%s'", bounds[ii].name);
    }
    t->tuple_len = n;
    Newxz(t->tuple_names, n, char*);
    for (ii = 0; ii < n; ii++) t->tuple_names[ii] = savepv(bounds[ii].name);
    t->tuple = parse_tuple_types_with_bounds(aTHX_ body, bounds, n, depth);

    for (ii = 0; ii < n; ii++) {
        if (!type_can_be_typed_path(t->tuple[ii]))
            croak("JSON(%s ...): typed path inner type cannot include "
                  "Variant, LowCardinality, JSON, or Dynamic (those have "
                  "wire prefixes that would interleave incorrectly)",
                  t->tuple_names[ii]);
    }
}

TypeInfo* parse_type(pTHX_ const char *type, STRLEN len) {
    return parse_type_at(aTHX_ type, len, 0);
}

static TypeInfo* parse_type_at(pTHX_ const char *type, STRLEN len, int depth) {
    TypeInfo *t;
    /* Slot lives on the heap so its address is stable across the XSUB lifetime. */
    TypeInfo **slot;

    if (++depth > CHE_MAX_TYPE_DEPTH)
        croak("Type nesting too deep (limit %d): %.*s",
              CHE_MAX_TYPE_DEPTH, (int)(len > 60 ? 60 : len), type);

    while (len && isSPACE(type[0])) { type++; len--; }
    while (len && isSPACE(type[len-1])) len--;
    if (memchr(type, '(', len) && (!len || type[len-1] != ')'))
        croak("Unbalanced type expression: %.*s", (int)len, type);
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
        t->param = parse_int_param(type + 12, len - 12, 0);
        if (t->param <= 0) croak("FixedString needs positive length");
        /* ClickHouse's MAX_FIXED_STRING_SIZE; beyond it the server itself
         * refuses the type, so no real schema reaches here. */
        if (t->param > 0xFFFFFF)
            croak("FixedString length %d exceeds the maximum of %d",
                  t->param, 0xFFFFFF);
    } else if (len > 6 && strncmp(type, "Array(", 6) == 0) {
        t->code = T_ARRAY;
        t->inner = parse_type_at(aTHX_ type + 6, len - 7, depth);
    } else if (len > 6 && strncmp(type, "Tuple(", 6) == 0) {
        t->code = T_TUPLE;
        const char *body = type + 6;
        STRLEN body_len = len - 7;
        TypeBound *bounds;
        Newx(bounds, type_list_capacity(body, body_len), TypeBound);
        SAVEFREEPV(bounds);
        t->tuple_len = split_type_list(aTHX_ body, body_len, bounds);
        t->tuple = parse_tuple_types_with_bounds(aTHX_ body, bounds,
                                                 t->tuple_len, depth);
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
                    t->tuple_names[j] = copy_type_name(aTHX_ body + bounds[j].name_start, bounds[j].name_len);
                }
                /* else: leave NULL -- mixed named/unnamed not really
                 * supported; encode will croak if hashref is used. */
            }
        }
    } else if (len > 9 && strncmp(type, "Nullable(", 9) == 0) {
        if (len > 18 && strncmp(type + 9, "Nullable(", 9) == 0)
            croak("Nullable(Nullable(...)) is not allowed");
        t->code = T_NULLABLE;
        t->inner = parse_type_at(aTHX_ type + 9, len - 10, depth);
    } else if (len > 6 && strncmp(type, "Enum8(", 6) == 0) {
        t->code = T_ENUM8;
        parse_enum_entries(aTHX_ t, type + 6, len - 7, T_ENUM8);
    } else if (len > 7 && strncmp(type, "Enum16(", 7) == 0) {
        t->code = T_ENUM16;
        parse_enum_entries(aTHX_ t, type + 7, len - 8, T_ENUM16);
    } else if (len > 10 && strncmp(type, "Decimal32(", 10) == 0) {
        t->code = T_DECIMAL32;
        t->param = parse_int_param(type + 10, len - 10, 0);
        if (t->param < 0 || t->param > 9)
            croak("Decimal32 scale must be 0..9, got %d", t->param);
    } else if (len > 10 && strncmp(type, "Decimal64(", 10) == 0) {
        t->code = T_DECIMAL64;
        t->param = parse_int_param(type + 10, len - 10, 0);
        if (t->param < 0 || t->param > 18)
            croak("Decimal64 scale must be 0..18, got %d", t->param);
    } else if (len > 11 && strncmp(type, "Decimal128(", 11) == 0) {
        t->code = T_DECIMAL128;
        t->param = parse_int_param(type + 11, len - 11, 0);
        if (t->param < 0 || t->param > 38)
            croak("Decimal128 scale must be 0..38, got %d", t->param);
    } else if (len > 11 && strncmp(type, "Decimal256(", 11) == 0) {
        t->code = T_DECIMAL256;
        t->param = parse_int_param(type + 11, len - 11, 0);
        if (t->param < 0 || t->param > 76)
            croak("Decimal256 scale must be 0..76, got %d", t->param);
    } else if (len > 8 && strncmp(type, "Decimal(", 8) == 0) {
        int precision = parse_int_param(type + 8, len - 8, 1);
        const char *comma = memchr(type + 8, ',', len - 8);
        if (!comma) croak("Decimal(P, S) requires precision and scale");
        int scale = parse_int_param(comma + 1, len - (STRLEN)(comma + 1 - type), 0);
        if (precision < 1 || precision > 76)
            croak("Decimal(P, S) precision must be 1..76, got %d", precision);
        if (scale < 0 || scale > precision)
            croak("Decimal scale must be 0..precision, got %d", scale);
        t->param = scale;
        if (precision <= 9) t->code = T_DECIMAL32;
        else if (precision <= 18) t->code = T_DECIMAL64;
        else if (precision <= 38) t->code = T_DECIMAL128;
        else t->code = T_DECIMAL256;
    } else if (len == 4 && strncmp(type, "Date", 4) == 0) {
        t->code = T_DATE;
    } else if (len == 6 && strncmp(type, "Date32", 6) == 0) {
        t->code = T_DATE32;
    } else if (len == 8 && strncmp(type, "DateTime", 8) == 0) {
        t->code = T_DATETIME;
    } else if (len > 9 && strncmp(type, "DateTime(", 9) == 0) {
        const char *arg = type + 9;
        STRLEN arg_len = len - 9;
        while (arg_len && isSPACE(*arg)) { arg++; arg_len--; }
        if (arg_len && *arg >= '0' && *arg <= '9') {
            t->param = parse_int_param(arg, arg_len, 1);
            if (t->param < 0 || t->param > 9) croak("DateTime precision must be 0..9");
            t->code = t->param ? T_DATETIME64 : T_DATETIME;
        } else t->code = T_DATETIME;
    } else if (len > 11 && strncmp(type, "DateTime64(", 11) == 0) {
        t->code = T_DATETIME64;
        t->param = parse_int_param(type + 11, len - 11, 1);
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
        TypeInfo *inner = parse_type_at(aTHX_ body + inner_off,
                                          body_len - inner_off, depth);
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
        Newx(bounds, type_list_capacity(body, body_len), TypeBound);
        SAVEFREEPV(bounds);
        t->tuple_len = split_type_list(aTHX_ body, body_len, bounds);
        if (t->tuple_len < 1)
            croak("Variant requires at least one type argument");
        if (t->tuple_len > 254)
            croak("Variant supports at most 254 types (got %d)", t->tuple_len);
        t->tuple = parse_tuple_types_with_bounds(aTHX_ body, bounds,
                                                 t->tuple_len, depth);

        SV **canonical;
        Newx(canonical, t->tuple_len, SV *);
        SAVEFREEPV(canonical);
        int vi;
        for (vi = 0; vi < t->tuple_len; vi++)
            canonical[vi] = canonical_variant_type(aTHX_ body + bounds[vi].start,
                                                  bounds[vi].len, t->tuple[vi]);

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
                STRLEN la, lb;
                const char *sa = SvPV(canonical[a], la), *sb = SvPV(canonical[b], lb);
                STRLEN cmp_len = la < lb ? la : lb;
                int cmp = memcmp(sa, sb, cmp_len);
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
        t->tuple = parse_tuple_types(aTHX_ type + 4, len - 5, &t->tuple_len, depth);
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
            parse_json_typed_paths(aTHX_ t, type + 5, len - 6, depth);
        }
    } else if (len == 5 && strncmp(type, "Point", 5) == 0) {
        /* Point = Tuple(Float64, Float64) */
        t->code = T_TUPLE;
        t->tuple = parse_tuple_types(aTHX_ "Float64, Float64", 16,
                                    &t->tuple_len, depth);
    } else if (len == 4 && strncmp(type, "Ring", 4) == 0) {
        /* Ring = Array(Point) */
        t->code = T_ARRAY;
        t->inner = parse_type_at(aTHX_ "Point", 5, depth);
    } else if (len == 10 && strncmp(type, "LineString", 10) == 0) {
        /* LineString = Array(Point) */
        t->code = T_ARRAY;
        t->inner = parse_type_at(aTHX_ "Point", 5, depth);
    } else if (len == 15 && strncmp(type, "MultiLineString", 15) == 0) {
        /* MultiLineString = Array(Array(Point)) */
        t->code = T_ARRAY;
        t->inner = parse_type_at(aTHX_ "Array(Point)", 12, depth);
    } else if (len == 7 && strncmp(type, "Polygon", 7) == 0) {
        /* Polygon = Array(Ring) */
        t->code = T_ARRAY;
        t->inner = parse_type_at(aTHX_ "Ring", 4, depth);
    } else if (len == 12 && strncmp(type, "MultiPolygon", 12) == 0) {
        /* MultiPolygon = Array(Polygon) */
        t->code = T_ARRAY;
        t->inner = parse_type_at(aTHX_ "Polygon", 7, depth);
    } else if (len > 15 && strncmp(type, "LowCardinality(", 15) == 0) {
        t->code = T_LOWCARDINALITY;
        t->inner = parse_type_at(aTHX_ type + 15, len - 16, depth);
        if (t->inner->code != T_STRING && t->inner->code != T_FIXEDSTRING
                && (t->inner->code != T_NULLABLE
                    || (t->inner->inner->code != T_STRING
                        && t->inner->inner->code != T_FIXEDSTRING)))
            croak("LowCardinality(T) currently supports T = String / FixedString / Nullable(String) / Nullable(FixedString)");
    } else {
        croak("Unknown type: %.*s", (int)len, type);
    }

    t->has_prefix = t->code == T_LOWCARDINALITY || t->code == T_VARIANT
                 || t->code == T_JSON || t->code == T_DYNAMIC;
    if (t->inner && t->inner->has_prefix) t->split_prefix = 1;
    int pi;
    for (pi = 0; pi < t->tuple_len; pi++)
        if (t->tuple[pi]->has_prefix) t->split_prefix = 1;
    t->has_prefix |= t->split_prefix;

    /* Disarm the slot: caller now owns t. */
    *slot = NULL;
    return t;
}
