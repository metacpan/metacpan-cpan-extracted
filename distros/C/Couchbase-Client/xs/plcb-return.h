#ifndef PLCB_RETURN_H_
#define PLCB_RETURN_H_

#include "plcb-util.h"

typedef enum {
    PLCB_RETIDX_VALUE   = 0,
    PLCB_RETIDX_ERRNUM  = 1,
    PLCB_RETIDX_ERRSTR  = 2,
    PLCB_RETIDX_CAS     = 3,
    
    /*Extended Fields*/
    PLCB_RETIDX_ORIGSIZE,
    PLCB_RETIDX_KEYFLAGS,
} PLCB_ret_idx_t;

#define plcb_ret_set_cas(obj, ret, cas) \
    av_store(ret, PLCB_RETIDX_CAS, \
        plcb_sv_from_u64_new(cas) );

#define plcb_ret_set_strval(obj, ret, value, nvalue, flags, cas) \
    av_store(ret, PLCB_RETIDX_VALUE, \
        plcb_convert_retrieval(obj, value, nvalue, flags)); \
    plcb_ret_set_cas(obj, ret, &cas);

/*not currently used*/

#define plcb_ret_set_extfields(obj, ret, orig_len, orig_flags) \
    if(obj->my_flags & PLCBf_RET_EXTENDED_FLAGS) { \
        av_store(ret, PLCB_RETIDX_ORIGSIZE, newSVuv(orig_len)); \
        av_store(ret, PLCB_RETIDX_KEYFLAGS, newSVuv(orig_flags)); \
    }

static inline void
plcb_ret_set_numval(PLCB_t *obj, AV *ret, uint64_t value, uint64_t cas)
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
    plcb_ret_set_cas(obj, ret, &cas);
}


#define plcb_ret_set_err(obj, ret, err) \
    av_store(ret, PLCB_RETIDX_ERRNUM, newSViv(err)); \
    if(err != LIBCOUCHBASE_SUCCESS) { \
        av_store(ret, PLCB_RETIDX_ERRSTR, \
        newSVpv(libcouchbase_strerror(obj->instance, err), 0)); \
    }

#define plcb_ret_blessed_rv(obj, ret) \
    sv_bless(newRV_noinc( (SV*)(ret)), (obj)->ret_stash)

#endif /*PLCB_RETURN_H_*/
