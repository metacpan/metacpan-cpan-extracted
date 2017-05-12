#include "perl-couchbase.h"
#include "plcb-util.h"
#include <libcouchbase/vbucket.h>


MODULE = Couchbase::BucketConfig PACKAGE = Couchbase::BucketConfig    PREFIX = VB_

PROTOTYPES: DISABLE


int
VB_ix_master(lcbvb_CONFIG *vbc, unsigned vbucket)
    CODE:
    RETVAL = lcbvb_vbmaster(vbc, vbucket);
    OUTPUT: RETVAL

int
VB_ix_replica(lcbvb_CONFIG *vbc, int vbucket, unsigned ix)
    CODE:
    RETVAL = lcbvb_vbreplica(vbc, vbucket, ix);
    OUTPUT: RETVAL

int
VB_to_vbucket(lcbvb_CONFIG *vbc, SV *input)
    PREINIT:
    STRLEN n = 0;
    const char *s = NULL;
    CODE:
    s = SvPV(input, n);
    if (!n) {
        die("Passed empty key");
    }
    RETVAL = lcbvb_k2vb(vbc, s, n);
    OUTPUT: RETVAL

const char *
VB__gethostport(lcbvb_CONFIG *vbc, unsigned ix, unsigned svc, unsigned mode)
    CODE:
    RETVAL = lcbvb_get_hostport(vbc, ix, svc, mode);
    if (RETVAL == NULL) { RETVAL = ""; }
    OUTPUT: RETVAL

const char *
VB__getcapi(lcbvb_CONFIG *vbc, unsigned ix, int mode)
    CODE:
    RETVAL = lcbvb_get_capibase(vbc, ix, mode);
    if (RETVAL == NULL) { RETVAL = ""; }
    OUTPUT: RETVAL

int
VB_nservers(lcbvb_CONFIG *vbc)
    CODE:
    RETVAL = lcbvb_get_nservers(vbc);
    OUTPUT: RETVAL

int
VB_nreplicas(lcbvb_CONFIG *vbc)
    CODE:
    RETVAL = lcbvb_get_nreplicas(vbc);
    OUTPUT: RETVAL

int
VB_rev(lcbvb_CONFIG *vbc)
    CODE:
    RETVAL = lcbvb_get_revision(vbc);
    OUTPUT: RETVAL

SV *
VB_dump(lcbvb_CONFIG *cfg)
    PREINIT:
    SV *sv;
    char *s;

    CODE:
    s = lcbvb_save_json(cfg);
    if (!s) {
        die("Couldn't get JSON!");
    }
    sv = newSV(0);
    sv_usepvn(sv, s, strlen(s));
    RETVAL = sv;
    OUTPUT: RETVAL

lcbvb_CONFIG *
VB_load(const char *s)
    PREINIT:
    lcbvb_CONFIG * vbc;

    CODE:
    vbc = lcbvb_create();
    if (!vbc) {
        die("Couldn't allocate memory");
    }
    if (0 != lcbvb_load_json(vbc, s)) {
        const char *err = lcbvb_get_error(vbc);
        lcbvb_destroy(vbc);
        die("Couldn't load json: %s", err);
    }
    RETVAL = vbc;
    OUTPUT: RETVAL

void
VB_DESTROY(lcbvb_CONFIG *cfg)
    CODE:
    lcbvb_destroy(cfg);
