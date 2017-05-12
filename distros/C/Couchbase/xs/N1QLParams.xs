#include "perl-couchbase.h"
#include "plcb-util.h"
#include <libcouchbase/n1ql.h>

MODULE = Couchbase::N1QL::Params PACKAGE = Couchbase::N1QL::Params PREFIX = N1P_

PROTOTYPES: DISABLE

SV *
N1P_new(SV *)
    PREINIT:
    HV *stash;

    CODE:
    lcb_N1QLPARAMS *pp = lcb_n1p_new();
    RETVAL = newRV_noinc(newSVuv(PTR2UV(pp)));
    stash = gv_stashpv("Couchbase::N1QL::Params", GV_ADD);
    sv_bless(RETVAL, stash);
    OUTPUT: RETVAL

void
N1P_DESTROY(lcb_N1QLPARAMS *params)
    CODE:
    lcb_n1p_free(params);

void
N1P_setquery(lcb_N1QLPARAMS *params, const char *query, int type)
    PREINIT:
    lcb_error_t rc;
    CODE:
    rc = lcb_n1p_setquery(params, query, -1, type);
    if (rc != LCB_SUCCESS) {
        die("Couldn't set query `%s`: %s (0x%x)", query, lcb_strerror(NULL, rc), rc);
    }

void
N1P_namedparam(lcb_N1QLPARAMS *params, const char *name, const char *value)
    PREINIT:
    lcb_error_t rc;
    CODE:
    rc = lcb_n1p_namedparamz(params, name, value);
    if (rc != LCB_SUCCESS) {
        die("Couldn't set named param %s=%s: %s (0x%x)", name, value, lcb_strerror(NULL, rc), rc);
    }

void
N1P_posparam(lcb_N1QLPARAMS *params, const char *value)
    PREINIT:
    lcb_error_t rc;
    CODE:
    rc =lcb_n1p_posparam(params, value, -1);
    if (rc != LCB_SUCCESS) {
        die("Couldn't add positional argument %s: %s (0x%x)", value, lcb_strerror(NULL, rc), rc);
    }

void
N1P_setopt(lcb_N1QLPARAMS *params, const char *option, const char *value)
    PREINIT:
    lcb_error_t rc;
    CODE:
    rc = lcb_n1p_setoptz(params, option, value);
    if (rc != LCB_SUCCESS) {
        die("Couldn't set option %s=%s: %s (0x%x)", option, value, lcb_strerror(NULL, rc), rc);
    }
