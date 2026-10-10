#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "bloom.h"

MODULE = Algorithm::BloomFilter		PACKAGE = Algorithm::BloomFilter
PROTOTYPES: DISABLE

TYPEMAP: <<HERE
bloom_t*	O_OBJECT

OUTPUT

O_OBJECT
  sv_setref_pv( $arg, CLASS, (void*)$var );

INPUT

O_OBJECT
  if ( sv_isobject($arg) && sv_isa($arg, \"Algorithm::BloomFilter\") && (SvTYPE(SvRV($arg)) == SVt_PVMG) )
    $var = ($type)SvIV((SV*)SvRV( $arg ));
  else
    croak( \"${Package}::$func_name() -- $var is not a blessed SV reference\" );

HERE

bloom_t *
new(const char *CLASS, UV n_bits, UV k_hashes)
  CODE:
    RETVAL = bl_alloc(n_bits, k_hashes, bl_siphash);
    if (!RETVAL)
      croak("Out of memory!");
  OUTPUT: RETVAL

void
DESTROY(bloom_t *bl)
  CODE:
    bl_free(bl);

void
add(bloom_t *bl, ...)
  PREINIT:
    const unsigned char *str;
    STRLEN len;
    unsigned int i;
    SV *value;
  PPCODE:
    for (i = 1; i < items; ++i) {
      value = ST(i);
      str = (const unsigned char *)SvPVbyte(value, len);
      bl_add(bl, str, len);
    }

IV
test(bloom_t *bl, SV *value)
  PREINIT:
    const unsigned char *str;
    STRLEN len;
  CODE:
    str = (const unsigned char *)SvPVbyte(value, len);
    RETVAL = (IV)bl_test(bl, str, len);
  OUTPUT: RETVAL

SV *
serialize(bloom_t *bl)
  PREINIT:
    char *out;
    size_t len;
  CODE:
    if (0 != bl_serialize(bl, &out, &len))
      croak("Failed to serialize bloom filter - OOM?");
    RETVAL = newSVpvn(out, len);
    free(out);
  OUTPUT: RETVAL

SV *
deserialize(const char *CLASS, SV *blob)
  PREINIT:
    char *str;
    STRLEN len;
    bloom_t *bl;
  CODE:
    str = SvPVbyte(blob, len);
    bl = bl_deserialize(str, len, bl_siphash);
    if (!bl)
      XSRETURN_UNDEF;
    RETVAL = sv_setref_pv(newSV(0), CLASS, (void *)bl);
  OUTPUT: RETVAL

void
merge(bloom_t *self, bloom_t *other)
  PREINIT:
    int result;
  CODE:
    result = bl_merge(self, other);
    if (result)
      croak("Failed to merge bloom filters: "
            "They are of incompatible sizes/configurations");

