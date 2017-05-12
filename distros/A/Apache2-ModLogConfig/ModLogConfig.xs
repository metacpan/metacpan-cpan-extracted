#include <mod_perl.h>
#include <mod_log_config.h>
#include <ctype.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/********************************************************************/
/********************************************************************/
# undef DEBUG
/********************************************************************/
/********************************************************************/

# ifdef DEBUG
# define W warn
# else
# define W if(0) warn
# endif

#include "ppport.h"

# ifndef MP_dTHX
#   ifdef PERL_IMPLICIT_CONTEXT
#     define MP_dTHX                                                        \
        modperl_interp_t *interp=modperl_interp_select(r, NULL, r->server); \
        dTHXa(interp->perl)
#     define MP_uTHX modperl_interp_unselect(interp)
#   else  /* PERL_IMPLICIT_CONTEXT */
#     define MP_dTHX dNOOP
#     define MP_uTHX dNOOP
#   endif
# endif

# ifndef MP_uTHX
#   define MP_uTHX NOOP
# endif

# define PREFIX "@perl:"
# define HND_KEY "^"
# define PPROC_KEY "modperl: Apache2::ModLogConfig"

static ap_log_writer_init *old_writer_init;
static ap_log_writer *old_writer;

typedef struct {
  int type;
  void *handle;
  char *name;
} writer_t;

typedef writer_t* Apache2__CustomLog;
typedef server_rec* Apache2__ServerRec;
typedef request_rec* Apache2__RequestRec;

static void*
writer_init(apr_pool_t *plog, server_rec *s, const char* name)
{
  const char *sp;
  writer_t *w;
  apr_hash_t *ghash, *shash;
  apr_pool_t *pconf=modperl_global_get_pconf();

  w=apr_palloc(pconf, sizeof(*w));
  w->name=apr_pstrdup(pconf, name);

  if( strncmp( PREFIX, name, sizeof(PREFIX)-1 ) ) {
    w->handle=old_writer_init(pconf, s, name);
    w->type=0;
  } else {
    sp=name+sizeof(PREFIX)-1;
    while( *sp && isspace(*sp) ) sp++;
    if( !*sp ) {
      w->handle=old_writer_init(pconf, s, name);
      w->type=0;
    } else {
      w->handle=modperl_handler_new(pconf, apr_pstrdup(pconf, sp));
      w->type=1;
    }
  }

  /* $ghash->{serveraddr}->{name}=w */

  /* fetch/init global hash */
  apr_pool_userdata_get((void**)&ghash, PPROC_KEY, pconf);
  if( !ghash ) {
    ghash=apr_hash_make(pconf);
    apr_pool_userdata_setn(ghash, PPROC_KEY, apr_pool_cleanup_null, pconf);
  }

  /* fetch/init per-server hash */
  shash=apr_hash_get(ghash, &s, sizeof(s));
  if( !shash ) {
    shash=apr_hash_make(pconf);
    apr_hash_set(ghash, apr_pmemdup(pconf, &s, sizeof(s)), sizeof(s), shash);
  }

  apr_hash_set(shash, w->name, strlen(w->name), w);

  return w;
}

static apr_status_t
writer(request_rec *r, void *handle, const char **strs,
       int *strl, int nelts, apr_size_t len)
{
  writer_t *w=handle;

  switch(w->type) {
  case 0:
    return old_writer(r, w->handle, strs, strl, nelts, len);
  case 1:
    {
      int status, i;
      MP_dTHX;
      AV *av=newAV();

      av_extend(av, nelts);
      av_store(av, 0, modperl_ptr2obj(aTHX_ "Apache2::RequestRec", r));
      for(i=0; i<nelts; i++) av_store(av, i+1, newSVpvn(strs[i], strl[i]));

      if((status=modperl_callback(aTHX_ w->handle, r->pool, r,
				  r->server, av))!=OK) {
	modperl_errsv(aTHX_ status, r, r->server);
      }

      SvREFCNT_dec(av);

      MP_uTHX;
    }
    return OK;
  }

  return OK;
}

static const char*
log_perl(request_rec *r, char *a)
{
  if( a && *a ) {
    I32 count;
    MP_dTHX;
    dSP;
    SV *sv;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(modperl_ptr2obj(aTHX_ "Apache2::RequestRec", r)));

    PUTBACK;
    count=call_pv(a, G_SCALAR|G_EVAL);
    SPAGAIN;

    if( SvTRUE(ERRSV) ) {
      (void)POPs;		/* G_SCALAR leaves exactly one value:
				 * undef here */
      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
		    "'%s' log format handler died: %s",
		    HND_KEY, SvPVX(ERRSV));
      a="";
    } else if( count==1 ) {
      STRLEN len;
      sv=POPs;
      a=SvPVbyte(sv, len);
      a=apr_pstrmemdup(r->pool, a, len);
    } else {
      ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
		    "'%s' log format handler died: internal error - "
		    "multiple return values (must not happen)", HND_KEY);
      while( count-- ) (void)POPs;
    }

    PUTBACK;
    FREETMPS; LEAVE;

    MP_uTHX;
    return a;
  } else {
    ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r,
		  "invalid empty function in '%s' log format specification",
		  HND_KEY);
    return "";
  }
}

struct writer_pair {
  ap_log_writer_init *wi;
  ap_log_writer *w;
};

# define VER(a,b,c) (1000000*(a)+1000*(b)+c)
# define AP_VER VER(AP_SERVER_MAJORVERSION_NUMBER,  \
		    AP_SERVER_MINORVERSION_NUMBER,  \
		    AP_SERVER_PATCHLEVEL_NUMBER)

static int
openlogs(apr_pool_t *pconf, apr_pool_t *plog, apr_pool_t *ptemp, server_rec *s)
{
  APR_OPTIONAL_FN_TYPE(ap_log_set_writer_init) *set_writer_init;
  APR_OPTIONAL_FN_TYPE(ap_log_set_writer) *set_writer;

  set_writer_init = APR_RETRIEVE_OPTIONAL_FN(ap_log_set_writer_init);
  set_writer      = APR_RETRIEVE_OPTIONAL_FN(ap_log_set_writer);

  if( !set_writer_init || !set_writer ) {
    ap_log_error(APLOG_MARK, APLOG_ERR, 0, s,
		 "ap_log_set_writer_init() or ap_log_set_writer() not found, "
		 "you have probably loaded a wrong mod_log_config");
    return DECLINED;
  }

  W("V=%d", AP_VER);

# if AP_VER <= 2002017

  /* We cannot rely here on apache cleaning up properly on restart.
   * Unfortunately there is a bug at least up to httpd 2.2.17 that prevents
   * the writer_init() and writer() values in mod_log_config to be
   * reinitialized to the default values when compiled statically in. So, it
   * may happen here that set_writer_init() returns our writer_init instead
   * of mod_log_config's.
   *
   *   see also https://issues.apache.org/bugzilla/show_bug.cgi?id=50861
   *
   * Further, there is no way to store the values in global variables
   * here because the shared lib is unloaded during restart and hence all
   * globals are reset.
   *
   * To solve the problem we store the original values as userdata in the
   * process pool. Fortunately, that one is accessible here. */

  {
    ap_module_symbol_t *mod;
    int is_static=0;
    for (mod=ap_prelinked_module_symbols; mod->name; mod++) {
      W("found static module %s", mod->name);
      if (!strcmp(mod->name, "log_config_module")) {is_static=1; break;}
    }

    if (is_static) {
      /* this is the problematic case. try to do the best */
      apr_pool_t *pproc=s->process->pool;
      struct writer_pair *w;

      apr_pool_userdata_get((void**)&w, PPROC_KEY, pproc);
      if( w ) {
	old_writer_init=w->wi;
	old_writer=w->w;
	W("found userdata: %p %p / %p %p",
	  old_writer_init, old_writer, writer_init, writer);
      } else {
	old_writer_init=set_writer_init(writer_init);
	old_writer=set_writer(writer);

	w=apr_palloc(pproc, sizeof(*w));
	w->wi=old_writer_init;
	w->w=old_writer;
	apr_pool_userdata_set(w, PPROC_KEY, apr_pool_cleanup_null, pproc);
	W("set up userdata: %p %p / %p %p",
	  old_writer_init, old_writer, writer_init, writer);
      }
    } else {
      old_writer_init=set_writer_init(writer_init);
      old_writer=set_writer(writer);

      if(old_writer_init==writer_init) croak("buggy");
    }
  }

# else	/* AP_VER < 2002017 */

  old_writer_init=set_writer_init(writer_init);
  old_writer=set_writer(writer);

  if(old_writer_init==writer_init) croak("buggy");

# endif

  return OK;
}

static void
boot_me_up(void)
{
  apr_pool_t *pconf=modperl_global_get_pconf();
  APR_OPTIONAL_FN_TYPE(ap_register_log_handler) *log_register;

  log_register=APR_RETRIEVE_OPTIONAL_FN(ap_register_log_handler);
  if( !log_register ) croak("mod_log_config not loaded");

  log_register(pconf, HND_KEY, log_perl, 0);

  ap_hook_open_logs(openlogs, NULL, NULL, APR_HOOK_REALLY_FIRST);
}

MODULE = Apache2::ModLogConfig	PACKAGE = Apache2::ServerRec

PROTOTYPES: DISABLE

void
custom_logs(s)
  Apache2::ServerRec s
  PPCODE:
  {
    apr_pool_t *pconf=modperl_global_get_pconf();
    apr_hash_t *hash;

    apr_pool_userdata_get((void**)&hash, PPROC_KEY, pconf);
    if( hash ) {
      hash=apr_hash_get(hash, &s, sizeof(s));
      if( hash ) {
	apr_pool_t *p;
	apr_hash_index_t *hi;

	apr_pool_create(&p, pconf);
	for( hi=apr_hash_first(p, hash); hi; hi=apr_hash_next(hi) ) {
	  const char *k;
	  apr_ssize_t klen;
	  void *val;
	  apr_hash_this(hi, (const void**)&k, &klen, &val);
	  mXPUSHs(newSVpv(k, klen));
	}
	apr_pool_destroy(p);
      }
    }
  }

void
custom_log_by_name(s, name)
  Apache2::ServerRec s
  SV* name
  PPCODE:
  {
    apr_pool_t *pconf=modperl_global_get_pconf();
    apr_hash_t *hash;

    apr_pool_userdata_get((void**)&hash, PPROC_KEY, pconf);
    if( hash ) {
      hash=apr_hash_get(hash, &s, sizeof(s));
      if( hash ) {
	STRLEN len;
	char *str=SvPV(name, len);
	Apache2__CustomLog log=apr_hash_get(hash, str, len);
	if( log ) {
	  mXPUSHs(modperl_ptr2obj(aTHX_ "Apache2::CustomLog", log));
	}
      }
    }
  }

MODULE = Apache2::ModLogConfig	PACKAGE = Apache2::CustomLog

void
print(log, r, ...)
  Apache2::CustomLog log
  Apache2::RequestRec r
  PPCODE:
  if(items>2) {
    apr_pool_t *p;
    const char **strs;
    int *strl;
    int i;
    apr_size_t len=0;
    apr_status_t rv;

    apr_pool_create(&p, r->pool);
    strs=apr_palloc(p, (items-2)*sizeof(*strs));
    strl=apr_palloc(p, (items-2)*sizeof(*strl));
    for( i=2; i<items; i++ ) {
      STRLEN l;
      strs[i-2]=SvPV(ST(i), l);
      strl[i-2]=l;
      len+=strl[i-2];
    }
    rv=writer(r, log, strs, strl, items-2, len);
    apr_pool_destroy(p);
    mXPUSHi(rv);
  }

BOOT:
  boot_me_up();

## Local Variables: ##
## mode: c ##
## End: ##

