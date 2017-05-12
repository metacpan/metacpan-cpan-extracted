#include "perl-couchbase.h"
#include <libcouchbase/views.h>
#include <libcouchbase/n1ql.h>

static void
rowreq_init_common(PLCB_t *parent, AV *req)
{
    SV *selfref;

    av_fill(req, PLCB_VHIDX_MAX);
    av_store(req, PLCB_VHIDX_ROWBUF, newRV_noinc((SV *)newAV()));
    av_store(req, PLCB_VHIDX_RAWROWS, newRV_noinc((SV *)newAV()));
    av_store(req, PLCB_VHIDX_PARENT, newRV_inc(parent->selfobj));

    selfref = newRV_inc((SV*)req);
    sv_rvweaken(selfref);
    av_store(req, PLCB_VHIDX_SELFREF, selfref);
}

static PLCB_t *
parent_from_req(AV *req)
{
    SV **pp = av_fetch(req, PLCB_VHIDX_PARENT, 0);
    return NUM2PTR(PLCB_t*,SvUV(SvRV(*pp)));
}

/* Handles the row, adding it into the internal structure */
static void
invoke_row(AV *req, SV *reqrv, SV *rowsrv)
{
    SV *meth;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    /* First arg */
    XPUSHs(reqrv);

    meth = *av_fetch(req, PLCB_VHIDX_PRIVCB, 0);
    if (rowsrv) {
        XPUSHs(rowsrv);
    }

    PUTBACK;
    call_sv(meth, G_DISCARD|G_EVAL);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        warn("Got error in %s", SvPV_nolen(ERRSV));
    }

    if (rowsrv) {
        av_clear((AV *)SvRV(rowsrv));
    }

    FREETMPS;
    LEAVE;
}

/* Wraps the buf:length pair as an SV */
static SV *
sv_from_rowdata(const char *s, size_t n)
{
    if (s && n) {
        SV *ret = newSVpvn(s, n);
        SvUTF8_on(ret);
        return ret;
    } else {
        return SvREFCNT_inc(&PL_sv_undef);
    }
}

static SV*
make_views_row(PLCB_t *parent, const lcb_RESPVIEWQUERY *resp)
{
    HV *rowdata = newHV();
    SV *docid = sv_from_rowdata(resp->docid, resp->ndocid);

    /* Key, Value, Doc ID, Geo, Doc */
    hv_stores(rowdata, "key", sv_from_rowdata(resp->key, resp->nkey));
    hv_stores(rowdata, "value", sv_from_rowdata(resp->value, resp->nvalue));
    hv_stores(rowdata, "geometry", sv_from_rowdata(resp->geometry, resp->ngeometry));
    hv_stores(rowdata, "id", docid);

    if (resp->docresp) {
        const lcb_RESPGET *docresp = resp->docresp;
        AV *docav = newAV();

        hv_stores(rowdata, "__doc__", newRV_noinc((SV*)docav));
        av_store(docav, PLCB_RETIDX_KEY, SvREFCNT_inc(docid));
        plcb_doc_set_err(parent, docav, resp->rc);

        if (docresp->rc == LCB_SUCCESS) {
            SV *docval = plcb_convert_getresp(parent, docav, docresp);
            av_store(docav, PLCB_RETIDX_VALUE, docval);
            plcb_doc_set_cas(parent, docav, &docresp->cas);
        }
    }
    return newRV_noinc((SV *)rowdata);
}

static SV *
make_n1ql_row(const lcb_RESPN1QL *resp)
{
    return sv_from_rowdata(resp->row, resp->nrow);
}

static void
common_callback(lcb_t obj, const lcb_RESPBASE *resp,
    const char *meta, size_t nmeta, const lcb_RESPHTTP *htresp,
    int is_n1ql)
{
    AV *req = resp->cookie;
    SV *req_weakrv = *av_fetch(req, PLCB_VHIDX_SELFREF, 0);
    SV *rawrows_rv = *av_fetch(req, PLCB_VHIDX_RAWROWS, 0);
    AV *rawrows = (AV *)SvRV(rawrows_rv);

    PLCB_t *plobj = parent_from_req(req);

    plcb_views_waitdone(plobj);

    if (resp->rflags & LCB_RESP_F_FINAL) {
        av_store(req, PLCB_VHIDX_VHANDLE, SvREFCNT_inc(&PL_sv_undef));

        /* Flush any remaining rows.. */
        invoke_row(req, req_weakrv, rawrows_rv);

        av_store(req, PLCB_VHIDX_ISDONE, SvREFCNT_inc(&PL_sv_yes));
        av_store(req, PLCB_VHIDX_RC, newSViv(resp->rc));
        av_store(req, PLCB_VHIDX_META, sv_from_rowdata(meta, nmeta));

        if (htresp) {
            av_store(req, PLCB_VHIDX_HTCODE, newSViv(htresp->htstatus));
        }
        invoke_row(req, req_weakrv, NULL);
        SvREFCNT_dec(req);
    } else {
        SV *row;
        if (is_n1ql) {
            row = make_n1ql_row((const lcb_RESPN1QL *)resp);
        } else {
            row = make_views_row(plobj, (const lcb_RESPVIEWQUERY *)resp);
        }

        av_push(rawrows, row);
        if (av_len(rawrows) >= 1) {
            invoke_row(req, req_weakrv, rawrows_rv);
        }
    }

}

static void
viewrow_callback(lcb_t obj, int ct, const lcb_RESPVIEWQUERY *resp)
{
    common_callback(obj, (lcb_RESPBASE*)resp,
        resp->value, resp->nvalue, resp->htresp, 0);
}

static void
n1ql_callback(lcb_t obj, int ct, const lcb_RESPN1QL *resp)
{
    common_callback(obj, (lcb_RESPBASE *)resp, resp->row, resp->nrow,
        resp->htresp, 1);
}

SV *
PLCB__viewhandle_new(PLCB_t *parent,
    const char *ddoc, const char *view, const char *options, int flags)
{
    AV *req = NULL;
    SV *blessed;
    lcb_CMDVIEWQUERY cmd = { 0 };
    lcb_VIEWHANDLE vh = NULL;
    lcb_error_t rc;

    req = newAV();
    rowreq_init_common(parent, req);
    blessed = newRV_noinc((SV*)req);
    sv_bless(blessed, parent->view_stash);

    lcb_view_query_initcmd(&cmd, ddoc, view, options, viewrow_callback);
    cmd.cmdflags = flags; /* Trust lcb on this */
    cmd.handle = &vh;

    rc = lcb_view_query(parent->instance, req, &cmd);

    if (rc != LCB_SUCCESS) {
        SvREFCNT_dec(blessed);
        die("Couldn't issue view query: (0x%x): %s", rc, lcb_strerror(NULL, rc));
    } else {
        SvREFCNT_inc(req); /* For the callback */
        av_store(req, PLCB_VHIDX_VHANDLE, newSVuv(PTR2UV(vh)));
    }
    return blessed;
}

void
PLCB__viewhandle_fetch(SV *pp)
{
    AV *req = (AV *)SvRV(pp);
    PLCB_t *parent = parent_from_req(req);
    plcb_views_wait(parent);
}

void
PLCB__viewhandle_stop(SV *pp)
{
    AV *req = (AV *)SvRV(pp);
    PLCB_t *parent = parent_from_req(req);
    SV **tmp, *vhsv;

    tmp = av_fetch(req, PLCB_VHIDX_VHANDLE, 0);
    if (!tmp) {
        return;
    }

    vhsv = *tmp;
    if (SvIOK(vhsv)) {
        lcb_VIEWHANDLE vh = NUM2PTR(lcb_VIEWHANDLE, SvUV(vhsv));
        lcb_view_cancel(parent->instance, vh);
        av_store(req, PLCB_VHIDX_VHANDLE, SvREFCNT_inc(&PL_sv_undef));
        av_store(req, PLCB_VHIDX_ISDONE, SvREFCNT_inc(&PL_sv_yes));
        SvREFCNT_dec((SV *)req);
    }
}

SV *
PLCB__n1qlhandle_new(PLCB_t *parent, lcb_N1QLPARAMS *params, const char *host)
{
    AV *req;
    SV *blessed;
    lcb_CMDN1QL cmd = { 0 };
    lcb_error_t rc;

    rc = lcb_n1p_mkcmd(params, &cmd);
    if (rc != LCB_SUCCESS) {
        die("Error encoding N1QL parameters: %s", lcb_strerror(NULL, rc));
    }

    if (host && *host) {
        cmd.host = host;
    }
    cmd.callback = n1ql_callback;

    req = newAV();
    rowreq_init_common(parent, req);
    blessed = newRV_noinc((SV*)req);
    sv_bless(blessed, parent->n1ql_stash);

    rc = lcb_n1ql_query(parent->instance, req, &cmd);
    if (rc != LCB_SUCCESS) {
        SvREFCNT_dec(blessed);
        die("Couldn't issue N1QL query: (0x%x): %s", rc, lcb_strerror(NULL, rc));
    } else {
        SvREFCNT_inc(req);
    }

    return blessed;
}
