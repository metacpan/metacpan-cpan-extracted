#include "perl-couchbase.h"

#define CONVERT_OUT 1
#define CONVERT_IN 2

static SV*
serialize_convert(SV *meth, SV *input, int direction)
{
    dSP;
    SV *ret;
    int count;    

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(input);
    PUTBACK;

    if (direction == CONVERT_OUT) {
        count = call_sv(meth, G_SCALAR);
        SPAGAIN;

        /*for ouptut we must have this function succeed!*/
        if (count != 1) {
            croak("Serialization method returned nothing!");
        }
        ret = POPs;

    } else {
        count = call_sv(meth, G_SCALAR|G_EVAL);
        SPAGAIN;

        /*if someone has messed up our flags, don't die, but throw a warning*/
        if (SvTRUE(ERRSV)) {
            warn("Couldn't deserialize data: %s", SvPV_nolen(ERRSV));
            ret = input;

        } else {
            if (count != 1) {
                croak("Serialization method returned nothing?");
            }
            ret = POPs;
        }
    }

    SvREFCNT_inc(ret);
    FREETMPS;
    LEAVE;
    return ret;
}

static SV *
custom_convert(AV *docav, SV *meth, SV *input, uint32_t *flags, int direction)
{
    dSP;
    SV *ret;
    SV *flags_rv;
    SV *input_rv;
    int callflags;

    ENTER; SAVETMPS;
    PUSHMARK(SP);

    input_rv = sv_2mortal(newRV_inc(input));
    flags_rv = sv_2mortal(newRV_noinc(newSVuv(*flags)));

    XPUSHs(sv_2mortal(newRV_inc( (SV *)docav)));
    XPUSHs(input_rv);
    XPUSHs(flags_rv);

    PUTBACK;

    callflags = G_VOID|G_DISCARD;
    if (direction == CONVERT_OUT) {
        callflags |= G_EVAL;
    }

    call_sv(meth, callflags);
    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        ret = input;
    } else {
        warn("Conversion function failed");
        ret = SvRV(input_rv);
        *flags = SvUV(SvRV(flags_rv));
    }

    SvREFCNT_inc(ret);
    return ret;
}

void
plcb_convert_storage(PLCB_t *object, AV *docav, plcb_DOCVAL *vspec)
{
    SV *pv = SvROK(vspec->value) ? SvRV(vspec->value) : vspec->value;
    uint32_t fmt = vspec->spec;

    if (object->cv_customenc) {
        vspec->need_free = 1;
        vspec->value = custom_convert(docav, object->cv_customenc, vspec->value, &vspec->flags, CONVERT_OUT);

    } else if (fmt == PLCB_CF_JSON) {
        vspec->flags = PLCB_LF_JSON|PLCB_CF_JSON;
        vspec->need_free = 1;
        vspec->value = serialize_convert(object->cv_jsonenc, vspec->value, CONVERT_OUT);

    } else if (fmt == PLCB_CF_STORABLE) {
        vspec->flags = PLCB_CF_STORABLE | PLCB_LF_STORABLE;
        vspec->need_free = 1;
        vspec->value = serialize_convert(object->cv_serialize, vspec->value, CONVERT_OUT);

    } else if (fmt == PLCB_CF_RAW) {
        vspec->flags = PLCB_CF_RAW | PLCB_LF_RAW;
        vspec->need_free = 0;
        if (!SvPOK(pv)) {
            die("Raw conversion requires string value!");
        }
    } else if (vspec->spec == PLCB_CF_UTF8) {
        vspec->flags = PLCB_CF_UTF8 | PLCB_LF_UTF8;
        vspec->need_free = 0;
        sv_utf8_upgrade(pv);

    } else {
        die("Unrecognized flags used (0x%x) but no custom converted installed!", vspec->spec);
    }

    if (!vspec->need_free) {
        /* Use input as-is */
        vspec->value = pv;
    }

    /* Assume the resultant value is an SV */
    if (SvTYPE(vspec->value) == SVt_PV) {
        vspec->encoded = SvPVX(vspec->value);
        vspec->len = SvCUR(vspec->value);
    } else {
        vspec->encoded = SvPV(vspec->value, vspec->len);
    }
}

void plcb_convert_storage_free(PLCB_t *object, plcb_DOCVAL *vs)
{
    if (vs->need_free) {
        SvREFCNT_dec(vs->value);
    }
}

SV*
plcb_convert_retrieval_ex(PLCB_t *object, AV *docav,
    const char *data, size_t data_len, uint32_t flags, int options)
{
    SV *ret_sv, *input_sv, *flags_sv;
    uint32_t f_common, f_legacy;
    input_sv = newSVpvn(data, data_len);

    f_common = flags & PLCB_CF_MASK;
    f_legacy = flags & PLCB_LF_MASK;
    flags_sv = *av_fetch(docav, PLCB_RETIDX_FMTSPEC, 1);

#define IS_FMT(fbase) f_common == PLCB_CF_##fbase || f_legacy == PLCB_LF_##fbase

    if (object->cv_customdec && options != PLCB_CONVERT_NOCUSTOM) {
        ret_sv = custom_convert(docav, object->cv_customdec, input_sv, &flags, CONVERT_IN);
        /* Flags remain unchanged? */

    } else if (IS_FMT(JSON)) {
        SvUTF8_on(input_sv);
        ret_sv = serialize_convert(object->cv_jsondec, input_sv, CONVERT_IN);
        flags = PLCB_CF_JSON;

    } else if (IS_FMT(STORABLE)) {
        ret_sv = serialize_convert(object->cv_deserialize, input_sv, CONVERT_IN);
        flags = PLCB_CF_STORABLE;

    } else if (IS_FMT(UTF8)) {
        SvUTF8_on(input_sv);
        ret_sv = input_sv;
        SvREFCNT_inc(ret_sv);
        flags = PLCB_CF_UTF8;

    } else {
        if (IS_FMT(RAW)) {
            flags = PLCB_CF_RAW;
        } else {
            warn("Unrecognized flags 0x%x. Assuming raw", flags);
        }
        ret_sv = input_sv;
        SvREFCNT_inc(ret_sv);
    }
#undef IS_FMT

    SvREFCNT_dec(input_sv);
    if (SvIOK(flags_sv) == 0 || SvUVX(flags_sv) != flags) {
        sv_setuv(flags_sv, flags);
    }
    return ret_sv;
}
