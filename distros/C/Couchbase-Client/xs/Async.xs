#include "perl-couchbase-async.h"

MODULE = Couchbase::Client PACKAGE = Couchbase::Client::Async PREFIX = PLCBA_

SV *
PLCBA_construct(pkg, options)
    const char *pkg
    AV *options


SV *
PLCBA__get_base_rv(self)
    SV *self
    
    PREINIT:
    SV *ret;
    
    CODE:
    /*this returns the underlying 'base' object, for selected proxy-methods*/
    if(!SvROK(self)) {
        die("I was not given a reference");
    }
    RETVAL = newRV_inc(SvRV(self));
    
    OUTPUT:
    RETVAL

void
PLCBA_connect(self)
    SV* self

void
PLCBA_HaveEvent(pkg, flags, opaque)
    const char *pkg
    short flags
    SV *opaque
    
void
PLCBA_request(self, cmd, reqtype, callcb, cbdata, cbtype, params)
    SV *self
    int cmd
    int reqtype
    SV *callcb
    SV *cbdata
    int cbtype
    AV *params
