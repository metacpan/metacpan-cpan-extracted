#include "perl-couchbase-async.h"
#include "plcb-util.h"

#define _mk_common_vars(selfsv, v_instance, v_base, v_async) \
    if( (!SvROK(selfsv)) || (!SvIOK(SvRV(selfsv))) ) \
        die("Passed a bad object!"); \
    v_async = NUM2PTR(PLCBA_t*, SvIV(SvRV(selfsv))); \
    v_base = &(v_async->base); \
    v_instance = v_base->instance;

static inline void av2request(
    PLCBA_t *async, PLCBA_cmd_t cmd,
    AV *reqav, struct PLCBA_request_st *request)
{
    #define _fetch_nonull(idx) \
        ((tmpsv = av_fetch(reqav, idx, 0)) && SvTYPE(*tmpsv) != SVt_NULL)
    #define _fetch_assert(idx, diemsg) \
        if((tmpsv = av_fetch(reqav, idx, 0)) == NULL) { die(diemsg); }
    
    #define _extract_exp() \
        request->exp = 0; \
        if((_fetch_nonull(PLCBA_REQIDX_EXP)) && SvIOK(*tmpsv) \
            && SvUV(*tmpsv) > 0) \
                { \
                    UV utmp = SvUV(*tmpsv); \
                    PLCB_UEXP2EXP((request->exp), utmp, 0); \
                }
    
    SV **tmpsv;
    STRLEN dummy;
    char *dummystr;
    uint64_t *dummy_cas;
    
    if(plcba_cmd_needs_key(cmd)) {
        _fetch_assert(PLCBA_REQIDX_KEY, "Expected key but none passed");
        plcb_get_str_or_die(*tmpsv, request->key, request->nkey, "key");
    }

    _extract_exp();
    
    if(plcba_cmd_needs_strval(cmd)) {
        _fetch_assert(PLCBA_REQIDX_VALUE, "Expected value but none passed");
        request->value = *tmpsv;
        request->nvalue = SvCUR(*tmpsv);
        
        if(!request->nvalue) {
            die("Got zero-length value");
        }
        
        
        if(plcba_cmd_needs_conversion(cmd)) {
            request->has_conversion = 1;
            plcb_convert_storage(&(async->base),
                                 &(request->value), &(request->nvalue),
                                 &(request->store_flags));
        }
    } else if(cmd == PLCBA_CMD_ARITHMETIC) {
        if( (tmpsv = av_fetch(reqav, PLCBA_REQIDX_ARITH_DELTA, 0)) == NULL) {
            die("Arithmetic operation requested but no value specified");
        }
        request->arithmetic.delta = plcb_sv_to_64(*tmpsv);
        
        if( _fetch_nonull(PLCBA_REQIDX_ARITH_INITIAL) ) {
            request->arithmetic.initial = plcb_sv_to_u64(*tmpsv);
            request->arithmetic.create = 1;
        } else {
            request->arithmetic.create = 0;
        }
    }
    
    if( _fetch_nonull(PLCBA_REQIDX_CAS) ) {
        //warn("Have CAS. Setting..");
        plcb_cas_from_sv(*tmpsv, dummy_cas, dummy);
        request->cas = *dummy_cas;
    } else {
        request->cas = 0;
    }
#undef _fetch_nonull
#undef _fetch_assert
#undef _extract_exp
}

static inline libcouchbase_storage_t
async_cmd_to_storop(PLCBA_cmd_t cmd)
{
    switch(cmd) {
    case PLCBA_CMD_SET:
        return LIBCOUCHBASE_SET;
    case PLCBA_CMD_ADD:
        return LIBCOUCHBASE_ADD;
    case PLCBA_CMD_APPEND:
        return LIBCOUCHBASE_APPEND;
    case PLCBA_CMD_PREPEND:
        return LIBCOUCHBASE_PREPEND;
    case PLCBA_CMD_REPLACE:
        return LIBCOUCHBASE_REPLACE;
    default:
        die("Unknown command");
        return LIBCOUCHBASE_REPLACE; /*make compiler happy*/
    }
}

/*single error for single operation on a cookie*/
#define error_single plcba_callback_notify_err

/*single error for multiple operations on a cookie*/
static inline void
error_true_multi(
    PLCBA_t *async,
    PLCBA_cookie_t *cookie,
    size_t num_keys,
    const char **keys, size_t *nkey,
    libcouchbase_error_t err)
{
    int i;
    for(i = 0; i < num_keys; i++) {
        error_single(async, cookie, keys[i], nkey[i], err);
    }
}

/*multiple errors for multiple operations on a cookie*/
static inline void
error_pseudo_multi(
    PLCBA_t *async,
    PLCBA_cookie_t *cookie,
    AV *reqlist,
    libcouchbase_error_t *errors)
{
    int i, idx_max;
    AV *reqav;
    libcouchbase_error_t errtmp;
    SV **tmpsv;
    
    idx_max = av_len(reqlist);
    for(i = 0; i <= idx_max; i++) {
        if(errors[i] == LIBCOUCHBASE_SUCCESS) {
            continue;
        }
        reqav = (AV*)*(av_fetch(reqlist, i, 0));
        tmpsv = av_fetch(reqav, PLCBA_REQIDX_KEY, 0);
        error_single(async, cookie, SvPVX_const(*tmpsv), SvLEN(*tmpsv),
                     errors[i]);
    }
}

void
PLCBA_request(
    SV *self,
    int cmd, int reqtype,
    SV *callcb, SV *cbdata, int cbtype,
    AV *params)
{
    PLCBA_cmd_t cmdtype;
    struct PLCBA_request_st r;
    
    PLCBA_t *async;
    libcouchbase_t instance;
    PLCB_t *base;
    AV *reqav;
    
    PLCBA_cookie_t *cookie;
    int nreq, i;
    libcouchbase_error_t *errors;
    int errcount;
    int has_conversion;
    
    SV **tmpsv;
    
    time_t *multi_exp;
    void **multi_key;
    size_t *multi_nkey;
    
    libcouchbase_error_t err;
    libcouchbase_storage_t storop;
    
    _mk_common_vars(self, instance, base, async);
    
    Newxz(cookie, 1, PLCBA_cookie_t);
    if(SvTYPE(callcb) == SVt_NULL) {
        die("Must have callback for asynchronous request");
    }
    
    if(reqtype == PLCBA_REQTYPE_MULTI) {
        nreq = av_len(params) + 1;
        if(!nreq) {
            die("No requests specified");
        }
    } else {
        nreq = 1;
    }
    
    cookie->callcb = callcb; SvREFCNT_inc(callcb);
    cookie->cbdata = cbdata; SvREFCNT_inc(cbdata);
    cookie->cbtype = cbtype;
    cookie->results = newHV();
    cookie->parent = async;
    cookie->remaining = nreq;
    
    /*pseudo-multi system:
     
     Most commands do not have a libcouchbase-level 'multi' implementation, but
     nevertheless it's more efficient to allow a 'multi' option from Perl because
     sub and xsub overhead is very expensive.
     
     Each operation defines a macro '_do_cbop' which does the following:
        1) call the libcouchbase api function appropriate for that operation
        2) set the function variable 'err' to the error which ocurred.
        
    the predefined pseudo_perform macro does the rest by doing the following:
        1) check to see if the request is multiple or single
        in the case of multiple requests, it:
            I) fetches the current request AV
            II) ensures the request is valid and defined
            III) extracts the information from the request into our request_st
                structure named 'r'
            IV) calls the locally-defined _do_cbop (which sets the error)
            V) checks the current value of 'err', if it is not a success, the
                error counter is incremented
            VI) when the loop has terminated, the error counter is checked again,
                and if it is greater than zero, the error dispatcher is called
        in the case of a single request, it:
            I) treats 'params' as the request AV
            II) passes the AV to av2request,
            III) calls _do_cbop once, and checks for errors
            IV) if there is an erorr, the dispatcher is called     
    */
    
    #define _fetch_assert(idx) \
        if((tmpsv = av_fetch(params, idx, 0)) == NULL) { \
            die("Null request found in request list"); \
        } \
        if(!SvROK(*tmpsv)) { \
            die("Expected reference type in parameter list."); \
        } \
        av2request(async, cmd, (AV*)(SvRV(*tmpsv)), &r);
        
    #define pseudo_multi_begin \
        Newxz(errors, nreq, libcouchbase_error_t); \
        errcount = 0;
    #define pseudo_multi_maybe_add \
        if( (errors[i] = err) != LIBCOUCHBASE_SUCCESS ) \
            errcount++;
    #define pseudo_multi_end \
        if(errcount) \
            error_pseudo_multi(async, params, errors, cookie); \
        Safefree(errors);
    
    #define pseudo_perform \
        if(reqtype == PLCBA_REQTYPE_MULTI) { \
            pseudo_multi_begin; \
            for(i = 0; i < nreq; i++) { \
                _fetch_assert(i); \
                _do_cbop(); \
                pseudo_multi_maybe_add; \
            } \
            if(errcount < nreq) { \
                libcouchbase_wait(instance); \
            } \
        } else { \
            av2request(async, cmd, params, &r); \
            _do_cbop(); \
            if(err != LIBCOUCHBASE_SUCCESS) { \
                warn("Key %s did not return OK (%d)", r.key, err); \
                error_single(async, cookie, r.key, r.nkey, err); \
            } else { \
                libcouchbase_wait(instance); \
            } \
        } \
    
    switch(cmd) {
        
    case PLCBA_CMD_GET:
    case PLCBA_CMD_TOUCH:
        #define _do_cbop(klist, szlist, explist) \
        if(cmd == PLCBA_CMD_GET) { \
            err = libcouchbase_mget(instance, cookie, nreq, \
                                    (const void* const*)klist, \
                                    (szlist), explist); \
        } else { \
            err = libcouchbase_mtouch(instance, cookie, nreq, \
                                    (const void* const*)klist, \
                                    szlist, explist); \
        }
        
        if(reqtype == PLCBA_REQTYPE_MULTI) {
            Newx(multi_key, nreq, void*);
            Newx(multi_nkey, nreq, size_t);
            Newx(multi_exp, nreq, time_t);
            for(i = 0; i < nreq; i++) {
                _fetch_assert(i);
                multi_key[i] = r.key;
                multi_nkey[i] = r.nkey;
                multi_exp[i] = r.exp;
            }

            _do_cbop(multi_key, multi_nkey, multi_exp);
            if(err != LIBCOUCHBASE_SUCCESS) {
                error_true_multi(
                    async, cookie, nreq, (const char**)multi_key, multi_nkey, err);
            } else {
                libcouchbase_wait(instance);
            }
            Safefree(multi_key);
            Safefree(multi_nkey);
            Safefree(multi_exp);
        } else {
            av2request(async, cmd, params, &r);
            _do_cbop(&(r.key), &(r.nkey), &(r.exp));
            if(err != LIBCOUCHBASE_SUCCESS) {
                error_single(async, cookie, r.key, r.nkey, err);
            } else {
                libcouchbase_wait(instance);
            }
        }
        break;
        #undef _do_cbop

    case PLCBA_CMD_SET:
    case PLCBA_CMD_ADD:
    case PLCBA_CMD_REPLACE:
    case PLCBA_CMD_APPEND:
    case PLCBA_CMD_PREPEND:
        storop = async_cmd_to_storop(cmd);
        //warn("Storop is %x (cmd=%x)", storop, cmd);
        has_conversion = plcba_cmd_needs_conversion(cmd);
        #define _do_cbop() \
            err = libcouchbase_store(instance, cookie, storop, r.key, r.nkey, \
                                    SvPVX(r.value), r.nvalue, r.store_flags, \
                                    r.exp, r.cas); \
            if(has_conversion) { \
                plcb_convert_storage_free(base, r.value, r.store_flags); \
            }
        
        pseudo_perform;
        break;
        #undef _do_cbop
    
    case PLCBA_CMD_ARITHMETIC:
        #define _do_cbop() \
            err = libcouchbase_arithmetic(instance, cookie, r.key, r.nkey, \
                                r.arithmetic.delta, r.exp, \
                                r.arithmetic.create, r.arithmetic.initial);
        pseudo_perform;
        break;
        #undef _do_cbop
    case PLCBA_CMD_REMOVE:
        #define _do_cbop() \
            err = libcouchbase_remove(instance, cookie, r.key, r.nkey, r.cas);
        pseudo_perform;
        break;
        #undef _do_cbop

    default:
        die("Unimplemented!");
    }
    
    #undef _fetch_assert
    #undef pseudo_multi_begin
    #undef pseduo_multi_maybe_add
    #undef pseudo_multi_end
    #undef pseudo_perform
}


static inline void
extract_async_options(PLCBA_t *async, AV *options)
{
    #define _assert_get_cv(idxbase, target, diemsg) \
        if( (tmpsv = av_fetch(options, PLCBA_CTORIDX_ ## idxbase, 0)) == NULL \
            || SvTYPE(*tmpsv) == SVt_NULL) { \
            die("Must have '%s' callback", diemsg); \
        } \
        SvREFCNT_inc(*tmpsv); \
        async->target = *tmpsv;
    
    SV **tmpsv;
    
    _assert_get_cv(CBEVMOD, cv_evmod, "update_event");
    _assert_get_cv(CBERR, cv_err, "error");
    _assert_get_cv(CBWAITDONE, cv_waitdone, "waitdone");
    _assert_get_cv(CBTIMERMOD, cv_timermod, "update_timer");
    
    if( (tmpsv = av_fetch(options, PLCBA_CTORIDX_BLESS_EVENT, 0)) ) {
        if(SvTRUE(*tmpsv)) {
            async->event_stash = gv_stashpv(PLCBA_EVENT_CLASS, 0);
        }
    }
    
    #undef _assert_get_cv
}

SV *
PLCBA_construct(const char *pkg, AV *options)
{
    PLCBA_t *async;
    char *host, *username, *password, *bucket;
    libcouchbase_t instance;
    SV *blessed_obj;
    
    Newxz(async, 1, PLCBA_t);
    
    extract_async_options(async, options);
    
    plcb_ctor_conversion_opts(&async->base, options);
    
    plcb_ctor_cbc_opts(options, &host, &username, &password, &bucket);
    instance = libcouchbase_create(host, username, password, bucket,
                                   plcba_make_io_opts(async));
    
    if(!instance) {
        die("Couldn't create instance!");
    }
    
    plcb_ctor_init_common(&async->base, instance, options);
    plcba_setup_callbacks(async);
    async->base_rv = newRV_inc(newSViv(PTR2IV(&(async->base))));
    
    blessed_obj = newSV(0);
    sv_setiv(newSVrv(blessed_obj, pkg), PTR2IV(async));
    return blessed_obj;
}

/*called from perl when an event arrives*/
void
PLCBA_HaveEvent(const char *pkg, short flags, SV *opaque)
{
    /*TODO: optmize this to take an arrayref, and maybe configure ourselves for
     event loops which have a different calling convention, e.g. POE*/
    
    PLCBA_c_event *cevent;
    //sv_dump(opaque);
    
    cevent = NUM2PTR(PLCBA_c_event*, SvIV(opaque));
    cevent->c.handler(cevent->fd, flags, cevent->c.arg);
}

void
PLCBA_connect(SV *self)
{
    libcouchbase_t instance;
    PLCBA_t *async;
    PLCB_t *base;
    libcouchbase_error_t err;
    
    _mk_common_vars(self, instance, base, async);
    if( (err = libcouchbase_connect(instance)) != LIBCOUCHBASE_SUCCESS) {
        die("Problem with initial connection: %s (%d)",
            libcouchbase_strerror(instance, err), err);
    }
    libcouchbase_wait(instance);
}

void
PLCBA_DESTROY(SV *self)
{
    libcouchbase_t instance;
    PLCBA_t *async;
    PLCB_t *base;
    
    #define _DEC_AND_NULLIFY(fld) \
        if(async->fld) { SvREFCNT_dec(async->fld); async->fld = NULL; }
    
    _DEC_AND_NULLIFY(base_rv);
    _DEC_AND_NULLIFY(cv_evmod);
    _DEC_AND_NULLIFY(cv_timermod);
    _DEC_AND_NULLIFY(cv_err);
    _DEC_AND_NULLIFY(cv_waitdone);
    
    #undef _DEC_AND_NULLIFY
    
    /*cleanup our base object. This will also cause the events to be destroyed*/
    plcb_cleanup(&async->base);
    Safefree(async);
}
