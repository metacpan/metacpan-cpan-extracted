/*  Copyright (c) 2008-2022 H.Merijn Brand.  All rights reserved.
 *  This program is free software; you can redistribute it and/or
 *  modify it under the same terms as Perl itself.
 */

#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#define NEED_pv_pretty
#define NEED_pv_escape
#define NEED_my_snprintf
#define NEED_utf8_to_uvchr_buf
#include "ppport.h"
#ifdef __cplusplus
}
#endif

SV *_DDump (pTHX_ SV *sv)
{
    int   err[3], n;
    char  buf[128];
    SV   *dd;

    if (pipe (err)) return (NULL);

    dd = sv_newmortal ();
    err[2] = dup (2);
    close (2);
    if (dup (err[1]) == 2)
	sv_dump (sv);
    close (err[1]);
    close (2);
    err[1] = dup (err[2]);
    close (err[2]);

    sv_setpvn (dd, "", 0);
    while ((n = read (err[0], buf, 128)) > 0)
	sv_catpvn_flags (dd, buf, n, SV_GMAGIC);
    return (dd);
    } /* _DDump */

SV *_DPeek (pTHX_ int items, SV *sv)
{
#ifdef NO_SV_PEEK
    return newSVpv ("Your perl did not export Perl_sv_peek ()", 0);
#else
    return newSVpv (sv_peek (items ? sv : DEFSV), 0);
#endif
    } /* _DPeek */

void _Dump_Dual (pTHX_ SV *sv, SV *pv, SV *iv, SV *nv, SV *rv)
{
#ifndef NO_SV_PEEK
    warn ("%s\n  PV: %s\n  IV: %s\n  NV: %s\n  RV: %s\n",
	sv_peek (sv), sv_peek (pv), sv_peek (iv), sv_peek (nv), sv_peek (rv));
#endif
    } /* _Dump_Dual */

MODULE = Data::Peek		PACKAGE = Data::Peek

void
DPeek (...)
  PROTOTYPE: ;$
  PPCODE:
    I32 gimme = GIMME_V;
    SV *sv    = items ? ST (0) : DEFSV;
    if (items == 0) EXTEND (SP, 1);
    ST (0) = _DPeek (aTHX_ items, sv);
    if (gimme == G_VOID) warn ("%s\n", SvPVX (ST (0)));
    XSRETURN (1);
    /* XS DPeek */

void
DDisplay (...)
  PROTOTYPE: ;$
  PPCODE:
    I32 gimme = GIMME_V;
    SV *sv    = items ? ST (0) : DEFSV;
    SV *dsp   = newSVpv ("", 0);
    if (SvPOK (sv) || SvPOKp (sv))
	pv_pretty (dsp, SvPVX (sv), SvCUR (sv), 0,
	    NULL, NULL,
	    (PERL_PV_PRETTY_DUMP | PERL_PV_ESCAPE_UNI_DETECT));
    if (items == 0) EXTEND (SP, 1);
    ST (0) = dsp;
    if (gimme == G_VOID) warn ("%s\n", SvPVX (ST (0)));
    XSRETURN (1);
    /* XS DDisplay */

void
triplevar (pv, iv, nv)
    SV  *pv
    SV  *iv
    SV  *nv

  PROTOTYPE: $$$
  PPCODE:
    SV  *tv = newSVpvs ("");
    SvUPGRADE (tv, SVt_PVNV);

    if (SvPOK (pv) || SvPOKp (pv)) {
	sv_setpvn (tv, SvPVX (pv), SvCUR (pv));
	if (SvUTF8 (pv)) SvUTF8_on (tv);
	}
    else
	sv_setpvn (tv, NULL, 0);

    if (SvNOK (nv) || SvNOKp (nv)) {
	SvNV_set (tv, SvNV (nv));
	SvNOK_on (tv);
	}

    if (SvIOK (iv) || SvIOKp (iv)) {
	SvIV_set (tv, SvIV (iv));
	SvIOK_on (tv);
	}

    ST (0) = tv;
    XSRETURN (1);
    /* XS triplevar */

void
DDual (sv, ...)
    SV   *sv

  PROTOTYPE: $;$
  PPCODE:
    I32 gimme = GIMME_V;

    if (items > 1 && SvGMAGICAL (sv) && SvTRUE (ST (1)))
	mg_get (sv);

    EXTEND (SP, 5);
    if (SvPOK (sv) || SvPOKp (sv)) {
	SV *xv = newSVpv (SvPVX (sv), 0);
	if (SvUTF8 (sv)) SvUTF8_on (xv);
	mPUSHs (xv);
	}
    else
	PUSHs (&PL_sv_undef);

    if (SvIOK (sv) || SvIOKp (sv))
	mPUSHi (SvIV (sv));
    else
	PUSHs (&PL_sv_undef);

    if (SvNOK (sv) || SvNOKp (sv))
	mPUSHn (SvNV (sv));
    else
	PUSHs (&PL_sv_undef);

    if (SvROK (sv)) {
	SV *xv = newSVsv (SvRV (sv));
	mPUSHs (xv);
	}
    else
	PUSHs (&PL_sv_undef);

    mPUSHi (SvMAGICAL (sv) >> 21);

    if (gimme == G_VOID) _Dump_Dual (aTHX_ sv, ST (0), ST (1), ST (2), ST (3));
    /* XS DDual */

void
DGrow (sv, size)
    SV     *sv
    IV      size

  PROTOTYPE: $$
  PPCODE:
    if (SvROK (sv))
	sv = SvRV (sv);
    if (!SvPOK (sv))
	sv_setpvn (sv, "", 0);
    SvGROW (sv, size);
    EXTEND (SP, 1);
    mPUSHi (SvLEN (sv));
    /* XS DGrow */

void
DDump_XS (sv)
    SV   *sv

  PROTOTYPE: $
  PPCODE:
    SV   *dd = _DDump (aTHX_ sv);

    if (dd) {
	ST (0) = dd;
	XSRETURN (1);
	}

    XSRETURN (0);
    /* XS DDump */

void
DDump_IO (io, sv, level)
    PerlIO *io
    SV     *sv
    IV      level

  PPCODE:
    do_sv_dump (0, io, sv, 1, level, 1, 0);
    XSRETURN (1);
    /* XS DDump */
