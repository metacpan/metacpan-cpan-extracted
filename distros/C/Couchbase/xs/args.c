/**
 * This is an attempt at consolidating argument handling for all functions
 * in single, multi, and async mode.
 */

#include "perl-couchbase.h"

static plcb_OPTION *
find_valspec(plcb_OPTION *values, const char *key, size_t nkey)
{
    plcb_OPTION *ret;
    for (ret = values; ret->key; ret++) {
        if (nkey != ret->nkey) {
            continue;
        }
        if (strncasecmp(ret->key, key, nkey) == 0) {
            return ret;
        }
    }
    return NULL;
}

static int
convert_valspec(plcb_OPTION *dst, SV *src)
{
    switch (dst->type) {
    case PLCB_ARG_T_PAD:
        return 0;

    case PLCB_ARG_T_INT:
    case PLCB_ARG_T_BOOL: {

        int assigned_val = 0;

        if (SvTYPE(src) == SVt_NULL) {
            assigned_val = 0;

        } else {
            assigned_val = SvIV(src);
        }

        *((int*)(dst->value)) = assigned_val;
        break;
    }


#define EXPECT_RV(subtype, friendly_name) \
    if (SvROK(src) == 0 || SvTYPE(SvRV(src)) != subtype) { \
        die("Expected %s for %s", friendly_name, dst->key); \
    } \
    *(void**)dst->value = src;

    case PLCB_ARG_T_SV:
        *(SV**)dst->value = src;
        break;

    case PLCB_ARG_T_HV:
        EXPECT_RV(SVt_PVHV, "Hash");
        break;

    case PLCB_ARG_T_AV:
        EXPECT_RV(SVt_PVAV, "Array");
        break;

    case PLCB_ARG_T_CV:
        EXPECT_RV(SVt_PVCV, "CODE");
        break;

#undef EXPECT_RV

    case PLCB_ARG_T_RV:
        if (!SvROK(src)) {
            die("Expected reference for %s", dst->key);
        }
        *(SV**)dst->value = src;
        break;

    case PLCB_ARG_T_CAS: {
        if (SvTYPE(src) == SVt_NULL) {
            break;
        }

        *(uint64_t*)dst->value = plcb_sv2cas(src);
        break;

    }

    case PLCB_ARG_T_EXP:
    case PLCB_ARG_T_EXPTT: {
        UV exp_uv = plcb_exp_from_sv(src);

        if (dst->type == PLCB_ARG_T_EXP) {
            *((UV*)dst->value) = exp_uv;
        } else {
            *(time_t*)dst->value = exp_uv;
        }

        break;
    }

    case PLCB_ARG_T_I64:
        *(int64_t*)dst->value = plcb_sv_to_64(src);
        break;

    case PLCB_ARG_T_U64:
        *(uint64_t*)dst->value = plcb_sv_to_u64(src);
        break;

    case PLCB_ARG_T_U32:
        *(uint32_t*)dst->value = SvUV(src);
        break;

    case PLCB_ARG_T_STRING:
    case PLCB_ARG_T_STRING_NN: {
        PLCB_XS_STRING_t *str = dst->value;
        str->origsv = src;
        str->base = SvPV(src, str->len);

        if (str->len == 0 && dst->type == PLCB_ARG_T_STRING_NN) {
            die("Value cannot be an empty string for %s", dst->key);
        }
        break;
    }

    case PLCB_ARG_T_CSTRING:
    case PLCB_ARG_T_CSTRING_NN: {
        *(const char **)dst->value = SvPV_nolen(src);
        if (dst->type == PLCB_ARG_T_CSTRING_NN) {
            if (dst->value == NULL|| *(const char*)dst->value == '\0') {
                die("Value passed must not be empty for %s", dst->key);
            }
        }
        break;
    }

    default:
        return -1;
        break;

    }

    return 0;

}

int
plcb_extract_args(SV *sv, plcb_OPTION *values)
{
    char *cur_key;
    I32 klen;
    if (SvROK(sv)) {
        sv = SvRV(sv);
    }

    if (SvTYPE(sv) == SVt_PVHV) {
        HV *hv = (HV*)sv;
        SV *cur_val;
        hv_iterinit(hv);

        while ( (cur_val = hv_iternextsv(hv, &cur_key, &klen)) ) {
            plcb_OPTION *curdst = find_valspec(values, cur_key, klen);

            if (!curdst) {
                warn("Unrecognized key '%.*s'", (int)klen, cur_key);
                continue;
            }

            if (convert_valspec(curdst, cur_val) == -1) {
                die("Bad value for %.*s'", (int)klen, cur_key);
            }

            curdst->sv = cur_val;
        }
    } else {
        die("Unrecognized options type. Must be hash");
    }
    return 0;
}

static void
load_doc_options(PLCB_t *parent, AV *ret, plcb_OPTION *values)
{
    plcb_OPTION *cur = values;

    for (cur = values; cur->value; cur++) {
        SV **tmpsv;
        int ix;

        if (cur->type == PLCB_ARG_T_PAD) {
            continue;
        }

        if (!strcmp(cur->key, PLCB_ARG_K_CAS)) {
            ix = PLCB_RETIDX_CAS;
        } else if (!strcmp(cur->key,PLCB_ARG_K_EXPIRY)) {
            ix = PLCB_RETIDX_EXP;
        } else if (!strcmp(cur->key,PLCB_ARG_K_VALUE)) {
            ix = PLCB_RETIDX_VALUE;
        } else if (!strcmp(cur->key,PLCB_ARG_K_FMT)) {
            ix = PLCB_RETIDX_FMTSPEC;
        } else {
            continue;
        }
        tmpsv = av_fetch(ret, ix, 0);
        if (!tmpsv) {
            continue;
        }

        if (convert_valspec(cur, *tmpsv) == -1) {
            die("Couldn't convert %s", cur->key);
        }
        cur->sv = *tmpsv;
    }
}

int
PLCB_args_get(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDGET *gcmd)
{
    if (args->cmdbase == PLCB_CMD_LOCK) {
        UV lockexp;
        plcb_OPTION opt_specs[] = {
            PLCB_KWARG(PLCB_ARG_K_LOCK, EXP, &lockexp),
            {NULL}
        };

        if (!args->cmdopts) {
            die("get_and_lock must have " PLCB_ARG_K_LOCK);
        }
        plcb_extract_args(args->cmdopts, opt_specs);
        if (!lockexp) {
            die("get_and_lock must have " PLCB_ARG_K_LOCK);
        }
        gcmd->lock = 1;
        gcmd->exptime = lockexp;

    } else if (args->cmdbase == PLCB_CMD_GAT || args->cmdbase == PLCB_CMD_TOUCH) {
        UV exp = 0;
        plcb_OPTION doc_specs[] = {
                PLCB_KWARG(PLCB_ARG_K_EXPIRY, EXP, &exp),
                {NULL}
        };
        load_doc_options(object, args->docav, doc_specs);
        ((lcb_CMDBASE*) gcmd)->exptime = exp;
    }

    return 0;
}

int
PLCB_args_remove(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDREMOVE *rcmd)
{
    int ignore_cas = 0;
    plcb_OPTION doc_specs[] = {
        PLCB_KWARG(PLCB_ARG_K_CAS, CAS, &rcmd->cas),
        { NULL }
    };
    plcb_OPTION opts_specs[] = {
        PLCB_KWARG(PLCB_ARG_K_IGNORECAS, BOOL, &ignore_cas),
        {NULL}
    };

    load_doc_options(object, args->docav, doc_specs);
    if (args->cmdopts) {
        plcb_extract_args(args->cmdopts, opts_specs);
    }

    if (ignore_cas) {
        rcmd->cas = 0;
    }
    return 0;
}

int
PLCB_args_arithmetic(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDCOUNTER *acmd)
{
    acmd->delta = 1;
    plcb_OPTION argspecs[] = {
        PLCB_KWARG(PLCB_ARG_K_ARITH_DELTA, I64, &acmd->delta),
        PLCB_KWARG(PLCB_ARG_K_ARITH_INITIAL, U64, &acmd->initial),
        PLCB_KWARG(PLCB_ARG_K_EXPIRY, EXP, &acmd->exptime),
        { NULL }
    };

    if (args->cmdopts) {
        plcb_extract_args(args->cmdopts, argspecs);
    }

    if (argspecs[1].sv && argspecs[1].sv != &PL_sv_undef) {
        acmd->create = 1;
    }
    return 0;
}

int
PLCB_args_unlock(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDUNLOCK *ucmd)
{
    plcb_OPTION argspecs[] = {
        PLCB_KWARG(PLCB_ARG_K_CAS, CAS, &ucmd->cas),
        { NULL }
    };

    load_doc_options(object, args->docav, argspecs);
    if (ucmd->cas == 0 && args->cmdbase == PLCB_CMD_UNLOCK) {
        die("Unlock command must have CAS");
    }
    return 0;
}

int
PLCB_args_observe(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDOBSERVE *cmd)
{
    int master_only = 0;
    plcb_OPTION argspecs[] = {
            PLCB_KWARG(PLCB_ARG_K_MASTERONLY, BOOL, &master_only),
            {NULL}
    };

    if (args->cmdopts) {
        plcb_extract_args(args->cmdopts, argspecs);
    }
    if (master_only) {
        cmd->cmdflags |= LCB_CMDOBSERVE_F_MASTER_ONLY;
    }
    return 0;
}

#define is_append(cmd) (cmd) == PLCB_CMD_APPEND || (cmd) == PLCB_CMD_PREPEND

int
PLCB_args_set(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDSTORE *scmd, plcb_DOCVAL *vspec)
{
    UV exp = 0;
    SV *dur_sv = NULL;
    int ignore_cas = 0;
    int persist_to = 0, replicate_to = 0;
    plcb_OPTION doc_specs[] = {
        PLCB_KWARG(PLCB_ARG_K_VALUE, SV, &vspec->value),
        PLCB_KWARG(PLCB_ARG_K_EXPIRY, EXP, &exp),
        PLCB_KWARG(PLCB_ARG_K_CAS, CAS, &scmd->cas),
        PLCB_KWARG(PLCB_ARG_K_FMT, U32, &vspec->spec),
        {NULL}
    };
    plcb_OPTION opt_specs[] = {
        PLCB_KWARG(PLCB_ARG_K_IGNORECAS, BOOL, &ignore_cas),
        PLCB_KWARG(PLCB_ARG_K_FRAGMENT, SV, &vspec->value),
        PLCB_KWARG(PLCB_ARG_K_PERSIST, INT, &persist_to),
        PLCB_KWARG(PLCB_ARG_K_REPLICATE, INT, &replicate_to),
        { NULL }
    };

    if (is_append(args->cmdbase)) {
        doc_specs[0].type = PLCB_ARG_T_PAD;
        vspec->spec = PLCB_CF_UTF8;
    } else {
        vspec->spec = PLCB_CF_JSON;
        opt_specs[1].type = PLCB_ARG_T_PAD;
    }

    load_doc_options(object, args->docav, doc_specs);
    if (args->cmdopts) {
        plcb_extract_args(args->cmdopts, opt_specs);
    }

    scmd->exptime = exp;
    if (ignore_cas) {
        scmd->cas = 0;
    }

    if (is_append(args->cmdbase)) {
        scmd->exptime = 0;
    } else if (args->cmdbase == PLCB_CMD_ADD) {
        scmd->cas = 0;
    }

    dur_sv = *av_fetch(args->docav, PLCB_RETIDX_OPTIONS, 1);
    if (SvIOK(dur_sv)) {
        SvUVX(dur_sv) = PLCB_MKDURABILITY(persist_to, replicate_to);
    } else {
        sv_setuv(dur_sv, PLCB_MKDURABILITY(persist_to, replicate_to));
    }

    if (vspec->value == NULL || SvTYPE(vspec->value) == SVt_NULL) {
        die("Must have value!");
    }

    if (is_append(args->cmdbase)) {
        if (vspec->spec != PLCB_CF_UTF8 && vspec->spec != PLCB_CF_RAW) {
            die("append and prepend must use 'raw' or 'utf8' formats");
        }
    }
    return 0;
}

int
PLCB_args_http(PLCB_t *object, plcb_SINGLEOP *args, lcb_CMDHTTP *htcmd)
{
    int ht_type = LCB_HTTP_TYPE_VIEW;
    int ht_meth = LCB_HTTP_METHOD_GET;
    PLCB_XS_STRING_t body = { NULL };

    plcb_OPTION argspecs[] = {
        PLCB_KWARG("type", U32, &ht_type),
        PLCB_KWARG("method", U32, &ht_meth),
        PLCB_KWARG("body", STRING, &body),
        PLCB_KWARG("content_type", CSTRING, &htcmd->content_type),
        PLCB_KWARG("username", CSTRING, &htcmd->username),
        PLCB_KWARG("password", CSTRING, &htcmd->password),
        PLCB_KWARG("host", CSTRING, &htcmd->host),
        {NULL}
    };

    if (!args->cmdopts) {
        die("Must have options!");
    }
    plcb_extract_args(args->cmdopts, argspecs);
    htcmd->body = body.base;
    htcmd->nbody = body.len;
    htcmd->type = ht_type;
    htcmd->method = ht_meth;
    return 0;
}
