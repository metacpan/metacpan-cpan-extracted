#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define RETCOPY(sv)		\
  if (GIMME_V != G_VOID)	\
    { 				\
      dXSTARG;			\
      sv_setsv (TARG, (sv));	\
      EXTEND (SP, 1);		\
      PUSHs (TARG);		\
    }

MODULE = Convert::Scalar		PACKAGE = Convert::Scalar

bool
utf8 (SV *scalar, SV *mode = NO_INIT)
        PROTOTYPE: $;$
        CODE:
        SvGETMAGIC (scalar);
        RETVAL = !!SvUTF8 (scalar);
        if (items > 1)
          {
            if (SvREADONLY (scalar))
              croak ("Convert::Scalar::utf8 called on read only scalar");
            if (SvTRUE (mode))
              SvUTF8_on (scalar);
            else
              SvUTF8_off (scalar);
          }
	OUTPUT:
        RETVAL

void
utf8_on (SV *scalar)
        PROTOTYPE: $
        PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_on called on read only scalar");

        SvGETMAGIC (scalar);
        SvUTF8_on (scalar);
        RETCOPY (scalar);

void
utf8_off (SV *scalar)
        PROTOTYPE: $
        PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_off called on read only scalar");

        SvGETMAGIC (scalar);
        SvUTF8_off (scalar);
        RETCOPY (scalar);

int
utf8_valid (SV *scalar)
        PROTOTYPE: $
        CODE:
        STRLEN len;
        char *str = SvPV (scalar, len);
        RETVAL = !!is_utf8_string (str, len);
	OUTPUT:
        RETVAL

void
utf8_upgrade (SV *scalar)
        PROTOTYPE: $
	PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_upgrade called on read only scalar");

        sv_utf8_upgrade(scalar);
        RETCOPY (scalar);

bool
utf8_downgrade (SV *scalar, bool fail_ok = 0)
        PROTOTYPE: $;$
	CODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_downgrade called on read only scalar");

        RETVAL = !!sv_utf8_downgrade (scalar, fail_ok);
	OUTPUT:
	RETVAL

void
utf8_encode (SV *scalar)
        PROTOTYPE: $
	PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_encode called on read only scalar");

        sv_utf8_encode (scalar);
        RETCOPY (scalar);

UV
utf8_length (SV *scalar)
        PROTOTYPE: $
	CODE:
        RETVAL = (UV) utf8_length (SvPV_nolen (scalar), SvEND (scalar));
	OUTPUT:
	RETVAL

bool
readonly (SV *scalar, SV *on = NO_INIT)
        PROTOTYPE: $;$
        CODE:
        RETVAL = SvREADONLY (scalar);
        if (items > 1)
          {
            if (SvTRUE (on))
              SvREADONLY_on (scalar);
            else
              SvREADONLY_off (scalar);
          }
	OUTPUT:
        RETVAL

void
readonly_on (SV *scalar)
        PROTOTYPE: $
        CODE:
        SvREADONLY_on (scalar);

void
readonly_off (SV *scalar)
        PROTOTYPE: $
        CODE:
        SvREADONLY_off (scalar);

void
unmagic (SV *scalar, char type)
        PROTOTYPE: $$
	CODE:
        sv_unmagic (scalar, type);

void
weaken (SV *scalar)
        PROTOTYPE: $
	CODE:
        sv_rvweaken (scalar);

void
taint (SV *scalar)
        PROTOTYPE: $
	CODE:
        SvTAINTED_on (scalar);

bool
tainted (SV *scalar)
        PROTOTYPE: $
        CODE:
        RETVAL = !!SvTAINTED (scalar);
	OUTPUT:
        RETVAL

void
untaint (SV *scalar)
        PROTOTYPE: $
	CODE:
        SvTAINTED_off (scalar);

STRLEN
len (SV *scalar)
	PROTOTYPE: $
	CODE:
        if (SvTYPE (scalar) < SVt_PV)
          XSRETURN_UNDEF;
        RETVAL = SvLEN (scalar);
	OUTPUT:
        RETVAL

void
grow (SV *scalar, STRLEN newlen)
        PROTOTYPE: $$
        PPCODE:
        sv_grow (scalar, newlen);
        if (GIMME_V != G_VOID)
          XPUSHs (sv_2mortal (SvREFCNT_inc (scalar)));

void
extend (SV *scalar, STRLEN addlen)
        PROTOTYPE: $$
        PPCODE:
{
	if (SvTYPE (scalar) < SVt_PV)
          sv_upgrade (scalar, SVt_PV);

        if (SvCUR (scalar) + addlen >= SvLEN (scalar))
          {
            STRLEN l = SvLEN (scalar);
            STRLEN o = SvCUR (scalar) + addlen >= 4096 ? sizeof (void *) * 4 : 0;

            if (l < 64)
              l = 64;

            /* for big sizes, leave a bit of space for malloc management, and assume 4kb or smaller pages */
            addlen += o;

            while (SvCUR (scalar) + addlen >= l)
              l <<= 1;

            l -= o;

            sv_grow (scalar, l);
          }

        if (GIMME_V != G_VOID)
          XPUSHs (sv_2mortal (SvREFCNT_inc (scalar)));
}

int
refcnt (SV *scalar, U32 newrefcnt = NO_INIT)
        PROTOTYPE: $;$
        ALIAS:
          refcnt_rv = 1
        CODE:
        if (ix)
          {
            if (!SvROK (scalar)) croak ("refcnt_rv requires a reference as it's first argument");
            scalar = SvRV (scalar);
          }
        RETVAL = SvREFCNT (scalar);
        if (items > 1)
          SvREFCNT (scalar) = newrefcnt;
	OUTPUT:
        RETVAL

void
refcnt_inc (SV *scalar)
        ALIAS:
          refcnt_inc_rv = 1
        PROTOTYPE: $
        CODE:
        if (ix)
          {
            if (!SvROK (scalar)) croak ("refcnt_inc_rv requires a reference as it's first argument");
            scalar = SvRV (scalar);
          }
        SvREFCNT_inc (scalar);

void
refcnt_dec (SV *scalar)
        ALIAS:
          refcnt_dec_rv = 1
        PROTOTYPE: $
        CODE:
        if (ix)
          {
            if (!SvROK (scalar)) croak ("refcnt_dec_rv requires a reference as it's first argument");
            scalar = SvRV (scalar);
          }
        SvREFCNT_dec (scalar);

bool
ok (SV *scalar)
        PROTOTYPE: $
        CODE:
        RETVAL = !!SvOK (scalar);
	OUTPUT:
        RETVAL

bool
uok (SV *scalar)
        PROTOTYPE: $
        CODE:
        RETVAL = !!SvUOK (scalar);
	OUTPUT:
        RETVAL

bool
rok (SV *scalar)
        PROTOTYPE: $
        CODE:
        RETVAL = !!SvROK (scalar);
	OUTPUT:
        RETVAL

bool
pok (SV *scalar)
        PROTOTYPE: $
        CODE:
        RETVAL = !!SvPOK (scalar);
	OUTPUT:
        RETVAL

bool
nok (SV *scalar)
        PROTOTYPE: $
        CODE:
        RETVAL = !!SvNOK (scalar);
	OUTPUT:
        RETVAL

bool
niok (SV *scalar)
        PROTOTYPE: $
        CODE:
        RETVAL = !!SvNIOK (scalar);
	OUTPUT:
        RETVAL

