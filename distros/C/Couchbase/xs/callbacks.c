#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perl-couchbase.h"

void plcb_evloop_wait_unref(PLCB_t *obj) {
    if (obj->wait_for_kv == 0 && obj->wait_for_views == 0) {
        lcb_breakout(obj->instance);
    }
}

static int
chain_endure(PLCB_t *obj, AV *resobj, const lcb_RESPSTORE *resp)
{
    lcb_MULTICMD_CTX *mctx = NULL;
    lcb_CMDENDURE dcmd = { 0 };
    lcb_durability_opts_t dopts = { 0 };
    char persist_to = 0, replicate_to = 0;
    lcb_error_t err = LCB_SUCCESS;
    SV *optsv;

    optsv = *av_fetch(resobj, PLCB_RETIDX_OPTIONS, 1);
    if (!SvIOK(optsv)) {
        return 0;
    }

    PLCB_GETDURABILITY(SvUVX(optsv), persist_to, replicate_to);
    if (persist_to == 0 && replicate_to == 0) {
        return 0;
    }
    if (persist_to < 0 || replicate_to < 0) {
        dopts.v.v0.cap_max = 1;
    }

    dopts.v.v0.persist_to = persist_to;
    dopts.v.v0.replicate_to = replicate_to;
    LCB_CMD_SET_KEY(&dcmd, resp->key, resp->nkey);
    dcmd.cas = resp->cas;

    mctx = lcb_endure3_ctxnew(obj->instance, &dopts, &err);
    if (mctx == NULL) {
        plcb_doc_set_err(obj, resobj, err);
        return 0;
    }

    err = mctx->addcmd(mctx, (lcb_CMDBASE *)&dcmd);
    if (err != LCB_SUCCESS) {
        mctx->fail(mctx);
        return 0;
    }

    lcb_sched_enter(obj->instance);
    err = mctx->done(mctx, resp->cookie);
    if (err != LCB_SUCCESS) {
        plcb_doc_set_err(obj, resobj, err);
        return 0;
    }

    lcb_sched_leave(obj->instance);
    return 1;
}

static void
call_helper(AV *resobj, int cbtype, const lcb_RESPBASE *resp)
{
    dSP;
    const char *methname;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc((SV*)resobj)));


    if (cbtype == LCB_CALLBACK_STATS) {
        const lcb_RESPSTATS *sresp = (const void *)resp;

        /** Call as statshelper($doc,$server,$key,$value); */
        XPUSHs(sv_2mortal(newSVpv(sresp->server, 0)));
        XPUSHs(sv_2mortal(newSVpvn(sresp->key, sresp->nkey)));
        if (sresp->value) {
            XPUSHs(sv_2mortal(newSVpvn(sresp->value, sresp->nvalue)));
        }
        methname = PLCB_STATS_PLHELPER;

    } else if (cbtype == LCB_CALLBACK_OBSERVE) {
        const lcb_RESPOBSERVE *oresp = (const void *)resp;

        /** Call as obshelper($doc,$status,$cas,$ismaster) */
        XPUSHs(sv_2mortal(newSVuv(oresp->status)));
        XPUSHs(sv_2mortal(plcb_sv_from_u64_new(&oresp->cas)));
        XPUSHs(oresp->ismaster ? &PL_sv_yes : &PL_sv_no);
        methname = PLCB_OBS_PLHELPER;
    } else {
        return;
    }

    PUTBACK;
    call_pv(methname, G_DISCARD|G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        warn("Got error in %s: %s", methname, SvPV_nolen(ERRSV));
    }

    FREETMPS;
    LEAVE;
}

static void
call_async(plcb_OPCTX *ctx, AV *resobj)
{
    SV *cv = ctx->u.callback;
    dSP;

    if (cv == NULL || SvOK(cv) == 0) {
        warn("Context does not have a callback (%p)!", cv);
        return;
    }

    if ((ctx->flags & PLCB_OPCTXf_IMPLICIT) == 0) {
        if (ctx->nremaining && (ctx->flags & PLCB_OPCTXf_CALLEACH) == 0) {
            return; /* Still have ops. Only call once they're all complete */
        }
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newRV_inc((SV*)resobj)));
    PUTBACK;
    call_sv(cv, G_DISCARD);
    FREETMPS;
    LEAVE;

    if (ctx->nremaining == 0 && (ctx->flags & PLCB_OPCTXf_CALLDONE)) {
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        call_sv(cv, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}

/* This callback is only ever called for single operation, single key results */
static void
callback_common(lcb_t instance, int cbtype, const lcb_RESPBASE *resp)
{
    AV *resobj = NULL;
    PLCB_t *parent;
    SV *ctxrv = (SV *)resp->cookie;
    plcb_OPCTX *ctx = NUM2PTR(plcb_OPCTX*, SvIVX(SvRV(ctxrv)));

    if (cbtype == LCB_CALLBACK_STATS || cbtype == LCB_CALLBACK_OBSERVE ||
            cbtype == LCB_CALLBACK_HTTP) {
        HE *tmp;

        hv_iterinit(ctx->docs);
        tmp = hv_iternext(ctx->docs);

        if (tmp && HeVAL(tmp) && SvROK(HeVAL(tmp))) {
            resobj = (AV *)SvRV(HeVAL(tmp));
        }
    } else {
        SV **tmp = hv_fetch(ctx->docs, resp->key, resp->nkey, 0);
        if (tmp && SvROK(*tmp)) {
            resobj = (AV*)SvRV(*tmp);
        }
    }

    if (!resobj) {
        warn("Couldn't find matching object!");
        return;
    }

    parent = (PLCB_t *)lcb_get_cookie(instance);
    plcb_doc_set_err(parent, resobj, resp->rc);

    switch (cbtype) {
    case LCB_CALLBACK_GET: {
        const lcb_RESPGET *gresp = (const lcb_RESPGET *)resp;
        if (resp->rc == LCB_SUCCESS) {
            SV *newval = plcb_convert_retrieval(parent,
                resobj, gresp->value, gresp->nvalue, gresp->itmflags);

            av_store(resobj, PLCB_RETIDX_VALUE, newval);
            plcb_doc_set_cas(parent, resobj, &resp->cas);
        }
        break;
    }

    case LCB_CALLBACK_TOUCH:
    case LCB_CALLBACK_REMOVE:
    case LCB_CALLBACK_UNLOCK:
    case LCB_CALLBACK_STORE:
    case LCB_CALLBACK_ENDURE:
        if (resp->cas && resp->rc == LCB_SUCCESS) {
            plcb_doc_set_cas(parent, resobj, &resp->cas);
        }

        if (cbtype == LCB_CALLBACK_STORE && resp->rc == LCB_SUCCESS &&
                chain_endure(parent, resobj, (const lcb_RESPSTORE *)resp)) {
            return; /* Will be handled already */
        }
        break;

    case LCB_CALLBACK_COUNTER: {
        const lcb_RESPCOUNTER *cresp = (const lcb_RESPCOUNTER*)resp;
        plcb_doc_set_numval(parent, resobj, cresp->value, resp->cas);
        break;
    }

    case LCB_CALLBACK_STATS: {
        const lcb_RESPSTATS *sresp = (const void *)resp;
        if (sresp->server) {
            call_helper(resobj, cbtype, (const lcb_RESPBASE *)sresp);
            return;
        }
        break;
    }
    case LCB_CALLBACK_OBSERVE: {
        const lcb_RESPOBSERVE *oresp = (const lcb_RESPOBSERVE*)resp;
        if (oresp->nkey) {
            call_helper(resobj, cbtype, (const lcb_RESPBASE*)oresp);
            return;
        }
        break;
    }
    case LCB_CALLBACK_HTTP: {
        const lcb_RESPHTTP *htresp = (const lcb_RESPHTTP *)resp;

        /* Store the CAS */
        av_store(resobj, PLCB_HTIDX_STATUS, newSViv(htresp->htstatus));
        if (htresp->headers) {
            const char * const * hdr_cur;
            HV *headers = newHV();
            av_store(resobj, PLCB_HTIDX_HEADERS, newRV_noinc((SV*)headers));

            for (hdr_cur = htresp->headers; *hdr_cur; hdr_cur += 2) {
                const char *hdrkey = hdr_cur[0];
                const char *hdrval = hdr_cur[1];
                SV *valsv = newSVpv(hdrval, 0);
                hv_store(headers, hdrkey, 0, valsv, 0);
            }
        }
        if (htresp->nbody) {
            lcb_U32 fmtflags = PLCB_CF_JSON;
            SV *body;
            SV *fmtspec = *av_fetch(resobj, PLCB_RETIDX_VALUE, 1);

            if (SvIOK(fmtspec)) {
                fmtflags = SvUV(fmtspec);
            }

            body = plcb_convert_retrieval_ex(parent, resobj,
                htresp->body, htresp->nbody, fmtflags,
                PLCB_CONVERT_NOCUSTOM);

            av_store(resobj, PLCB_RETIDX_VALUE, body);
        }
        break;
    }

    default:
        abort();
        break;
    }

    ctx->nremaining--;

    if (parent->async) {
        call_async(ctx, resobj);
    } else if (ctx->flags & PLCB_OPCTXf_WAITONE) {
        av_push(ctx->u.ctxqueue, newRV_inc( (SV* )resobj));
        plcb_kv_waitdone(parent);
    }

    if (!ctx->nremaining) {
        SvREFCNT_dec(ctxrv);
        plcb_kv_waitdone(parent);
        plcb_opctx_clear(parent);
    }
}

static void
bootstrap_callback(lcb_t instance, lcb_error_t status)
{
    dSP;
    PLCB_t *obj = (PLCB_t*) lcb_get_cookie(instance);
    if (!obj->async) {
        return;
    }
    if (!obj->conncb) {
        warn("Object %p does not have a connect callback!", obj);
        return;
    }
    printf("Invoking callback for connect..!\n");

    ENTER;SAVETMPS;PUSHMARK(SP);

    XPUSHs(sv_2mortal(newRV_inc(obj->selfobj)));
    XPUSHs(sv_2mortal(newSViv(status)));
    PUTBACK;

    call_sv(obj->conncb, G_DISCARD);
    SPAGAIN;
    FREETMPS;LEAVE;
    SvREFCNT_dec(obj->conncb); obj->conncb = NULL;
}

void
plcb_callbacks_setup(PLCB_t *object)
{
    lcb_t o = object->instance;

    lcb_install_callback3(o, LCB_CALLBACK_GET, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_GETREPLICA, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_STORE, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_TOUCH, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_REMOVE, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_COUNTER, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_UNLOCK, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_ENDURE, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_STATS, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_OBSERVE, callback_common);
    lcb_install_callback3(o, LCB_CALLBACK_HTTP, callback_common);
    lcb_set_bootstrap_callback(o, bootstrap_callback);
}
