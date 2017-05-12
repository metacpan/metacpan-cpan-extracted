#define PERL_NO_GET_CONTEXT      /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "lru.h"

#define CACHE_DEFAULT_SIZE 1000

static int cache_dtor(pTHX_ SV *sv, MAGIC *mg) {
    Cache* cache = (Cache*) mg->mg_ptr;
    cache_destroy(aTHX_ cache);
    return 0;
}

static void cache_visit(Cache* cache, CacheEntry* entry, void* arg)
{
    /* TODO: find out if we really need to call all these magic macros */
    dTHX;
    dSP;
    if (!cache || !entry || !arg) {
        return;
    }
    ENTER;
    SAVETMPS;

    EXTEND(SP, 2);
    PUSHMARK(SP);
    PUSHs(newSVsv(entry->key));
    PUSHs(entry->val);
    PUTBACK;

    SV* cb = (SV*) arg;
    call_sv(cb, G_SCALAR | G_EVAL | G_DISCARD);

    SPAGAIN;

    PUTBACK;
    FREETMPS;
    LEAVE;
}

static MGVTBL session_magic_vtbl = { .svt_free = cache_dtor };

MODULE = Cache::utLRU        PACKAGE = Cache::utLRU
PROTOTYPES: DISABLE

#################################################################

Cache*
new(char* CLASS, int size = 0)
CODE:
{
    if (size <= 0) {
        size = CACHE_DEFAULT_SIZE;
    }
    RETVAL = cache_build(aTHX_ size);
    if (!RETVAL) {
        croak("could not create cache");
    }
}
OUTPUT: RETVAL

int
size(Cache* cache)
CODE:
{
    RETVAL = cache_size(aTHX_ cache);
}
OUTPUT: RETVAL

int
capacity(Cache* cache)
CODE:
{
    RETVAL = cache_capacity(aTHX_ cache);
}
OUTPUT: RETVAL

void
clear(Cache* cache)
CODE:
{
    cache_clear(aTHX_ cache);
}

void
add(Cache* cache, SV* key, SV* val)
CODE:
{
    if (!key || !SvOK(key) || !SvPOK(key)) {
        croak("add key argument must be a string");
    }
    if (!val || !SvOK(val)) {
        croak("add value argument must be an actual value");
    }
    if (!cache_add(aTHX_ cache, key, val)) {
        croak("could not add element to cache");
    }
}

void
find(Cache* cache, SV* key)
PPCODE:
{
    /* We use PPCODE because XS mortalizes the return value */
    if (!key || !SvOK(key) || !SvPOK(key)) {
        croak("find key argument must be a string");
    }
    ST(0) = cache_find(aTHX_ cache, key);
    XSRETURN(1);
}

void
visit(Cache* cache, SV* cb)
CODE:
{
    if (!cb || !SvOK(cb) || !SvROK(cb) || SvTYPE(SvRV(cb)) != SVt_PVCV) {
        croak("visit cb argument must be a coderef");
    }
    cache_iterate(aTHX_ cache, cache_visit, cb);
}
