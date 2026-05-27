#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#ifdef _WIN32
#  include <winsock2.h>
#  include <ws2tcpip.h>
#else
#  include <sys/socket.h>
#  include <arpa/inet.h>
#endif

#include "types.h"
#include "buffer.h"
#include "decimal.h"
#include "scalar_kind.h"
#include "datetime.h"
#include "json_kind.h"
#include "encode.h"

/* Build a recursive NULL placeholder for `t`. Returns a mortal SV.
 * Leaf types get a defined zero/empty SV (not &PL_sv_undef) so that the
 * encoder doesn't warn about uninit values when filling padding bytes. */
static SV *make_null_placeholder(pTHX_ TypeInfo *t) {
    if (t->code == T_ARRAY || t->code == T_MAP) {
        AV *empty = newAV();
        return sv_2mortal(newRV_noinc((SV*)empty));
    }
    if (t->code == T_TUPLE) {
        AV *tuple = newAV();
        int i;
        for (i = 0; i < t->tuple_len; i++) {
            SV *child = make_null_placeholder(aTHX_ t->tuple[i]);
            av_push(tuple, SvREFCNT_inc(child));
        }
        return sv_2mortal(newRV_noinc((SV*)tuple));
    }
    if (t->code == T_LOWCARDINALITY)
        return make_null_placeholder(aTHX_ t->inner);
    if (t->code == T_VARIANT)
        /* Variant's encoder treats undef as the NULL discriminator. */
        return &PL_sv_undef;
    if (t->code == T_STRING || t->code == T_FIXEDSTRING)
        return sv_2mortal(newSVpvn("", 0));
    if (t->code == T_UUID || t->code == T_IPV6)
        return sv_2mortal(newSVpvn("\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", 16));
    if (t->code == T_FLOAT32 || t->code == T_FLOAT64 || t->code == T_BFLOAT16)
        return sv_2mortal(newSVnv(0.0));
    /* numeric / date / decimal / enum / bool / ipv4: a defined integer 0 is fine */
    return sv_2mortal(newSViv(0));
}

static int enum_lookup_name(pTHX_ TypeInfo *t, const char *s, STRLEN slen, int16_t *out) {
    SV **psv = hv_fetch(t->enum_lookup, s, slen, 0);
    if (!psv) return 0;
    *out = (int16_t)SvIV(*psv);
    return 1;
}

static void encode_scalar(pTHX_ Buffer *b, SV *val, TypeInfo *t) {
    switch (t->code) {
        case T_INT8:   buf_byte(aTHX_ b,(uint8_t)(int8_t)SvIV(val)); break;
        case T_INT16:  buf_le16(aTHX_ b,(uint16_t)(int16_t)SvIV(val)); break;
        case T_INT32:  buf_le32(aTHX_ b,(uint32_t)(int32_t)SvIV(val)); break;
        case T_INT64:  buf_le64(aTHX_ b,(uint64_t)(int64_t)SvIV(val)); break;
        case T_UINT8:  buf_byte(aTHX_ b,(uint8_t)SvUV(val)); break;
        case T_UINT16: buf_le16(aTHX_ b,(uint16_t)SvUV(val)); break;
        case T_UINT32: buf_le32(aTHX_ b,(uint32_t)SvUV(val)); break;
        case T_UINT64: buf_le64(aTHX_ b,(uint64_t)SvUV(val)); break;
        case T_FLOAT32: buf_lefloat(aTHX_ b,(float)SvNV(val)); break;
        case T_FLOAT64: buf_ledouble(aTHX_ b,SvNV(val)); break;
        case T_BFLOAT16: {
            /* BFloat16 = top 16 bits of the Float32 binary representation
             * (truncation, no rounding -- matches ClickHouse server). */
            union { float f; uint32_t u; } u;
            u.f = (float)SvNV(val);
            buf_le16(aTHX_ b, (uint16_t)(u.u >> 16));
            break;
        }
        case T_STRING: {
            if (!SvOK(val)) {
                buf_varint(aTHX_ b,0);
            } else {
                STRLEN len;
                const char *s = SvPV(val, len);
                buf_string(aTHX_ b,s, len);
            }
            break;
        }
        case T_FIXEDSTRING: {
            buf_grow(aTHX_ b,t->param);
            if (!SvOK(val)) {
                memset(b->ptr + b->len, 0, t->param);
                b->len += t->param;
            } else {
                STRLEN len;
                const char *s = SvPV(val, len);
                if (len >= (STRLEN)t->param) {
                    memcpy(b->ptr + b->len, s, t->param);
                    b->len += t->param;
                } else {
                    memcpy(b->ptr + b->len, s, len);
                    memset(b->ptr + b->len + len, 0, t->param - len);
                    b->len += t->param;
                }
            }
            break;
        }
        case T_ENUM8: {
            int16_t v = 0;
            if (!SvOK(val)) {
                /* zero */
            } else if (SvIOK(val) || SvNOK(val)) {
                IV iv = SvIV(val);
                if (iv < -128 || iv > 127)
                    croak("Enum8 value %" IVdf " out of range", iv);
                v = (int16_t)iv;
            } else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (!enum_lookup_name(aTHX_ t, s, slen, &v))
                    croak("Unknown enum value: %.*s", (int)slen, s);
            }
            buf_byte(aTHX_ b,(uint8_t)(int8_t)v);
            break;
        }
        case T_ENUM16: {
            int16_t v = 0;
            if (!SvOK(val)) {
                /* zero */
            } else if (SvIOK(val) || SvNOK(val)) {
                IV iv = SvIV(val);
                if (iv < -32768 || iv > 32767)
                    croak("Enum16 value %" IVdf " out of range", iv);
                v = (int16_t)iv;
            } else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (!enum_lookup_name(aTHX_ t, s, slen, &v))
                    croak("Unknown enum value: %.*s", (int)slen, s);
            }
            buf_le16(aTHX_ b,(uint16_t)v);
            break;
        }
        case T_DECIMAL32: {
            int64_t v64;
            if (looks_stringy(val)) {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (!parse_decimal_int64_str(s, slen, t->param, &v64))
                    croak("Invalid decimal string: %.*s", (int)slen, s);
            } else {
                double d = SvNV(val) * decimal_pow10(t->param);
                if (!(d >= (double)INT32_MIN && d <= (double)INT32_MAX))
                    croak("Decimal32 overflow");
                v64 = (int64_t)llround(d);
            }
            if (v64 < INT32_MIN || v64 > INT32_MAX)
                croak("Decimal32 overflow");
            buf_le32(aTHX_ b,(uint32_t)(int32_t)v64);
            break;
        }
        case T_DECIMAL64: {
            int64_t v;
            if (looks_stringy(val)) {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (!parse_decimal_int64_str(s, slen, t->param, &v))
                    croak("Invalid decimal string: %.*s", (int)slen, s);
            } else {
                double d = SvNV(val) * decimal_pow10(t->param);
                /* INT64_MAX (2^63 - 1) isn't exactly representable in double;
                 * the next representable double above it is 2^63 itself, so use
                 * a strict less-than against 2^63 to bracket the valid range. */
                if (!(d > -9.223372036854776e18 && d < 9.223372036854776e18))
                    croak("Decimal64 overflow (or non-finite value)");
                v = (int64_t)llround(d);
            }
            buf_le64(aTHX_ b,(uint64_t)v);
            break;
        }
        case T_DECIMAL256: {
            uint64_t limbs[4] = {0,0,0,0};
            if (looks_stringy(val)) {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (!parse_decimal256_str(s, slen, t->param, limbs))
                    croak("Invalid decimal string: %.*s", (int)slen, s);
            } else {
                /* Float path through long double; lossy past ~18 digits. */
                long double d = (long double)SvNV(val) * decimal_pow10l(t->param);
                if (!isfinite(d))
                    croak("Decimal256: cannot encode non-finite value");
                int neg = d < 0;
                if (neg) d = -d;
                d = roundl(d);
                long double two64  = (long double)18446744073709551616.0L;
                long double two255 = two64 * two64 * two64
                                   * (long double)9223372036854775808.0L;
                /* Reject values that would overflow signed 256-bit (i.e. set
                 * the sign bit, which CH would interpret as negative).
                 * Mirrors the >= 2^127 check in the Decimal128 path. */
                if (d >= two255)
                    croak("Decimal256 overflow");
                int j;
                for (j = 0; j < 4 && d > 0; j++) {
                    limbs[j] = (uint64_t)fmodl(d, two64);
                    d = (d - limbs[j]) / two64;
                }
                if (neg) {
                    for (j = 0; j < 4; j++) limbs[j] = ~limbs[j];
                    add_digit_256(limbs, 1);
                }
            }
            buf_le64(aTHX_ b, limbs[0]);
            buf_le64(aTHX_ b, limbs[1]);
            buf_le64(aTHX_ b, limbs[2]);
            buf_le64(aTHX_ b, limbs[3]);
            break;
        }
        case T_DECIMAL128: {
            uint64_t lo, hi;
            if (looks_stringy(val)) {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (!parse_decimal128_str(s, slen, t->param, &hi, &lo))
                    croak("Invalid decimal string: %.*s", (int)slen, s);
            } else {
                long double d = (long double)SvNV(val) * decimal_pow10l(t->param);
                if (!isfinite(d))
                    croak("Decimal128: cannot encode non-finite value");
                int neg = d < 0;
                if (neg) d = -d;
                d = roundl(d);
                long double two64  = (long double)18446744073709551616.0L;
                long double two127 = two64 * (long double)9223372036854775808.0L;
                if (d >= two127)
                    croak("Decimal128 overflow");
                hi = (uint64_t)(d / two64);
                lo = (uint64_t)fmodl(d, two64);
                if (neg) {
                    lo = ~lo + 1;
                    hi = ~hi + (lo == 0 ? 1 : 0);
                }
            }
            buf_le64(aTHX_ b,lo);
            buf_le64(aTHX_ b,hi);
            break;
        }
        case T_DATE: {
            uint16_t v;
            if (!SvOK(val)) v = 0;
            else if (SvIOK(val) || SvNOK(val)) v = (uint16_t)SvUV(val);
            else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (looks_like_int_str(s, slen)) v = (uint16_t)SvUV(val);
                else v = (uint16_t)parse_date_string(aTHX_ s, slen);
            }
            buf_le16(aTHX_ b,v);
            break;
        }
        case T_DATE32: {
            int32_t v;
            if (!SvOK(val)) v = 0;
            else if (SvIOK(val) || SvNOK(val)) v = (int32_t)SvIV(val);
            else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (looks_like_int_str(s, slen)) v = (int32_t)SvIV(val);
                else v = parse_date_string(aTHX_ s, slen);
            }
            buf_le32(aTHX_ b,(uint32_t)v);
            break;
        }
        case T_DATETIME: {
            uint32_t v;
            if (!SvOK(val)) v = 0;
            else if (SvIOK(val) || SvNOK(val)) v = (uint32_t)SvUV(val);
            else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (looks_like_int_str(s, slen)) v = (uint32_t)SvUV(val);
                else v = parse_datetime_string(aTHX_ s, slen);
            }
            buf_le32(aTHX_ b,v);
            break;
        }
        case T_DATETIME64: {
            int64_t v;
            if (!SvOK(val)) v = 0;
            else if (SvIOK(val)) v = (int64_t)SvIV(val);
            else if (SvNOK(val)) v = dt64_double_to_int64(aTHX_ SvNV(val), t->param);
            else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (looks_like_int_str(s, slen))
                    v = (int64_t)SvIV(val);
                else if (looks_like_number_str(s, slen))
                    v = dt64_double_to_int64(aTHX_ SvNV(val), t->param);
                else
                    v = parse_datetime64_string(aTHX_ s, slen, t->param);
            }
            buf_le64(aTHX_ b,(uint64_t)v);
            break;
        }
        case T_BOOL: {
            uint8_t v = SvOK(val) && SvTRUE(val) ? 1 : 0;
            buf_byte(aTHX_ b, v);
            break;
        }
        case T_UUID: {
            /* Wire format: two LE UInt64 halves with bytes reversed within
             * each half. Standard input is "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
             * also accept 16 raw bytes. */
            uint8_t buf16[16];
            if (!SvOK(val)) {
                memset(buf16, 0, 16);
            } else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (slen == 16) {
                    memcpy(buf16, s, 16);
                } else if (slen == 36) {
                    /* parse hex with dashes at positions 8, 13, 18, 23 */
                    int i, j = 0;
                    if (s[8] != '-' || s[13] != '-' || s[18] != '-' || s[23] != '-')
                        croak("Invalid UUID format: %.*s", (int)slen, s);
                    for (i = 0; i < 36; i++) {
                        if (i == 8 || i == 13 || i == 18 || i == 23) continue;
                        char c = s[i];
                        int nyb = (c >= '0' && c <= '9') ? c - '0'
                                : (c >= 'a' && c <= 'f') ? c - 'a' + 10
                                : (c >= 'A' && c <= 'F') ? c - 'A' + 10
                                : -1;
                        if (nyb < 0)
                            croak("Invalid UUID hex digit: %.*s", (int)slen, s);
                        if ((j & 1) == 0) buf16[j >> 1]  = nyb << 4;
                        else              buf16[j >> 1] |= nyb;
                        j++;
                    }
                } else {
                    croak("UUID requires 36-char string or 16 raw bytes, got %d bytes",
                          (int)slen);
                }
            }
            /* Reverse first half then second half. */
            uint8_t out[16];
            int i;
            for (i = 0; i < 8; i++) out[i]   = buf16[7 - i];
            for (i = 0; i < 8; i++) out[8+i] = buf16[15 - i];
            buf_append(aTHX_ b, (const char *)out, 16);
            break;
        }
        case T_IPV4: {
            uint32_t v;
            if (!SvOK(val)) v = 0;
            else if (SvIOK(val) || SvNOK(val)) v = (uint32_t)SvUV(val);
            else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (looks_like_int_str(s, slen)) {
                    v = (uint32_t)SvUV(val);
                } else {
                    char tmp[INET_ADDRSTRLEN];
                    if (slen >= sizeof(tmp))
                        croak("IPv4 string too long: %.*s", (int)slen, s);
                    memcpy(tmp, s, slen);
                    tmp[slen] = 0;
                    struct in_addr addr;
                    if (inet_pton(AF_INET, tmp, &addr) != 1)
                        croak("Invalid IPv4 address: %s", tmp);
                    /* inet_pton stores in network byte order; ntohl gives
                     * the canonical host-order integer (e.g. 0x01020304
                     * for "1.2.3.4") on any host. buf_le32 then writes
                     * the LE wire bytes [04][03][02][01]. */
                    v = ntohl((uint32_t)addr.s_addr);
                }
            }
            buf_le32(aTHX_ b, v);
            break;
        }
        case T_IPV6: {
            uint8_t out[16];
            if (!SvOK(val)) {
                memset(out, 0, 16);
            } else {
                STRLEN slen;
                const char *s = SvPV(val, slen);
                if (slen == 16) {
                    memcpy(out, s, 16);
                } else {
                    char tmp[INET6_ADDRSTRLEN];
                    if (slen >= sizeof(tmp))
                        croak("IPv6 string too long: %.*s", (int)slen, s);
                    memcpy(tmp, s, slen);
                    tmp[slen] = 0;
                    if (inet_pton(AF_INET6, tmp, out) != 1)
                        croak("Invalid IPv6 address: %s", tmp);
                }
            }
            buf_append(aTHX_ b, (const char *)out, 16);
            break;
        }
        default:
            croak("encode_scalar called on non-scalar type");
    }
}

static void encode_null_scalar(pTHX_ Buffer *b, TypeInfo *t) {
    switch (t->code) {
        case T_INT8: case T_UINT8: case T_ENUM8: case T_BOOL:
            buf_byte(aTHX_ b,0); break;
        case T_INT16: case T_UINT16: case T_ENUM16: case T_DATE: case T_BFLOAT16:
            buf_le16(aTHX_ b,0); break;
        case T_INT32: case T_UINT32: case T_FLOAT32:
        case T_DECIMAL32: case T_DATE32: case T_DATETIME: case T_IPV4:
            buf_le32(aTHX_ b,0); break;
        case T_INT64: case T_UINT64: case T_FLOAT64:
        case T_DECIMAL64: case T_DATETIME64:
            buf_le64(aTHX_ b,0); break;
        case T_DECIMAL128: case T_UUID: case T_IPV6:
            buf_le64(aTHX_ b,0); buf_le64(aTHX_ b,0); break;
        case T_DECIMAL256:
            buf_le64(aTHX_ b,0); buf_le64(aTHX_ b,0);
            buf_le64(aTHX_ b,0); buf_le64(aTHX_ b,0); break;
        case T_STRING:
            buf_varint(aTHX_ b,0); break;
        case T_FIXEDSTRING: {
            buf_grow(aTHX_ b,t->param);
            memset(b->ptr + b->len, 0, t->param);
            b->len += t->param;
            break;
        }
        default:
            croak("encode_null_scalar called on complex type");
    }
}

static int is_simple_type(TypeInfo *t) {
    return t->code != T_ARRAY && t->code != T_TUPLE && t->code != T_NULLABLE
        && t->code != T_MAP && t->code != T_LOWCARDINALITY
        && t->code != T_VARIANT && t->code != T_JSON
        && t->code != T_DYNAMIC;
}

/* Allocate an SV** array backed by a mortal SV (auto-freed on scope exit). */
SV **alloc_sv_array(pTHX_ SSize_t n) {
    if (n <= 0) return NULL;
    STRLEN bytes = n * sizeof(SV*);
    SV *holder = sv_2mortal(newSV(bytes));
    SvPOK_only(holder);
    SvCUR_set(holder, bytes);  /* keep the SV's claimed length in sync */
    return (SV**)SvPVX(holder);
}

static int json_is_bool_ref(pTHX_ SV *val);

/* For an arrayref leaf, infer the element kind. All elements must
 * resolve to the same scalar kind (Bool/Float64/Int64/String) or be
 * undef. Returns the matching JV_ARRAY_* kind, or -1 if heterogeneous
 * / unsupported. NULL elements are accepted and encoded as zero-valued
 * placeholders; CH represents them via the element type's Nullable
 * wrapper if the user declares one - we use the bare type here. */
static int json_classify_array(pTHX_ AV *av) {
    SSize_t n = av_len(av) + 1;
    int seen_kind = -1;
    SSize_t i;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        if (!e || !SvOK(*e)) continue;
        if (SvROK(*e)) {
            /* recognized booleans only; nested arrays/hashes in array
             * leaves are not yet supported */
            if (json_is_bool_ref(aTHX_ *e)) {
                if (seen_kind == -1) seen_kind = JV_BOOL;
                else if (seen_kind != JV_BOOL) return -1;
                continue;
            }
            return -1;
        }
        int leaf;
#ifdef SvIsBOOL
        if (SvIsBOOL(*e)) leaf = JV_BOOL;
        else
#endif
        if (SvIOK(*e) && !SvNOK(*e)) leaf = JV_INT64;
        else if (SvNOK(*e)) {
            NV nv = SvNV(*e);
            leaf = (nv == (NV)(int64_t)nv
                    && nv >= (NV)INT64_MIN && nv <= (NV)INT64_MAX)
                 ? JV_INT64 : JV_FLOAT64;
        } else {
            leaf = JV_STRING;
        }
        if (seen_kind == -1) seen_kind = leaf;
        else if (seen_kind != leaf) return -1;
    }
    /* all-NULL or empty: default to Array(Int64). The empty array
     * doesn't carry an element type, so we pick one arbitrarily. If
     * another row in the same path has a non-empty Array(T), the kind
     * mask will then carry both Array(Int64) and Array(T); for a clean
     * single-variant column the user can declare the column explicitly
     * via a Variant(...) type. */
    if (seen_kind == -1) return JV_ARRAY_INT64;
    switch (seen_kind) {
        case JV_BOOL:    return JV_ARRAY_BOOL;
        case JV_FLOAT64: return JV_ARRAY_FLOAT64;
        case JV_INT64:   return JV_ARRAY_INT64;
        case JV_STRING:  return JV_ARRAY_STRING;
        default:         return -1;
    }
}

static int json_pkg_is_bool(const char *pkg) {
    return pkg && (strcmp(pkg, "JSON::PP::Boolean") == 0
                || strcmp(pkg, "Types::Serialiser::Boolean") == 0
                || strcmp(pkg, "JSON::XS::Boolean") == 0
                || strcmp(pkg, "Cpanel::JSON::XS::Boolean") == 0
                || strcmp(pkg, "boolean") == 0);
}

/* True if val is a blessed ref into one of the recognized boolean packages. */
static int json_is_bool_ref(pTHX_ SV *val) {
    if (!(SvROK(val) && sv_isobject(val))) return 0;
    HV *stash = SvSTASH(SvRV(val));
    return stash && json_pkg_is_bool(HvNAME(stash));
}

/* Classify a non-undef leaf SV for JSON encoding. Hash/array refs (other
 * than recognized booleans) must be rejected by the caller before this. */
static JsonValueKind json_classify_leaf(pTHX_ SV *val) {
    if (json_is_bool_ref(aTHX_ val)) return JV_BOOL;
#ifdef SvIsBOOL
    if (SvIsBOOL(val)) return JV_BOOL;
#endif
    if (SvIOK(val) && !SvNOK(val)) return JV_INT64;
    if (SvNOK(val)) {
        NV n = SvNV(val);
        /* NV holding an exact integer value (e.g. `1.0`) collapses to
         * Int64 - matches CH's JSONEachRow type-inference. Users who
         * need `1.0` to survive as Float64 on the wire should put the
         * value through a float-typed Variant or an explicit Float64
         * column. NaN/Inf fall through to Float64 because the integer
         * round-trip equality check fails for them. */
        if (n == (NV)(int64_t)n
            && n >= (NV)INT64_MIN && n <= (NV)INT64_MAX)
            return JV_INT64;
        return JV_FLOAT64;
    }
    return JV_STRING;
}

/* Classify a (defined) JSON/Dynamic value SV. Dispatches arrayrefs to
 * json_classify_array and everything else to json_classify_leaf, so the
 * caller doesn't have to repeat the SvROK / bool-ref check. Returns the
 * JsonValueKind, or -1 if `val` is an arrayref with heterogeneous
 * elements. Caller has already ruled out hashref-non-bool refs. */
static int json_classify_value(pTHX_ SV *val) {
    if (SvROK(val) && !json_is_bool_ref(aTHX_ val))
        return json_classify_array(aTHX_ (AV*)SvRV(val));
    return json_classify_leaf(aTHX_ val);
}

/* Emit one element of an Array(T) Dynamic variant. Used by both T_JSON
 * (per-path) and T_DYNAMIC (top-level) encode paths; `ev` may be undef
 * in which case a zero-valued placeholder of the element type is written
 * (CH represents nulls via Nullable wrappers, which we don't introduce
 * inside Dynamic variant arrays). */
static void json_emit_array_elem(pTHX_ Buffer *b, SV *ev, int k_match) {
    switch (k_match) {
        case JV_ARRAY_BOOL: {
            if (!SvOK(ev)) { buf_byte(aTHX_ b, 0); break; }
            SV *bv = SvROK(ev) ? SvRV(ev) : ev;
            buf_byte(aTHX_ b, SvTRUE(bv) ? 1 : 0);
            break;
        }
        case JV_ARRAY_INT64:
            buf_le64(aTHX_ b, SvOK(ev) ? (uint64_t)(int64_t)SvIV(ev) : 0);
            break;
        case JV_ARRAY_FLOAT64:
            buf_ledouble(aTHX_ b, SvOK(ev) ? SvNV(ev) : 0.0);
            break;
        case JV_ARRAY_STRING: {
            if (!SvOK(ev)) { buf_varint(aTHX_ b, 0); break; }
            STRLEN sl;
            const char *ss = SvPV(ev, sl);
            buf_string(aTHX_ b, ss, sl);
            break;
        }
    }
}

/* Emit one scalar value of a Dynamic variant. `val` is assumed defined
 * (the disc loop has already routed undef rows to disc 0xff). */
static void json_emit_scalar(pTHX_ Buffer *b, SV *val, int k_match) {
    switch (k_match) {
        case JV_BOOL: {
            SV *bv = SvROK(val) ? SvRV(val) : val;
            buf_byte(aTHX_ b, SvTRUE(bv) ? 1 : 0);
            break;
        }
        case JV_INT64:
            buf_le64(aTHX_ b, (uint64_t)(int64_t)SvIV(val));
            break;
        case JV_FLOAT64:
            buf_ledouble(aTHX_ b, SvNV(val));
            break;
        case JV_STRING: {
            STRLEN sl;
            const char *s = SvPV(val, sl);
            buf_string(aTHX_ b, s, sl);
            break;
        }
        default: break;
    }
}

/* Recursively flatten a JSON value hash into a flat HV of dotted-path
 * names. Allocated SVs are mortalized so the caller never has to free
 * them; the only references stored in `out_flat` are to leaf SVs from
 * the original hash (which the caller pins).
 *
 * If `stop_paths` is non-NULL, it's a HV of dotted-path names to treat
 * as leaves: when we encounter a hash value at a path in the set, we
 * store the hashref directly rather than recursing. Used by JSON typed
 * paths whose declared inner type is a hash-shape (Map / Tuple). */
static void flatten_json_hash(pTHX_ HV *src,
                              const char *prefix, STRLEN prefix_len,
                              HV *out_flat, HV *stop_paths) {
    hv_iterinit(src);
    HE *he;
    while ((he = hv_iternext(src))) {
        I32 klen;
        char *kstr = hv_iterkey(he, &klen);
        SV *vsv = hv_iterval(src, he);

        STRLEN new_len = prefix_len + (prefix_len ? 1 : 0) + klen;
        SV *path_sv = sv_2mortal(newSV(new_len));
        SvPOK_only(path_sv);
        char *pbuf = SvPVX(path_sv);
        if (prefix_len) {
            memcpy(pbuf, prefix, prefix_len);
            pbuf[prefix_len] = '.';
            memcpy(pbuf + prefix_len + 1, kstr, klen);
        } else {
            memcpy(pbuf, kstr, klen);
        }
        SvCUR_set(path_sv, new_len);

        int stop_here = stop_paths
            && hv_exists(stop_paths, SvPVX(path_sv), new_len);

        if (!stop_here
            && SvROK(vsv) && SvTYPE(SvRV(vsv)) == SVt_PVHV
            && !json_is_bool_ref(aTHX_ vsv)) {
            /* Reject blessed hashrefs that aren't recognized Booleans:
             * a JSON value of `bless {}, "Custom"` shouldn't silently
             * flatten as if it were a plain hash. */
            if (sv_isobject(vsv))
                croak("JSON column: opaque blessed hashref (package '%s') "
                      "is not a JSON value; only known Boolean classes "
                      "are accepted as object leaves",
                      HvNAME(SvSTASH(SvRV(vsv))));
            flatten_json_hash(aTHX_ (HV*)SvRV(vsv),
                              SvPVX(path_sv), new_len, out_flat,
                              stop_paths);
        } else {
            hv_store(out_flat, SvPVX(path_sv), new_len,
                     SvREFCNT_inc_simple_NN(vsv), 0);
        }
    }
}

/* (path, len) pair: lets the JSON encoder sort paths whose keys may
 * contain embedded NUL bytes without falling back to strlen() after
 * sort. Perl HV keys are NUL-terminated but the value bytes themselves
 * are arbitrary, so we carry both together. */
typedef struct { char *path; STRLEN len; } PathEntry;

static int cmp_path_entry(const void *a, const void *b) {
    const PathEntry *pa = (const PathEntry *)a;
    const PathEntry *pb = (const PathEntry *)b;
    STRLEN n = pa->len < pb->len ? pa->len : pb->len;
    int r = memcmp(pa->path, pb->path, n);
    if (r) return r;
    if (pa->len < pb->len) return -1;
    if (pa->len > pb->len) return  1;
    return 0;
}

void encode_column(pTHX_ Buffer *b, SV **values, SSize_t num_rows, TypeInfo *t) {
    SSize_t r;

    switch (t->code) {
        case T_INT8: case T_INT16: case T_INT32: case T_INT64:
        case T_UINT8: case T_UINT16: case T_UINT32: case T_UINT64:
        case T_FLOAT32: case T_FLOAT64: case T_BFLOAT16:
        case T_STRING: case T_FIXEDSTRING:
        case T_ENUM8: case T_ENUM16:
        case T_DECIMAL32: case T_DECIMAL64: case T_DECIMAL128: case T_DECIMAL256:
        case T_DATE: case T_DATE32: case T_DATETIME: case T_DATETIME64:
        case T_BOOL: case T_UUID: case T_IPV4: case T_IPV6:
            for (r = 0; r < num_rows; r++) encode_scalar(aTHX_ b,values[r], t);
            break;

        case T_ARRAY: {
            uint64_t offset = 0;
            SSize_t total_elems = 0;

            for (r = 0; r < num_rows; r++) {
                SV *val = values[r];
                if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
                    croak("Expected arrayref for Array type");
                AV *av = (AV*)SvRV(val);
                SSize_t n = av_len(av) + 1;
                offset += (uint64_t)n;
                total_elems += n;
                buf_le64(aTHX_ b,offset);
            }

            if (total_elems > 0) {
                SV **all_elems = alloc_sv_array(aTHX_ total_elems);
                SSize_t idx = 0;
                for (r = 0; r < num_rows; r++) {
                    AV *av = (AV*)SvRV(values[r]);
                    SSize_t n = av_len(av) + 1;
                    SSize_t i;
                    for (i = 0; i < n; i++) {
                        SV **elem = av_fetch(av, i, 0);
                        all_elems[idx++] = elem ? *elem : &PL_sv_undef;
                    }
                }
                encode_column(aTHX_ b, all_elems, total_elems, t->inner);
            }
            break;
        }

        case T_TUPLE: {
            int i;
            SV **elem_values = alloc_sv_array(aTHX_ num_rows);

            for (i = 0; i < t->tuple_len; i++) {
                for (r = 0; r < num_rows; r++) {
                    SV *val = values[r];
                    if (!SvROK(val))
                        croak("Expected arrayref or hashref for Tuple type");
                    SV *rv = SvRV(val);
                    if (SvTYPE(rv) == SVt_PVAV) {
                        SV **elem = av_fetch((AV*)rv, i, 0);
                        elem_values[r] = elem ? *elem : &PL_sv_undef;
                    } else if (SvTYPE(rv) == SVt_PVHV
                               && t->tuple_names && t->tuple_names[i]) {
                        /* Named-tuple input as hashref: look up by name. */
                        SV **elem = hv_fetch((HV*)rv, t->tuple_names[i],
                                             strlen(t->tuple_names[i]), 0);
                        elem_values[r] = elem ? *elem : &PL_sv_undef;
                    } else if (SvTYPE(rv) == SVt_PVHV) {
                        croak("Tuple given as hashref but type is unnamed; "
                              "use arrayref or declare named Tuple(name Type, ...)");
                    } else {
                        croak("Expected arrayref or hashref for Tuple type");
                    }
                }
                encode_column(aTHX_ b, elem_values, num_rows, t->tuple[i]);
            }
            break;
        }

        case T_NULLABLE: {
            for (r = 0; r < num_rows; r++) {
                buf_byte(aTHX_ b,!SvOK(values[r]) ? 1 : 0);
            }

            if (is_simple_type(t->inner)) {
                for (r = 0; r < num_rows; r++) {
                    if (!SvOK(values[r])) encode_null_scalar(aTHX_ b, t->inner);
                    else encode_scalar(aTHX_ b,values[r], t->inner);
                }
            } else {
                SV **inner_values = alloc_sv_array(aTHX_ num_rows);
                for (r = 0; r < num_rows; r++) {
                    if (!SvOK(values[r]))
                        inner_values[r] = make_null_placeholder(aTHX_ t->inner);
                    else
                        inner_values[r] = values[r];
                }
                encode_column(aTHX_ b, inner_values, num_rows, t->inner);
            }
            break;
        }

        case T_MAP: {
            /* Wire format is identical to Array(Tuple(K, V)). Each row's value
             * is either a hashref or arrayref-of-pairs; normalize to a flat
             * arrayref of [k, v] pairs and reuse the Array(Tuple) path. */
            SV **norm = alloc_sv_array(aTHX_ num_rows);
            for (r = 0; r < num_rows; r++) {
                SV *val = values[r];
                if (!SvROK(val))
                    croak("Expected hashref or arrayref for Map type");
                SV *rv = SvRV(val);
                if (SvTYPE(rv) == SVt_PVAV) {
                    norm[r] = val;  /* already arrayref-of-pairs */
                } else if (SvTYPE(rv) == SVt_PVHV) {
                    HV *hv = (HV *)rv;
                    AV *pairs = newAV();
                    hv_iterinit(hv);
                    HE *he;
                    while ((he = hv_iternext(hv))) {
                        I32 klen;
                        char *kstr = hv_iterkey(he, &klen);
                        SV *vsv = hv_iterval(hv, he);
                        AV *pair = newAV();
                        av_push(pair, newSVpvn(kstr, klen));
                        av_push(pair, SvREFCNT_inc(vsv));
                        av_push(pairs, newRV_noinc((SV *)pair));
                    }
                    norm[r] = sv_2mortal(newRV_noinc((SV *)pairs));
                } else {
                    croak("Expected hashref or arrayref for Map type");
                }
            }

            /* Synthesize the Array(Tuple(K,V)) wire path. */
            uint64_t offset = 0;
            SSize_t total = 0;
            for (r = 0; r < num_rows; r++) {
                AV *av = (AV *)SvRV(norm[r]);
                SSize_t n = av_len(av) + 1;
                offset += (uint64_t)n;
                total += n;
                buf_le64(aTHX_ b, offset);
            }
            if (total > 0) {
                SV **all = alloc_sv_array(aTHX_ total);
                SSize_t idx = 0;
                for (r = 0; r < num_rows; r++) {
                    AV *av = (AV *)SvRV(norm[r]);
                    SSize_t n = av_len(av) + 1;
                    SSize_t i;
                    for (i = 0; i < n; i++) {
                        SV **elem = av_fetch(av, i, 0);
                        all[idx++] = elem ? *elem : &PL_sv_undef;
                    }
                }
                /* Encode as Tuple(K, V): first all keys, then all values. */
                int j;
                for (j = 0; j < 2; j++) {
                    SV **col = alloc_sv_array(aTHX_ total);
                    SSize_t k;
                    for (k = 0; k < total; k++) {
                        if (!SvROK(all[k]) || SvTYPE(SvRV(all[k])) != SVt_PVAV)
                            croak("Map pair must be a 2-element arrayref");
                        AV *pair = (AV *)SvRV(all[k]);
                        SV **e = av_fetch(pair, j, 0);
                        col[k] = e ? *e : &PL_sv_undef;
                    }
                    encode_column(aTHX_ b, col, total, t->tuple[j]);
                }
            }
            break;
        }

        case T_VARIANT: {
            /* Variant wire format (CH 24.1+):
             *   UInt64 LE  mode = 0 (non-shared serialization)
             *   UInt8[N]   wire discriminators (255 = NULL, else 0..n-1
             *              referring to the alphabetical-order position)
             *   <sub-cols> one per variant, in alphabetical order of type
             *              names; each contains the values whose
             *              discriminator equals that variant's wire index
             *
             * The user passes [decl_idx, value] using declaration order;
             * variant_decl_to_wire[d] / variant_wire_to_decl[w] handle
             * the alphabetical reordering ClickHouse requires. */
            int nvar = t->tuple_len;
            #define VARIANT_NULL 255

            buf_le64(aTHX_ b, 0);

            int *counts;  /* indexed by declaration idx */
            Newxz(counts, nvar, int);
            SAVEFREEPV(counts);
            SV ***per_var;  /* per_var[decl_idx] = values for that variant */
            Newxz(per_var, nvar, SV **);
            SAVEFREEPV(per_var);
            int v;
            for (v = 0; v < nvar; v++)
                per_var[v] = alloc_sv_array(aTHX_ num_rows);

            for (r = 0; r < num_rows; r++) {
                SV *val = values[r];
                if (!SvOK(val)) {
                    buf_byte(aTHX_ b, VARIANT_NULL);
                    continue;
                }
                if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVAV)
                    croak("Variant value must be undef or [variant_idx, value]");
                AV *av = (AV *)SvRV(val);
                if (av_len(av) + 1 != 2)
                    croak("Variant value must be a 2-element [idx, value] pair");
                SV **idx_sv = av_fetch(av, 0, 0);
                SV **vsv    = av_fetch(av, 1, 0);
                IV idx = idx_sv ? SvIV(*idx_sv) : -1;
                if (idx < 0 || idx >= nvar)
                    croak("Variant index %" IVdf " out of range (0..%d)",
                          idx, nvar - 1);
                buf_byte(aTHX_ b, (uint8_t)t->variant_decl_to_wire[idx]);
                per_var[idx][counts[idx]++] = vsv ? *vsv : &PL_sv_undef;
            }

            /* Emit sub-columns in wire (alphabetical) order. */
            for (v = 0; v < nvar; v++) {
                int d = t->variant_wire_to_decl[v];
                encode_column(aTHX_ b, per_var[d], counts[d], t->tuple[d]);
            }
            #undef VARIANT_NULL
            break;
        }

        case T_LOWCARDINALITY: {
            /* LowCardinality block format (per ClickHouse Native protocol):
             *   UInt64 LE  serialization version (= 1)
             *   UInt64 LE  flags: HasAdditionalKeys(=1<<9) | index-type-bits(0..3)
             *   UInt64 LE  dictionary keys count
             *   <dict>     keys serialized using the inner type's column format
             *   UInt64 LE  index count (= num_rows)
             *   <indices>  packed UInt8/16/32/64 according to flags low byte
             *
             * For Nullable(T) the underlying inner type for serialization is
             * the bare T; NULL is represented by reserving dictionary index 0
             * (which always carries the "default" value) and the wire format
             * for the actual non-NULL dict starts at index 1.
             */
            TypeInfo *inner = t->inner;
            int is_null = (inner->code == T_NULLABLE);
            TypeInfo *leaf = is_null ? inner->inner : inner;

            HV *seen     = (HV *)sv_2mortal((SV *)newHV());
            AV *dict_av  = (AV *)sv_2mortal((SV *)newAV());

            /* For FixedString(N) inner, dedup by the canonical N-byte form
             * (truncate or zero-pad) so inputs of different length that
             * encode to the same wire bytes collapse into one dict slot. */
            int fixed_n = (leaf->code == T_FIXEDSTRING) ? leaf->param : 0;
            SV *canon_holder = NULL;
            if (fixed_n > 0) {
                canon_holder = sv_2mortal(newSV(fixed_n));
                SvPOK_only(canon_holder);
                SvCUR_set(canon_holder, fixed_n);
            }

            /* Reserve dict slot 0. For Nullable inner this slot is the NULL
             * sentinel and must not be reused for the literal default value;
             * for non-Nullable it IS the default (empty / N-zero-bytes). */
            av_push(dict_av, newSVpvn("", 0));
            if (!is_null) {
                if (fixed_n > 0) {
                    char *cz = SvPVX(canon_holder);
                    memset(cz, 0, fixed_n);
                    hv_store(seen, cz, fixed_n, newSViv(0), 0);
                } else {
                    hv_store(seen, "", 0, newSViv(0), 0);
                }
            }

            /* Pre-allocate index buffer. */
            STRLEN idx_buf_len = num_rows * sizeof(uint64_t);
            SV *idx_sv = sv_2mortal(newSV(idx_buf_len));
            SvPOK_only(idx_sv);
            SvCUR_set(idx_sv, idx_buf_len);
            uint64_t *indices = (uint64_t *)SvPVX(idx_sv);

            for (r = 0; r < num_rows; r++) {
                SV *val = values[r];
                if (!SvOK(val)) {
                    /* Nullable: slot 0 is the NULL sentinel. Non-nullable:
                     * coerce undef to empty string (matches plain String
                     * behaviour) without invoking SvPV on undef, which
                     * would emit a "Use of uninitialized value" warning. */
                    if (is_null) { indices[r] = 0; continue; }
                    val = sv_2mortal(newSVpvn("", 0));
                }
                STRLEN slen;
                const char *s = SvPV(val, slen);
                const char *key;
                STRLEN klen;
                if (fixed_n > 0) {
                    /* Canonicalize to exactly N bytes: truncate or zero-pad. */
                    char *cz = SvPVX(canon_holder);
                    if (slen >= (STRLEN)fixed_n) {
                        memcpy(cz, s, fixed_n);
                    } else {
                        memcpy(cz, s, slen);
                        memset(cz + slen, 0, fixed_n - slen);
                    }
                    key  = cz;
                    klen = fixed_n;
                } else {
                    key  = s;
                    klen = slen;
                }
                SV **slot_sv = hv_fetch(seen, key, klen, 0);
                if (slot_sv) {
                    indices[r] = (uint64_t)SvUV(*slot_sv);
                } else {
                    UV pos = (UV)(av_len(dict_av) + 1);
                    av_push(dict_av, newSVpvn(key, klen));
                    hv_store(seen, key, klen, newSVuv(pos), 0);
                    indices[r] = (uint64_t)pos;
                }
            }

            UV dict_count = av_len(dict_av) + 1;
            int idx_bytes;
            int idx_type;
            if      (dict_count <= 256)        { idx_type = 0; idx_bytes = 1; }
            else if (dict_count <= 65536)      { idx_type = 1; idx_bytes = 2; }
            else if (dict_count <= 0xFFFFFFFF) { idx_type = 2; idx_bytes = 4; }
            else                               { idx_type = 3; idx_bytes = 8; }

            uint64_t flags = (uint64_t)idx_type | (1ULL << 9);  /* HasAdditionalKeys */

            buf_le64(aTHX_ b, 1);              /* version */
            buf_le64(aTHX_ b, flags);
            buf_le64(aTHX_ b, (uint64_t)dict_count);

            /* Serialize the dict using the leaf type. */
            SV **dict_vals = alloc_sv_array(aTHX_ (SSize_t)dict_count);
            SSize_t di;
            for (di = 0; di < (SSize_t)dict_count; di++) {
                SV **e = av_fetch(dict_av, di, 0);
                dict_vals[di] = e ? *e : &PL_sv_undef;
            }
            encode_column(aTHX_ b, dict_vals, (SSize_t)dict_count, leaf);

            buf_le64(aTHX_ b, (uint64_t)num_rows);

            for (r = 0; r < num_rows; r++) {
                uint64_t v = indices[r];
                switch (idx_bytes) {
                    case 1: buf_byte(aTHX_ b, (uint8_t)v); break;
                    case 2: buf_le16(aTHX_ b, (uint16_t)v); break;
                    case 4: buf_le32(aTHX_ b, (uint32_t)v); break;
                    case 8: buf_le64(aTHX_ b, v); break;
                }
            }
            break;
        }

        case T_JSON: {
            /* Per doc/json-research/README.md (validated byte-for-byte
             * against ClickHouse 26.3). Wire layout (V1):
             *   Object prefix: UInt64=0, varint K (twice for V1),
             *                  K * lenstr path                 -- K = dynamic paths
             *   For each typed path (sorted): inner prefix (empty for simple types)
             *   For each dynamic path: Dynamic prefix (UInt64=1, varint T x2,
             *                  T * lenstr type-name, UInt64=0)
             *   SharedData prefix: empty for MAP version
             *   For each typed path (sorted): inner column data
             *   For each dynamic path: N disc bytes + per-variant data
             *   Shared data: N * UInt64 LE zero
             *
             * t->tuple_len > 0 means JSON(name Type, ...) was declared:
             * those paths emit as regular columns, the rest as Dynamic.
             */

            /* Step 1: flatten each row's hashref to dotted-path leaves.
             * Typed paths whose declared inner type is itself a hash
             * shape (Map / Tuple) must NOT be recursed into during
             * flatten - the user's nested hash for those is the leaf
             * value, not a sub-object. Build a stop-set of those names
             * and pass it to flatten so it stops recursing at them. */
            HV *stop_paths = NULL;
            if (t->tuple_len > 0) {
                stop_paths = (HV*)sv_2mortal((SV*)newHV());
                int sk;
                for (sk = 0; sk < t->tuple_len; sk++) {
                    /* Unwrap Nullable so JSON(x Nullable(Map(...))) also
                     * stops at "x" rather than flattening the inner
                     * hash and losing the user's data. */
                    TypeInfo *inner = t->tuple[sk];
                    if (inner->code == T_NULLABLE) inner = inner->inner;
                    if (inner->code == T_MAP || inner->code == T_TUPLE) {
                        STRLEN nlen = strlen(t->tuple_names[sk]);
                        hv_store(stop_paths, t->tuple_names[sk],
                                 (I32)nlen, newSViv(1), 0);
                    }
                }
            }

            HV **row_hvs = NULL;
            if (num_rows > 0) {
                Newxz(row_hvs, num_rows, HV*);
                SAVEFREEPV(row_hvs);
            }
            HV *all_paths = (HV*)sv_2mortal((SV*)newHV());

            for (r = 0; r < num_rows; r++) {
                SV *val = values[r];
                if (!SvOK(val)) { row_hvs[r] = NULL; continue; }
                if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV)
                    croak("JSON column row %" IVdf
                          ": must be hashref or undef", (IV)r);
                HV *flat = (HV*)sv_2mortal((SV*)newHV());
                flatten_json_hash(aTHX_ (HV*)SvRV(val), NULL, 0, flat,
                                  stop_paths);
                row_hvs[r] = flat;
            }

            /* Step 1b: if typed paths are declared, extract their values
             * per row from each flat HV (and hv_delete to keep them out
             * of the dynamic-paths discovery below). For missing keys
             * we substitute a type-appropriate placeholder: undef for
             * Nullable/Variant, [] for Array/Map, "" for String, 0 for
             * numerics. The inner encoder then emits the default
             * bytes the same way it would for any other column. */
            SV ***typed_vals = NULL;
            int n_typed = t->tuple_len;
            if (n_typed > 0 && num_rows > 0) {
                Newxz(typed_vals, n_typed, SV **);
                SAVEFREEPV(typed_vals);
                int tp;
                for (tp = 0; tp < n_typed; tp++) {
                    typed_vals[tp] = alloc_sv_array(aTHX_ num_rows);
                    STRLEN nlen = strlen(t->tuple_names[tp]);
                    SV *missing = (t->tuple[tp]->code == T_NULLABLE)
                                  ? &PL_sv_undef
                                  : make_null_placeholder(aTHX_ t->tuple[tp]);
                    for (r = 0; r < num_rows; r++) {
                        if (!row_hvs[r]) {
                            typed_vals[tp][r] = missing;
                            continue;
                        }
                        SV **e = hv_fetch(row_hvs[r], t->tuple_names[tp],
                                          (I32)nlen, 0);
                        if (e) {
                            typed_vals[tp][r] = SvOK(*e) ? *e : missing;
                            /* hv_delete unconditionally on key presence
                             * so an explicit `undef` value doesn't leak
                             * into the dynamic-paths discovery below
                             * (would double-emit the path). */
                            hv_delete(row_hvs[r], t->tuple_names[tp],
                                      (I32)nlen, G_DISCARD);
                        } else {
                            typed_vals[tp][r] = missing;
                        }
                    }
                }
            }

            /* Step 1c: union remaining dynamic-path keys across rows. */
            for (r = 0; r < num_rows; r++) {
                if (!row_hvs[r]) continue;
                hv_iterinit(row_hvs[r]);
                HE *he;
                while ((he = hv_iternext(row_hvs[r]))) {
                    I32 klen;
                    char *kstr = hv_iterkey(he, &klen);
                    SV **e = hv_fetch(row_hvs[r], kstr, klen, 0);
                    if (e && SvOK(*e))
                        hv_store(all_paths, kstr, klen, newSViv(1), 0);
                }
            }

            /* Step 2: collect & sort path names. Snapshot (ptr, len) into
             * a paired struct array so the sort preserves the original
             * length even if a key contains an embedded NUL byte (legal
             * in Perl HVs; strlen() after sort would silently truncate). */
            int num_paths = 0;
            char **paths    = NULL;
            STRLEN *path_lens = NULL;
            {
                int total = (int)HvUSEDKEYS(all_paths);
                if (total > 0) {
                    Newx(paths, total, char*);
                    SAVEFREEPV(paths);
                    Newx(path_lens, total, STRLEN);
                    SAVEFREEPV(path_lens);
                    PathEntry *pe;
                    Newx(pe, total, PathEntry);
                    SAVEFREEPV(pe);
                    hv_iterinit(all_paths);
                    HE *he;
                    while ((he = hv_iternext(all_paths))) {
                        I32 klen;
                        char *kstr = hv_iterkey(he, &klen);
                        pe[num_paths].path = kstr;
                        pe[num_paths].len  = (STRLEN)klen;
                        num_paths++;
                    }
                    if (num_paths > 1)
                        qsort(pe, num_paths, sizeof(*pe), cmp_path_entry);
                    int pi;
                    for (pi = 0; pi < num_paths; pi++) {
                        paths[pi]     = pe[pi].path;
                        path_lens[pi] = pe[pi].len;
                    }
                }
            }

            /* Step 3: per-path kind mask. Walk each leaf; scalars and
             * recognized bool refs classify directly; arrayrefs classify
             * via json_classify_array (homogeneous element kind). Hash
             * refs or heterogeneous arrays fail loud with location. */
            unsigned *kind_masks = NULL;
            if (num_paths > 0) {
                Newxz(kind_masks, num_paths, unsigned);
                SAVEFREEPV(kind_masks);
                int p;
                for (p = 0; p < num_paths; p++) {
                    for (r = 0; r < num_rows; r++) {
                        if (!row_hvs[r]) continue;
                        SV **e = hv_fetch(row_hvs[r], paths[p],
                                          (I32)path_lens[p], 0);
                        if (!e || !SvOK(*e)) continue;
                        if (SvROK(*e) && !json_is_bool_ref(aTHX_ *e)
                            && SvTYPE(SvRV(*e)) != SVt_PVAV)
                            croak("JSON column row %" IVdf
                                  " path '%s': "
                                  "hash refs as leaves are not "
                                  "supported (already flattened); "
                                  "got %s",
                                  (IV)r, paths[p],
                                  sv_reftype(SvRV(*e), 0));
                        int k = json_classify_value(aTHX_ *e);
                        if (k < 0)
                            croak("JSON column row %" IVdf " path '%s': "
                                  "heterogeneous or unsupported array "
                                  "(elements must all be int, float, "
                                  "bool, or string)",
                                  (IV)r, paths[p]);
                        kind_masks[p] |= 1u << k;
                    }
                }
            }

            /* Step 4: emit Object structure prefix (V1). */
            buf_le64(aTHX_ b, 0);                     /* Object V1 */
            buf_varint(aTHX_ b, (UV)num_paths);       /* max_dynamic_paths */
            buf_varint(aTHX_ b, (UV)num_paths);       /* actual count */
            int p;
            for (p = 0; p < num_paths; p++)
                buf_string(aTHX_ b, paths[p], path_lens[p]);

            /* Per-path wire-slot tables. path_slots[p*5+s] is the lex-ordered
             * slot at index s (kind index or -1 for SharedVariant);
             * wire_slot_counts[p] is the slot count for path p. Computed
             * once, used by both prefix and data loops below. */
            int *path_slots = NULL;
            int *wire_slot_counts = NULL;
            if (num_paths > 0) {
                Newx(path_slots, num_paths * JSON_LEX_SLOTS, int);
                SAVEFREEPV(path_slots);
                Newx(wire_slot_counts, num_paths, int);
                SAVEFREEPV(wire_slot_counts);
                for (p = 0; p < num_paths; p++)
                    wire_slot_counts[p] =
                        json_build_lex_table(kind_masks[p], path_slots + p*JSON_LEX_SLOTS);
            }

            /* Step 5: per-path Dynamic V1 prefix + Variant mode. */
            for (p = 0; p < num_paths; p++) {
                int wire_slots = wire_slot_counts[p];
                int kc = wire_slots - 1;  /* minus SharedVariant */

                buf_le64(aTHX_ b, 1);                   /* Dynamic V1 */
                buf_varint(aTHX_ b, (UV)kc);            /* max_dynamic_types */
                buf_varint(aTHX_ b, (UV)kc);            /* actual count */

                /* User variant type names in lex order (skip SharedVariant). */
                int *slots = path_slots + p*JSON_LEX_SLOTS;
                int s;
                for (s = 0; s < wire_slots; s++) {
                    int k = slots[s];
                    if (k < 0) continue;
                    const char *nm = json_kind_type_name[k];
                    buf_string(aTHX_ b, nm, strlen(nm));
                }
                buf_le64(aTHX_ b, 0);                   /* Variant BASIC */
            }

            /* Step 5b: emit typed-path column data (sorted by name).
             * Typed paths come before dynamic-path Variant data on the
             * wire; their inner types are simple-prefix so encode_column
             * emits only the column body. typed_vals is only allocated
             * when both n_typed and num_rows are positive; skip when
             * num_rows == 0 to avoid dereferencing a NULL outer array. */
            if (n_typed > 0 && num_rows > 0) {
                int tp;
                for (tp = 0; tp < n_typed; tp++)
                    encode_column(aTHX_ b, typed_vals[tp], num_rows,
                                  t->tuple[tp]);
            }

            /* Step 6: per-path Variant data (discs + per-variant values).
             * For Array(T) variants the column's wire layout is:
             *   N UInt64 LE offsets (cumulative element counts)
             *   <inner-type values concatenated>
             * We emit offsets and inner data in a single pass per variant. */
            for (p = 0; p < num_paths; p++) {
                int wire_slots = wire_slot_counts[p];
                int *slots = path_slots + p*JSON_LEX_SLOTS;

                /* Discriminator byte per row. */
                for (r = 0; r < num_rows; r++) {
                    if (!row_hvs[r]) { buf_byte(aTHX_ b, 0xff); continue; }
                    SV **e = hv_fetch(row_hvs[r], paths[p],
                                      (I32)path_lens[p], 0);
                    if (!e || !SvOK(*e)) { buf_byte(aTHX_ b, 0xff); continue; }
                    int k = json_classify_value(aTHX_ *e);
                    buf_byte(aTHX_ b,
                             (uint8_t)json_kind_disc_in(k, slots, wire_slots));
                }

                /* Per-variant data in lex order. SharedVariant has zero
                 * rows in our encoder's output. */
                int s;
                for (s = 0; s < wire_slots; s++) {
                    int k_match = slots[s];
                    if (k_match < 0) continue;

                    /* Array(T) variants: first pass emits offsets (so the
                     * downstream offset cursor is contiguous) and counts
                     * total elements; second pass emits inner values. */
                    int is_array = (k_match >= JV_ARRAY_BOOL
                                 && k_match <= JV_ARRAY_STRING);
                    if (is_array) {
                        uint64_t offset = 0;
                        for (r = 0; r < num_rows; r++) {
                            if (!row_hvs[r]) continue;
                            SV **e = hv_fetch(row_hvs[r], paths[p],
                                              (I32)path_lens[p], 0);
                            if (!e || !SvOK(*e)) continue;
                            if (json_classify_value(aTHX_ *e) != k_match)
                                continue;
                            AV *av = (AV*)SvRV(*e);
                            SSize_t n = av_len(av) + 1;
                            offset += (uint64_t)n;
                            buf_le64(aTHX_ b, offset);
                        }
                    }

                    /* Element-value pass (Array(T)) or scalar pass (T). */
                    for (r = 0; r < num_rows; r++) {
                        if (!row_hvs[r]) continue;
                        SV **e = hv_fetch(row_hvs[r], paths[p],
                                          (I32)path_lens[p], 0);
                        if (!e || !SvOK(*e)) continue;
                        if (json_classify_value(aTHX_ *e) != k_match) continue;

                        if (is_array) {
                            AV *av = (AV*)SvRV(*e);
                            SSize_t n = av_len(av) + 1, i;
                            for (i = 0; i < n; i++) {
                                SV **elem = av_fetch(av, i, 0);
                                SV *ev = (elem && SvOK(*elem))
                                       ? *elem : &PL_sv_undef;
                                json_emit_array_elem(aTHX_ b, ev, k_match);
                            }
                        } else {
                            json_emit_scalar(aTHX_ b, *e, k_match);
                        }
                    }
                }
            }

            /* Step 7: shared data trailer (Array(Tuple(String,String))
             * with all rows empty -> N UInt64 LE zero offsets). */
            if (num_rows > 0) {
                STRLEN nbytes = (STRLEN)num_rows * 8;
                buf_grow(aTHX_ b, nbytes);
                memset(b->ptr + b->len, 0, nbytes);
                b->len += nbytes;
            }
            break;
        }

        case T_DYNAMIC: {
            /* Standalone Dynamic column: same wire format as one JSON
             * path's Dynamic sub-column (Dynamic V1 prefix + Variant
             * mode + Variant data) with no Object wrapping or shared
             * data trailer. Each row is a scalar / array / undef. */
            unsigned mask = 0;
            int *row_kinds = NULL;
            if (num_rows > 0) {
                Newx(row_kinds, num_rows, int);
                SAVEFREEPV(row_kinds);
            }
            for (r = 0; r < num_rows; r++) {
                SV *val = values[r];
                if (!SvOK(val)) { row_kinds[r] = -1; continue; }
                if (SvROK(val) && !json_is_bool_ref(aTHX_ val)
                    && SvTYPE(SvRV(val)) != SVt_PVAV)
                    croak("Dynamic row %" IVdf ": hash refs are not "
                          "supported; use JSON column instead "
                          "(got %s)", (IV)r, sv_reftype(SvRV(val), 0));
                int k = json_classify_value(aTHX_ val);
                if (k < 0)
                    croak("Dynamic row %" IVdf ": heterogeneous or "
                          "unsupported array", (IV)r);
                row_kinds[r] = k;
                mask |= 1u << k;
            }

            int slots[JSON_LEX_SLOTS];
            int wire_slots = json_build_lex_table(mask, slots);
            int kc = wire_slots - 1;

            buf_le64(aTHX_ b, 1);              /* Dynamic V1 */
            buf_varint(aTHX_ b, (UV)kc);       /* max_dynamic_types */
            buf_varint(aTHX_ b, (UV)kc);       /* actual count */
            int s;
            for (s = 0; s < wire_slots; s++) {
                int k = slots[s];
                if (k < 0) continue;
                const char *nm = json_kind_type_name[k];
                buf_string(aTHX_ b, nm, strlen(nm));
            }
            buf_le64(aTHX_ b, 0);              /* Variant BASIC */

            /* Discriminator byte per row. */
            for (r = 0; r < num_rows; r++) {
                if (row_kinds[r] < 0) { buf_byte(aTHX_ b, 0xff); continue; }
                buf_byte(aTHX_ b,
                         (uint8_t)json_kind_disc_in(row_kinds[r],
                                                    slots, wire_slots));
            }

            /* Per-variant data in lex order. */
            for (s = 0; s < wire_slots; s++) {
                int k_match = slots[s];
                if (k_match < 0) continue;
                int is_array = (k_match >= JV_ARRAY_BOOL
                             && k_match <= JV_ARRAY_STRING);

                if (is_array) {
                    uint64_t offset = 0;
                    for (r = 0; r < num_rows; r++) {
                        if (row_kinds[r] != k_match) continue;
                        AV *av = (AV*)SvRV(values[r]);
                        offset += (uint64_t)(av_len(av) + 1);
                        buf_le64(aTHX_ b, offset);
                    }
                    for (r = 0; r < num_rows; r++) {
                        if (row_kinds[r] != k_match) continue;
                        AV *av = (AV*)SvRV(values[r]);
                        SSize_t n = av_len(av) + 1, i;
                        for (i = 0; i < n; i++) {
                            SV **elem = av_fetch(av, i, 0);
                            SV *ev = (elem && SvOK(*elem))
                                   ? *elem : &PL_sv_undef;
                            json_emit_array_elem(aTHX_ b, ev, k_match);
                        }
                    }
                } else {
                    for (r = 0; r < num_rows; r++) {
                        if (row_kinds[r] != k_match) continue;
                        json_emit_scalar(aTHX_ b, values[r], k_match);
                    }
                }
            }
            break;
        }

        default:
            croak("encode_column: unhandled type code %d", t->code);
    }
}
