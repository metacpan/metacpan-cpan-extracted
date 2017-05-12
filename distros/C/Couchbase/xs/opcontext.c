#include "perl-couchbase.h"

SV *
plcb_opctx_new(PLCB_t *parent, int flags)
{
    plcb_OPCTX *ctx;
    SV *blessed;

    if (parent->curctx) {
        ctx = NUM2PTR(plcb_OPCTX*,SvIVX(SvRV(parent->curctx)));
        if (ctx->nremaining == 0) {
            plcb_opctx_clear(parent);
        } else {
            die("Existing context found. Existing context must be waited for or cleared");
        }
    }

    if (parent->cachectx && (flags & PLCB_OPCTXf_IMPLICIT)) {
        blessed = parent->cachectx;
        parent->cachectx = NULL;
        ctx = NUM2PTR(plcb_OPCTX*,SvIVX(SvRV(blessed)));

    } else {
        Newxz(ctx, 1, plcb_OPCTX);
        ctx->docs = newHV();
        ctx->parent = newRV_inc(parent->selfobj);
        sv_rvweaken(ctx->parent);

        blessed = newRV_noinc(newSViv(PTR2IV(ctx)));
        sv_bless(blessed, parent->opctx_sync_stash);
    }

    ctx->flags = flags;
    ctx->nremaining = 0;
    parent->curctx = blessed;
    SvREFCNT_inc(parent->curctx);
    lcb_sched_enter(parent->instance);
    return blessed;
}

void
plcb_opctx_clear(PLCB_t *parent)
{
    plcb_OPCTX *ctx;
    if (!parent->curctx) {
        return;
    }
    if (!SvROK(parent->curctx)) {
        SvREFCNT_dec(parent->curctx);
        parent->curctx = NULL;
        return;
    }

    ctx = NUM2PTR(plcb_OPCTX*,SvIVX(SvRV(parent->curctx)));
    hv_clear(ctx->docs);

    if (ctx->multi) {
        ctx->multi->fail(ctx->multi);
        ctx->multi = NULL;
    }

    if ((ctx->flags & PLCB_OPCTXf_IMPLICIT) && parent->cachectx == NULL) {
        parent->cachectx = parent->curctx;
    } else {
        SvREFCNT_dec(parent->curctx);
    }
    parent->curctx = NULL;
}

void
plcb_opctx_initop(plcb_SINGLEOP *so, PLCB_t *parent, SV *doc, SV *ctx, SV *options)
{
    if (!plcb_doc_isa(parent, doc)) {
        die("Must pass a " PLCB_RET_CLASSNAME);
    }

    so->docrv = doc;
    so->docav = (AV *)SvRV(doc);
    so->opctx = ctx;
    so->parent = parent;

    plcb_doc_set_err(parent, so->docav, -1);

    /* Extract options for this command */
    if (options && SvTYPE(options) != SVt_NULL) {
        if (SvROK(options) == 0 || SvTYPE(SvRV(options)) != SVt_PVHV) {
            die("options must be undef or a HASH reference");
        }
        so->cmdopts = options;
    }

    if (ctx && SvTYPE(ctx) != SVt_NULL) {
        if (SvRV(so->opctx) != SvRV(parent->curctx)) {
            die("Got a different context than current!");
        }
        so->opctx = parent->curctx;
    } else {
        so->opctx = plcb_opctx_new(parent, PLCB_OPCTXf_IMPLICIT);
        /* If we get an error, don't leave the pointer dangling */
        SAVEFREESV(so->opctx);
    }

    so->cookie = so->opctx;
    so->ctxptr = NUM2PTR(plcb_OPCTX*, SvIVX(SvRV(so->opctx)));
}

SV *
plcb_opctx_return(plcb_SINGLEOP *so, lcb_error_t err)
{
    /* Figure out what type of context we are */
    int haserr = 0;
    SV *retval;
    SV *ksv;
    HE *ent;
    plcb_OPCTX *ctx = NUM2PTR(plcb_OPCTX*, SvIVX(SvRV(so->opctx)));

    if (err != LCB_SUCCESS) {
        plcb_doc_set_err(so->parent, so->docav, err);

        if (ctx->flags & PLCB_OPCTXf_IMPLICIT) {
            lcb_sched_fail(so->parent->instance);
        }

        warn("Couldn't schedule operation. Code 0x%x (%s)\n", err, lcb_strerror(NULL, err));
        haserr = 1;
        goto GT_RET;
    }

    /* Get the key */
    if (so->cmdbase == PLCB_CMD_STATS || so->cmdbase == PLCB_CMD_OBSERVE ||
            so->cmdbase == PLCB_CMD_HTTP) {
        ksv = &PL_sv_yes;
    } else {
        ksv = *av_fetch(so->docav, PLCB_RETIDX_KEY, 1);
    }

    ent = hv_fetch_ent(ctx->docs, ksv, 1, 0);
    if (SvOK(HeVAL(ent))) {
        die("Found duplicate item inside batch context");
    } else {
        SvREFCNT_dec(HeVAL(ent));
        HeVAL(ent) = newRV_inc((SV*)so->docav);
    }

    /* Increment remaining count on the context */
    ctx->nremaining++;

    if (ctx->flags & PLCB_OPCTXf_IMPLICIT) {
        SvREFCNT_inc(so->opctx); /* Undo SAVEFREESV */
        lcb_sched_leave(so->parent->instance);

        if (so->parent->async) {
            /* Clear this context right now */
            SvREFCNT_dec(so->parent->curctx);
            so->parent->curctx = NULL;
            goto GT_RET;
        }
        plcb_kv_wait(so->parent);
        /* See if we have an error */
        if (plcb_doc_get_err(so->docav) != LCB_SUCCESS) {
            haserr = 1;
        }
    }

    GT_RET:
    if (haserr) {
        retval = &PL_sv_no;
    } else if (so->parent->async || (ctx->flags & PLCB_OPCTXf_IMPLICIT) == 0) {
        retval = so->opctx;
    } else {
        retval = &PL_sv_yes;
    }
    SvREFCNT_inc(retval);
    return retval;
}


void
plcb_opctx_submit(PLCB_t *parent, plcb_OPCTX *ctx)
{
    lcb_error_t err = LCB_SUCCESS;
    if (ctx->multi) {
        err = ctx->multi->done(ctx->multi, parent->curctx);
        ctx->multi = NULL;
        if (err != LCB_SUCCESS) {
            die("Couldn't submit multi context: Code=0x%x", err);
        }
    }
    lcb_sched_leave(parent->instance);
}
