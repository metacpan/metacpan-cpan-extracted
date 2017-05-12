#ifndef __INHERITED_XS_OP_H_
#define __INHERITED_XS_OP_H_

#ifdef CAIX_OPTIMIZE_OPMETHOD
#include <algorithm>

typedef void (*ACCESSOR_t)(pTHX_ SV**, CV*, HV*);
typedef std::pair<XSUBADDR_t, ACCESSOR_t> accessor_cb_pair_t;
#endif

#define OP_UNSTEAL(name) STMT_START {       \
        ++unstolen;                         \
        PL_op->op_ppaddr = PL_ppaddr[name]; \
        return PL_ppaddr[name](aTHX);       \
    } STMT_END                              \

template <AccessorType type, AccessorOpts opts> static
XSPROTO(CAIXS_entersub_wrapper) {
    dSP;

    CAIXS_accessor<type, opts>(aTHX_ SP, cv, NULL);

    return;
}

#ifdef CAIX_OPTIMIZE_OPMETHOD

/* catchy place, don't forget to add new types here */
#define ACCESSOR_MAP_SIZE 12
static accessor_cb_pair_t accessor_map[ACCESSOR_MAP_SIZE] = {
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<Inherited, IsReadonly>, &CAIXS_accessor<Inherited, IsReadonly>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<Inherited, None>, &CAIXS_accessor<Inherited, None>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<InheritedCb, IsReadonly>, &CAIXS_accessor<InheritedCb, IsReadonly>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<InheritedCb, None>, &CAIXS_accessor<InheritedCb, None>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<PrivateClass, IsReadonly>, &CAIXS_accessor<PrivateClass, IsReadonly>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<PrivateClass, None>, &CAIXS_accessor<PrivateClass, None>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<LazyClass, IsReadonly>, &CAIXS_accessor<LazyClass, IsReadonly>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<LazyClass, None>, &CAIXS_accessor<LazyClass, None>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<ObjectOnly, IsReadonly>, &CAIXS_accessor<ObjectOnly, IsReadonly>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<ObjectOnly, None>, &CAIXS_accessor<ObjectOnly, None>),
    accessor_cb_pair_t(&CAIXS_entersub_wrapper<Constructor, None>, &CAIXS_accessor<Constructor, None>),
    accessor_cb_pair_t(NULL, NULL) /* sentinel */
};

static int
CAIXS_map_compare(const void* a, const void* b) {
    return ((const accessor_cb_pair_t*)a)->first > ((const accessor_cb_pair_t*)b)->first ? -1 : 1;
}

template <AccessorType type, int optype, AccessorOpts opts> static
OP *
CAIXS_opmethod_wrapper(pTHX) {
    dSP;

    SV* self = PL_stack_base + TOPMARK == SP ? (SV*)NULL : *(PL_stack_base + TOPMARK + 1);
    HV* stash = NULL;

    /*
        This block isn't required for the 'goto gotcv' case, but skipping it
        (or swapping those blocks) makes unstealing inside 'goto gotcv' block impossible,
        thus requiring additional check in the fast case, which is to be avoided.
    */
#ifndef GV_CACHE_ONLY
    if (LIKELY(self != NULL)) {
        SvGETMAGIC(self);
#else
    if (LIKELY(self && !SvGMAGICAL(self))) {
        /* SvIsCOW_shared_hash is incompatible with SvGMAGICAL, so skip it completely */
        if (SvIsCOW_shared_hash(self)) {
            stash = gv_stashsv(self, GV_CACHE_ONLY);
        } else
#endif
        if (SvROK(self)) {
            SV* ob = SvRV(self);
            if (SvOBJECT(ob)) stash = SvSTASH(ob);

        } else if (SvPOK(self)) {
            const char* packname = SvPVX_const(self);
            const STRLEN packlen = SvCUR(self);
            const int is_utf8 = SvUTF8(self);

#ifndef GV_CACHE_ONLY
            const HE* const he = (const HE *)hv_common(PL_stashcache, NULL, packname, packlen, is_utf8, 0, NULL, 0);
            if (he) stash = INT2PTR(HV*, SvIV(HeVAL(he)));
            else
#endif
            stash = gv_stashpvn(packname, packlen, is_utf8);
        }
    }

    SV* meth;
    CV* cv = NULL;
    U32 hash;

    if (optype == OP_METHOD) {
        meth = TOPs;
        if (SvROK(meth)) {
            SV* const rmeth = SvRV(meth);
            if (SvTYPE(rmeth) == SVt_PVCV) {
                cv = (CV*)rmeth;
                goto gotcv; /* We don't care about the 'stash' var here */
            }
        }

        hash = 0;

    } else if (optype == OP_METHOD_NAMED) {
        meth = cSVOPx_sv(PL_op);

#ifndef GV_CACHE_ONLY
        hash = SvSHARED_HASH(meth);
#else
        hash = 0;
#endif
    }

    /* SvTYPE check appeared only since 5.22, but execute it for all perls nevertheless */
    if (UNLIKELY(!stash || SvTYPE(stash) != SVt_PVHV)) {
        OP_UNSTEAL(optype);
    }

    HE* he; /* To allow 'goto' to jump over this */
    if ((he = hv_fetch_ent(stash, meth, 0, hash))) {
        GV* gv = (GV*)(HeVAL(he));
        if (isGV(gv) && GvCV(gv) && (!GvCVGEN(gv) || GvCVGEN(gv) == (PL_sub_generation + HvMROMETA(stash)->cache_gen))) {
            cv = GvCV(gv);
        }
    }

    if (UNLIKELY(!cv)) {
        GV* gv = gv_fetchmethod_sv_flags(stash, meth, GV_AUTOLOAD|GV_CROAK);
        assert(gv);

        cv = isGV(gv) ? GvCV(gv) : (CV*)gv;
        assert(cv);
    }

gotcv:
    ACCESSOR_t accessor = NULL;
    XSUBADDR_t xsub = CvXSUB(cv);

    if (LIKELY((xsub == (XSUBADDR_t)&CAIXS_entersub_wrapper<type, opts>))) {
        accessor = &CAIXS_accessor<type, opts>;

    } else {
        /*
            Check whether this is an iterator over another friendly accessor.
            This is much faster then a permanent optimization lift, even if we guess
            base type only once.
        */

        const accessor_cb_pair_t* iter = accessor_map;
        while (iter->first > xsub) { ++iter; }
        if (iter->first == xsub) accessor = iter->second;
    }

    if (LIKELY(accessor != NULL)) {
        assert(CvISXSUB(cv));
        if (optype == OP_METHOD) {--SP; PUTBACK; }

        accessor(aTHX_ SP, cv, stash);
        return PL_op->op_next->op_next;

    } else {
        /*
            We could also lift off CAIXS_entersub optimization here, but that's a one-time action,
            so let it fail on it's own
        */
        OP_UNSTEAL(optype);
    }
}

#endif /* CAIX_OPTIMIZE_OPMETHOD */

template <AccessorType type, AccessorOpts opts> static
OP *
CAIXS_entersub(pTHX) {
    dSP;

    CV* sv = (CV*)TOPs;

    if (LIKELY(sv != NULL)) {
        if (UNLIKELY(SvTYPE(sv) != SVt_PVCV)) {
            /* can('acc')->() or (\&acc)->()  */

            if ((SvFLAGS(sv) & (SVf_ROK|SVs_GMG)) == SVf_ROK) sv = (CV*)SvRV(sv);
            if (UNLIKELY((SvTYPE(sv) != SVt_PVCV) || SvOBJECT(sv))) OP_UNSTEAL(OP_ENTERSUB);
        }

        /* Some older gcc's can't deduce correct function - have to add explicit cast  */
        if (LIKELY((CvXSUB(sv) == (XSUBADDR_t)&CAIXS_entersub_wrapper<type, opts>))) {
            /*
                Assert against future XPVCV layout change - as for now, xcv_xsub shares space with xcv_root
                which are both pointers, so address check is enough, and there's no need to look into op_flags for CvISXSUB.
            */
            assert(CvISXSUB(sv));

            POPs; PUTBACK;
            CAIXS_accessor<type, opts>(aTHX_ SP, sv, NULL);

            return NORMAL;
        }

    }

    OP_UNSTEAL(OP_ENTERSUB);
}

template <AccessorType type, AccessorOpts opts> inline
void
CAIXS_install_entersub(pTHX) {
    /*
        Check whether we can replace opcode executor with our own variant. Unfortunatelly, this guards
        only against local changes, not when someone steals PL_ppaddr[OP_ENTERSUB] globally.
        Sorry, Devel::NYTProf.
    */

    OP* op = PL_op;

    if (
        (op->op_spare & 1) != 1
            &&
        op->op_type == OP_ENTERSUB
            &&
        (op->op_flags & OPf_STACKED) /* avoid stealing &sub calls, as we don't want to unpack @_ */
            &&
        op->op_ppaddr == PL_ppaddr[OP_ENTERSUB]
            &&
        optimize_entersub
    ) {
        op->op_spare |= 1;
        op->op_ppaddr = &CAIXS_entersub<type, opts>;

#ifdef CAIX_OPTIMIZE_OPMETHOD
        OP* methop = cUNOPx(op)->op_first;
        if (LIKELY(methop != NULL)) {   /* Such op can be created by call_sv(G_METHOD_NAMED) */
            while (OpHAS_SIBLING(methop)) { methop = OpSIBLING(methop); }

            if (methop->op_next == op) {
                if (methop->op_type == OP_METHOD_NAMED && methop->op_ppaddr == PL_ppaddr[OP_METHOD_NAMED]) {
                    methop->op_ppaddr = &CAIXS_opmethod_wrapper<type, OP_METHOD_NAMED, opts>;

                } else if (methop->op_type == OP_METHOD && methop->op_ppaddr == PL_ppaddr[OP_METHOD]) {
                    methop->op_ppaddr = &CAIXS_opmethod_wrapper<type, OP_METHOD, opts>;
                }
            }
        }
#endif /* CAIX_OPTIMIZE_OPMETHOD */
    }
}

#endif /* __INHERITED_XS_OP_H_ */
