#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perl-couchbase.h"

static inline void
signal_done(PLCB_sync_t *sync)
{
    sync->parent->npending--;
    if(sync->parent->npending) {
        return;
    }
    
    sync->parent->io_ops->stop_event_loop(
        sync->parent->io_ops);
}

void plcb_callback_get(
    libcouchbase_t instance,
    const void *cookie,
    libcouchbase_error_t err,
    const void *key, size_t nkey,
    const void *value, size_t nvalue,
    uint32_t flags, uint64_t cas)
{
    PLCB_sync_t *syncp = plcb_sync_cast(cookie);
    plcb_ret_set_err(syncp->parent, syncp->ret, err);
    if(err == LIBCOUCHBASE_SUCCESS && nvalue) {
        plcb_ret_set_strval(
            syncp->parent, syncp->ret, value, nvalue, flags, cas);
    }
    signal_done(syncp);
}

void plcb_callback_multi_get(
    libcouchbase_t instance,
    const void *cookie,
    libcouchbase_error_t err,
    const void *key, size_t nkey,
    const void *value, size_t nvalue,
    uint32_t flags, uint64_t cas)
{
    PLCB_sync_t *syncp = plcb_sync_cast(cookie);
    AV *ret;
    HV *results;
        
    ret = newAV();
    results = (HV*)(syncp->ret);
    
    hv_store(results, key, nkey, plcb_ret_blessed_rv(syncp->parent, ret), 0);
    
    plcb_ret_set_err(syncp->parent, ret, err);
    
    if(err == LIBCOUCHBASE_SUCCESS && nvalue) {
        plcb_ret_set_strval(
            syncp->parent, ret, value, nvalue, flags, cas);
    }
    signal_done(syncp);
}

void plcb_callback_storage(
    libcouchbase_t instance,
    const void *cookie,
    libcouchbase_storage_t op,
    libcouchbase_error_t err,
    const void *key, size_t nkey,
    uint64_t cas) 
{
    PLCB_sync_t *syncp = plcb_sync_cast(cookie);
    plcb_ret_set_err(syncp->parent, syncp->ret, err);
    if(err == LIBCOUCHBASE_SUCCESS) {
        plcb_ret_set_cas(syncp->parent, syncp->ret, &cas);
    }
    signal_done(syncp);
}

static void arithmetic_callback(
    libcouchbase_t instance, const void *cookie,
    libcouchbase_error_t err, const void *key, size_t nkey,
    uint64_t value, uint64_t cas)
{
    PLCB_sync_t *syncp = plcb_sync_cast(cookie);
    plcb_ret_set_err(syncp->parent, syncp->ret, err);
    if(err == LIBCOUCHBASE_SUCCESS) {
        plcb_ret_set_numval(syncp->parent, syncp->ret, value, cas);
    }
    signal_done(syncp);
}


void plcb_callback_error(
    libcouchbase_t instance,
    libcouchbase_error_t err,
    const char *errinfo) 
{
    PLCB_t *object;
    object = (PLCB_t*)libcouchbase_get_cookie(instance);
    plcb_errstack_push(object, err, errinfo);
}

#ifdef PLCB_HAVE_CONNFAIL
void plcb_callback_connfail(
    libcouchbase_t instance,
    int conn_errno,
    const char *hostname,
    const char *port,
    libcouchbase_retry_t *retry_param)
{
    warn("Error in connecting to %s:%s", hostname, port);
    *retry_param = LIBCOUCHBASE_RETRY_BAIL;
}
#endif

/*Common callback for key-only operations*/
static void keyop_callback(
    libcouchbase_t instance, const void *cookie,
    libcouchbase_error_t err,
    const void *key, size_t nkey)
{
    plcb_callback_get(instance, cookie, err, key, nkey,
                      NULL, 0, 0, 0);
}

static void keyop_multi_callback(
    libcouchbase_t instance, const void *cookie,
    libcouchbase_error_t err,
    const void *key, size_t nkey)
{
    plcb_callback_multi_get(instance, cookie, err, key, nkey,
                            NULL, 0, 0, 0);
}

static void stat_callback(
    libcouchbase_t instance, const void *cookie,
    const char *server,
    libcouchbase_error_t err,
    const void *stat_key, size_t nkey,
    const void *bytes, size_t nbytes)
{
    PLCB_t *object;
    SV *server_sv, *data_sv, *key_sv;
    dSP;
    
    object = (PLCB_t*)libcouchbase_get_cookie(instance);
    
    if(stat_key == NULL && server == NULL) {
        PLCB_sync_t sync;
        sync.parent = object;
        object->npending = 1;
        signal_done(&sync);
        return;
    }
    
    server_sv = newSVpvn(server, strlen(server));
    if(nkey) {
        key_sv = newSVpvn(stat_key, nkey);
    } else {
        key_sv = newSVpvn("", 0);
    }
    
    if(nbytes) {
        data_sv = newSVpvn(bytes, nbytes);
    } else {
        data_sv = newSVpvn("", 0);
    }
    
    if(!object->stats_hv) {
        die("We have nothing to write our stats to!");
    }
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc((SV*)object->stats_hv)));
    XPUSHs(sv_2mortal(server_sv));
    XPUSHs(sv_2mortal(key_sv));
    XPUSHs(sv_2mortal(data_sv));
    PUTBACK;
    
    call_pv(PLCB_STATS_SUBNAME, G_DISCARD);
    FREETMPS;
    LEAVE;    
}

void plcb_callbacks_set_multi(PLCB_t *object)
{
    libcouchbase_t instance = object->instance;
    libcouchbase_set_get_callback(instance, plcb_callback_multi_get);
    libcouchbase_set_touch_callback(instance, keyop_multi_callback);
}

void plcb_callbacks_set_single(PLCB_t *object)
{
    libcouchbase_t instance = object->instance;
    libcouchbase_set_get_callback(instance, plcb_callback_get);
    libcouchbase_set_touch_callback(instance, keyop_callback);
}

void plcb_callbacks_setup(PLCB_t *object)
{
    libcouchbase_t instance = object->instance;
    libcouchbase_set_get_callback(instance, plcb_callback_get);
    libcouchbase_set_storage_callback(instance, plcb_callback_storage);
    libcouchbase_set_error_callback(instance, plcb_callback_error);
#ifdef PLCB_HAVE_CONNFAIL
    libcouchbase_set_connfail_callback(instance, plcb_callback_connfail);
#endif

    libcouchbase_set_touch_callback(instance, keyop_callback);
    libcouchbase_set_remove_callback(instance, keyop_callback);
    libcouchbase_set_arithmetic_callback(instance, arithmetic_callback);
    libcouchbase_set_stat_callback(instance, stat_callback);
    
    libcouchbase_set_cookie(instance, object);
}
