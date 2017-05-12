#include "perl-couchbase.h"
#include "plcb-util.h"
#include <libcouchbase/vbucket.h>

static int PLCB_connect(PLCB_t* self);

void plcb_cleanup(PLCB_t *object)
{
    plcb_opctx_clear(object);
    SvREFCNT_dec(object->cachectx);

    if (object->instance) {
        lcb_destroy(object->instance);
        object->instance = NULL;
    }

    #define _free_cv(fld) if (object->fld) { SvREFCNT_dec(object->fld); object->fld = NULL; }
    _free_cv(cv_serialize); _free_cv(cv_deserialize);
    _free_cv(cv_jsonenc); _free_cv(cv_jsondec);
    _free_cv(cv_customenc); _free_cv(cv_customdec);
    #undef _free_cv
}

/*Construct a new libcouchbase object*/
static SV *
PLCB_construct(const char *pkg, HV *hvopts)
{
    lcb_t instance;
    lcb_error_t err;
    struct lcb_create_st cr_opts = { 0 };

    SV *blessed_obj;
    SV *iops_impl = NULL;
    SV *conncb = NULL;

    PLCB_t *object;
    plcb_OPTION options[] = {
        PLCB_KWARG("connstr", CSTRING, &cr_opts.v.v3.connstr),
        PLCB_KWARG("password", CSTRING, &cr_opts.v.v3.passwd),
        PLCB_KWARG("io", SV, &iops_impl),
        PLCB_KWARG("on_connect", CV, &conncb),
        { NULL }
    };

    cr_opts.version = 3;
    plcb_extract_args((SV*)hvopts, options);

    if (iops_impl && SvTYPE(iops_impl) != SVt_NULL) {
        plcb_IOPROCS *ioprocs;
        /* Validate */
        if (!sv_derived_from(iops_impl, PLCB_IOPROCS_CLASS)) {
            die("io must be a valid " PLCB_IOPROCS_CLASS);
        }
        if (!conncb) {
            die("Connection callback must be specified in async mode");
        }
        ioprocs = NUM2PTR(plcb_IOPROCS* , SvIV(SvRV(iops_impl)));
        cr_opts.v.v3.io = ioprocs->iops_ptr;
    }

    err = lcb_create(&instance, &cr_opts);

    if (!instance) {
        die("Failed to create instance: %s", lcb_strerror(NULL, err));
    }

    Newxz(object, 1, PLCB_t);
    lcb_set_cookie(instance, object);
    object->instance = instance;

    if (iops_impl) {
        object->ioprocs = newRV_inc(SvRV(iops_impl));
        object->conncb = newRV_inc(SvRV(conncb));
        object->async = 1;
    }

    plcb_callbacks_setup(object);

    #define get_stash_assert(stashname, target) \
        if (! (object->target = gv_stashpv(stashname, 0)) ) { \
            die("Couldn't load '%s'", stashname); \
        }

    get_stash_assert(PLCB_RET_CLASSNAME, ret_stash);
    get_stash_assert(PLCB_OPCTX_CLASSNAME, opctx_sync_stash);
    get_stash_assert(PLCB_VIEWHANDLE_CLASS, view_stash);
    get_stash_assert(PLCB_N1QLHANDLE_CLASS, n1ql_stash);

    blessed_obj = newSV(0);
    sv_setiv(newSVrv(blessed_obj, PLCB_BKT_CLASSNAME), PTR2IV(object));

    object->selfobj = SvRV(blessed_obj);
    return blessed_obj;
}

static int
PLCB_connect(PLCB_t *object)
{
    lcb_error_t err;
    lcb_t instance = object->instance;

    if (object->connected) {
        warn("Already connected");
        return 1;

    } else {
        if ((err = lcb_connect(instance)) != LCB_SUCCESS) {
            goto GT_ERR;
        }
        if (object->async) {
            return 0;
        }

        lcb_wait(instance);
        if ((err = lcb_get_bootstrap_status(instance)) != LCB_SUCCESS) {
            goto GT_ERR;
        }
        object->connected = 1;
        return 1;
    }

    GT_ERR:
    die("Couldn't connect: 0x%x (%s)", err, lcb_strerror(NULL, err));
    return 0;
}

static void
get_converter_pointers(PLCB_t *object, int type, SV ***cv_encode, SV ***cv_decode)
{
    if (type == PLCB_CONVERTERS_CUSTOM) {
        *cv_encode = &object->cv_customenc;
        *cv_decode = &object->cv_customdec;
    } else if (type == PLCB_CONVERTERS_JSON) {
        *cv_encode = &object->cv_jsonenc;
        *cv_decode = &object->cv_jsondec;
    } else if (type == PLCB_CONVERTERS_STORABLE) {
        *cv_encode = &object->cv_serialize;
        *cv_decode = &object->cv_deserialize;
    } else {
        die("Unrecognized converter type %d", type);
    }
}


/* lcb_cntl() APIs */
static void
PLCB__cntl_set(PLCB_t *object, int setting, int type, SV *value)
{
    lcb_error_t err;
    void *p = NULL;
    union {
        float floatval;
        int intval;
        unsigned uintval;
        size_t sizeval;
        uint32_t u32val;
    } u;
    p = &u;

    if (!SvOK(value)) {
        if (SvTYPE(value) == SVt_PVMG && SvREFCNT(value) == 1) {
            /* Workaround for local $cb->settings->{foo} with older perls */
            return;
        }
        die("Passed empty value");
    }

    if (type == PLCB_SETTING_INT) {
        u.intval = SvIV(value);
    } else if (type == PLCB_SETTING_UINT) {
        u.uintval = SvUV(value);
    } else if (type == PLCB_SETTING_U32) {
        u.u32val = SvUV(value);
    } else if (type == PLCB_SETTING_SIZE) {
        u.sizeval = SvUV(value);
    } else if (type == PLCB_SETTING_TIMEOUT) {
        u.u32val = SvNV(value) * 1000000;
    } else if (type == PLCB_SETTING_STRING) {
        p = SvPV_nolen(value);
    } else {
        die("Unrecognized type code %d", type);
    }
    err = lcb_cntl(object->instance, LCB_CNTL_SET, setting, p);
    if (err != LCB_SUCCESS) {
        warn("Failed to set setting=%d, type=%d", setting, type);
    }
}

static SV *
PLCB__cntl_get(PLCB_t *object, int setting, int type)
{
    lcb_error_t err;
    union {
        float floatval;
        int intval;
        unsigned uintval;
        size_t sizeval;
        uint32_t u32val;
        const char *strval;
    } u;

    memset(&u, 0, sizeof u);

    err = lcb_cntl(object->instance, LCB_CNTL_GET, setting, &u);
    if (err != LCB_SUCCESS) {
        warn("Couldn't get setting=%d, type=%d: %s", setting, type, lcb_strerror(NULL, err));
        SvREFCNT_inc(&PL_sv_undef);
        return &PL_sv_undef;
    }

    if (type == PLCB_SETTING_INT) {
        return newSViv(u.intval);
    } else if (type == PLCB_SETTING_UINT) {
        return newSVuv(u.uintval);
    } else if (type == PLCB_SETTING_U32) {
        return newSVuv(u.u32val);
    } else if (type == PLCB_SETTING_SIZE) {
        return newSVuv(u.sizeval);
    } else if (type == PLCB_SETTING_TIMEOUT) {
        return newSVnv((float)u.u32val / 1000000.0);
    } else if (type == PLCB_SETTING_STRING) {
        return newSVpv(u.strval ? u.strval : "", 0);
    } else {
        die("Unknown type %d", type);
        return NULL;
    }
}

#define dPLCB_INPUTS \
    SV *options = &PL_sv_undef; SV *ctx = &PL_sv_undef;

#define FILL_EXTRA_PARAMS() \
    if (items > 4) { croak_xs_usage(cv, "bucket, doc [, options, ctx ]"); } \
    if (items >= 3) { options = ST(2); } \
    if (items >= 4) { ctx = ST(3); }

MODULE = Couchbase PACKAGE = Couchbase::Bucket    PREFIX = PLCB_

PROTOTYPES: DISABLE

SV *
PLCB_construct(const char *pkg, HV *options)

int
PLCB_connect(PLCB_t *object)

SV *
PLCB__codec_common(PLCB_t *object, int type, ...)
    ALIAS:
    _encoder = 1
    _decoder = 2

    PREINIT:
    SV **cv_encode = NULL, **cv_decode = NULL, **target = NULL;

    CODE:
    get_converter_pointers(object, type, &cv_encode, &cv_decode);
    target = ix == 1 ? cv_encode : cv_decode;

    if (items == 2) {
        if (*target) {
            RETVAL = newRV_inc(*target);
        } else {
            RETVAL = &PL_sv_undef; SvREFCNT_inc(&PL_sv_undef);
        }
    } else {
        SV *tmpsv = ST(2);
        SV *to_decref = *target;

        RETVAL = &PL_sv_undef;
        if (tmpsv != &PL_sv_undef) {
            if (SvROK(tmpsv) == 0 || SvTYPE(SvRV(tmpsv)) != SVt_PVCV) {
                die("Argument passed must be undef or CODE reference");
            }
            *target = SvRV(tmpsv);
            SvREFCNT_inc(*target);
        } else {
            *target = NULL;
        }
        SvREFCNT_dec(to_decref);
        SvREFCNT_inc(RETVAL);
    }
    OUTPUT: RETVAL

void
PLCB__cntl_set(PLCB_t *object, int setting, int type, SV *value)

SV *
PLCB__cntl_get(PLCB_t *object, int setting, int type)

void
PLCB_DESTROY(PLCB_t *object)
    CODE:
    plcb_cleanup(object);
    Safefree(object);

SV *
PLCB__get(PLCB_t *self, SV *doc, ...)
    ALIAS:
    get = PLCB_CMD_GET
    get_and_touch = PLCB_CMD_GAT
    get_and_lock = PLCB_CMD_LOCK
    touch = PLCB_CMD_TOUCH

    PREINIT:
    plcb_SINGLEOP opinfo = { ix };
    dPLCB_INPUTS

    CODE:
    FILL_EXTRA_PARAMS()

    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    RETVAL = PLCB_op_get(self, &opinfo);
    OUTPUT: RETVAL
    
SV *
PLCB__store(PLCB_t *self, SV *doc, ...)
    ALIAS:
    upsert = PLCB_CMD_SET
    insert = PLCB_CMD_ADD
    replace = PLCB_CMD_REPLACE
    append_bytes = PLCB_CMD_APPEND
    prepend_bytes = PLCB_CMD_PREPEND

    PREINIT:
    plcb_SINGLEOP opinfo = { 0 };
    dPLCB_INPUTS
    
    CODE:
    FILL_EXTRA_PARAMS()
    opinfo.cmdbase = ix;
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);

    
    RETVAL = PLCB_op_set(self, &opinfo);
    OUTPUT: RETVAL
    
SV *
PLCB_remove(PLCB_t *self, SV *doc, ...)
    PREINIT:
    plcb_SINGLEOP opinfo = { PLCB_CMD_REMOVE };
    dPLCB_INPUTS

    CODE:
    FILL_EXTRA_PARAMS()
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    
    RETVAL = PLCB_op_remove(self, &opinfo);
    OUTPUT: RETVAL


SV *
PLCB_unlock(PLCB_t *self, SV *doc, ...)
    PREINIT:
    plcb_SINGLEOP opinfo = { PLCB_CMD_UNLOCK };
    dPLCB_INPUTS

    CODE:
    FILL_EXTRA_PARAMS()
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    RETVAL = PLCB_op_unlock(self, &opinfo);
    OUTPUT: RETVAL

SV *
PLCB_counter(PLCB_t *self, SV *doc, ...)
    PREINIT:
    plcb_SINGLEOP opinfo = { PLCB_CMD_COUNTER };
    dPLCB_INPUTS;
    CODE:
    FILL_EXTRA_PARAMS()
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    RETVAL = PLCB_op_counter(self, &opinfo);
    OUTPUT: RETVAL


SV *
PLCB_endure(PLCB_t *self, SV *doc, ...)
    PREINIT:
    plcb_SINGLEOP opinfo = { PLCB_CMD_ENDURE };
    dPLCB_INPUTS;
    CODE:
    FILL_EXTRA_PARAMS()
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    RETVAL = PLCB_op_endure(self, &opinfo);
    OUTPUT: RETVAL


SV *
PLCB__stats_common(PLCB_t *self, SV *doc, ...)
    ALIAS:
    _stats = PLCB_CMD_STATS
    _keystats = PLCB_CMD_KEYSTATS

    PREINIT:
    plcb_SINGLEOP opinfo = { ix };
    dPLCB_INPUTS

    CODE:
    FILL_EXTRA_PARAMS()
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    RETVAL = PLCB_op_stats(self, &opinfo);
    OUTPUT: RETVAL


SV *
PLCB__observe(PLCB_t *self, SV *doc, ...)
    PREINIT:
    plcb_SINGLEOP opinfo = { PLCB_CMD_OBSERVE };
    dPLCB_INPUTS
    CODE:
    FILL_EXTRA_PARAMS()
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    RETVAL = PLCB_op_observe(self, &opinfo);
    OUTPUT: RETVAL

SV *
PLCB__http(PLCB_t *self, SV *doc, ...)
    PREINIT:
    plcb_SINGLEOP opinfo = { PLCB_CMD_HTTP };
    dPLCB_INPUTS
    CODE:
    FILL_EXTRA_PARAMS()
    plcb_opctx_initop(&opinfo, self, doc, ctx, options);
    RETVAL = PLCB_op_http(self, &opinfo);
    OUTPUT: RETVAL

SV *
PLCB_cluster_nodes(PLCB_t *object)
    PREINIT:
    AV *retav;
    const char * const * server_nodes;

    CODE:
    server_nodes = lcb_get_server_list(object->instance);
    retav = newAV();
    RETVAL = newRV_noinc((SV*)retav);

    if (server_nodes) {
        const char * const *cur_node;
        for (cur_node = server_nodes; *cur_node; cur_node++) {
            av_push(retav, newSVpv(*cur_node, 0));
        }
    }

    OUTPUT: RETVAL
    
lcbvb_CONFIG *
PLCB_get_bucket_config(PLCB_t *object)
    PREINIT:
    lcbvb_CONFIG *orig, *cp;
    lcb_error_t err;
    char *tmpstr;

    CODE:
    err = lcb_cntl(object->instance, LCB_CNTL_GET, LCB_CNTL_VBCONFIG, &orig);
    if (err != LCB_SUCCESS) {
        die("Couldn't get config: %s", lcb_strerror(NULL, err));
    }
    if (orig == NULL) {
        die("Client does not have a config yet");
    }
    tmpstr = lcbvb_save_json(orig);
    if (!tmpstr) {
        die("Couldn't get JSON dump");
    }
    cp = lcbvb_create();
    if (!cp) {
        free(tmpstr);
        die("Couldn't allocate new config");
    }
    if (0 != lcbvb_load_json(cp, tmpstr)) {
        const char *err = lcbvb_get_error(cp);
        free(tmpstr);
        lcbvb_destroy(cp);
        die("Couldn't load new config: %s", err);
    }
    free(tmpstr);
    RETVAL = cp;
    OUTPUT: RETVAL

SV *
PLCB_batch(PLCB_t *object)
    PREINIT:
    SV *ctxrv = NULL;

    CODE:
    ctxrv = plcb_opctx_new(object, 0);
    RETVAL = newRV_inc(SvRV(ctxrv));

    lcb_sched_enter(object->instance);
    OUTPUT: RETVAL

SV *
PLCB_durability_batch(PLCB_t *object, SV *options)
    PREINIT:
    int persist_to = 0, replicate_to = 0, is_delete = 0;
    SV *ctxrv = NULL;
    plcb_OPCTX *opctx;
    lcb_error_t err;
    lcb_durability_opts_t dopts = { 0 };
    plcb_OPTION args[] = {
        PLCB_KWARG(PLCB_ARG_K_PERSIST, INT, &persist_to),
        PLCB_KWARG(PLCB_ARG_K_REPLICATE, INT, &replicate_to),
        PLCB_KWARG(PLCB_ARG_K_ISDELETE, BOOL, &is_delete),
        { NULL }
    };
    CODE:
    plcb_extract_args(options, args);
    ctxrv = plcb_opctx_new(object, 0);
    RETVAL = newRV_inc(SvRV(ctxrv));
    dopts.v.v0.persist_to = persist_to;
    dopts.v.v0.replicate_to = replicate_to;
    dopts.v.v0.check_delete = is_delete;
    if (replicate_to == -1 || persist_to == -1) {
        dopts.v.v0.cap_max = 1;
    }

    opctx = NUM2PTR(plcb_OPCTX*,SvIVX(SvRV(ctxrv)));
    assert(opctx->multi == NULL);
    opctx->multi = lcb_endure3_ctxnew(object->instance, &dopts, &err);
    if (!opctx->multi) {
        SvREFCNT_dec(RETVAL);
        die("Bad parameters for durability: 0x%x (%s)", err, lcb_strerror(NULL, err));
    }

    OUTPUT: RETVAL

void
PLCB__ctx_clear(PLCB_t *object)
    CODE:
    plcb_opctx_clear(object);


SV *
PLCB_user_data(PLCB_t *object, ...)
    PREINIT:
    CODE:
    if (items == 1) {
        RETVAL = object->udata;
    } else {
        SvREFCNT_dec(object->udata);
        object->udata = ST(1);
        SvREFCNT_inc(object->udata);
        RETVAL = &PL_sv_undef;
    }
    SvREFCNT_inc(RETVAL);
    OUTPUT: RETVAL

int
PLCB_connected(PLCB_t *object)
    CODE:
    RETVAL = object->connected;
    OUTPUT: RETVAL

MODULE = Couchbase PACKAGE = Couchbase::OpContext PREFIX = PLCB_ctx_

void
PLCB_ctx_wait_all(plcb_OPCTX *ctx)
    PREINIT:
    PLCB_t *parent;

    CODE:
    if (!parent) {
        die("Parent context is destroyed");
    }

    if (!parent->curctx) {
        die("Current context is not active");
    }

    if (!ctx->nremaining) {
        return;
    }
    /* Remove the 'wait_one' flag */
    ctx->flags &= ~PLCB_OPCTXf_WAITONE;
    plcb_opctx_submit(parent, ctx);
    lcb_wait3(parent->instance, LCB_WAIT_NOCHECK);


SV *
PLCB_ctx_wait_one(plcb_OPCTX *ctx)
    PREINIT:
    PLCB_t *parent;

    CODE:
    if (!parent) {
        die("Parent context is destroyed");
    }

    if (ctx->u.ctxqueue) {
        RETVAL = av_shift(ctx->u.ctxqueue);
        if (RETVAL != &PL_sv_undef) {
            goto GT_DONE;
        }
    }

    if (!ctx->nremaining) {
        RETVAL = &PL_sv_undef;
        SvREFCNT_inc(&PL_sv_undef);
        goto GT_DONE;
    }

    if (!ctx->u.ctxqueue) {
        ctx->u.ctxqueue = newAV();
    }

    ctx->flags |= PLCB_OPCTXf_WAITONE;
    plcb_opctx_submit(parent, ctx);
    lcb_wait3(parent->instance, LCB_WAIT_NOCHECK);
    RETVAL = av_shift(ctx->u.ctxqueue);

    GT_DONE: ;
    OUTPUT: RETVAL

SV *
PLCB_ctx__cbo(plcb_OPCTX *ctx)
    PREINIT:
    PLCB_t *parent;
    CODE:
    (void)parent;
    RETVAL = newRV_inc(SvRV(ctx->parent));
    OUTPUT: RETVAL

void
PLCB_ctx_set_callback(plcb_OPCTX *ctx, CV *cv)
    PREINIT:
    PLCB_t *parent;
    CODE:
    SvREFCNT_dec(ctx->u.callback);
    ctx->u.callback = newRV_inc((SV*)cv);

SV *
PLCB_ctx_get_callback(plcb_OPCTX *ctx)
    PREINIT:
    PLCB_t *parent;
    CODE:
    if (!ctx->u.callback) {
        RETVAL = &PL_sv_undef;
    } else {
        RETVAL = ctx->u.callback;
    }
    SvREFCNT_inc(RETVAL);
    OUTPUT: RETVAL


void
PLCB_ctx_DESTROY(plcb_OPCTX *ctx)
    PREINIT:
    PLCB_t *parent;
    CODE:

    SvREFCNT_dec(ctx->parent);
    SvREFCNT_dec(ctx->u.ctxqueue);
    SvREFCNT_dec(ctx->docs);
    Safefree(ctx);

MODULE = Couchbase PACKAGE = Couchbase    PREFIX = PLCB_

HV *
PLCB_lcb_version()
    PREINIT:
    lcb_U32 ivers;
    HV *ret;
    const char *tmp;

    CODE:
    ret = newHV();
    tmp = lcb_get_version(&ivers);
    
    (void)hv_stores(ret, "hex", newSVuv(ivers));
    (void)hv_stores(ret, "str", newSVpv(tmp, 0));
    if (lcb_cntl(NULL, LCB_CNTL_GET, LCB_CNTL_CHANGESET, &tmp) == LCB_SUCCESS) {
        (void)hv_stores(ret, "rev", newSVpv(tmp, 0));
    }
    
    RETVAL = ret;
    OUTPUT: RETVAL

IV
PLCB__get_errtype(int code)
    CODE:
    RETVAL = lcb_get_errtype(code);
    OUTPUT: RETVAL

SV *
PLCB_strerror(int code)
    PREINIT:
    const char *msg;
    unsigned len;
    CODE:
    msg = lcb_strerror(NULL, code);
    len = strlen(msg);
    RETVAL = newSVpvn_share(msg, len, 0);
    SvREADONLY_on(RETVAL);
    OUTPUT: RETVAL


SV *
PLCB__viewhandle_new(PLCB_t *obj, \
    const char *view, const char *design, const char *options, int flags)

void
PLCB__viewhandle_fetch(SV *vh)

void
PLCB__viewhandle_stop(SV *vh)

SV *
PLCB__n1qlhandle_new(PLCB_t *parent, lcb_N1QLPARAMS *params, const char *host)


BOOT:
/*XXX: DO NOT MODIFY WHITESPACE HERE. xsubpp is touchy*/
#define PLCB_BOOTSTRAP_DEPENDENCY(bootfunc) \
PUSHMARK(SP); \
mXPUSHs(newSVpv("Couchbase", sizeof("Couchbase")-1)); \
mXPUSHs(newSVpv(XS_VERSION, sizeof(XS_VERSION)-1)); \
PUTBACK; \
bootfunc(aTHX_ cv); \
SPAGAIN;
{
    plcb_define_constants();
    PLCB_BOOTSTRAP_DEPENDENCY(boot_Couchbase__BucketConfig);
    PLCB_BOOTSTRAP_DEPENDENCY(boot_Couchbase__IO);
    PLCB_BOOTSTRAP_DEPENDENCY(boot_Couchbase__N1QL__Params);
}
#undef PLCB_BOOTSTRAP_DEPENDENCY
