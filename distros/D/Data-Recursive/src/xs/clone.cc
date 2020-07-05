#include "clone.h"
#include <map>

#ifndef gv_fetchmeth
#define gv_fetchmeth(stash,name,len,level,flags) gv_fetchmethod_autoload(stash,name,0)
#endif

namespace xs {

static const char* HOOK_METHOD  = "HOOK_CLONE";
static const int   HOOK_METHLEN = strlen(HOOK_METHOD);
static const int   CLONE_MAX_DEPTH = 1000;

static MGVTBL clone_marker;

struct CrossData {
    struct WeakRef {
        SV*      dest;
        uint64_t key;
    };
    std::map<uint64_t, SV*> map;
    std::vector<WeakRef>    weakrefs;
};

static void _clone (pTHX_ SV*, SV*, CrossData*&, I32);

Sv clone (const Sv& source, int flags) {
    dTHX;
    Sv ret = Sv::create();

    CrossData* crossdata = NULL;
    if (flags & CloneFlags::TRACK_REFS) {
        CrossData data;
        crossdata = &data;
        _clone(aTHX_ ret, source, crossdata, 0);
        auto end = data.map.end();
        for (const auto& row : data.weakrefs) { // post process weak refs that appeared before their strong refs
            auto it = data.map.find(row.key);
            if (it == end) continue;
            SvSetSV_nosteal(row.dest, it->second);
            sv_rvweaken(row.dest);
        }
    }
    else _clone(aTHX_ ret, source, crossdata, 0);

    return ret;
}

static void _clone (pTHX_ SV* dest, SV* source, CrossData*& xdata, I32 depth) {
    if (depth > CLONE_MAX_DEPTH) throw std::invalid_argument(
        std::string("clone: max depth (") + std::to_string(CLONE_MAX_DEPTH) + ") reached, it looks like you passed a cycled structure"
    );

    if (SvROK(source)) { // reference
        SV* source_val = SvRV(source);
        svtype val_type = SvTYPE(source_val);

        if (val_type == SVt_PVCV || val_type == SVt_PVIO) { // CV and IO cannot be copied - just set reference to the same SV
            SvSetSV_nosteal(dest, source);
            if (SvWEAKREF(source)) sv_rvweaken(dest);
            return;
        }

        uint64_t id = PTR2UV(source_val);
        if (xdata) {
            auto it = xdata->map.find(id);
            if (it != xdata->map.end()) {
                SvSetSV_nosteal(dest, it->second);
                if (SvWEAKREF(source)) sv_rvweaken(dest);
                return;
            }
            if (SvWEAKREF(source)) {
                // we can't clone object weakref points to right now, because no strong refs for the object cloned so far, we must wait until the end
                xdata->weakrefs.push_back({dest, id});
                return;
            }
        }

        GV* cloneGV;
        bool is_object = SvOBJECT(source_val);

        // cloning an object with custom clone behavior
        if (is_object) {
            auto mg = mg_findext(source_val, PERL_MAGIC_ext, &clone_marker);
            if (mg) {
                xdata = reinterpret_cast<CrossData*>(mg->mg_ptr); // restore top-map after recursive clone() call
            }
            else if ((cloneGV = gv_fetchmeth(SvSTASH(source_val), HOOK_METHOD, HOOK_METHLEN, 0))) {
                // set cloning flag into object's magic to prevent infinite loop if user calls 'clone' again from hook
                sv_magicext(source_val, NULL, PERL_MAGIC_ext, &clone_marker, (const char*)xdata, 0);
                dSP; ENTER; SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(source);
                PUTBACK;
                int count = call_sv((SV*)GvCV(cloneGV), G_SCALAR);
                SPAGAIN;
                SV* retval = NULL;
                while (count--) retval = POPs;
                if (retval) SvSetSV(dest, retval);
                PUTBACK;
                FREETMPS; LEAVE;
                // remove cloning flag from object's magic
                sv_unmagicext(source_val, PERL_MAGIC_ext, &clone_marker);
                if (xdata) xdata->map[id] = dest;
                return;
            }
        }

        SV* refval = newSV(0);
        sv_upgrade(dest, SVt_RV);
        SvRV_set(dest, refval);
        SvROK_on(dest);

        if (is_object) sv_bless(dest, SvSTASH(source_val)); // cloning an object without any specific clone behavior
        if (xdata) xdata->map[id] = dest;
        _clone(aTHX_ refval, source_val, xdata, depth+1);

        return;
    }

    switch (SvTYPE(source)) {
        case SVt_IV:     // integer
        case SVt_NV:     // long double
        case SVt_PV:     // string
        case SVt_PVIV:   // string + integer
        case SVt_PVNV:   // string + long double
        case SVt_PVMG:   // blessed scalar (doesn't really true, it's just vars or magic vars)
        case SVt_PVGV:   // typeglob
#if PERL_VERSION > 16
        case SVt_REGEXP: // regexp
#endif
            SvSetSV_nosteal(dest, source);
            return;
#if PERL_VERSION <= 16 // fix bug in SvSetSV_nosteal while copying regexp SV prior to perl 5.16.0
        case SVt_REGEXP: // regexp
            SvSetSV_nosteal(dest, source);
            if (SvSTASH(dest) == NULL) SvSTASH_set(dest, gv_stashpv("Regexp",0));
            return;
#endif
        case SVt_PVAV: { // array
            sv_upgrade(dest, SVt_PVAV);
            SV** srclist = AvARRAY((AV*)source);
            SSize_t srcfill = AvFILLp((AV*)source);
            av_extend((AV*)dest, srcfill); // dest is an empty array. we can set directly it's SV** array for speed
            AvFILLp((AV*)dest) = srcfill; // set array len
            SV** dstlist = AvARRAY((AV*)dest);
            for (SSize_t i = 0; i <= srcfill; ++i) {
                SV* srcval = *srclist++;
                if (srcval != NULL) { // if not empty slot
                    SV* elem = newSV(0);
                    dstlist[i] = elem;
                    _clone(aTHX_ elem, srcval, xdata, depth+1);
                }
            }
            return;
        }
        case SVt_PVHV: { // hash
            sv_upgrade(dest, SVt_PVHV);
            STRLEN hvmax = HvMAX((HV*)source);
            HE** hvarr = HvARRAY((HV*)source);
            if (!hvarr) return;

            for (STRLEN i = 0; i <= hvmax; ++i) {
                const HE* entry;
                for (entry = hvarr[i]; entry; entry = HeNEXT(entry)) {
                    HEK* hek = HeKEY_hek(entry);
                    SV* elem = newSV(0);
                    hv_storehek((HV*)dest, hek, elem);
                    _clone(aTHX_ elem, HeVAL(entry), xdata, depth+1);
                }
            }

            return;
        }
        case SVt_NULL: // undef
        default: // BIND, LVALUE, FORMAT - are not copied
            return;
    }
}

}
