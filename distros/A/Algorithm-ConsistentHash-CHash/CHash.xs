#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "libchash.h"

MODULE = Algorithm::ConsistentHash::CHash PACKAGE = Algorithm::ConsistentHash::CHash

TYPEMAP: <<HERE
struct chash_t *	O_OBJECT

OUTPUT

O_OBJECT
  sv_setref_pv( $arg, CLASS, (void*)$var );

INPUT

O_OBJECT
  if ( sv_isobject($arg) && (SvTYPE(SvRV($arg)) == SVt_PVMG) )
    $var = INT2PTR($type, SvIV((SV*)SvRV( $arg )));
  else
    croak( \"${Package}::$func_name() -- $var is not a blessed SV reference\" );
HERE


### new({ids => [key1, key2, key3], replicas => 123})

struct chash_t *
new(CLASS, ...)
    char *CLASS
  PREINIT:
    HV *params;
    I32 i;
    SV **svp;
    AV *ids;
    size_t replicas;
    const char **keys;
    size_t *lens;
    size_t nkeys;
    SV *keys_guard;
    SV *lens_guard;
  CODE:
    if ( (items-1) % 2 )
      croak("Even number of parameters expected!");

    params = (HV *)sv_2mortal( (SV*)newHV() );
    for (i = 1; i < items; i += 2) {
      SV *keyname = ST(i);
      SV *value   = ST(i+1);
      SvREFCNT_inc(value); /* hv_store_ent acquires a refcount ownership */
      hv_store_ent(params, keyname, value, 0);
    }

    /* Find the ids part */
    svp = hv_fetchs(params, "ids", 0);
    if (!svp || !SvROK(*svp) || SvTYPE(SvRV(*svp)) != SVt_PVAV)
      croak("Expected an 'ids' parameter that is an array reference");

    ids = (AV *)SvRV(*svp);

    /* Now find replicas */
    svp = hv_fetchs(params, "replicas", 0);
    if (!svp)
      croak("Expected an 'replicas' parameter");

    replicas = SvIV(*svp);
    if (replicas == 0)
      croak("Cannot work with zero replicas!");

    nkeys = av_len(ids)+1;

    /* Allocate memory in an exception-safe manner */
    keys_guard = sv_2mortal( newSV( nkeys * sizeof(char *) ) );
    keys = (const char **)SvPVX(keys_guard);

    lens_guard = sv_2mortal( newSV( nkeys * sizeof(size_t) ) );
    lens = (size_t *)SvPVX(lens_guard);

    for (i = 0; i < nkeys; ++i) {
      char *k;
      STRLEN len;

      svp = av_fetch(ids, i, 0);
      if (svp == NULL) {
        /* this is wrong */
        len = 0;
        k = NULL;
      }
      else {
        k = SvPVbyte(*svp, len); /* FIXME is this correct for UTF8? */
      }

      keys[i] = k;
      lens[i] = len;
      /* fprintf(stderr, "node => '%s', len => %u\n", k, len); */
    }

    /* fprintf(stderr, "nkeys => %u, replicas => %u\n", nkeys, replicas); */
    RETVAL = chash_create(keys, lens, nkeys, replicas);

    if (RETVAL == NULL)
      croak("Unknown error");
  OUTPUT: RETVAL


void
DESTROY(self)
    struct chash_t *self
  CODE:
    chash_free(self);

SV *
lookup(self, key)
    struct chash_t *self
    SV *key;
  PREINIT:
    const char *out_str;
    size_t out_str_len;
    const char *key_str;
    STRLEN key_len;
  CODE:
    key_str = SvPVbyte(key, key_len);
    chash_lookup(self, key_str, key_len, &out_str, &out_str_len);
    RETVAL = newSVpvn(out_str, out_str_len);
  OUTPUT: RETVAL

