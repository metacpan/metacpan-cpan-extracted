#ifndef PLCB_RETURN_H_
#define PLCB_RETURN_H_

#include "plcb-util.h"

#define plcb_doc_isa(obj, ret) \
    (sv_isobject(ret) && (SvSTASH(ret) == (obj)->ret_stash || \
            sv_derived_from(ret, PLCB_RET_CLASSNAME)))

#define plcb_opctx_isa(obj, ret) \
    (sv_isobject(ret) && (SvSTASH(ret) == (obj)->opctx_sync_stash || \
                    sv_derived_from(ret, PLCB_OPCTX_CLASSNAME)))

#define plcb_doc_set_cas(obj, ret, cas) \
    av_store(ret, PLCB_RETIDX_CAS, plcb_sv_from_u64_new(cas) );

static inline void
plcb_doc_set_numval(PLCB_t *obj, AV *ret, uint64_t value, uint64_t cas)
{
    SV *isv = newSV(0);
#ifdef PLCB_PERL64
    sv_setuv(isv, value);
#else
    if (value < UINT32_MAX) {
        sv_setuv(isv, value);
    } else {
        sv_setpvf(isv, "%llu", value);
    }
#endif
    av_store(ret, PLCB_RETIDX_VALUE, isv);
    plcb_doc_set_cas(obj, ret, &cas);
}

static inline void
plcb_doc_set_err(PLCB_t *obj, AV *ret, lcb_error_t err)
{
    SV **ivsv = av_fetch(ret, PLCB_RETIDX_ERRNUM, 1);
    sv_setiv(*ivsv, err);
    (void)obj;
}
static inline lcb_error_t
plcb_doc_get_err(AV *ret)
{
    SV **ivsv = av_fetch(ret, PLCB_RETIDX_ERRNUM, 0);
    if (ivsv == NULL || SvIOK(*ivsv) == 0) {
        return LCB_ERROR;
    }
    return SvIVX(*ivsv);
}

#define plcb_ret_blessed_rv(obj, ret) \
    sv_bless(newRV_noinc( (SV*)(ret)), (obj)->ret_stash)

static inline int
plcb_opctx_remaining(AV *arr, int op)
{
    SV *ivsv = *(av_fetch(arr, PLCB_OPCTXIDX_REMAINING, 1));
    if (!SvIOK(ivsv)) {
        if (op < 0) {
            die("Cannot decrement non existent remaining count");
        }
        sv_setiv(ivsv, op);
    } else {
        SvIVX(ivsv) += op;
    }
    return SvIVX(ivsv);
}

#define PLCB_MKDURABILITY(persist_to, replicate_to) \
    persist_to | (replicate_to << 8)

#define PLCB_GETDURABILITY(cur, persist_to, replicate_to) \
    persist_to = cur & 0xff; \
    replicate_to = ( cur >> 8 )  & 0xff

#endif /*PLCB_RETURN_H_*/
