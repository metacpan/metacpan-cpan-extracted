#ifdef MOD_PERL
#include "mod_perl.h"
#include "../proxy/mod_proxy.h"
#else
#include "modules/perl/mod_perl.h"
#include "modules/proxy/mod_proxy.h"
#endif

MODULE = Apache::Proxy		PACKAGE = Apache::Proxy

PROTOTYPES:DISABLE

int
pass(self, r, uri)
    SV *self
    Apache r
    char *uri

    PREINIT:
    cache_req *c = (cache_req *)safemalloc(sizeof(cache_req));

    CODE: 
    c->fp = NULL;
    c->req = r;

    RETVAL = ap_proxy_http_handler(r, c, uri, NULL, 0);
    safefree(c);
    OUTPUT:
    RETVAL

char*
proxy_hash(self, r, uri)
    SV *self
    Apache r
    char *uri

    PREINIT:
    void *sconf = r->server->module_config;
    proxy_server_conf *pconf = (proxy_server_conf *) ap_get_module_config(sconf, &proxy_module);
    char filename[66];
    
    CODE:
    ap_proxy_hash(uri, filename, pconf->cache.dirlevels, pconf->cache.dirlength);
    RETVAL = filename;

    OUTPUT:
    RETVAL

