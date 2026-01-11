#include "Affix.h"

/*
|-------------------0----------------|--0---4----------------------------||
|.----------0---3-------0---3---0----|----------3---0-------0---3---0---.||
|.------2----------------------------|----------------------------------.||
|---3--------------------------------|------------------3----------------||
*/

// This will be moved somewhere else eventually...
#ifdef __SIZEOF_INT128__
#define sv_to_int128_safe(sv, ptr) *(__int128_t *)ptr = sv_to_int128(aTHX_ sv)
#define sv_to_uint128_safe(sv, ptr) *(__uint128_t *)ptr = sv_to_uint128(aTHX_ sv)
#define sv_from_int128_safe(targ, ptr) sv_setsv(targ, sv_2mortal(int128_to_sv(aTHX_ *(__int128_t *)ptr)))
#define sv_from_uint128_safe(targ, ptr) sv_setsv(targ, sv_2mortal(uint128_to_sv(aTHX_ *(__uint128_t *)ptr)))
static __int128_t sv_to_int128(pTHX_ SV * sv) {
    // If it's already an IV/NV, use that (fast path for small numbers)
    if (SvIOK(sv))
        return (__int128_t)SvIV(sv);
    if (SvNOK(sv))
        return (__int128_t)SvNV(sv);

    STRLEN len;
    const char * s = SvPV(sv, len);
    char * end;
    // Note: We assume base 10. Future me might implement a
    // custom parser here, but strtoll isn't enough either.
    __int128_t res = 0;
    int sign = 1;
    while (*s == ' ' || *s == '\t')
        s++;  // skip whitespace
    if (*s == '-') {
        sign = -1;
        s++;
    }
    else if (*s == '+')
        s++;
    while (*s >= '0' && *s <= '9') {
        res = res * 10 + (*s - '0');
        s++;
    }
    return res * sign;
}

static __uint128_t sv_to_uint128(pTHX_ SV * sv) {
    if (SvIOK(sv))
        return (__uint128_t)SvUV(sv);

    STRLEN len;
    const char * s = SvPV(sv, len);

    __uint128_t res = 0;
    while (*s == ' ' || *s == '\t')
        s++;
    if (*s == '+')
        s++;  // skip optional +

    while (*s >= '0' && *s <= '9') {
        res = res * 10 + (*s - '0');
        s++;
    }
    return res;
}

static SV * int128_to_sv(pTHX_ __int128_t val) {
    if (val == 0)
        return newSVpvs("0");

    char buf[64];  // Max 128-bit int is ~39 digits
    char * p = buf + 63;
    *p = '\0';

    bool neg = val < 0;
    unsigned __int128 uval = neg ? -(unsigned __int128)val : (unsigned __int128)val;

    while (uval > 0) {
        *--p = (char)((uval % 10) + '0');
        uval /= 10;
    }
    if (neg)
        *--p = '-';

    return newSVpv(p, 0);
}

static SV * uint128_to_sv(pTHX_ __uint128_t val) {
    if (val == 0)
        return newSVpvs("0");

    char buf[64];
    char * p = buf + 63;
    *p = '\0';

    while (val > 0) {
        *--p = (char)((val % 10) + '0');
        val /= 10;
    }
    return newSVpv(p, 0);
}
#else
#define sv_to_int128_safe(sv, ptr) croak("128-bit not supported")
#define sv_to_uint128_safe(sv, ptr) croak("128-bit not supported")
#define sv_from_int128_safe(targ, ptr) croak("128-bit not supported")
#define sv_from_uint128_safe(targ, ptr) croak("128-bit not supported")
#endif

// Handles thread cloning for pins. Deep copies metadata and managed memory
static int Affix_pin_dup(pTHX_ MAGIC * mg, CLONE_PARAMS * param) {
    PERL_UNUSED_VAR(param);
    Affix_Pin * old_pin = (Affix_Pin *)mg->mg_ptr;

    if (!old_pin)
        return 0;

    Affix_Pin * new_pin;
    Newxz(new_pin, 1, Affix_Pin);

    // Copy metadata
    new_pin->size = old_pin->size;
    new_pin->managed = old_pin->managed;

    // Handle data ownership
    if (old_pin->managed && old_pin->pointer && old_pin->size > 0) {
        // Deep copy managed memory so new thread owns its own block.
        // This prevents double-free and context violations.
        new_pin->pointer = safemalloc(new_pin->size);
        memcpy(new_pin->pointer, old_pin->pointer, new_pin->size);
    }
    else
        // Unmanaged/Global/Null: Shallow copy pointer.
        new_pin->pointer = old_pin->pointer;

    // Handle type arena (Deep Copy)
    if (old_pin->type_arena && old_pin->type) {
        new_pin->type_arena = infix_arena_create(4096);
        new_pin->type = _copy_type_graph_to_arena(new_pin->type_arena, old_pin->type);
    }
    else {
        // Likely a raw void* or simple cast where arena wasn't used/needed
        new_pin->type = old_pin->type;
        new_pin->type_arena = nullptr;
    }
    mg->mg_ptr = (char *)new_pin;
    return 0;
}

// Handles UTF-16LE (Windows) and UTF-32 (Linux/Mac) conversion to UTF-8 SV
static void pull_pointer_as_wstring(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    PERL_UNUSED_VAR(affix);
    PERL_UNUSED_VAR(type);

    wchar_t * wstr = *(wchar_t **)ptr;

    if (wstr == nullptr) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    // Calculate length (like wcslen)
    size_t wlen = 0;
    while (wstr[wlen])
        wlen++;

    // Pre-allocate SV buffer.
    // Worst case UTF-8 expansion: 1 wchar (4 bytes) -> 4 UTF-8 bytes.
    // +1 for null terminator.
    SvGROW(sv, (wlen * sizeof(wchar_t)) + 1);

    char * d = SvPVX(sv);
    wchar_t * s = wstr;

    while (*s) {
        UV uv = (UV)*s++;

        // Handle Windows Surrogate Pairs (UTF-16LE)
        if (sizeof(wchar_t) == 2 && uv >= 0xD800 && uv <= 0xDBFF) {
            if (*s >= 0xDC00 && *s <= 0xDFFF) {
                UV low = (UV)*s++;
                uv = ((uv - 0xD800) << 10) + (low - 0xDC00) + 0x10000;
            }
        }

        d = (char *)uvchr_to_utf8((U8 *)d, uv);
    }
    *d = 0;

    // Set Perl SV properties
    SvCUR_set(sv, d - SvPVX(sv));
    SvPOK_on(sv);
    SvUTF8_on(sv);
}

// Direct marshalling experiment
// Forward declarations for static helpers
static infix_direct_value_t affix_marshaller_sint(void * sv_raw);
static infix_direct_value_t affix_marshaller_uint(void * sv_raw);
static infix_direct_value_t affix_marshaller_double(void * sv_raw);
static infix_direct_value_t affix_marshaller_pointer(void * sv_raw);
static void affix_aggregate_marshaller(void * sv_raw, void * dest, const infix_type * type);
static void affix_aggregate_writeback(void * sv_raw, void * src, const infix_type * type);
static infix_direct_arg_handler_t get_direct_handler_for_type(const infix_type * type);

void Affix_trigger_backend(pTHX_ CV * cv) {
    dSP;
    dAXMARK;
    dXSTARG;

    Affix_Backend * backend = (Affix_Backend *)CvXSUBANY(cv).any_ptr;

    if (UNLIKELY((SP - MARK) != backend->num_args))
        croak("Wrong number of arguments to affixed function. Expected %" UVuf ", got %" UVuf,
              (UV)backend->num_args,
              (UV)(SP - MARK));

    void * ret_buffer = alloca(infix_type_get_size(backend->ret_type));
    SV ** perl_stack_frame = &ST(0);

    backend->cif(ret_buffer, (void **)perl_stack_frame);

    switch (backend->ret_opcode) {
    case OP_RET_VOID:
        sv_setsv(TARG, &PL_sv_undef);
        break;
    case OP_RET_BOOL:
        sv_setbool(TARG, *(bool *)ret_buffer);
        break;
    case OP_RET_SINT8:
        sv_setiv(TARG, *(int8_t *)ret_buffer);
        break;
    case OP_RET_UINT8:
        sv_setuv(TARG, *(uint8_t *)ret_buffer);
        break;
    case OP_RET_SINT16:
        sv_setiv(TARG, *(int16_t *)ret_buffer);
        break;
    case OP_RET_UINT16:
        sv_setuv(TARG, *(uint16_t *)ret_buffer);
        break;
    case OP_RET_SINT32:
        sv_setiv(TARG, *(int32_t *)ret_buffer);
        break;
    case OP_RET_UINT32:
        sv_setuv(TARG, *(uint32_t *)ret_buffer);
        break;
    case OP_RET_SINT64:
        sv_setiv(TARG, *(int64_t *)ret_buffer);
        break;
    case OP_RET_UINT64:
        sv_setuv(TARG, *(uint64_t *)ret_buffer);
        break;
    case OP_RET_FLOAT:
        sv_setnv(TARG, (double)*(float *)ret_buffer);
        break;
    case OP_RET_DOUBLE:
        sv_setnv(TARG, *(double *)ret_buffer);
        break;
    case OP_RET_PTR_CHAR:
        {
            char * p = *(char **)ret_buffer;
            if (p)
                sv_setpv(TARG, p);
            else
                sv_setsv(TARG, &PL_sv_undef);
            break;
        }
    case OP_RET_PTR_WCHAR:
        pull_pointer_as_wstring(aTHX_ nullptr, TARG, backend->ret_type, ret_buffer);
        break;
    case OP_RET_SV:
        {
            SV * s = *(SV **)ret_buffer;
            if (s)
                sv_setsv(TARG, s);
            else
                sv_setsv(TARG, &PL_sv_undef);
            break;
        }
    case OP_RET_CUSTOM:
    default:
        backend->pull_handler(aTHX_ nullptr, TARG, backend->ret_type, ret_buffer);
        break;
    }

    ST(0) = TARG;
    PL_stack_sp = PL_stack_base + ax;
}

static infix_direct_value_t affix_marshaller_sint(void * sv_raw) {
    dTHX;
    infix_direct_value_t val;
    val.i64 = SvIV((SV *)sv_raw);
    return val;
}

static infix_direct_value_t affix_marshaller_uint(void * sv_raw) {
    dTHX;
    infix_direct_value_t val;
    val.u64 = SvUV((SV *)sv_raw);
    return val;
}

static infix_direct_value_t affix_marshaller_double(void * sv_raw) {
    infix_direct_value_t val;
    SV * sv = (SV *)sv_raw;
    U32 flags = SvFLAGS(sv);

    if (LIKELY(flags & SVf_NOK)) {
        val.f64 = SvNVX(sv);
    }
    else if (flags & SVf_IOK) {
        if (flags & SVf_IVisUV)
            val.f64 = (double)SvUVX(sv);
        else
            val.f64 = (double)SvIVX(sv);
    }
    else {
        dTHX;
        val.f64 = (double)SvNV(sv);
    }
    return val;
}

static infix_direct_value_t affix_marshaller_pointer(void * sv_raw) {
    dTHX;
    infix_direct_value_t val;
    SV * sv = (SV *)sv_raw;
    if (is_pin(aTHX_ sv))
        val.ptr = _get_pin_from_sv(aTHX_ sv)->pointer;
    else if (SvPOK(sv))
        val.ptr = (void *)SvPV_nolen(sv);
    else if (!SvOK(sv))
        val.ptr = nullptr;
    else
        val.ptr = INT2PTR(void *, SvIV(SvRV(sv)));
    return val;
}

static void affix_aggregate_marshaller(void * sv_raw, void * dest_buffer, const infix_type * type) {
    dTHX;
    // This ensures optional fields and padding are 0.
    memset(dest_buffer, 0, infix_type_get_size(type));
    SV * sv = (SV *)sv_raw;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        return;
    HV * hv = (HV *)SvRV(sv);
    for (size_t i = 0; i < infix_type_get_member_count(type); ++i) {
        const infix_struct_member * member = infix_type_get_member(type, i);
        if (member->name) {
            SV ** member_sv_ptr = hv_fetch(hv, member->name, strlen(member->name), 0);
            if (member_sv_ptr) {
                void * member_ptr = (char *)dest_buffer + member->offset;
                sv2ptr(aTHX_ nullptr, *member_sv_ptr, member_ptr, member->type);
            }
        }
    }
}

static void affix_aggregate_writeback(void * sv_raw, void * src_buffer, const infix_type * type) {
    dTHX;
    SV * sv = (SV *)sv_raw;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV)
        return;

    HV * hv = (HV *)SvRV(sv);
    for (size_t i = 0; i < infix_type_get_member_count(type); ++i) {
        const infix_struct_member * member = infix_type_get_member(type, i);
        if (member->name) {
            void * member_ptr = (char *)src_buffer + member->offset;
            SV * member_sv = newSV(0);
            ptr2sv(aTHX_ nullptr, member_ptr, member_sv, member->type);
            hv_store(hv, member->name, strlen(member->name), member_sv, 0);
        }
    }
}

static void affix_array_writeback(pTHX_ Affix * affix, const OutParamInfo * info, SV * perl_sv, void * c_arg_ptr) {
    AV * av = NULL;

    // The XSUB unwraps references, so perl_sv might BE the AV.
    if (SvTYPE(perl_sv) == SVt_PVAV)
        av = (AV *)perl_sv;
    // Just in case it's still wrapped (e.g. nested refs)
    else if (SvROK(perl_sv) && SvTYPE(SvRV(perl_sv)) == SVt_PVAV)
        av = (AV *)SvRV(perl_sv);
    else
        return;

    void * data_ptr = *(void **)c_arg_ptr;
    if (!data_ptr)
        return;

    const infix_type * type = info->pointee_type;
    const infix_type * element_type = type->meta.array_info.element_type;
    size_t element_size = infix_type_get_size(element_type);
    size_t count = av_len(av) + 1;

    for (size_t i = 0; i < count; ++i) {
        void * elem_src = (char *)data_ptr + (i * element_size);
        SV * sv = newSV(0);
        ptr2sv(aTHX_ affix, elem_src, sv, element_type);
        av_store(av, i, sv);
    }
}

static infix_direct_arg_handler_t get_direct_handler_for_type(const infix_type * type) {
    infix_direct_arg_handler_t h = {0};
    switch (type->category) {
    case INFIX_TYPE_PRIMITIVE:
        if (is_float(type) || is_double(type))
            h.scalar_marshaller = &affix_marshaller_double;
        else if (type->meta.primitive_id <= INFIX_PRIMITIVE_SINT128)
            h.scalar_marshaller = &affix_marshaller_sint;
        else
            h.scalar_marshaller = &affix_marshaller_uint;
        break;
    case INFIX_TYPE_POINTER:
        {
            const infix_type * pointee = type->meta.pointer_info.pointee_type;
            if (pointee->category == INFIX_TYPE_STRUCT || pointee->category == INFIX_TYPE_UNION) {
                h.aggregate_marshaller = &affix_aggregate_marshaller;
                h.writeback_handler = &affix_aggregate_writeback;
            }
            else
                h.scalar_marshaller = &affix_marshaller_pointer;
            break;
        }
    case INFIX_TYPE_STRUCT:
    case INFIX_TYPE_UNION:
        h.aggregate_marshaller = &affix_aggregate_marshaller;
        break;
    default:
        h.aggregate_marshaller = &affix_aggregate_marshaller;
        break;
    }
    return h;
}

static const infix_type * _unwrap_pin_type(const infix_type * type) {
    if (type->category == INFIX_TYPE_POINTER) {
        const infix_type * pointee = type->meta.pointer_info.pointee_type;
        // SPECIAL CASE: Do NOT unwrap char* (Pointer[Int8]).
        if (pointee->category == INFIX_TYPE_PRIMITIVE &&
            (pointee->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
             pointee->meta.primitive_id == INFIX_PRIMITIVE_UINT8)) {
            return type;
        }
        if (pointee->category != INFIX_TYPE_VOID)
            return pointee;
    }
    return type;
}

static const char * _get_string_from_type_obj(pTHX_ SV * type_sv) {
    const char * str = nullptr;
    if (sv_isobject(type_sv) && sv_derived_from(type_sv, "Affix::Type")) {
        if (SvROK(type_sv)) {
            SV * rv = SvRV(type_sv);
            if (SvTYPE(rv) == SVt_PVHV) {
                HV * hv = (HV *)rv;
                SV ** stringify_sv_ptr = hv_fetchs(hv, "stringify", 0);
                if (stringify_sv_ptr && SvPOK(*stringify_sv_ptr))
                    str = SvPV_nolen(*stringify_sv_ptr);
            }
        }
    }
    if (!str)
        str = SvPV_nolen(type_sv);

    // Promote "SV" to "@SV" so the parser sees it as a named type.
    // This allows the infix parser to recognize it as a named type.
    if (str && strstr(str, "SV")) {
        SV * modified = sv_newmortal();
        sv_setpvn(modified, "", 0);

        const char * p = str;
        const char * start = str;
        while ((p = strstr(p, "SV"))) {
            // Check boundaries: Ensure we match whole word "SV"
            // Start boundary: Beginning of string OR prev char is not alnum/_/@
            bool start_ok = (p == start) || (!isALNUM((unsigned char)*(p - 1)) && *(p - 1) != '_' && *(p - 1) != '@');

            // End boundary: End of string OR next char is not alnum/_
            bool end_ok = (p[2] == '\0') || (!isALNUM((unsigned char)p[2]) && p[2] != '_');

            if (start_ok && end_ok) {
                // Append everything before this match
                sv_catpvn(modified, start, p - start);
                // Append the named type reference
                sv_catpvs(modified, "@SV");
                // Advance past "SV"
                p += 2;
                start = p;
            }
            else  // Not a standalone "SV", skip this occurrence
                p++;
        }
        // Append remainder
        sv_catpv(modified, start);

        // Only return modified string if we actually changed something
        if (SvCUR(modified) > strlen(str))
            return SvPV_nolen(modified);
    }
    return str;
}

int64_t affix_perl_shim_sv_to_sint64(pTHX_ void * sv_raw) { return SvIVX((SV *)sv_raw); }
double affix_perl_shim_sv_to_double(pTHX_ void * sv_raw) { return SvNVX((SV *)sv_raw); }
const char * affix_perl_shim_sv_to_string(pTHX_ void * sv_raw) { return SvPV_nolen((SV *)sv_raw); }
void * affix_perl_shim_sv_to_pointer(pTHX_ void * sv_raw) {
    SV * sv = (SV *)sv_raw;
    if (!SvOK(sv) || !SvROK(sv))
        return nullptr;
    return INT2PTR(void *, SvIV(SvRV(sv)));
}

void * affix_perl_shim_newSViv(pTHX_ int64_t value) { return newSViv(value); }
void * affix_perl_shim_newSVnv(pTHX_ double value) { return newSVnv(value); }
void * affix_perl_shim_newSVpv(pTHX_ const char * value) { return newSVpv(value, 0); }

static int Affix_get_pin(pTHX_ SV * sv, MAGIC * mg);
static int Affix_set_pin(pTHX_ SV * sv, MAGIC * mg);
static U32 Affix_len_pin(pTHX_ SV * sv, MAGIC * mg);
static int Affix_free_pin(pTHX_ SV * sv, MAGIC * mg);
void _pin_sv(pTHX_ SV * sv, const infix_type * type, void * pointer, bool managed);

static void push_union(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p);

// Execution plan for mainline Affix
static void plan_step_push_bool(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_sint8(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_uint8(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_sint16(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_uint16(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_sint32(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_uint32(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_sint64(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_uint64(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_float(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_double(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_long_double(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
#if !defined(INFIX_COMPILER_MSVC)
static void plan_step_push_sint128(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_uint128(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
#endif
static void plan_step_push_pointer(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_struct(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_union(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_array(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_enum(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_complex(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_vector(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_sv(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);
static void plan_step_push_callback(pTHX_ Affix *, Affix_Plan_Step *, SV **, void *, void **, void *);

static void push_handler_bool(pTHX_ Affix *, SV *, void *);
static void push_handler_sint8(pTHX_ Affix *, SV *, void *);
static void push_handler_uint8(pTHX_ Affix *, SV *, void *);
static void push_handler_sint16(pTHX_ Affix *, SV *, void *);
static void push_handler_uint16(pTHX_ Affix *, SV *, void *);
static void push_handler_sint32(pTHX_ Affix *, SV *, void *);
static void push_handler_uint32(pTHX_ Affix *, SV *, void *);
static void push_handler_sint64(pTHX_ Affix *, SV *, void *);
static void push_handler_uint64(pTHX_ Affix *, SV *, void *);
static void push_handler_float(pTHX_ Affix *, SV *, void *);
static void push_handler_double(pTHX_ Affix *, SV *, void *);
static void push_handler_long_double(pTHX_ Affix *, SV *, void *);

static void pull_sint8(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_uint8(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_sint16(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_uint16(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_sint32(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_uint32(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_sint64(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_uint64(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_float(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_double(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_long_double(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_bool(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_void(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_struct(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_union(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_array(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_enum(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_enum_dualvar(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_complex(pTHX_ Affix *, SV *, const infix_type *, void * p);
static void pull_vector(pTHX_ Affix *, SV *, const infix_type *, void * p);
static void pull_pointer(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_pointer_as_string(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_pointer_as_struct(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_pointer_as_array(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_pointer_as_pin(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_sv(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_reverse_trampoline(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_file(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_perlio(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_stringlist(pTHX_ Affix *, SV *, const infix_type *, void *);
#if !defined(INFIX_COMPILER_MSVC)
static void pull_sint128(pTHX_ Affix *, SV *, const infix_type *, void *);
static void pull_uint128(pTHX_ Affix *, SV *, const infix_type *, void *);
#endif

#define DEFINE_PUSH_PRIMITIVE_EXECUTOR(name, c_type, sv_accessor)         \
    static void plan_step_push_##name(pTHX_ Affix * affix,                \
                                      Affix_Plan_Step * step,             \
                                      SV ** perl_stack_frame,             \
                                      void * args_buffer,                 \
                                      void ** c_args,                     \
                                      void * ret_buffer) {                \
        PERL_UNUSED_VAR(affix);                                           \
        PERL_UNUSED_VAR(ret_buffer);                                      \
        SV * sv = perl_stack_frame[step->data.index];                     \
        void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset; \
        *(c_type *)c_arg_ptr = (c_type)sv_accessor(sv);                   \
        c_args[step->data.index] = c_arg_ptr;                             \
    }

#define DEFINE_IV_PUSH_HANDLER(name, c_type)                                      \
    static void push_handler_##name(pTHX_ Affix * affix, SV * sv, void * c_ptr) { \
        PERL_UNUSED_VAR(affix);                                                   \
        U32 flags = SvFLAGS(sv);                                                  \
        if (flags & SVf_IOK) {                                                    \
            if (flags & SVf_IVisUV)                                               \
                *(c_type *)c_ptr = (c_type)SvUVX(sv);                             \
            else                                                                  \
                *(c_type *)c_ptr = (c_type)SvIVX(sv);                             \
        }                                                                         \
        else {                                                                    \
            dTHX;                                                                 \
            *(c_type *)c_ptr = (c_type)SvIV(sv);                                  \
        }                                                                         \
        return;                                                                   \
    }

#define DEFINE_UV_PUSH_HANDLER(name, c_type)                                      \
    static void push_handler_##name(pTHX_ Affix * affix, SV * sv, void * c_ptr) { \
        PERL_UNUSED_VAR(affix);                                                   \
        U32 flags = SvFLAGS(sv);                                                  \
        if (flags & SVf_IOK) {                                                    \
            if (flags & SVf_IVisUV)                                               \
                *(c_type *)c_ptr = (c_type)SvUVX(sv);                             \
            else                                                                  \
                *(c_type *)c_ptr = (c_type)SvIVX(sv);                             \
        }                                                                         \
        else {                                                                    \
            dTHX;                                                                 \
            *(c_type *)c_ptr = (c_type)SvUV(sv);                                  \
        }                                                                         \
        return;                                                                   \
    }

#define DEFINE_NV_PUSH_HANDLER(name, c_type)                                      \
    static void push_handler_##name(pTHX_ Affix * affix, SV * sv, void * c_ptr) { \
        PERL_UNUSED_VAR(affix);                                                   \
        U32 flags = SvFLAGS(sv);                                                  \
        if (LIKELY(flags & SVf_NOK))                                              \
            *(c_type *)c_ptr = SvNVX(sv);                                         \
        else if (flags & SVf_IOK) {                                               \
            if (flags & SVf_IVisUV)                                               \
                *(c_type *)c_ptr = (c_type)SvUVX(sv);                             \
            else                                                                  \
                *(c_type *)c_ptr = (c_type)SvIVX(sv);                             \
        }                                                                         \
        else {                                                                    \
            dTHX;                                                                 \
            *(c_type *)c_ptr = (c_type)SvNV(sv);                                  \
        }                                                                         \
        return;                                                                   \
    }

static Affix_Opcode get_opcode_for_type(const infix_type * type) {
    switch (type->category) {
    case INFIX_TYPE_PRIMITIVE:
        switch (type->meta.primitive_id) {
        case INFIX_PRIMITIVE_BOOL:
            return OP_PUSH_BOOL;
        case INFIX_PRIMITIVE_SINT8:
            return OP_PUSH_SINT8;
        case INFIX_PRIMITIVE_UINT8:
            return OP_PUSH_UINT8;
        case INFIX_PRIMITIVE_SINT16:
            return OP_PUSH_SINT16;
        case INFIX_PRIMITIVE_UINT16:
            return OP_PUSH_UINT16;
        case INFIX_PRIMITIVE_SINT32:
            return OP_PUSH_SINT32;
        case INFIX_PRIMITIVE_UINT32:
            return OP_PUSH_UINT32;
        case INFIX_PRIMITIVE_SINT64:
            return OP_PUSH_SINT64;
        case INFIX_PRIMITIVE_UINT64:
            return OP_PUSH_UINT64;
        case INFIX_PRIMITIVE_FLOAT:
            return OP_PUSH_FLOAT;
        case INFIX_PRIMITIVE_DOUBLE:
            return OP_PUSH_DOUBLE;
        case INFIX_PRIMITIVE_LONG_DOUBLE:
            return OP_PUSH_LONGDOUBLE;
#ifdef __SIZEOF_INT128__
        case INFIX_PRIMITIVE_SINT128:
            return OP_PUSH_SINT128;
        case INFIX_PRIMITIVE_UINT128:
            return OP_PUSH_UINT128;
#endif
        default:
            return OP_PUSH_SINT32;  // Fallback
        }
    case INFIX_TYPE_POINTER:
        {
            const char * name = infix_type_get_name(type);
            // Check for SV* itself
            if (name && (strEQ(name, "SV") || strEQ(name, "@SV")))
                return OP_PUSH_SV;

            const infix_type * pointee = type->meta.pointer_info.pointee_type;
            const char * pointee_name = infix_type_get_name(pointee);
            // Check for Pointer to SV
            if (pointee_name && (strEQ(pointee_name, "SV") || strEQ(pointee_name, "@SV")))
                return OP_PUSH_SV;

            if (pointee->category == INFIX_TYPE_PRIMITIVE) {
                if (pointee->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                    pointee->meta.primitive_id == INFIX_PRIMITIVE_UINT8)
                    return OP_PUSH_PTR_CHAR;
#if defined(INFIX_OS_WINDOWS)
                // Note: This treats any pointer to 2-byte primitive as potential WString on Windows
                if (infix_type_get_size(pointee) == sizeof(wchar_t))
                    return OP_PUSH_PTR_WCHAR;
#endif
            }
            return OP_PUSH_POINTER;
        }
    case INFIX_TYPE_VECTOR:
        return OP_PUSH_VECTOR;
    case INFIX_TYPE_STRUCT:
        {
            const char * name = infix_type_get_name(type);
            if (name && (strEQ(name, "SV") || strEQ(name, "@SV")))
                croak("Type 'SV' cannot be passed by value. Use 'Pointer[SV]' instead.");
            return OP_PUSH_STRUCT;
        }
    case INFIX_TYPE_UNION:
        return OP_PUSH_UNION;
    case INFIX_TYPE_ARRAY:
        return OP_PUSH_ARRAY;
    case INFIX_TYPE_ENUM:
        return OP_PUSH_ENUM;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        return OP_PUSH_CALLBACK;
    default:
        return OP_PUSH_STRUCT;
    }
}

static Affix_Opcode get_ret_opcode_for_type(const infix_type * type) {
    if (type->category == INFIX_TYPE_VOID)
        return OP_RET_VOID;

    if (type->category == INFIX_TYPE_PRIMITIVE) {
        switch (type->meta.primitive_id) {
        case INFIX_PRIMITIVE_BOOL:
            return OP_RET_BOOL;
        case INFIX_PRIMITIVE_SINT8:
            return OP_RET_SINT8;
        case INFIX_PRIMITIVE_UINT8:
            return OP_RET_UINT8;
        case INFIX_PRIMITIVE_SINT16:
            return OP_RET_SINT16;
        case INFIX_PRIMITIVE_UINT16:
            return OP_RET_UINT16;
        case INFIX_PRIMITIVE_SINT32:
            return OP_RET_SINT32;
        case INFIX_PRIMITIVE_UINT32:
            return OP_RET_UINT32;
        case INFIX_PRIMITIVE_SINT64:
            return OP_RET_SINT64;
        case INFIX_PRIMITIVE_UINT64:
            return OP_RET_UINT64;
        case INFIX_PRIMITIVE_FLOAT:
            return OP_RET_FLOAT;
        case INFIX_PRIMITIVE_DOUBLE:
            return OP_RET_DOUBLE;
#ifdef __SIZEOF_INT128__
        case INFIX_PRIMITIVE_SINT128:
            return OP_RET_SINT128;
        case INFIX_PRIMITIVE_UINT128:
            return OP_RET_UINT128;
#endif
        default:
            break;
        }
    }

    if (type->category == INFIX_TYPE_POINTER) {
        const char * name = infix_type_get_name(type);
        if (name && (strEQ(name, "SV") || strEQ(name, "@SV")))
            return OP_RET_SV;

        const infix_type * pointee = type->meta.pointer_info.pointee_type;
        const char * pointee_name = infix_type_get_name(pointee);
        if (pointee_name && (strEQ(pointee_name, "SV") || strEQ(pointee_name, "@SV")))
            return OP_RET_SV;

        if (pointee->category == INFIX_TYPE_PRIMITIVE) {
            if (pointee->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                pointee->meta.primitive_id == INFIX_PRIMITIVE_UINT8) {
                return OP_RET_PTR_CHAR;
            }
#if defined(INFIX_OS_WINDOWS)
            if (infix_type_get_size(pointee) == sizeof(wchar_t))
                return OP_RET_PTR_WCHAR;
#endif
        }
    }

    if (type->category == INFIX_TYPE_STRUCT) {
        const char * name = infix_type_get_name(type);
        if (name && (strEQ(name, "SV") || strEQ(name, "@SV")))
            croak("Type 'SV' cannot be returned by value. Use 'Pointer[SV]' instead.");
    }

    return OP_RET_CUSTOM;
}

DEFINE_IV_PUSH_HANDLER(sint8, int8_t)
DEFINE_UV_PUSH_HANDLER(uint8, uint8_t)
DEFINE_IV_PUSH_HANDLER(sint16, int16_t)
DEFINE_UV_PUSH_HANDLER(uint16, uint16_t)
DEFINE_IV_PUSH_HANDLER(sint32, int32_t)
DEFINE_UV_PUSH_HANDLER(uint32, uint32_t)
DEFINE_IV_PUSH_HANDLER(sint64, int64_t)
DEFINE_UV_PUSH_HANDLER(uint64, uint64_t)
DEFINE_NV_PUSH_HANDLER(float, float);
DEFINE_NV_PUSH_HANDLER(double, double);
DEFINE_NV_PUSH_HANDLER(long_double, long double);

static void push_handler_bool(pTHX_ Affix * affix, SV * perl_sv, void * c_ptr) {
    PERL_UNUSED_VAR(affix);
    *(bool *)c_ptr = SvTRUE(perl_sv);
}

DEFINE_PUSH_PRIMITIVE_EXECUTOR(bool, bool, SvTRUE)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(sint8, int8_t, SvIV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(uint8, uint8_t, SvUV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(sint16, int16_t, SvIV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(uint16, uint16_t, SvUV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(sint32, int32_t, SvIV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(uint32, uint32_t, SvUV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(sint64, int64_t, SvIV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(uint64, uint64_t, SvUV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(float, float, SvNV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(double, double, SvNV)
DEFINE_PUSH_PRIMITIVE_EXECUTOR(long_double, long double, SvNV)

#if !defined(INFIX_COMPILER_MSVC)
static void plan_step_push_sint128(pTHX_ Affix * affix,
                                   Affix_Plan_Step * step,
                                   SV ** perl_stack_frame,
                                   void * args_buffer,
                                   void ** c_args,
                                   void * ret_buffer) {
    croak("128-bit integer marshalling not yet implemented");
}
static void plan_step_push_uint128(pTHX_ Affix * affix,
                                   Affix_Plan_Step * step,
                                   SV ** perl_stack_frame,
                                   void * args_buffer,
                                   void ** c_args,
                                   void * ret_buffer) {
    croak("128-bit integer marshalling not yet implemented");
}
#endif

static MGVTBL Affix_pin_vtbl = {
    Affix_get_pin, Affix_set_pin, Affix_len_pin, nullptr, Affix_free_pin, nullptr, Affix_pin_dup, nullptr};

static const Affix_Step_Executor primitive_executors[] = {
    [INFIX_PRIMITIVE_BOOL] = plan_step_push_bool,
    [INFIX_PRIMITIVE_SINT8] = plan_step_push_sint8,
    [INFIX_PRIMITIVE_UINT8] = plan_step_push_uint8,
    [INFIX_PRIMITIVE_SINT16] = plan_step_push_sint16,
    [INFIX_PRIMITIVE_UINT16] = plan_step_push_uint16,
    [INFIX_PRIMITIVE_SINT32] = plan_step_push_sint32,
    [INFIX_PRIMITIVE_UINT32] = plan_step_push_uint32,
    [INFIX_PRIMITIVE_SINT64] = plan_step_push_sint64,
    [INFIX_PRIMITIVE_UINT64] = plan_step_push_uint64,
    [INFIX_PRIMITIVE_FLOAT] = plan_step_push_float,
    [INFIX_PRIMITIVE_DOUBLE] = plan_step_push_double,
    [INFIX_PRIMITIVE_LONG_DOUBLE] = plan_step_push_long_double,
#if !defined(INFIX_COMPILER_MSVC)
    [INFIX_PRIMITIVE_SINT128] = plan_step_push_sint128,
    [INFIX_PRIMITIVE_UINT128] = plan_step_push_uint128,
#endif
};

static const Affix_Push_Handler primitive_push_handlers[] = {
    [INFIX_PRIMITIVE_BOOL] = push_handler_bool,
    [INFIX_PRIMITIVE_SINT8] = push_handler_sint8,
    [INFIX_PRIMITIVE_UINT8] = push_handler_uint8,
    [INFIX_PRIMITIVE_SINT16] = push_handler_sint16,
    [INFIX_PRIMITIVE_UINT16] = push_handler_uint16,
    [INFIX_PRIMITIVE_SINT32] = push_handler_sint32,
    [INFIX_PRIMITIVE_UINT32] = push_handler_uint32,
    [INFIX_PRIMITIVE_SINT64] = push_handler_sint64,
    [INFIX_PRIMITIVE_UINT64] = push_handler_uint64,
    [INFIX_PRIMITIVE_FLOAT] = push_handler_float,
    [INFIX_PRIMITIVE_DOUBLE] = push_handler_double,
    [INFIX_PRIMITIVE_LONG_DOUBLE] = push_handler_long_double,
};
static void plan_step_push_pointer(pTHX_ Affix * affix,
                                   Affix_Plan_Step * step,
                                   SV ** perl_stack_frame,
                                   void * args_buffer,
                                   void ** c_args,
                                   void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;

    if (is_pin(aTHX_ sv)) {
        *(void **)c_arg_ptr = _get_pin_from_sv(aTHX_ sv)->pointer;
        return;
    }
    const infix_type * pointee_type = type->meta.pointer_info.pointee_type;
    if (pointee_type == nullptr)
        croak("Internal error in push_pointer: pointee_type is nullptr");

    if (!SvOK(sv)) {
        if (!SvREADONLY(sv)) {
            size_t size = infix_type_get_size(pointee_type);
            size_t align = infix_type_get_alignment(pointee_type);

            if (size == 0) {
                size = sizeof(void *);
                align = _Alignof(void *);
            }

            void * temp_slot = infix_arena_alloc(affix->args_arena, size, align > 0 ? align : 1);
            memset(temp_slot, 0, size);
            *(void **)c_arg_ptr = temp_slot;
            return;
        }

        *(void **)c_arg_ptr = nullptr;
        return;
    }

    if (SvIOK(sv)) {  // Treat integer value as a raw memory address
        *(void **)c_arg_ptr = INT2PTR(void *, SvUV(sv));
        return;
    }

    const char * type_name = infix_type_get_name(type);
    if (type_name &&
        (strEQ(type_name, "Buffer") || strEQ(type_name, "@Buffer") || strEQ(type_name, "SockAddr") ||
         strEQ(type_name, "@SockAddr") || strEQ(type_name, "StringList") || strEQ(type_name, "@StringList"))) {
        sv2ptr(aTHX_ affix, sv, c_arg_ptr, type);
        return;
    }

    const char * pointee_name = infix_type_get_name(pointee_type);
    if (pointee_name &&
        (strEQ(pointee_name, "File") || strEQ(pointee_name, "@File") || strEQ(pointee_name, "PerlIO") ||
         strEQ(pointee_name, "@PerlIO"))) {
        sv2ptr(aTHX_ affix, sv, c_arg_ptr, type);
        return;
    }

    if (pointee_type->category == INFIX_TYPE_REVERSE_TRAMPOLINE &&
        (SvTYPE(sv) == SVt_PVCV || (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV))) {
        push_reverse_trampoline(aTHX_ affix, pointee_type, sv, c_arg_ptr);
        return;
    }
    if (SvROK(sv)) {
        SV * const rv = SvRV(sv);
        if (pointee_type->category == INFIX_TYPE_POINTER) {
            const infix_type * inner_pointee_type = pointee_type->meta.pointer_info.pointee_type;
            if (inner_pointee_type->category == INFIX_TYPE_PRIMITIVE &&
                (inner_pointee_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                 inner_pointee_type->meta.primitive_id == INFIX_PRIMITIVE_UINT8)) {
                if (SvPOK(rv)) {
                    char ** ptr_slot = (char **)infix_arena_alloc(affix->args_arena, sizeof(char *), _Alignof(char *));
                    *ptr_slot = SvPV_nolen(rv);
                    *(void **)c_arg_ptr = ptr_slot;
                    return;
                }
            }
        }
        if (SvTYPE(rv) == SVt_PVAV) {
            AV * av = (AV *)rv;
            size_t len = av_len(av) + 1;
            size_t element_size = infix_type_get_size(pointee_type);
            size_t total_size = len * element_size;
            char * c_array = (char *)infix_arena_alloc(affix->args_arena, total_size, _Alignof(void *));
            if (!c_array)
                croak("Failed to allocate from arena for array marshalling");
            memset(c_array, 0, total_size);
            for (size_t i = 0; i < len; ++i) {
                SV ** elem_sv_ptr = av_fetch(av, i, 0);
                if (elem_sv_ptr)
                    sv2ptr(aTHX_ affix, *elem_sv_ptr, c_array + (i * element_size), pointee_type);
            }
            *(void **)c_arg_ptr = c_array;
            return;
        }
        const infix_type * copy_type = (pointee_type->category == INFIX_TYPE_VOID)
            ? (SvIOK(rv)       ? infix_type_create_primitive(INFIX_PRIMITIVE_SINT64)
                   : SvNOK(rv) ? infix_type_create_primitive(INFIX_PRIMITIVE_DOUBLE)
                   : SvPOK(rv) ? (*(void **)c_arg_ptr = SvPV_nolen(rv), (infix_type *)nullptr)
                               : (croak("Cannot pass reference to this type of scalar for a 'void*' parameter"),
                                  (infix_type *)nullptr))
            : pointee_type;
        if (!copy_type)
            return;
        void * dest_c_ptr =
            infix_arena_alloc(affix->args_arena, infix_type_get_size(copy_type), infix_type_get_alignment(copy_type));
        SV * sv_to_marshal = (SvTYPE(rv) == SVt_PVHV) ? sv : rv;
        sv2ptr(aTHX_ affix, sv_to_marshal, dest_c_ptr, copy_type);
        *(void **)c_arg_ptr = dest_c_ptr;
        return;
    }
    if (SvPOK(sv)) {
        bool is_char_ptr = (pointee_type->category == INFIX_TYPE_PRIMITIVE &&
                            (pointee_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                             pointee_type->meta.primitive_id == INFIX_PRIMITIVE_UINT8));
        bool is_void_ptr = (pointee_type->category == INFIX_TYPE_VOID);
        if (is_char_ptr || is_void_ptr) {
            *(const char **)c_arg_ptr = SvPV_nolen(sv);
            return;
        }
    }
    PING;
    sv_dump(sv);
    char signature_buf[256];
    (void)infix_type_print(signature_buf, sizeof(signature_buf), (infix_type *)type, INFIX_DIALECT_SIGNATURE);
    croak("Don't know how to handle this type of scalar as a pointer argument yet: %s", signature_buf);
}

static void plan_step_push_struct(pTHX_ Affix * affix,
                                  Affix_Plan_Step * step,
                                  SV ** perl_stack_frame,
                                  void * args_buffer,
                                  void ** c_args,
                                  void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;
    push_struct(aTHX_ affix, type, sv, c_arg_ptr);
}

static void plan_step_push_union(pTHX_ Affix * affix,
                                 Affix_Plan_Step * step,
                                 SV ** perl_stack_frame,
                                 void * args_buffer,
                                 void ** c_args,
                                 void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;
    push_union(aTHX_ affix, type, sv, c_arg_ptr);
}

static void plan_step_push_array(pTHX_ Affix * affix,
                                 Affix_Plan_Step * step,
                                 SV ** perl_stack_frame,
                                 void * args_buffer,
                                 void ** c_args,
                                 void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];

    // args_buffer slot is sizeof(void*) because we substituted Pointer for Array in the JIT
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;

    // Handle NULL/Undef
    if (!SvOK(sv)) {
        *(void **)c_arg_ptr = nullptr;
        return;
    }

    const infix_type * element_type = type->meta.array_info.element_type;
    size_t element_size = infix_type_get_size(element_type);

    if (SvPOK(sv) && element_type->category == INFIX_TYPE_PRIMITIVE && element_size == 1) {
        STRLEN len;
        const char * s = SvPV(sv, len);

        size_t fixed_len = type->meta.array_info.num_elements;
        size_t alloc_len = (fixed_len > 0) ? fixed_len : len + 1;  // +1 for null if dynamic

        void * temp_array = infix_arena_alloc(affix->args_arena, alloc_len, 1);
        if (!temp_array)
            croak("Failed to allocate memory for array argument");

        memset(temp_array, 0, alloc_len);

        // Copy what fits
        size_t copy_len = (len < alloc_len) ? len : alloc_len;
        memcpy(temp_array, s, copy_len);

        if (element_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 && len >= alloc_len && alloc_len > 0)
            ((char *)temp_array)[alloc_len - 1] = '\0';

        *(void **)c_arg_ptr = temp_array;
        return;
    }


    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
        croak("Expected an ARRAY reference or String for array marshalling");

    AV * av = (AV *)SvRV(sv);
    size_t input_len = av_len(av) + 1;

    size_t fixed_len = type->meta.array_info.num_elements;
    size_t alloc_len = (fixed_len > 0 && fixed_len > input_len) ? fixed_len : input_len;
    size_t total_size = alloc_len * element_size;


    // Allocate transient memory in the args_arena
    void * temp_array =
        infix_arena_alloc(affix->args_arena, total_size > 0 ? total_size : 1, infix_type_get_alignment(element_type));
    if (!temp_array)
        croak("Failed to allocate memory for array argument");

    memset(temp_array, 0, total_size);  // Zero-fill (important for padding fixed arrays)

    for (size_t i = 0; i < input_len; ++i) {  // Copy data
        SV ** elem_sv_ptr = av_fetch(av, i, 0);
        if (elem_sv_ptr) {
            void * elem_ptr = (char *)temp_array + (i * element_size);
            sv2ptr(aTHX_ affix, *elem_sv_ptr, elem_ptr, element_type);
        }
    }

    // Write the POINTER to the argument slot
    *(void **)c_arg_ptr = temp_array;
}

static void plan_step_push_enum(pTHX_ Affix * affix,
                                Affix_Plan_Step * step,
                                SV ** perl_stack_frame,
                                void * args_buffer,
                                void ** c_args,
                                void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;
    sv2ptr(aTHX_ affix, sv, c_arg_ptr, type->meta.enum_info.underlying_type);
}

static void plan_step_push_complex(pTHX_ Affix * affix,
                                   Affix_Plan_Step * step,
                                   SV ** perl_stack_frame,
                                   void * args_buffer,
                                   void ** c_args,
                                   void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
        croak("Expected an ARRAY reference with two numbers for complex type marshalling");
    AV * av = (AV *)SvRV(sv);
    if (av_len(av) != 1)
        croak("Expected exactly two elements (real, imaginary) for complex type");
    const infix_type * base_type = type->meta.complex_info.base_type;
    size_t base_size = infix_type_get_size(base_type);
    SV ** real_sv_ptr = av_fetch(av, 0, 0);
    SV ** imag_sv_ptr = av_fetch(av, 1, 0);
    if (!real_sv_ptr || !imag_sv_ptr)
        croak("Failed to fetch real or imaginary part from array for complex type");
    sv2ptr(aTHX_ affix, *real_sv_ptr, c_arg_ptr, base_type);
    sv2ptr(aTHX_ affix, *imag_sv_ptr, (char *)c_arg_ptr + base_size, base_type);
}

static void plan_step_push_vector(pTHX_ Affix * affix,
                                  Affix_Plan_Step * step,
                                  SV ** perl_stack_frame,
                                  void * args_buffer,
                                  void ** c_args,
                                  void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;

    // If it's a string, assume it's a packed buffer (e.g. pack 'f4')
    // and copy it directly. This is much faster than iterating an AV.
    if (SvPOK(sv)) {
        STRLEN len;
        const char * buf = SvPV(sv, len);
        size_t expected_size = infix_type_get_size(type);
        if (len >= expected_size) {
            memcpy(c_arg_ptr, buf, expected_size);
            return;
        }
        // If string is too short, fall through to AV check or error
    }

    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
        croak("Expected an ARRAY reference or Packed String for vector marshalling");
    AV * av = (AV *)SvRV(sv);
    size_t num_elements = av_len(av) + 1;
    size_t c_vector_len = type->meta.vector_info.num_elements;
    if (num_elements != c_vector_len)
        croak("Perl array has %lu elements, but C vector type requires %lu.",
              (unsigned long)num_elements,
              (unsigned long)c_vector_len);
    const infix_type * element_type = type->meta.vector_info.element_type;
    size_t element_size = infix_type_get_size(element_type);
    for (size_t i = 0; i < num_elements; ++i) {
        SV ** element_sv_ptr = av_fetch(av, i, 0);
        if (element_sv_ptr) {
            void * element_ptr = (char *)c_arg_ptr + (i * element_size);
            sv2ptr(aTHX_ affix, *element_sv_ptr, element_ptr, element_type);
        }
    }
}

static void plan_step_push_sv(pTHX_ Affix * affix,
                              Affix_Plan_Step * step,
                              SV ** perl_stack_frame,
                              void * args_buffer,
                              void ** c_args,
                              void * ret_buffer) {
    PERL_UNUSED_VAR(affix);
    PERL_UNUSED_VAR(ret_buffer);
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;
    SvREFCNT_inc(sv);
    *(void **)c_arg_ptr = sv;
}

static void plan_step_push_callback(pTHX_ Affix * affix,
                                    Affix_Plan_Step * step,
                                    SV ** perl_stack_frame,
                                    void * args_buffer,
                                    void ** c_args,
                                    void * ret_buffer) {
    PERL_UNUSED_VAR(ret_buffer);
    const infix_type * type = step->data.type;
    SV * sv = perl_stack_frame[step->data.index];
    void * c_arg_ptr = (char *)args_buffer + step->data.c_arg_offset;
    c_args[step->data.index] = c_arg_ptr;
    push_reverse_trampoline(aTHX_ affix, type, sv, c_arg_ptr);
}

static void plan_step_call_c_function(pTHX_ Affix * affix,
                                      Affix_Plan_Step * step,
                                      SV ** perl_stack_frame,
                                      void * args_buffer,
                                      void ** c_args,
                                      void * ret_buffer) {
    PERL_UNUSED_VAR(step);
    PERL_UNUSED_VAR(perl_stack_frame);
    PERL_UNUSED_VAR(args_buffer);
    affix->cif(ret_buffer, c_args);
}

static void plan_step_pull_return_value(pTHX_ Affix * affix,
                                        Affix_Plan_Step * step,
                                        SV ** perl_stack_frame,
                                        void * args_buffer,
                                        void ** c_args,
                                        void * ret_buffer) {
    PERL_UNUSED_VAR(perl_stack_frame);
    PERL_UNUSED_VAR(args_buffer);
    PERL_UNUSED_VAR(c_args);
    step->data.pull_handler(aTHX_ affix, affix->return_sv, step->data.type, ret_buffer);
}

Affix_Step_Executor get_plan_step_executor(const infix_type * type) {
    switch (type->category) {
    case INFIX_TYPE_PRIMITIVE:
        return primitive_executors[type->meta.primitive_id];
    case INFIX_TYPE_POINTER:
        {
            const char * name = infix_type_get_name(type);
            if (name && (strEQ(name, "SV") || strEQ(name, "@SV")))
                return plan_step_push_sv;
            return plan_step_push_pointer;
        }
    case INFIX_TYPE_STRUCT:
        {
            const char * name = infix_type_get_name(type);
            if (name && (strEQ(name, "SV") || strEQ(name, "@SV")))
                return plan_step_push_sv;
            return plan_step_push_struct;
        }
    case INFIX_TYPE_UNION:
        return plan_step_push_union;
    case INFIX_TYPE_ARRAY:
        return plan_step_push_array;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        return plan_step_push_callback;
    case INFIX_TYPE_ENUM:
        return plan_step_push_enum;
    case INFIX_TYPE_COMPLEX:
        return plan_step_push_complex;
    case INFIX_TYPE_VECTOR:
        return plan_step_push_vector;
    default:
        return nullptr;
    }
}

static void writeback_primitive(pTHX_ Affix * affix, const OutParamInfo * info, SV * perl_sv, void * c_arg_ptr) {
    void * actual_data_ptr = *(void **)c_arg_ptr;
    if (!actual_data_ptr)
        return;

    // Handle the case where perl_sv IS the AV (because it was unwrapped in the trigger)
    if (SvTYPE(perl_sv) == SVt_PVAV) {
        // Array Decay Writeback: Update each element of the Perl array from the C array
        AV * av = (AV *)perl_sv;
        size_t count = av_len(av) + 1;
        size_t elem_size = infix_type_get_size(info->pointee_type);

        for (size_t i = 0; i < count; ++i) {
            // Calculate pointer to current element in C array
            void * elem_ptr = (char *)actual_data_ptr + (i * elem_size);
            // Fetch the existing SV* from the AV (to update in place if possible)
            SV ** sv_ptr = av_fetch(av, i, 0);
            if (sv_ptr) {
                ptr2sv(aTHX_ affix, elem_ptr, *sv_ptr, info->pointee_type);
            }
            else {
                // Slot was empty, create new SV and store it
                SV * val = newSV(0);
                ptr2sv(aTHX_ affix, elem_ptr, val, info->pointee_type);
                av_store(av, i, val);
            }
        }
        return;
    }

    if (UNLIKELY(SvTYPE(perl_sv) >= SVt_PVAV))
        return;

    if (SvROK(perl_sv)) {
        SV * rv = SvRV(perl_sv);
        if (SvTYPE(rv) == SVt_PVAV) {
            // Array Decay Writeback
            AV * av = (AV *)rv;
            size_t count = av_len(av) + 1;
            size_t elem_size = infix_type_get_size(info->pointee_type);
            for (size_t i = 0; i < count; ++i) {
                SV * val_sv = newSV(0);
                ptr2sv(aTHX_ affix, (char *)actual_data_ptr + (i * elem_size), val_sv, info->pointee_type);
                av_store(av, i, val_sv);
            }
            return;
        }
        // Scalar Ref Writeback
        ptr2sv(aTHX_ affix, actual_data_ptr, rv, info->pointee_type);
    }
    else if (!SvREADONLY(perl_sv)) {
        // Lvalue Writeback
        ptr2sv(aTHX_ affix, actual_data_ptr, perl_sv, info->pointee_type);
    }
}

static void writeback_struct(pTHX_ Affix * affix, const OutParamInfo * info, SV * perl_sv, void * c_arg_ptr) {
    void * struct_ptr = *(void **)c_arg_ptr;
    if (!struct_ptr)
        return;

    // Direct AV check
    if (SvTYPE(perl_sv) == SVt_PVAV) {
        AV * av = (AV *)perl_sv;
        size_t count = av_len(av) + 1;
        size_t elem_size = infix_type_get_size(info->pointee_type);
        for (size_t i = 0; i < count; ++i) {
            SV ** item_ptr = av_fetch(av, i, 0);
            if (item_ptr && SvROK(*item_ptr) && SvTYPE(SvRV(*item_ptr)) == SVt_PVHV) {
                _populate_hv_from_c_struct(
                    aTHX_ affix, (HV *)SvRV(*item_ptr), info->pointee_type, (char *)struct_ptr + (i * elem_size));
            }
        }
        return;
    }

    if (SvTYPE(perl_sv) == SVt_PVHV) {
        _populate_hv_from_c_struct(aTHX_ affix, (HV *)perl_sv, info->pointee_type, struct_ptr);
    }
    else if (SvROK(perl_sv) && SvTYPE(SvRV(perl_sv)) == SVt_PVAV) {
        // Array of structs decay
        AV * av = (AV *)SvRV(perl_sv);
        size_t count = av_len(av) + 1;
        size_t elem_size = infix_type_get_size(info->pointee_type);
        for (size_t i = 0; i < count; ++i) {
            SV ** item_ptr = av_fetch(av, i, 0);
            if (item_ptr && SvROK(*item_ptr) && SvTYPE(SvRV(*item_ptr)) == SVt_PVHV) {
                _populate_hv_from_c_struct(
                    aTHX_ affix, (HV *)SvRV(*item_ptr), info->pointee_type, (char *)struct_ptr + (i * elem_size));
            }
        }
    }
}

static void writeback_pointer_to_string(pTHX_ Affix * affix,
                                        const OutParamInfo * info,
                                        SV * perl_sv,
                                        void * c_arg_ptr) {
    PERL_UNUSED_VAR(affix);
    PERL_UNUSED_VAR(info);
    if (UNLIKELY(SvTYPE(perl_sv) >= SVt_PVAV))
        return;
    sv_setpv(perl_sv, **(char ***)c_arg_ptr);
}

static void writeback_pointer_generic(pTHX_ Affix * affix, const OutParamInfo * info, SV * perl_sv, void * c_arg_ptr) {
    void * inner_ptr = *(void **)c_arg_ptr;
    // If the function didn't touch the output slot, inner_ptr might be a nullptr
    // But inner_ptr is the address of our temp_slot if it's an lvalue
    if (!inner_ptr)
        return;

    // Direct AV check
    if (SvTYPE(perl_sv) == SVt_PVAV) {
        AV * av = (AV *)perl_sv;
        size_t count = av_len(av) + 1;
        size_t elem_size = infix_type_get_size(info->pointee_type);
        for (size_t i = 0; i < count; ++i) {
            SV ** item_ptr = av_fetch(av, i, 0);
            if (item_ptr)
                ptr2sv(aTHX_ affix, (char *)inner_ptr + (i * elem_size), *item_ptr, info->pointee_type);
        }
        return;
    }

    if (SvROK(perl_sv)) {  // reference to an SV*
        SV * rv = SvRV(perl_sv);
        if (SvTYPE(rv) == SVt_PVAV) {
            // Array Decay for Pointer[Pointer]
            AV * av = (AV *)rv;
            size_t count = av_len(av) + 1;
            size_t elem_size = infix_type_get_size(info->pointee_type);
            for (size_t i = 0; i < count; ++i) {
                SV * val_sv = newSV(0);
                // inner_ptr is T*. Array elements are at inner_ptr[i].
                ptr2sv(aTHX_ affix, (char *)inner_ptr + (i * elem_size), val_sv, info->pointee_type);
                av_store(av, i, val_sv);
            }
            return;
        }
        if (SvTYPE(rv) == SVt_PVHV)
            return;

        ptr2sv(aTHX_ affix, inner_ptr, rv, info->pointee_type);
    }
    else {
        if (UNLIKELY(SvTYPE(perl_sv) >= SVt_PVAV))
            return;
        ptr2sv(aTHX_ affix, inner_ptr, perl_sv, info->pointee_type);
    }
}

Affix_Out_Param_Writer get_out_param_writer(const infix_type * pointee_type) {
    if (pointee_type->category == INFIX_TYPE_STRUCT)
        return writeback_struct;
    if (pointee_type->category == INFIX_TYPE_POINTER) {
        const infix_type * inner_pointee_type = pointee_type->meta.pointer_info.pointee_type;
        if (inner_pointee_type->category == INFIX_TYPE_PRIMITIVE &&
            (inner_pointee_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
             inner_pointee_type->meta.primitive_id == INFIX_PRIMITIVE_UINT8)) {
            return writeback_pointer_to_string;
        }
        return writeback_pointer_generic;
    }
    return writeback_primitive;
}

// Dispatcher implementation details
#if defined(INFIX_COMPILER_GCC) || defined(INFIX_COMPILER_CLANG)
#define USE_THREADED_CODE 1

// Label is an address
#define OP_LABEL(op) [op] = &&CASE_##op

// Jump to next instruction
#define DISPATCH() goto * dispatch_table[(++step)->opcode]

// Jump to first instruction
#define DISPATCH_START() goto * dispatch_table[step->opcode]

// Sentinel does nothing, execution falls through
#define DISPATCH_END() (void)0

// Define the table
#define DEFINE_DISPATCH_TABLE()                                                                 \
    static void * dispatch_table[] = {OP_LABEL(OP_PUSH_BOOL),     OP_LABEL(OP_PUSH_SINT8),      \
                                      OP_LABEL(OP_PUSH_UINT8),    OP_LABEL(OP_PUSH_SINT16),     \
                                      OP_LABEL(OP_PUSH_UINT16),   OP_LABEL(OP_PUSH_SINT32),     \
                                      OP_LABEL(OP_PUSH_UINT32),   OP_LABEL(OP_PUSH_SINT64),     \
                                      OP_LABEL(OP_PUSH_UINT64),   OP_LABEL(OP_PUSH_FLOAT),      \
                                      OP_LABEL(OP_PUSH_DOUBLE),   OP_LABEL(OP_PUSH_LONGDOUBLE), \
                                      OP_LABEL(OP_PUSH_SINT128),  OP_LABEL(OP_PUSH_UINT128),    \
                                      OP_LABEL(OP_PUSH_PTR_CHAR), OP_LABEL(OP_PUSH_PTR_WCHAR),  \
                                      OP_LABEL(OP_PUSH_POINTER),  OP_LABEL(OP_PUSH_SV),         \
                                      OP_LABEL(OP_PUSH_STRUCT),   OP_LABEL(OP_PUSH_UNION),      \
                                      OP_LABEL(OP_PUSH_ARRAY),    OP_LABEL(OP_PUSH_CALLBACK),   \
                                      OP_LABEL(OP_PUSH_ENUM),     OP_LABEL(OP_PUSH_COMPLEX),    \
                                      OP_LABEL(OP_PUSH_VECTOR),   OP_LABEL(OP_DONE)};
#else
#define USE_THREADED_CODE 0

// Label is a case statement
#define OP_LABEL(op) case op:

// Break to loop again
#define DISPATCH() \
    step++;        \
    break

// Start loop and switch
#define DISPATCH_START() \
    while (1) {          \
        switch (step->opcode) {

// Close switch and break loop
#define DISPATCH_END() \
    }                  \
    break;             \
    }

// No table needed
#define DEFINE_DISPATCH_TABLE()
#endif

// We use a macro to generate two variants (Stack vs Arena) to ensure logic sync.
#define GENERATE_TRIGGER_XSUB(NAME, USE_STACK_ALLOC)                                                         \
    void NAME(pTHX_ CV * cv) {                                                                               \
        dSP;                                                                                                 \
        dAXMARK;                                                                                             \
        dXSTARG;                                                                                             \
        Affix * affix = (Affix *)CvXSUBANY(cv).any_ptr;                                                      \
                                                                                                             \
        if (UNLIKELY((SP - MARK) != affix->num_args))                                                        \
            croak("Wrong number of arguments. Expected %d, got %d", (int)affix->num_args, (int)(SP - MARK)); \
                                                                                                             \
        register Affix_Plan_Step * step = affix->plan;                                                       \
        register SV ** perl_stack_frame = &ST(0);                                                            \
                                                                                                             \
        /* ALLOCATION STRATEGY */                                                                            \
        size_t arena_mark = affix->args_arena->current_offset;                                               \
        void * args_buffer;                                                                                  \
        if (USE_STACK_ALLOC) {                                                                               \
            /* Fast path: Stack allocation */                                                                \
            args_buffer = alloca(affix->total_args_size);                                                    \
        }                                                                                                    \
        else {                                                                                               \
            /* Slow path: Arena allocation */                                                                \
            arena_mark = affix->args_arena->current_offset;                                                  \
            /* Alignment 64 is safe for AVX-512 vectors */                                                   \
            args_buffer = infix_arena_alloc(affix->args_arena, affix->total_args_size, 64);                  \
        }                                                                                                    \
                                                                                                             \
        register void ** c_args = (void **)alloca(affix->num_args * sizeof(void *));                         \
                                                                                                             \
        size_t ret_align = affix->ret_type->alignment;                                                       \
        if (ret_align < 1)                                                                                   \
            ret_align = 1;                                                                                   \
        void * ret_buffer = infix_arena_alloc(affix->ret_arena, affix->ret_type->size, ret_align);           \
                                                                                                             \
        DEFINE_DISPATCH_TABLE();                                                                             \
                                                                                                             \
        DISPATCH_START();                                                                                    \
                                                                                                             \
CASE_OP_PUSH_BOOL:                                                                                           \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(bool *)ptr = SvTRUE(sv);                                                                       \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_SINT8:                                                                                          \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(int8_t *)ptr = (int8_t)SvIV(sv);                                                               \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_UINT8:                                                                                          \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(uint8_t *)ptr = (uint8_t)SvUV(sv);                                                             \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_SINT16:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(int16_t *)ptr = (int16_t)SvIV(sv);                                                             \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_UINT16:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(uint16_t *)ptr = (uint16_t)SvUV(sv);                                                           \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_SINT32:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(int32_t *)ptr = (int32_t)SvIV(sv);                                                             \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_UINT32:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(uint32_t *)ptr = (uint32_t)SvUV(sv);                                                           \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_SINT64:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(int64_t *)ptr = (int64_t)SvIV(sv);                                                             \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_UINT64:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            *(uint64_t *)ptr = (uint64_t)SvUV(sv);                                                           \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_FLOAT:                                                                                          \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            U32 flags = SvFLAGS(sv);                                                                         \
            if (LIKELY(flags & SVf_NOK))                                                                     \
                *(float *)ptr = (float)SvNVX(sv);                                                            \
            else if (flags & SVf_IOK)                                                                        \
                *(float *)ptr = (float)((flags & SVf_IVisUV) ? SvUVX(sv) : SvIVX(sv));                       \
            else                                                                                             \
                *(float *)ptr = (float)SvNV(sv);                                                             \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_DOUBLE:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            U32 flags = SvFLAGS(sv);                                                                         \
            if (LIKELY(flags & SVf_NOK))                                                                     \
                *(double *)ptr = SvNVX(sv);                                                                  \
            else if (flags & SVf_IOK)                                                                        \
                *(double *)ptr = (double)((flags & SVf_IVisUV) ? SvUVX(sv) : SvIVX(sv));                     \
            else                                                                                             \
                *(double *)ptr = (double)SvNV(sv);                                                           \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_LONGDOUBLE:                                                                                     \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            U32 flags = SvFLAGS(sv);                                                                         \
            if (LIKELY(flags & SVf_NOK))                                                                     \
                *(long double *)ptr = SvNVX(sv);                                                             \
            else if (flags & SVf_IOK)                                                                        \
                *(long double *)ptr = (long double)((flags & SVf_IVisUV) ? SvUVX(sv) : SvIVX(sv));           \
            else                                                                                             \
                *(long double *)ptr = (long double)SvNV(sv);                                                 \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_SINT128:                                                                                        \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            sv_to_int128_safe(sv, ptr);                                                                      \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_UINT128:                                                                                        \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            sv_to_uint128_safe(sv, ptr);                                                                     \
            c_args[step->data.index] = ptr;                                                                  \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_PTR_CHAR:                                                                                       \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            c_args[step->data.index] = ptr;                                                                  \
            if (SvPOK(sv)) {                                                                                 \
                *(const char **)ptr = SvPV_nolen(sv);                                                        \
            }                                                                                                \
            else if (!SvOK(sv)) {                                                                            \
                *(void **)ptr = nullptr;                                                                     \
            }                                                                                                \
            else if (is_pin(aTHX_ sv)) {                                                                     \
                *(void **)ptr = _get_pin_from_sv(aTHX_ sv)->pointer;                                         \
            }                                                                                                \
            else {                                                                                           \
                step->executor(aTHX_ affix, step, perl_stack_frame, args_buffer, c_args, ret_buffer);        \
            }                                                                                                \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_PTR_WCHAR:                                                                                      \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            c_args[step->data.index] = ptr;                                                                  \
            if (SvPOK(sv)) {                                                                                 \
                STRLEN len;                                                                                  \
                U8 * s = (U8 *)SvPVutf8(sv, len);                                                            \
                U8 * e = s + len;                                                                            \
                Newx(*(void **)ptr, len + 1, wchar_t);                                                       \
                wchar_t * d = *(void **)ptr;                                                                 \
                while (s < e) {                                                                              \
                    UV uv = utf8_to_uvchr_buf(s, e, nullptr);                                                \
                    if (sizeof(wchar_t) == 2 && uv > 0xFFFF) {                                               \
                        uv -= 0x10000;                                                                       \
                        *d++ = (wchar_t)((uv >> 10) + 0xD800);                                               \
                        *d++ = (wchar_t)((uv & 0x3FF) + 0xDC00);                                             \
                    }                                                                                        \
                    else {                                                                                   \
                        *d++ = (wchar_t)uv;                                                                  \
                    }                                                                                        \
                    s += UTF8SKIP(s);                                                                        \
                }                                                                                            \
                *d = 0;                                                                                      \
                SAVEFREEPV(*(void **)ptr);                                                                   \
            }                                                                                                \
            else if (!SvOK(sv)) {                                                                            \
                *(void **)ptr = nullptr;                                                                     \
            }                                                                                                \
            else if (is_pin(aTHX_ sv)) {                                                                     \
                *(void **)ptr = _get_pin_from_sv(aTHX_ sv)->pointer;                                         \
            }                                                                                                \
            else {                                                                                           \
                step->executor(aTHX_ affix, step, perl_stack_frame, args_buffer, c_args, ret_buffer);        \
            }                                                                                                \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_POINTER:                                                                                        \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            c_args[step->data.index] = ptr;                                                                  \
            if (is_pin(aTHX_ sv))                                                                            \
                *(void **)ptr = _get_pin_from_sv(aTHX_ sv)->pointer;                                         \
            else if (!SvOK(sv) && SvREADONLY(sv))                                                            \
                *(void **)ptr = nullptr;                                                                     \
            else                                                                                             \
                step->executor(aTHX_ affix, step, perl_stack_frame, args_buffer, c_args, ret_buffer);        \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_SV:                                                                                             \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            c_args[step->data.index] = ptr;                                                                  \
            SvREFCNT_inc(sv);                                                                                \
            *(SV **)ptr = sv;                                                                                \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_VECTOR:                                                                                         \
        {                                                                                                    \
            SV * sv = perl_stack_frame[step->data.index];                                                    \
            void * ptr = (char *)args_buffer + step->data.c_arg_offset;                                      \
            c_args[step->data.index] = ptr;                                                                  \
            if (SvPOK(sv)) {                                                                                 \
                STRLEN len;                                                                                  \
                const char * buf = SvPV(sv, len);                                                            \
                size_t sz = infix_type_get_size(step->data.type);                                            \
                if (len >= sz) {                                                                             \
                    memcpy(ptr, buf, sz);                                                                    \
                    DISPATCH();                                                                              \
                }                                                                                            \
            }                                                                                                \
            step->executor(aTHX_ affix, step, perl_stack_frame, args_buffer, c_args, ret_buffer);            \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_PUSH_STRUCT:                                                                                         \
CASE_OP_PUSH_UNION:                                                                                          \
CASE_OP_PUSH_ARRAY:                                                                                          \
CASE_OP_PUSH_CALLBACK:                                                                                       \
CASE_OP_PUSH_ENUM:                                                                                           \
CASE_OP_PUSH_COMPLEX:                                                                                        \
        {                                                                                                    \
            step->executor(aTHX_ affix, step, perl_stack_frame, args_buffer, c_args, ret_buffer);            \
            DISPATCH();                                                                                      \
        }                                                                                                    \
CASE_OP_DONE:                                                                                                \
        DISPATCH_END();                                                                                      \
                                                                                                             \
        affix->cif(ret_buffer, c_args);                                                                      \
                                                                                                             \
        switch (affix->ret_opcode) {                                                                         \
        case OP_RET_VOID:                                                                                    \
            sv_setsv(TARG, &PL_sv_undef);                                                                    \
            break;                                                                                           \
        case OP_RET_BOOL:                                                                                    \
            sv_setbool(TARG, *(bool *)ret_buffer);                                                           \
            break;                                                                                           \
        case OP_RET_SINT8:                                                                                   \
            sv_setiv(TARG, *(int8_t *)ret_buffer);                                                           \
            break;                                                                                           \
        case OP_RET_UINT8:                                                                                   \
            sv_setuv(TARG, *(uint8_t *)ret_buffer);                                                          \
            break;                                                                                           \
        case OP_RET_SINT16:                                                                                  \
            sv_setiv(TARG, *(int16_t *)ret_buffer);                                                          \
            break;                                                                                           \
        case OP_RET_UINT16:                                                                                  \
            sv_setuv(TARG, *(uint16_t *)ret_buffer);                                                         \
            break;                                                                                           \
        case OP_RET_SINT32:                                                                                  \
            sv_setiv(TARG, *(int32_t *)ret_buffer);                                                          \
            break;                                                                                           \
        case OP_RET_UINT32:                                                                                  \
            sv_setuv(TARG, *(uint32_t *)ret_buffer);                                                         \
            break;                                                                                           \
        case OP_RET_SINT64:                                                                                  \
            sv_setiv(TARG, *(int64_t *)ret_buffer);                                                          \
            break;                                                                                           \
        case OP_RET_UINT64:                                                                                  \
            sv_setuv(TARG, *(uint64_t *)ret_buffer);                                                         \
            break;                                                                                           \
        case OP_RET_FLOAT:                                                                                   \
            sv_setnv(TARG, (double)*(float *)ret_buffer);                                                    \
            break;                                                                                           \
        case OP_RET_DOUBLE:                                                                                  \
            sv_setnv(TARG, *(double *)ret_buffer);                                                           \
            break;                                                                                           \
        case OP_RET_PTR_CHAR:                                                                                \
            {                                                                                                \
                char * p = *(char **)ret_buffer;                                                             \
                if (p)                                                                                       \
                    sv_setpv(TARG, p);                                                                       \
                else                                                                                         \
                    sv_setsv(TARG, &PL_sv_undef);                                                            \
                break;                                                                                       \
            }                                                                                                \
        case OP_RET_PTR_WCHAR:                                                                               \
            pull_pointer_as_wstring(aTHX_ affix, TARG, affix->ret_type, ret_buffer);                         \
            break;                                                                                           \
        case OP_RET_SV:                                                                                      \
            {                                                                                                \
                SV * s = *(SV **)ret_buffer;                                                                 \
                if (s)                                                                                       \
                    sv_setsv(TARG, s);                                                                       \
                else                                                                                         \
                    sv_setsv(TARG, &PL_sv_undef);                                                            \
                break;                                                                                       \
            }                                                                                                \
        case OP_RET_SINT128:                                                                                 \
            sv_from_int128_safe(TARG, ret_buffer);                                                           \
            break;                                                                                           \
        case OP_RET_UINT128:                                                                                 \
            sv_from_uint128_safe(TARG, ret_buffer);                                                          \
            break;                                                                                           \
        case OP_RET_CUSTOM:                                                                                  \
        default:                                                                                             \
            if (affix->ret_pull_handler)                                                                     \
                affix->ret_pull_handler(aTHX_ affix, TARG, affix->ret_type, ret_buffer);                     \
            break;                                                                                           \
        }                                                                                                    \
        if (UNLIKELY(affix->num_out_params > 0)) {                                                           \
            for (size_t i = 0; i < affix->num_out_params; ++i) {                                             \
                const OutParamInfo * info = &affix->out_param_info[i];                                       \
                SV * arg_sv = perl_stack_frame[info->perl_stack_index];                                      \
                if (SvROK(arg_sv) && !is_pin(aTHX_ arg_sv)) {                                                \
                    SV * rsv = SvRV(arg_sv);                                                                 \
                    info->writer(aTHX_ affix, info, rsv, c_args[info->perl_stack_index]);                    \
                }                                                                                            \
                else if (!SvOK(arg_sv) && !SvREADONLY(arg_sv)) {                                             \
                    info->writer(aTHX_ affix, info, arg_sv, c_args[info->perl_stack_index]);                 \
                }                                                                                            \
            }                                                                                                \
        }                                                                                                    \
                                                                                                             \
        affix->args_arena->current_offset = arena_mark;                                                      \
        affix->ret_arena->current_offset = 0;                                                                \
                                                                                                             \
        ST(0) = TARG;                                                                                        \
        PL_stack_sp = PL_stack_base + ax;                                                                    \
    }

// Generate the two XSUBs
GENERATE_TRIGGER_XSUB(Affix_trigger_stack, 1)
GENERATE_TRIGGER_XSUB(Affix_trigger_arena, 0)

static infix_library_t * _get_lib_from_registry(pTHX_ const char * path) {
    dMY_CXT;
    const char * lookup_path = (path == nullptr) ? "" : path;
    SV ** entry_sv_ptr = hv_fetch(MY_CXT.lib_registry, lookup_path, strlen(lookup_path), 0);
    if (entry_sv_ptr) {
        LibRegistryEntry * entry = INT2PTR(LibRegistryEntry *, SvIV(*entry_sv_ptr));
        entry->ref_count++;
        return entry->lib;
    }
    infix_library_t * lib = infix_library_open(path);
    if (lib) {
        LibRegistryEntry * new_entry;
        Newxz(new_entry, 1, LibRegistryEntry);
        new_entry->lib = lib;
        new_entry->ref_count = 1;
        hv_store(MY_CXT.lib_registry, lookup_path, strlen(lookup_path), newSViv(PTR2IV(new_entry)), 0);
        return lib;
    }
    return nullptr;
}

static int Affix_cv_free(pTHX_ SV * sv, MAGIC * mg) {
    Affix * affix = (Affix *)mg->mg_ptr;
    if (affix) {
        if (affix->variadic_cache) {
            // Destroy all cached JIT trampolines
            hv_iterinit(affix->variadic_cache);
            HE * he;
            while ((he = hv_iternext(affix->variadic_cache))) {
                SV * val = HeVAL(he);
                infix_forward_t * t = INT2PTR(infix_forward_t *, SvIV(val));
                infix_forward_destroy(t);
            }
            SvREFCNT_dec(affix->variadic_cache);
        }
        if (affix->infix)
            infix_forward_destroy(affix->infix);
        if (affix->args_arena)
            infix_arena_destroy(affix->args_arena);
        if (affix->ret_arena)
            infix_arena_destroy(affix->ret_arena);
        if (affix->plan)
            safefree(affix->plan);
        if (affix->out_param_info)
            safefree(affix->out_param_info);
        if (affix->c_args)
            safefree(affix->c_args);
        if (affix->sig_str)
            safefree(affix->sig_str);
        if (affix->sym_name)
            safefree(affix->sym_name);
        if (affix->return_sv)
            SvREFCNT_dec(affix->return_sv);
        safefree(affix);
    }
    return 0;
}
static int Affix_cv_dup(pTHX_ MAGIC * mg, CLONE_PARAMS * param) {
    Affix * old_affix = (Affix *)mg->mg_ptr;
    Affix * new_affix;
    Newxz(new_affix, 1, Affix);

    /* Basic copy of fields */
    new_affix->num_args = old_affix->num_args;
    new_affix->plan_length = old_affix->plan_length;
    new_affix->total_args_size = old_affix->total_args_size;
    new_affix->ret_opcode = old_affix->ret_opcode;
    new_affix->num_out_params = old_affix->num_out_params;

    /* Reconstruct strings */
    if (old_affix->sig_str)
        new_affix->sig_str = savepv(old_affix->sig_str);
    if (old_affix->sym_name)
        new_affix->sym_name = savepv(old_affix->sym_name);
    new_affix->target_addr = old_affix->target_addr;

    /* Re-create Infix Trampoline in new thread */
    /* Note: We rely on the signature string and target address to rebuild. */
    /* This requires the new thread to have a valid registry. Affix_CLONE handles registry init. */
    dMY_CXT;
    infix_status status =
        infix_forward_create(&new_affix->infix, new_affix->sig_str, new_affix->target_addr, MY_CXT.registry);

    if (status == INFIX_SUCCESS) {
        new_affix->cif = infix_forward_get_code(new_affix->infix);
        new_affix->ret_type = infix_forward_get_return_type(new_affix->infix);
        new_affix->ret_pull_handler = get_pull_handler(aTHX_ new_affix->ret_type);

        /* Re-allocate Arenas */
        new_affix->args_arena = infix_arena_create(4096);
        new_affix->ret_arena = infix_arena_create(1024);
        if (new_affix->num_args > 0)
            Newx(new_affix->c_args, new_affix->num_args, void *);
        new_affix->return_sv = newSV(0);

        /* Re-create Plan (simplified copy since types are in infix) */
        /* Note: For full thread safety, we should re-parse or deep copy the plan. */
        /* This basic dup prevents the crash but might need more work for complex types in threads. */
        if (old_affix->plan) {
            Newxz(new_affix->plan, new_affix->plan_length + 1, Affix_Plan_Step);
            for (size_t i = 0; i < new_affix->num_args; i++) {
                new_affix->plan[i] = old_affix->plan[i];  // Copy descriptors
                // Types are pointers to Infix types. If Infix types are shared or re-created, this needs care.
                // Since we created a new infix_forward, we should technically re-fetch types.
                // However, for now, we just want to stop the SEGV.
            }
        }
    }

    mg->mg_ptr = (char *)new_affix;

    /* Update the new CV's fast access pointer */
    CV * new_cv = (CV *)mg->mg_obj;
    CvXSUBANY(new_cv).any_ptr = (void *)new_affix;

    return 0;
}

static MGVTBL Affix_cv_vtbl = {0, 0, 0, 0, Affix_cv_free, 0, Affix_cv_dup, 0};

static MGVTBL Affix_coercion_vtbl = {0};  // Marker vtable for coerced values

// Helper to extract the signature string from a coerced SV
static const char * _get_coerced_sig(pTHX_ SV * sv) {
    if (SvMAGICAL(sv)) {
        MAGIC * mg = mg_findext(sv, PERL_MAGIC_ext, &Affix_coercion_vtbl);
        if (mg && mg->mg_ptr)
            return mg->mg_ptr;
    }
    return NULL;
}

void Affix_trigger_variadic(pTHX_ CV * cv) {
    dSP;
    dAXMARK;
    dXSTARG;
    dMY_CXT;

    Affix * affix = (Affix *)CvXSUBANY(cv).any_ptr;
    size_t items = SP - MARK;

    if (items < affix->num_fixed_args)
        croak(
            "Not enough arguments for variadic function. Expected at least %zu, got %zu", affix->num_fixed_args, items);

    // Construct the complete signature string dynamically
    SV * sig_sv = sv_2mortal(newSVpv("", 0));

    // Reconstruct fixed part from the cached sig_str (which ends in '; ...' or similar)
    // We need to parse the original signature string to get the fixed part cleanly,
    // OR we can reconstruct it from the plan.
    // Simplest: The affix->sig_str contains the fixed part and the ';'.
    // We assume affix->sig_str is like "(*char; ...)->int"

    char * semi_ptr = strchr(affix->sig_str, ';');
    if (!semi_ptr)
        croak("Internal error: Variadic function missing semicolon in signature");

    // Append fixed part up to and including ';'
    sv_catpvn(sig_sv, affix->sig_str, (semi_ptr - affix->sig_str) + 1);

    // Iterate varargs to infer types and append to signature
    for (size_t i = affix->num_fixed_args; i < items; ++i) {
        SV * arg = ST(i);
        const char * coerced_sig = _get_coerced_sig(aTHX_ arg);

        if (i > affix->num_fixed_args)
            sv_catpvs(sig_sv, ",");

        if (coerced_sig)
            sv_catpv(sig_sv, coerced_sig);
        else if (is_pin(aTHX_ arg))
            // It's a pointer/struct pin. We treat it as a void pointer for the signature
            // unless we can introspect the pin's type object deeply.
            // For now, let's treat pins as '*void' (opaque pointer) in varargs unless coerced.
            sv_catpvs(sig_sv, "*void");
        else if (SvIOK(arg))
            sv_catpvs(sig_sv, "sint64");  // Default integer promotion
        else if (SvNOK(arg))
            sv_catpvs(sig_sv, "double");  // Default float promotion
        else if (SvPOK(arg))
            sv_catpvs(sig_sv, "*char");  // Default string promotion
        else                             // Fallback/Unknown
            sv_catpvs(sig_sv, "sint64");
    }

    // Append return type part (find ')' in original sig)
    char * close_paren = strrchr(affix->sig_str, ')');
    if (close_paren)
        sv_catpv(sig_sv, close_paren);
    else
        croak("Malformed signature string in affix");

    const char * full_sig = SvPV_nolen(sig_sv);

    // Check Cache
    infix_forward_t * trampoline = NULL;
    SV ** cache_entry = hv_fetch(affix->variadic_cache, full_sig, strlen(full_sig), 0);

    if (cache_entry)
        trampoline = INT2PTR(infix_forward_t *, SvIV(*cache_entry));
    else {
        // Cache Miss: Compile new trampoline
        // We use the parsing logic to get types
        infix_arena_t * temp_arena = NULL;
        infix_type * ret_type = NULL;
        infix_function_argument * args = NULL;
        size_t num_args = 0, num_fixed = 0;

        infix_status status =
            infix_signature_parse(full_sig, &temp_arena, &ret_type, &args, &num_args, &num_fixed, MY_CXT.registry);

        if (status != INFIX_SUCCESS) {
            if (temp_arena)
                infix_arena_destroy(temp_arena);
            croak("Failed to compile variadic signature: %s", full_sig);
        }

        // Convert args to type array
        infix_type ** arg_types = NULL;
        if (num_args > 0) {
            arg_types = safemalloc(sizeof(infix_type *) * num_args);
            for (size_t i = 0; i < num_args; ++i)
                arg_types[i] = args[i].type;
        }

        status = infix_forward_create_manual(&trampoline, ret_type, arg_types, num_args, num_fixed, affix->target_addr);

        if (arg_types)
            safefree(arg_types);
        infix_arena_destroy(temp_arena);

        if (status != INFIX_SUCCESS)
            croak("Failed to create variadic trampoline");

        // Store in cache
        hv_store(affix->variadic_cache, full_sig, strlen(full_sig), newSViv(PTR2IV(trampoline)), 0);
    }

    // Execute
    infix_cif_func cif = infix_forward_get_code(trampoline);
    size_t num_args = infix_forward_get_num_args(trampoline);
    const infix_type * ret_type = infix_forward_get_return_type(trampoline);

    // Allocate args buffer (pointers)
    void ** c_args = alloca(sizeof(void *) * num_args);

    // Use an arena for argument data to avoid many malloc/frees
    infix_arena_t * call_arena = infix_arena_create(2048);
    void * ret_buffer = infix_arena_alloc(call_arena, infix_type_get_size(ret_type), 8);

    // Marshal Arguments
    for (size_t i = 0; i < num_args; ++i) {
        const infix_type * arg_type = infix_forward_get_arg_type(trampoline, i);
        void * data = infix_arena_alloc(call_arena, infix_type_get_size(arg_type), infix_type_get_alignment(arg_type));
        sv2ptr(aTHX_ affix, ST(i), data, arg_type);
        c_args[i] = data;
    }

    // Call
    cif(ret_buffer, c_args);

    // Marshal Return
    SV * ret_sv = TARG;
    ptr2sv(aTHX_ affix, ret_buffer, ret_sv, ret_type);

    infix_arena_destroy(call_arena);

    ST(0) = ret_sv;
    XSRETURN(1);
}

XS_INTERNAL(Affix_coerce) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "type, value_sv");

    SV * type_sv = ST(0);
    SV * target_sv = ST(1);

    if (SvREADONLY(target_sv))
        croak("Cannot coerce a read-only value");

    const char * sig = _get_string_from_type_obj(aTHX_ type_sv);
    if (!sig)
        croak("Invalid type object passed to coerce");

    // Attach magic to the SV containing the signature string
    sv_magicext(target_sv, NULL, PERL_MAGIC_ext, &Affix_coercion_vtbl, sig, strlen(sig));

    // Return the modified SV
    ST(0) = target_sv;
    XSRETURN(1);
}
XS_INTERNAL(Affix_affix) {
    dXSARGS;
    dXSI32;
    dMY_CXT;

    if (ix == 2 || ix == 4) {
        if (items != 3)
            croak_xs_usage(cv, "Affix::affix_bundle($target, $name, $signature)");
    }
    else {
        // Allow 2 items for wrap($ptr, $sig)
        if (items < 2 || items > 4)
            croak_xs_usage(cv, "Affix::affix($target, ...)");
    }

    void * symbol = nullptr;
    SV * target_sv = ST(0);

    // Detect target type (library vs raw pointer)
    bool is_raw_ptr_target = false;

    if (_get_pin_from_sv(aTHX_ target_sv)) {
        symbol = _get_pin_from_sv(aTHX_ target_sv)->pointer;
        is_raw_ptr_target = true;
    }
    else if (SvIOK(target_sv) && !sv_isobject(target_sv)) {
        symbol = INT2PTR(void *, SvUV(target_sv));
        is_raw_ptr_target = true;
    }

    // Symbol lookup (unles it's a raw pointer)
    const char * symbol_name_str = nullptr;
    const char * rename_str = nullptr;
    infix_library_t * lib_handle_for_symbol = nullptr;
    bool created_implicit_handle = false;

    // We only process names/libraries if we don't already have a raw pointer address
    if (!is_raw_ptr_target) {
        SV * name_sv = ST(1);

        // Handle rename: affix($lib, ['real', 'alias'], ...)
        if (SvROK(name_sv) && SvTYPE(SvRV(name_sv)) == SVt_PVAV) {
            if (ix == 1 || ix == 3)  // wrap/direct_wrap
                croak("Cannot rename an anonymous Affix'd wrapper");

            AV * name_av = (AV *)SvRV(name_sv);
            if (av_count(name_av) != 2)
                croak("Name spec arrayref must contain exactly two elements: [symbol_name, new_sub_name]");

            SV ** sym_sv = av_fetch(name_av, 0, 0);
            SV ** alias_sv = av_fetch(name_av, 1, 0);

            if (!sym_sv || !alias_sv)
                croak("Invalid name spec");

            rename_str = SvPV_nolen(*alias_sv);

            // Is the symbol inside the array a raw pointer?
            // affix(undef, [$ptr, 'name'], ...)
            if (_get_pin_from_sv(aTHX_ * sym_sv))
                symbol = _get_pin_from_sv(aTHX_ * sym_sv)->pointer;
            else if (SvIOK(*sym_sv))
                symbol = INT2PTR(void *, SvUV(*sym_sv));
            else
                symbol_name_str = SvPV_nolen(*sym_sv);
        }
        else {
            // Name a Scalar? (string or raw pointer)
            // wrap(undef, $ptr, ...)
            if (_get_pin_from_sv(aTHX_ name_sv))
                symbol = _get_pin_from_sv(aTHX_ name_sv)->pointer;
            else if (SvIOK(name_sv))
                symbol = INT2PTR(void *, SvUV(name_sv));
            else {
                // It's a string name
                symbol_name_str = SvPV_nolen(name_sv);
                rename_str = symbol_name_str;
            }
        }

        // Only load library if we don't have a direct symbol pointer yet
        if (!symbol) {
            if (sv_isobject(target_sv) && sv_derived_from(target_sv, "Affix::Lib")) {
                IV tmp = SvIV((SV *)SvRV(target_sv));
                lib_handle_for_symbol = INT2PTR(infix_library_t *, tmp);
                created_implicit_handle = false;
            }
            else {
                const char * path = SvOK(target_sv) ? SvPV_nolen(target_sv) : nullptr;
                lib_handle_for_symbol = _get_lib_from_registry(aTHX_ path);
                if (lib_handle_for_symbol)
                    created_implicit_handle = true;
            }

            if (lib_handle_for_symbol && symbol_name_str)
                symbol = infix_library_get_symbol(lib_handle_for_symbol, symbol_name_str);
        }

        if (symbol == nullptr) {
            if (created_implicit_handle) {
                const char * lookup_path = SvOK(target_sv) ? SvPV_nolen(target_sv) : "";
                SV ** entry_sv_ptr = hv_fetch(MY_CXT.lib_registry, lookup_path, strlen(lookup_path), 0);
                if (entry_sv_ptr) {
                    LibRegistryEntry * entry = INT2PTR(LibRegistryEntry *, SvIV(*entry_sv_ptr));
                    entry->ref_count--;
                    if (entry->ref_count == 0) {
                        infix_library_close(entry->lib);
                        safefree(entry);
                        hv_delete_ent(MY_CXT.lib_registry, newSVpvn(lookup_path, strlen(lookup_path)), G_DISCARD, 0);
                    }
                }
            }
            warn("Failed to locate symbol '%s'", symbol_name_str ? symbol_name_str : "(null)");
            XSRETURN_UNDEF;
        }
    }

    // Argument shifting (Determine where signature starts)
    SV * args_sv = nullptr;
    SV * ret_sv = nullptr;
    SV * sig_sv = nullptr;
    bool explicit_args = false;  // true if using [Args] => Ret format

    if (is_raw_ptr_target) {
        // Mode A: wrap($ptr, [Args], Ret)  -> items=3
        // Mode B: wrap($ptr, "Signature")  -> items=2
        if (items == 3) {
            args_sv = ST(1);
            ret_sv = ST(2);
            explicit_args = true;
        }
        else
            sig_sv = ST(1);
    }
    else {
        // Mode C: wrap($lib, $name, [Args], Ret) -> items=4
        // Mode D: wrap($lib, $name, "Signature") -> items=3
        if (items == 4) {
            args_sv = ST(2);
            ret_sv = ST(3);
            explicit_args = true;
        }
        else
            sig_sv = ST(2);
    }

    // Build infix signature string
    char signature_buf[1024] = {0};
    const char * signature = nullptr;

    if (explicit_args) {
        if (!SvROK(args_sv) || SvTYPE(SvRV(args_sv)) != SVt_PVAV)
            croak("Usage: affix(..., \\@args, $ret_type) - args must be an array reference");

        strcat(signature_buf, "(");
        AV * args_av = (AV *)SvRV(args_sv);
        SSize_t num_args = av_len(args_av) + 1;

        for (SSize_t i = 0; i < num_args; ++i) {
            SV ** type_sv_ptr = av_fetch(args_av, i, 0);
            if (!type_sv_ptr)
                continue;
            const char * arg_sig = _get_string_from_type_obj(aTHX_ * type_sv_ptr);
            if (!arg_sig)
                croak("Invalid type object in signature");

            strcat(signature_buf, arg_sig);

            // Logic to prevent adding commas around ';', which denotes VarArgs start
            if (i < num_args - 1) {
                if (strEQ(arg_sig, ";"))
                    continue;
                SV ** next_sv_ptr = av_fetch(args_av, i + 1, 0);
                if (next_sv_ptr) {
                    const char * next_sig = _get_string_from_type_obj(aTHX_ * next_sv_ptr);
                    if (next_sig && strEQ(next_sig, ";"))
                        continue;
                }
                strcat(signature_buf, ",");
            }
        }
        strcat(signature_buf, ") -> ");
        const char * ret_sig = _get_string_from_type_obj(aTHX_ ret_sv);
        if (!ret_sig)
            croak("Invalid return type object");
        strcat(signature_buf, ret_sig);
        signature = signature_buf;
    }
    else {
        signature = _get_string_from_type_obj(aTHX_ sig_sv);
        if (!signature)
            signature = SvPV_nolen(sig_sv);
    }

    // Direct marshalling path
    if (ix == 2) {
        Affix_Backend * backend;
        Newxz(backend, 1, Affix_Backend);

        infix_arena_t * parse_arena = nullptr;
        infix_type * ret_type = nullptr;
        infix_function_argument * args = nullptr;
        size_t num_args = 0, num_fixed = 0;

        infix_status status =
            infix_signature_parse(signature, &parse_arena, &ret_type, &args, &num_args, &num_fixed, MY_CXT.registry);

        if (status != INFIX_SUCCESS) {
            safefree(backend);
            if (parse_arena)
                infix_arena_destroy(parse_arena);
            infix_error_details_t err = infix_get_last_error();
            if (err.message[0] != '\0')
                warn("Failed to parse signature for affix_bundle: %s", err.message);
            else
                warn("Failed to parse signature for affix_bundle (Error Code: %d)", status);
            XSRETURN_UNDEF;
        }

        infix_direct_arg_handler_t * handlers =
            (infix_direct_arg_handler_t *)safecalloc(num_args, sizeof(infix_direct_arg_handler_t));

        for (size_t i = 0; i < num_args; ++i)
            handlers[i] = get_direct_handler_for_type(args[i].type);

        status = infix_forward_create_direct(&backend->infix, signature, symbol, handlers, MY_CXT.registry);

        safefree(handlers);
        infix_arena_destroy(parse_arena);

        if (status != INFIX_SUCCESS) {
            safefree(backend);
            infix_error_details_t err = infix_get_last_error();
            warn("Failed to create direct trampoline: %s", err.message[0] ? err.message : "Unknown Error");
            XSRETURN_UNDEF;
        }

        backend->cif = infix_forward_get_direct_code(backend->infix);
        backend->num_args = num_args;
        backend->ret_type = infix_forward_get_return_type(backend->infix);

        backend->pull_handler = get_pull_handler(aTHX_ backend->ret_type);
        backend->ret_opcode = get_ret_opcode_for_type(backend->ret_type);

        if (!backend->pull_handler) {
            infix_forward_destroy(backend->infix);
            safefree(backend);
            warn("Unsupported return type for affix_bundle");
            XSRETURN_UNDEF;
        }

        backend->lib_handle = created_implicit_handle ? lib_handle_for_symbol : nullptr;

        CV * cv_new =
            newXSproto_portable((ix == 0 || ix == 2) ? rename_str : nullptr, Affix_trigger_backend, __FILE__, nullptr);

        CvXSUBANY(cv_new).any_ptr = (void *)backend;

        SV * obj = newRV_inc(MUTABLE_SV(cv_new));
        sv_bless(obj, gv_stashpv("Affix::Bundled", GV_ADD));
        ST(0) = sv_2mortal(obj);
        XSRETURN(1);
    }

    // Standard path (parse & prepare types)
    infix_arena_t * parse_arena = NULL;
    infix_type * ret_type = NULL;
    infix_function_argument * args = NULL;
    size_t num_args = 0, num_fixed = 0;

    infix_status status =
        infix_signature_parse(signature, &parse_arena, &ret_type, &args, &num_args, &num_fixed, MY_CXT.registry);

    if (status != INFIX_SUCCESS) {
        infix_error_details_t err = infix_get_last_error();
        warn("Failed to parse signature: %s", err.message);
        if (parse_arena)
            infix_arena_destroy(parse_arena);
        XSRETURN_UNDEF;
    }

    // JIT Type substitution (array decay)
    // We create a separate list of types for JIT compilation where Arrays are replaced by Pointers.
    // The original Array types are kept for the marshalling plan.
    infix_type ** jit_arg_types = NULL;
    if (num_args > 0) {
        jit_arg_types = safemalloc(sizeof(infix_type *) * num_args);
        for (size_t i = 0; i < num_args; ++i) {
            infix_type * t = args[i].type;
            if (t->category == INFIX_TYPE_ARRAY) {
                // Arrays passed as arguments decay to pointers.
                // We create a Pointer[Element] type in the temp arena for JIT creation.
                infix_type * ptr_type = NULL;
                // FIX: Check return value to satisfy nodiscard warning
                if (infix_type_create_pointer_to(parse_arena, &ptr_type, t->meta.array_info.element_type) !=
                    INFIX_SUCCESS) {
                    safefree(jit_arg_types);
                    infix_arena_destroy(parse_arena);
                    croak("Failed to create pointer type for array decay");
                }
                jit_arg_types[i] = ptr_type;
            }
            else
                jit_arg_types[i] = t;
        }
    }

    // Object init & trampoline generation
    Affix * affix;
    Newxz(affix, 1, Affix);
    affix->return_sv = newSV(0);
    affix->variadic_cache = newHV();

    bool is_variadic = (strstr(signature, ";") != NULL);
    affix->sig_str = savepv(signature);
    if (rename_str)
        affix->sym_name = savepv(rename_str);
    affix->target_addr = symbol;
    if (lib_handle_for_symbol && !created_implicit_handle)
        affix->lib_handle = lib_handle_for_symbol;

    // Create Trampoline using the JIT-optimized types
    status = infix_forward_create_manual(&affix->infix, ret_type, jit_arg_types, num_args, num_fixed, symbol);

    if (jit_arg_types)
        safefree(jit_arg_types);

    if (status != INFIX_SUCCESS) {
        infix_error_details_t err = infix_get_last_error();
        warn("Failed to create trampoline: %s", err.message);
        SvREFCNT_dec(affix->return_sv);
        SvREFCNT_dec(affix->variadic_cache);
        safefree(affix->sig_str);
        if (affix->sym_name)
            safefree(affix->sym_name);
        safefree(affix);
        infix_arena_destroy(parse_arena);
        XSRETURN_UNDEF;
    }

    affix->cif = infix_forward_get_code(affix->infix);
    affix->num_args = num_args;
    affix->num_fixed_args = num_fixed;

    affix->ret_type = infix_forward_get_return_type(affix->infix);
    affix->ret_pull_handler = get_pull_handler(aTHX_ affix->ret_type);
    affix->ret_opcode = get_ret_opcode_for_type(affix->ret_type);

    if (affix->ret_pull_handler == nullptr) {
        infix_forward_destroy(affix->infix);
        SvREFCNT_dec(affix->return_sv);
        SvREFCNT_dec(affix->variadic_cache);
        safefree(affix->sig_str);
        if (affix->sym_name)
            safefree(affix->sym_name);
        safefree(affix);
        warn("Unsupported return type");
        infix_arena_destroy(parse_arena);
        XSRETURN_UNDEF;
    }

    if (affix->num_args > 0)
        Newx(affix->c_args, affix->num_args, void *);
    else
        affix->c_args = nullptr;

    affix->args_arena = infix_arena_create(4096);
    affix->ret_arena = infix_arena_create(1024);

    // Build execution plan
    affix->plan_length = affix->num_args;
    Newxz(affix->plan, affix->plan_length + 1, Affix_Plan_Step);

    size_t current_offset = 0;
    size_t out_param_count = 0;
    OutParamInfo * temp_out_info = safemalloc(sizeof(OutParamInfo) * (affix->num_args > 0 ? affix->num_args : 1));

    for (size_t i = 0; i < affix->num_args; ++i) {
        // Deep copy from temporary parse_arena to persistent args_arena.
        // We use the ORIGINAL types (args[i].type) so marshalling knows it's an Array.
        const infix_type * original_type = _copy_type_graph_to_arena(affix->args_arena, args[i].type);

        // Calculate offset based on JIT expectation (Array Decay -> Pointer size)
        size_t alignment, size;
        if (original_type->category == INFIX_TYPE_ARRAY) {
            alignment = _Alignof(void *);
            size = sizeof(void *);
        }
        else {
            alignment = infix_type_get_alignment(original_type);
            size = infix_type_get_size(original_type);
        }
        if (alignment == 0)
            alignment = 1;

        current_offset = (current_offset + alignment - 1) & ~(alignment - 1);
        affix->plan[i].data.c_arg_offset = current_offset;
        current_offset += size;

        affix->plan[i].executor = get_plan_step_executor(original_type);
        affix->plan[i].opcode = get_opcode_for_type(original_type);
        affix->plan[i].data.type = original_type;  // Now points to persistent memory
        affix->plan[i].data.index = i;

        if (original_type->category == INFIX_TYPE_POINTER) {
            const infix_type * pointee = original_type->meta.pointer_info.pointee_type;
            const char * pointee_name = infix_type_get_name(pointee);
            // Skip writeback for Pointer[@SV] to avoid corrupting Perl variables with void return values
            // We assume SV* passed to C is owned by C for the duration and shouldn't be auto-updated
            // (since the SV* itself is the value, not a pointer to a value we want copied back).
            bool is_sv_pointer = pointee_name && (strEQ(pointee_name, "SV") || strEQ(pointee_name, "@SV"));

            if (!is_sv_pointer && pointee->category != INFIX_TYPE_REVERSE_TRAMPOLINE &&
                pointee->category != INFIX_TYPE_VOID) {
                temp_out_info[out_param_count].perl_stack_index = i;
                temp_out_info[out_param_count].pointee_type = pointee;
                temp_out_info[out_param_count].writer = get_out_param_writer(pointee);
                out_param_count++;
            }
        }
        else if (original_type->category == INFIX_TYPE_ARRAY) {
            // Register write-back handler for Arrays
            temp_out_info[out_param_count].perl_stack_index = i;
            temp_out_info[out_param_count].pointee_type = original_type;
            temp_out_info[out_param_count].writer = affix_array_writeback;
            out_param_count++;
        }
    }
    affix->plan[affix->num_args].opcode = OP_DONE;
    affix->total_args_size = current_offset;

    affix->num_out_params = out_param_count;
    if (out_param_count > 0) {
        affix->out_param_info = safemalloc(sizeof(OutParamInfo) * out_param_count);
        memcpy(affix->out_param_info, temp_out_info, sizeof(OutParamInfo) * out_param_count);
    }
    else
        affix->out_param_info = nullptr;

    safefree(temp_out_info);

    char prototype_buf[256] = {0};
    for (size_t i = 0; i < affix->num_args; ++i)
        strcat(prototype_buf, "$");

    // Install XSUB
    XSUBADDR_t trigger;
    if (is_variadic)
        trigger = Affix_trigger_variadic;
    else
        trigger = (affix->total_args_size <= 512) ? Affix_trigger_stack : Affix_trigger_arena;

    CV * cv_new = newXSproto_portable(ix == 0 ? rename_str : nullptr, trigger, __FILE__, nullptr);
    if (UNLIKELY(cv_new == nullptr)) {
        infix_forward_destroy(affix->infix);
        SvREFCNT_dec(affix->return_sv);
        infix_arena_destroy(affix->args_arena);
        infix_arena_destroy(affix->ret_arena);
        safefree(affix->plan);
        if (affix->out_param_info)
            safefree(affix->out_param_info);
        if (affix->c_args)
            safefree(affix->c_args);
        safefree(affix->sig_str);
        if (affix->sym_name)
            safefree(affix->sym_name);
        SvREFCNT_dec(affix->variadic_cache);
        safefree(affix);
        warn("Failed to install new XSUB");
        infix_arena_destroy(parse_arena);
        XSRETURN_UNDEF;
    }

    // Attach magic for lifecycle management
    sv_magicext((SV *)cv_new, nullptr, PERL_MAGIC_ext, &Affix_cv_vtbl, (const char *)affix, 0);

    // Set optimization pointer
    CvXSUBANY(cv_new).any_ptr = (void *)affix;

    //
    SV * obj = newRV_inc(MUTABLE_SV(cv_new));
    sv_bless(obj, gv_stashpv("Affix", GV_ADD));
    ST(0) = sv_2mortal(obj);

    infix_arena_destroy(parse_arena);  // Now safe to destroy as we deep-copied everything
    XSRETURN(1);
}
XS_INTERNAL(Affix_Bundled_DESTROY) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    Affix_Backend * backend;
    STMT_START {
        HV * st;
        GV * gvp;
        SV * const xsub_tmp_sv = ST(0);
        SvGETMAGIC(xsub_tmp_sv);
        CV * cv_ptr = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
        backend = (Affix_Backend *)CvXSUBANY(cv_ptr).any_ptr;
    }
    STMT_END;

    if (backend) {
        if (backend->infix)
            infix_forward_destroy(backend->infix);
        safefree(backend);
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_DESTROY) {
    dXSARGS;
    dMY_CXT;
    PERL_UNUSED_VAR(items);
    Affix * affix;
    STMT_START {
        HV * st;
        GV * gvp;
        SV * const xsub_tmp_sv = ST(0);
        SvGETMAGIC(xsub_tmp_sv);
        CV * cv_ptr = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
        affix = (Affix *)CvXSUBANY(cv_ptr).any_ptr;
    }
    STMT_END;
    if (affix != nullptr) {
        if (affix->lib_handle != nullptr && MY_CXT.lib_registry != nullptr) {
            hv_iterinit(MY_CXT.lib_registry);
            HE * he;
            while ((he = hv_iternext(MY_CXT.lib_registry))) {
                SV * entry_sv = HeVAL(he);
                LibRegistryEntry * entry = INT2PTR(LibRegistryEntry *, SvIV(entry_sv));
                if (entry->lib == affix->lib_handle) {
                    entry->ref_count--;
                    if (entry->ref_count == 0) {
                        infix_library_close(entry->lib);
                        safefree(entry);
                        hv_delete_ent(MY_CXT.lib_registry, HeKEY_sv(he), G_DISCARD, 0);
                    }
                    break;
                }
            }
        }
        if (affix->return_sv)
            SvREFCNT_dec(affix->return_sv);
        if (affix->args_arena != nullptr)
            infix_arena_destroy(affix->args_arena);
        if (affix->ret_arena != nullptr)
            infix_arena_destroy(affix->ret_arena);
        if (affix->infix != nullptr)
            infix_forward_destroy(affix->infix);
        if (affix->plan != nullptr)
            safefree(affix->plan);
        if (affix->out_param_info != nullptr)
            safefree(affix->out_param_info);
        if (affix->c_args != nullptr)
            safefree(affix->c_args);
        safefree(affix);
    }
    XSRETURN_EMPTY;
}

static void pull_sint8(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setiv(sv, *(int8_t *)p); }
static void pull_uint8(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setuv(sv, *(uint8_t *)p); }
static void pull_sint16(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setiv(sv, *(int16_t *)p); }
static void pull_uint16(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setuv(sv, *(uint16_t *)p); }
static void pull_sint32(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setiv(sv, *(int32_t *)p); }
static void pull_uint32(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setuv(sv, *(uint32_t *)p); }
static void pull_sint64(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setiv(sv, *(int64_t *)p); }
static void pull_uint64(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setuv(sv, *(uint64_t *)p); }
static void pull_float(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setnv(sv, *(float *)p); }
static void pull_double(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setnv(sv, *(double *)p); }
static void pull_long_double(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) {
    sv_setnv(sv, *(long double *)p);
}
static void pull_bool(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setbool(sv, *(bool *)p); }
static void pull_void(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) { sv_setsv(sv, &PL_sv_undef); }

#if !defined(INFIX_COMPILER_MSVC)
static void pull_sint128(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) {
    croak("128-bit integer marshalling not yet implemented");
}
static void pull_uint128(pTHX_ Affix * affix, SV * sv, const infix_type * t, void * p) {
    croak("128-bit integer marshalling not yet implemented");
}
#endif

static void pull_struct(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    HV * hv;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)
        hv = (HV *)SvRV(sv);
    else {
        hv = newHV();
        sv_setsv(sv, sv_2mortal(newRV_noinc(MUTABLE_SV(hv))));
    }
    _populate_hv_from_c_struct(aTHX_ affix, hv, type, p);
}

static void pull_union(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    HV * hv;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) {
        hv = (HV *)SvRV(sv);
        hv_clear(hv);
    }
    else {
        hv = newHV();
        sv_setsv(sv, sv_2mortal(newRV_noinc(MUTABLE_SV(hv))));
    }

    // Iterate over union members
    for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
        const infix_struct_member * member = &type->meta.aggregate_info.members[i];
        if (member->name) {
            // Create a pin for this member (reference to magic scalar)
            SV * val_sv = newSV(0);
            _pin_sv(aTHX_ val_sv, member->type, (char *)p + member->offset, false);
            hv_store(hv, member->name, strlen(member->name), val_sv, 0);
        }
    }
}

// Helper for portability if strnlen isn't available
static size_t _safe_strnlen(const char * s, size_t maxlen) {
    size_t len;
    for (len = 0; len < maxlen; len++, s++)
        if (!*s)
            break;
    return len;
}

static void pull_array(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    const infix_type * element_type = type->meta.array_info.element_type;

    if (element_type->category == INFIX_TYPE_PRIMITIVE) {
        if (element_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8) {
            // char[] / int8[]: Treat as fixed buffer but strip trailing nulls.
            // This satisfies typical C-string in struct usage (padded with nulls)
            // AND binary usage where nulls are embedded (as long as not trailing).
            size_t len = type->meta.array_info.num_elements;
            const char * ptr = (const char *)p;
            while (len > 0 && ptr[len - 1] == '\0')
                len--;
            sv_setpvn(sv, ptr, len);
            return;
        }
        if (element_type->meta.primitive_id == INFIX_PRIMITIVE_UINT8) {
            // uchar[] / uint8[]: Treat as raw binary blob, read full length.
            sv_setpvn(sv, (const char *)p, type->meta.array_info.num_elements);
            return;
        }
    }

    // Standard array handling (ArrayRef of values)
    AV * av;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        av = (AV *)SvRV(sv);
        av_clear(av);
    }
    else {
        av = newAV();
        sv_setsv(sv, sv_2mortal(newRV_noinc(MUTABLE_SV(av))));
    }
    size_t num_elements = type->meta.array_info.num_elements;
    size_t element_size = infix_type_get_size(element_type);
    av_extend(av, num_elements);
    for (size_t i = 0; i < num_elements; ++i) {
        void * element_ptr = (char *)p + (i * element_size);
        SV * element_sv = newSV(0);
        ptr2sv(aTHX_ affix, element_ptr, element_sv, element_type);
        av_push(av, element_sv);
    }
}

static void pull_reverse_trampoline(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    sv_setiv(sv, PTR2IV(*(void **)p));
}

static void pull_enum(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    ptr2sv(aTHX_ affix, p, sv, type->meta.enum_info.underlying_type);
}

static void pull_enum_dualvar(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    // We assume standard 'e:int' (int32/64 based on platform 'int').
    // But type->meta.enum_info.underlying_type tells us the exact size.
    const infix_type * int_type = type->meta.enum_info.underlying_type;
    IV val = 0;

    // Quick and dirty reader based on size.
    // Ideally use 'ptr2sv' to get the IV, then upgrade.
    // Optimization: Inline specific sizes.
    size_t size = infix_type_get_size(int_type);

    if (size == 4)
        val = *(int32_t *)p;
    else if (size == 8)
        val = *(int64_t *)p;
    else if (size == 1)
        val = *(int8_t *)p;
    else if (size == 2)
        val = *(int16_t *)p;
    else
        val = *(int *)p;  // Fallback?

    // Set the Integer Value
    sv_setiv(sv, val);

    // Look up the Name
    dMY_CXT;
    const char * type_name = infix_type_get_name(type);

    if (type_name) {
        SV ** enum_map_ptr = hv_fetch(MY_CXT.enum_registry, type_name, strlen(type_name), 0);
        if (enum_map_ptr) {
            HV * enum_map = (HV *)SvRV(*enum_map_ptr);

            // Look up the integer value in the hash
            // Keys in Perl hashes are strings, so we format the IV.
            char key[64];
            snprintf(key, 64, "%" IVdf, val);

            SV ** name_sv = hv_fetch(enum_map, key, strlen(key), 0);
            if (name_sv && SvPOK(*name_sv)) {
                // Set the String Value (creating Dualvar)
                // sv_setpv overwrites the IV. We need to set PV while keeping IOK.
                const char * name_str = SvPV_nolen(*name_sv);
                sv_setpv(sv, name_str);  // Sets PV, clears IV? No, usually clears flags, right?

                // Force dualvar state by manually reinstating the IV
                SvIV_set(sv, val);
                SvIOK_on(sv);  // It is valid Integer
                // SvPOK is on from sv_setpv
            }
        }
    }
}

static void pull_complex(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    AV * av;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        av = (AV *)SvRV(sv);
        av_clear(av);
    }
    else {
        av = newAV();
        sv_setsv(sv, sv_2mortal(newRV_noinc(MUTABLE_SV(av))));
    }
    const infix_type * base_type = type->meta.complex_info.base_type;
    size_t base_size = infix_type_get_size(base_type);
    SV * real_sv = newSV(0);
    ptr2sv(aTHX_ affix, p, real_sv, base_type);
    av_push(av, real_sv);
    SV * imag_sv = newSV(0);
    ptr2sv(aTHX_ affix, (char *)p + base_size, imag_sv, base_type);
    av_push(av, imag_sv);
}

static void pull_vector(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * p) {
    AV * av;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        av = (AV *)SvRV(sv);
        av_clear(av);
    }
    else {
        av = newAV();
        sv_setsv(sv, sv_2mortal(newRV_noinc(MUTABLE_SV(av))));
    }
    const infix_type * element_type = type->meta.vector_info.element_type;
    size_t num_elements = type->meta.vector_info.num_elements;
    size_t element_size = infix_type_get_size(element_type);
    av_extend(av, num_elements);
    for (size_t i = 0; i < num_elements; ++i) {
        void * element_ptr = (char *)p + (i * element_size);
        SV * element_sv = newSV(0);
        ptr2sv(aTHX_ affix, element_ptr, element_sv, element_type);
        av_push(av, element_sv);
    }
}

static void pull_pointer_as_string(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    void * c_ptr = *(void **)ptr;
    if (c_ptr == nullptr)
        sv_setsv(sv, &PL_sv_undef);
    else
        sv_setpv(sv, (const char *)c_ptr);
}

static void pull_pointer_as_struct(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    void * c_ptr = *(void **)ptr;
    if (c_ptr == nullptr)
        sv_setsv(sv, &PL_sv_undef);
    else {
        const infix_type * pointee_type = type->meta.pointer_info.pointee_type;
        pull_struct(aTHX_ affix, sv, pointee_type, c_ptr);
    }
}

static void pull_pointer_as_array(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    void * c_ptr = *(void **)ptr;
    if (c_ptr == nullptr)
        sv_setsv(sv, &PL_sv_undef);
    else {
        const infix_type * pointee_type = type->meta.pointer_info.pointee_type;
        pull_array(aTHX_ affix, sv, pointee_type, c_ptr);
    }
}

static void pull_pointer_as_pin(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    void * c_ptr = *(void **)ptr;

    if (c_ptr == nullptr) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    Affix_Pin * pin;
    Newxz(pin, 1, Affix_Pin);
    pin->pointer = c_ptr;

    // Ensure we point to the content type, not Pointer[Content]
    pin->type = _unwrap_pin_type(type);
    pin->managed = false;

    SV * obj_data = newSV(0);
    sv_setiv(obj_data, PTR2IV(pin));

    // Create the Reference
    SV * rv = sv_2mortal(newRV_noinc(obj_data));
    sv_magicext(obj_data, nullptr, PERL_MAGIC_ext, &Affix_pin_vtbl, (const char *)pin, 0);

    // Update the target SV
    sv_setsv(sv, rv);
}

static void pull_sv(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    void * c_ptr = *(void **)ptr;
    if (c_ptr == nullptr)
        sv_setsv(sv, &PL_sv_undef);
    else
        sv_setsv(sv, (SV *)c_ptr);
}

static void pull_file(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    PERL_UNUSED_VAR(affix);
    PERL_UNUSED_VAR(type);
    FILE * fp = *(FILE **)ptr;
    if (!fp) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    // Duplicate FD to avoid double-close issues
    int fd =
#ifdef _WIN32
        _fileno
#else
        fileno
#endif
        (fp);
    if (fd < 0) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    int new_fd = PerlLIO_dup(fd);
    if (new_fd < 0) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    PerlIO * new_pio = PerlIO_fdopen(new_fd, "r+");  // Assuming R/W safe
    if (!new_pio) {
        PerlLIO_close(new_fd);
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    GV * gv = newGVgen("Affix::FileHandle");
    if (do_open(gv, "+<&", 3, FALSE, 0, 0, new_pio))
        sv_setsv(sv, sv_2mortal(newRV((SV *)gv)));
    else {
        PerlIO_close(new_pio);
        sv_setsv(sv, &PL_sv_undef);
    }
}

static void pull_perlio(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    PERL_UNUSED_VAR(affix);
    PERL_UNUSED_VAR(type);
    PerlIO * pio = *(PerlIO **)ptr;
    if (!pio) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    int fd = PerlIO_fileno(pio);
    if (fd < 0) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    int new_fd = PerlLIO_dup(fd);
    if (new_fd < 0) {
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    PerlIO * new_pio = PerlIO_fdopen(new_fd, "r+");
    if (!new_pio) {
        PerlLIO_close(new_fd);
        sv_setsv(sv, &PL_sv_undef);
        return;
    }

    GV * gv = newGVgen("Affix::FileHandle");
    if (do_open(gv, "+<&", 3, FALSE, 0, 0, new_pio))
        sv_setsv(sv, sv_2mortal(newRV((SV *)gv)));
    else {
        PerlIO_close(new_pio);
        sv_setsv(sv, &PL_sv_undef);
    }
}

static void push_stringlist(pTHX_ Affix * affix, SV * sv, void * c_arg_ptr) {
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV) {
        *(void **)c_arg_ptr = NULL;
        return;
    }

    AV * av = (AV *)SvRV(sv);
    size_t len = av_len(av) + 1;

    // Allocate array of pointers + 1 for NULL terminator
    // We use the args_arena so this memory is automatically freed after the call
    char ** list = (char **)infix_arena_alloc(affix->args_arena, (len + 1) * sizeof(char *), _Alignof(char *));

    for (size_t i = 0; i < len; ++i) {
        SV ** elem = av_fetch(av, i, 0);
        if (elem && SvPOK(*elem)) {
            STRLEN slen;
            const char * s = SvPV(*elem, slen);
            // Copy string content to arena to ensure stability
            char * buf = (char *)infix_arena_alloc(affix->args_arena, slen + 1, 1);
            memcpy(buf, s, slen + 1);
            list[i] = buf;
        }
        else {
            list[i] = NULL;
        }
    }
    list[len] = NULL;  // Terminator

    *(char ***)c_arg_ptr = list;
}

static void pull_stringlist(pTHX_ Affix * affix, SV * sv, const infix_type * type, void * ptr) {
    PERL_UNUSED_VAR(affix);
    PERL_UNUSED_VAR(type);
    char ** list = *(char ***)ptr;

    AV * av = newAV();
    if (list) {
        while (*list) {
            av_push(av, newSVpv(*list, 0));
            list++;
        }
    }

    // Return ArrayRef
    sv_setsv(sv, sv_2mortal(newRV_noinc(MUTABLE_SV(av))));
}

// Mutable Buffer: Passes pointer to Perl's string buffer directly.
// Allows C to write to the Perl scalar.
static void push_buffer(pTHX_ Affix * affix, SV * sv, void * c_arg_ptr) {
    PERL_UNUSED_VAR(affix);
    if (!SvOK(sv)) {
        *(void **)c_arg_ptr = NULL;
        return;
    }

    // De-ref if it's a reference (e.g., passing \$scalar)
    if (SvROK(sv))
        sv = SvRV(sv);

    if (SvREADONLY(sv))
        croak("Cannot pass read-only scalar as a mutable Buffer");

    // Force string upgrade if needed, but don't copy
    SvPV_force_nolen(sv);

    // Return raw pointer to SV's buffer
    *(char **)c_arg_ptr = SvPVX(sv);
}

// SockAddr: Passes pointer to Perl's string buffer (readonly ok).
static void push_sockaddr(pTHX_ Affix * affix, SV * sv, void * c_arg_ptr) {
    PERL_UNUSED_VAR(affix);
    if (!SvOK(sv)) {
        *(void **)c_arg_ptr = NULL;
        return;
    }

    // De-ref
    if (SvROK(sv))
        sv = SvRV(sv);

    if (!SvPOK(sv))
        croak("SockAddr argument must be a packed string");

    *(void **)c_arg_ptr = SvPVX(sv);
}

static const Affix_Pull pull_handlers[] = {[INFIX_PRIMITIVE_BOOL] = pull_bool,
                                           [INFIX_PRIMITIVE_SINT8] = pull_sint8,
                                           [INFIX_PRIMITIVE_UINT8] = pull_uint8,
                                           [INFIX_PRIMITIVE_SINT16] = pull_sint16,
                                           [INFIX_PRIMITIVE_UINT16] = pull_uint16,
                                           [INFIX_PRIMITIVE_SINT32] = pull_sint32,
                                           [INFIX_PRIMITIVE_UINT32] = pull_uint32,
                                           [INFIX_PRIMITIVE_SINT64] = pull_sint64,
                                           [INFIX_PRIMITIVE_UINT64] = pull_uint64,
                                           [INFIX_PRIMITIVE_FLOAT] = pull_float,
                                           [INFIX_PRIMITIVE_DOUBLE] = pull_double,
                                           [INFIX_PRIMITIVE_LONG_DOUBLE] = pull_long_double,
#if !defined(INFIX_COMPILER_MSVC)
                                           [INFIX_PRIMITIVE_SINT128] = pull_sint128,
                                           [INFIX_PRIMITIVE_UINT128] = pull_uint128
#endif
};

Affix_Pull get_pull_handler(pTHX_ const infix_type * type) {
    switch (type->category) {
    case INFIX_TYPE_PRIMITIVE:
        return pull_handlers[type->meta.primitive_id];
    case INFIX_TYPE_POINTER:
        {
            const char * name = infix_type_get_name(type);
            if (name) {
                if (strEQ(name, "Buffer") || strEQ(name, "@Buffer"))
                    return pull_pointer_as_pin;  // Fallback: Return pin to buffer
                if (strEQ(name, "SockAddr") || strEQ(name, "@SockAddr"))
                    return pull_pointer_as_pin;  // Fallback: Return pin to struct
                if (strEQ(name, "StringList") || strEQ(name, "@StringList"))
                    return pull_stringlist;
                if (strEQ(name, "SV") || strEQ(name, "@SV"))
                    return pull_sv;
            }
            if (name != nullptr)
                return pull_pointer_as_pin;

            const infix_type * pointee_type = type->meta.pointer_info.pointee_type;
            const char * pointee_name = infix_type_get_name(pointee_type);
            if (pointee_name && (strEQ(pointee_name, "SV") || strEQ(pointee_name, "@SV")))
                return pull_sv;
            if (pointee_name && (strEQ(pointee_name, "File") || strEQ(pointee_name, "@File")))
                return pull_file;
            if (pointee_name && (strEQ(pointee_name, "PerlIO") || strEQ(pointee_name, "@PerlIO")))
                return pull_perlio;

            if (pointee_type->category == INFIX_TYPE_PRIMITIVE) {
                if (pointee_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                    pointee_type->meta.primitive_id == INFIX_PRIMITIVE_UINT8) {
                    return pull_pointer_as_string;
                }
#if defined(INFIX_OS_WINDOWS)
                // Wide string return check
                if (infix_type_get_size(pointee_type) == sizeof(wchar_t))
                    return pull_pointer_as_wstring;
#endif
            }
            if (pointee_type->category == INFIX_TYPE_STRUCT)
                return pull_pointer_as_pin;
            if (pointee_type->category == INFIX_TYPE_ARRAY)
                return pull_pointer_as_pin;

            return pull_pointer_as_pin;
        }
    case INFIX_TYPE_STRUCT:
        {
            const char * name = infix_type_get_name(type);
            if (name && (strEQ(name, "SV") || strEQ(name, "@SV")))
                return pull_sv;
            return pull_struct;
        }
    case INFIX_TYPE_UNION:
        return pull_union;
    case INFIX_TYPE_ARRAY:
        return pull_array;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        return pull_reverse_trampoline;
    case INFIX_TYPE_ENUM:
        {  // Check if we have registered values for this enum
            dMY_CXT;
            const char * name = infix_type_get_name(type);
            if (name && hv_exists(MY_CXT.enum_registry, name, strlen(name)))
                return pull_enum_dualvar;
        }
        // Fallback to simple integer
        return pull_enum;
    case INFIX_TYPE_COMPLEX:
        return pull_complex;
    case INFIX_TYPE_VECTOR:
        return pull_vector;
    case INFIX_TYPE_VOID:
        return pull_void;
    default:
        return nullptr;
    }
}

void ptr2sv(pTHX_ Affix * affix, void * c_ptr, SV * perl_sv, const infix_type * type) {
    Affix_Pull h = get_pull_handler(aTHX_ type);
    if (!h) {
        char buffer[128];
        if (infix_type_print(buffer, sizeof(buffer), type, INFIX_DIALECT_SIGNATURE) == INFIX_SUCCESS)
            croak("Cannot convert C type to Perl SV. Unsupported type: %s", buffer);
        croak("Cannot convert C type to Perl SV. Unsupported type.");
    }
    h(aTHX_ affix, perl_sv, type, c_ptr);
}

static int _get_pointer_depth(const infix_type * t) {
    int depth = 0;
    while (t && t->category == INFIX_TYPE_POINTER) {
        depth++;
        t = t->meta.pointer_info.pointee_type;
    }
    return depth;
}

void sv2ptr(pTHX_ Affix * affix, SV * perl_sv, void * c_ptr, const infix_type * type) {
    switch (type->category) {
    case INFIX_TYPE_PRIMITIVE:
        primitive_push_handlers[type->meta.primitive_id](aTHX_ affix, perl_sv, c_ptr);
        break;
    case INFIX_TYPE_POINTER:
        {
            if (!SvOK(perl_sv)) {
                *(void **)c_ptr = nullptr;
                return;
            }

            const char * type_name = infix_type_get_name(type);
            if (type_name) {
                if (strEQ(type_name, "Buffer") || strEQ(type_name, "@Buffer")) {
                    push_buffer(aTHX_ affix, perl_sv, c_ptr);
                    return;
                }
                if (strEQ(type_name, "SockAddr") || strEQ(type_name, "@SockAddr")) {
                    push_sockaddr(aTHX_ affix, perl_sv, c_ptr);
                    return;
                }
                if (strEQ(type_name, "StringList") || strEQ(type_name, "@StringList")) {
                    push_stringlist(aTHX_ affix, perl_sv, c_ptr);
                    return;
                }
            }
            const infix_type * pointee_type = type->meta.pointer_info.pointee_type;
            const char * pointee_name = infix_type_get_name(pointee_type);
            if (pointee_name && (strEQ(pointee_name, "SV") || strEQ(pointee_name, "@SV"))) {
                *(SV **)c_ptr = perl_sv;
                SvREFCNT_inc(perl_sv);
                return;
            }
            if (pointee_name && (strEQ(pointee_name, "File") || strEQ(pointee_name, "@File"))) {
                IO * io = sv_2io(perl_sv);
                if (!io)
                    croak("Argument is not an IO handle");
                // IoIFP gets the PerlIO*, PerlIO_findFILE gets the stdio FILE*
                // Note: This might flush buffers.
                PerlIO * pio = IoIFP(io);
                *(FILE **)c_ptr = PerlIO_findFILE(pio);
                return;
            }
            if (pointee_name && (strEQ(pointee_name, "PerlIO") || strEQ(pointee_name, "@PerlIO"))) {
                IO * io = sv_2io(perl_sv);
                if (!io)
                    croak("Argument is not an IO handle");
                *(PerlIO **)c_ptr = IoIFP(io);
                return;
            }

            if (pointee_type->category == INFIX_TYPE_REVERSE_TRAMPOLINE) {
                push_reverse_trampoline(aTHX_ affix, pointee_type, perl_sv, c_ptr);
                return;
            }
            if (is_pin(aTHX_ perl_sv)) {
                Affix_Pin * p = _get_pin_from_sv(aTHX_ perl_sv);
                if (p) {
                    const infix_type * t_target = type->meta.pointer_info.pointee_type;
                    const infix_type * t_source = p->type;

                    while (t_target && t_target->category == INFIX_TYPE_POINTER) {
                        if (t_target->meta.pointer_info.pointee_type->category == INFIX_TYPE_VOID)
                            break;

                        if (!t_source || t_source->category != INFIX_TYPE_POINTER) {
                            croak("Type Mismatch: Expected pointer depth %d, got %d",
                                  _get_pointer_depth(type),
                                  _get_pointer_depth(p->type) + 1);
                        }

                        t_target = t_target->meta.pointer_info.pointee_type;
                        t_source = t_source->meta.pointer_info.pointee_type;
                    }
                    *(void **)c_ptr = p->pointer;
                }
                else
                    *(void **)c_ptr = nullptr;
            }
            else if (SvIOK(perl_sv))
                // Allow passing raw integer addresses as pointers
                *(void **)c_ptr = INT2PTR(void *, SvUV(perl_sv));
            else if (SvPOK(perl_sv))
                *(const char **)c_ptr = SvPV_nolen(perl_sv);
            else if (SvROK(perl_sv)) {
                SV * const rv = SvRV(perl_sv);

                if (pointee_type->category == INFIX_TYPE_VOID) {
                    if (SvTYPE(rv) == SVt_PVGV || SvTYPE(rv) == SVt_PVIO) {
                        IO * io = sv_2io(perl_sv);
                        if (io) {
                            PerlIO * pio = IoIFP(io);
                            *(FILE **)c_ptr = PerlIO_findFILE(pio);
                            return;
                        }
                    }
                }

                if (SvTYPE(rv) == SVt_PVAV) {
                    AV * av = (AV *)SvRV(perl_sv);
                    size_t len = av_len(av) + 1;
                    size_t element_size = infix_type_get_size(pointee_type);
                    size_t total_size = len * element_size;
                    char * c_array;
                    Newx(c_array, total_size, char);
                    for (size_t i = 0; i < len; ++i) {
                        SV ** elem_sv_ptr = av_fetch(av, i, 0);
                        if (elem_sv_ptr)
                            sv2ptr(aTHX_ affix, *elem_sv_ptr, c_array + (i * element_size), pointee_type);
                    }
                    *(void **)c_ptr = c_array;
                    return;
                }
                else if (SvTYPE(rv) == SVt_PVHV) {
                    size_t size = infix_type_get_size(pointee_type);
                    size_t align = infix_type_get_alignment(pointee_type);
                    if (align < 1)
                        align = 1;
                    void * temp_ptr;
                    if (affix && affix->args_arena)
                        temp_ptr = infix_arena_alloc(affix->args_arena, size, align);
                    else
                        temp_ptr = safecalloc(1, size);
                    memset(temp_ptr, 0, size);
                    sv2ptr(aTHX_ affix, rv, temp_ptr, pointee_type);
                    *(void **)c_ptr = temp_ptr;
                    return;
                }

                size_t size = infix_type_get_size(pointee_type);
                size_t align = infix_type_get_alignment(pointee_type);
                if (align < 1)
                    align = 1;
                void * temp_ptr;
                if (affix && affix->args_arena)
                    temp_ptr = infix_arena_alloc(affix->args_arena, size, align);
                else
                    temp_ptr = safecalloc(1, size);
                memset(temp_ptr, 0, size);

                if (pointee_type->category == INFIX_TYPE_PRIMITIVE || pointee_type->category == INFIX_TYPE_ENUM)
                    sv2ptr(aTHX_ affix, rv, temp_ptr, pointee_type);
                else
                    sv2ptr(aTHX_ affix, perl_sv, temp_ptr, pointee_type);
                *(void **)c_ptr = temp_ptr;
            }
            else {
                char signature_buf[256];
                (void)infix_type_print(
                    signature_buf, sizeof(signature_buf), (infix_type *)type, INFIX_DIALECT_SIGNATURE);
                croak("sv2ptr cannot handle this kind of pointer conversion yet: %s", signature_buf);
            }
        }
        break;
    case INFIX_TYPE_STRUCT:
        {
            const char * name = infix_type_get_name(type);
            if (name && (strEQ(name, "SV") || strEQ(name, "@SV"))) {
                *(SV **)c_ptr = perl_sv;
                SvREFCNT_inc(perl_sv);
                return;
            }
            push_struct(aTHX_ affix, type, perl_sv, c_ptr);
        }
        break;
    case INFIX_TYPE_UNION:
        push_union(aTHX_ affix, type, perl_sv, c_ptr);
        break;
    case INFIX_TYPE_ARRAY:
        push_array(aTHX_ affix, type, perl_sv, c_ptr);
        break;
    case INFIX_TYPE_REVERSE_TRAMPOLINE:
        push_reverse_trampoline(aTHX_ affix, type, perl_sv, c_ptr);
        break;
    case INFIX_TYPE_ENUM:
        sv2ptr(aTHX_ affix, perl_sv, c_ptr, type->meta.enum_info.underlying_type);
        break;
    default:
        croak("sv2ptr cannot convert this complex type");
        break;
    }
}
void push_struct(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p) {
    HV * hv;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)
        hv = (HV *)SvRV(sv);
    else if (SvTYPE(sv) == SVt_PVHV)
        hv = (HV *)sv;
    else
        croak("Expected a HASH or HASH reference for struct marshalling");
    for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
        const infix_struct_member * member = &type->meta.aggregate_info.members[i];
        if (!member->name)
            continue;
        void * member_ptr = (char *)p + member->offset;
        SV ** member_sv_ptr = hv_fetch(hv, member->name, strlen(member->name), 0);
        if (member_sv_ptr)
            sv2ptr(aTHX_ affix, *member_sv_ptr, member_ptr, member->type);
    }
}
void push_union(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p) {
    HV * hv;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV)
        hv = (HV *)SvRV(sv);
    else if (SvTYPE(sv) == SVt_PVHV)
        hv = (HV *)sv;
    else
        croak("Expected a HASH or HASH reference for union marshalling");
    for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
        const infix_struct_member * member = &type->meta.aggregate_info.members[i];
        if (member->name) {
            SV ** member_sv_ptr = hv_fetch(hv, member->name, strlen(member->name), 0);
            if (member_sv_ptr) {
                sv2ptr(aTHX_ affix, *member_sv_ptr, (char *)p + member->offset, member->type);
                return;
            }
        }
    }
}
void push_array(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p) {
    const infix_type * element_type = type->meta.array_info.element_type;
    size_t c_array_len = type->meta.array_info.num_elements;
    if (element_type->category == INFIX_TYPE_PRIMITIVE &&
        (element_type->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
         element_type->meta.primitive_id == INFIX_PRIMITIVE_UINT8) &&
        SvPOK(sv)) {
        STRLEN perl_len;
        const char * perl_str = SvPV(sv, perl_len);
        if (perl_len >= c_array_len) {
            memcpy(p, perl_str, c_array_len - 1);
            ((char *)p)[c_array_len - 1] = '\0';
        }
        else
            memcpy(p, perl_str, perl_len + 1);
        return;
    }
    if (!SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV)
        croak("Expected an ARRAY reference for array marshalling");
    AV * av = (AV *)SvRV(sv);
    size_t perl_array_len = av_len(av) + 1;
    size_t num_to_copy = perl_array_len < c_array_len ? perl_array_len : c_array_len;
    size_t element_size = infix_type_get_size(element_type);
    for (size_t i = 0; i < num_to_copy; ++i) {
        SV ** element_sv_ptr = av_fetch(av, i, 0);
        if (element_sv_ptr) {
            void * element_ptr = (char *)p + (i * element_size);
            sv2ptr(aTHX_ affix, *element_sv_ptr, element_ptr, element_type);
        }
    }
}
void push_reverse_trampoline(pTHX_ Affix * affix, const infix_type * type, SV * sv, void * p) {
    PERL_UNUSED_VAR(affix);
    dMY_CXT;
    SV * coderef_cv = nullptr;
    if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)
        coderef_cv = SvRV(sv);
    else if (SvTYPE(sv) == SVt_PVCV)
        coderef_cv = sv;
    if (coderef_cv) {
        char key[32];
        snprintf(key, sizeof(key), "%p", (void *)coderef_cv);
        SV ** entry_sv_ptr = hv_fetch(MY_CXT.callback_registry, key, strlen(key), 0);
        if (entry_sv_ptr) {
            Implicit_Callback_Magic * magic_data = INT2PTR(Implicit_Callback_Magic *, SvIV(*entry_sv_ptr));
            *(void **)p = infix_reverse_get_code(magic_data->reverse_ctx);
        }
        else {
            Affix_Callback_Data * cb_data;
            Newxz(cb_data, 1, Affix_Callback_Data);
            cb_data->coderef_rv = newRV_inc(coderef_cv);
            storeTHX(cb_data->perl);
            infix_type * ret_type = type->meta.func_ptr_info.return_type;
            size_t num_args = type->meta.func_ptr_info.num_args;
            size_t num_fixed_args = type->meta.func_ptr_info.num_fixed_args;
            infix_type ** arg_types = nullptr;
            if (num_args > 0) {
                Newx(arg_types, num_args, infix_type *);
                for (size_t i = 0; i < num_args; ++i)
                    arg_types[i] = type->meta.func_ptr_info.args[i].type;
            }
            infix_reverse_t * reverse_ctx = nullptr;

            infix_status status = infix_reverse_create_closure_manual(&reverse_ctx,
                                                                      ret_type,
                                                                      arg_types,
                                                                      num_args,
                                                                      num_fixed_args,
                                                                      (void *)_affix_callback_handler_entry,
                                                                      (void *)cb_data);
            if (arg_types)
                Safefree(arg_types);
            if (status != INFIX_SUCCESS) {
                SvREFCNT_dec(cb_data->coderef_rv);
                safefree(cb_data);
                croak("Failed to create callback: %s", infix_get_last_error().message);
            }
            Implicit_Callback_Magic * magic_data;
            Newxz(magic_data, 1, Implicit_Callback_Magic);
            magic_data->reverse_ctx = reverse_ctx;
            hv_store(MY_CXT.callback_registry, key, strlen(key), newSViv(PTR2IV(magic_data)), 0);
            *(void **)p = infix_reverse_get_code(reverse_ctx);
        }
    }
    else if (!SvOK(sv))
        *(void **)p = nullptr;
    else
        croak("Argument for a callback must be a code reference or undef.");
}
static SV * _format_parse_error(pTHX_ const char * context_msg, const char * signature, infix_error_details_t err) {
    STRLEN sig_len = strlen(signature);
    int radius = 20;
    size_t start = (err.position > radius) ? (err.position - radius) : 0;
    size_t end = (err.position + radius < sig_len) ? (err.position + radius) : sig_len;
    const char * start_indicator = (start > 0) ? "... " : "";
    const char * end_indicator = (end < sig_len) ? " ..." : "";
    int start_indicator_len = (start > 0) ? 4 : 0;
    char snippet[128];
    snprintf(
        snippet, sizeof(snippet), "%s%.*s%s", start_indicator, (int)(end - start), signature + start, end_indicator);
    char pointer[128];
    int caret_pos = err.position - start + start_indicator_len;
    snprintf(pointer, sizeof(pointer), "%*s^", caret_pos, "");
    return sv_2mortal(newSVpvf("Failed to parse signature %s:\n\n  %s\n  %s\n\nError: %s (at position %zu)",
                               context_msg,
                               snippet,
                               pointer,
                               err.message,
                               err.position));
}
XS_INTERNAL(Affix_Lib_as_string) {
    dVAR;
    dXSARGS;
    if (items < 1)
        croak_xs_usage(cv, "$lib");
    IV RETVAL;
    {
        infix_library_t * lib;
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lib = INT2PTR(infix_library_t *, tmp);
        RETVAL = PTR2IV(lib->handle);
    }
    XSRETURN_IV(RETVAL);
};
XS_INTERNAL(Affix_Lib_DESTROY) {
    dXSARGS;
    dMY_CXT;
    if (items != 1)
        croak_xs_usage(cv, "$lib");
    IV tmp = SvIV((SV *)SvRV(ST(0)));
    infix_library_t * lib = INT2PTR(infix_library_t *, tmp);
    if (MY_CXT.lib_registry) {
        hv_iterinit(MY_CXT.lib_registry);
        HE * he;
        while ((he = hv_iternext(MY_CXT.lib_registry))) {
            SV * entry_sv = HeVAL(he);
            LibRegistryEntry * entry = INT2PTR(LibRegistryEntry *, SvIV(entry_sv));
            if (entry->lib == lib) {
                entry->ref_count--;
                if (entry->ref_count == 0) {
                    infix_library_close(entry->lib);
                    safefree(entry);
                    hv_delete_ent(MY_CXT.lib_registry, HeKEY_sv(he), G_DISCARD, 0);
                }
                break;
            }
        }
    }
    XSRETURN_EMPTY;
}
XS_INTERNAL(Affix_load_library) {
    dXSARGS;
    dMY_CXT;
    if (items != 1)
        croak_xs_usage(cv, "library_path");
    const char * path = SvPV_nolen(ST(0));
    SV ** entry_sv_ptr = hv_fetch(MY_CXT.lib_registry, path, strlen(path), 0);
    if (entry_sv_ptr) {
        LibRegistryEntry * entry = INT2PTR(LibRegistryEntry *, SvIV(*entry_sv_ptr));
        entry->ref_count++;
        SV * obj_data = newSV(0);
        sv_setiv(obj_data, PTR2IV(entry->lib));
        ST(0) = sv_2mortal(sv_bless(newRV_inc(obj_data), gv_stashpv("Affix::Lib", GV_ADD)));
        XSRETURN(1);
    }
    infix_library_t * lib = infix_library_open(path);
    if (lib) {
        LibRegistryEntry * new_entry;
        Newxz(new_entry, 1, LibRegistryEntry);
        new_entry->lib = lib;
        new_entry->ref_count = 1;
        hv_store(MY_CXT.lib_registry, path, strlen(path), newSViv(PTR2IV(new_entry)), 0);
        SV * obj_data = newSV(0);
        sv_setiv(obj_data, PTR2IV(lib));
        ST(0) = sv_2mortal(sv_bless(newRV_inc(obj_data), gv_stashpv("Affix::Lib", GV_ADD)));
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}
XS_INTERNAL(Affix_get_last_error_message) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    infix_error_details_t err = infix_get_last_error();
    if (err.message[0] != '\0')
        ST(0) = sv_2mortal(newSVpv(err.message, 0));
#if defined(INFIX_OS_WINDOWS)
    else if (err.system_error_code != 0) {
        char buf[256];
        FormatMessageA(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                       nullptr,
                       err.system_error_code,
                       0,
                       buf,
                       sizeof(buf),
                       nullptr);
        ST(0) = sv_2mortal(newSVpvf("System error: %s (code %ld)", buf, err.system_error_code));
    }
#endif
    else
        ST(0) = sv_2mortal(newSVpvf("Infix error code %d at position %zu", (int)err.code, err.position));
    XSRETURN(1);
}

Affix_Pin * _get_pin_from_sv(pTHX_ SV * sv) {
    if (!sv || !SvOK(sv) || !SvROK(sv) || !SvMAGICAL(SvRV(sv)))
        return nullptr;
    MAGIC * mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &Affix_pin_vtbl);
    if (mg)
        return (Affix_Pin *)mg->mg_ptr;
    return nullptr;
}
static int Affix_set_pin(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin * pin = (Affix_Pin *)mg->mg_ptr;
    if (!pin || !pin->pointer || !pin->type)
        return 0;

    const infix_type * type_to_marshal = pin->type;

    if (pin->type->category == INFIX_TYPE_POINTER) {
        const infix_type * pointee = pin->type->meta.pointer_info.pointee_type;
        if (pointee->category == INFIX_TYPE_VOID) {
            if (pin->size > 0) {
                STRLEN perl_len;
                const char * perl_str = SvPV(sv, perl_len);
                size_t bytes_to_copy = (perl_len < pin->size) ? perl_len : pin->size;
                memcpy(pin->pointer, perl_str, bytes_to_copy);
                if (bytes_to_copy < pin->size)
                    memset((char *)pin->pointer + bytes_to_copy, 0, pin->size - bytes_to_copy);
                return 0;
            }
            else
                croak("Cannot assign a value to a dereferenced void pointer (opaque handle)");
        }
    }

    sv2ptr(aTHX_ nullptr, sv, pin->pointer, type_to_marshal);
    return 0;
}
static U32 Affix_len_pin(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin * pin = (Affix_Pin *)mg->mg_ptr;
    if (!pin || !pin->pointer || !pin->type) {
        if (SvTYPE(sv) == SVt_PVAV)
            return av_len(MUTABLE_AV(sv));
        return sv_len(sv);
    }
    return pin->type->size;
}
static int Affix_free_pin(pTHX_ SV * sv, MAGIC * mg) {
    PERL_UNUSED_VAR(sv);
    Affix_Pin * pin = (Affix_Pin *)mg->mg_ptr;
    if (pin == nullptr)
        return 0;
    if (pin->managed && pin->pointer)
        safefree(pin->pointer);
    if (pin->type_arena != nullptr)
        infix_arena_destroy(pin->type_arena);
    safefree(pin);
    mg->mg_ptr = nullptr;
    return 0;
}
static int Affix_get_pin(pTHX_ SV * sv, MAGIC * mg) {
    Affix_Pin * pin = (Affix_Pin *)mg->mg_ptr;
    if (!pin || !pin->pointer) {
        sv_setsv_mg(sv, &PL_sv_undef);
        return 0;
    }

    if (pin->type && pin->type->category == INFIX_TYPE_POINTER) {
        const infix_type * pointee = pin->type->meta.pointer_info.pointee_type;

        if (pointee->category == INFIX_TYPE_PRIMITIVE &&
            (pointee->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
             pointee->meta.primitive_id == INFIX_PRIMITIVE_UINT8)) {

            const char * str = (const char *)pin->pointer;
            if (str)
                sv_setpv(sv, str);
            else
                sv_setsv(sv, &PL_sv_undef);

            return 0;
        }
    }

    if (pin->type) {
        if (pin->type->category == INFIX_TYPE_POINTER &&
            pin->type->meta.pointer_info.pointee_type->category == INFIX_TYPE_VOID) {
            sv_setuv(sv, PTR2UV(pin->pointer));
        }
        else
            ptr2sv(aTHX_ nullptr, pin->pointer, sv, pin->type);
    }
    return 0;
}
bool is_pin(pTHX_ SV * sv) {
    if (!sv || !SvOK(sv) || !SvROK(sv) || !SvMAGICAL(SvRV(sv)))
        return false;
    return mg_findext(SvRV(sv), PERL_MAGIC_ext, &Affix_pin_vtbl) != nullptr;
}
void _pin_sv(pTHX_ SV * sv, const infix_type * type, void * pointer, bool managed) {
    if (SvREADONLY(sv))
        return;
    SvUPGRADE(sv, SVt_PVMG);
    MAGIC * mg = mg_findext(sv, PERL_MAGIC_ext, &Affix_pin_vtbl);
    Affix_Pin * pin;
    if (mg) {
        pin = (Affix_Pin *)mg->mg_ptr;
        if (pin && pin->managed && pin->pointer)
            safefree(pin->pointer);
        if (pin && pin->type_arena) {
            infix_arena_destroy(pin->type_arena);
            pin->type_arena = nullptr;
        }
    }
    else {
        Newxz(pin, 1, Affix_Pin);
        mg = sv_magicext(sv, nullptr, PERL_MAGIC_ext, &Affix_pin_vtbl, (const char *)pin, 0);
    }
    pin->pointer = pointer;
    pin->managed = managed;
    pin->type_arena = infix_arena_create(2048);
    if (!pin->type_arena) {
        safefree(pin);
        mg->mg_ptr = nullptr;
        croak("Failed to create memory arenas for pin's type information");
    }
    pin->type = _copy_type_graph_to_arena(pin->type_arena, type);
    if (!pin->type) {
        infix_arena_destroy(pin->type_arena);
        safefree(pin);
        mg->mg_ptr = nullptr;
        croak("Failed to copy type information into pin");
    }
}
XS_INTERNAL(Affix_find_symbol) {
    dXSARGS;
    if (items != 2 || !sv_isobject(ST(0)) || !sv_derived_from(ST(0), "Affix::Lib"))
        croak_xs_usage(cv, "Affix_Lib_object, symbol_name");
    IV tmp = SvIV((SV *)SvRV(ST(0)));
    infix_library_t * lib = INT2PTR(infix_library_t *, tmp);
    const char * name = SvPV_nolen(ST(1));
    void * symbol = infix_library_get_symbol(lib, name);
    if (symbol) {
        Affix_Pin * pin;
        Newxz(pin, 1, Affix_Pin);
        pin->pointer = symbol;
        pin->managed = false;
        pin->type_arena = infix_arena_create(256);
        infix_type * void_ptr_type = nullptr;
        if (infix_type_create_pointer_to(pin->type_arena, &void_ptr_type, infix_type_create_void()) != INFIX_SUCCESS) {
            safefree(pin);
            infix_arena_destroy(pin->type_arena);
            croak("Internal error: Failed to create pointer type for pin");
        }
        pin->type = void_ptr_type;
        SV * obj_data = newSV(0);
        sv_setiv(obj_data, PTR2IV(pin));
        SV * rv = newRV_inc(obj_data);
        sv_magicext(obj_data, nullptr, PERL_MAGIC_ext, &Affix_pin_vtbl, (const char *)pin, 0);
        ST(0) = sv_2mortal(rv);
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

XS_INTERNAL(Affix_pin) {
    dXSARGS;
    dMY_CXT;
    if (items != 4)
        croak_xs_usage(cv, "var, lib, symbol, type");
    SV * target_sv = ST(0);
    const char * lib_path_or_name = SvPV_nolen(ST(1));
    const char * symbol_name = SvPV_nolen(ST(2));
    const char * signature = SvPV_nolen(ST(3));
    infix_library_t * lib = infix_library_open(lib_path_or_name);
    if (lib == nullptr) {
        warn("Failed to load library from path '%s' for pinning: %s", lib_path_or_name, infix_get_last_error().message);
        XSRETURN_UNDEF;
    }
    void * ptr = infix_library_get_symbol(lib, symbol_name);
    infix_library_close(lib);
    if (ptr == nullptr) {
        warn("Failed to locate symbol '%s' in library '%s'", symbol_name, lib_path_or_name);
        XSRETURN_UNDEF;
    }
    infix_type * type = nullptr;
    infix_arena_t * arena = nullptr;
    if (infix_type_from_signature(&type, &arena, signature, MY_CXT.registry) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "for pin", signature, infix_get_last_error());
        warn_sv(err_sv);
        if (arena)
            infix_arena_destroy(arena);
        XSRETURN_UNDEF;
    }
    _pin_sv(aTHX_ target_sv, type, ptr, false);
    infix_arena_destroy(arena);
    XSRETURN_YES;
}

XS_INTERNAL(Affix_unpin) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "var");
    if (mg_findext(ST(0), PERL_MAGIC_ext, &Affix_pin_vtbl) && !sv_unmagicext(ST(0), PERL_MAGIC_ext, &Affix_pin_vtbl))
        XSRETURN_YES;
    XSRETURN_NO;
}

XS_INTERNAL(Affix_sizeof) {
    dXSARGS;
    dMY_CXT;
    if (items != 1)
        croak_xs_usage(cv, "type_signature");
    SV * type_sv = ST(0);
    const char * signature = _get_string_from_type_obj(aTHX_ type_sv);
    infix_type * type = nullptr;
    infix_arena_t * arena = nullptr;
    if (infix_type_from_signature(&type, &arena, signature, MY_CXT.registry) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "for sizeof", signature, infix_get_last_error());
        warn_sv(err_sv);
        if (arena)
            infix_arena_destroy(arena);
        XSRETURN_UNDEF;
    }
    size_t type_size = infix_type_get_size(type);
    infix_arena_destroy(arena);
    ST(0) = sv_2mortal(newSVuv(type_size));
    XSRETURN(1);
}

XS_INTERNAL(Affix_alignof) {
    dXSARGS;
    dMY_CXT;
    if (items != 1)
        croak_xs_usage(cv, "type_signature");
    SV * type_sv = ST(0);
    const char * signature = _get_string_from_type_obj(aTHX_ type_sv);
    infix_type * type = nullptr;
    infix_arena_t * arena = nullptr;
    if (infix_type_from_signature(&type, &arena, signature, MY_CXT.registry) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "for alignof", signature, infix_get_last_error());
        warn_sv(err_sv);
        if (arena)
            infix_arena_destroy(arena);
        XSRETURN_UNDEF;
    }
    size_t align = (type->category == INFIX_TYPE_ARRAY) ? type->alignment : infix_type_get_alignment(type);
    if (align == 0)
        align = 1;
    infix_arena_destroy(arena);
    ST(0) = sv_2mortal(newSVuv(align));
    XSRETURN(1);
}

XS_INTERNAL(Affix_offsetof) {
    dXSARGS;
    dMY_CXT;
    if (items != 2)
        croak_xs_usage(cv, "type_signature, member_name");
    SV * type_sv = ST(0);
    const char * signature = _get_string_from_type_obj(aTHX_ type_sv);
    const char * member_name = SvPV_nolen(ST(1));
    infix_type * type = nullptr;
    infix_arena_t * arena = nullptr;
    if (infix_type_from_signature(&type, &arena, signature, MY_CXT.registry) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "for offsetof", signature, infix_get_last_error());
        warn_sv(err_sv);
        if (arena)
            infix_arena_destroy(arena);
        XSRETURN_UNDEF;
    }

    if (type->category != INFIX_TYPE_STRUCT && type->category != INFIX_TYPE_UNION) {
        infix_arena_destroy(arena);
        warn("offsetof expects a Struct or Union type");
        XSRETURN_UNDEF;
    }

    size_t offset = 0;
    bool found = false;
    for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
        const infix_struct_member * m = &type->meta.aggregate_info.members[i];
        if (m->name && strEQ(m->name, member_name)) {
            offset = m->offset;
            found = true;
            break;
        }
    }
    infix_arena_destroy(arena);
    if (!found) {
        warn("Member '%s' not found in type '%s'", member_name, signature);
        XSRETURN_UNDEF;
    }
    ST(0) = sv_2mortal(newSVuv(offset));
    XSRETURN(1);
}

void _export_function(pTHX_ HV * _export, const char * what, const char * _tag) {
    SV ** tag = hv_fetch(_export, _tag, strlen(_tag), TRUE);
    if (tag && SvOK(*tag) && SvROK(*tag) && (SvTYPE(SvRV(*tag))) == SVt_PVAV)
        av_push((AV *)SvRV(*tag), newSVpv(what, 0));
    else {
        AV * av = newAV();
        av_push(av, newSVpv(what, 0));
        (void)hv_store(_export, _tag, strlen(_tag), newRV_noinc(MUTABLE_SV(av)), 0);
    }
}

void _affix_callback_handler_entry(infix_context_t * ctx, void * retval, void ** args) {
    Affix_Callback_Data * cb_data = (Affix_Callback_Data *)infix_reverse_get_user_data(ctx);
    if (!cb_data)
        return;
    dTHXa(cb_data->perl);
    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    size_t num_args = infix_reverse_get_num_args(ctx);

    for (size_t i = 0; i < num_args; ++i) {
        const infix_type * type = infix_reverse_get_arg_type(ctx, i);
        Affix_Pull puller = get_pull_handler(aTHX_ type);
        if (!puller)
            croak("Unsupported callback argument type");
        SV * arg_sv = newSV(0);
        puller(aTHX_ nullptr, arg_sv, type, args[i]);
        mXPUSHs(arg_sv);
    }
    PUTBACK;
    const infix_type * ret_type = infix_reverse_get_return_type(ctx);
    U32 call_flags = G_EVAL | G_KEEPERR | ((ret_type->category == INFIX_TYPE_VOID) ? G_VOID : G_SCALAR);
    size_t count = call_sv(cb_data->coderef_rv, call_flags);
    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "Perl callback died: %" SVf, ERRSV);
        sv_setsv(ERRSV, &PL_sv_undef);
        if (retval && !(call_flags & G_VOID))
            memset(retval, 0, infix_type_get_size(ret_type));
    }
    else if (call_flags & G_SCALAR) {
        SPAGAIN;
        SV * return_sv = (count == 1) ? POPs : &PL_sv_undef;
        sv2ptr(aTHX_ nullptr, return_sv, retval, ret_type);
        PUTBACK;
    }
    FREETMPS;
    LEAVE;
}

XS_INTERNAL(Affix_as_string) {
    dVAR;
    dXSARGS;
    if (items < 1)
        croak_xs_usage(cv, "$affix");
    {
        char * RETVAL;
        dXSTARG;
        Affix * affix;
        if (sv_derived_from(ST(0), "Affix")) {
            IV tmp = SvIV((SV *)SvRV(ST(0)));
            affix = INT2PTR(Affix *, tmp);
        }
        else
            croak("affix is not of type Affix");
        RETVAL = (char *)affix->infix->target_fn;
        sv_setpv(TARG, RETVAL);
        XSprePUSH;
        PUSHTARG;
    }
    XSRETURN(1);
};

XS_INTERNAL(Affix_END) {
    dXSARGS;
    dMY_CXT;
    PERL_UNUSED_VAR(items);
    if (MY_CXT.lib_registry) {
        hv_iterinit(MY_CXT.lib_registry);
        HE * he;
        while ((he = hv_iternext(MY_CXT.lib_registry))) {
            SV * entry_sv = HeVAL(he);
            LibRegistryEntry * entry = INT2PTR(LibRegistryEntry *, SvIV(entry_sv));
            if (entry) {
#if DEBUG > 0
                if (entry->ref_count > 0)
                    warn("Affix: library handle for '%s' has %d outstanding references at END.",
                         HeKEY(he),
                         (int)entry->ref_count);
#endif

                // This extra symbol check is here to prevent shared libs written in Go from crashing Affix.
                // The issue is that Go inits the full Go runtime when the lib is loaded but DOES NOT STOP
                // IT when the lib is unloaded. Threads and everything else still run and we crash when perl
                // exits. This only happens on Windows.
                // See:
                //  - https://github.com/golang/go/issues/43591
                //  - https://github.com/golang/go/issues/22192
                //  - https://github.com/golang/go/issues/11100
                if (entry->lib
#ifdef _WIN32
                    && infix_library_get_symbol(entry->lib, "_cgo_dummy_export") == nullptr
#endif
                )
                    infix_library_close(entry->lib);

                safefree(entry);
            }
        }
        hv_undef(MY_CXT.lib_registry);
        MY_CXT.lib_registry = nullptr;
    }
    if (MY_CXT.callback_registry) {
        hv_iterinit(MY_CXT.callback_registry);
        HE * he;
        while ((he = hv_iternext(MY_CXT.callback_registry))) {
            SV * entry_sv = HeVAL(he);
            Implicit_Callback_Magic * magic_data = INT2PTR(Implicit_Callback_Magic *, SvIV(entry_sv));
            if (magic_data) {
                infix_reverse_t * ctx = magic_data->reverse_ctx;
                if (ctx) {
                    Affix_Callback_Data * cb_data = (Affix_Callback_Data *)infix_reverse_get_user_data(ctx);
                    if (cb_data) {
                        SvREFCNT_dec(cb_data->coderef_rv);
                        safefree(cb_data);
                    }
                    infix_reverse_destroy(ctx);
                }
                safefree(magic_data);
            }
        }
        hv_undef(MY_CXT.callback_registry);
        MY_CXT.callback_registry = nullptr;
    }
    if (MY_CXT.registry) {
        infix_registry_destroy(MY_CXT.registry);
        MY_CXT.registry = nullptr;
    }
    if (MY_CXT.enum_registry) {
        // Values are HVs, we need to dec ref them?
        // hv_undef decreases refcounts of values automatically.
        hv_undef(MY_CXT.enum_registry);
        MY_CXT.enum_registry = nullptr;
    }
    if (MY_CXT.coercion_cache) {
        hv_undef(MY_CXT.coercion_cache);
        MY_CXT.coercion_cache = nullptr;
    }
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_register_enum_values) {
    dXSARGS;
    dMY_CXT;
    if (items != 2)
        croak_xs_usage(cv, "name, values_hashref");

    const char * name = SvPV_nolen(ST(0));
    SV * values_rv = ST(1);

    if (!SvROK(values_rv) || SvTYPE(SvRV(values_rv)) != SVt_PVHV)
        croak("Enum values must be a Hash Reference { Int => String }");

    // Store in registry. We create a copy or ref?
    // Let's store a new Reference to the HV to keep it alive.
    SV * hv_ref = newRV_inc(SvRV(values_rv));

    if (!hv_store(MY_CXT.enum_registry, name, strlen(name), hv_ref, 0))
        SvREFCNT_dec(hv_ref);
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_typedef) {
    dXSARGS;
    dMY_CXT;
    if (items < 1 || items > 2)
        croak_xs_usage(cv, "$name, [$type]");
    PING;
    SV * name_sv = ST(0);

    const char * raw_name = SvPV_nolen(name_sv);
    const char * name = raw_name;
    PING;
    if (name[0] == '@')
        name++;
    PING;
    SV * def_sv = sv_2mortal(newSVpvf("@%s", name));
    PING;
    if (items == 2) {
        PING;
        sv_catpv(def_sv, " = ");
        SV * type_sv = ST(1);
        const char * type_str = _get_string_from_type_obj(aTHX_ type_sv);
        if (!type_str)
            type_str = SvPV_nolen(type_sv);
        sv_catpv(def_sv, type_str);
    }
    sv_catpv(def_sv, ";");
    PING;
    if (infix_register_types(MY_CXT.registry, SvPV_nolen(def_sv)) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "in typedef", SvPV_nolen(def_sv), infix_get_last_error());
        warn_sv(err_sv);
        XSRETURN_UNDEF;
    }

#if DEBUG
    char * blah;
    Newxz(blah, 1024 * 5, char);
    infix_registry_print(blah, 1024 * 5, MY_CXT.registry);
    warn("registry: %s", blah);
#endif
    PING;
    HV * stash = CopSTASH(PL_curcop);
    bool sub_exists = false;
    PING;
    if (stash) {
        PING;
        SV ** entry = hv_fetch(stash, name, strlen(name), 0);
        if (entry && *entry && isGV(*entry)) {
            PING;
            if (GvCV((GV *)*entry))
                sub_exists = true;
        }
    }
    PING;
    if (!sub_exists) {
        PING;
        SV * type_name_sv = newSVpvf("@%s", name);
        newCONSTSUB(stash, (char *)name, type_name_sv);
    }
    PING;
    XSRETURN_YES;
}

XS_INTERNAL(Affix_defined_types) {
    dXSARGS;
    dMY_CXT;
    PERL_UNUSED_VAR(cv);

    size_t count = 0;
    infix_registry_iterator_t it_counter = infix_registry_iterator_begin(MY_CXT.registry);
    while (infix_registry_iterator_next(&it_counter))
        if (infix_registry_iterator_get_type(&it_counter))
            count++;

    if (GIMME_V == G_SCALAR) {
        ST(0) = sv_2mortal(newSVuv(count));
        XSRETURN(1);
    }
    if (count == 0)
        XSRETURN(0);

    EXTEND(SP, count);

    infix_registry_iterator_t it = infix_registry_iterator_begin(MY_CXT.registry);
    while (infix_registry_iterator_next(&it)) {
        if (infix_registry_iterator_get_type(&it)) {
            const char * name = infix_registry_iterator_get_name(&it);
            PUSHs(sv_2mortal(newSVpv(name, 0)));
        }
    }
    XSRETURN(count);
}

void _DumpHex(pTHX_ const void * addr, size_t len, const char * file, int line) {
    PING;
    if (addr == nullptr) {
        printf("Dumping %lu bytes from null pointer %p at %s line %d\n", (unsigned long)len, addr, file, line);
        fflush(stdout);
        return;
    }
    PING;
    fflush(stdout);
    int perLine = 16;
    if (perLine < 4 || perLine > 64)
        perLine = 16;
    size_t i;
    U8 * buff;
    PING;
    Newxz(buff, perLine + 1, U8);
    PING;
    const U8 * pc = (const U8 *)addr;
    PING;
    printf("Dumping %lu bytes from %p at %s line %d\n", (unsigned long)len, addr, file, line);
    PING;
    if (len == 0) {
        warn("ZERO LENGTH");
        return;
    }
    PING;
    for (i = 0; i < len; i++) {
        PING;
        if ((i % perLine) == 0) {
            PING;
            if (i != 0)
                printf(" | %s\n", buff);
            printf("#  %03zu ", i);
        }
        PING;
        printf(" %02x", pc[i]);
        PING;
        if ((pc[i] < 0x20) || (pc[i] > 0x7e))
            buff[i % perLine] = '.';
        else
            buff[i % perLine] = pc[i];
        PING;
        buff[(i % perLine) + 1] = '\0';
        PING;
    }
    PING;
    while ((i % perLine) != 0) {
        PING;
        printf("   ");
        i++;
    }
    PING;
    printf(" | %s\n", buff);
    PING;
    safefree(buff);
    PING;
    fflush(stdout);
    PING;
}

void _DD(pTHX_ SV * scalar, const char * file, int line) {
    Perl_load_module(aTHX_ PERL_LOADMOD_NOIMPORT, newSVpvs("Data::Printer"), nullptr, nullptr, nullptr);
    if (!get_cvs("Data::Printer::p", GV_NOADD_NOINIT | GV_NO_SVGMAGIC))
        return;
    fflush(stdout);
    dSP;
    int count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 1);
    PUSHs(scalar);
    PUTBACK;
    count = call_pv("Data::Printer::p", G_SCALAR);
    SPAGAIN;
    if (count != 1) {
        warn("Big trouble\n");
        return;
    }
    STRLEN len;
    const char * s = SvPVx(POPs, len);
    printf("%s at %s line %d\n", s, file, line);
    fflush(stdout);
    PUTBACK;
    FREETMPS;
    LEAVE;
}

XS_INTERNAL(Affix_sv_dump) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "sv");
    sv_dump(ST(0));
    XSRETURN_EMPTY;
}

static SV * _new_pointer_obj(pTHX_ Affix_Pin * pin) {
    SV * data_sv = newSV(0);
    SV * rv = newRV_noinc(data_sv);

    sv_setiv(data_sv, PTR2IV(pin));
    SvUPGRADE(data_sv, SVt_PVMG);
    sv_magicext(data_sv, nullptr, PERL_MAGIC_ext, &Affix_pin_vtbl, (const char *)pin, 0);
    return rv;
}

XS_INTERNAL(Affix_malloc) {
    dXSARGS;
    dMY_CXT;

    if (items < 1)
        croak_xs_usage(cv, "size");

    UV size = SvUV(ST(0));
    infix_type * type = nullptr;
    infix_arena_t * parse_arena = nullptr;

    const char * sig = "*void";

    if (infix_type_from_signature(&type, &parse_arena, sig, MY_CXT.registry) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "for malloc", sig, infix_get_last_error());
        warn_sv(err_sv);
        if (parse_arena)
            infix_arena_destroy(parse_arena);
        XSRETURN_UNDEF;
    }

    if (size == 0) {
        infix_arena_destroy(parse_arena);
        warn("Cannot malloc a zero-sized type");
        XSRETURN_UNDEF;
    }

    void * ptr = safemalloc(size);
    Affix_Pin * pin;
    Newx(pin, 1, Affix_Pin);
    pin->size = size;
    pin->pointer = ptr;
    pin->managed = true;
    pin->type_arena = infix_arena_create(1024);

    // We unwrap the pointer type logic here similar to cast.
    // If the user passed "Int", we want the pin to be typed as "Int" (so $$pin reads an int).
    // _unwrap_pin_type handles the logic of "don't unwrap *void or *char".
    pin->type = _copy_type_graph_to_arena(pin->type_arena, _unwrap_pin_type(type));

    infix_arena_destroy(parse_arena);
    ST(0) = sv_2mortal(_new_pointer_obj(aTHX_ pin));
    XSRETURN(1);
}

XS_INTERNAL(Affix_calloc) {
    dXSARGS;
    dMY_CXT;
    if (items != 2)
        croak_xs_usage(cv, "count, type_signature");
    UV count = SvUV(ST(0));
    const char * signature = nullptr;
    SV * type_sv = ST(1);
    signature = _get_string_from_type_obj(aTHX_ type_sv);
    if (!signature)
        signature = SvPV_nolen(type_sv);

    infix_type * elem_type = nullptr;
    infix_arena_t * parse_arena = nullptr;
    if (infix_type_from_signature(&elem_type, &parse_arena, signature, MY_CXT.registry) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "for calloc", signature, infix_get_last_error());
        warn_sv(err_sv);
        if (parse_arena)
            infix_arena_destroy(parse_arena);
        XSRETURN_UNDEF;
    }
    size_t elem_size = infix_type_get_size(elem_type);
    if (elem_size == 0) {
        infix_arena_destroy(parse_arena);
        warn("Cannot calloc a zero-sized type");
        XSRETURN_UNDEF;
    }
    void * ptr = safecalloc(count, elem_size);
    Affix_Pin * pin;
    Newxz(pin, 1, Affix_Pin);
    pin->pointer = ptr;
    pin->managed = true;
    pin->type_arena = infix_arena_create(1024);
    infix_type * array_type;
    if (infix_type_create_array(pin->type_arena, &array_type, elem_type, count) != INFIX_SUCCESS) {
        safefree(pin);
        if (ptr)
            safefree(ptr);
        infix_arena_destroy(pin->type_arena);
        infix_arena_destroy(parse_arena);
        warn("Failed to create array type graph.");
        XSRETURN_UNDEF;
    }
    pin->type = array_type;
    pin->size = (count * elem_size);
    infix_arena_destroy(parse_arena);
    ST(0) = sv_2mortal(_new_pointer_obj(aTHX_ pin));
    XSRETURN(1);
}

XS_INTERNAL(Affix_realloc) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "self, new_size");
    Affix_Pin * pin = _get_pin_from_sv(aTHX_ ST(0));
    if (!pin || !pin->managed) {
        warn("Can only realloc a managed pointer");
        XSRETURN_NO;
    }
    UV new_size = SvUV(ST(1));
    size_t old_size = pin->size;
    void * new_ptr = saferealloc(pin->pointer, new_size);
    if (new_size > old_size)
        memset((char *)new_ptr + old_size, 0, new_size - old_size);
    pin->pointer = new_ptr;
    pin->size = new_size;
    XSRETURN_YES;
}

XS_INTERNAL(Affix_free) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "pointer_object");
    Affix_Pin * pin = _get_pin_from_sv(aTHX_ ST(0));
    if (!pin) {
        warn("Affix::free called on a non-pointer object");
        XSRETURN_NO;
    }
    if (!pin->managed) {
        warn("Cannot free a pointer that was not allocated by Affix (it is unmanaged)");
        XSRETURN_NO;
    }
    if (pin->pointer) {
        safefree(pin->pointer);
        pin->pointer = nullptr;
    }
    XSRETURN_YES;
}

XS_INTERNAL(Affix_cast) {
    dXSARGS;
    dMY_CXT;
    if (items != 2)
        croak_xs_usage(cv, "pointer_or_address, new_type_signature");

    SV * arg = ST(0);
    Affix_Pin * pin = _get_pin_from_sv(aTHX_ arg);
    void * ptr_val = nullptr;

    if (pin)
        ptr_val = pin->pointer;
    else if (SvIOK(arg))
        ptr_val = INT2PTR(void *, SvUV(arg));
    else {
        warn("Argument to cast must be a Pointer Object or Integer Address");
        XSRETURN_UNDEF;
    }

    SV * type_sv = ST(1);
    const char * signature = _get_string_from_type_obj(aTHX_ type_sv);
    if (!signature)
        signature = SvPV_nolen(type_sv);

    infix_type * new_type = nullptr;
    infix_arena_t * parse_arena = nullptr;

    if (infix_type_from_signature(&new_type, &parse_arena, signature, MY_CXT.registry) != INFIX_SUCCESS) {
        SV * err_sv = _format_parse_error(aTHX_ "for cast", signature, infix_get_last_error());
        warn_sv(err_sv);
        if (parse_arena)
            infix_arena_destroy(parse_arena);
        XSRETURN_UNDEF;
    }

    /* Value (Copy) vs Pin (Reference) */
    bool return_as_value = false;
    bool is_string_type = false;

    if (new_type->category == INFIX_TYPE_PRIMITIVE || new_type->category == INFIX_TYPE_ENUM ||
        new_type->category == INFIX_TYPE_STRUCT || new_type->category == INFIX_TYPE_UNION) {
        return_as_value = true;
    }
    else if (new_type->category == INFIX_TYPE_POINTER) {
        const infix_type * pointee = new_type->meta.pointer_info.pointee_type;

        /* Check if casting to String (*char) or WString (*wchar_t) */
        if (pointee->category == INFIX_TYPE_PRIMITIVE) {
            if (pointee->meta.primitive_id == INFIX_PRIMITIVE_SINT8 ||
                pointee->meta.primitive_id == INFIX_PRIMITIVE_UINT8 ||
                /* Char check */
                infix_type_get_size(pointee) == 1) {
                return_as_value = true;
                is_string_type = true;
            }
#if defined(INFIX_OS_WINDOWS)
            else if (infix_type_get_size(pointee) == sizeof(wchar_t)) {
                return_as_value = true;
                is_string_type = true;
            }
#endif
        }
    }

    if (return_as_value) {
        /* Read memory -> Perl Scalar */
        SV * ret_val = sv_newmortal();

        if (is_string_type) {
            /*
             * String pull handlers expect a pointer-to-pointer (char**).
             * 'ptr_val' IS the char*. So we pass '&ptr_val'.
             * The handler reads *(&ptr_val) -> ptr_val, then reads the string.
             */
            ptr2sv(aTHX_ nullptr, &ptr_val, ret_val, new_type);
        }
        else {
            /*
             * Primitives expect a pointer to the value.
             * 'ptr_val' IS the address of the value. We pass 'ptr_val'.
             * The handler reads *(int*)ptr_val.
             */
            ptr2sv(aTHX_ nullptr, ptr_val, ret_val, new_type);
        }

        infix_arena_destroy(parse_arena);
        ST(0) = ret_val;
    }
    else {
        /* Return Alias Pin */
        Affix_Pin * new_pin;
        Newxz(new_pin, 1, Affix_Pin);
        new_pin->pointer = ptr_val;
        new_pin->managed = false;
        new_pin->type_arena = parse_arena;

        if (new_type->category == INFIX_TYPE_POINTER)
            new_pin->type = _unwrap_pin_type(new_type);
        else
            new_pin->type = new_type;

        // Create the object (SV wrapped in RV)
        SV * rv = _new_pointer_obj(aTHX_ new_pin);

        // Return the RV
        ST(0) = sv_2mortal(rv);
    }
    XSRETURN(1);
}

XS_INTERNAL(Affix_own) {
    dXSARGS;
    if (items < 1)
        croak_xs_usage(cv, "pin, [should_own]");

    Affix_Pin * pin = _get_pin_from_sv(aTHX_ ST(0));
    if (!pin) {
        warn("Argument is not a pinned pointer");
        XSRETURN_UNDEF;
    }

    if (items > 1) {
        // Don't dirty the memory if value hasn't changed
        bool new_val = SvTRUE(ST(1));
        if (pin->managed != new_val)
            pin->managed = new_val;
    }

    // Return current state as fast booleans (PL_sv_yes/no are essentially singletons)
    ST(0) = pin->managed ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

XS_INTERNAL(Affix_errno) {
    dXSARGS;
    PERL_UNUSED_VAR(items);

    SV * dual = newSV(1);

#ifdef _WIN32
    DWORD err_code = GetLastError();
    sv_setuv(dual, (UV)err_code);

    char * buf = nullptr;
    DWORD len =
        FormatMessageA(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                       nullptr,
                       err_code,
                       MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                       (LPSTR)&buf,
                       0,
                       nullptr);

    if (buf) {
        while (len > 0 && (buf[len - 1] == '\n' || buf[len - 1] == '\r'))
            buf[--len] = '\0';
        sv_setpvn(dual, buf, len);
        LocalFree(buf);
    }
    else
        sv_setpvn(dual, "Unknown system error", 20);

    SvIOK_on(dual);
    SvIsUV_on(dual);  // Mark as unsigned for DWORD
#else
    int err_code = errno;
    sv_setiv(dual, err_code);

    const char * msg = strerror(err_code);
    if (msg)
        sv_setpv(dual, msg);
    else
        sv_setpv(dual, "Unknown system error");

    SvIV_set(dual, (IV)err_code);
    SvIOK_on(dual);
#endif

    ST(0) = sv_2mortal(dual);
    XSRETURN(1);
}

XS_INTERNAL(Affix_dump) {
    dVAR;
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "scalar, length_in_bytes");
    PING;
    Affix_Pin * pin = _get_pin_from_sv(aTHX_ ST(0));
    PING;
    if (!pin) {
        warn("scalar is not a valid pointer");
        XSRETURN_EMPTY;
    }
    if (!pin->pointer) {
        PING;
        warn("Cannot dump a nullptr pointer");
        XSRETURN_EMPTY;
    }
    PING;
    UV length = SvUV(ST(1));
    PING;
    if (length == 0) {
        warn("Dump length cannot be zero");
        XSRETURN_EMPTY;
    }
    PING;
    // PL_curcop may be nullptr during thread destruction or callbacks?
    const char * file = "Unknown";
    int line = 0;
    PING;
    if (LIKELY(PL_curcop)) {
        PING;
        file = OutCopFILE(PL_curcop);
        PING;
        line = CopLINE(PL_curcop);
        PING;
    }
    PING;
    _DumpHex(aTHX_ pin->pointer, length, file, line);
    PING;
    ST(0) = ST(0);
    PING;
    XSRETURN(1);
}

static void * _resolve_writable_ptr(pTHX_ SV * sv) {
    if (is_pin(aTHX_ sv)) {
        Affix_Pin * p = _get_pin_from_sv(aTHX_ sv);
        return p ? p->pointer : nullptr;
    }
    if (SvIOK(sv))
        return INT2PTR(void *, SvUV(sv));
    return nullptr;
}

static const void * _resolve_readable_ptr(pTHX_ SV * sv) {
    if (is_pin(aTHX_ sv)) {
        Affix_Pin * p = _get_pin_from_sv(aTHX_ sv);
        return p ? p->pointer : nullptr;
    }
    if (SvIOK(sv))
        return INT2PTR(void *, SvUV(sv));
    if (SvPOK(sv))
        return (const void *)SvPV_nolen(sv);
    return nullptr;
}

XS_INTERNAL(Affix_memcpy) {
    dXSARGS;
    if (items != 3)
        croak_xs_usage(cv, "dest, src, n");
    void * dest = _resolve_writable_ptr(aTHX_ ST(0));
    if (!dest) {
        warn("dest must be a pinned pointer or address");
        XSRETURN_UNDEF;
    }
    const void * src = _resolve_readable_ptr(aTHX_ ST(1));
    if (!src) {
        warn("src must be a pinned pointer, address, or string");
        XSRETURN_UNDEF;
    }
    size_t n = (size_t)SvUV(ST(2));
    memcpy(dest, src, n);
    XSRETURN(1);
}

XS_INTERNAL(Affix_memmove) {
    dXSARGS;
    if (items != 3)
        croak_xs_usage(cv, "dest, src, n");
    void * dest = _resolve_writable_ptr(aTHX_ ST(0));
    if (!dest) {
        warn("dest must be a pinned pointer or address");
        XSRETURN_UNDEF;
    }
    const void * src = _resolve_readable_ptr(aTHX_ ST(1));
    if (!src) {
        warn("src must be a pinned pointer, address, or string");
        XSRETURN_UNDEF;
    }
    size_t n = (size_t)SvUV(ST(2));
    memmove(dest, src, n);
    XSRETURN(1);
}

XS_INTERNAL(Affix_memset) {
    dXSARGS;
    if (items != 3)
        croak_xs_usage(cv, "dest, val, n");
    void * dest = _resolve_writable_ptr(aTHX_ ST(0));
    if (!dest) {
        warn("dest must be a pinned pointer or address");
        XSRETURN_UNDEF;
    }
    int val = (int)SvIV(ST(1));
    size_t n = (size_t)SvUV(ST(2));
    memset(dest, val, n);
    XSRETURN(1);
}

XS_INTERNAL(Affix_memcmp) {
    dXSARGS;
    if (items != 3)
        croak_xs_usage(cv, "lhs, rhs, n");
    const void * lhs = _resolve_readable_ptr(aTHX_ ST(0));
    const void * rhs = _resolve_readable_ptr(aTHX_ ST(1));
    if (!lhs || !rhs) {
        warn("arguments must be pinned pointers, addresses, or strings");
        XSRETURN_UNDEF;
    }
    size_t n = (size_t)SvUV(ST(2));
    int ret = memcmp(lhs, rhs, n);
    ST(0) = sv_2mortal(newSViv(ret));
    XSRETURN(1);
}

XS_INTERNAL(Affix_memchr) {
    dXSARGS;
    if (items != 3)
        croak_xs_usage(cv, "ptr, val, n");
    const void * ptr = _resolve_readable_ptr(aTHX_ ST(0));
    if (!ptr) {
        warn("ptr must be a pinned pointer, address, or string");
        XSRETURN_UNDEF;
    }
    int val = (int)SvIV(ST(1));
    size_t n = (size_t)SvUV(ST(2));
    void * res = memchr(ptr, val, n);
    if (res) {
        Affix_Pin * new_pin;
        Newxz(new_pin, 1, Affix_Pin);
        new_pin->pointer = res;
        new_pin->managed = false;
        new_pin->type_arena = infix_arena_create(128);
        new_pin->type =
            _copy_type_graph_to_arena(new_pin->type_arena, infix_type_create_primitive(INFIX_PRIMITIVE_SINT8));
        ST(0) = sv_2mortal(_new_pointer_obj(aTHX_ new_pin));
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

XS_INTERNAL(Affix_ptr_add) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "ptr, offset_bytes");

    Affix_Pin * pin = _get_pin_from_sv(aTHX_ ST(0));
    void * ptr_val = nullptr;
    const infix_type * type = nullptr;

    if (pin) {
        ptr_val = pin->pointer;
        type = pin->type;
    }
    else if (SvIOK(ST(0))) {
        ptr_val = INT2PTR(void *, SvUV(ST(0)));
        type = nullptr;
    }
    else {
        warn("ptr must be a pinned pointer or address");
        XSRETURN_UNDEF;
    }

    IV offset = SvIV(ST(1));
    void * new_addr = (char *)ptr_val + offset;

    Affix_Pin * new_pin;
    Newxz(new_pin, 1, Affix_Pin);
    new_pin->pointer = new_addr;
    new_pin->managed = false;  // Aliases are never managed
    new_pin->type_arena = infix_arena_create(256);

    if (type) {
        if (type->category == INFIX_TYPE_ARRAY) {
            // Decay Array[T] -> Pointer[T] logic.
            // When adding an offset to an array, the result is a pointer to the element type,
            // not a new array. This allows dereferencing assignment ($$ptr = val) to work correctly.
            const infix_type * elem_src = type->meta.array_info.element_type;
            const infix_type * elem_copy = _copy_type_graph_to_arena(new_pin->type_arena, elem_src);

            // Cast to (infix_type*) to satisfy signature; safe because we just allocated it in our arena.
            if (infix_type_create_pointer_to(
                    new_pin->type_arena, (infix_type **)&new_pin->type, (infix_type *)elem_copy) != INFIX_SUCCESS) {
                infix_arena_destroy(new_pin->type_arena);
                safefree(new_pin);
                warn("Failed to create decayed array pointer type in ptr_add");
                XSRETURN_UNDEF;
            }
        }
        else {
            // Standard pointer arithmetic, keep the same type (e.g., int* + 4 -> int*)
            new_pin->type = _copy_type_graph_to_arena(new_pin->type_arena, type);
        }
    }
    else {
        // Fallback to *void for raw addresses
        infix_type * void_t = infix_type_create_void();
        if (infix_type_create_pointer_to(new_pin->type_arena, (infix_type **)&new_pin->type, void_t) != INFIX_SUCCESS) {
            infix_arena_destroy(new_pin->type_arena);
            safefree(new_pin);
            warn("Failed to create void* type in ptr_add");
            XSRETURN_UNDEF;
        }
    }

    ST(0) = sv_2mortal(_new_pointer_obj(aTHX_ new_pin));
    XSRETURN(1);
}

XS_INTERNAL(Affix_ptr_diff) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "ptr1, ptr2");

    // Use resolve_readable to accept pins or ints
    const void * p1 = _resolve_readable_ptr(aTHX_ ST(0));
    const void * p2 = _resolve_readable_ptr(aTHX_ ST(1));

    if (!p1 || !p2)
        XSRETURN_UNDEF;

    IV diff = (const char *)p1 - (const char *)p2;
    ST(0) = sv_2mortal(newSViv(diff));
    XSRETURN(1);
}


XS_INTERNAL(Affix_strdup) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "string");

    STRLEN len;
    const char * str = SvPV(ST(0), len);

    // Allocate managed memory
    char * dup = safemalloc(len + 1);
    memcpy(dup, str, len);
    dup[len] = '\0';

    Affix_Pin * pin;
    Newx(pin, 1, Affix_Pin);
    pin->pointer = dup;
    pin->managed = true;
    pin->size = len + 1;
    pin->type_arena = infix_arena_create(128);
    // char*
    infix_type * char_type = infix_type_create_primitive(INFIX_PRIMITIVE_SINT8);
    if (infix_type_create_pointer_to(pin->type_arena, (infix_type **)&pin->type, char_type) != INFIX_SUCCESS) {
        infix_arena_destroy(pin->type_arena);
        safefree(dup);
        safefree(pin);
        warn("Failed to create char* type for strdup");
        XSRETURN_UNDEF;
    }

    ST(0) = sv_2mortal(_new_pointer_obj(aTHX_ pin));
    XSRETURN(1);
}

XS_INTERNAL(Affix_strnlen) {
    dXSARGS;
    if (items != 2)
        croak_xs_usage(cv, "ptr, maxlen");
    const char * ptr = (const char *)_resolve_readable_ptr(aTHX_ ST(0));
    size_t maxlen = (size_t)SvUV(ST(1));

    if (!ptr)
        XSRETURN_IV(0);

    // strnlen is not standard C89, so we implement it manually to be safe
    size_t len = 0;
    while (len < maxlen && ptr[len] != '\0')
        len++;
    ST(0) = sv_2mortal(newSVuv(len));
    XSRETURN(1);
}

XS_INTERNAL(Affix_is_null) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "ptr");
    const void * ptr = _resolve_readable_ptr(aTHX_ ST(0));
    ST(0) = ptr == nullptr ? &PL_sv_yes : &PL_sv_no;
    XSRETURN(1);
}

void _populate_hv_from_c_struct(pTHX_ Affix * affix, HV * hv, const infix_type * type, void * p) {
    hv_clear(hv);
    for (size_t i = 0; i < type->meta.aggregate_info.num_members; ++i) {
        const infix_struct_member * member = &type->meta.aggregate_info.members[i];
        if (member->name) {
            void * member_ptr = (char *)p + member->offset;
            SV * member_sv = newSV(0);
            ptr2sv(aTHX_ affix, member_ptr, member_sv, member->type);
            hv_store(hv, member->name, strlen(member->name), member_sv, 0);
        }
    }
}

// Cribbed from Perl::Destruct::Level so leak testing works without yet another prereq
XS_INTERNAL(Affix_set_destruct_level) {
    dVAR;
    dXSARGS;
    // TODO: report this with a warn(...)
    if (items != 1)
        croak_xs_usage(cv, "level");
    PL_perl_destruct_level = SvIV(ST(0));
    XSRETURN_EMPTY;
}

XS_INTERNAL(Affix_address) {
    dXSARGS;
    if (items != 1)
        croak_xs_usage(cv, "pointer");

    Affix_Pin * pin = _get_pin_from_sv(aTHX_ ST(0));

    if (!pin) {
        warn("Argument is not a pinned pointer");
        XSRETURN_UNDEF;
    }

    // Return the pointer address as a Perl unsigned integer (UV)
    ST(0) = sv_2mortal(newSVuv(PTR2UV(pin->pointer)));
    XSRETURN(1);
}

XS_INTERNAL(Affix_CLONE) {
    dXSARGS;
    PERL_UNUSED_VAR(items);

    // Initialize the new thread's context (copies bitwise from parent)
    MY_CXT_CLONE;

    // Overwrite shared pointers with fresh objects for the new thread
    MY_CXT.lib_registry = newHV();
    MY_CXT.callback_registry = newHV();
    MY_CXT.enum_registry = newHV();
    MY_CXT.coercion_cache = newHV();
    MY_CXT.registry = infix_registry_create();
    if (!MY_CXT.registry)
        warn("Failed to initialize the global type registry in new thread");
    XSRETURN_EMPTY;
}

void boot_Affix(pTHX_ CV * cv) {
    dVAR;
    dXSBOOTARGSXSAPIVERCHK;
    PERL_UNUSED_VAR(items);
#ifdef USE_ITHREADS
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif
    MY_CXT_INIT;
    MY_CXT.lib_registry = newHV();
    MY_CXT.callback_registry = newHV();
    MY_CXT.enum_registry = newHV();
    MY_CXT.coercion_cache = newHV();
    MY_CXT.registry = infix_registry_create();
    if (!MY_CXT.registry)
        croak("Failed to initialize the global type registry");

    // Register SV as a named type (dummy struct ensures it keeps the name in the registry).
    // This allows signature parsing of "@SV" or "SV" (via hack) to map to a named opaque type.
    // NOTE: Direct usage of this type is blocked in get_opcode_for_type; it must be wrapped in Pointer[].
    if (infix_register_types(MY_CXT.registry, "@SV = { __sv_opaque: uint8 };") != INFIX_SUCCESS)
        croak("Failed to register internal type alias '@SV'");

    // We register File and PerlIO as opaque structs.
    // This semantically matches C's FILE struct which (for now) will remain opaque to the user.
    // We require "Pointer[File]" to mean "FILE*"
    if (infix_register_types(MY_CXT.registry, "@File = { _opaque: [0:uchar] };") != INFIX_SUCCESS)
        croak("Failed to register internal type alias '@File'");
    if (infix_register_types(MY_CXT.registry, "@PerlIO = { _opaque: [0:uchar] };") != INFIX_SUCCESS)
        croak("Failed to register internal type alias '@PerlIO'");

    // Other special types are opaque structs too. ...but they don't always mean anything in particular.
    if (infix_register_types(MY_CXT.registry, "@StringList = *void;") != INFIX_SUCCESS)
        croak("Failed to register internal type alias '@StringList'");
    if (infix_register_types(MY_CXT.registry, "@Buffer = *void;") != INFIX_SUCCESS)
        croak("Failed to register internal type alias '@Buffer'");
    if (infix_register_types(MY_CXT.registry, "@SockAddr = *void;") != INFIX_SUCCESS)
        croak("Failed to register internal type alias '@SockAddr'");

    // Helper macro to define and export an XSUB in one line.
    // Assumes C function is Affix_name and Perl sub is Affix::name.
#define XSUB_EXPORT(name, proto, tag)                                          \
    (void)newXSproto_portable("Affix::" #name, Affix_##name, __FILE__, proto); \
    export_function("Affix", #name, tag)

    {
        // Core affix/wrap construction (Manual due to aliasing via XSANY)
        cv = newXSproto_portable("Affix::affix", Affix_affix, __FILE__, "$$$;$");
        XSANY.any_i32 = 0;
        export_function("Affix", "affix", "core");

        cv = newXSproto_portable("Affix::wrap", Affix_affix, __FILE__, "$$$;$");
        XSANY.any_i32 = 1;
        export_function("Affix", "wrap", "core");

        cv = newXSproto_portable("Affix::direct_affix", Affix_affix, __FILE__, "$$$;$");
        XSANY.any_i32 = 2;
        export_function("Affix", "direct_affix", "core");

        cv = newXSproto_portable("Affix::direct_wrap", Affix_affix, __FILE__, "$$$;$");
        XSANY.any_i32 = 3;
        export_function("Affix", "direct_wrap", "core");

        // Destructors
        newXS("Affix::Bundled::DESTROY", Affix_Bundled_DESTROY, __FILE__);
        // newXS("Affix::DESTROY", Affix_DESTROY, __FILE__);
        newXS("Affix::END", Affix_END, __FILE__);
        newXS("Affix::Lib::DESTROY", Affix_Lib_DESTROY, __FILE__);
        newXS("Affix::CLONE", Affix_CLONE, __FILE__);

        // Overloads
        sv_setsv(get_sv("Affix::()", TRUE), &PL_sv_yes);
        (void)newXSproto_portable("Affix::()", Affix_as_string, __FILE__, "$;@");

        sv_setsv(get_sv("Affix::Lib::()", TRUE), &PL_sv_yes);
        (void)newXSproto_portable("Affix::Lib::(0+", Affix_Lib_as_string, __FILE__, "$;@");
        (void)newXSproto_portable("Affix::Lib::()", Affix_as_string, __FILE__, "$;@");

        // Library & core utils
        XSUB_EXPORT(load_library, "$", "lib");
        XSUB_EXPORT(find_symbol, "$$", "lib");
        XSUB_EXPORT(get_last_error_message, "", "core");

        // Scalar pins
        XSUB_EXPORT(pin, "$$$$", "pin");
        XSUB_EXPORT(unpin, "$", "pin");

        // Introspection
        XSUB_EXPORT(sizeof, "$", "core");
        XSUB_EXPORT(alignof, "$", "core");
        XSUB_EXPORT(offsetof, "$$", "core");

        // Type registry
        (void)newXSproto_portable("Affix::_typedef", Affix_typedef, __FILE__, "$;$");
        (void)newXSproto_portable("Affix::_register_enum_values", Affix_register_enum_values, __FILE__, "$;$");
        (void)newXSproto_portable("Affix::types", Affix_defined_types, __FILE__, "");

        // Debugging
        (void)newXSproto_portable("Affix::sv_dump", Affix_sv_dump, __FILE__, "$");

        // Memory management & pointers
        XSUB_EXPORT(address, "$", "memory");
        XSUB_EXPORT(malloc, "$", "memory");
        XSUB_EXPORT(calloc, "$$", "memory");
        XSUB_EXPORT(realloc, "$$", "memory");
        XSUB_EXPORT(free, "$", "memory");
        XSUB_EXPORT(cast, "$$", "memory");
        XSUB_EXPORT(dump, "$$", "memory");
        XSUB_EXPORT(own, "$;$", "memory");

        // Raw memory operations
        XSUB_EXPORT(memcpy, "$$$", "memory");
        XSUB_EXPORT(memmove, "$$$", "memory");
        XSUB_EXPORT(memset, "$$$", "memory");
        XSUB_EXPORT(memcmp, "$$$", "memory");
        XSUB_EXPORT(memchr, "$$$", "memory");

        // Pointer utils
        XSUB_EXPORT(ptr_add, "$$", "memory");
        XSUB_EXPORT(ptr_diff, "$$", "memory");
        XSUB_EXPORT(strdup, "$", "memory");
        XSUB_EXPORT(strnlen, "$$", "memory");
        XSUB_EXPORT(is_null, "$", "memory");
    }

    XSUB_EXPORT(coerce, "$$", "core");

    XSUB_EXPORT(errno, "", "core");
    (void)newXSproto_portable("Affix::set_destruct_level", Affix_set_destruct_level, __FILE__, "$");

#undef XSUB_EXPORT

    Perl_xs_boot_epilog(aTHX_ ax);
}
