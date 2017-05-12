#include "perl-couchbase-async.h"

static inline void
tell_perl(PLCBA_cookie_t *cookie, AV *ret,
            const char *key, size_t nkey)
{
    dSP;
    
    hv_store(cookie->results, key, nkey,
             plcb_ret_blessed_rv(&(cookie->parent->base), ret),
             0);
    
    cookie->remaining--;    
    
    if(cookie->cbtype == PLCBA_CBTYPE_INCREMENTAL ||
       (cookie->cbtype == PLCBA_CBTYPE_COMPLETION &&
        cookie->remaining == 0)) {
        
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        
        XPUSHs(sv_2mortal(newRV_inc((SV*)cookie->results)));
        XPUSHs(cookie->cbdata);
        
        PUTBACK;
        
        call_sv(cookie->callcb, G_DISCARD);
        
        FREETMPS;
        LEAVE;
    }
    
    if(!cookie->remaining) {
        SvREFCNT_dec(cookie->results);
        SvREFCNT_dec(cookie->callcb);
        SvREFCNT_dec(cookie->cbdata);
        Safefree(cookie);
    }
}

void plcba_callback_notify_err(PLCBA_t *async,
                               PLCBA_cookie_t *cookie,
                               const char *key, size_t nkey,
                               libcouchbase_error_t err)
{
    AV *ret;
    
    warn("Got immediate error for %s", key);
    ret = newAV();
    plcb_ret_set_err((&(async->base)), ret, err);
    tell_perl(cookie, ret, key, nkey);
}

/*macro to define common variables and operations for callbacks*/

#define _CB_INIT \
    PLCBA_cookie_t *cookie; \
    AV *ret; \
    PLCB_t *object; \
    \
    ret = newAV(); \
    cookie = (PLCBA_cookie_t*)(v_cookie); \
    object = &(cookie->parent->base); \
    plcb_ret_set_err(object, ret, err);

static void
get_callback(
    libcouchbase_t instance,
    const void *v_cookie,
    libcouchbase_error_t err,
    const void *key, size_t nkey,
    const void *bytes, size_t nbytes,
    uint32_t flags, uint64_t cas)
{
    _CB_INIT;
    //warn("Get callback");
    if(err == LIBCOUCHBASE_SUCCESS) {
        //warn("Got value of %d bytes", nbytes);
        plcb_ret_set_strval(object, ret, bytes, nbytes, flags, cas);
    }
    tell_perl(cookie, ret, key, nkey);
}

static void
storage_callback(libcouchbase_t instance,
                 const void *v_cookie,
                 libcouchbase_storage_t operation,
                 libcouchbase_error_t err,
                 const void *key, size_t nkey,
                 uint64_t cas)
{
    _CB_INIT;
    if(cas) {
        plcb_ret_set_cas(object, ret, &cas);
    }
    tell_perl(cookie, ret, key, nkey);
}

static void
arithmetic_callback(libcouchbase_t instance,
                    const void *v_cookie,
                    libcouchbase_error_t err,
                    const void *key, size_t nkey,
                    uint64_t value, uint64_t cas)
{
    _CB_INIT;
    if(err == LIBCOUCHBASE_SUCCESS) {
        plcb_ret_set_numval(object, ret, value, cas);
    }
    tell_perl(cookie, ret, key, nkey);
}

static void
remove_callback(libcouchbase_t instance,
                const void *v_cookie,
                libcouchbase_error_t err,
                const void *key, size_t nkey)
{
    _CB_INIT;
    tell_perl(cookie, ret, key, nkey);
}

/*stat not implemented*/

#define touch_callback remove_callback

static void
error_callback(libcouchbase_t instance,
               libcouchbase_error_t err,
               const char *errinfo)
{
    PLCBA_t *async;
    dSP;

    async = (PLCBA_t*)libcouchbase_get_cookie(instance);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    
    XPUSHs(sv_2mortal(newSViv(err)));
    XPUSHs(sv_2mortal(newSVpv(errinfo, 0)));
    PUTBACK;
    
    call_sv(async->cv_err, G_DISCARD);
    
    FREETMPS;
    LEAVE;
}

void
plcba_setup_callbacks(PLCBA_t *async)
{
    libcouchbase_t instance;
    
    instance = async->base.instance;
    
    libcouchbase_set_get_callback(instance, get_callback);
    libcouchbase_set_storage_callback(instance, storage_callback);
    libcouchbase_set_arithmetic_callback(instance, arithmetic_callback);
    libcouchbase_set_remove_callback(instance, remove_callback);
    /*
    libcouchbase_set_stats_callback(instance, stats_callback);
    */
    libcouchbase_set_touch_callback(instance, touch_callback);
    libcouchbase_set_error_callback(instance, error_callback);
    
    libcouchbase_set_cookie(instance, async);
}
