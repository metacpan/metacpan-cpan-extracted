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

//#include "ppport.h"

#ifndef av_count
#define av_count(av) (AvFILL(av) + 1)
#endif

#ifndef aTHX_
#define aTHX_ aTHX,
#endif

#if defined(_WIN32) || defined(_WIN64)
// Handle special Windows stuff
#else
#include <dlfcn.h>
#endif

#include <dyncall.h>
#include <dyncall_callback.h>
#include <dynload.h>

#include <dyncall_value.h>
#include <dyncall_callf.h>

#include <dyncall_signature.h>

#include <dyncall/dyncall/dyncall_aggregate.h>

//{ii[5]Z&<iZ>}
#define DC_SIGCHAR_CODE '&'      // 'p' but allows us to wrap CV * for the user
#define DC_SIGCHAR_ARRAY '['     // 'A' but nicer
#define DC_SIGCHAR_STRUCT '{'    // 'A' but nicer
#define DC_SIGCHAR_UNION '<'     // 'A' but nicer
#define DC_SIGCHAR_BLESSED '$'   // 'p' but an object or subclass of a given package
#define DC_SIGCHAR_ANY '*'       // 'p' but it's really an SV/HV/AV
#define DC_SIGCHAR_ENUM 'e'      // 'i' but with multiple options
#define DC_SIGCHAR_ENUM_UINT 'E' // 'I' but with multiple options
#define DC_SIGCHAR_ENUM_CHAR 'o' // 'c' but with multiple options

#if Size_t_size == INTSIZE
#define DC_SIGCHAR_SSIZE_T DC_SIGCHAR_INT
#define DC_SIGCHAR_SIZE_T DC_SIGCHAR_UINT
#elsif Size_t_size == LONGSIZE
#define DC_SIGCHAR_SSIZE_T DC_SIGCHAR_LONG
#define DC_SIGCHAR_SIZE_T DC_SIGCHAR_ULONG
#else
#define DC_SIGCHAR_SSIZE_T DC_SIGCHAR_LONGLONG
#define DC_SIGCHAR_SIZE_T DC_SIGCHAR_ULONGLONG
#endif

// bring balance
#define DC_SIGCHAR_ARRAY_END ']'
#define DC_SIGCHAR_STRUCT_END '}'
#define DC_SIGCHAR_UNION_END '>'

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

#define DECL_BOOT(name) EXTERN_C XS(CAT2(boot_, name))
#define CALL_BOOT(name)                                                                            \
    STMT_START {                                                                                   \
        PUSHMARK(SP);                                                                              \
        CALL_FPTR(CAT2(boot_, name))(aTHX_ cv);                                                    \
    }                                                                                              \
    STMT_END

/* Useful but undefined in perlapi */
#define FLOATSIZE sizeof(float)
#define BOOLSIZE sizeof(bool) // ha!

const char *file = __FILE__;

/* api wrapping utils */

#define MY_CXT_KEY "Dyn::_guts" XS_VERSION

typedef struct
{
    DCCallVM *cvm;
} my_cxt_t;

START_MY_CXT

// http://www.catb.org/esr/structure-packing/#_structure_alignment_and_padding
/* Returns the amount of padding needed after `offset` to ensure that the
following address will be aligned to `alignment`. */
size_t padding_needed_for(size_t offset, size_t alignment) {
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
    _DumpHex(addr, len, __FILE__, __LINE__)

void _DumpHex(const void *addr, size_t len, const char *file, int line) {
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

SV *enum2sv(SV *type, int in) {
    dTHX;
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

const char *ordinal(int n) {
    static const char suffixes[][3] = {"th", "st", "nd", "rd"};
    int ord = n % 100;
    if (ord / 10 == 1) { ord = 0; }
    ord = ord % 10;
    if (ord > 3) { ord = 0; }
    return suffixes[ord];
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

static size_t _sizeof(pTHX_ SV *type) {
    // sv_dump(type);
    char *str = SvPVbytex_nolen(type); // stringify to sigchar; speed cheat vs sv_derived_from(...)
    // warn("str == %s", str);
    switch (str[0]) {
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
        return DOUBLESIZE;
    case DC_SIGCHAR_STRUCT: {
        if (hv_exists(MUTABLE_HV(SvRV(type)), "sizeof", 6))
            return SvIV(*hv_fetchs(MUTABLE_HV(SvRV(type)), "sizeof", 0));
        SV **idk_wtf = hv_fetchs(MUTABLE_HV(SvRV(type)), "fields", 0);
        SV **sv_packed = hv_fetchs(MUTABLE_HV(SvRV(type)), "packed", 0);
        bool packed = SvTRUE(*sv_packed);
        AV *idk_arr = MUTABLE_AV(SvRV(*idk_wtf));
        int field_count = av_count(idk_arr);
        size_t size = 0;
        for (int i = 0; i < field_count; ++i) {
            SV **type_ptr = av_fetch(MUTABLE_AV(*av_fetch(idk_arr, i, 0)), 1, 0);
            size_t __sizeof = _sizeof(aTHX_ * type_ptr);
            size += packed ? 0
                           : padding_needed_for(size, MEM_ALIGNBYTES > __sizeof ? __sizeof
                                                                                : MEM_ALIGNBYTES);

            size += __sizeof;
            /*warn("alignto(%d, %d)            == %d", size, __sizeof, alignto(size, __sizeof));
            warn("aligntonext(%d, %d)        == %d", size, __sizeof, aligntonext(size, __sizeof));
            warn("padding_needed_for(%d, %d) == %d", size, __sizeof,
                 padding_needed_for(size, __sizeof));*/
            hv_stores(MUTABLE_HV(SvRV(*type_ptr)), "offset", newSViv(size - __sizeof));
            // warn("[%d] size                    == %d", i, size);
        }
        if (!packed && size > MEM_ALIGNBYTES * 2) size += padding_needed_for(size, MEM_ALIGNBYTES);
        hv_stores(MUTABLE_HV(SvRV(type)), "sizeof", newSViv(size));
        return size;
    }
    case DC_SIGCHAR_ARRAY: {
        if (hv_exists(MUTABLE_HV(SvRV(type)), "sizeof", 6))
            return SvIV(*hv_fetchs(MUTABLE_HV(SvRV(type)), "sizeof", 0));
        SV **type_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "type", 0);
        SV **size_ptr = hv_fetchs(MUTABLE_HV(SvRV(type)), "size", 0);
        SV **sv_packed = hv_fetchs(MUTABLE_HV(SvRV(type)), "packed", 0);
        bool packed = SvTRUE(*sv_packed);
        size_t size = 0, offset = 0;
        size_t field_count = SvIV(*size_ptr);
        size_t __sizeof = _sizeof(aTHX_ * type_ptr);
        for (int i = 0; i < field_count; ++i) {
            // size += packed ? 0 : padding_needed_for(size, __sizeof);

            // hv_stores(MUTABLE_HV(SvRV(*type_ptr)), "offset", newSViv(offset + padding));
            size += __sizeof;
            offset = size;
        }
        hv_stores(MUTABLE_HV(SvRV(type)), "sizeof", newSViv(size));
        return size;
    }
    case DC_SIGCHAR_UNION: {
        if (hv_exists(MUTABLE_HV(SvRV(type)), "sizeof", 6))
            return SvIV(*hv_fetchs(MUTABLE_HV(SvRV(type)), "sizeof", 0));
        SV **idk_wtf = hv_fetchs(MUTABLE_HV(SvRV(type)), "fields", 0);
        SV **sv_packed = hv_fetchs(MUTABLE_HV(SvRV(type)), "packed", 0);
        bool packed = SvTRUE(*sv_packed);
        AV *idk_arr = MUTABLE_AV(SvRV(*idk_wtf));
        int field_count = av_count(idk_arr);
        size_t size = 0;
        for (int i = 0; i < field_count; ++i) {
            SV **type_ptr = av_fetch(MUTABLE_AV(*av_fetch(idk_arr, i, 0)), 1, 0);
            hv_stores(MUTABLE_HV(SvRV(*type_ptr)), "offset", newSViv(0));
            size_t __sizeof = _sizeof(aTHX_ * type_ptr);
            if (size < __sizeof) size = __sizeof;
            if (!packed && field_count > 1 && __sizeof > MEM_ALIGNBYTES)
                size += padding_needed_for(__sizeof, MEM_ALIGNBYTES);
        }

        hv_stores(MUTABLE_HV(SvRV(type)), "sizeof", newSViv(size));
        return size;
    }
    case DC_SIGCHAR_CODE: // automatically wrapped in a DCCallback pointer
    case DC_SIGCHAR_POINTER:
    case DC_SIGCHAR_STRING:
    case DC_SIGCHAR_BLESSED:
        return PTRSIZE;
    case DC_SIGCHAR_ANY:
        return sizeof(SV);
    default:
        croak("Failed to gather sizeof info for unknown type: %s", str);
        return -1;
    }
}

static DCaggr *_aggregate(pTHX_ SV *type) {
    // warn("here at %s line %d", __FILE__, __LINE__);
    // sv_dump(type);

    char *str = SvPVbytex_nolen(type); // stringify to sigchar; speed cheat vs sv_derived_from(...)
                                       // warn("here at %s line %d", __FILE__, __LINE__);

    size_t size = _sizeof(aTHX_ type);
    // warn("here at %s line %d", __FILE__, __LINE__);

    switch (str[0]) {
    case DC_SIGCHAR_STRUCT:
    case DC_SIGCHAR_UNION: {
        // warn("here at %s line %d", __FILE__, __LINE__);

        if (hv_exists(MUTABLE_HV(SvRV(type)), "aggregate", 9)) {
            SV *__type = *hv_fetchs(MUTABLE_HV(SvRV(type)), "aggregate", 0);
            // warn("here at %s line %d", __FILE__, __LINE__);
            // sv_dump(__type);

            // return SvIV(*hv_fetchs(MUTABLE_HV(SvRV(type)), "aggregate", 0));
            if (sv_derived_from(__type, "Dyn::Call::Aggregate")) {
                // warn("here at %s line %d", __FILE__, __LINE__);

                HV *hv_ptr = MUTABLE_HV(__type);
                // warn("here at %s line %d", __FILE__, __LINE__);

                IV tmp = SvIV((SV *)SvRV(__type));
                // warn("here at %s line %d", __FILE__, __LINE__);

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
            // warn("DCaggr *agg = dcNewAggr(%d, %d); at %s line %d", field_count, size, __FILE__,
            //     __LINE__);
            DCaggr *agg = dcNewAggr(field_count, size);
            for (int i = 0; i < field_count; ++i) {
                SV **type_ptr = av_fetch(MUTABLE_AV(*av_fetch(idk_arr, i, 0)), 1, 0);
                size_t __sizeof = _sizeof(aTHX_ * type_ptr);
                size_t offset = SvIV(*hv_fetchs(MUTABLE_HV(SvRV(*type_ptr)), "offset", 0));
                char *str = SvPVbytex_nolen(*type_ptr);
                switch (str[0]) {
                case DC_SIGCHAR_AGGREGATE:
                case DC_SIGCHAR_STRUCT:
                case DC_SIGCHAR_UNION: {
                    DCaggr *child = _aggregate(aTHX_ * type_ptr);
                    dcAggrField(agg, DC_SIGCHAR_AGGREGATE, offset, 1, child);
                } break;
                case DC_SIGCHAR_ARRAY: {
                    // sv_dump(*type_ptr);
                    SV *type = *hv_fetchs(MUTABLE_HV(SvRV(*type_ptr)), "type", 0);
                    int array_len = SvIV(*hv_fetchs(MUTABLE_HV(SvRV(*type_ptr)), "size", 0));
                    char *str = SvPVbytex_nolen(type);
                    dcAggrField(agg, str[0], offset, array_len);
                    /*warn("dcAggrField(agg, %c, %zd, %d); at %s line %d", str[0], offset,
                       array_len,
                         __FILE__, __LINE__);*/
                } break;
                default: {
                    dcAggrField(agg, str[0], offset, 1);
                    // warn("dcAggrField(agg, %c, %d, 1); at %s line %d", str[0], offset, __FILE__,
                    //     __LINE__);
                } break;
                }
            }
            // warn("here at %s line %d", __FILE__, __LINE__);

            // warn("dcCloseAggr(agg); at %s line %d", __FILE__, __LINE__);
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

SV *agg2sv(pTHX_ DCaggr *agg, SV *type, DCpointer data, size_t size);

SV *ptr2sv(pTHX_ DCpointer ptr, SV *type) {
    // warn("here at %s line %d", __FILE__, __LINE__);
    SV *RETVAL = newSV(0);
    SV *subtype;
    if (sv_derived_from(type, "Affix::Type::Pointer"))
        subtype = *hv_fetchs(MUTABLE_HV(SvRV(type)), "type", 0);
    else
        subtype = type;
    char *_subtype = SvPV_nolen(subtype);
    switch (_subtype[0]) {
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
        sv_setiv(RETVAL, *(long long *)ptr);
        break;
    case DC_SIGCHAR_ULONGLONG:
        sv_setuv(RETVAL, *(unsigned long long *)ptr);
        break;
    case DC_SIGCHAR_FLOAT:
        sv_setnv(RETVAL, *(float *)ptr);
        break;
    case DC_SIGCHAR_DOUBLE:
        sv_setnv(RETVAL, *(double *)ptr);
        break;
    case DC_SIGCHAR_STRING:
        sv_setsv(RETVAL, newSVpv(*(char **)ptr, 0));
        break;
    case DC_SIGCHAR_ARRAY:
    case DC_SIGCHAR_STRUCT:
    case DC_SIGCHAR_UNION: {
        DCaggr *agg = _aggregate(aTHX_ subtype);
        size_t si = _sizeof(aTHX_ subtype);
        RETVAL = agg2sv(aTHX_ agg, SvRV(subtype), ptr, si);
    } break;
    case DC_SIGCHAR_POINTER: {
        if (_subtype[0] == DC_SIGCHAR_VOID) {
            SV *RETVALSV = newSV(0); // sv_newmortal();
            RETVAL = sv_setref_pv(RETVALSV, "Dyn::Call::Pointer", ptr);
        }
        else {
            // DumpHex(aTHX_ ptr, _sizeof(subtype));
            RETVAL = ptr2sv(aTHX_ ptr, subtype);
        }
    } break;
    default:
        croak("Oh, this is unexpected: %c", _subtype[0]);
    }
    return RETVAL;
}

SV *agg2sv(pTHX_ DCaggr *agg, SV *type, DCpointer data, size_t size) {
    // sv_dump(aTHX_ type);
    //  sv_dump(aTHX_ SvRV(*hv_fetch(MUTABLE_HV(sv), "fields", 6, 0)));
    //  DumpHex(data, size);
    AV *fields = MUTABLE_AV(SvRV(*hv_fetch(MUTABLE_HV(type), "fields", 6, 0)));
    HV *RETVAL = newHV();
    intptr_t offset;
    DCsize i = agg->n_fields;
    // warn("agg->n_fields == %d", i);
    DCpointer me = safemalloc(0);
    for (int i = 0; i < agg->n_fields; ++i) {
        // warn("i==%d type==%c", i, agg->fields[i].type);
        SV **field = av_fetch(fields, i, 0);
        SV **name_ptr = av_fetch(MUTABLE_AV(*field), 0, 0);
        SV **value_ptr = av_fetch(MUTABLE_AV(*field), 1, 0);

        // sv_dump(*name_ptr);
        offset = PTR2IV(data) + agg->fields[i].offset;
        /*
                warn("field offset: %ld at %s line %d", agg->fields[i].offset, __FILE__, __LINE__);
                warn("field size: %ld at %s line %d", agg->fields[i].size, __FILE__, __LINE__);
                warn("field alignment: %ld at %s line %d", agg->fields[i].alignment, __FILE__,
           __LINE__); warn("field array_len: %ld at %s line %d", agg->fields[i].array_len, __FILE__,
           __LINE__); warn("field type: %c at %s line %d", agg->fields[i].type, __FILE__, __LINE__);
        */
        // 	DCsize offset, size, alignment, array_len;
        me = saferealloc(me, agg->fields[i].size * agg->fields[i].array_len);

        // sv_dump(*field);

        switch (agg->fields[i].type) {
        case DC_SIGCHAR_BOOL:
            Copy(offset, me, agg->fields[i].array_len, bool);
            hv_store_ent(RETVAL, *name_ptr, boolSV(*(bool *)me), 0);
            break;
        case DC_SIGCHAR_CHAR:
            Copy(offset, me, agg->fields[i].array_len, char);
            if (agg->fields[i].array_len == 1)
                hv_store_ent(RETVAL, *name_ptr, newSViv(*(char *)me), 0);
            else
                hv_store_ent(RETVAL, *name_ptr, newSVpv((char *)me, agg->fields[i].array_len), 0);
            break;
        case DC_SIGCHAR_UCHAR:
            Copy(offset, me, agg->fields[i].array_len, unsigned char);
            if (agg->fields[i].array_len == 1)
                hv_store_ent(RETVAL, *name_ptr, newSVuv(*(unsigned char *)me), 0);
            else
                hv_store_ent(RETVAL, *name_ptr,
                             newSVpv((char *)(unsigned char *)me, agg->fields[i].array_len), 0);
            break;
        case DC_SIGCHAR_SHORT:
            Copy(offset, me, agg->fields[i].array_len, short);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(short *)me), 0);
            break;
        case DC_SIGCHAR_USHORT:
            Copy(offset, me, agg->fields[i].array_len, unsigned short);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(unsigned short *)me), 0);
            break;
        case DC_SIGCHAR_INT:
            Copy(offset, me, agg->fields[i].array_len, int);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(int *)me), 0);
            break;
        case DC_SIGCHAR_UINT:
            Copy(offset, me, agg->fields[i].array_len, int);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(int *)me), 0);
            break;
        case DC_SIGCHAR_LONG:
            Copy(offset, me, agg->fields[i].array_len, long);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(long *)me), 0);
            break;
        case DC_SIGCHAR_ULONG:
            Copy(offset, me, agg->fields[i].array_len, unsigned long);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(unsigned long *)me), 0);
            break;
        case DC_SIGCHAR_LONGLONG:
            Copy(offset, me, agg->fields[i].array_len, long long);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(long long *)me), 0);
            break;
        case DC_SIGCHAR_ULONGLONG:
            Copy(offset, me, agg->fields[i].array_len, unsigned long long);
            hv_store_ent(RETVAL, *name_ptr, newSViv(*(unsigned long long *)me), 0);
            break;
        case DC_SIGCHAR_FLOAT:
            Copy(offset, me, agg->fields[i].array_len, float);
            hv_store_ent(RETVAL, *name_ptr, newSVnv(*(float *)me), 0);
            break;
        case DC_SIGCHAR_DOUBLE:
            Copy(offset, me, agg->fields[i].array_len, double);
            hv_store_ent(RETVAL, *name_ptr, newSVnv(*(double *)me), 0);
            break;
        case DC_SIGCHAR_POINTER: {
            Copy(offset, me, agg->fields[i].array_len, void *);
            SV *RETVALSV = newSV(0); // sv_newmortal();
            sv_setref_pv(RETVALSV, "Dyn::Call::Pointer", me);
            hv_store_ent(RETVAL, *name_ptr, RETVALSV, 0);
        } break;
        case DC_SIGCHAR_STRING: {
            Copy(offset, me, agg->fields[i].array_len, void *);
            if (me != NULL)
                hv_store_ent(RETVAL, *name_ptr, newSVpv(*(char **)me, 0), 0);
            else
                hv_store_ent(RETVAL, *name_ptr, &PL_sv_undef, 0);
        } break;
        case DC_SIGCHAR_AGGREGATE: {
            SV **type_ptr = av_fetch(MUTABLE_AV(*field), 1, 0);
            Copy(offset, me, agg->fields[i].size * agg->fields[i].array_len, char);
            SV *kid = agg2sv(aTHX_(DCaggr *) agg->fields[i].sub_aggr, SvRV(*type_ptr), me,
                             agg->fields[i].size * agg->fields[i].array_len);
            hv_store_ent(RETVAL, *name_ptr, kid, 0);
        } break;
        case DC_SIGCHAR_ENUM: {
            Copy(offset, me, agg->fields[i].array_len, int);
            hv_store_ent(RETVAL, *name_ptr, enum2sv(*value_ptr, *(int *)me), 0);
            break;
        }
        case DC_SIGCHAR_ENUM_UINT: {
            Copy(offset, me, agg->fields[i].array_len, unsigned int);
            hv_store_ent(RETVAL, *name_ptr, enum2sv(*value_ptr, *(unsigned int *)me), 0);
            break;
        }
        case DC_SIGCHAR_ENUM_CHAR: {
            Copy(offset, me, agg->fields[i].array_len, char);
            hv_store_ent(RETVAL, *name_ptr, enum2sv(*value_ptr, *(char *)me), 0);
            break;
        }
        default:
            warn("TODO: %c", agg->fields[i].type);
            hv_store_ent(RETVAL, *name_ptr,
                         newSVpv(form("Unhandled type: %c", agg->fields[i].type), 0), 0);
            break;
        }
    }

    safefree(me);

    {
        SV *RETVALSV;
        RETVALSV = newRV((SV *)RETVAL);
        // RETVALSV = sv_2mortal(RETVALSV);
        return RETVALSV;
    }
}

static DCaggr *sv2ptr(pTHX_ SV *type, SV *data, DCpointer ptr, bool packed, size_t pos) {
    // warn("pos == %p", pos);
    // sv_dump(type);
    char *str = SvPVbytex_nolen(type);
    // warn("[c] type: %s, offset: %d at %s line %d", str, pos, __FILE__, __LINE__);
    switch (str[0]) {
    case DC_SIGCHAR_VOID: {
        if (sv_derived_from(data, "Dyn::Call::Pointer")) {
            IV tmp = SvIV((SV *)SvRV(data));
            DCpointer ptr = INT2PTR(DCpointer, tmp);
            Copy((DCpointer)(&data), ptr, 1, intptr_t);
        }
        else
            croak("Expected a subclass of Dyn::Call::Pointer");
    } break;
    case DC_SIGCHAR_STRUCT: {
        DCaggr *retval = _aggregate(aTHX_ type);
        if (sv_derived_from(data, "Dyn::Call::Pointer")) {
            IV tmp = SvIV((SV *)SvRV(data));
            DCpointer ptr = INT2PTR(DCpointer, tmp);
            Copy((DCpointer)(&ptr), ptr, 1, intptr_t);
        }
        else {
            if (SvTYPE(SvRV(data)) != SVt_PVHV) croak("Expected a hash reference");
            size_t size = _sizeof(aTHX_ type);
            HV *hv_type = MUTABLE_HV(SvRV(type));
            HV *hv_data = MUTABLE_HV(SvRV(data));
            SV **sv_fields = hv_fetchs(hv_type, "fields", 0);
            SV **sv_packed = hv_fetchs(hv_type, "packed", 0);
            AV *av_fields = MUTABLE_AV(SvRV(*sv_fields));
            int field_count = av_count(av_fields);
            for (int i = 0; i < field_count; ++i) {
                SV **field = av_fetch(av_fields, i, 0);
                AV *key_value = MUTABLE_AV((*field));
                SV **name_ptr = av_fetch(key_value, 0, 0);
                SV **type_ptr = av_fetch(key_value, 1, 0);
                char *key = SvPVbytex_nolen(*name_ptr);
                if (!hv_exists(hv_data, key, strlen(key)))
                    continue; // croak("Expected key %s does not exist in given data", key);
                SV **_data = hv_fetch(hv_data, key, strlen(key), 0);
                char *type = SvPVbytex_nolen(*type_ptr);
                size_t el_len = _sizeof(aTHX_ * type_ptr);
                if (SvOK(data) || SvOK(SvRV(data)))
                    sv2ptr(aTHX_ * type_ptr, *(hv_fetch(hv_data, key, strlen(key), 0)),
                           ((DCpointer)(PTR2IV(ptr) + pos)), packed, pos);
                pos += el_len;
            }
        }
        dcCloseAggr(retval);
        return retval;
    } break;
    case DC_SIGCHAR_ARRAY: {
        // sv_dump(data);
        int spot = 1;
        AV *elements = MUTABLE_AV(SvRV(data));
        SV *pointer;
        HV *hv_ptr = MUTABLE_HV(SvRV(type));
        SV **type_ptr = hv_fetchs(hv_ptr, "type", 0);
        SV **size_ptr = hv_fetchs(hv_ptr, "size", 0);
        size_t size = SvIV(*size_ptr);

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

            for (int i = 0; i < av_len; ++i) {
                sv2ptr(aTHX_ * type_ptr, *(av_fetch(elements, i, 0)),
                       ((DCpointer)(PTR2IV(ptr) + pos)), packed, pos);
                pos += (el_len);
            }
        }
            // return _sizeof(aTHX_ type);
        }
        // croak("ARRAY!");
    } break;
    case DC_SIGCHAR_CODE:
        croak("TODO: CODE!");
        break;
    case DC_SIGCHAR_BOOL: {
        bool value = SvTRUE(data);
        Copy((char *)(&value), ptr, 1, bool);
    } break;
    case DC_SIGCHAR_CHAR: {
        if (SvIOK(data)) {
            char value = (char)SvIV(data);
            Copy((char *)(&value), ptr, 1, char);
        }
        else {
            char *value = SvPV_nolen(data);
            Copy(value, ptr, 1, char);
            Copy((char *)(&value), ptr, 1, char);
        }
    } break;
    case DC_SIGCHAR_UCHAR: {
        if (SvUOK(data)) {
            unsigned char value = (unsigned char)SvUV(data);
            Copy((char *)(&value), ptr, 1, unsigned char);
        }
        else {
            unsigned char *value = (unsigned char *)SvPV_nolen(data);
            Copy((char *)(&value), ptr, 1, unsigned char);
        }
    } break;
    case DC_SIGCHAR_SHORT: {
        short value = (short)SvIV(data);
        Copy((char *)(&value), ptr, 1, short);
    } break;
    case DC_SIGCHAR_USHORT: {
        unsigned short value = (unsigned short)SvUV(data);
        Copy((char *)(&value), ptr, 1, unsigned short);
    } break;
    case DC_SIGCHAR_INT: {
        int value = SvIV(data);
        Copy((char *)(&value), ptr, 1, int);
    } break;
    case DC_SIGCHAR_UINT: {
        unsigned int value = SvUV(data);
        Copy((char *)(&value), ptr, 1, unsigned int);
    } break;
    case DC_SIGCHAR_LONG: {
        long value = SvIV(data);
        Copy((char *)(&value), ptr, 1, long);
    } break;
    case DC_SIGCHAR_ULONG: {
        unsigned long value = SvUV(data);
        Copy((char *)(&value), ptr, 1, unsigned long);
    } break;
    case DC_SIGCHAR_LONGLONG: {
        long long value = SvUV(data);
        Copy((char *)(&value), ptr, 1, long long);
    } break;
    case DC_SIGCHAR_ULONGLONG: {
        unsigned long long value = SvUV(data);
        Copy((char *)(&value), ptr, 1, unsigned long long);
    } break;
    case DC_SIGCHAR_FLOAT: {
        float value = SvNV(data);
        Copy((char *)(&value), ptr, 1, float);
    } break;
    case DC_SIGCHAR_DOUBLE: {
        double value = SvNV(data);
        Copy((char *)(&value), ptr, 1, double);
    } break;
    case DC_SIGCHAR_STRING: {
        char *value = SvPV_nolen(data);
        Copy(&value, ptr, 1, intptr_t);
    } break;
    case DC_SIGCHAR_POINTER: {
        HV *hv_ptr = MUTABLE_HV(SvRV(type));
        SV **type_ptr = hv_fetchs(hv_ptr, "type", 0);
        DCpointer value = safemalloc(_sizeof(aTHX_ * type_ptr));
        sv2ptr(aTHX_ * type_ptr, data, value, packed, 0);
        Copy(&value, ptr, 1, intptr_t);
    } break;
    default: {
        char *str = SvPVbytex_nolen(type);
        croak("%c is not a known type in sv2ptr(...)", str[0]);
    }
    }
    // DumpHex(RETVAL, 1024);
    return NULL; // pos;
                 /*return newSV(0);
                 return MUTABLE_SV(newAV_mortal());
                 return (newSVpv((const char *)RETVAL, 1024)); // XXX: Use mock sizeof from elements
                 */
}
