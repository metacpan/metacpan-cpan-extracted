typedef uint16_t float16_t;

bool is_pin_v2(pTHX_ SV * sv);
const infix_type * resolve_type(pTHX_ const infix_type * type);
SV * bind_aggregate(pTHX_ void * ptr, const infix_type * type, SV * owner, bool);
int is_v2_vtable(MGVTBL * v);

static SV * _bind_aggregate_internal(
    pTHX_ void * ptr, const infix_type * type, SV * owner, infix_arena_t * arena, bool, bool);
int is_string_list_type(pTHX_ const infix_type * type) {
    const infix_type * t = resolve_type(aTHX_ type);
    if (!t)
        return 0;
    if (t->category != INFIX_TYPE_POINTER)
        return 0;

    const infix_type * p1 = resolve_type(aTHX_ t->meta.pointer_info.pointee_type);
    if (!p1 || p1->category != INFIX_TYPE_POINTER)
        return 0;

    const infix_type * p2 = resolve_type(aTHX_ p1->meta.pointer_info.pointee_type);
    if (!p2)
        return 0;
    if (p2->category != INFIX_TYPE_PRIMITIVE)
        return 0;

    /* We treat 'char' and 'uchar' as semantic strings.
       'sint8' is left as a raw integer for manual memory control. */
    return (p2->meta.primitive_id == INFIX_PRIMITIVE_SINT8 || p2->meta.primitive_id == INFIX_PRIMITIVE_UINT8);
}

/**
 * @brief Converts IEEE 754 half-precision (16-bit) to single-precision (32-bit) float.
 * @details Half-precision has 1 sign bit, 5 exponent bits, and 10 mantissa bits.
 * @param h The 16-bit half-precision value (stored as an unsigned integer).
 * @return The 32-bit single-precision float.
 */
float float16_to_float32(float16_t h) {
    uint32_t h_exp = (h >> 10) & 0x1f;         /* Extract 5-bit exponent */
    uint32_t h_sig = h & 0x3ff;                /* Extract 10-bit mantissa (significand) */
    uint32_t sign = (uint32_t)(h >> 15) << 31; /* Shift sign bit to 32-bit position */
    if (h_exp == 0) {
        if (h_sig == 0)
            return (sign) ? -0.0f : 0.0f; /* Signed zero */

        while (!(h_sig & 0x400)) { /* Subnormal number: normalize it */
            h_sig <<= 1;
            h_exp--;
        }
        h_exp++;
        h_sig &= ~0x400;
    }
    else if (h_exp == 0x1f) {
        /* Infinity or NaN */
        uint32_t f_nan = (h_sig == 0) ? 0x7f800000 : 0x7fc00000;
        union {
            uint32_t u;
            float f;
        } u;
        u.u = sign | f_nan;
        return u.f;
    }
    /* Adjust exponent bias from 15 to 127 and align mantissa to 23 bits */
    uint32_t f_exp = (h_exp + (127 - 15)) << 23;
    uint32_t f_sig = h_sig << 13;
    union {
        uint32_t u;
        float f;
    } u;
    u.u = sign | f_exp | f_sig;
    return u.f;
}
/**
 * @brief Converts IEEE 754 single-precision (32-bit) float to half-precision (16-bit).
 * @details Rounds standard floats down to the limited bounds of a half-precision float.
 * @param f The 32-bit single-precision float.
 * @return The 16-bit half-precision value.
 */
float16_t float32_to_float16(float f) {
    union {
        float f;
        uint32_t u;
    } u;
    u.f = f;
    uint32_t sign = (u.u >> 16) & 0x8000;
    uint32_t exp = (u.u >> 23) & 0xff;
    uint32_t sig = u.u & 0x7fffff;
    /* Handle Inf and NaN */
    if (exp == 0xff)
        return sign | 0x7c00 | (sig ? 0x200 : 0);
    int e = (int)exp - 127 + 15; /* Re-bias exponent to 15 */
    if (e >= 31)
        return sign | 0x7c00; /* Overflow to Infinity */
    if (e <= 0) {
        /* Underflow to Subnormal */
        if (e < -10)
            return sign;
        sig |= 0x800000;
        sig >>= (1 - e);
        return sign | (sig >> 13);
    }
    return sign | (e << 10) | (sig >> 13);
}

/**
 * @brief Common destructor for all v2 magic.
 * Ensures that if a pin owns an anonymous type graph, it is freed with the SV.
 */
int free_v2_pin(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->destructor && im->ptr)
        im->destructor(im->ptr);
    if (im->destructor_lib_sv)
        SvREFCNT_dec(im->destructor_lib_sv);
    if (im->arena)
        infix_arena_destroy(im->arena);
    return 0;
}

static int dup_v2_pin(pTHX_ MAGIC * mg, CLONE_PARAMS * param) {
#ifdef USE_ITHREADS
    Affix_Pin_2_Point_Oh * old_pin = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (!old_pin)
        return 0;

    Affix_Pin_2_Point_Oh * new_pin;
    Newxz(new_pin, 1, Affix_Pin_2_Point_Oh);
    memcpy(new_pin, old_pin, sizeof(Affix_Pin_2_Point_Oh));

    // Lifeline Tracking (Library handles)
    if (old_pin->destructor_lib_sv) {
        new_pin->destructor_lib_sv = sv_dup(old_pin->destructor_lib_sv, param);
        SvREFCNT_inc(new_pin->destructor_lib_sv);
    }

    // Type Metadata (Deep Copy)
    if (old_pin->arena) {
        // If the pin owns a private type arena (anonymous signatures),
        // we must clone the arena and re-point the type into the new arena.
        new_pin->arena = infix_arena_create(4096);
        new_pin->type = _copy_type_graph_to_arena(new_pin->arena, old_pin->type);
    }
    // Else: Global types from the registry are handled via CLONE in Affix.c

    mg->mg_ptr = (char *)new_pin;
#endif
    return 0;
}

/**
 * @brief Heuristic algorithm to determine if an array type should be treated as a string.
 * @details C has no real strings, only arrays. This checks if the array consists of
 * integer types matching known string types (char, char16_t, wchar_t).
 * @param type The infix_type definition.
 * @param out_wide Pointer to an int that will be set to 1 if the string is wide (UTF-16/32).
 * @return 1 if it's a string array, 0 otherwise.
 */
int is_string_array(pTHX_ const infix_type * type, int * out_wide) {
    if (type->category != INFIX_TYPE_ARRAY)
        return 0;

    const infix_type * el_raw = type->meta.array_info.element_type;
    const infix_type * el_res = resolve_type(aTHX_ el_raw);

    if (el_res->category != INFIX_TYPE_PRIMITIVE)
        return 0;

    // Standard 8-bit ints/chars are always treated as standard C strings
    if (el_res->meta.primitive_id == INFIX_PRIMITIVE_SINT8 || el_res->meta.primitive_id == INFIX_PRIMITIVE_UINT8) {
        if (out_wide)
            *out_wide = 0;
        return 1;
    }

    // Check explicitly named types (e.g. char16_t, WChar, wchar_t, etc.)
    const char * n = infix_type_get_name(el_raw);
    if (!n && el_raw->category == INFIX_TYPE_NAMED_REFERENCE)
        n = el_raw->meta.named_reference.name;

    if (!n) {
        n = infix_type_get_name(el_res);
        if (!n && el_res->category == INFIX_TYPE_NAMED_REFERENCE)
            n = el_res->meta.named_reference.name;
    }
    if (n) {
        /* Use a robust substring check to catch all variations of "char" / "WChar" */
        if (strstr(n, "char") || strstr(n, "Char") || strstr(n, "CHAR") || strEQ(n, "WChar") || strEQ(n, "wchar_t")) {
            if (el_res->size == 2 || el_res->size == 4) {
                if (out_wide)
                    *out_wide = 1;
                return 1;
            }
        }
    }

    return 0;
}

/**
 * @brief Recursively resolves named references and enums to their underlying AST types.
 * @param type The infix_type definition to resolve.
 * @return The resolved infix_type.
 */
const infix_type * resolve_type(pTHX_ const infix_type * type) {
    dMY_CXT;
    while (type) {
        if (type->category == INFIX_TYPE_NAMED_REFERENCE) {
            if (!MY_CXT.registry)
                break;
            const infix_type * resolved = infix_registry_lookup_type(MY_CXT.registry, type->meta.named_reference.name);
            if (resolved)
                type = resolved;
            else
                break;
        }
        else
            break;
    }
    return type;
}

#define MG_V2_TABLE(get, set, len) {get, set, len, nullptr, free_v2_pin, nullptr, dup_v2_pin}

/*
   FAST DISPATCH VTABLES:
   These Virtual Tables hook into Perl's SV read/write events. Instead of
   allocating a new SV on every read, they intercept reads and map them directly
   from the underlying C memory, creating zero-copy bindings.
*/
#undef MAKE_PRIMITIVE_DISPATCH
#define MAKE_PRIMITIVE_DISPATCH(NAME, C_TYPE, SV_SET, SV_GET)           \
    int get_##NAME(pTHX_ SV * sv, MAGIC * mg) {                         \
        Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr; \
        SvSMAGICAL_off(sv);                                             \
        if (!im->ptr)                                                   \
            sv_setsv(sv, &PL_sv_undef);                                 \
        else                                                            \
            SV_SET(sv, *(C_TYPE *)im->ptr);                             \
        SvSMAGICAL_on(sv);                                              \
        return 0;                                                       \
    }                                                                   \
    int set_##NAME(pTHX_ SV * sv, MAGIC * mg) {                         \
        Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr; \
        if (im->readonly)                                               \
            croak("Modification of a read-only C value attempted");     \
        if (!im->ptr)                                                   \
            return 0;                                                   \
        SvGMAGICAL_off(sv);                                             \
        *(C_TYPE *)im->ptr = (C_TYPE)SV_GET(sv);                        \
        SvGMAGICAL_on(sv);                                              \
        return 0;                                                       \
    }                                                                   \
    MGVTBL vtbl_##NAME = MG_V2_TABLE(get_##NAME, set_##NAME, nullptr);
MAKE_PRIMITIVE_DISPATCH(sint8, int8_t, sv_setiv, SvIV)
MAKE_PRIMITIVE_DISPATCH(uint8, uint8_t, sv_setuv, SvUV)
MAKE_PRIMITIVE_DISPATCH(sint16, int16_t, sv_setiv, SvIV)
MAKE_PRIMITIVE_DISPATCH(uint16, uint16_t, sv_setuv, SvUV)
MAKE_PRIMITIVE_DISPATCH(sint32, int32_t, sv_setiv, SvIV)
MAKE_PRIMITIVE_DISPATCH(uint32, uint32_t, sv_setuv, SvUV)
MAKE_PRIMITIVE_DISPATCH(sint64, int64_t, sv_setiv, SvIV)
MAKE_PRIMITIVE_DISPATCH(uint64, uint64_t, sv_setuv, SvUV)
MAKE_PRIMITIVE_DISPATCH(float, float, sv_setnv, SvNV)
MAKE_PRIMITIVE_DISPATCH(double, double, sv_setnv, SvNV)

/**
 * @brief VTable GET handler for half-precision floats.
 */
int get_float16(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    SvSMAGICAL_off(sv);
    if (!im->ptr)
        sv_setsv(sv, &PL_sv_undef);
    else
        sv_setnv(sv, (NV)float16_to_float32(*(float16_t *)im->ptr));
    SvSMAGICAL_on(sv);
    return 0;
}

/**
 * @brief VTable SET handler for half-precision floats.
 */
int set_float16(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (!im->ptr)
        return 0;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    SvGMAGICAL_off(sv);
    *(float16_t *)im->ptr = float32_to_float16((float)SvNV(sv));
    SvGMAGICAL_on(sv);
    return 0;
}
MGVTBL vtbl_float16 = {get_float16, set_float16, nullptr, nullptr, free_v2_pin};

/**
 * @brief VTable Handlers for Booleans
 */
int get_bool(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    SvSMAGICAL_off(sv);
    if (!im->ptr)
        sv_setsv(sv, &PL_sv_undef);
    else
        sv_setiv(sv, *(bool *)im->ptr ? 1 : 0);
    SvSMAGICAL_on(sv);
    return 0;
}

int set_bool(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (!im->ptr)
        return 0;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    SvGMAGICAL_off(sv);
    *(bool *)im->ptr = SvTRUE(sv);
    SvGMAGICAL_on(sv);
    return 0;
}
MGVTBL vtbl_bool = {get_bool, set_bool, nullptr, nullptr, free_v2_pin};

/**
 * @brief Converts a native 128-bit unsigned integer to a base-10 string SV.
 * @details Perl lacks internal 128-bit support, so it must be marshalled as a string.
 * @param sv The destination Perl Scalar.
 * @param val The native 128-bit value.
 * @param is_signed If true, checks the sign bit and prepends '-'.
 */
void alt_int128_to_sv(pTHX_ SV * sv, unsigned __int128 val, bool is_signed) {
    char buf[64];
    char * p = buf + 63;
    *p = '\0';
    bool neg = false;
    /* Safely evaluate 128-bit negative bounds via casting */
    if (is_signed && (__int128)val < 0) {
        neg = true;
        val = -(__int128)val;
    }
    if (val == 0) {
        *--p = '0';
    }
    else {
        while (val > 0) {
            *--p = (char)((val % 10) + '0');
            val /= 10;
        }
    }
    if (neg)
        *--p = '-';
    sv_setpv(sv, p);
}

/**
 * @brief Parses a base-10 or base-16 Perl String into a native 128-bit integer.
 * @param sv The source Perl string.
 * @return The parsed native 128-bit value.
 */
unsigned __int128 _alt_sv_to_int128(pTHX_ SV * sv) {
    STRLEN len;
    char * p = SvPV(sv, len);
    unsigned __int128 res = 0;
    bool neg = false;
    while (len > 0 && isSPACE(*p)) {
        p++;
        len--;
    } /* Trim leading whitespace */
    if (len > 0 && *p == '-') {
        neg = true;
        p++;
        len--;
    }
    /* Support Hexadecimal 0x format natively */
    if (len >= 2 && p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
        p += 2;
        len -= 2;
        while (len > 0) {
            int v = (*p >= '0' && *p <= '9') ? (*p - '0')
                : (*p >= 'a' && *p <= 'f')   ? (*p - 'a' + 10)
                : (*p >= 'A' && *p <= 'F')   ? (*p - 'A' + 10)
                                             : -1;
            if (v == -1)
                break;
            if (res > (unsigned __int128)~(unsigned __int128)0 / 16)
                croak("Overflow parsing 128-bit hex literal");
            res = res * 16 + v;
            p++;
            len--;
        }
    }
    else {
        while (len > 0 && *p >= '0' && *p <= '9') {
            if (res > (unsigned __int128)~(unsigned __int128)0 / 10)
                croak("Overflow parsing 128-bit decimal literal");
            res = res * 10 + (*p - '0');
            p++;
            len--;
        }
    }
    return neg ? (unsigned __int128)(-(__int128)res) : res;
}

int get_128s(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    SvSMAGICAL_off(sv);
    if (!im->ptr)
        sv_setsv(sv, &PL_sv_undef);
    else
        alt_int128_to_sv(aTHX_ sv, *(unsigned __int128 *)im->ptr, true);
    SvSMAGICAL_on(sv);
    return 0;
}

int get_128u(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    SvSMAGICAL_off(sv);
    if (!im->ptr)
        sv_setsv(sv, &PL_sv_undef);
    else
        alt_int128_to_sv(aTHX_ sv, *(unsigned __int128 *)im->ptr, false);
    SvSMAGICAL_on(sv);
    return 0;
}

int set_128(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    if (!im->ptr)
        return 0;
    SvGMAGICAL_off(sv);
    *(unsigned __int128 *)im->ptr = _alt_sv_to_int128(aTHX_ sv);
    SvGMAGICAL_on(sv);
    return 0;
}
MGVTBL vtbl_sint128 = {get_128s, set_128, nullptr, nullptr, free_v2_pin};
MGVTBL vtbl_uint128 = {get_128u, set_128, nullptr, nullptr, free_v2_pin};

/**
 * @brief Dynamic lookup to associate an Infix Type AST with a Perl Magic VTable.
 */
MGVTBL * get_primitive_vtable(const infix_type * type) {
    switch (type->meta.primitive_id) {
    case INFIX_PRIMITIVE_SINT8:
        return &vtbl_sint8;
    case INFIX_PRIMITIVE_UINT8:
        return &vtbl_uint8;
    case INFIX_PRIMITIVE_SINT16:
        return &vtbl_sint16;
    case INFIX_PRIMITIVE_UINT16:
        return &vtbl_uint16;
    case INFIX_PRIMITIVE_SINT32:
        return &vtbl_sint32;
    case INFIX_PRIMITIVE_UINT32:
        return &vtbl_uint32;
    case INFIX_PRIMITIVE_SINT64:
        return &vtbl_sint64;
    case INFIX_PRIMITIVE_UINT64:
        return &vtbl_uint64;
    case INFIX_PRIMITIVE_FLOAT:
        return &vtbl_float;
    case INFIX_PRIMITIVE_DOUBLE:
        return &vtbl_double;
    case INFIX_PRIMITIVE_FLOAT16:
        return &vtbl_float16;
    case INFIX_PRIMITIVE_BOOL:
        return &vtbl_bool;
    case INFIX_PRIMITIVE_SINT128:
        return &vtbl_sint128;
    case INFIX_PRIMITIVE_UINT128:
        return &vtbl_uint128;
    default:
        warn("Affix: unknown primitive type ID %d, falling back to sint32", type->meta.primitive_id);
        return &vtbl_sint32;
    }
}

int void_mg_get(pTHX_ SV * sv, MAGIC * mg) {
    SvSMAGICAL_off(sv);
    sv_setsv(sv, &PL_sv_undef);
    SvSMAGICAL_on(sv);
    return 0;
}

MGVTBL vtbl_void = {void_mg_get, nullptr, nullptr, nullptr, free_v2_pin};

int string_mg_get(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    const infix_type * t = resolve_type(aTHX_ im->type);
    size_t max_len = t->meta.array_info.num_elements;
    SvSMAGICAL_off(sv);
    char * target = (char *)im->ptr;
    if (!target) {
        sv_setsv(sv, &PL_sv_undef);
    }
    else if (max_len == 0) {
        sv_setpvn(sv, "", 0);
    }
    else {
        size_t actual = 0;
        while (actual < max_len && target[actual] != '\0')
            actual++;
        sv_setpvn(sv, target, actual);
    }
    SvSMAGICAL_on(sv);
    return 0;
}

int string_mg_set(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    if (!im->ptr)
        return 0;

    const infix_type * t = resolve_type(aTHX_ im->type);
    size_t max_len = t->meta.array_info.num_elements;
    if (max_len == 0)
        return 0;

    SvGMAGICAL_off(sv);
    STRLEN len;
    const char * str = SvPV(sv, len);

    size_t to_copy = (len < max_len) ? len : max_len - 1;
    memcpy(im->ptr, str, to_copy);
    ((char *)im->ptr)[to_copy] = '\0';

    SvGMAGICAL_on(sv);
    return 0;
}

MGVTBL string_vtable = {string_mg_get, string_mg_set, nullptr, nullptr, free_v2_pin};

/**
 * @brief Reads UTF-16/32 Wide Strings from C and converts them into a Perl UTF-8 String.
 */
int wstring_mg_get(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    const infix_type * t = resolve_type(aTHX_ im->type);
    size_t max_len = t->meta.array_info.num_elements;
    size_t el_sz = t->meta.array_info.element_type->size;
    SvSMAGICAL_off(sv);
    size_t act = 0;
    if (!im->ptr) {
        sv_setpvn(sv, "", 0);
        SvSMAGICAL_on(sv);
        return 0;
    }
    /* Find null terminator */
    for (; act < max_len; act++)
        if (el_sz == 2 && ((uint16_t *)im->ptr)[act] == 0)
            break;
        else if (el_sz == 4 && ((uint32_t *)im->ptr)[act] == 0)
            break;
    /* Allocate temp buffer for UTF-8 (max 4 bytes per character) */
    U8 * buf = (U8 *)safemalloc(act * UTF8_MAXBYTES + 1);
    U8 * d = buf;
    for (size_t i = 0; i < act; i++) {
        UV cp = (el_sz == 2) ? ((uint16_t *)im->ptr)[i] : ((uint32_t *)im->ptr)[i];
        /* Combine Surrogate Pairs for UTF-16 */
        if (el_sz == 2 && cp >= 0xD800 && cp <= 0xDBFF && i + 1 < act) {
            uint16_t low = ((uint16_t *)im->ptr)[i + 1];
            if (low >= 0xDC00 && low <= 0xDFFF) {
                cp = 0x10000 + (((cp - 0xD800) << 10) | (low - 0xDC00));
                i++;
            }
        }
        d = uvchr_to_utf8(d, cp);
    }
    *d = '\0';
    sv_setpvn(sv, (char *)buf, d - buf);
    SvUTF8_on(sv);
    safefree(buf);
    SvSMAGICAL_on(sv);
    return 0;
}

/**
 * @brief Converts a Perl UTF-8 string into a C UTF-16/32 Array.
 */
int wstring_mg_set(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    if (!im->ptr)
        return 0;
    const infix_type * t = resolve_type(aTHX_ im->type);
    size_t max_len = t->meta.array_info.num_elements;
    size_t el_sz = t->meta.array_info.element_type->size;
    if (max_len == 0)
        return 0;
    SvGMAGICAL_off(sv);
    STRLEN len;
    char * str = SvPVutf8(sv, len);
    U8 * p = (U8 *)str;
    U8 * pend = p + len;
    size_t i = 0;
    while (p < pend && i < max_len - 1) {
        STRLEN rlen;
        UV cp = utf8_to_uvchr_buf(p, pend, &rlen);
        if (rlen == 0)
            break;
        p += rlen;
        if (cp == 0)
            break;
        /* Split UTF-8 back into UTF-16 Surrogate Pairs if applicable */
        if (el_sz == 2 && cp > 0xFFFF) {
            /* Truncation safety: Don't write half a pair if buffer is almost full */
            if (i < max_len - 2) {
                cp -= 0x10000;
                ((uint16_t *)im->ptr)[i++] = 0xD800 + (cp >> 10);
                ((uint16_t *)im->ptr)[i++] = 0xDC00 + (cp & 0x3FF);
            }
            else
                break;
        }
        else {
            if (el_sz == 2)
                ((uint16_t *)im->ptr)[i++] = (uint16_t)cp;
            else
                ((uint32_t *)im->ptr)[i++] = (uint32_t)cp;
        }
    }
    /* Terminate string */
    if (el_sz == 2)
        ((uint16_t *)im->ptr)[i] = 0;
    else
        ((uint32_t *)im->ptr)[i] = 0;
    SvGMAGICAL_on(sv);
    return 0;
}

MGVTBL wstring_vtable = {wstring_mg_get, wstring_mg_set, nullptr, nullptr, free_v2_pin};

/**
 * @brief VTable GET handler for Bitfields
 */
int get_bitfield(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    const infix_type * type = resolve_type(aTHX_ im->type);
    SvSMAGICAL_off(sv);
    if (!im->ptr) {
        sv_setsv(sv, &PL_sv_undef);
        SvSMAGICAL_on(sv);
        return 0;
    }
    uint64_t val = 0;
    size_t sz = type->size;
    if (sz == 1)
        val = *(uint8_t *)im->ptr;
    else if (sz == 2)
        val = *(uint16_t *)im->ptr;
    else if (sz == 4)
        val = *(uint32_t *)im->ptr;
    else if (sz == 8)
        val = *(uint64_t *)im->ptr;

    uint64_t mask = (im->bit_width == 64) ? ~0ULL : ((1ULL << im->bit_width) - 1);
    val = (val >> im->bit_offset) & mask;

    bool is_signed =
        (type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 || type->meta.primitive_id == INFIX_PRIMITIVE_SINT16 ||
         type->meta.primitive_id == INFIX_PRIMITIVE_SINT32 || type->meta.primitive_id == INFIX_PRIMITIVE_SINT64 ||
         type->meta.primitive_id == INFIX_PRIMITIVE_SINT128);

    if (is_signed && (val & (1ULL << (im->bit_width - 1)))) {
        val |= ~mask; /* Sign extend */
        sv_setiv(sv, (IV)val);
    }
    else {
        sv_setuv(sv, val);
    }

    SvSMAGICAL_on(sv);
    return 0;
}

/**
 * @brief VTable SET handler for Bitfields (With safe mask overflow bounding)
 */
int set_bitfield(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    if (!im->ptr)
        return 0;
    const infix_type * type = resolve_type(aTHX_ im->type);
    SvGMAGICAL_off(sv);
    uint64_t val = 0;
    size_t sz = type->size;
    if (sz == 1)
        val = *(uint8_t *)im->ptr;
    else if (sz == 2)
        val = *(uint16_t *)im->ptr;
    else if (sz == 4)
        val = *(uint32_t *)im->ptr;
    else if (sz == 8)
        val = *(uint64_t *)im->ptr;
    /* Calculate bitmask and apply overflow protection */
    uint64_t wmask = (im->bit_width == 64) ? ~0ULL : ((1ULL << im->bit_width) - 1);
    uint64_t mask = wmask << im->bit_offset;
    uint64_t new_bits = (SvUV(sv) & wmask) << im->bit_offset;
    val = (val & ~mask) | new_bits;
    if (sz == 1)
        *(uint8_t *)im->ptr = (uint8_t)val;
    else if (sz == 2)
        *(uint16_t *)im->ptr = (uint16_t)val;
    else if (sz == 4)
        *(uint32_t *)im->ptr = (uint32_t)val;
    else if (sz == 8)
        *(uint64_t *)im->ptr = (uint64_t)val;
    SvGMAGICAL_on(sv);
    return 0;
}

MGVTBL vtbl_bitfield = {get_bitfield, set_bitfield, nullptr, nullptr, free_v2_pin};

/**
 * @brief Universal closure trampoline for FFI Perl callbacks attached to Structs.
 * @details This function is invoked from native C space when a callback fires. It converts
 * the raw C arguments back into Perl variables using VTable magic, executes
 * the Perl subroutine, and marshals the result back into the expected C return type.
 */
void perl_universal_closure(infix_context_t * ctx, void * ret, void ** args) {
    dTHX;
    dSP;
    CV * perl_sub = (CV *)infix_reverse_get_user_data(ctx);
    size_t n = infix_reverse_get_num_args(ctx);

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* Push C arguments onto the Perl Stack using Affix 2.0 pull handlers */
    for (size_t i = 0; i < n; i++) {
        const infix_type * type = infix_reverse_get_arg_type(ctx, i);
        Affix_Pull puller = get_pull_handler(aTHX_ type);

        if (!puller)
            croak("Unsupported struct callback argument type");

        SV * arg_sv = newSV(0);
        puller(aTHX_ nullptr, arg_sv, type, args[i], false);
        mXPUSHs(arg_sv);
    }
    PUTBACK;

    const infix_type * ret_type = infix_reverse_get_return_type(ctx);
    U32 call_flags = G_KEEPERR | ((ret_type->category == INFIX_TYPE_VOID) ? G_VOID : G_SCALAR);

    size_t count = call_sv((SV *)perl_sub, call_flags);
    SPAGAIN;

    /* Retrieve Perl return value and pass it back to C using Affix 2.0 push handlers */
    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "Perl struct callback died: %" SVf, ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
        if (ret && !(call_flags & G_VOID))
            memset(ret, 0, infix_type_get_size(ret_type));
    }
    else if (call_flags & G_SCALAR) {
        SV * return_sv = (count == 1) ? POPs : &PL_sv_undef;
        sv2ptr(aTHX_ nullptr, return_sv, ret, ret_type);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
}

void pull_pointer_as_callable(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p, bool readonly) {
    void * c_ptr = *(void **)p;
    if (c_ptr == nullptr) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    const infix_type * pointee = type;
    if (type->category == INFIX_TYPE_POINTER)
        pointee = resolve_type(aTHX_ type->meta.pointer_info.pointee_type);

    SV * wrapper = wrap_callable_pointer(aTHX_ c_ptr, pointee);
    sv_setsv(sv, wrapper);
    SvREFCNT_dec(wrapper);
}

/**
 * @brief Dynamically wraps a C function pointer into a callable Perl Subroutine.
 */
SV * wrap_callable_pointer(pTHX_ void * addr, const infix_type * type) {
    if (!addr)
        return newSV(0);

    char sig[512];
    /* Serialize the AST back into a string signature */
    if (infix_type_print(sig, sizeof(sig), type, INFIX_DIALECT_SIGNATURE) != INFIX_SUCCESS) {
        warn("Affix: failed to serialize callback type signature, wrapping as raw pointer");
        return newSVuv(PTR2UV(addr));
    }

    /* Strip the callback indicator '!' so Affix::wrap treats it as a standard function */
    char * sig_ptr = sig;
    if (sig_ptr[0] == '!')
        sig_ptr++;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    /* Push arguments for Affix::wrap($address, $signature_string) */
    PUSHs(sv_2mortal(newSVuv(PTR2UV(addr))));
    PUSHs(sv_2mortal(newSVpv(sig_ptr, 0)));
    PUTBACK;

    int count = call_pv("Affix::wrap", G_SCALAR);
    SPAGAIN;

    SV * ret = newSV(0);
    if (count == 1) {
        SV * wrapped = POPs;
        if (SvOK(wrapped))
            sv_setsv(ret, wrapped);
        else
            sv_setuv(ret, PTR2UV(addr));
    }
    else {
        sv_setuv(ret, PTR2UV(addr));
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

int get_ptr(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    SvSMAGICAL_off(sv);

    /* If it's absolute (malloc/cast/pin), im->ptr is the memory address of the data.
       If it's relative (struct member), im->ptr is the address of a pointer variable. */
    void * addr = im->absolute ? im->ptr : (im->ptr ? *(void **)im->ptr : nullptr);

    if (!addr) {
        sv_setsv(sv, &PL_sv_undef);
    }
    else {
        const infix_type * res = resolve_type(aTHX_ im->type);

        /* Detect terminal pointers (String, StringList, Callback, etc.) */
        Affix_Pull puller = get_pull_handler(aTHX_ res);
        if (puller && puller != pull_pointer_as_pin) {
            puller(aTHX_ nullptr, sv, res, &addr, im->readonly);
        }
        else {
            /* If the type is a pointer, step down one level. */
            const infix_type * pointee =
                (res->category == INFIX_TYPE_POINTER) ? res->meta.pointer_info.pointee_type : res;

            /* Unwrap terminal string/void protections for the inner pin if needed */
            const infix_type * pin_type = _unwrap_pin_type(pointee);

            pull_pointer_as_pin(aTHX_ nullptr, sv, pin_type, &addr, im->readonly);
        }
    }

    SvSMAGICAL_on(sv);
    return 0;
}

int set_ptr(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    if (!im || !im->ptr)
        return 0;

    SvGMAGICAL_off(sv);
    void * new_addr = nullptr;

    /* Priority 1: Subroutines */
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV) {
        CV * cv = (CV *)SvRV(sv);
        SvREFCNT_inc(cv);
        infix_reverse_t * rc = nullptr;
        const infix_type * ft = resolve_type(aTHX_ im->type);
        while (ft && ft->category == INFIX_TYPE_POINTER)
            ft = resolve_type(aTHX_ ft->meta.pointer_info.pointee_type);

        size_t n = (ft && ft->category == INFIX_TYPE_REVERSE_TRAMPOLINE) ? ft->meta.func_ptr_info.num_args : 0;
        if (ft && ft->category != INFIX_TYPE_REVERSE_TRAMPOLINE)
            croak("Expected a callback type for struct member assignment");
        infix_type ** at = n ? (infix_type **)safecalloc(n, sizeof(infix_type *)) : nullptr;
        for (size_t i = 0; i < n; i++)
            at[i] = ft->meta.func_ptr_info.args[i].type;

        if (ft && ft->category == INFIX_TYPE_REVERSE_TRAMPOLINE &&
            infix_reverse_create_closure_manual(&rc,
                                                ft->meta.func_ptr_info.return_type,
                                                at,
                                                n,
                                                ft->meta.func_ptr_info.num_fixed_args,
                                                perl_universal_closure,
                                                cv) == INFIX_SUCCESS) {
            new_addr = infix_reverse_get_code(rc);
        }
        if (at)
            safefree(at);
    }
    /* Priority 2: Null */
    else if (!SvOK(sv)) {
        new_addr = nullptr;
    }


    /* Priority 3: StringLists (char**) */
    else if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        if (is_string_list_type(aTHX_ im->type)) {
            AV * av = (AV *)SvRV(sv);
            size_t len = av_len(av) + 1;

            /* If the pin has an arena (common in struct members), we use it.
               Otherwise, we use safemalloc (leak risk if not managed). */
            char ** list =
                (char **)(im->arena ? infix_arena_alloc(im->arena, (len + 1) * sizeof(char *), _Alignof(char *))
                                    : safecalloc(len + 1, sizeof(char *)));

            for (size_t i = 0; i < len; ++i) {
                SV ** elem = av_fetch(av, i, 0);
                if (elem && SvPOK(*elem)) {
                    STRLEN slen;
                    const char * s = SvPV(*elem, slen);
                    if (im->arena) {
                        list[i] = (char *)infix_arena_alloc(im->arena, slen + 1, 1);
                        memcpy(list[i], s, slen + 1);
                    }
                    else {
                        list[i] = savepv(s);
                    }
                }
                else {
                    list[i] = nullptr;
                }
            }
            list[len] = nullptr;
            new_addr = list;
        }
        else {
            /* Fallback: User passed an ArrayRef to a non-char** pointer.
               Treat as raw integer address. */
            new_addr = INT2PTR(void *, SvUV(sv));
        }
    }

    /* Priority 4: Strings for char* */
    else if (SvPOK(sv) && !SvROK(sv) && !sv_isobject(sv)) {
        const infix_type * ft_raw = resolve_type(aTHX_ im->type);
        if (ft_raw->category == INFIX_TYPE_POINTER) {
            const infix_type * pointee = resolve_type(aTHX_ ft_raw->meta.pointer_info.pointee_type);
            if (pointee->category == INFIX_TYPE_PRIMITIVE &&
                (pointee->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                 pointee->meta.primitive_id == INFIX_PRIMITIVE_UINT8)) {
                new_addr = (void *)SvPV_nolen(sv);
            }
            else {
                new_addr = INT2PTR(void *, SvUV(sv));
            }
        }
        else {
            new_addr = INT2PTR(void *, SvUV(sv));
        }
    }

    /* Priority 5: Existing Pins/Addresses */
    else {
        void * extracted = _extract_pointer_value(aTHX_ sv, mg);
        new_addr = extracted ? extracted : (SvIOK(sv) ? INT2PTR(void *, SvUV(sv)) : nullptr);
    }

    *(void **)im->ptr = new_addr;

    SvGMAGICAL_on(sv);
    return 0;
}

MGVTBL vtbl_pointer = {get_ptr, set_ptr, nullptr, nullptr, free_v2_pin};

int array_mg_fetch(pTHX_ SV * sv, MAGIC * mg) {
    /* This is triggered when someone does $array[i] */
    /* However, for MAGIC_ext on AVs, Perl doesn't call svt_get for indices. */
    /* To truly protect indices, we'd need to hook into the AV's vtable. */
    /* For now, we will focus on the bind_aggregate logic to prevent creation of OOB pins. */
    return 0;
}

/**
 * @brief Returns the length of an Infix C array so Perl's `scalar(@arr)` works.
 */
U32 array_mg_len(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (!im->ptr)
        return 0;
    const infix_type * t = resolve_type(aTHX_ im->type);
    size_t len = (t->category == INFIX_TYPE_ARRAY) ? t->meta.array_info.num_elements : t->meta.vector_info.num_elements;
    return (U32)(len > 0 ? len - 1 : 0);
}

MGVTBL vtbl_array = {nullptr, nullptr, (U32 (*)(pTHX_ SV *, MAGIC *))array_mg_len, nullptr, free_v2_pin};

/**
 * @brief Lazy-loads child structures from memory when a Perl user tries to interact with a struct.
 */
int lazy_agg_get(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (SvROK(sv) || SvTYPE(sv) >= SVt_PVAV)
        return 0;

    SvSMAGICAL_off(sv);
    if (!im->ptr) {
        SV * rv = _bind_aggregate_internal(aTHX_ nullptr, im->type, mg->mg_obj, im->arena, true, im->readonly);
        sv_setsv(sv, rv);
        SvREFCNT_dec(rv);
        im->arena = nullptr;
    }
    else {
        SV * rv = _bind_aggregate_internal(aTHX_ im->ptr, im->type, mg->mg_obj, im->arena, true, im->readonly);
        if (SvROK(sv))
            sv_unref(sv);
        im->arena = nullptr;
        sv_setsv(sv, rv);
        SvREFCNT_dec(rv);
    }
    SvSMAGICAL_on(sv);
    return 0;
}

/**
 * @brief Performs deep writes to structs when a user assigns a hash (`$struct = { x => 1 }`).
 */
int lazy_agg_set(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    if (!im->ptr)
        return 0;
    SV * owner = mg->mg_obj;
    const infix_type * type = resolve_type(aTHX_ im->type);
    infix_type_category cat = infix_type_get_category(type);

    SvGMAGICAL_off(sv);
    SvSMAGICAL_off(sv);

    /* Support both the RV and the raw HV/AV (from the auto-sync loop) */
    SV * rv = SvROK(sv) ? SvRV(sv) : sv;

    if ((cat == INFIX_TYPE_STRUCT || cat == INFIX_TYPE_UNION) && SvTYPE(rv) == SVt_PVHV) {
        HV * user_hv = (HV *)rv;
        size_t count = infix_type_get_member_count(type);
        for (size_t i = 0; i < count; i++) {
            const infix_struct_member * m = infix_type_get_member(type, i);
            SV ** val_ptr = hv_fetch(user_hv, m->name ? m->name : "", strlen(m->name ? m->name : ""), 0);
            if (val_ptr && *val_ptr) {
                SV * temp = newSV(0);
                sv_setsv(temp, *val_ptr);
                bind_placeholder(aTHX_ temp,
                                 (char *)im->ptr + m->offset,
                                 m->type,
                                 +m->bit_offset,
                                 m->bit_width,
                                 false,
                                 owner,
                                 nullptr,
                                 im->readonly,
                                 false);
                SvGMAGICAL_off(temp);
                MAGIC * cmg = mg_find(temp, PERL_MAGIC_ext);
                if (cmg && cmg->mg_virtual && cmg->mg_virtual->svt_set)
                    cmg->mg_virtual->svt_set(aTHX_ temp, cmg);
                SvREFCNT_dec(temp);
                if (cat == INFIX_TYPE_UNION) {
                    /* Store the name of the active member in a hidden key */
                    hv_store(user_hv, "_active", 7, newSVpv(m->name, 0), 0);
                }
            }
        }
    }
    else if ((cat == INFIX_TYPE_ARRAY || cat == INFIX_TYPE_VECTOR || cat == INFIX_TYPE_COMPLEX) &&
             SvTYPE(rv) == SVt_PVAV) {
        AV * user_av = (AV *)rv;
        size_t max_len, step;
        const infix_type * el_type;
        if (cat == INFIX_TYPE_COMPLEX) {
            max_len = 2;
            el_type = type->meta.complex_info.base_type;
            step = el_type->size;
        }
        else if (cat == INFIX_TYPE_ARRAY) {
            max_len = type->meta.array_info.num_elements;
            el_type = type->meta.array_info.element_type;
            step = resolve_type(aTHX_ el_type)->size;
        }
        else {
            max_len = type->meta.vector_info.num_elements;
            el_type = type->meta.vector_info.element_type;
            step = el_type->size;
        }
        SSize_t user_len = av_len(user_av) + 1;
        size_t copy_len = ((size_t)user_len < max_len) ? (size_t)user_len : max_len;
        for (size_t i = 0; i < copy_len; i++) {
            SV ** val_ptr = av_fetch(user_av, i, 0);
            if (val_ptr && *val_ptr) {
                SV * temp = newSV(0);
                sv_setsv(temp, *val_ptr);
                bind_placeholder(aTHX_ temp,
                                 (char *)im->ptr + (i * step),
                                 el_type,
                                 0,
                                 0,
                                 false,
                                 owner,
                                 nullptr,
                                 im->readonly,
                                 false);
                SvGMAGICAL_off(temp);
                MAGIC * cmg = mg_find(temp, PERL_MAGIC_ext);
                if (cmg && cmg->mg_virtual && cmg->mg_virtual->svt_set)
                    cmg->mg_virtual->svt_set(aTHX_ temp, cmg);
                SvREFCNT_dec(temp);
            }
        }
    }
    SvGMAGICAL_on(sv);
    SvSMAGICAL_on(sv);
    return 0;
}

MGVTBL vtbl_lazy_aggregate = {lazy_agg_get, lazy_agg_set, nullptr, nullptr, free_v2_pin};

/**
 * @brief VTable GET handler for Enums (Dualvar creation)
 */
int get_enum(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    dMY_CXT;
    SvSMAGICAL_off(sv);

    if (!im->ptr) {
        sv_setsv(sv, &PL_sv_undef);
    }
    else {
        /* Resolve the Enum type itself */
        const infix_type * enum_type = resolve_type(aTHX_ im->type);
        /* Resolve the integer type inside the enum */
        const infix_type * underlying = resolve_type(aTHX_ enum_type->meta.enum_info.underlying_type);

        /* Read the raw integer value */
        IV val = 0;
        size_t sz = underlying->size;
        if (sz == 1)
            val = *(int8_t *)im->ptr;
        else if (sz == 2)
            val = *(int16_t *)im->ptr;
        else if (sz == 4)
            val = *(int32_t *)im->ptr;
        else
            val = *(int64_t *)im->ptr;

        /* Look for the name in the registry */
        const char * type_name = infix_type_get_name(im->type);
        if (!type_name && im->type->category == INFIX_TYPE_NAMED_REFERENCE)
            type_name = im->type->meta.named_reference.name;
        if (!type_name)
            type_name = infix_type_get_name(enum_type);
        if (type_name) {
            SV ** info_ptr = hv_fetch(MY_CXT.enum_registry, type_name, strlen(type_name), 0);
            if (info_ptr && SvROK(*info_ptr)) {
                HV * enum_info = (HV *)SvRV(*info_ptr);
                SV ** vals_ptr = hv_fetch(enum_info, "vals", 4, 0);
                if (vals_ptr && SvROK(*vals_ptr)) {
                    char key[32];
                    snprintf(key, sizeof(key), "%" IVdf, val);
                    SV ** name_sv = hv_fetch((HV *)SvRV(*vals_ptr), key, strlen(key), 0);

                    if (name_sv && SvPOK(*name_sv)) {
                        /* Create the Dualvar: Set String then force Integer bit */
                        sv_setpv(sv, SvPV_nolen(*name_sv));
                        SvUPGRADE(sv, SVt_PVIV);
                        SvIV_set(sv, val);
                        SvIOK_on(sv);
                        goto done;
                    }
                }
            }
        }
        /* Fallback: just a normal integer */
        sv_setiv(sv, val);
    }

done:
    SvSMAGICAL_on(sv);
    return 0;
}

/**
 * @brief VTable SET handler for Enums (Accepts names or integers)
 */
int set_enum(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");
    dMY_CXT;
    if (!im->ptr)
        return 0;

    SvGMAGICAL_off(sv);
    IV val = 0;

    if (SvPOK(sv) && !SvIOK(sv)) {
        const char * type_name = infix_type_get_name(im->type);
        if (!type_name && im->type->category == INFIX_TYPE_NAMED_REFERENCE)
            type_name = im->type->meta.named_reference.name;
        if (!type_name) {
            const infix_type * resolved = resolve_type(aTHX_ im->type);
            type_name = infix_type_get_name(resolved);
        }

        if (type_name) {
            SV ** info_ptr = hv_fetch(MY_CXT.enum_registry, type_name, strlen(type_name), 0);
            if (info_ptr && SvROK(*info_ptr)) {
                HV * enum_info = (HV *)SvRV(*info_ptr);
                SV ** consts_ptr = hv_fetch(enum_info, "consts", 6, 0);
                if (consts_ptr && SvROK(*consts_ptr)) {
                    STRLEN len;
                    const char * name = SvPV(sv, len);
                    SV ** val_sv = hv_fetch((HV *)SvRV(*consts_ptr), name, len, 0);
                    if (val_sv) {
                        val = SvIV(*val_sv);
                        goto do_write;
                    }
                }
            }
        }
    }
    val = SvIV(sv);

do_write:
    {
        const infix_type * enum_type = resolve_type(aTHX_ im->type);
        const infix_type * underlying = resolve_type(aTHX_ enum_type->meta.enum_info.underlying_type);
        size_t sz = underlying->size;
        if (sz == 1)
            *(int8_t *)im->ptr = (int8_t)val;
        else if (sz == 2)
            *(int16_t *)im->ptr = (int16_t)val;
        else if (sz == 4)
            *(int32_t *)im->ptr = (int32_t)val;
        else
            *(int64_t *)im->ptr = (int64_t)val;
    }
    SvGMAGICAL_on(sv);
    return 0;
}

/* Register the VTable */
MGVTBL vtbl_enum = {get_enum, set_enum, nullptr, nullptr, free_v2_pin};

int buffer_mg_get(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    const infix_type * t = resolve_type(aTHX_ im->type);
    /* For arrays, num_elements is our buffer size */
    size_t max_len = t->meta.array_info.num_elements;

    SvSMAGICAL_off(sv);
    if (!im->ptr) {
        sv_setsv(sv, &PL_sv_undef);
    }
    else {
        /* FIX: Use sv_setpvn to copy the full length, nulls and all */
        sv_setpvn(sv, (char *)im->ptr, max_len);
    }
    SvSMAGICAL_on(sv);
    return 0;
}

int buffer_mg_set(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
    if (im->readonly)
        croak("Modification of a read-only C value attempted");

    const infix_type * t = resolve_type(aTHX_ im->type);
    size_t max_len = t->meta.array_info.num_elements;

    if (!im->ptr || max_len == 0)
        return 0;

    SvGMAGICAL_off(sv);
    STRLEN len;
    char * str = SvPV(sv, len);

    /* Copy only what fits, but do NOT append a null terminator */
    size_t to_copy = (len < max_len) ? len : max_len;
    memcpy(im->ptr, str, to_copy);

    SvGMAGICAL_on(sv);
    return 0;
}

MGVTBL vtbl_buffer = {buffer_mg_get, buffer_mg_set, NULL, NULL, free_v2_pin};

/**
 * @brief Binds a single C value (primitive or placeholder) to a Perl SV with magic.
 * @param sv The Perl Scalar to bind.
 * @param ptr Pointer to the raw C memory.
 * @param type The infix_type definition.
 * @param bit_offset Offset in bits (for bitfields).
 * @param bit_width Width in bits (for bitfields).
 * @param prime If true, immediately synchronize the SV with C memory.
 * @param owner The "root" SV that owns the C memory (lifeline reference tracking).
 */
void bind_placeholder(pTHX_ SV * sv,
                      void * ptr,
                      const infix_type * type,
                      uint8_t bit_offset,
                      uint8_t bit_width,
                      bool prime,
                      SV * owner,
                      infix_arena_t * arena,
                      bool readonly,
                      bool absolute) {
    const infix_type * res = resolve_type(aTHX_ type);
    infix_type_category cat = infix_type_get_category(res);

    Affix_Pin_2_Point_Oh m = {.ptr = ptr,
                              .type = type,
                              .arena = arena,
                              .bit_offset = bit_offset,
                              .bit_width = bit_width,
                              .readonly = readonly,
                              .absolute = absolute,
                              .destructor = nullptr,
                              .destructor_lib_sv = nullptr};

    MGVTBL * v = nullptr;
    int is_wide = 0;

    if (bit_width > 0)
        v = &vtbl_bitfield;
    else if (cat == INFIX_TYPE_ENUM)
        v = &vtbl_enum;
    else if (cat == INFIX_TYPE_PRIMITIVE) {
        if (res->meta.primitive_id == INFIX_PRIMITIVE_SINT128)
            v = &vtbl_sint128;
        else if (res->meta.primitive_id == INFIX_PRIMITIVE_UINT128)
            v = &vtbl_uint128;
        else
            v = get_primitive_vtable(res);
    }
    else if (cat == INFIX_TYPE_POINTER || cat == INFIX_TYPE_REVERSE_TRAMPOLINE)
        v = &vtbl_pointer;
    else if (cat == INFIX_TYPE_VOID)
        v = &vtbl_void;
    else if (is_string_array(aTHX_ type, &is_wide)) {
        if (is_wide) {
            v = &wstring_vtable;
        }
        else {
            /* Resolve the element type to check signedness */
            const infix_type * el = resolve_type(aTHX_ type->meta.array_info.element_type);
            if (el->meta.primitive_id == INFIX_PRIMITIVE_UINT8)
                v = &vtbl_buffer; /* Array[UInt8] -> Binary */
            else
                v = &string_vtable; /* Array[Char] -> String */
        }
    }
    else
        v = &vtbl_lazy_aggregate;

    sv_magicext(sv, owner, PERL_MAGIC_ext, v, (char *)&m, sizeof(Affix_Pin_2_Point_Oh));
    SvMAGICAL_on(sv);
    SvGMAGICAL_on(sv);
    SvSMAGICAL_on(sv);

    /* FIX 3: Never prime a lazy aggregate placeholder; let it vivify on first use. */
    if (prime && v != &vtbl_lazy_aggregate && v != &vtbl_void)
        v->svt_get(aTHX_ sv, mg_find(sv, PERL_MAGIC_ext));
}

#define LAZY_ARRAY_THRESHOLD 100

/**
 * @brief Internal helper to build the actual Perl Hash/Array structure.
 * @param ptr   The raw C memory address (may be nullptr).
 * @param type  The infix_type definition.
 * @param owner The root SV lifeline.
 * @param arena The local arena for anonymous types (if any).
 * @param eager If false, large arrays return a magical scalar placeholder.
 * @param readonly If true, mutations via the resulting aggregate are blocked.
 */
static SV * _bind_aggregate_internal(
    pTHX_ void * ptr, const infix_type * type, SV * owner, infix_arena_t * arena, bool eager, bool readonly) {
    const infix_type * res = resolve_type(aTHX_ type);
    infix_type_category cat = infix_type_get_category(res);

    if (cat == INFIX_TYPE_STRUCT || cat == INFIX_TYPE_UNION) {
        HV * hv = newHV();
        Affix_Pin_2_Point_Oh m = {.ptr = ptr, .type = type, .arena = arena, .readonly = readonly};
        sv_magicext((SV *)hv, owner, PERL_MAGIC_ext, &vtbl_lazy_aggregate, (char *)&m, sizeof(Affix_Pin_2_Point_Oh));

        size_t count = infix_type_get_member_count(res);
        for (size_t i = 0; i < count; i++) {
            const infix_struct_member * m = infix_type_get_member(res, i);
            SV * v = newSV(0);
            /* Propagate nullptr safely so getters don't read from 0x0 + offset */
            void * child_ptr = ptr ? ((char *)ptr + m->offset) : nullptr;
            // Don't read the memory now. Wait until the user accesses the hash key.
            bind_placeholder(
                aTHX_ v, child_ptr, m->type, m->bit_offset, m->bit_width, false, (SV *)hv, NULL, readonly, false);
            hv_store(hv, m->name ? m->name : "", strlen(m->name ? m->name : ""), v, 0);
        }
        return newRV_noinc((SV *)hv);
    }
    else if (cat == INFIX_TYPE_ARRAY || cat == INFIX_TYPE_VECTOR || cat == INFIX_TYPE_COMPLEX) {
        if (is_string_array(aTHX_ type, nullptr)) {
            SV * sv = newSV(0);
            bind_placeholder(aTHX_ sv, ptr, type, 0, 0, true, owner, arena, readonly, false);
            /* WRAP IN REFERENCE to ensure magic persists across assignments */
            return newRV_noinc(sv);
        }

        size_t n, step;
        const infix_type * el_type;
        if (cat == INFIX_TYPE_COMPLEX) {
            n = 2;
            el_type = res->meta.complex_info.base_type;
            step = el_type->size;
        }
        else if (cat == INFIX_TYPE_ARRAY) {
            n = res->meta.array_info.num_elements;
            el_type = res->meta.array_info.element_type;
            step = resolve_type(aTHX_ el_type)->size;
        }
        else {
            n = res->meta.vector_info.num_elements;
            el_type = res->meta.vector_info.element_type;
            step = el_type->size;
        }

        if (!eager && n > LAZY_ARRAY_THRESHOLD) {
            SV * lazy_placeholder = newSV(0);
            bind_placeholder(aTHX_ lazy_placeholder, ptr, type, 0, 0, false, owner, arena, readonly, false);
            return lazy_placeholder;
        }

        AV * av = newAV();
        Affix_Pin_2_Point_Oh am = {.ptr = ptr, .type = type, .arena = arena, .readonly = readonly};
        sv_magicext((SV *)av, owner, PERL_MAGIC_ext, &vtbl_array, (char *)&am, sizeof(Affix_Pin_2_Point_Oh));

        for (size_t i = 0; i < n; i++) {
            SV * el = newSV(0);
            void * child_ptr = ptr ? ((char *)ptr + (i * step)) : nullptr;
            bind_placeholder(aTHX_ el, child_ptr, el_type, 0, 0, true, (SV *)av, nullptr, readonly, false);
            av_push(av, el);
        }
        return newRV_noinc((SV *)av);
    }
    return newSV(0);
}

/**
 * @brief Recursively constructs a Perl tree (Hash/Array) mapping to a C aggregate.
 * @param ptr Pointer to the raw C memory.
 * @param type The aggregate (struct/union/array) type.
 * @param owner The "root" SV that owns the C memory (lifeline).
 * @return A new reference to the constructed Perl aggregate.
 */
SV * bind_aggregate(pTHX_ void * ptr, const infix_type * type, SV * owner, bool readonly) {
    return _bind_aggregate_internal(aTHX_ ptr, type, owner, nullptr, false, readonly);
}

/**
 * @brief Public Strategy: Used by cast() to handle anonymous type lifecycle.
 */
SV * bind_aggregate_anon(pTHX_ void * ptr, const infix_type * type, SV * owner, infix_arena_t * arena, bool readonly) {
    return _bind_aggregate_internal(aTHX_ ptr, type, owner, arena, false, readonly);
}

/**
 * @brief Registers multiple types into the global Infix Type Registry.
 * @param defs The Infix type definition string.
 */
void define_types(pTHX_ const char * defs) {
    dMY_CXT;
    if (infix_register_types(MY_CXT.registry, defs) != INFIX_SUCCESS)
        croak("Parse Error");
}

/**
 * @brief Returns the layout size of a type by name.
 * @param name Type name or AST signature.
 * @return Size in bytes.
 */
IV sizeof_type(pTHX_ const char * name) {
    dMY_CXT;
    const infix_type * t = infix_registry_lookup_type(MY_CXT.registry, name);
    if (!t) {
        infix_arena_t * ta;
        infix_type * tt;
        if (infix_type_from_signature(&tt, &ta, name, MY_CXT.registry) == INFIX_SUCCESS) {
            size_t s = tt->size;
            infix_arena_destroy(ta);
            return s;
        }
    }
    return t ? t->size : 0;
}

/**
 * @brief Returns the byte offset of a member in a struct/union.
 * @param type_name The aggregate type name.
 * @param member_name The member field name.
 * @return Offset in bytes, or -1 if not found.
 */
IV offsetof_member(pTHX_ const char * type_name, const char * member_name) {
    dMY_CXT;
    const infix_type * t = resolve_type(aTHX_ infix_registry_lookup_type(MY_CXT.registry, type_name));
    if (!t || (t->category != INFIX_TYPE_STRUCT && t->category != INFIX_TYPE_UNION))
        return -1;
    for (size_t i = 0; i < t->meta.aggregate_info.num_members; i++)
        if (strEQ(t->meta.aggregate_info.members[i].name, member_name))
            return (IV)t->meta.aggregate_info.members[i].offset;
    return -1;
}

/**
 * @brief Casts a raw pointer (or memory block) to a magic-bound Perl variable mapping its layout.
 * @param in The input SV (integer address or Affix::Memory managed object).
 * @param name The struct or primitive type name to cast the memory into.
 * @return A magic-bound SV tracking the memory block natively.
 */
SV * cast(pTHX_ SV * in, const char * name) {
    dMY_CXT;
    void * addr = get_address_v2(aTHX_ in);
    if (!addr)
        return &PL_sv_undef;

    SV * owner = (SvROK(in) && sv_derived_from(in, "Affix::Memory")) ? SvRV(in) : nullptr;
    infix_type * new_type = nullptr;
    infix_arena_t * local_arena = nullptr;

    if (infix_type_from_signature(&new_type, &local_arena, name, MY_CXT.registry) != INFIX_SUCCESS)
        croak("Type not found: %s", name);

    const infix_type * resolved = resolve_type(aTHX_ new_type);
    infix_type_category cat = infix_type_get_category(resolved);

    /* AGGREGATES: Return a Reference (HashRef, ArrayRef, or ScalarRef for strings) */
    if (cat == INFIX_TYPE_STRUCT || cat == INFIX_TYPE_UNION || cat == INFIX_TYPE_ARRAY || cat == INFIX_TYPE_VECTOR ||
        cat == INFIX_TYPE_COMPLEX) {
        return bind_aggregate_anon(aTHX_ addr, new_type, owner, local_arena, false);
    }

    /* PRIMITIVES: Return a scalar reference ($$ptr) to allow writes back to C */
    SV * sv = newSV(0);
    bind_placeholder(aTHX_ sv, addr, new_type, 0, 0, true, owner, local_arena, false, true);
    return newRV_noinc(sv);
}

/**
 * @brief Wraps an existing C pointer with a custom destructor callback into an object payload.
 * @param ptr_iv The raw pointer (as integer).
 * @param dtor_iv The destructor callback pointer (as integer).
 * @return An Affix::Memory object representing the mapped block.
 */
SV * wrap_owned(pTHX_ UV ptr_uv, UV dtor_uv) {
    AV * av = newAV();
    av_push(av, newSVuv(ptr_uv));  /* Use UV */
    av_push(av, newSVuv(dtor_uv)); /* Use UV */
    SV * rv = newRV_noinc((SV *)av);
    sv_bless(rv, gv_stashpv("Affix::Memory", GV_ADD));
    return rv;
}
/**
 * @brief Allocates zeroed C memory and wraps it into a Perl Affix::Memory object.
 * @param size Memory allocation size in bytes.
 * @return An Affix::Memory object representation.
 */
SV * alloc_owned(pTHX_ UV size) {
    void * ptr = safecalloc(1, size);
    SV * sv = newSVuv(PTR2UV(ptr)); /* Use UV */
    SV * rv = newRV_noinc(sv);
    sv_bless(rv, gv_stashpv("Affix::Memory", GV_ADD));
    return rv;
}

/**
 * @brief Garbage Collector Hook: Frees C memory owned by an Affix::Memory object.
 * @details Can fall back to standard `safefree` or use a custom C++ destructor mapping if passed via `wrap_owned`.
 * @param rv The Affix::Memory reference triggered by DESTROY.
 */
void free_owned(pTHX_ SV * rv) {
    if (!rv || !SvROK(rv))
        return;
    SV * sv = SvRV(rv);
    if (SvTYPE(sv) == SVt_PVAV) {
        AV * av = (AV *)sv;
        SV ** r_ptr = av_fetch(av, 0, 0);
        SV ** r_dtor = av_fetch(av, 1, 0);
        if (r_ptr && *r_ptr && SvOK(*r_ptr)) {


            /* Use UV directly to bypass INT2PTR sign-extension bugs */
            UV raw_ptr = SvUV(*r_ptr);
            if (raw_ptr) {
                /* Zero the pointer immediately to prevent double-free or recursion */
                sv_setuv(*r_ptr, 0);

                if (r_dtor && *r_dtor && SvOK(*r_dtor)) {
                    UV raw_dtor = SvUV(*r_dtor);
                    if (raw_dtor) {
                        /* Explicit cast to function pointer */
                        typedef void (*dtor_t)(void *);
                        dtor_t custom_dtor = (dtor_t)raw_dtor;
                        custom_dtor((void *)raw_ptr);
                        return;
                    }
                }
                safefree((void *)raw_ptr);
            }
        }
    }
    /* Case 2: alloc_owned() stores ptr directly in a UV scalar */
    else if (SvOK(sv)) {
        UV raw_ptr = SvUV(sv);
        if (raw_ptr) {
            sv_setuv(sv, 0);
            safefree((void *)raw_ptr);
        }
    }
}

IV alloc_raw(pTHX_ IV sz) { return PTR2IV(safecalloc(1, sz)); }

void set_mem_u128(IV addr, IV l, IV h) {
    unsigned __int128 * p = (unsigned __int128 *)addr;
    *p = ((unsigned __int128)h << 64) | (unsigned __int128)l;
}

IV get_string_ptr() {
    static char * m = "Hello from C Pointer";
    return PTR2IV(m);
}

int test_invoke_callback(IV addr, int a, double b) {
    int (*f)(int, double) = (int (*)(int, double))addr;
    return f(a, b);
}

/**
 * @brief Verifies native callback invocation for 128-bit function pointers.
 */
SV * test_invoke_callback_128(pTHX_ IV addr, SV * arg_sv) {
    unsigned __int128 (*f)(__int128) = (unsigned __int128 (*)(__int128))addr;
    __int128 arg = (__int128)_alt_sv_to_int128(aTHX_ arg_sv);
    unsigned __int128 res = f(arg);
    SV * ret = newSV(0);
    alt_int128_to_sv(aTHX_ ret, res, false); /* Callback return value is uint128 */
    return ret;
}

IV get_file_ptr(pTHX_ SV * fh_ref) {
    IO * io = sv_2io(fh_ref);
    if (!io)
        return 0;
    return PTR2IV(PerlIO_exportFILE(IoIFP(io), nullptr));
}

typedef struct {
    unsigned __int128 val;
    int id;
} BigData;

void mutate_big_data_native(BigData * d) {
    d->val += 1; /* Add 1 to the 128-bit int natively */
    d->id = 777;
}

void verify_marshalling_128(pTHX_ SV * input) {
    dMY_CXT;
    const infix_type * type = infix_registry_lookup_type(MY_CXT.registry, "BigData");
    BigData stack_struct = {0, 0};
    if (SvROK(input)) {
        SV * proxy = newSV(0);
        sv_setsv(proxy, input);
        bind_placeholder(aTHX_ proxy, &stack_struct, type, 0, 0, false, nullptr, nullptr, false, false);
        MAGIC * mg = mg_find(proxy, PERL_MAGIC_ext);
        if (mg && mg->mg_virtual->svt_set)
            mg->mg_virtual->svt_set(aTHX_ proxy, mg);
        SvREFCNT_dec(proxy);
    }
    mutate_big_data_native(&stack_struct);
    if (SvROK(input)) {
        SV * proxy_rv = bind_aggregate(aTHX_ & stack_struct, type, nullptr, false);
        HV * target_hv = (HV *)SvRV(input);
        HV * source_hv = (HV *)SvRV(proxy_rv);
        hv_iterinit(source_hv);
        HE * entry;
        while ((entry = hv_iternext(source_hv))) {
            I32 klen;
            char * kstr = hv_iterkey(entry, &klen);
            SV * val = hv_iterval(source_hv, entry);
            hv_store(target_hv, kstr, klen, newSVsv(val), 0);
        }
        SvREFCNT_dec(proxy_rv);
    }
}

/*   Mock C++ Object For Custom Destructor Test   */
typedef struct {
    int value;
} MockCxxObj;

static int mock_cxx_dtor_calls = 0;

IV mock_cxx_new(int v) {
    MockCxxObj * obj = safemalloc(sizeof(MockCxxObj));
    obj->value = v;
    return PTR2IV(obj);
}

void mock_cxx_delete(void * ptr) {
    mock_cxx_dtor_calls++;
    safefree(ptr);
}

IV get_mock_cxx_dtor() { return PTR2IV(mock_cxx_delete); }
int get_mock_cxx_dtor_calls() { return mock_cxx_dtor_calls; }

XS_INTERNAL(XS_main_define_types) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "defs");
    define_types(aTHX_ SvPV_nolen(ST(0)));
    XSRETURN_EMPTY;
}

XS_INTERNAL(XS_main_sizeof_type) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "name");
    {
        const char * name = (const char *)SvPV_nolen(ST(0));
        IV RETVAL;
        dXSTARG;
        RETVAL = sizeof_type(aTHX_ name);
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_offsetof_member) {
    dVAR;
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "type_name, member_name");
    {
        const char * type_name = (const char *)SvPV_nolen(ST(0));
        const char * member_name = (const char *)SvPV_nolen(ST(1));
        IV RETVAL;
        dXSTARG;
        RETVAL = offsetof_member(aTHX_ type_name, member_name);
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_cast) {
    dVAR;
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "in, name");
    {
        SV * in = ST(0);
        const char * name = (const char *)SvPV_nolen(ST(1));
        SV * RETVAL;
        RETVAL = cast(aTHX_ in, name);
        RETVAL = sv_2mortal(RETVAL);
        ST(0) = RETVAL;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_free_owned) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "rv");
    SV * arg = ST(0);
    if (arg)
        free_owned(aTHX_ arg);
    XSRETURN_EMPTY;
}

XS_INTERNAL(XS_main_wrap_owned) {
    dVAR;
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "ptr_uv, dtor_uv");
    {
        UV ptr_uv = SvUV(ST(0)); /* Correct for high-bit addresses */
        UV dtor_uv = SvUV(ST(1));
        ST(0) = sv_2mortal(wrap_owned(aTHX_ ptr_uv, dtor_uv));
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_alloc_owned) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "size");
    {
        UV size = SvUV(ST(0));
        ST(0) = sv_2mortal(alloc_owned(aTHX_ size));
    }
    XSRETURN(1);
}
XS_INTERNAL(XS_main_alloc_raw) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "sz");
    {
        IV sz = (IV)SvIV(ST(0));
        IV RETVAL;
        dXSTARG;
        RETVAL = alloc_raw(aTHX_ sz);
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_set_mem_u128) {
    dVAR;
    dXSARGS;
    if (items != 3)
        croak_xs_usage(cv, "addr, l, h");
    set_mem_u128((IV)SvIV(ST(0)), (IV)SvIV(ST(1)), (IV)SvIV(ST(2)));
    XSRETURN_EMPTY;
}

XS_INTERNAL(XS_main_get_string_ptr) {
    dVAR;
    dXSARGS;
    if (items != 0)
        croak_xs_usage(cv, "");
    {
        IV RETVAL;
        dXSTARG;
        RETVAL = get_string_ptr();
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}
XS_INTERNAL(XS_main_test_invoke_callback) {
    dVAR;
    dXSARGS;
    if (items != 3)
        croak_xs_usage(cv, "addr, a, b");
    {
        IV addr = (IV)SvIV(ST(0));
        int a = (int)SvIV(ST(1));
        double b = (double)SvNV(ST(2));
        int RETVAL;
        dXSTARG;
        RETVAL = test_invoke_callback(addr, a, b);
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_test_invoke_callback_128) {
    dVAR;
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "addr, arg_sv");
    {
        IV addr = (IV)SvIV(ST(0));
        SV * arg_sv = ST(1);
        SV * RETVAL;
        RETVAL = test_invoke_callback_128(aTHX_ addr, arg_sv);
        RETVAL = sv_2mortal(RETVAL);
        ST(0) = RETVAL;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_get_file_ptr) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "fh_ref");
    {
        SV * fh_ref = ST(0);
        IV RETVAL;
        dXSTARG;
        RETVAL = get_file_ptr(aTHX_ fh_ref);
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}
XS_INTERNAL(XS_main_verify_marshalling_128) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "input");
    verify_marshalling_128(aTHX_ ST(0));
    XSRETURN_EMPTY;
}

XS_INTERNAL(XS_main_mock_cxx_new) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "v");
    {
        int v = (int)SvIV(ST(0));
        IV RETVAL;
        dXSTARG;
        RETVAL = mock_cxx_new(v);
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_get_mock_cxx_dtor) {
    dVAR;
    dXSARGS;
    if (items != 0)
        croak_xs_usage(cv, "");
    {
        IV RETVAL;
        dXSTARG;
        RETVAL = get_mock_cxx_dtor();
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

XS_INTERNAL(XS_main_mock_cxx_delete) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "ptr");
    mock_cxx_delete(INT2PTR(void *, SvIV(ST(0))));
    XSRETURN_EMPTY;
}

XS_INTERNAL(XS_main_get_mock_cxx_dtor_calls) {
    dVAR;
    dXSARGS;
    if (items != 0)
        croak_xs_usage(cv, "");
    {
        int RETVAL;
        dXSTARG;
        RETVAL = get_mock_cxx_dtor_calls();
        TARGi((IV)RETVAL, 1);
        ST(0) = TARG;
    }
    XSRETURN(1);
}

/**
 * @brief Helper to verify if a VTable belongs to the Affix system (v1 or v2).
 */
int is_v2_vtable(MGVTBL * v) {
    if (!v)
        return 0;
    return (v == &vtbl_sint8 || v == &vtbl_uint8 || v == &vtbl_sint16 || v == &vtbl_uint16 || v == &vtbl_sint32 ||
            v == &vtbl_uint32 || v == &vtbl_sint64 || v == &vtbl_uint64 || v == &vtbl_sint128 || v == &vtbl_uint128 ||
            v == &vtbl_float || v == &vtbl_double || v == &vtbl_float16 || v == &vtbl_bool || v == &vtbl_void ||
            v == &vtbl_bitfield || v == &vtbl_pointer || v == &vtbl_array || v == &string_vtable ||
            v == &wstring_vtable || v == &vtbl_lazy_aggregate || v == &vtbl_enum || v == &vtbl_buffer);
}

/**
 * @brief Internal helper to safely extract a pointer address from a Perl scalar.
 * @details This function handles Affix::Memory objects, v2.0 magical Pins, and
 * raw integers. It includes logic to handle Pointer[Void] correctly by
 * suppressing the dereference that is normally required for typed pointers.
 *
 * @param sv The Perl Scalar to inspect.
 * @param ignore_mg A specific magic pointer to skip (prevents self-extraction during assignment).
 * @return The raw C pointer address, or NULL if extraction fails.
 */
void * _extract_pointer_value(pTHX_ SV * sv, MAGIC * ignore_mg) {
    if (!sv)
        return nullptr;

    // Use a secondary pointer for unwrapping to preserve the original SV (the potential object)
    SV * target = sv;
    if (SvROK(sv))
        target = SvRV(sv);

    /* Handle Magic Pins (even inside blessed objects) */
    if (SvMAGICAL(target)) {
        MAGIC * mg = mg_find(target, PERL_MAGIC_ext);
        while (mg) {
            if (is_v2_vtable(mg->mg_virtual) && mg != ignore_mg) {
                Affix_Pin_2_Point_Oh * im = (Affix_Pin_2_Point_Oh *)mg->mg_ptr;
                if (mg->mg_virtual == &vtbl_pointer)
                    return im->absolute ? im->ptr : (im->ptr ? *(void **)im->ptr : nullptr);
                return im->ptr;
            }
            mg = mg->mg_moremagic;
        }
    }

    /* Handle Affix::Memory Handles */
    if (sv_isobject(sv) && sv_derived_from(sv, "Affix::Memory")) {
        SV * rv = SvRV(sv);
        if (SvTYPE(rv) == SVt_PVAV) {
            SV ** p = av_fetch((AV *)rv, 0, 0);
            return (p && *p) ? INT2PTR(void *, SvUV(*p)) : nullptr;
        }
        return INT2PTR(void *, SvUV(rv));
    }

    /* Fallback: Raw Integers */
    if (SvIOK(sv))
        return INT2PTR(void *, SvUV(sv));

    return nullptr;
}

/**
 * @brief The internal C function to extract a pointer from the 2.0 memory system.
 * @param sv The SV to inspect (Handle or Magical Variable).
 * @return The raw C pointer, or nullptr if not found.
 */
void * get_address_v2(pTHX_ SV * sv) { return _extract_pointer_value(aTHX_ sv, nullptr); }

/**
 * @brief Determines the underlying type for a pointer pin.
 * @details Prevents unwrapping char* (which should remain a string) but unwraps others
 * so that $$ptr reads the correct data type.
 */
const infix_type * _unwrap_pin_type(const infix_type * type) {
    if (type->category == INFIX_TYPE_POINTER) {
        const infix_type * pointee = type->meta.pointer_info.pointee_type;
        /* Do not unwrap char*; it's handled as a terminal String */
        if (pointee->category == INFIX_TYPE_PRIMITIVE && (pointee->meta.primitive_id <= INFIX_PRIMITIVE_UINT8))
            return type;
        /* Do not unwrap Void; we want Pointer[Void] pins for raw addresses */
        if (pointee->category == INFIX_TYPE_VOID)
            return type;
        return pointee;
    }
    return type;
}

/**
 * @brief Checks if a Perl Scalar is managed by the new 2.0 memory system.
 * @details This identifies SVs that are directly mapped to C memory via the
 * Affix_Pin_2_Point_Oh struct and its associated VTables or an Affix::Memory handle.
 * @param sv The Perl Scalar to check.
 * @return true if it is a v2.0 pin, false otherwise.
 */
bool is_pin_v2(pTHX_ SV * sv) {
    if (!sv)
        return false;
    if (sv_isobject(sv) && sv_derived_from(sv, "Affix::Memory"))
        return true;

    SV * target = (SvROK(sv) && !sv_isobject(sv)) ? SvRV(sv) : sv;
    if (SvMAGICAL(target)) {
        MAGIC * mg = mg_find(target, PERL_MAGIC_ext);

        while (mg) {
            if (is_v2_vtable(mg->mg_virtual))
                return true;
            mg = mg->mg_moremagic;
        }
    }
    return false;
}

/**
 * @brief Utility to extract the 2.0 pin payload from an SV.
 * @param sv The Perl Scalar.
 * @return Pointer to the Affix_Pin_2_Point_Oh struct, or nullptr if not a v2 pin.
 */
Affix_Pin_2_Point_Oh * get_pin_v2(pTHX_ SV * sv) {
    if (!is_pin_v2(aTHX_ sv))
        return nullptr;

    SV * target = SvROK(sv) ? SvRV(sv) : sv;
    if (!SvMAGICAL(target))
        return nullptr;

    MAGIC * mg = mg_find(target, PERL_MAGIC_ext);
    while (mg && !is_v2_vtable(mg->mg_virtual))
        mg = mg->mg_moremagic;

    return mg ? (Affix_Pin_2_Point_Oh *)mg->mg_ptr : nullptr;
}

/**
 * @brief Perl-level check for v2.0 magic-bound memory.
 * @usage Affix::is_pin($var)
 */
XS_INTERNAL(Affix_is_pin) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "sv");
    if (is_pin_v2(aTHX_ ST(0)))
        XSRETURN_YES;
    XSRETURN_NO;
}

/**
 * @brief Returns the raw memory address of a v2.0 pin as an integer.
 * @usage my $addr = Affix::address_v2($var);
 */
XS_INTERNAL(Affix_address) {
    dVAR;
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "pointer");

    void * addr = get_address_v2(aTHX_ ST(0));
    if (addr) {
        ST(0) = sv_2mortal(newSVuv(PTR2UV(addr)));
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}
