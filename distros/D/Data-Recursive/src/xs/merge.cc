#include "merge.h"
#include <xs/clone.h>

#define MERGE_CAN_ALIAS(flags, value) (!(flags & MergeFlags::COPY_SOURCE) && !SvROK(value))
#define MERGE_CAN_LAZY(flags, value)  ((flags & MergeFlags::LAZY) && !SvROK(value))
#define MERGE_MAX_DEPTH 5000
#define MERGE_DEPTH_ERROR std::invalid_argument("synchronous cycled reference in source and dest data detected")

namespace xs {

static void _hash_merge (pTHX_ HV* dest, HV* source, IV flags, I32 depth);
static void _array_merge (pTHX_ AV* dest, AV* source, IV flags, I32 depth);

static inline void _elem_merge (pTHX_ SV* dest, SV* source, IV flags, I32 depth) {
    if (SvROK(source)) {
        uint8_t type = SvTYPE(SvRV(source));
        if (type == SVt_PVHV && dest != NULL && SvROK(dest) && SvTYPE(SvRV(dest)) == type) {
            _hash_merge(aTHX_ (HV*) SvRV(dest), (HV*) SvRV(source), flags, depth+1);
            return;
        }
        else if (type == SVt_PVAV && (flags & (MergeFlags::ARRAY_MERGE|MergeFlags::ARRAY_CONCAT)) && dest != NULL && SvROK(dest) && SvTYPE(SvRV(dest)) == type) {
            _array_merge(aTHX_ (AV*) SvRV(dest), (AV*) SvRV(source), flags, depth+1);
            return;
        }

        if ((flags & MergeFlags::LAZY) && SvOK(dest)) return;

        if (flags & MergeFlags::COPY_SOURCE) { // deep copy reference value
            SV* copy = newRV_noinc(clone(SvRV(source), 0).detach());
            SvSetSV_nosteal(dest, copy);
            SvREFCNT_dec(copy);
            return;
        }

        SvSetSV_nosteal(dest, source);
    }
    else {
        if ((flags & MergeFlags::LAZY) && SvOK(dest)) return;
        SvSetSV_nosteal(dest, source);
    }
}

static void _hash_merge (pTHX_ HV* dest, HV* source, IV flags, I32 depth) {
    if (dest == source) return; // nothing to merge, avoid recursive cycle-reference self-merge
    if (depth > MERGE_MAX_DEPTH) throw MERGE_DEPTH_ERROR;

    STRLEN hvmax = HvMAX(source);
    HE** hvarr = HvARRAY(source);
    if (!hvarr) return;
    for (STRLEN i = 0; i <= hvmax; ++i) {
        const HE* entry;
        for (entry = hvarr[i]; entry; entry = HeNEXT(entry)) {
            HEK* hek = HeKEY_hek(entry);
            SV* valueSV = HeVAL(entry);
            if ((flags & MergeFlags::SKIP_UNDEF) && !SvOK(valueSV)) continue; // skip undefs
            if ((flags & MergeFlags::DELETE_UNDEF) && !SvOK(valueSV)) {
                hv_deletehek(dest, hek, G_DISCARD);
                continue;
            }
            if (MERGE_CAN_LAZY(flags, valueSV)) {
                SV** elemref = hv_fetchhek(dest, hek, 0);
                if (elemref != NULL && SvOK(*elemref)) continue;
            }
            if (MERGE_CAN_ALIAS(flags, valueSV)) { // make aliases for simple values
                SvREFCNT_inc(valueSV);
                hv_storehek(dest, hek, valueSV);
                continue;
            }
            SV* destSV  = *(hv_fetchhek(dest, hek, 1));
            _elem_merge(aTHX_ destSV, valueSV, flags, depth);
        }
    }
}

static void _array_merge (pTHX_ AV* dest, AV* source, IV flags, I32 depth) {
    if (dest == source) return; // nothing to merge, avoid recursive cycle-reference self-merge
    if (depth > MERGE_MAX_DEPTH) throw MERGE_DEPTH_ERROR;

    // we are using low-level code for AV for efficiency (it is 5-10x times faster)
    if (SvREADONLY(dest)) Perl_croak_no_modify();
    SV** srclist = AvARRAY(source);
    SSize_t srcfill = AvFILLp(source);

    if (flags & MergeFlags::ARRAY_CONCAT) {
        SSize_t savei = AvFILLp(dest) + 1;
        av_extend(dest, savei + srcfill);
        SV** dstlist = AvARRAY(dest);
        if (flags & MergeFlags::COPY_SOURCE) {
            while (srcfill-- >= 0) {
                SV* elem = *srclist++;
                dstlist[savei++] = elem == NULL ? newSV(0) : clone(elem, 0).detach();
            }
        } else {
            while (srcfill-- >= 0) {
                SV* elem = *srclist++;
                if (elem == NULL) dstlist[savei++] = newSV(0);
                else {
                    SvREFCNT_inc_simple_void_NN(elem);
                    dstlist[savei++] = elem;
                }
            }
        }
        AvFILLp(dest) = savei - 1;
    }
    else {
        av_extend(dest, srcfill);
        SV** dstlist = AvARRAY(dest);
        for (int i = 0; i <= srcfill; ++i) {
            SV* elem = *srclist++;
            if (elem == NULL) continue; // skip empty slots
            if ((flags & MergeFlags::SKIP_UNDEF) && !SvOK(elem)) continue; // skip undefs
            if (MERGE_CAN_LAZY(flags, elem) && dstlist[i] && SvOK(dstlist[i])) continue;
            if (MERGE_CAN_ALIAS(flags, elem)) { // hardcode for speed - make aliases for simple values
                SvREFCNT_inc_simple_void_NN(elem);
                if (AvREAL(dest)) SvREFCNT_dec(dstlist[i]);
                dstlist[i] = elem;
                continue;
            }
            if (!dstlist[i]) dstlist[i] = newSV(0);
            _elem_merge(aTHX_ dstlist[i], elem, flags, depth);
        }
        if (AvFILLp(dest) < srcfill) AvFILLp(dest) = srcfill;
    } 
}

Hash merge (Hash dest, const Hash& source, int flags) {
    if (!dest) dest = Hash::create();
    else if (flags & MergeFlags::COPY_DEST) dest = clone(dest, 0);
    if (source) _hash_merge(aTHX_ dest, source, flags, 1);
    return dest;
}

Array merge (Array dest, const Array& source, int flags) {
    if (!dest) dest = Array::create();
    else if (flags & MergeFlags::COPY_DEST) dest = clone(dest, 0);
    if (source) _array_merge(aTHX_ dest, source, flags | MergeFlags::ARRAY_MERGE, 1);
    return dest;
}

Sv merge (Sv dest, const Sv& source, int flags) {
    if ((flags & MergeFlags::COPY_ALL) && dest) dest = clone(dest, 0);
    _elem_merge(aTHX_ dest, source ? source.get() : &PL_sv_undef, flags, 0);
    return dest;
}

}
