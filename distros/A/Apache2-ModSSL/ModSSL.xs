#include <mod_perl.h>

/* mod_ssl.h is not safe for inclusion in 2.0, so duplicate the
 * optional function declarations. */
APR_DECLARE_OPTIONAL_FN(char *, ssl_var_lookup,
                        (apr_pool_t *, server_rec *,
                         conn_rec *, request_rec *,
                         char *));
APR_DECLARE_OPTIONAL_FN(int, ssl_is_https, (conn_rec *));
APR_DECLARE_OPTIONAL_FN(const char *, ssl_ext_lookup,
                        (apr_pool_t *p, conn_rec *c, int peer,
                         const char *oidnum));

typedef conn_rec *Apache2__Connection;

static APR_OPTIONAL_FN_TYPE(ssl_is_https) *is_https = NULL;
static APR_OPTIONAL_FN_TYPE(ssl_var_lookup) *lookup = NULL;
static APR_OPTIONAL_FN_TYPE(ssl_ext_lookup) *ext_lookup = NULL;

static int is_initialized=0;

static void
retrieve_functions(void)
{
  if( is_initialized ) return;
  is_initialized++;
  is_https=APR_RETRIEVE_OPTIONAL_FN(ssl_is_https);
  lookup=APR_RETRIEVE_OPTIONAL_FN(ssl_var_lookup);
  ext_lookup=APR_RETRIEVE_OPTIONAL_FN(ssl_ext_lookup);
}

MODULE = Apache2::ModSSL    PACKAGE = Apache2::Connection   PREFIX = mpxs_Apache2__Connection_

int
mpxs_Apache2__Connection_is_https(c)
    Apache2::Connection c
PROTOTYPE: $
CODE:
  {
    retrieve_functions();
    if( !is_https ) return XSRETURN_UNDEF;
    RETVAL=is_https(c);
  }
OUTPUT:
    RETVAL

void
mpxs_Apache2__Connection_ssl_var_lookup(c, var)
    Apache2::Connection c
    char *var
PROTOTYPE: $$
PPCODE:
  {
    apr_pool_t *p=NULL;
    apr_status_t stat;
    char buf[512];

    retrieve_functions();
    if( !lookup ) return XSRETURN_UNDEF;
    if( (stat=apr_pool_create( &p, NULL ))!=APR_SUCCESS ) {
      croak("Cannot create temp pool: %s", apr_strerror(stat, buf, sizeof(buf)));
    }
    PUSHs(sv_2mortal(newSVpv(lookup( p, c->base_server, c, NULL, var ), 0)));
    apr_pool_destroy( p );
  }

void
mpxs_Apache2__Connection_ssl_ext_lookup(c, peer, oid)
    Apache2::Connection c
    int peer
    char *oid
PROTOTYPE: $$
PPCODE:
  {
    apr_pool_t *p=NULL;
    apr_status_t stat;
    char buf[512];
    const char *ptr;

    retrieve_functions();
    if( !lookup ) return XSRETURN_UNDEF;
    if( (stat=apr_pool_create( &p, NULL ))!=APR_SUCCESS ) {
      croak("Cannot create temp pool: %s", apr_strerror(stat, buf, sizeof(buf)));
    }
    ptr=ext_lookup( p, c, peer, oid );
    if( ptr ) PUSHs(sv_2mortal(newSVpv(ptr, 0)));
    apr_pool_destroy( p );
  }

## Local Variables: ##
## mode: c ##
## End: ##
