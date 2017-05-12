#include "perl-couchbase.h"

#define MULTI_STACK_ELEM 128

#ifndef mk_instance_vars
#define mk_instance_vars(sv, inst_name, obj_name) \
    if(!SvROK(sv)) { die("self must be a reference"); } \
    obj_name = NUM2PTR(PLCB_t*, SvIV(SvRV(sv))); \
    if(!obj_name) { die("tried to access de-initialized PLCB_t"); } \
    inst_name = obj_name->instance;

#endif

#define _fetch_assert(tmpsv, av, idx, diemsg) \
    if( (tmpsv = av_fetch(av, idx, 0)) == NULL) { \
        die("%s (expected something at %d)", diemsg, idx); \
    }


#define _MULTI_INIT_COMMON(object, ret, nreq, args, now) \
    if( (nreq = av_len(args) + 1) == 0 ) { \
        die("Need at least one spec"); \
    } \
    ret = newHV(); \
    SAVEFREESV(ret); \
    now = time(NULL); \
    object->npending = nreq; \
    av_clear(object->errors);

#define _MAYBE_STACK_ALLOC(syncp, stackp)

#define _SYNC_RESULT_INIT(object, hv, sync) \
    sync.ret = newAV(); \
    hv_store(hv, sync.key, sync.nkey, \
        plcb_ret_blessed_rv(object, sync.ret), 0); \
    sync.parent = object;


#define _exp_from_av(av, idx, nowvar, expvar, tmpsv) \
    if( (tmpsv = av_fetch(av, idx, 0)) && (expvar = SvUV(*tmpsv))) { \
        PLCB_UEXP2EXP(expvar, expvar, nowvar); \
    }

#define _cas_from_av(av, idx, casvar, tmpsv) \
    if( (tmpsv = av_fetch(av, idx, 0)) && SvTRUE(*tmpsv) ) { \
        casvar = plcb_sv_to_u64(*tmpsv); \
    }

#define _MAYBE_SET_IMMEDIATE_ERROR(err, retav, waitvar) \
    if(err == LIBCOUCHBASE_SUCCESS) { waitvar++; } \
    else { \
        plcb_ret_set_err(object, retav, err); \
    }

#define _MAYBE_WAIT(waitvar) \
    if(waitvar) { \
        object->io_ops->run_event_loop(object->io_ops); \
    }

#define _dMULTI_VARS \
    PLCB_t *object; \
    libcouchbase_t instance; \
    libcouchbase_error_t err; \
    int nreq, i; \
    time_t now; \
    HV *ret;

enum {
    MULTI_CMD_GET = 1,
    MULTI_CMD_TOUCH,
    MULTI_CMD_GAT,
    
    MULTI_CMD_SET,
    MULTI_CMD_ADD,
    MULTI_CMD_REPLACE,
    MULTI_CMD_APPEND,
    MULTI_CMD_PREPEND,
    MULTI_CMD_REMOVE,
    MULTI_CMD_CAS,
    
    MULTI_CMD_ARITHMETIC,
    MULTI_CMD_INCR,
    MULTI_CMD_DECR
};    

static inline libcouchbase_storage_t
_cmd2storop(int cmd)
{
    switch(cmd) {
    case MULTI_CMD_SET:
    case MULTI_CMD_CAS:
        return LIBCOUCHBASE_SET;
    case MULTI_CMD_ADD:
        return LIBCOUCHBASE_ADD;
    case MULTI_CMD_REPLACE:
        return LIBCOUCHBASE_REPLACE;
    case MULTI_CMD_APPEND:
        return LIBCOUCHBASE_APPEND;
    case MULTI_CMD_PREPEND:
        return LIBCOUCHBASE_PREPEND;
    default:
        die("Unhandled command %d", cmd);
        return LIBCOUCHBASE_ADD;
    }
}

static SV*
PLCB_multi_get_common(SV *self, AV *args, int cmd)
{
    _dMULTI_VARS
    
    void **keys;
    size_t *sizes;
    time_t *exps;
    SV **tmpsv;
    PLCB_sync_t *syncp;
    
    void *keys_stacked[MULTI_STACK_ELEM];
    size_t sizes_stacked[MULTI_STACK_ELEM];
    time_t exps_stacked[MULTI_STACK_ELEM];
    
    mk_instance_vars(self, instance, object);
    _MULTI_INIT_COMMON(object, ret, nreq, args, now);
    
    syncp = &object->sync;
    syncp->parent = object;
    syncp->ret = (AV*)ret;
    
    if(nreq <= MULTI_STACK_ELEM) {
        keys = keys_stacked;
        sizes = sizes_stacked;
        exps = (cmd == MULTI_CMD_GET) ? NULL : exps_stacked;
    } else {
        Newx(keys, nreq, void*); SAVEFREEPV(keys);
        Newx(sizes, nreq, size_t); SAVEFREEPV(sizes);
        if(cmd == MULTI_CMD_GET) {
            exps = NULL;
        } else {
            Newx(exps, nreq, time_t); SAVEFREEPV(exps);
        } 
    }
    
    for(i = 0; i < nreq; i++) {
        _fetch_assert(tmpsv, args, i, "arguments");
        
        if(SvTYPE(*tmpsv) <= SVt_PV) {
            if(exps) {
                die("This command requires a valid expiry");
            }
            plcb_get_str_or_die(*tmpsv, keys[i], sizes[i], "key");            
        } else {
            AV *argav;
            
            if(SvROK(*tmpsv) == 0 || ( (argav = (AV*)SvRV(*tmpsv))
                                      && SvTYPE(argav) != SVt_PVAV)) {
                die("Expected an array reference");
            }
            _fetch_assert(tmpsv, argav, 0, "missing key");
            
            plcb_get_str_or_die(*tmpsv, keys[i], sizes[i], "key");
            
            if(exps) {
                _fetch_assert(tmpsv, argav, 1, "expiry");
                if(! (exps[i] = SvUV(*tmpsv)) ) {
                    die("expiry of 0 passed. This is not what you want");
                }
            }
        }
    }
    
    plcb_callbacks_set_multi(object);
    
    if(cmd == MULTI_CMD_TOUCH) {
        err = libcouchbase_mtouch(instance, syncp, nreq,
                                  (const void* const*)keys, sizes, exps);
    } else {
        err = libcouchbase_mget(instance, syncp, nreq,
                                (const void* const*)keys, sizes, NULL);
    }
    
    if(err == LIBCOUCHBASE_SUCCESS) {
        object->io_ops->run_event_loop(object->io_ops);
    } else {
        for(i = 0; i < nreq; i++) {
            AV *errav = newAV();
            plcb_ret_set_err(object, errav, err);
            hv_store(ret, keys[i], sizes[i],
                     plcb_ret_blessed_rv(object, errav), 0);
        }
    }
    
    plcb_callbacks_set_single(object);
    
    return newRV_inc( (SV*)ret);
}

static SV*
PLCB_multi_set_common(SV *self, AV *args, int cmd)
{
    _dMULTI_VARS
    PLCB_sync_t *syncs = NULL;
    PLCB_sync_t syncs_stacked[MULTI_STACK_ELEM];
    libcouchbase_storage_t storop;
    int nwait;
    
    mk_instance_vars(self, instance, object);
    
    _MULTI_INIT_COMMON(object, ret, nreq, args, now);
    
    if(nreq <= MULTI_STACK_ELEM) {
        syncs = syncs_stacked;
    } else {
        Newx(syncs, nreq, PLCB_sync_t);
        SAVEFREEPV(syncs);
    }
    
    nwait = 0;
    storop = _cmd2storop(cmd);
    
    for(i = 0; i < nreq; i++) {
        AV *argav;
        SV **tmpsv;
        char *value;
        STRLEN nvalue;
        SV *value_sv = NULL;
        uint32_t store_flags = 0;
        uint64_t cas = 0;
        time_t exp = 0;
        
        _fetch_assert(tmpsv, args, i, "empty argument in spec");
        
        if (SvROK(*tmpsv) == 0 || ( ((argav = (AV*)SvRV(*tmpsv)) &&
                                    SvTYPE(argav) != SVt_PVAV))) {
            die("Expected array reference");
        }
        
        _fetch_assert(tmpsv, argav, 0, "expected key");
        plcb_get_str_or_die(*tmpsv, syncs[i].key, syncs[i].nkey, "key");
        _fetch_assert(tmpsv, argav, 1, "expected_value");
        plcb_get_str_or_die(*tmpsv, value, nvalue, "value");
        value_sv = *tmpsv;
        
        switch(cmd) {
        case MULTI_CMD_SET:
        case MULTI_CMD_ADD:
        case MULTI_CMD_REPLACE:
        case MULTI_CMD_APPEND:
        case MULTI_CMD_PREPEND:
            _exp_from_av(argav, 2, now, exp, tmpsv);
            _cas_from_av(argav, 3, cas, tmpsv);
            break;
        case MULTI_CMD_CAS:
            _fetch_assert(tmpsv, argav, 2, "Expected cas");
            _cas_from_av(argav, 2, cas, tmpsv);
            _exp_from_av(argav, 3, now, exp, tmpsv);
            break;
        default:
            die("Unhandled command %d", cmd);
        }
        
        _SYNC_RESULT_INIT(object, ret, syncs[i]);

        plcb_convert_storage(object, &value_sv, &nvalue, &store_flags);
                
        err = libcouchbase_store(
            instance, &syncs[i], storop, syncs[i].key, syncs[i].nkey,
            SvPVX(value_sv), nvalue, store_flags, exp, cas);
        
        plcb_convert_storage_free(object, value_sv, store_flags);
        
        _MAYBE_SET_IMMEDIATE_ERROR(err, syncs[i].ret, nwait);
        
    }
    _MAYBE_WAIT(nwait);
    return newRV_inc( (SV*)ret);
}

static SV*
PLCB_multi_arithmetic_common(SV *self, AV *args, int cmd)
{
    _dMULTI_VARS
    
    PLCB_sync_t *syncs;
    PLCB_sync_t syncs_stacked[MULTI_STACK_ELEM];
    int nwait = 0;
    
    mk_instance_vars(self, instance, object);
    _MULTI_INIT_COMMON(object, ret, nreq, args, now);
        
    if(nreq <= MULTI_STACK_ELEM) {
        syncs = syncs_stacked;
    } else {
        Newx(syncs, nreq, PLCB_sync_t);
        SAVEFREEPV(syncs);
    }
    
    for(i = 0; i < nreq; i++) {
        AV *argav;
        SV **tmpsv;
        time_t exp = 0;
        int64_t delta = 1;
        uint64_t initial = 0;
        int do_create = 0;
        
        #define _do_arith_simple(only_sv) \
            plcb_get_str_or_die(only_sv, syncs[i].key, syncs[i].nkey, "key"); \
            delta = (cmd == MULTI_CMD_DECR) ? (-delta) : delta; \
            goto GT_CBC_CMD;
        
        _fetch_assert(tmpsv, args, i, "empty argument in spec");
        
        
        if(SvTYPE(*tmpsv) == SVt_PV) {
            /*simple key*/
            if(cmd == MULTI_CMD_ARITHMETIC) {
                die("Expected array reference!");
            }
            _do_arith_simple(*tmpsv);
        } else {
            if(SvROK(*tmpsv) == 0 || ( (argav = (AV*)SvRV(*tmpsv)) &&
                                      SvTYPE(argav) != SVt_PVAV)) {
                die("Expected ARRAY reference");
            }
        }
        
        _fetch_assert(tmpsv, argav, 0, "expected key");
        
        if(av_len(argav) == 0) {
            _do_arith_simple(*tmpsv);
        } else {
            plcb_get_str_or_die(*tmpsv, syncs[i].key, syncs[i].nkey, "key");
        }
        
        _fetch_assert(tmpsv, argav, 1, "expected delta");
        delta = SvIV(*tmpsv);
        delta = (cmd == MULTI_CMD_DECR) ? (-delta) : delta;
        
        if(cmd != MULTI_CMD_ARITHMETIC) {
            goto GT_CBC_CMD;
        }
        
        /*fetch initial value here*/
        if( (tmpsv = av_fetch(argav, 2, 0)) && SvTYPE(*tmpsv) != SVt_NULL ) {
            initial = SvUV(*tmpsv);
            do_create = 1;
        }
        
        if ( (tmpsv = av_fetch(argav, 3, 0)) && (exp = SvUV(*tmpsv)) ) {
            PLCB_UEXP2EXP(exp, exp, now);
        }
        
        GT_CBC_CMD:
        
        _SYNC_RESULT_INIT(object, ret, syncs[i]);
        err = libcouchbase_arithmetic(instance, &syncs[i], syncs[i].key,
                                      syncs[i].nkey,
                                      delta, exp, do_create, initial);
        _MAYBE_SET_IMMEDIATE_ERROR(err, syncs[i].ret, nwait);
        
    }
    
    _MAYBE_WAIT(nwait);            
    return newRV_inc( (SV*)ret);
}

static SV*
PLCB_multi_remove(SV *self, AV *args)
{
    _dMULTI_VARS
    PLCB_sync_t *syncs = NULL;
    PLCB_sync_t syncs_stacked[MULTI_STACK_ELEM];
    
    int nwait = 0;
    
    mk_instance_vars(self, instance, object);
    _MULTI_INIT_COMMON(object, ret, nreq, args, now);
    
    if(nreq < MULTI_STACK_ELEM) {
        syncs = syncs_stacked;
    } else {
        Newx(syncs, nreq, PLCB_sync_t);
        SAVEFREEPV(syncs);
    }
    
    for(i = 0; i < nreq; i++) {
        AV *argav;
        SV **tmpsv;
        uint64_t cas = 0;
        
        _fetch_assert(tmpsv, args, i, "empty arguments in spec");
        if(SvTYPE(*tmpsv) == SVt_PV) {
            plcb_get_str_or_die(*tmpsv, syncs[i].key, syncs[i].nkey, "key");
        } else {
            if(SvROK(*tmpsv) == 0 || ( (argav = (AV*)SvRV(*tmpsv)) &&
                                      SvTYPE(argav) != SVt_PVAV)) {
                die("Expected ARRAY reference");
            }
            _fetch_assert(tmpsv, argav, 0, "key");
            plcb_get_str_or_die(*tmpsv, syncs[i].key, syncs[i].nkey, "key");
            _cas_from_av(argav, 1, cas, tmpsv);
        }
        
        _SYNC_RESULT_INIT(object, ret, syncs[i]);
        
        err = libcouchbase_remove(instance, &syncs[i],
                                  syncs[i].key, syncs[i].nkey, cas);
        _MAYBE_SET_IMMEDIATE_ERROR(err, syncs[i].ret, nwait);
    }
    _MAYBE_WAIT(nwait);
    return newRV_inc( (SV*)ret );
    
}

static int get_cmd_map[] = {
    MULTI_CMD_GET,
    MULTI_CMD_TOUCH,
    MULTI_CMD_GAT,
};

static int set_cmd_map[] = {
    MULTI_CMD_SET,
    MULTI_CMD_ADD,
    MULTI_CMD_REPLACE,
    MULTI_CMD_APPEND,
    MULTI_CMD_PREPEND,
    MULTI_CMD_CAS
};

static int arith_cmd_map[] = {
    MULTI_CMD_ARITHMETIC,
    MULTI_CMD_INCR,
    MULTI_CMD_DECR
};



#define _MAYBE_MULTI_ARG2(array, always_wrap) \
    if(items == 2 && always_wrap == 0) { \
        array = (AV*)ST(1); \
        if( (SvROK((SV*)array)) && (array = (AV*)SvRV((SV*)array))) { \
            if(SvTYPE(array) < SVt_PVAV) { \
                die("Expected ARRAY reference for arguments"); \
            } \
        } \
    } else if (items > 2 || items == 2 && always_wrap == 1) { \
        array = (AV*)sv_2mortal((SV*)av_make(items - 1, (SP - items + 2))); \
    } else { \
        die("Usage: %s(self, args)", GvNAME(GvCV(cv))); \
    }


#define _MAYBE_MULTI_ARG(array) \
    _MAYBE_MULTI_ARG2(array, 0)


MODULE = Couchbase::Client_multi PACKAGE = Couchbase::Client    PREFIX = PLCB_

PROTOTYPES: DISABLE

SV* PLCB_get_multi(self, ...)
    SV *self
    
    ALIAS:
    touch_multi = 1
    gat_multi = 2
    
    PREINIT:
    int cmd;
    AV *args;
    
    CODE:
    cmd = get_cmd_map[ix];
    _MAYBE_MULTI_ARG(args);
    
    RETVAL = PLCB_multi_get_common(self, args, cmd);
    
    OUTPUT:
    RETVAL
    
SV*
PLCB_set_multi(self, ...)
    SV *self
    
    ALIAS:
    add_multi = 1
    replace_multi = 2
    append_multi = 3
    prepend_multi = 4
    cas_multi = 5
    
    PREINIT:
    int cmd;
    AV *args;
    
    CODE:
    cmd = set_cmd_map[ix];
    _MAYBE_MULTI_ARG2(args, 1);
    RETVAL = PLCB_multi_set_common(self, args, cmd);
    
    OUTPUT:
    RETVAL
    
SV*
PLCB_arithmetic_multi(self, ...)
    SV *self
    
    ALIAS:
    incr_multi = 1
    decr_multi = 2
    
    PREINIT:
    AV *args;
    int cmd;
    
    CODE:
    cmd = arith_cmd_map[ix];
    _MAYBE_MULTI_ARG(args);
    RETVAL = PLCB_multi_arithmetic_common(self, args, cmd);
    
    OUTPUT:
    RETVAL

SV*
PLCB_remove_multi(self, ...)
    SV *self
    
    ALIAS:
    delete_multi = 1
    
    PREINIT:
    AV *args;
    
    CODE:
    _MAYBE_MULTI_ARG(args);
    RETVAL = PLCB_multi_remove(self, args);
    
    OUTPUT:
    RETVAL
    
