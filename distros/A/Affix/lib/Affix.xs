#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT 1 /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#define NO_XSLOCKS /* for exceptions */
#include <XSUB.h>

#ifdef MULTIPLICITY
#define storeTHX(var) (var) = aTHX
#define dTHXfield(var) tTHX var;
#else
#define storeTHX(var) dNOOP
#define dTHXfield(var)
#endif

#ifdef __cplusplus
} /* extern "C" */
#endif

#define dcAllocMem safemalloc
#define dcFreeMem Safefree

// #include "ppport.h"

#ifndef av_count
#define av_count(av) (AvFILL(av) + 1)
#endif

#if defined(_WIN32) || defined(_WIN64)
#else
#include <dlfcn.h>
#include <iconv.h>
#endif

// older perls are missing wcslen
// PERL_VERSION is deprecated but PERL_VERSION_LE, etc. do not exist pre-5.34.x
#if /*(defined(PERL_VERSION_LE) && PERL_VERSION_LE(5, 30, '*')) ||*/ PERL_VERSION <= 30
#include <wchar.h>
#endif

#include <dyncall.h>
#include <dyncall_callback.h>
#include <dynload.h>

#include <dyncall_callf.h>
#include <dyncall_value.h>

#include <dyncall_signature.h>

#include <dyncall/dyncall/dyncall_aggregate.h>

//{ii[5]Z&<iZ>}
#define DC_SIGCHAR_CODE '&'        // 'p' but allows us to wrap CV * for the user
#define DC_SIGCHAR_ARRAY '['       // 'A' but nicer
#define DC_SIGCHAR_STRUCT '{'      // 'A' but nicer
#define DC_SIGCHAR_UNION '<'       // 'A' but nicer
#define DC_SIGCHAR_INSTANCEOF '$'  // 'p' but an object or subclass of a given package
#define DC_SIGCHAR_ANY '*'         // 'p' but it's really an SV/HV/AV
#define DC_SIGCHAR_ENUM 'e'        // 'i' but with multiple options
#define DC_SIGCHAR_ENUM_UINT 'E'   // 'I' but with multiple options
#define DC_SIGCHAR_ENUM_CHAR 'o'   // 'c' but with multiple options
#define DC_SIGCHAR_WIDE_STRING 'z' // 'Z' but wchar_t

// MEM_ALIGNBYTES is messed up by quadmath and long doubles
#define AFFIX_ALIGNBYTES 8

#if Size_t_size == INTSIZE
#define DC_SIGCHAR_SSIZE_T DC_SIGCHAR_INT
#define DC_SIGCHAR_SIZE_T DC_SIGCHAR_UINT
#elif Size_t_size == LONGSIZE
#define DC_SIGCHAR_SSIZE_T DC_SIGCHAR_LONG
#define DC_SIGCHAR_SIZE_T DC_SIGCHAR_ULONG
#elif Size_t_size == LONGLONGSIZE
#define DC_SIGCHAR_SSIZE_T DC_SIGCHAR_LONGLONG
#define DC_SIGCHAR_SIZE_T DC_SIGCHAR_ULONGLONG
#else // quadmath is broken
#define DC_SIGCHAR_SSIZE_T DC_SIGCHAR_LONGLONG
#define DC_SIGCHAR_SIZE_T DC_SIGCHAR_ULONGLONG
#endif

/* portability stuff not supported by ppport.h yet */

#ifndef STATIC_INLINE /* from 5.13.4 */
#if defined(__cplusplus) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#define STATIC_INLINE static inline
#else
#define STATIC_INLINE static
#endif
#endif /* STATIC_INLINE */

#ifndef newSVpvs_share
#define newSVpvs_share(s) Perl_newSVpvn_share(aTHX_ STR_WITH_LEN(s), 0U)
#endif

#ifndef get_cvs
#define get_cvs(name, flags) get_cv(name, flags)
#endif

#ifndef GvNAME_get
#define GvNAME_get GvNAME
#endif
#ifndef GvNAMELEN_get
#define GvNAMELEN_get GvNAMELEN
#endif

#ifndef CvGV_set
#define CvGV_set(cv, gv) (CvGV(cv) = (gv))
#endif

/* general utility */

#if PERL_BCDVERSION >= 0x5008005
#define LooksLikeNumber(x) looks_like_number(x)
#else
#define LooksLikeNumber(x) (SvPOKp(x) ? looks_like_number(x) : (I32)SvNIOKp(x))
#endif

// added in perl 5.35.7?
#ifndef sv_setbool_mg
#define sv_setbool_mg(sv, b) sv_setsv_mg(sv, boolSV(b))
#endif

#define newAV_mortal() (AV *)sv_2mortal((SV *)newAV())
#define newHV_mortal() (HV *)sv_2mortal((SV *)newHV())
#define newRV_inc_mortal(sv) sv_2mortal(newRV_inc(sv))
#define newRV_noinc_mortal(sv) sv_2mortal(newRV_noinc(sv))

/* Useful but undefined in perlapi */
#define FLOATSIZE sizeof(float)
#define BOOLSIZE sizeof(bool)      // ha!
#define XDOUBLESIZE sizeof(double) // ugh...
#define XPTRSIZE sizeof(intptr_t)  // ugh...
#define WCHAR_T_SIZE sizeof(wchar_t)

const char *file = __FILE__;

/* api wrapping utils */
#define MY_CXT_KEY "Affix::_guts" XS_VERSION

typedef struct {
    DCCallVM *cvm;
} my_cxt_t;

START_MY_CXT

typedef struct CoW {
    DCCallback *cb;
} CoW;

typedef struct {
    char *sig;
    size_t sig_len;
    char ret;
    void *fptr;
    char *perl_sig;
    DLLib *lib;
    AV *args;
    SV *retval;
    bool reset;
} Call;

typedef struct {
    char *sig;
    size_t sig_len;
    char ret;
    char *perl_sig;
    SV *cv;
    AV *args;
    SV *retval;
    dTHXfield(perl)
} Callback;

SV *ptr2sv(pTHX_ DCpointer ptr, SV *type);

// http://www.catb.org/esr/structure-packing/#_structure_alignment_and_padding
/* Returns the amount of padding needed after `offset` to ensure that the
following address will be aligned to `alignment`. */
size_t padding_needed_for(size_t offset, size_t alignment) {
    if (alignment == 0) return 0;
    size_t misalignment = offset % alignment;
    if (misalignment) // round to the next multiple of alignment
        return alignment - misalignment;
    return 0; // already a multiple of alignment*/
}

void set_isa(const char *klass, const char *parent) {
    dTHX;
    HV *parent_stash = gv_stashpv(parent, GV_ADD | GV_ADDMULTI);
    av_push(get_av(form("%s::ISA", klass), TRUE), newSVpv(parent, 0));
    // TODO: make this spider up the list and make deeper connections?
}

void register_constant(const char *package, const char *name, SV *value) {
    dTHX;
    HV *_stash = gv_stashpv(package, TRUE);
    newCONSTSUB(_stash, (char *)name, value);
}

void export_function__(HV *_export, const char *what, const char *_tag) {
    dTHX;
    SV **tag = hv_fetch(_export, _tag, strlen(_tag), TRUE);
    if (tag && SvOK(*tag) && SvROK(*tag) && (SvTYPE(SvRV(*tag))) == SVt_PVAV)
        av_push((AV *)SvRV(*tag), newSVpv(what, 0));
    else {
        SV *av;
        av = (SV *)newAV();
        av_push((AV *)av, newSVpv(what, 0));
        tag = hv_store(_export, _tag, strlen(_tag), newRV_noinc(av), 0);
    }
}

void export_function(const char *package, const char *what, const char *tag) {
    dTHX;
    export_function__(get_hv(form("%s::EXPORT_TAGS", package), GV_ADD), what, tag);
}

void export_constant(const char *package, const char *name, const char *_tag, double val) {
    dTHX;
    register_constant(package, name, newSVnv(val));
    export_function(package, name, _tag);
}

#define DumpHex(addr, len)                                                                         \
    ;                                                                                              \
    _DumpHex(aTHX_ addr, len, __FILE__, __LINE__)

void _DumpHex(pTHX_ const void *addr, size_t len, const char *file, int line) {
    fflush(stdout);
    int perLine = 16;
    // Silently ignore silly per-line values.
    if (perLine < 4 || perLine > 64) perLine = 16;
    int i;
    unsigned char buff[perLine + 1];
    const unsigned char *pc = (const unsigned char *)addr;
    printf("Dumping %lu bytes from %p at %s line %d\n", len, addr, file, line);
    // Length checks.
    if (len == 0) croak("ZERO LENGTH");
    if (len < 0) croak("NEGATIVE LENGTH: %lu", len);
    for (i = 0; i < len; i++) {
        if ((i % perLine) == 0) { // Only print previous-line ASCII buffer for
            // lines beyond first.
            if (i != 0) printf(" | %s\n", buff);
            printf("#  %04x ", i); // Output the offset of current line.
        }
        // Now the hex code for the specific character.
        printf(" %02x", pc[i]);
        // And buffer a printable ASCII character for later.
        if ((pc[i] < 0x20) || (pc[i] > 0x7e)) // isprint() may be better.
            buff[i % perLine] = '.';
        else
            buff[i % perLine] = pc[i];
        buff[(i % perLine) + 1] = '\0';
    }
    // Pad out last line if not exactly perLine characters.
    while ((i % perLine) != 0) {
        printf("   ");
        i++;
    }
    printf(" | %s\n", buff);
    fflush(stdout);
}

SV *enum2sv(pTHX_ SV *type, int in) {
    SV *val = newSViv(in);
    AV *values = MUTABLE_AV(SvRV(*hv_fetchs(MUTABLE_HV(SvRV(type)), "values", 0)));
    for (int i = 0; i < av_count(values); ++i) {
        SV *el = *av_fetch(values, i, 0);
        // Future ref: https://groups.google.com/g/perl.perl5.porters/c/q1k1qfbeVk0
        // if(sv_numeq(val, el))
        if (in == SvIV(el)) return el;
    }
    return val;
}

bool is_valid_class_name(SV *sv) { // Stolen from Type::Tiny::XS::Util
    dTHX;
    bool RETVAL;
    SvGETMAGIC(sv);
    if (SvPOKp(sv) && SvCUR(sv) > 0) {
        UV i;
        RETVAL = TRUE;
        for (i = 0; i < SvCUR(sv); i++) {
            char const c = SvPVX(sv)[i];
            if (!(isALNUM(c) || c == ':')) {
                RETVAL = FALSE;
                break;
            }
        }
    }
    else { RETVAL = SvNIOKp(sv) ? TRUE : FALSE; }
    return RETVAL;
}

// Lazy load actual type from typemap and InstanceOf[]
SV *_instanceof(pTHX_ SV *type) {
    SV *retval;
    char *name = SvPV_nolen(*hv_fetchs(MUTABLE_HV(SvRV(type)), "package", 0));
    {
        dSP;
        int count;
        SV *err_tmp;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = call_pv(name, G_SCALAR | G_EVAL);
        SPAGAIN;
        err_tmp = ERRSV;
        if (SvTRUE(err_tmp)) {
            croak("Malformed InstanceOf[ '%s' ]; %s\n", name, SvPV_nolen(err_tmp));
            POPs;
        }
        else {
            if (count != 1) croak("Malformed InstanceOf[ '%s' ]; missing typedef", name);
            retval = POPs;
            SvSetMagicSV(type, retval);
        }
        FREETMPS;
        LEAVE;
    }
    return type;
}

static size_t _sizeof(pTHX_ SV *type) {
    char *_type = SvPVbytex_nolen(type);
    switch (_type[0]) {
    case DC_SIGCHAR_VOID:
        return 0;
    case DC_SIGCHAR_BOOL:
        return BOOLSIZE;
    case DC_SIGCHAR_CHAR:
    case DC_SIGCHAR_UCHAR:
        return I8SIZE;
    case DC_SIGCHAR_SHORT:
    case DC_SIGCHAR_USHORT:
        return SHORTSIZE;
    case DC_SIGCHAR_INT:
    case DC_SIGCHAR_UINT:
    case DC_SIGCHAR_ENUM:
    case DC_SIGCHAR_ENUM_UINT:
        return INTSIZE;
    case DC_SIGCHAR_LONG:
    case DC_SIGCHAR_ULONG:
        return LONGSIZE;
    case DC_SIGCHAR_LONGLONG:
    case DC_SIGCHAR_ULONGLONG:
        return LONGLONGSIZE;
    case DC_SIGCHAR_FLOAT:
        return FLOATSIZE;
    case DC_SIGCHAR_DOUBLE:
        return XDOUBLESIZE;
    case DC_SIGCHAR_STRUCT:
    case DC_SIGCHAR_UNION:
    case DC_SIGCHAR_ARRAY:
        return SvUV(*hv_fetchs(MUTABLE_HV(SvRV(type)), "sizeof", 0));
    case DC_SIGCHAR_CODE: // automatically wrapped in a DCCallback pointer
    case DC_SIGCHAR_POINTER:
    case DC_SIGCHAR_STRING:
    case DC_SIGCHAR_WIDE_STRING:
    case DC_SIGCHAR_ANY:
    case DC_SIGCHAR_INSTANCEOF:
        return XPTRSIZE;
    default:
        croak("Failed to gather sizeof info for unknown type: %s", _type);
        return -1;
    }
}

static size_t _offsetof(pTHX_ SV *type) {
    if (hv_exists(MUTABLE_HV(SvRV(type)), "offset", 6))
        return SvUV(*hv_fetchs(MUTABLE_HV(SvRV(type)), "offset", 0));
    return 0;
}

static DCaggr *_aggregate(pTHX_ SV *type) {
    char *str = SvPVbytex_nolen(type);
    size_t size = _sizeof(aTHX_ type);
    switch (str[0]) {
    case DC_SIGCHAR_STRUCT:
    case DC_SIGCHAR_UNION: {
        HV *hv_type = MUTABLE_HV(SvRV(type));
        SV **agg_ = hv_fetch(hv_type, "aggregate", 9, 0);
        if (agg_ != NULL) {
            SV *agg = *agg_;
            if (sv_derived_from(agg, "Dyn::Call::Aggregate")) {
                HV *hv_ptr = MUTABLE_HV(agg);
                IV tmp = SvIV((SV *)SvRV(agg));
                return INT2PTR(DCaggr *, tmp);
            }
            else
                croak("Oh, no...");
        }
        else {
            SV **idk_wtf = hv_fetchs(MUTABLE_HV(SvRV(type)), "fields", 0);
            bool packed = false;
            if (str[0] == DC_SIGCHAR_STRUCT) {
                SV **sv_packed = hv_fetchs(MUTABLE_HV(SvRV(type)), "packed", 0);
                packed = SvTRUE(*sv_packed);
            }
            AV *idk_arr = MUTABLE_AV(SvRV(*idk_wtf));
            int field_count = av_count(idk_arr);
            DCaggr *agg = dcNewAggr(field_count, size);
            for (int i = 0; i < field_count; ++i) {
                SV **field_ptr = av_fetch(idk_arr, i, 0);
                AV *field = MUTABLE_AV(SvRV(*field_ptr));
                SV **type_ptr = av_fetch(field, 1, 0);
                size_t __sizeof = _sizeof(aTHX_ * type_ptr);
                size_t offset = _offsetof(aTHX_ * type_ptr);
                char *str = SvPVbytex_nolen(*type_ptr);
                switch (str[0]) {
                case DC_SIGCHAR_AGGREGATE:
                case DC_SIGCHAR_STRUCT:
                case DC_SIGCHAR_UNION: {
                    DCaggr *child = _aggregate(aTHX_ * type_ptr);
                    dcAggrField(agg, DC_SIGCHAR_AGGREGATE, offset, 1, child);
                } break;
                case DC_SIGCHAR_ARRAY: {
                    SV *type = *hv_fetchs(MUTABLE_HV(SvRV(*type_ptr)), "type", 0);
                    int array_len = SvIV(*hv_fetchs(MUTABLE_HV(SvRV(*type_ptr)), "size", 0));
                    char *str = SvPVbytex_nolen(type);
                    dcAggrField(agg, str[0], offset, array_len);
                } break;
                case DC_SIGCHAR_ANY:
                case DC_SIGCHAR_CODE:
                case DC_SIGCHAR_POINTER:
                case DC_SIGCHAR_WIDE_STRING:
                case DC_SIGCHAR_INSTANCEOF: {
                    dcAggrField(agg, DC_SIGCHAR_POINTER, offset, 1);
                } break;
                default: {
                    dcAggrField(agg, str[0], offset, 1);
                } break;
                }
            }
            dcCloseAggr(agg);
            {
                SV *RETVALSV;
                RETVALSV = newSV(1);
                sv_setref_pv(RETVALSV, "Dyn::Call::Aggregate", (void *)agg);
                hv_stores(MUTABLE_HV(SvRV(type)), "aggregate", newSVsv(RETVALSV));
            }
            return agg;
        }
    } break;
    default: {
        croak("unsupported aggregate: %s at %s line %d", str, __FILE__, __LINE__);
        break;
    }
    }
    return NULL;
}

// Snagged from Encode/Encode.xs
static SV *call_encoding(pTHX_ const char *method, SV *obj, SV *src, SV *check) {
    dSP;
    I32 count;
    SV *dst = &PL_sv_undef;
    PUSHMARK(sp);
    if (check) check = sv_2mortal(newSVsv(check));
    if (!check || SvROK(check) || !SvTRUE_nomg(check)) src = sv_2mortal(newSVsv(src));
    XPUSHs(obj);
    XPUSHs(src);
    XPUSHs(check ? check : &PL_sv_no);
    PUTBACK;
    count = call_method(method, G_SCALAR);
    SPAGAIN;
    if (count > 0) {
        dst = POPs;
        SvREFCNT_inc(dst);
    }
    PUTBACK;
    return dst;
}
// https://www.gnu.org/software/libunistring/manual/html_node/The-wchar_005ft-mess.html
// TODO: store this SV* for the sake of speed
static SV *find_encoding(pTHX) {
    char encoding[9];
    my_snprintf(encoding, 9, "UTF-%d%cE", (WCHAR_T_SIZE == 2 ? 16 : 32),
                ((BYTEORDER == 0x1234 || BYTEORDER == 0x12345678) ? 'L' : 'B'));
    // warn("encoding: %s", encoding);
    dSP;
    int count;
    require_pv("Encode.pm");
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(encoding, 0)));
    PUTBACK;
    count = call_pv("Encode::find_encoding", G_SCALAR);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        warn("Error: %s\n", SvPV_nolen(ERRSV));
        (void)POPs;
    }
    if (count != 1) croak("find_encoding fault: bad number of returned values: %d", count);
    SV *encode = POPs;
    SvREFCNT_inc(encode);
    PUTBACK;
    FREETMPS;
    LEAVE;
    return encode;
}

char cbHandler(DCCallback *, DCArgs *, DCValue *, DCpointer);

SV *ptr2sv(pTHX_ DCpointer ptr, SV *type) {
    SV *RETVAL = newSV(0);
    char *_type = SvPV_nolen(type);
    //~ sv_dump(type);
    //~ warn("ptr2sv(%p, %s) at %s line %d", ptr, _type, __FILE__, __LINE__);
    switch (_type[0]) {
    case DC_SIGCHAR_VOID:
        sv_setref_pv(RETVAL, "Affix::Pointer", ptr);
        break;
    case DC_SIGCHAR_BOOL:
        sv_setbool_mg(RETVAL, (bool)*(bool *)ptr);
        break;
    case DC_SIGCHAR_CHAR:
        sv_setiv(RETVAL, (IV) * (char *)ptr);
        break;
    case DC_SIGCHAR_UCHAR:
        sv_setuv(RETVAL, (UV) * (unsigned char *)ptr);
        break;
    case DC_SIGCHAR_SHORT:
        sv_setiv(RETVAL, *(short *)ptr);
        break;
    case DC_SIGCHAR_USHORT:
        sv_setuv(RETVAL, *(unsigned short *)ptr);
        break;
    case DC_SIGCHAR_INT:
        sv_setiv(RETVAL, *(int *)ptr);
        break;
    case DC_SIGCHAR_UINT:
        sv_setuv(RETVAL, *(unsigned int *)ptr);
        break;
    case DC_SIGCHAR_LONG:
        sv_setiv(RETVAL, *(long *)ptr);
        break;
    case DC_SIGCHAR_ULONG:
        sv_setuv(RETVAL, *(unsigned long *)ptr);
        break;
    case DC_SIGCHAR_LONGLONG:
        sv_setiv(RETVAL, *(I64 *)ptr);
        break;
    case DC_SIGCHAR_ULONGLONG:
        sv_setuv(RETVAL, *(U64 *)ptr);
        break;
    case DC_SIGCHAR_FLOAT:
        sv_setnv(RETVAL, *(float *)ptr);
        break;
    case DC_SIGCHAR_DOUBLE:
        sv_setnv(RETVAL, *(double *)ptr);
        break;
    case DC_SIGCHAR_POINTER: {
        SV *subtype;
        if (sv_derived_from(type, "Affix::Type::Pointer"))
            subtype = *hv_fetchs(MUTABLE_HV(SvRV(type)), "type", 0);
        else
            subtype = type;
        char *_subtype = SvPV_nolen(subtype);
        if (_subtype[0] == DC_SIGCHAR_VOID) {
            SV *RETVALSV = newSV(1); // sv_newmortal();
            SvSetSV(RETVAL, sv_setref_pv(RETVALSV, "Affix::Pointer", *(DCpointer *)ptr));
        }
        else { SvSetSV(RETVAL, ptr2sv(aTHX_ ptr, subtype)); }
    } break;
    case DC_SIGCHAR_STRING:
        sv_setsv(RETVAL, newSVpv(*(char **)ptr, 0));
        break;
    case DC_SIGCHAR_WIDE_STRING: {
        size_t len = wcslen((const wchar_t *)ptr) * WCHAR_T_SIZE;
        RETVAL =
            call_encoding(aTHX_ "decode", find_encoding(aTHX), newSVpv((char *)ptr, len), NULL);
    } break;
    case DC_SIGCHAR_ARRAY: {
        AV *RETVAL_ = newAV_mortal();
        HV *_type = MUTABLE_HV(SvRV(type));
        SV *subtype = *hv_fetchs(_type, "type", 0);
        SV **size = hv_fetchs(_type, "size", 0);
        size_t pos = PTR2IV(ptr);
        size_t sof = _sizeof(aTHX_ subtype);
        size_t av_len;
        if (SvOK(*size))
            av_len = SvIV(*size);
        else
            av_len = SvIV(*hv_fetchs(_type, "size_", 0)) + 1;
        for (size_t i = 0; i < av_len; ++i) {
            av_push(RETVAL_, ptr2sv(aTHX_ INT2PTR(DCpointer, pos), subtype));
            pos += sof;
        }
        SvSetSV(RETVAL, newRV(MUTABLE_SV(RETVAL_)));
    } break;
    case DC_SIGCHAR_STRUCT:
    case DC_SIGCHAR_UNION: {
        HV *RETVAL_ = newHV_mortal();
        HV *_type = MUTABLE_HV(SvRV(type));
        AV *fields = MUTABLE_AV(SvRV(*hv_fetchs(_type, "fields", 0)));
        size_t field_count = av_count(fields);
        for (size_t i = 0; i < field_count; ++i) {
            AV *field = MUTABLE_AV(SvRV(*av_fetch(fields, i, 0)));
            SV *name = *av_fetch(field, 0, 0);
            SV *subtype = *av_fetch(field, 1, 0);
            (void)hv_store_ent(
                RETVAL_, name,
                ptr2sv(aTHX_ INT2PTR(DCpointer, PTR2IV(ptr) + _offsetof(aTHX_ subtype)), subtype),
                0);
        }
        SvSetSV(RETVAL, newRV(MUTABLE_SV(RETVAL_)));
    } break;
    case DC_SIGCHAR_CODE: {
        CoW *p = (CoW *)ptr;
        Callback *cb = (Callback *)dcbGetUserData((DCCallback *)p->cb);
        SvSetSV(RETVAL, cb->cv);
    } break;
    case DC_SIGCHAR_INSTANCEOF: {
        RETVAL = ptr2sv(aTHX_ ptr, _instanceof(aTHX_ type));
    } break;
    case DC_SIGCHAR_ENUM: {
        SvSetSV(RETVAL, enum2sv(aTHX_ type, *(int *)ptr));
    }; break;
    case DC_SIGCHAR_ENUM_UINT: {
        SvSetSV(RETVAL, enum2sv(aTHX_ type, *(unsigned int *)ptr));
    }; break;
    case DC_SIGCHAR_ENUM_CHAR: {
        SvSetSV(RETVAL, enum2sv(aTHX_ type, (IV) * (char *)ptr));
    }; break;
    default:
        croak("Oh, this is unexpected: %c", _type[0]);
    }
    return RETVAL;
}

void sv2ptr(pTHX_ SV *type, SV *data, DCpointer ptr, bool packed) {
    char *str = SvPVbytex_nolen(type);
    //~ warn("sv2ptr(%c, ..., %p, %s) at %s line %d", str[0], ptr, (packed ? "true" : "false"),
    //~ __FILE__, __LINE__);
    switch (str[0]) {
    case DC_SIGCHAR_VOID: {
        if (!SvOK(data))
            Zero(ptr, 1, intptr_t);
        else if (sv_derived_from(data, "Affix::Pointer")) {
            IV tmp = SvIV((SV *)SvRV(data));
            ptr = INT2PTR(DCpointer, tmp);
            Copy((DCpointer)(&data), ptr, 1, intptr_t);
        }
        else
            croak("Expected a subclass of Affix::Pointer");
    } break;
    case DC_SIGCHAR_BOOL: {
        bool value = SvOK(data) ? SvTRUE(data) : (bool)0; // default to false
        Copy(&value, ptr, 1, bool);
    } break;
    case DC_SIGCHAR_ENUM_CHAR:
    case DC_SIGCHAR_CHAR: {
        if (SvPOK(data)) {
            char *value = SvPV_nolen(data);
            Copy(&value, ptr, 1, char);
        }
        else {
            char value = SvIOK(data) ? SvIV(data) : 0;
            Copy(&value, ptr, 1, char);
        }
    } break;
    case DC_SIGCHAR_UCHAR: {
        if (SvPOK(data)) {
            unsigned char *value = (unsigned char *)SvPV_nolen(data);
            Copy(&value, ptr, 1, unsigned char);
        }
        else {
            unsigned char value = SvUOK(data) ? SvUV(data) : 0;
            Copy(&value, ptr, 1, unsigned char);
        }
    } break;
    case DC_SIGCHAR_SHORT: {
        short value = SvIOK(data) ? (short)SvIV(data) : 0;
        Copy(&value, ptr, 1, short);
    } break;
    case DC_SIGCHAR_USHORT: {
        unsigned short value = SvUOK(data) ? (unsigned short)SvIV(data) : 0;
        Copy(&value, ptr, 1, unsigned short);
    } break;
    case DC_SIGCHAR_ENUM:
    case DC_SIGCHAR_INT: {
        int value = SvIOK(data) ? SvIV(data) : 0;
        Copy(&value, ptr, 1, int);
    } break;
    case DC_SIGCHAR_ENUM_UINT:
    case DC_SIGCHAR_UINT: {
        unsigned int value = SvUOK(data) ? SvUV(data) : 0;
        Copy(&value, ptr, 1, unsigned int);
    } break;
    case DC_SIGCHAR_LONG: {
        long value = SvIOK(data) ? SvIV(data) : 0;
        Copy(&value, ptr, 1, long);
    } break;
    case DC_SIGCHAR_ULONG: {
        unsigned long value = SvUOK(data) ? SvUV(data) : 0;
        Copy(&value, ptr, 1, unsigned long);
    } break;
    case DC_SIGCHAR_LONGLONG: {
        I64 value = SvIOK(data) ? SvIV(data) : 0;
        Copy(&value, ptr, 1, I64);
    } break;
    case DC_SIGCHAR_ULONGLONG: {
        U64 value = SvIOK(data) ? SvUV(data) : 0;
        Copy(&value, ptr, 1, U64);
    } break;
    case DC_SIGCHAR_FLOAT: {
        float value = SvOK(data) ? SvNV(data) : 0.0f;
        Copy(&value, ptr, 1, float);
    } break;
    case DC_SIGCHAR_DOUBLE: {
        double value = SvOK(data) ? SvNV(data) : 0.0f;
        Copy(&value, ptr, 1, double);
    } break;
    case DC_SIGCHAR_POINTER: {
        HV *hv_ptr = MUTABLE_HV(SvRV(type));
        SV **type_ptr = hv_fetchs(hv_ptr, "type", 0);
        DCpointer value = safemalloc(_sizeof(aTHX_ * type_ptr));
        if (SvOK(data)) sv2ptr(aTHX_ * type_ptr, data, value, packed);
        Copy(&value, ptr, 1, intptr_t);
    } break;
    case DC_SIGCHAR_STRING: {
        if (SvPOK(data)) {
            STRLEN len;
            const char *str = SvPV(data, len);
            DCpointer value;
            Newxz(value, len + 1, char);
            Copy(str, value, len, char);
            Copy(&value, ptr, 1, intptr_t);
        }
        else
            Zero(ptr, 1, intptr_t);
    } break;
    case DC_SIGCHAR_WIDE_STRING: {
        if (SvPOK(data)) {
            SV *idk = call_encoding(aTHX_ "encode", find_encoding(aTHX), data, NULL);
            STRLEN len;
            char *str = SvPV(idk, len);
            DCpointer value;
            Newxz(value, len + WCHAR_T_SIZE, char);
            Copy(str, value, len, char);
            Copy(&value, ptr, 1, intptr_t);
        }
        else
            Zero(ptr, 1, intptr_t);
    } break;
    case DC_SIGCHAR_INSTANCEOF: {
        HV *hv_ptr = MUTABLE_HV(SvRV(type));
        SV **type_ptr = hv_fetchs(hv_ptr, "type", 0);
        DCpointer value = safemalloc(_sizeof(aTHX_ * type_ptr));
        if (SvOK(data)) sv2ptr(aTHX_ _instanceof(aTHX_ * type_ptr), data, value, packed);
        Copy(&value, ptr, 1, intptr_t);
    } break;
    case DC_SIGCHAR_UNION:
    case DC_SIGCHAR_STRUCT: {
        size_t size = _sizeof(aTHX_ type);
        if (SvOK(data)) {
            if (SvTYPE(SvRV(data)) != SVt_PVHV) croak("Expected a hash reference");
            HV *hv_type = MUTABLE_HV(SvRV(type));
            HV *hv_data = MUTABLE_HV(SvRV(data));
            SV **sv_fields = hv_fetchs(hv_type, "fields", 0);
            SV **sv_packed = hv_fetchs(hv_type, "packed", 0);
            AV *av_fields = MUTABLE_AV(SvRV(*sv_fields));
            int field_count = av_count(av_fields);
            for (int i = 0; i < field_count; ++i) {
                SV **field = av_fetch(av_fields, i, 0);
                AV *name_type = MUTABLE_AV(SvRV(*field));
                SV **name_ptr = av_fetch(name_type, 0, 0);
                SV **type_ptr = av_fetch(name_type, 1, 0);
                char *key = SvPVbytex_nolen(*name_ptr);
                SV **_data = hv_fetch(hv_data, key, strlen(key), 1);
                if (data != NULL)
                    sv2ptr(aTHX_ * type_ptr, *(hv_fetch(hv_data, key, strlen(key), 1)),
                           INT2PTR(DCpointer, PTR2IV(ptr) + _offsetof(aTHX_ * type_ptr)), packed);
            }
        }
    } break;
    case DC_SIGCHAR_ARRAY: {
        int spot = 1;
        AV *elements = MUTABLE_AV(SvRV(data));
        SV *pointer;
        HV *hv_ptr = MUTABLE_HV(SvRV(type));
        SV **type_ptr = hv_fetchs(hv_ptr, "type", 0);
        SV **size_ptr = hv_fetchs(hv_ptr, "size", 0);
        size_t size = SvOK(*size_ptr) ? SvIV(*size_ptr) : av_len(elements);
        hv_stores(hv_ptr, "size_", newSViv(size));
        char *type_char = SvPVbytex_nolen(*type_ptr);
        switch (type_char[0]) {
        case DC_SIGCHAR_CHAR:
        case DC_SIGCHAR_UCHAR: {
            if (SvPOK(data)) {
                if (type_char[0] == DC_SIGCHAR_CHAR) {
                    char *value = SvPV(data, size);
                    Copy(value, ptr, size, char);
                }
                else {
                    unsigned char *value = (unsigned char *)SvPV(data, size);
                    Copy(value, ptr, size, unsigned char);
                }
                break;
            }
        }
        // fall through
        default: {
            if (SvTYPE(SvRV(data)) != SVt_PVAV) croak("Expected an array");
            // //sv_dump(*type_ptr);
            // //sv_dump(*size_ptr);
            size_t av_len = av_count(elements);
            if (SvOK(*size_ptr)) {
                if (av_len != size)
                    croak("Expected and array of %zu elements; found %zu", size, av_len);
            }
            size_t el_len = _sizeof(aTHX_ * type_ptr);
            size_t pos = 0; // override
            for (int i = 0; i < av_len; ++i) {
                //~ warn("Putting index %d into pointer plus %d", i, pos);
                sv2ptr(aTHX_ * type_ptr, *(av_fetch(elements, i, 0)),
                       INT2PTR(DCpointer, PTR2IV(ptr) + pos), packed);
                pos += (el_len);
            }
        }
            // return _sizeof(aTHX_ type);
        }
    } break;
    case DC_SIGCHAR_CODE: {
        DCCallback *cb = NULL;
        HV *field = MUTABLE_HV(SvRV(type)); // Make broad assumptions
        SV **sig = hv_fetchs(field, "signature", 0);
        SV **sig_len = hv_fetchs(field, "sig_len", 0);
        SV **ret = hv_fetchs(field, "return", 0);
        SV **args = hv_fetchs(field, "args", 0);
        Callback *callback;
        Newxz(callback, 1, Callback);
        callback->args = MUTABLE_AV(SvRV(*args));
        callback->sig = SvPV_nolen(*sig);
        callback->sig_len = (size_t)SvIV(*sig_len);
        callback->ret = (char)*SvPV_nolen(*ret);
        callback->cv = SvREFCNT_inc(data);
        storeTHX(callback->perl);
        cb = dcbNewCallback(callback->sig, cbHandler, callback);
        {
            CoW *hold;
            Newxz(hold, 1, CoW);
            hold->cb = cb;
            Copy(hold, ptr, 1, DCpointer);
        }
    } break;
    default: {
        char *str = SvPVbytex_nolen(type);
        sv_dump(type);
        croak("%c is not a known type in sv2ptr(...)", str[0]);
    }
    }
    return;
}

char cbHandler(DCCallback *cb, DCArgs *args, DCValue *result, DCpointer userdata) {
    Callback *cbx = (Callback *)userdata;
    dTHXa(cbx->perl);
    dSP;
    int count;
    char ret_c = cbx->ret;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, cbx->sig_len);
    if (cbx->sig_len) {
        char type;
        for (size_t i = 0; i < cbx->sig_len; ++i) {
            type = cbx->sig[i];
            switch (type) {
            case DC_SIGCHAR_VOID:
                // TODO: push undef?
                break;
            case DC_SIGCHAR_BOOL:
                mPUSHs(boolSV(dcbArgBool(args)));
                break;
            case DC_SIGCHAR_CHAR:
                mPUSHi((IV)dcbArgChar(args));
                break;
            case DC_SIGCHAR_UCHAR:
                mPUSHu((UV)dcbArgChar(args));
                break;
            case DC_SIGCHAR_SHORT:
                mPUSHi((IV)dcbArgShort(args));
                break;
            case DC_SIGCHAR_USHORT:
                mPUSHu((UV)dcbArgShort(args));
                break;
            case DC_SIGCHAR_INT:
                mPUSHi((IV)dcbArgInt(args));
                break;
            case DC_SIGCHAR_UINT:
                mPUSHu((UV)dcbArgInt(args));
                break;
            case DC_SIGCHAR_LONG:
                mPUSHi((IV)dcbArgLong(args));
                break;
            case DC_SIGCHAR_ULONG:
                mPUSHu((UV)dcbArgLong(args));
                break;
            case DC_SIGCHAR_LONGLONG:
                mPUSHi((IV)dcbArgLongLong(args));
                break;
            case DC_SIGCHAR_ULONGLONG:
                mPUSHu((UV)dcbArgLongLong(args));
                break;
            case DC_SIGCHAR_FLOAT:
                mPUSHn((NV)dcbArgFloat(args));
                break;
            case DC_SIGCHAR_DOUBLE:
                mPUSHn((NV)dcbArgDouble(args));
                break;
            case DC_SIGCHAR_POINTER: {
                DCpointer ptr = dcbArgPointer(args);
                SV *__type = *av_fetch(cbx->args, i, 0);
                char *_type = SvPV_nolen(__type);
                switch (_type[0]) { // true type
                case DC_SIGCHAR_ANY: {
                    SV *s = ptr2sv(aTHX_ ptr, __type);
                    mPUSHs(s);
                } break;
                case DC_SIGCHAR_CODE: {
                    Callback *cb = (Callback *)dcbGetUserData((DCCallback *)ptr);
                    mPUSHs(cb->cv);
                } break;
                default:
                    mPUSHs(sv_setref_pv(newSV(1), "Affix::Pointer", ptr));
                    break;
                }
            } break;
            case DC_SIGCHAR_STRING: {
                DCpointer ptr = dcbArgPointer(args);
                PUSHs(newSVpv((char *)ptr, 0));
            } break;
            case DC_SIGCHAR_WIDE_STRING: {
                DCpointer ptr = dcbArgPointer(args);
                PUSHs(newSVpvn_utf8((char *)ptr, 0, 1));
            } break;
            case DC_SIGCHAR_INSTANCEOF: {
                DCpointer ptr = dcbArgPointer(args);
                HV *blessed = MUTABLE_HV(SvRV(*av_fetch(cbx->args, i, 0)));
                SV **package = hv_fetchs(blessed, "package", 0);
                PUSHs(sv_setref_pv(newSV(1), SvPV_nolen(*package), ptr));
            } break;
            case DC_SIGCHAR_ENUM:
            case DC_SIGCHAR_ENUM_UINT: {
                PUSHs(enum2sv(aTHX_ * av_fetch(cbx->args, i, 0), dcbArgInt(args)));
            } break;
            case DC_SIGCHAR_ENUM_CHAR: {
                PUSHs(enum2sv(aTHX_ * av_fetch(cbx->args, i, 0), dcbArgChar(args)));
            } break;
            case DC_SIGCHAR_ANY: {
                DCpointer ptr = dcbArgPointer(args);
                SV *sv = newSV(0);
                if (ptr != NULL && SvOK(MUTABLE_SV(ptr))) { sv = MUTABLE_SV(ptr); }
                PUSHs(sv);
            } break;
            default:
                croak("Unhandled callback arg. Type: %c [%s]", cbx->sig[i], cbx->sig);
                break;
            }
        }
    }
    PUTBACK;
    if (cbx->ret == DC_SIGCHAR_VOID) {
        count = call_sv(cbx->cv, G_VOID);
        SPAGAIN;
    }
    else {
        count = call_sv(cbx->cv, G_SCALAR);
        SPAGAIN;
        if (count != 1) croak("Big trouble: %d returned items", count);
        SV *ret = POPs;
        switch (ret_c) {
        case DC_SIGCHAR_VOID:
            break;
        case DC_SIGCHAR_BOOL:
            result->B = SvTRUEx(ret);
            break;
        case DC_SIGCHAR_CHAR:
            result->c = SvIOK(ret) ? SvIV(ret) : 0;
            break;
        case DC_SIGCHAR_UCHAR:
            result->C = SvIOK(ret) ? ((UV)SvUVx(ret)) : 0;
            break;
        case DC_SIGCHAR_SHORT:
            result->s = SvIOK(ret) ? SvIVx(ret) : 0;
            break;
        case DC_SIGCHAR_USHORT:
            result->S = SvIOK(ret) ? SvUVx(ret) : 0;
            break;
        case DC_SIGCHAR_INT:
            result->i = SvIOK(ret) ? SvIVx(ret) : 0;
            break;
        case DC_SIGCHAR_UINT:
            result->I = SvIOK(ret) ? SvUVx(ret) : 0;
            break;
        case DC_SIGCHAR_LONG:
            result->j = SvIOK(ret) ? SvIVx(ret) : 0;
            break;
        case DC_SIGCHAR_ULONG:
            result->J = SvIOK(ret) ? SvUVx(ret) : 0;
            break;
        case DC_SIGCHAR_LONGLONG:
            result->l = SvIOK(ret) ? SvIVx(ret) : 0;
            break;
        case DC_SIGCHAR_ULONGLONG:
            result->L = SvIOK(ret) ? SvUVx(ret) : 0;
            break;
        case DC_SIGCHAR_FLOAT:
            result->f = SvNOK(ret) ? SvNVx(ret) : 0.0;
            break;
        case DC_SIGCHAR_DOUBLE:
            result->d = SvNOK(ret) ? SvNVx(ret) : 0.0;
            break;
        case DC_SIGCHAR_POINTER: {
            if (SvOK(ret)) {
                if (sv_derived_from(ret, "Affix::Pointer")) {
                    IV tmp = SvIV((SV *)SvRV(ret));
                    result->p = INT2PTR(DCpointer, tmp);
                }
                else
                    croak("Returned value is not a Affix::Pointer or subclass");
            }
            else
                result->p = NULL; // ha.
        } break;
        case DC_SIGCHAR_STRING:
            result->Z = SvPOK(ret) ? SvPVx_nolen_const(ret) : NULL;
            break;
        case DC_SIGCHAR_WIDE_STRING:
            result->p = SvPOK(ret) ? (DCpointer)SvPVx_nolen_const(ret) : NULL;
            ret_c = DC_SIGCHAR_POINTER;
            break;
        case DC_SIGCHAR_STRUCT:
        case DC_SIGCHAR_UNION:
        case DC_SIGCHAR_INSTANCEOF:
        case DC_SIGCHAR_ANY:
            //~ result->p = SvPOK(ret) ?  sv2ptr(aTHX_ ret, _instanceof(aTHX_ cbx->retval), false):
            //NULL; ~ ret_c = DC_SIGCHAR_POINTER; ~ break;
        default:
            croak("Unhandled return from callback: %c", ret_c);
        }
    }
    PUTBACK;

    FREETMPS;
    LEAVE;

    return ret_c;
}

typedef struct {
    SV *type;
    void *ptr;
} var_ptr;

int get_pin(pTHX_ SV *sv, MAGIC *mg) {
    var_ptr *ptr = (var_ptr *)mg->mg_ptr;
    SV *val = ptr2sv(aTHX_ ptr->ptr, ptr->type);
    sv_setsv(sv, val);
    return 0;
}

int set_pin(pTHX_ SV *sv, MAGIC *mg) {
    var_ptr *ptr = (var_ptr *)mg->mg_ptr;
    if (SvOK(sv)) sv2ptr(aTHX_ ptr->type, sv, ptr->ptr, false);
    return 0;
}

int free_pin(pTHX_ SV *sv, MAGIC *mg) {
    var_ptr *ptr = (var_ptr *)mg->mg_ptr;
    sv_2mortal(ptr->type);
    safefree(ptr);
    return 0;
}

static MGVTBL pin_vtbl = {
    get_pin,  // get
    set_pin,  // set
    NULL,     // len
    NULL,     // clear
    free_pin, // free
    NULL,     // copy
    NULL,     // dup
    NULL      // local
};

XS_INTERNAL(Types_wrapper) {
    dVAR;
    dXSARGS;
    dXSI32;
    char *package = (char *)XSANY.any_ptr;
    package = form("%s", package);
    SV *RETVAL;
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        mXPUSHs(newSVpv(package, 0));
        for (int i = 0; i < items; i++)
            mXPUSHs(newSVsv(ST(i)));
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        if (count != 1) croak("Big trouble\n");
        RETVAL = newSVsv(POPs);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    RETVAL = sv_2mortal(RETVAL);
    ST(0) = RETVAL;
    XSRETURN(1);
}

XS_INTERNAL(Types) {
    dVAR;
    dXSARGS;
    dXSI32;
    dMY_CXT;
    char *package = (char *)SvPV_nolen(ST(0));
    HV *RETVAL_HV = newHV();
    switch (ix) {
    case DC_SIGCHAR_ENUM:
    case DC_SIGCHAR_ENUM_UINT:
    case DC_SIGCHAR_ENUM_CHAR: {
        AV *vals = MUTABLE_AV(SvRV(ST(1)));
        AV *values = newAV_mortal();
        SV *current_value = newSViv(0);
        for (int i = 0; i < av_count(vals); ++i) {
            SV *name = newSV(0);
            SV **item = av_fetch(vals, i, 0);
            if (SvROK(*item)) {
                if (SvTYPE(SvRV(*item)) == SVt_PVAV) {
                    AV *cast = MUTABLE_AV(SvRV(*item));
                    if (av_count(cast) == 2) {
                        name = *av_fetch(cast, 0, 0);
                        current_value = *av_fetch(cast, 1, 0);
                        if (!SvIOK(current_value)) { // C-like enum math like: enum { a,
                                                     // b, c = a+b}
                            char *eval = NULL;
                            size_t pos = 0;
                            size_t size = 1024;
                            Newxz(eval, size, char);
                            for (int i = 0; i < av_count(values); i++) {
                                SV *e = *av_fetch(values, i, 0);
                                char *str = SvPV_nolen(e);
                                char *line;
                                if (SvIOK(e)) {
                                    int num = SvIV(e);
                                    line = form("sub %s(){%d}", str, num);
                                }
                                else {
                                    char *chr = SvPV_nolen(e);
                                    line = form("sub %s(){'%s'}", str, chr);
                                }
                                // size_t size = pos + strlen(line);
                                size = (strlen(eval) > (size + strlen(line))) ? size + strlen(line)
                                                                              : size;
                                Renewc(eval, size, char, char);
                                Copy(line, INT2PTR(DCpointer, PTR2IV(eval) + pos), strlen(line) + 1,
                                     char);
                                pos += strlen(line);
                            }
                            current_value = eval_pv(form("package Affix::Enum::eval{no warnings "
                                                         "qw'redefine reserved';%s%s}",
                                                         eval, SvPV_nolen(current_value)),
                                                    1);
                            safefree(eval);
                        }
                    }
                }
                else { croak("Enum element must be a [key => value] pair"); }
            }
            else
                sv_setsv(name, *item);
            {
                SV *TARGET = newSV(1);
                { // Let's make enum values dualvars just 'cause; snagged from
                  // Scalar::Util
                    SV *num = newSVsv(current_value);
                    (void)SvUPGRADE(TARGET, SVt_PVNV);
                    sv_copypv(TARGET, name);
                    if (SvNOK(num) || SvPOK(num) || SvMAGICAL(num)) {
                        SvNV_set(TARGET, SvNV(num));
                        SvNOK_on(TARGET);
                    }
#ifdef SVf_IVisUV
                    else if (SvUOK(num)) {
                        SvUV_set(TARGET, SvUV(num));
                        SvIOK_on(TARGET);
                        SvIsUV_on(TARGET);
                    }
#endif
                    else {
                        SvIV_set(TARGET, SvIV(num));
                        SvIOK_on(TARGET);
                    }
                    if (PL_tainting && (SvTAINTED(num) || SvTAINTED(name))) SvTAINTED_on(TARGET);
                }
                av_push(values, newSVsv(TARGET));
            }
            sv_inc(current_value);
        }
        hv_stores(RETVAL_HV, "values", newRV_inc(MUTABLE_SV(values)));
    }; break;
    case DC_SIGCHAR_ARRAY: { // ArrayRef[Int, 5]
        AV *type_size = MUTABLE_AV(SvRV(ST(1)));
        SV *type, *size;
        size_t array_length, array_sizeof = 0;
        bool packed = false;
        switch (av_count(type_size)) {
        case 1: {
            size = newSV(1);
            type = *av_fetch(type_size, 0, 0);
            if (!(sv_isobject(type) && sv_derived_from(type, "Affix::Type::Base")))
                croak("Given type for '%s' is not a subclass of Affix::Type::Base",
                      SvPV_nolen(type));
            size_t offset = 0;
            size_t type_sizeof = _sizeof(aTHX_ type);
        } break;
        case 2: {
            array_length = SvUV(*av_fetch(type_size, 1, 0));
            if (array_length < 1) croak("Given size %zd is not a positive integer", array_length);
            type = *av_fetch(type_size, 0, 0);
            if (!(sv_isobject(type) && sv_derived_from(type, "Affix::Type::Base")))
                croak("Given type for '%s' is not a subclass of Affix::Type::Base",
                      SvPV_nolen(type));
            size_t offset = 0;
            size_t type_sizeof = _sizeof(aTHX_ type);
            for (int i = 0; i < array_length; ++i) {
                array_sizeof += type_sizeof;
                array_sizeof +=
                    packed ? 0
                           : padding_needed_for(array_sizeof, AFFIX_ALIGNBYTES > type_sizeof
                                                                  ? type_sizeof
                                                                  : AFFIX_ALIGNBYTES);
                offset = array_sizeof;
            }
            size = newSVuv(array_length);
        } break;
        default:
            croak("Expected a single type and array length: "
                  "ArrayRef[Int, 5]");
        }
        hv_stores(RETVAL_HV, "sizeof", newSVuv(array_sizeof));
        hv_stores(RETVAL_HV, "size", size);
        hv_stores(RETVAL_HV, "name", newSV(0));
        hv_stores(RETVAL_HV, "packed", sv_2mortal(boolSV(packed)));
        hv_stores(RETVAL_HV, "type", newSVsv(type));
    } break;
    case DC_SIGCHAR_CODE: {
        AV *fields = newAV_mortal();
        SV *retval = sv_newmortal();
        size_t field_count;
        {
            if (items != 2) croak("CodeRef[ [args] => return]");
            AV *args = MUTABLE_AV(SvRV(ST(1)));
            if (av_count(args) != 2) croak("Expected a list of arguments and a return value");
            fields = MUTABLE_AV(SvRV(*av_fetch(args, 0, 0)));
            field_count = av_count(fields);
            for (int i = i; i < field_count; ++i) {
                SV **type_ref = av_fetch(fields, i, 0);
                if (!(sv_isobject(*type_ref) && sv_derived_from(*type_ref, "Affix::Type::Base")))
                    croak("Given type for CodeRef %d is not a subclass of "
                          "Affix::Type::Base",
                          i);
                av_push(fields, SvREFCNT_inc(((*type_ref))));
            }
            sv_setsv(retval, *av_fetch(args, 1, 0));
            if (!(sv_isobject(retval) && sv_derived_from(retval, "Affix::Type::Base")))
                croak("Given type for return value is not a subclass of "
                      "Affix::Type::Base");
            char *signature;
            Newxz(signature, field_count + 1, char);
            for (int i = 0; i < field_count; i++) {
                SV **type_ref = av_fetch(fields, i, 0);
                char *str = SvPVbytex_nolen(*type_ref);
                // av_push(cb->args, SvREFCNT_inc(*type_ref));
                switch (str[0]) {
                case DC_SIGCHAR_CODE:
                case DC_SIGCHAR_ARRAY:
                    signature[i] = DC_SIGCHAR_POINTER;
                    break;
                case DC_SIGCHAR_AGGREGATE:
                case DC_SIGCHAR_STRUCT:
                    signature[i] = DC_SIGCHAR_AGGREGATE;
                    break;
                default:
                    signature[i] = str[0];
                    break;
                }
            }
            signature[field_count] = ')';
            signature[field_count + 1] = (char)*SvPV_nolen(retval);
            hv_stores(RETVAL_HV, "args", SvREFCNT_inc(*av_fetch(args, 0, 0)));
            hv_stores(RETVAL_HV, "return", SvREFCNT_inc(retval));
            hv_stores(RETVAL_HV, "sig_len", newSViv(field_count));
            hv_stores(RETVAL_HV, "signature", newSVpv(signature, field_count + 2));
        }
    } break;
    case DC_SIGCHAR_STRUCT:
    case DC_SIGCHAR_UNION: {
        if (items == 2) {
            bool packed = false; // TODO: handle packed structs correctly
            hv_stores(RETVAL_HV, "packed", boolSV(packed));
            AV *fields = newAV();
            AV *fields_in = MUTABLE_AV(SvRV(ST(1)));
            size_t field_count = av_count(fields_in);
            size_t size = 0;
            if (field_count && field_count % 2) croak("Expected an even sized list");
            for (int i = 0; i < field_count; i += 2) {
                AV *field = newAV();
                SV *key = newSVsv(*av_fetch(fields_in, i, 0));
                if (!SvPOK(key)) croak("Given name of '%s' is not a string", SvPV_nolen(key));
                SV *type = *av_fetch(fields_in, i + 1, 0);
                if (!(sv_isobject(type) && sv_derived_from(type, "Affix::Type::Base")))
                    croak("Given type for '%s' is not a subclass of Affix::Type::Base",
                          SvPV_nolen(key));
                size_t __sizeof = _sizeof(aTHX_ type);
                if (ix == DC_SIGCHAR_STRUCT) {
                    size += packed ? 0
                                   : padding_needed_for(size, AFFIX_ALIGNBYTES > __sizeof
                                                                  ? __sizeof
                                                                  : AFFIX_ALIGNBYTES);
                    size += __sizeof;
                    (void)hv_stores(MUTABLE_HV(SvRV(type)), "offset", newSVuv(size - __sizeof));
                }
                else {
                    if (size < __sizeof) size = __sizeof;
                    if (!packed && field_count > 1 && __sizeof > AFFIX_ALIGNBYTES)
                        size += padding_needed_for(__sizeof, AFFIX_ALIGNBYTES);
                    (void)hv_stores(MUTABLE_HV(SvRV(type)), "offset", newSVuv(0));
                }
                (void)hv_stores(MUTABLE_HV(SvRV(type)), "sizeof", newSVuv(__sizeof));
                av_push(field, SvREFCNT_inc(key));
                SV **value_ptr = av_fetch(fields_in, i + 1, 0);
                SV *value = *value_ptr;
                av_push(field, SvREFCNT_inc(value));
                SV *sv_field = (MUTABLE_SV(field));
                av_push(fields, newRV(sv_field));
            }

            if (ix == DC_SIGCHAR_STRUCT) {
                if (!packed && size > AFFIX_ALIGNBYTES * 2)
                    size += padding_needed_for(size, AFFIX_ALIGNBYTES);
            }
            hv_stores(RETVAL_HV, "sizeof", newSVuv(size));
            hv_stores(RETVAL_HV, "fields", newRV(MUTABLE_SV(fields)));
        }
        else
            croak("%s[...] expected an even a list of elements",
                  ix == DC_SIGCHAR_STRUCT ? "Struct" : "Union");
    } break;
    case DC_SIGCHAR_POINTER: {
        AV *fields = MUTABLE_AV(SvRV(ST(1)));
        if (av_count(fields) == 1) {
            SV *inside;
            SV **type_ref = av_fetch(fields, 0, 0);
            SV *type = *type_ref;
            if (!(sv_isobject(type) && sv_derived_from(type, "Affix::Type::Base")))
                croak("Pointer[...] expects a subclass of Affix::Type::Base");
            hv_stores(RETVAL_HV, "type", SvREFCNT_inc(type));
        }
        else
            croak("Pointer[...] expects a single type. e.g. Pointer[Int]");
    } break;
    case DC_SIGCHAR_INSTANCEOF: {
        AV *packages_in = MUTABLE_AV(SvRV(ST(1)));
        if (av_count(packages_in) != 1) croak("InstanceOf[...] expects a single package name");
        SV **package_ptr = av_fetch(packages_in, 0, 0);
        if (is_valid_class_name(*package_ptr))
            hv_stores(RETVAL_HV, "package", newSVsv(*package_ptr));
        else
            croak("%s is not a known type", SvPVbytex_nolen(*package_ptr));
    } break;
    case DC_SIGCHAR_ANY: {
        break;
    } break;
    default:
        if (items > 1)
            croak("Too many arguments for subroutine '%s' (got %d; expected 0)", package, items);
        break;
    }

    SV *self = newRV_inc(MUTABLE_SV(RETVAL_HV));
    ST(0) = sv_bless(self, gv_stashpv(package, GV_ADD));
    XSRETURN(1);
}

XS_INTERNAL(Types_sig) {
    dXSARGS;
    dXSI32;
    dXSTARG;
    if (PL_phase == PERL_PHASE_DESTRUCT) XSRETURN_IV(0);
    XSRETURN_PV((char *)&ix);
}

XS_INTERNAL(Types_return_typedef) {
    dXSARGS;
    dXSI32;
    dXSTARG;
    ST(0) = sv_2mortal(newSVsv(XSANY.any_sv));
    XSRETURN(1);
}

XS_INTERNAL(Types_type) {
    dXSARGS;
    dXSI32;
    dXSTARG;
    if (items != 1) croak("Expected 1 parameter; found %d", items);
    AV *args = MUTABLE_AV(SvRV(newSVsv(ST(0))));
    if (av_count(args) > 1) croak("Expected 1 parameter; found %zu", av_count(args));
    SV *type = av_shift(args);
    if (SvPOK(type)) {
        HV *type_registry = get_hv("Affix::Type::_reg", GV_ADD);
        const char *type_str = SvPV_nolen(type);
        if (!hv_exists_ent(type_registry, type, 0)) croak("Type named '%s' is undefined", type_str);
        type = MUTABLE_SV(SvRV(*hv_fetch(type_registry, type_str, strlen(type_str), 0)));
    }
    ST(0) = newSVsv(type);
    XSRETURN(1);
}

XS_INTERNAL(Affix_call) {
    dVAR;
    dXSARGS;
    // dXSI32;
    dMY_CXT;
    Call *call = (Call *)XSANY.any_ptr;
    if (call->reset) dcReset(MY_CXT.cvm);
    bool pointers = false;
    if (call->sig_len != items) {
        if (call->sig_len < items && !call->reset) croak("Too many arguments");
        if (call->sig_len > items) croak("Not enough arguments");
    }
    DCaggr *agg;
    switch (call->ret) {
    case DC_SIGCHAR_AGGREGATE:
    case DC_SIGCHAR_UNION:
    case DC_SIGCHAR_ARRAY:
    case DC_SIGCHAR_STRUCT: {
        agg = _aggregate(aTHX_ call->retval);
        dcBeginCallAggr(MY_CXT.cvm, agg);
    } break;
    default:
        break;
    }

    char _type;
    DCpointer pointer[items];
    bool l_pointer[items];
    {
        SV *type;
        for (size_t pos_arg = 0, pos_csig = 0, pos_psig = 0; pos_arg < items;
             ++pos_arg, ++pos_csig, ++pos_psig) {
            type = *av_fetch(call->args, pos_arg, 0); // Make broad assexumptions
            _type = call->sig[pos_csig];
            switch (_type) {
            case DC_SIGCHAR_VOID:
                break;
            case DC_SIGCHAR_BOOL:
                dcArgBool(MY_CXT.cvm, SvTRUE(ST(pos_arg))); // Anything can be a bool
                break;
            case DC_SIGCHAR_CHAR:
                dcArgChar(MY_CXT.cvm, (char)(SvIOK(ST(pos_arg)) ? SvIV(ST(pos_arg))
                                                                : *SvPV_nolen(ST(pos_arg))));
                break;
            case DC_SIGCHAR_UCHAR:
                dcArgChar(MY_CXT.cvm,
                          (unsigned char)(SvIOK(ST(pos_arg)) ? SvUV(ST(pos_arg))
                                                             : *SvPV_nolen(ST(pos_arg))));
                break;
            case DC_SIGCHAR_SHORT:
                dcArgShort(MY_CXT.cvm, (short)(SvIV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_USHORT:
                dcArgShort(MY_CXT.cvm, (unsigned short)(SvUV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_INT:
                dcArgInt(MY_CXT.cvm, (int)(SvIV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_UINT:
                dcArgInt(MY_CXT.cvm, (unsigned int)(SvUV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_LONG:
                dcArgLong(MY_CXT.cvm, (long)(SvIV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_ULONG:
                dcArgLong(MY_CXT.cvm, (unsigned long)(SvUV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_LONGLONG:
                dcArgLongLong(MY_CXT.cvm, (I64)(SvIV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_ULONGLONG:
                dcArgLongLong(MY_CXT.cvm, (U64)(SvUV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_FLOAT:
                dcArgFloat(MY_CXT.cvm, (float)SvNV(ST(pos_arg)));
                break;
            case DC_SIGCHAR_DOUBLE:
                dcArgDouble(MY_CXT.cvm, (double)SvNV(ST(pos_arg)));
                break;
            case DC_SIGCHAR_POINTER: {
                SV **subtype_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "type", 0);
                if (SvOK(ST(pos_arg))) {
                    if (sv_derived_from(ST(pos_arg), "Affix::Pointer")) {
                        IV tmp = SvIV((SV *)SvRV(ST(pos_arg)));
                        pointer[pos_arg] = INT2PTR(DCpointer, tmp);
                        l_pointer[pos_arg] = false;
                        pointers = true;
                    }
                    else {
                        if (sv_isobject(ST(pos_arg))) croak("Unexpected pointer to blessed object");
                        pointer[pos_arg] = safemalloc(_sizeof(aTHX_ * subtype_ptr));
                        sv2ptr(aTHX_ * subtype_ptr, ST(pos_arg), pointer[pos_arg], false);
                        l_pointer[pos_arg] = true;
                        pointers = true;
                    }
                }
                else if (SvREADONLY(ST(pos_arg))) { // explicit undef
                    pointer[pos_arg] = NULL;
                    l_pointer[pos_arg] = false;
                }
                else { // treat as if it's an lST(pos_arg)
                    SV **subtype_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "type", 0);
                    SV *type = *subtype_ptr;
                    size_t size = _sizeof(aTHX_ type);
                    Newxz(pointer[pos_arg], size, char);
                    l_pointer[pos_arg] = true;
                    pointers = true;
                }
                dcArgPointer(MY_CXT.cvm, pointer[pos_arg]);
            } break;
            case DC_SIGCHAR_INSTANCEOF: { // Essentially the same as DC_SIGCHAR_POINTER
                SV **package_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "package", 0);
                DCpointer ptr;
                if (SvROK(ST(pos_arg)) &&
                    sv_derived_from((ST(pos_arg)), (const char *)SvPVbytex_nolen(*package_ptr))) {
                    IV tmp = SvIV((SV *)SvRV(ST(pos_arg)));
                    ptr = INT2PTR(DCpointer, tmp);
                }
                else if (!SvOK(ST(pos_arg))) // Passed us an undef
                    ptr = NULL;
                else
                    croak("Type of arg %lu must be an instance or subclass of %s", pos_arg + 1,
                          SvPVbytex_nolen(*package_ptr));
                dcArgPointer(MY_CXT.cvm, ptr);
            } break;
            case DC_SIGCHAR_ANY: {
                if (!SvOK(ST(pos_arg))) sv_set_undef(ST(pos_arg));
                dcArgPointer(MY_CXT.cvm, SvREFCNT_inc(ST(pos_arg)));
            } break;
            case DC_SIGCHAR_STRING: {
                dcArgPointer(MY_CXT.cvm, !SvOK(ST(pos_arg)) ? NULL : SvPV_nolen(ST(pos_arg)));
            } break;
            case DC_SIGCHAR_WIDE_STRING: {
                if (SvOK(ST(pos_arg))) {
                    l_pointer[pos_arg] = false;
                    SV *idk = call_encoding(aTHX_ "encode", find_encoding(aTHX), ST(pos_arg), NULL);
                    STRLEN len;
                    char *holder = SvPV(idk, len);
                    pointer[pos_arg] = safecalloc(len + WCHAR_T_SIZE, 1);
                    Copy(holder, pointer[pos_arg], len, char);
                }
                else { Zero(pointer[pos_arg], 1, intptr_t); }
                dcArgPointer(MY_CXT.cvm, pointer[pos_arg]);
            } break;
            case DC_SIGCHAR_CODE: {
                if (SvOK(ST(pos_arg))) {
                    CoW *hold;
                    Newx(hold, 1, CoW);
                    sv2ptr(aTHX_ type, ST(pos_arg), hold, false);
                    dcArgPointer(MY_CXT.cvm, hold->cb);
                }
                else
                    dcArgPointer(MY_CXT.cvm, NULL);
            } break;
            case DC_SIGCHAR_ARRAY: {
                if (!SvOK(ST(pos_arg)) && SvREADONLY(ST(pos_arg)) // explicit undef
                ) {
                    dcArgPointer(MY_CXT.cvm, NULL);
                }
                else {
                    if (!SvROK(ST(pos_arg)) || SvTYPE(SvRV(ST(pos_arg))) != SVt_PVAV)
                        croak("Type of arg %lu must be an array ref", pos_arg + 1);
                    AV *elements = MUTABLE_AV(SvRV(ST(pos_arg)));
                    HV *hv_ptr = MUTABLE_HV(SvRV(type));
                    SV **type_ptr = hv_fetchs(hv_ptr, "type", 0);
                    SV **size_ptr = hv_fetchs(hv_ptr, "size", 0);
                    SV **ptr_ptr = hv_fetchs(hv_ptr, "pointer", 0);
                    size_t av_len;
                    if (SvOK(*size_ptr)) {
                        av_len = SvIV(*size_ptr);
                        if (av_count(elements) != av_len)
                            croak("Expected an array of %lu elements; found %zd", av_len,
                                  av_count(elements));
                    }
                    else
                        av_len = av_count(elements);
                    hv_stores(hv_ptr, "size_", newSViv(av_len));
                    size_t size = _sizeof(aTHX_ * type_ptr);
                    //~ warn("av_len * size = %d * %d = %d", av_len, size, av_len * size);
                    Newxz(pointer[pos_arg], av_len * size, char);
                    l_pointer[pos_arg] = true;
                    pointers = true;
                    sv2ptr(aTHX_ type, ST(pos_arg), pointer[pos_arg], false);
                    dcArgPointer(MY_CXT.cvm, pointer[pos_arg]);
                }
            } break;
            case DC_SIGCHAR_STRUCT: {
                if (!SvROK(ST(pos_arg)) || SvTYPE(SvRV(ST(pos_arg))) != SVt_PVHV)
                    croak("Type of arg %lu must be a hash ref", pos_arg + 1);
                DCaggr *agg = _aggregate(aTHX_ type);
                DCpointer ptr = safemalloc(_sizeof(aTHX_ type));
                sv2ptr(aTHX_ type, ST(pos_arg), ptr, false);
                dcArgAggr(MY_CXT.cvm, agg, ptr);
            } break;
            case DC_SIGCHAR_ENUM:
                dcArgInt(MY_CXT.cvm, (int)(SvIV(ST(pos_arg))));
                break;
            case DC_SIGCHAR_ENUM_UINT:
                dcArgInt(MY_CXT.cvm, (unsigned int)SvUV(ST(pos_arg)));
                break;
            case DC_SIGCHAR_ENUM_CHAR:
                dcArgChar(MY_CXT.cvm, (char)(SvIOK(ST(pos_arg)) ? SvIV(ST(pos_arg))
                                                                : *SvPV_nolen(ST(pos_arg))));
                break;
            case DC_SIGCHAR_CC_PREFIX: {
                --pos_arg;
                DCsigchar _mode = call->sig[++pos_csig];
                DCint mode = dcGetModeFromCCSigChar(_mode);
                dcMode(MY_CXT.cvm, mode);
                switch (_mode) {
                case DC_SIGCHAR_CC_ELLIPSIS:
                case DC_SIGCHAR_CC_ELLIPSIS_VARARGS:
                    break; // TODO: Should I allow for this to reset anyway?
                default:
                    dcReset(MY_CXT.cvm);
                    break;
                }
                break;
            }
            default:
                croak("--> Unfinished: [%c/%lu]%s", call->sig[pos_csig], pos_arg, call->sig);
            }
        }
    }
    SV *RETVAL;
    {
        switch (call->ret) {
        case DC_SIGCHAR_VOID:
            RETVAL = newSV(0);
            dcCallVoid(MY_CXT.cvm, call->fptr);
            break;
        case DC_SIGCHAR_BOOL:
            RETVAL = newSV(0);
            sv_setbool_mg(RETVAL, (bool)dcCallBool(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_CHAR:
            RETVAL = newSViv((char)dcCallChar(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_UCHAR:
            RETVAL = newSVuv((unsigned char)dcCallChar(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_SHORT:
            RETVAL = newSViv((short)dcCallShort(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_USHORT:
            RETVAL = newSVuv((unsigned short)dcCallShort(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_INT:
            RETVAL = newSViv((int)dcCallInt(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_UINT:
            RETVAL = newSVuv((unsigned int)dcCallInt(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_LONG:
            RETVAL = newSViv((long)dcCallLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_ULONG:
            RETVAL = newSVuv((unsigned long)dcCallLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_LONGLONG:
            RETVAL = newSViv((I64)dcCallLongLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_ULONGLONG:
            RETVAL = newSVuv((U64)dcCallLongLong(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_FLOAT:
            RETVAL = newSVnv((float)dcCallFloat(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_DOUBLE:
            RETVAL = newSVnv((double)dcCallDouble(MY_CXT.cvm, call->fptr));
            break;
        case DC_SIGCHAR_POINTER: {
            SV *RETVALSV;
            RETVALSV = newSV(1);
            DCpointer ptr = dcCallPointer(MY_CXT.cvm, call->fptr);
            sv_setref_pv(RETVALSV, "Affix::Pointer", ptr);
            RETVAL = RETVALSV;
        } break;
        case DC_SIGCHAR_STRING:
            RETVAL = newSVpv((char *)dcCallPointer(MY_CXT.cvm, call->fptr), 0);
            break;
        case DC_SIGCHAR_WIDE_STRING: {
            DCpointer ret_ptr = dcCallPointer(MY_CXT.cvm, call->fptr);
            RETVAL = ptr2sv(aTHX_ ret_ptr, (call->retval));
        } break;
        case DC_SIGCHAR_INSTANCEOF: {
            DCpointer ptr = dcCallPointer(MY_CXT.cvm, call->fptr);
            SV **package = hv_fetchs(MUTABLE_HV(SvRV(call->retval)), "package", 0);
            RETVAL = newSV(1);
            sv_setref_pv(RETVAL, SvPVbytex_nolen(*package), ptr);
        } break;
        case DC_SIGCHAR_ANY: {
            DCpointer ptr = dcCallPointer(MY_CXT.cvm, call->fptr);
            if (ptr && SvOK((SV *)ptr))
                RETVAL = (SV *)ptr;
            else
                sv_set_undef(RETVAL);
        } break;
        case DC_SIGCHAR_AGGREGATE:
        case DC_SIGCHAR_STRUCT:
        case DC_SIGCHAR_UNION: {
            DCpointer ret_ptr = safemalloc(_sizeof(aTHX_ call->retval));
            dcCallAggr(MY_CXT.cvm, call->fptr, agg, ret_ptr);
            RETVAL = ptr2sv(aTHX_ ret_ptr, call->retval);
        } break;
        case DC_SIGCHAR_ENUM:
        case DC_SIGCHAR_ENUM_UINT: {
            RETVAL = enum2sv(aTHX_ call->retval, (int)dcCallInt(MY_CXT.cvm, call->fptr));
        } break;
        case DC_SIGCHAR_ENUM_CHAR: {
            RETVAL = enum2sv(aTHX_ call->retval, (char)dcCallChar(MY_CXT.cvm, call->fptr));
        } break;
        default:
            croak("Unhandled return type: %c", call->ret);
        }

        if (pointers) {
            for (int i = 0; i < call->sig_len; ++i) {
                switch (call->sig[i]) {
                case DC_SIGCHAR_ARRAY: {
                    SV *package = *av_fetch(call->args, i, 0); // Make broad assumptions
                    if (!SvREADONLY(ST(i))) {
                        SV *sv = ptr2sv(aTHX_ pointer[i], package);
                        if (SvFLAGS(ST(i)) & SVs_TEMP) { // likely a temp ref
                            size_t av_len = av_count(MUTABLE_AV(SvRV(ST(i))));
                            for (size_t q = 0; q < av_len; ++q) {
                                SV **blah_ptr = av_fetch(MUTABLE_AV(SvRV(sv)), q, 1);
                                SV *blah = *blah_ptr;
                                sv_setsv(*av_fetch(MUTABLE_AV(SvRV(ST(i))), q, 1), blah);
                                SvSETMAGIC(SvRV(ST(i)));
                            }
                        }
                        else // scalar ref is faster :D
                            SvSetMagicSV(ST(i), sv);
                    }
                } break;
                case DC_SIGCHAR_POINTER: {
                    SV *package = *av_fetch(call->args, i, 0); // Make broad assumptions
                    if (SvOK(ST(i)) && sv_derived_from(ST(i), "Affix::Pointer")) {
                        IV tmp = SvIV((SV *)SvRV(ST(i)));
                        pointer[i] = INT2PTR(DCpointer, tmp);
                    }
                    else if (!SvREADONLY(ST(i))) { // not explicit undef
                        HV *type_hv = MUTABLE_HV(SvRV(package));
                        SV **type_ptr = hv_fetchs(type_hv, "type", 0);
                        SV *type = *type_ptr;
                        char *_type = SvPV_nolen(type);
                        switch (_type[0]) {
                        case DC_SIGCHAR_VOID:
                            // let it pass through as a Affix::Pointer
                            break;
                        case DC_SIGCHAR_AGGREGATE:
                        case DC_SIGCHAR_STRUCT:
                        case DC_SIGCHAR_ARRAY: {
                            SvSetMagicSV(ST(i), ptr2sv(aTHX_ pointer[i], type));
                        } break;
                        default: {
                            SV *sv = ptr2sv(aTHX_ pointer[i], type);
                            if (!SvREADONLY(ST(i))) SvSetMagicSV(ST(i), sv);
                        }
                        }
                    }
                } break;
                default:
                    // croak("Unhandled pointer! %c", call->sig[i]);
                    break;
                }
                if (l_pointer[i] && pointer[i] != NULL) { pointer[i] = NULL; }
            }
        }
        if (call->ret == DC_SIGCHAR_VOID) XSRETURN_EMPTY;
        RETVAL = sv_2mortal(RETVAL);
        ST(0) = RETVAL;
        XSRETURN(1);
    }
}

XS_INTERNAL(Affix_DESTROY) {
    dVAR;
    dXSARGS;
    Call *call;
    CV *THIS;
    STMT_START {
        HV *st;
        GV *gvp;
        SV *const xsub_tmp_sv = ST(0);
        SvGETMAGIC(xsub_tmp_sv);
        THIS = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
        {
            CV *cv = THIS;
            call = (Call *)XSANY.any_ptr;
        }
    }
    STMT_END;
    if (call == NULL) XSRETURN_EMPTY;
    if (call->lib != NULL) dlFreeLibrary(call->lib);
    if (call->fptr != NULL) call->fptr = NULL;
    SvREFCNT_dec(call->args);
    SvREFCNT_dec(call->retval);
    if (call->sig != NULL) safefree(call->sig);
    if (call->perl_sig != NULL) safefree(call->perl_sig);
    safefree(call);
    call = NULL;
    if (XSANY.any_ptr != NULL) safefree(XSANY.any_ptr);
    XSANY.any_ptr = NULL;
    XSRETURN_EMPTY;
}

#define TYPE(NAME, SIGCHAR, SIGCHAR_C)                                                             \
    {                                                                                              \
        const char *package = form("Affix::Type::%s", #NAME);                                      \
        set_isa(package, "Affix::Type::Base");                                                     \
        cv = newXSproto_portable(form("Affix::%s", #NAME), Types_wrapper, file, ";$");             \
        Newx(XSANY.any_ptr, strlen(package) + 1, char);                                            \
        Copy(package, XSANY.any_ptr, strlen(package) + 1, char);                                   \
        cv = get_cv(form("%s::new", package), 0); /* Allow type constructors to be overridden */   \
        if (cv == NULL) {                                                                          \
            cv = newXSproto_portable(form("%s::new", package), Types /*_#NAME*/, file, "$");       \
            safefree(XSANY.any_ptr);                                                               \
            XSANY.any_i32 = (int)SIGCHAR;                                                          \
        }                                                                                          \
        export_function("Affix", #NAME, "types");                                                  \
        /*warn("Exporting %s to Affix q[:types]", NAME);*/                                         \
        /* Int->sig == 'i'; Struct[Int, Float]->sig == '{if}' */                                   \
        cv = newXSproto_portable(form("%s::sig", package), Types_sig, file, "$");                  \
        XSANY.any_i32 = (int)SIGCHAR;                                                              \
        /* embed an extra character inside a method call to get the 'real' C type*/                \
        cv = newXSproto_portable(form("%s::csig", package), Types_sig, file, "$");                 \
        XSANY.any_i32 = (int)SIGCHAR_C;                                                            \
        /* types objects can stringify to sigchars */                                              \
        cv = newXSproto_portable(form("%s::(\"\"", package), Types_sig, file, ";$");               \
        XSANY.any_i32 = (int)SIGCHAR;                                                              \
        /* The magic for overload gets a GV* via gv_fetchmeth as */                                \
        /* mentioned above, and looks in the SV* slot of it for */                                 \
        /* the "fallback" status. */                                                               \
        sv_setsv(get_sv(form("%s::()", package), TRUE), &PL_sv_yes);                               \
        /* Making a sub named "Affix::Call::Aggregate::()" allows the package */                   \
        /* to be findable via fetchmethod(), and causes */                                         \
        /* overload::Overloaded("Affix::Call::Aggregate") to return true. */                       \
        (void)newXSproto_portable(form("%s::()", package), Types_sig, file, ";$");                 \
    }

#define CLEANUP(NAME)                                                                              \
    cv = get_cv(form("Affix::%s", #NAME), 0);                                                      \
    if (cv != NULL) safefree(XSANY.any_ptr);

// clang-format off

MODULE = Affix PACKAGE = Affix

# Override default typemap

TYPEMAP: <<HERE
DCpointer   T_DCPOINTER

INPUT
T_DCPOINTER
    if (sv_derived_from($arg, \"Affix::Pointer\")){
    IV tmp = SvIV((SV*)SvRV($arg));
    $var = INT2PTR($type, tmp);
  }
  else
    croak(\"$var is not of type Affix::Pointer\");

OUTPUT
T_DCPOINTER
    sv_setref_pv($arg,\"Affix::Pointer\", $var);

HERE

BOOT:
  // clang-format on
#ifdef USE_ITHREADS
    my_perl = (PerlInterpreter *)PERL_GET_CONTEXT;
#endif
{
    MY_CXT_INIT;
    MY_CXT.cvm = dcNewCallVM(4096);
}
{
    (void)newXSproto_portable("Affix::Type", Types_type, file, "$");
    (void)newXSproto_portable("Affix::DESTROY", Affix_DESTROY, file, "$");

    CV *cv;
    TYPE(Void, DC_SIGCHAR_VOID, DC_SIGCHAR_VOID);
    TYPE(Bool, DC_SIGCHAR_BOOL, DC_SIGCHAR_BOOL);
    TYPE(Char, DC_SIGCHAR_CHAR, DC_SIGCHAR_CHAR);
    TYPE(UChar, DC_SIGCHAR_UCHAR, DC_SIGCHAR_UCHAR);
    TYPE(Short, DC_SIGCHAR_SHORT, DC_SIGCHAR_SHORT);
    TYPE(UShort, DC_SIGCHAR_USHORT, DC_SIGCHAR_USHORT);
    TYPE(Int, DC_SIGCHAR_INT, DC_SIGCHAR_INT);
    TYPE(UInt, DC_SIGCHAR_UINT, DC_SIGCHAR_UINT);
    TYPE(Long, DC_SIGCHAR_LONG, DC_SIGCHAR_LONG);
    TYPE(ULong, DC_SIGCHAR_ULONG, DC_SIGCHAR_ULONG);
    TYPE(LongLong, DC_SIGCHAR_LONGLONG, DC_SIGCHAR_LONGLONG);
    TYPE(ULongLong, DC_SIGCHAR_ULONGLONG, DC_SIGCHAR_ULONGLONG);
    TYPE(Float, DC_SIGCHAR_FLOAT, DC_SIGCHAR_FLOAT);
    TYPE(Double, DC_SIGCHAR_DOUBLE, DC_SIGCHAR_DOUBLE);
    TYPE(Pointer, DC_SIGCHAR_POINTER, DC_SIGCHAR_POINTER);
    TYPE(Str, DC_SIGCHAR_STRING, DC_SIGCHAR_STRING);
    TYPE(Struct, DC_SIGCHAR_STRUCT, DC_SIGCHAR_AGGREGATE);
    TYPE(ArrayRef, DC_SIGCHAR_ARRAY, DC_SIGCHAR_AGGREGATE);
    TYPE(Union, DC_SIGCHAR_UNION, DC_SIGCHAR_AGGREGATE);
    TYPE(CodeRef, DC_SIGCHAR_CODE, DC_SIGCHAR_AGGREGATE);
    TYPE(InstanceOf, DC_SIGCHAR_INSTANCEOF, DC_SIGCHAR_POINTER);
    TYPE(Any, DC_SIGCHAR_ANY, DC_SIGCHAR_POINTER);
    TYPE(SSize_t, DC_SIGCHAR_SSIZE_T, DC_SIGCHAR_SSIZE_T);
    TYPE(Size_t, DC_SIGCHAR_SIZE_T, DC_SIGCHAR_SIZE_T);
    TYPE(WStr, DC_SIGCHAR_WIDE_STRING, DC_SIGCHAR_POINTER);

    TYPE(Enum, DC_SIGCHAR_ENUM, DC_SIGCHAR_INT);

    TYPE(IntEnum, DC_SIGCHAR_ENUM, DC_SIGCHAR_INT);
    set_isa("Affix::Type::IntEnum", "Affix::Type::Enum");

    TYPE(UIntEnum, DC_SIGCHAR_ENUM_UINT, DC_SIGCHAR_UINT);
    set_isa("Affix::Type::UIntEnum", "Affix::Type::Enum");

    TYPE(CharEnum, DC_SIGCHAR_ENUM_CHAR, DC_SIGCHAR_CHAR);
    set_isa("Affix::Type::CharEnum", "Affix::Type::Enum");

    TYPE(CC_DEFAULT, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_DEFAULT);
    TYPE(CC_THISCALL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_THISCALL);
    TYPE(CC_ELLIPSIS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ELLIPSIS);
    TYPE(CC_ELLIPSIS_VARARGS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ELLIPSIS_VARARGS);
    TYPE(CC_CDECL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_CDECL);
    TYPE(CC_STDCALL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_STDCALL);
    TYPE(CC_FASTCALL_MS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_FASTCALL_MS);
    TYPE(CC_FASTCALL_GNU, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_FASTCALL_GNU);
    TYPE(CC_THISCALL_MS, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_THISCALL_MS);
    TYPE(CC_THISCALL_GNU, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_THISCALL_GNU);
    TYPE(CC_ARM_ARM, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ARM_ARM);
    TYPE(CC_ARM_THUMB, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_ARM_THUMB);
    TYPE(CC_SYSCALL, DC_SIGCHAR_CC_PREFIX, DC_SIGCHAR_CC_SYSCALL);

    // Enum[]?
    export_function("Affix", "typedef", "types");
    export_function("Affix", "wrap", "default");
    export_function("Affix", "affix", "default");
    export_function("Affix", "MODIFY_CODE_ATTRIBUTES", "default");
    export_function("Affix", "AUTOLOAD", "default");
}
// clang-format off

DLLib *
load_lib(const char * lib_name)
CODE:
{
    // clang-format on
    // Use perl to get the actual path to the library
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 1);
        PUSHs(ST(0));
        PUTBACK;
        count = call_pv("Affix::locate_lib", G_SCALAR);
        SPAGAIN;
        if (count == 1) lib_name = SvPVx_nolen(POPs);
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    RETVAL =
#if defined(_WIN32) || defined(_WIN64)
        dlLoadLibrary(lib_name);
#else
        (DLLib *)dlopen(lib_name, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
    if (RETVAL == NULL) {
#if defined(_WIN32) || defined(__WIN32__)
        unsigned int err = GetLastError();
        croak("Failed to load %s: %d", lib_name, err);
#else
        char *reason = dlerror();
        croak("Failed to load %s: %s", lib_name, reason);
#endif
        XSRETURN_EMPTY;
    }
}
// clang-format off
OUTPUT:
    RETVAL

void
pin(SV *sv, lib, symbol, SV *type);
    const char * symbol
PREINIT:
	struct ufuncs uf;
PPCODE:
// clang-format on
{
    PERL_UNUSED_VAR(sv);
    DLLib *lib;
    if (!SvOK(ST(1)))
        lib = NULL;
    else if (SvROK(ST(1)) && sv_derived_from(ST(1), "Dyn::Load::Lib")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lib = INT2PTR(DLLib *, tmp);
    }
    else {
        char *lib_name = (char *)SvPV_nolen(ST(1));
        // Use perl to get the actual path to the library
        {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(ST(1));
            PUTBACK;
            count = call_pv("Affix::locate_lib", G_SCALAR);
            SPAGAIN;
            if (count == 1) lib_name = SvPVx_nolen(POPs);
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        lib =
#if defined(_WIN32) || defined(_WIN64)
            dlLoadLibrary(lib_name);
#else
            (DLLib *)dlopen(lib_name, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
        if (lib == NULL) {
#if defined(_WIN32) || defined(__WIN32__)
            unsigned int err = GetLastError();
            croak("Failed to load %s: %d", lib_name, err);
#else
            char *reason = dlerror();
            croak("Failed to load %s: %s", lib_name, reason);
#endif
            XSRETURN_EMPTY;
        }
    }
    DCpointer ptr = dlFindSymbol(lib, symbol);
    if (ptr == NULL) { // TODO: throw a warning
        croak("Failed to locate symbol %s", symbol);
    }
    MAGIC *mg;
    mg = sv_magicext(sv, NULL, PERL_MAGIC_ext, &pin_vtbl, NULL, 0);
    {
        var_ptr *_ptr;
        Newx(_ptr, 1, var_ptr);
        _ptr->ptr = ptr;
        _ptr->type = newSVsv(type);
        mg->mg_ptr = (char *)_ptr;
    }
    // magic_dump(mg);
    XSRETURN_YES;
}
// clang-format off

SV *
affix(lib, symbol, args, ret = sv_bless(newRV_inc(MUTABLE_SV(newHV())), gv_stashpv("Affix::Type::Void", GV_ADD)))
    SV * symbol
    AV * args
    SV * ret
ALIAS:
    affix = 0
    wrap  = 1
PREINIT:
    dMY_CXT;
CODE:
// clang-format on
{
    Call *call;
    DLLib *lib;

    if (!SvOK(ST(0)))
        lib = NULL;
    else if (SvROK(ST(0)) && sv_derived_from(ST(0), "Dyn::Load::Lib")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lib = INT2PTR(DLLib *, tmp);
    }
    else {
        char *lib_name = (char *)SvPV_nolen(ST(0));
        // Use perl to get the actual path to the library
        {
            dSP;
            int count;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            EXTEND(SP, 1);
            PUSHs(ST(0));
            PUTBACK;
            count = call_pv("Affix::locate_lib", G_SCALAR);
            SPAGAIN;
            if (count == 1) lib_name = SvPVx_nolen(POPs);
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        lib =
#if defined(_WIN32) || defined(_WIN64)
            dlLoadLibrary(lib_name);
#else
            (DLLib *)dlopen(lib_name, RTLD_LAZY /* RTLD_NOW|RTLD_GLOBAL */);
#endif
        if (lib == NULL) {
#if defined(_WIN32) || defined(__WIN32__)
            unsigned int err = GetLastError();
            croak("Failed to load %s: %d", lib_name, err);
#else
            char *reason = dlerror();
            croak("Failed to load %s: %s", lib_name, reason);
#endif
            XSRETURN_EMPTY;
        }
    }
    Newx(call, 1, Call);

    const char *symbol_, *func_name;
    if (SvROK(symbol) && SvTYPE(SvRV(symbol)) == SVt_PVAV) {
        SV *symbol__ = av_shift(MUTABLE_AV(SvRV(symbol)));
        if (!SvOK(symbol__)) croak("Expected a symbol name");
        symbol_ = SvPV_nolen(symbol__);
        SV *func_name__ = av_shift(MUTABLE_AV(SvRV(symbol)));
        if (SvOK(func_name__))
            func_name = SvPV_nolen(func_name__);
        else
            func_name = symbol_;
    }
    else { symbol_ = func_name = SvPV_nolen(symbol); }

    call->fptr = dlFindSymbol(lib, symbol_);
    size_t args_len = av_count(args);

    if (call->fptr == NULL) { // TODO: throw a warning
        safefree(call);
        croak("Failed to locate symbol %s", symbol_);
    }

    call->lib = lib;
    call->reset = true;
    call->retval = SvREFCNT_inc(ret);
    Newxz(call->sig, args_len * 2, char);
    Newxz(call->perl_sig, args_len, char);

    char c_sig[args_len];
    call->args = newAV();
    size_t perl_sig_pos = 0;
    size_t c_sig_pos = 0;
    call->sig_len = 0;
    for (int i = 0; i < args_len; ++i) {
        SV **type_ref = av_fetch(args, i, 0);
        if (!(sv_isobject(*type_ref) && sv_derived_from(*type_ref, "Affix::Type::Base")))
            croak("Given type for arg %d is not a subclass of Affix::Type::Base", i);
        av_push(call->args, SvREFCNT_inc(*type_ref));
        char *str = SvPVbytex_nolen(*type_ref);
        call->sig[c_sig_pos++] = str[0];
        switch (str[0]) {
        case DC_SIGCHAR_CODE:
            call->perl_sig[perl_sig_pos] = '&';
            break;
        case DC_SIGCHAR_ARRAY:
            call->perl_sig[perl_sig_pos++] = '\\';
            call->perl_sig[perl_sig_pos] = '@';
            break;
        case DC_SIGCHAR_STRUCT:
            call->perl_sig[perl_sig_pos++] = '\\';
            call->perl_sig[perl_sig_pos] = '%'; // TODO: Get actual type
            break;
        case DC_SIGCHAR_CC_PREFIX: { // Don't add to perl sig or inc arg count
            char cc[1];
            {
                dSP;
                int count;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                EXTEND(SP, 1);
                PUSHs(*type_ref);
                PUTBACK;
                count = call_method("csig", G_SCALAR);
                SPAGAIN;
                if (count == 1) Copy(POPp, cc, 1, char);
                PUTBACK;
                FREETMPS;
                LEAVE;
            }
            call->sig[c_sig_pos++] = cc[0];
            if (i == 0 &&
                !(cc[0] != DC_SIGCHAR_CC_ELLIPSIS || cc[0] != DC_SIGCHAR_CC_ELLIPSIS_VARARGS)) {
                call->reset = false;
            }
        }
            continue;
        default:
            call->perl_sig[perl_sig_pos] = '$';
            break;
        }
        ++call->sig_len;
        ++perl_sig_pos;
    }
    {
        char *str = SvPVbytex_nolen(ret);
        call->ret = str[0];
    }
    // if (call == NULL) croak("Failed to affix %s", symbol);
    /* Create a new XSUB instance at runtime and set it's XSANY.any_ptr to contain
     *the necessary user data. name can be NULL => fully anonymous sub!
     **/

    CV *cv;
    STMT_START {
        cv = newXSproto_portable((ix == 0 ? func_name : NULL), Affix_call, file, call->perl_sig);
        if (cv == NULL) croak("ARG! Something went really wrong while installing a new XSUB!");
        XSANY.any_ptr = (DCpointer)call;
    }
    STMT_END;
    RETVAL = sv_bless((ix == 1 ? newRV_noinc(MUTABLE_SV(cv)) : newRV_inc(MUTABLE_SV(cv))),
                      gv_stashpv("Affix", GV_ADD));
}
// clang-format off
OUTPUT:
    RETVAL

void
typedef(char * name, SV * type)
CODE:
// clang-format on
{
    {
        CV *cv = newXSproto_portable(name, Types_return_typedef, __FILE__, "");
        XSANY.any_sv = SvREFCNT_inc(newSVsv(type));
    }

    if (sv_isobject(type)) {
        if (sv_derived_from(type, "Affix::Type::Enum")) {
            HV *href = MUTABLE_HV(SvRV(type));
            SV **values_ref = hv_fetch(href, "values", 6, 0);
            AV *values = MUTABLE_AV(SvRV(*values_ref));
            HV *_stash = gv_stashpv(name, TRUE);
            for (int i = 0; i < av_count(values); i++) {
                SV **value = av_fetch(MUTABLE_AV(values), i, 0);
                register_constant(name, SvPV_nolen(*value), *value);
            }
        }
    }
    else
        croak("Expected a subclass of Affix::Type::Base");
}
// clang-format off

void
CLONE(...)
CODE :
    MY_CXT_CLONE;

void
sv_dump(SV * sv)
CODE :
    sv_dump(sv);

DCpointer
sv2ptr( SV * data, SV * type)
CODE:
    RETVAL = safemalloc(_sizeof(aTHX_ type));
    sv2ptr(aTHX_ type, data, RETVAL, false);
OUTPUT:
    RETVAL

SV *
ptr2sv(DCpointer ptr, SV * type)
CODE:
    RETVAL = ptr2sv(aTHX_ ptr, type);
OUTPUT:
    RETVAL

void
DumpHex(DCpointer ptr, size_t size)
CODE:
    DumpHex(ptr, size);

BOOT :
// clang-format on
{
    export_function("Affix", "sv2ptr", "utility");
    export_function("Affix", "ptr2sv", "utility");
    export_function("Affix", "DumpHex", "utility");
    export_function("Affix", "pin", "default");
    export_function("Affix", "cast", "default");

    export_function("Affix", "DEFAULT_ALIGNMENT", "vars");
    export_constant("Affix", "ALIGNBYTES", "all", AFFIX_ALIGNBYTES);
    export_constant("Affix::Feature", "Syscall", "feature",
#ifdef DC__Feature_Syscall
                    1
#else
                    0
#endif
    );
    export_constant("Affix::Feature", "AggrByVal", "feature",
#ifdef DC__Feature_AggrByVal
                    1
#else
                    0
#endif
    );
}
// clang-format off

void
_shutdown()
INIT:
    dMY_CXT;
CODE:
// clang-format on
{
    dcFree(MY_CXT.cvm);
    CV *cv;
    CLEANUP(Void);
    CLEANUP(Bool);
    CLEANUP(Char);
    CLEANUP(UChar);
    CLEANUP(Short);
    CLEANUP(UShort);
    CLEANUP(Int);
    CLEANUP(UInt);
    CLEANUP(Long);
    CLEANUP(ULong);
    CLEANUP(LongLong);
    CLEANUP(ULongLong);
    CLEANUP(Float);
    CLEANUP(Double);
    CLEANUP(Pointer);
    CLEANUP(Str);
    CLEANUP(Aggregate);
    CLEANUP(Struct);
    CLEANUP(ArrayRef);
    CLEANUP(Union);
    CLEANUP(CodeRef);
    CLEANUP(InstanceOf);
    CLEANUP(Any);
    CLEANUP(SSize_t);
    CLEANUP(Size_t);
    CLEANUP(WStr);
    CLEANUP(Enum);
    CLEANUP(IntEnum);
    CLEANUP(UIntEnum);
    CLEANUP(CharEnum);
    CLEANUP(CC_DEFAULT);
    CLEANUP(CC_THISCALL);
    CLEANUP(CC_ELLIPSIS);
    CLEANUP(CC_ELLIPSIS_VARARGS);
    CLEANUP(CC_CDECL);
    CLEANUP(CC_STDCALL);
    CLEANUP(CC_FASTCALL_MS);
    CLEANUP(CC_FASTCALL_GNU);
    CLEANUP(CC_THISCALL_MS);
    CLEANUP(CC_THISCALL_GNU);
    CLEANUP(CC_ARM_ARM);
    CLEANUP(CC_ARM_THUMB);
    CLEANUP(CC_SYSCALL);
    }
// clang-format off

size_t
sizeof(SV * type)
CODE:
    RETVAL = _sizeof(aTHX_ type);
OUTPUT:
    RETVAL

size_t
offsetof(SV * type, char * field)
CODE:
  // clang-format on
  {
    if (sv_isobject(type) && (sv_derived_from(type, "Affix::Type::Struct"))) {
        HV *href = MUTABLE_HV(SvRV(type));
        SV **fields_ref = hv_fetch(href, "fields", 6, 0);
        AV *fields = MUTABLE_AV(SvRV(*fields_ref));
        size_t field_count = av_count(fields);
        for (size_t i = 0; i < field_count; ++i) {
            AV *av_field = MUTABLE_AV(SvRV(*av_fetch(fields, i, 0)));
            SV *sv_field = *av_fetch(av_field, 0, 0);
            char *this_field = SvPV_nolen(sv_field);
            if (!strcmp(this_field, field)) {
                RETVAL = _offsetof(aTHX_ * av_fetch(av_field, 1, 0));
                break;
            }
            if (i == field_count) croak("Given structure does not contain field named '%s'", field);
        }
    }
    else
        croak("Given type is not a structure");
}
    // clang-format off
OUTPUT:
    RETVAL

DCpointer
malloc(size_t size)
CODE:
// clang-format on
{
    RETVAL = safemalloc(size);
    if (RETVAL == NULL) XSRETURN_EMPTY;
}
// clang-format off
OUTPUT:
RETVAL

DCpointer
calloc(size_t num, size_t size)
CODE:
// clang-format off
    {RETVAL = safecalloc(num, size);
    if (RETVAL == NULL) XSRETURN_EMPTY;}
// clang-format off
OUTPUT:
    RETVAL

DCpointer
realloc(IN_OUT DCpointer ptr, size_t size)
CODE:
    ptr = saferealloc(ptr, size);
OUTPUT:
    RETVAL

void
free(DCpointer ptr)
PPCODE:
// clang-format on
{
    if (ptr) {
        safefree(ptr);
        ptr = NULL;
    }
    sv_set_undef(ST(0));
} // Let Affix::Pointer::DESTROY take care of the rest
  // clang-format off

DCpointer
memchr(DCpointer ptr, char ch, size_t count)

int
memcmp(lhs, rhs, size_t count)
INIT:
    DCpointer lhs, rhs;
CODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        lhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        lhs = INT2PTR(DCpointer, tmp);
    }
    else
        croak("ptr is not of type Affix::Pointer");
    if (sv_derived_from(ST(1), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        rhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        rhs = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { rhs = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Affix::Pointer");
    RETVAL = memcmp(lhs, rhs, count);
}
// clang-format off
OUTPUT:
    RETVAL

DCpointer
memset(DCpointer dest, char ch, size_t count)

void
memcpy(dest, src, size_t nitems)
INIT:
    DCpointer dest, src;
PPCODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Affix::Pointer");
    if (sv_derived_from(ST(1), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { src = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Affix::Pointer");
    CopyD(src, dest, nitems, char);
}
// clang-format off

void
memmove(dest, src, size_t nitems)
INIT:
    DCpointer dest, src;
PPCODE:
// clang-format on
{
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        dest = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Affix::Pointer");
    if (sv_derived_from(ST(1), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(1))) {
        IV tmp = SvIV((SV *)(ST(1)));
        src = INT2PTR(DCpointer, tmp);
    }
    else if (SvPOK(ST(1))) { src = (DCpointer)(unsigned char *)SvPV_nolen(ST(1)); }
    else
        croak("dest is not of type Affix::Pointer");
    Move(src, dest, nitems, char);
}
// clang-format off

DCpointer
strdup(char * str1)

BOOT:
// clang-format on
{
    export_function("Affix", "offsetof", "default");
    export_function("Affix", "sizeof", "default");
    export_function("Affix", "malloc", "memory");
    export_function("Affix", "calloc", "memory");
    export_function("Affix", "realloc", "memory");
    export_function("Affix", "free", "memory");
    export_function("Affix", "memchr", "memory");
    export_function("Affix", "memcmp", "memory");
    export_function("Affix", "memset", "memory");
    export_function("Affix", "memcpy", "memory");
    export_function("Affix", "memmove", "memory");
    export_function("Affix", "strdup", "memory");
    set_isa("Affix::Pointer", "Dyn::Call::Pointer");
}
// clang-format off

MODULE = Affix PACKAGE = Affix::Pointer

FALLBACK: TRUE

IV
plus(DCpointer ptr, IV other, IV swap)
OVERLOAD: +
CODE:
    // clang-format on
    RETVAL = PTR2IV(ptr) + other;
// clang-format off
OUTPUT:
    RETVAL

IV
minus(DCpointer ptr, IV other, IV swap)
OVERLOAD: -
CODE:
    // clang-format on
    RETVAL = PTR2IV(ptr) - other;
// clang-format off
OUTPUT:
    RETVAL

char *
as_string(DCpointer ptr, ...)
OVERLOAD: \"\"
CODE:
    // clang-format on
    RETVAL = (char *)ptr;
// clang-format off
OUTPUT:
    RETVAL

SV *
raw(ptr, size_t size, bool utf8 = false)
CODE:
// clang-format on
{
    DCpointer ptr;
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Affix::Pointer");
    RETVAL = newSVpvn_utf8((const char *)ptr, size, utf8 ? 1 : 0);
}
// clang-format off
OUTPUT:
    RETVAL

void
dump(ptr, size_t size)
CODE:
// clang-format on
{
    DCpointer ptr;
    if (sv_derived_from(ST(0), "Affix::Pointer")) {
        IV tmp = SvIV((SV *)SvRV(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else if (SvIOK(ST(0))) {
        IV tmp = SvIV((SV *)(ST(0)));
        ptr = INT2PTR(DCpointer, tmp);
    }
    else
        croak("dest is not of type Affix::Pointer");
}
  //clang-format off

#if 0
void
DESTROY(HV * me)
CODE:
// clang-format on
{
    SV **ptr_ptr = hv_fetchs(me, "pointer", 0);
    if (!ptr_ptr) return;
    DCpointer ptr;
    IV tmp = SvIV((SV *)SvRV(*ptr_ptr));
    ptr = INT2PTR(DCpointer, tmp);
    if (ptr) safefree(ptr);
    ptr = NULL;
}
// clang-format off

#endif
