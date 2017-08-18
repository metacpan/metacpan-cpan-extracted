#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define RETCOPY(sv)		\
  if (GIMME_V != G_VOID)	\
    {				\
      dXSTARG;			\
      sv_setsv (TARG, (sv));	\
      EXTEND (SP, 1);		\
      PUSHs (TARG);		\
    }

static void
extend (SV *scalar, STRLEN addlen)
{
  SvUPGRADE (scalar, SVt_PV);

  STRLEN cur = SvCUR (scalar);
  STRLEN len = SvLEN (scalar);
  
  if (cur + addlen < len)
    return;

  STRLEN l = len;
  STRLEN o = cur + addlen >= 4096 ? sizeof (void *) * 4 : 0;

  if (l < 64)
    l = 64;

  /* for big sizes, leave a bit of space for malloc management, and assume 4kb or smaller pages */
  addlen += o;

  while (cur + addlen >= l)
    l <<= 1;

  sv_grow (scalar, l - o);
}

MODULE = Convert::Scalar		PACKAGE = Convert::Scalar

TYPEMAP: <<EOF
SSize_t		T_UV
EOF

PROTOTYPES: ENABLE

bool
utf8 (SV *scalar, SV *mode = NO_INIT)
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
        PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_on called on read only scalar");

        SvGETMAGIC (scalar);
        SvUTF8_on (scalar);
        RETCOPY (scalar);

void
utf8_off (SV *scalar)
        PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_off called on read only scalar");

        SvGETMAGIC (scalar);
        SvUTF8_off (scalar);
        RETCOPY (scalar);

int
utf8_valid (SV *scalar)
        CODE:
        STRLEN len;
        char *str = SvPV (scalar, len);
        RETVAL = !!is_utf8_string (str, len);
	OUTPUT:
        RETVAL

void
utf8_upgrade (SV *scalar)
	PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_upgrade called on read only scalar");

        sv_utf8_upgrade(scalar);
        RETCOPY (scalar);

bool
utf8_downgrade (SV *scalar, bool fail_ok = 0)
	CODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_downgrade called on read only scalar");

        RETVAL = !!sv_utf8_downgrade (scalar, fail_ok);
	OUTPUT:
	RETVAL

void
utf8_encode (SV *scalar)
	PPCODE:
        if (SvREADONLY (scalar))
          croak ("Convert::Scalar::utf8_encode called on read only scalar");

        sv_utf8_encode (scalar);
        RETCOPY (scalar);

UV
utf8_length (SV *scalar)
	CODE:
        RETVAL = (UV) utf8_length (SvPV_nolen (scalar), SvEND (scalar));
	OUTPUT:
	RETVAL

bool
readonly (SV *scalar, SV *on = NO_INIT)
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
        CODE:
        SvREADONLY_on (scalar);

void
readonly_off (SV *scalar)
        CODE:
        SvREADONLY_off (scalar);

void
unmagic (SV *scalar, char type)
	CODE:
        sv_unmagic (scalar, type);

void
weaken (SV *scalar)
	CODE:
        sv_rvweaken (scalar);

void
taint (SV *scalar)
	CODE:
        SvTAINTED_on (scalar);

bool
tainted (SV *scalar)
        CODE:
        RETVAL = !!SvTAINTED (scalar);
	OUTPUT:
        RETVAL

void
untaint (SV *scalar)
	CODE:
        SvTAINTED_off (scalar);

STRLEN
len (SV *scalar)
	CODE:
        if (SvTYPE (scalar) < SVt_PV)
          XSRETURN_UNDEF;
        RETVAL = SvLEN (scalar);
	OUTPUT:
        RETVAL

void
grow (SV *scalar, STRLEN newlen)
        PPCODE:
        sv_grow (scalar, newlen);
        if (GIMME_V != G_VOID)
          XPUSHs (sv_2mortal (SvREFCNT_inc (scalar)));

void
extend (SV *scalar, STRLEN addlen = 64)
        PPCODE:
{
	extend (scalar, addlen);

        if (GIMME_V != G_VOID)
          XPUSHs (sv_2mortal (SvREFCNT_inc (scalar)));
}

SSize_t
extend_read (PerlIO *fh, SV *scalar, STRLEN addlen = 64)
        CODE:
{
	if (SvUTF8 (scalar))
          sv_utf8_downgrade (scalar, 0);

	extend (scalar, addlen);

        RETVAL = PerlLIO_read (PerlIO_fileno (fh), SvEND (scalar), SvLEN (scalar) - SvCUR (scalar));

        if (RETVAL < 0)
          XSRETURN_UNDEF;

        SvPOK_only (scalar);
        SvCUR_set (scalar, SvCUR (scalar) + RETVAL);
}
	OUTPUT: RETVAL

SSize_t
read_all (PerlIO *fh, SV *scalar, STRLEN count)
	CODE:
{
	SvUPGRADE (scalar, SVt_PV);
	if (SvUTF8 (scalar))
          sv_utf8_downgrade (scalar, 0);

        SvPOK_only (scalar);

	int fd = PerlIO_fileno (fh);
	RETVAL = 0;

        SvGROW (scalar, count);

        for (;;)
          {
            STRLEN rem = count - RETVAL;

            if (!rem)
              break;

            STRLEN got = PerlLIO_read (fd, SvPVX (scalar) + RETVAL, rem);

            if (got == 0)
              break;
            else if (got < 0)
              if (RETVAL)
                break;
              else
                XSRETURN_UNDEF;

            RETVAL += got;
          }

        SvCUR_set (scalar, RETVAL);
}
	OUTPUT: RETVAL

SSize_t
write_all (PerlIO *fh, SV *scalar)
	CODE:
{
	STRLEN count;
        char *ptr = SvPVbyte (scalar, count);

	int fd = PerlIO_fileno (fh);
	RETVAL = 0;

        for (;;)
          {
            STRLEN rem = count - RETVAL;

            if (!rem)
              break;

            STRLEN got = PerlLIO_write (fd, ptr + RETVAL, rem);

            if (got < 0)
              if (RETVAL)
                break;
              else
                XSRETURN_UNDEF;

            RETVAL += got;
          }
}
	OUTPUT: RETVAL

int
refcnt (SV *scalar, U32 newrefcnt = NO_INIT)
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
        CODE:
        if (ix)
          {
            if (!SvROK (scalar)) croak ("refcnt_dec_rv requires a reference as it's first argument");
            scalar = SvRV (scalar);
          }
        SvREFCNT_dec (scalar);

bool
ok (SV *scalar)
        CODE:
        RETVAL = !!SvOK (scalar);
	OUTPUT:
        RETVAL

bool
uok (SV *scalar)
        CODE:
        RETVAL = !!SvUOK (scalar);
	OUTPUT:
        RETVAL

bool
rok (SV *scalar)
        CODE:
        RETVAL = !!SvROK (scalar);
	OUTPUT:
        RETVAL

bool
pok (SV *scalar)
        CODE:
        RETVAL = !!SvPOK (scalar);
	OUTPUT:
        RETVAL

bool
nok (SV *scalar)
        CODE:
        RETVAL = !!SvNOK (scalar);
	OUTPUT:
        RETVAL

bool
niok (SV *scalar)
        CODE:
        RETVAL = !!SvNIOK (scalar);
	OUTPUT:
        RETVAL

