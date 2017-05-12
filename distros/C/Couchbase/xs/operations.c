#include "perl-couchbase.h"
#include <libcouchbase/api3.h>

static int
cmd_to_storop(int cmd)
{
    if (cmd == PLCB_CMD_ADD) { return LCB_ADD; }
    if (cmd == PLCB_CMD_SET) { return LCB_SET; }
    if (cmd == PLCB_CMD_REPLACE) { return LCB_REPLACE; }
    if (cmd == PLCB_CMD_APPEND) { return LCB_APPEND; }
    if (cmd == PLCB_CMD_PREPEND) { return LCB_PREPEND; }
    abort();
    return -1;
}

static void
key_from_so(plcb_SINGLEOP *so, lcb_CMDBASE *cmd)
{
    const char *key = NULL;
    STRLEN nkey = 0;

    SV **tmpsv = av_fetch(so->docav, PLCB_RETIDX_KEY, 0);
    if (so->cmdbase == PLCB_CMD_STATS) {
        if (!tmpsv) {
            return;
        }
        key = SvPV(*tmpsv, nkey);
    } else {
        if (tmpsv == NULL) {
            die("Cannot pass document without key");
        }
        plcb_get_str_or_die(*tmpsv, key, nkey, "Invalid key");
    }

    LCB_CMD_SET_KEY(cmd, key, nkey);
}

SV *
PLCB_op_get(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_error_t err = LCB_SUCCESS;
    lcb_CMDGET gcmd = { 0 };

    PLCB_args_get(object, opinfo, &gcmd);
    key_from_so(opinfo, (lcb_CMDBASE*)&gcmd);
    if (opinfo->cmdbase == PLCB_CMD_TOUCH) {
        err = lcb_touch3(object->instance, opinfo->cookie, (lcb_CMDTOUCH*)&gcmd);
    } else {
        err = lcb_get3(object->instance, opinfo->cookie, &gcmd);
    }
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_set(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_error_t err = LCB_SUCCESS;
    plcb_DOCVAL vspec = { 0 };
    lcb_CMDSTORE scmd = { 0 };

    key_from_so(opinfo, (lcb_CMDBASE *)&scmd);
    PLCB_args_set(object, opinfo, &scmd, &vspec);
    plcb_convert_storage(object, opinfo->docav, &vspec);

    if (vspec.encoded == NULL) {
        die("Invalid value!");
    }

    LCB_CMD_SET_VALUE(&scmd, vspec.encoded, vspec.len);

    if (opinfo->cmdbase != PLCB_CMD_APPEND && opinfo->cmdbase != PLCB_CMD_PREPEND) {
        scmd.flags = vspec.flags;
    }
    scmd.operation =  cmd_to_storop(opinfo->cmdbase);

    err = lcb_store3(object->instance, opinfo->cookie, &scmd);
    plcb_convert_storage_free(object, &vspec);
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_counter(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_CMDCOUNTER ccmd = { 0 };
    lcb_error_t err = LCB_SUCCESS;
    
    key_from_so(opinfo, (lcb_CMDBASE *)&ccmd);
    PLCB_args_arithmetic(object, opinfo, &ccmd);
    err = lcb_counter3(object->instance, opinfo->cookie, &ccmd);
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_remove(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_CMDREMOVE rcmd = { 0 };
    lcb_error_t err = LCB_SUCCESS;

    key_from_so(opinfo, &rcmd);
    PLCB_args_remove(object, opinfo, &rcmd);
    err = lcb_remove3(object->instance, opinfo->cookie, &rcmd);
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_unlock(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_CMDUNLOCK ucmd = { 0 };
    lcb_error_t err = LCB_SUCCESS;

    key_from_so(opinfo, &ucmd);
    PLCB_args_unlock(object, opinfo, &ucmd);
    err = lcb_unlock3(object->instance, opinfo->cookie, &ucmd);
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_stats(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_CMDSTATS scmd = { 0 };
    lcb_error_t err = LCB_SUCCESS;
    key_from_so(opinfo, &scmd);

    if (opinfo->cmdbase == PLCB_CMD_KEYSTATS) {
        scmd.cmdflags = LCB_CMDSTATS_F_KV;
    }

    err = lcb_stats3(object->instance, opinfo->cookie, &scmd);
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_observe(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_CMDOBSERVE obscmd = { 0 };
    lcb_MULTICMD_CTX *mctx;
    lcb_error_t err = LCB_SUCCESS;

    key_from_so(opinfo, (lcb_CMDBASE*)&obscmd);
    PLCB_args_observe(object, opinfo, &obscmd);

    mctx = lcb_observe3_ctxnew(object->instance);
    if (!mctx) {
        err = LCB_CLIENT_ENOMEM;
        goto GT_DONE;
    }

    err = mctx->addcmd(mctx, (lcb_CMDBASE*)&obscmd);
    if (err == LCB_SUCCESS) {
        err = mctx->done(mctx, opinfo->cookie);
    } else {
        mctx->fail(mctx);
    }

    GT_DONE:
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_endure(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_CMDENDURE ecmd = { 0 };
    lcb_error_t err;
    lcb_MULTICMD_CTX *mctx = opinfo->ctxptr->multi;

    if (!mctx) {
        die("Durability operations must be created with their own batch context");
    }

    key_from_so(opinfo, (lcb_CMDBASE*)&ecmd);
    PLCB_args_endure(object, opinfo, (lcb_CMDBASE*)&ecmd);
    err = mctx->addcmd(mctx, (lcb_CMDBASE*)&ecmd);
    return plcb_opctx_return(opinfo, err);
}

SV*
PLCB_op_http(PLCB_t *object, plcb_SINGLEOP *opinfo)
{
    lcb_CMDHTTP htcmd = { 0 };
    lcb_error_t err;

    key_from_so(opinfo, (lcb_CMDBASE*)&htcmd);
    PLCB_args_http(object, opinfo, &htcmd);
    err = lcb_http3(object->instance, opinfo->cookie, &htcmd);
    return plcb_opctx_return(opinfo, err);
}
