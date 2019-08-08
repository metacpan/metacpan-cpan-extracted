#include "compare.h"
#include <stdint.h>

namespace xs {

static inline bool _elem_cmp (pTHX_ SV* f, SV* s);

static inline bool hv_compare (pTHX_ HV* f, HV* s) {
    if (HvUSEDKEYS(f) != HvUSEDKEYS(s)) return false;

    HE** farr = HvARRAY(f);
    if (!farr) return true; // both are empty
    STRLEN fmax = HvMAX(f);
    bool res = true;

    for (STRLEN i = 0; res && i <= fmax; ++i) {
        const HE* entry;
        for (entry = farr[i]; res && entry; entry = HeNEXT(entry)) {
            const HEK* hek = HeKEY_hek(entry);
            SV** sref = hv_fetchhek(s, hek, 0);
            if (!sref) return false;
            res = _elem_cmp(aTHX_ HeVAL(entry), *sref);
        }
    }

    return res;
}

static inline bool av_compare (pTHX_ AV* f, AV* s) {
    SSize_t lasti = AvFILLp(f);
    if (lasti != AvFILLp(s)) return false;
    SV** fl = AvARRAY(f);
    SV** sl = AvARRAY(s);

    bool res = true;
    while (res && lasti-- >= 0) {
        if ((bool)*fl ^ (bool)*sl) return false; // one is null while another is not.
        res = _elem_cmp(aTHX_ *fl++, *sl++);
    }
    return res;
}

static inline bool _elem_cmp (pTHX_ SV* f, SV* s) {
    if (f == s) return true;

    if (SvROK(f) | SvROK(s)) { /* unroll references */
        while (SvROK(f) & SvROK(s)) {
            SV* fval = SvRV(f);
            SV* sval = SvRV(s);
            if (SvOBJECT(fval) ^ SvOBJECT(sval)) return false;
            if (SvOBJECT(fval)) {
                if (fval == sval) return true;
                if (SvSTASH(fval) != SvSTASH(sval)) return false;
                if (HvAMAGIC(SvSTASH(fval))) { // class has operator overloadings
                    SV* const tmpsv = amagic_call(f, s, eq_amg, 0);
                    if (tmpsv) return SvTRUE(tmpsv); // class has '==' operator overloading
                    // otherwise compare object's data structure as it wasn't blessed at all.
                }
            }
            f = fval;
            s = sval;
        }
        if (SvROK(f) | SvROK(s)) return false; /* asymmetric references */
        if (f == s) return true;
    }

    switch (SvTYPE(f)) {
        case SVt_IV:
        case SVt_NV:
        case SVt_PV:
        case SVt_PVIV:
        case SVt_PVNV:
        case SVt_NULL:
        case SVt_PVMG:
            if (SvOK(f) && SvOK(s)) { // both are not undefs
                if (SvTYPE(s) > SVt_PVMG) return false; // wrong type
                if (SvPOK(f) | SvPOK(s)) return strEQ(SvPV_nolen(f), SvPV_nolen(s)); // both strings
                if (SvNOK(f) | SvNOK(s)) return SvNV(f) == SvNV(s); // natural values
                return SvIVX(f) == SvIVX(s); // compare as integers
            }
            return !(SvOK(f) || SvOK(s));
        case SVt_PVHV:
            return SvTYPE(s) == SVt_PVHV && hv_compare(aTHX_ (HV*)f, (HV*)s);
        case SVt_PVAV:
            return SvTYPE(s) == SVt_PVAV && av_compare(aTHX_ (AV*)f, (AV*)s);
        case SVt_PVIO:
            return SvTYPE(s) == SVt_PVIO && PerlIO_fileno(IoIFP(f)) == PerlIO_fileno(IoIFP(s));
        case SVt_REGEXP:
            return SvTYPE(s) == SVt_REGEXP && strEQ(SvPV_nolen(f), SvPV_nolen(s));
        case SVt_PVCV:
        case SVt_PVGV:
            return false; /* already checked by pointers equality */
        default:
            return false;
    }
}

bool compare (const Sv& f, const Sv& s) {
    if ((bool)f ^ (bool)s) return false;
    return _elem_cmp(aTHX_ f, s); // _elem_cmp cannot receive NULLs except for when both are NULLs
}


}
