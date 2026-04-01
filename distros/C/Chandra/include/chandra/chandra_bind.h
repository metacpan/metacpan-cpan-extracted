/*
 * chandra_bind.h — Bind module static helpers
 * Included from Chandra.xs before the INCLUDE: xs/bind.xs
 */

#ifndef CHANDRA_BIND_H
#define CHANDRA_BIND_H

static HV *_bind_registry = NULL;
static SV *_bind_json_obj = NULL;

static HV *
_bind_get_registry(pTHX)
{
    if (!_bind_registry)
        _bind_registry = newHV();
    return _bind_registry;
}

static SV *
_bind_get_json(pTHX)
{
    if (!_bind_json_obj || !SvOK(_bind_json_obj)) {
        _bind_json_obj = eval_pv(
            "require Cpanel::JSON::XS;"
            "Cpanel::JSON::XS->new->utf8->allow_nonref->allow_blessed->convert_blessed",
            TRUE
        );
        SvREFCNT_inc_simple_void(_bind_json_obj);
    }
    return _bind_json_obj;
}

/* Decode JSON string. On error, *err is set (caller must SvREFCNT_dec). */
static SV *
_bind_json_decode(pTHX_ SV *json_sv, SV **err)
{
    dSP;
    SV *json_obj = _bind_get_json(aTHX);
    SV *result;
    int count;

    *err = NULL;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(json_obj);
    XPUSHs(json_sv);
    PUTBACK;

    count = call_method("decode", G_SCALAR | G_EVAL);
    SPAGAIN;

    if (count > 0) {
        result = POPs;
    } else {
        result = &PL_sv_undef;
    }

    if (SvTRUE(ERRSV)) {
        *err = newSVsv(ERRSV);
        result = &PL_sv_undef;
    } else {
        SvREFCNT_inc_simple_void(result);
    }

    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

/* Encode SV to JSON string */
static SV *
_bind_json_encode(pTHX_ SV *val)
{
    dSP;
    SV *json_obj = _bind_get_json(aTHX);
    SV *result;
    int count;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(json_obj);
    XPUSHs(val ? val : &PL_sv_undef);
    PUTBACK;

    count = call_method("encode", G_SCALAR);
    SPAGAIN;
    result = (count > 0) ? SvREFCNT_inc(POPs) : newSVpvs("null");

    PUTBACK;
    FREETMPS;
    LEAVE;
    return result;
}

#endif /* CHANDRA_BIND_H */
