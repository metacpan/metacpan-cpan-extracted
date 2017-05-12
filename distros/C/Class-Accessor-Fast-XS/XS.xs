#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AutoXS.h"

MODULE = Class::Accessor::Fast::XS    PACKAGE = Class::Accessor::Fast::XS


void
_xs_ro_accessor(self, ...)
    SV* self;
  PROTOTYPE: DISABLE
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = AutoXS_hashkeys[ix];
    HE* he;
  PPCODE:
    if ( items > 1 )
        croak("cannot alter readonly value");

    if ( he = hv_fetch_ent((HV *)SvRV(self), readfrom.key, 0, readfrom.hash) )
        PUSHs(HeVAL(he));
    else
        XSRETURN_UNDEF;

void
_xs_wo_accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    HE *res;
    SV *newvalue;
    IV i;
    const autoxs_hashkey readfrom = AutoXS_hashkeys[ix];
  PPCODE:
    if ( items == 2 ) {
        newvalue = newSVsv(ST(1));
    } else if ( items > 2 ) {
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for(i = 1; i < items; i++) {
            newvalue = newSVsv(ST(i));
            if (!av_store(tmp, i - 1, newvalue)) {
                SvREFCNT_dec(newvalue);
                croak("cannot store value in array");
            }
        }
        newvalue = newRV_noinc((SV*) tmp);
    } else {
        croak("cannot access writeonly value");
    }

    if (res = hv_store_ent((HV*)SvRV(self), readfrom.key, newvalue, readfrom.hash)) {
        PUSHs(HeVAL(res));
    } else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
    }

void
_xs_accessor(self, ...)
    SV* self;
  ALIAS:
  INIT:
    HE *res;
    SV *newvalue;
    IV i;
    /* Get the const hash key struct from the global storage */
    /* ix is the magic integer variable that is set by the perl guts for us.
     * We uses it to identify the currently running alias of the accessor. Gollum! */
    const autoxs_hashkey readfrom = AutoXS_hashkeys[ix];
  PPCODE:
    if ( items == 1 ) {
        res = hv_fetch_ent((HV *)SvRV(self), readfrom.key, 0, readfrom.hash);
        if (res == NULL)
            XSRETURN_UNDEF;

        PUSHs(HeVAL(res));
        XSRETURN(1);
    }
    else if ( items == 2 ) {
        newvalue = newSVsv(ST(1));
    }
    else {
        AV* tmp = newAV();
        av_extend(tmp, items-1);
        for(i = 1; i < items; i++) {
            newvalue = newSVsv(ST(i));
            if (!av_store(tmp, i - 1, newvalue)) {
                SvREFCNT_dec(newvalue);
                croak("Cannot store value in array");
            }
        }
        newvalue = newRV_noinc((SV*) tmp);
    }
    if (res = hv_store_ent((HV*)SvRV(self), readfrom.key, newvalue, readfrom.hash)) {
        PUSHs(HeVAL(res));
    } else {
        SvREFCNT_dec(newvalue);
        croak("Failed to write new value to hash.");
    }

void
xs_make_ro_accessor(name, key)
  char* name;
  char* key;
  INIT:
    autoxs_hashkey hashkey;
    unsigned int len;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_hashkey();
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__Accessor__Fast__XS__xs_ro_accessor, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      /* Precompute the hash of the key and store it in the global structure */
      len = strlen(key);
      hashkey.key = newSVpvn(key, len);
      PERL_HASH(hashkey.hash, key, len);
      AutoXS_hashkeys[functionIndex] = hashkey;
    }

void
xs_make_wo_accessor(name, key)
  char* name;
  char* key;
  INIT:
    autoxs_hashkey hashkey;
    unsigned int len;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_hashkey();
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__Accessor__Fast__XS__xs_wo_accessor, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      /* Precompute the hash of the key and store it in the global structure */
      len = strlen(key);
      hashkey.key = newSVpvn(key, len);
      PERL_HASH(hashkey.hash, key, len);
      AutoXS_hashkeys[functionIndex] = hashkey;
    }

void
xs_make_accessor(name, key)
  char* name;
  char* key;
  INIT:
    autoxs_hashkey hashkey;
    unsigned int len;
  PPCODE:
    char* file = __FILE__;
    const unsigned int functionIndex = get_next_hashkey();
    {
      CV * cv;
      /* This code is very similar to what you get from using the ALIAS XS syntax.
       * Except I took it from the generated C code. Hic sunt dragones, I suppose... */
      cv = newXS(name, XS_Class__Accessor__Fast__XS__xs_accessor, file);
      if (cv == NULL)
        croak("ARG! SOMETHING WENT REALLY WRONG!");
      XSANY.any_i32 = functionIndex;

      /* Precompute the hash of the key and store it in the global structure */
      len = strlen(key);
      hashkey.key = newSVpvn(key, len);
      PERL_HASH(hashkey.hash, key, len);
      AutoXS_hashkeys[functionIndex] = hashkey;
    }

