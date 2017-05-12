/*-
 * Copyright (c) 2008, 2009
 *	Thorsten Glaser <tg@mirbsd.org>
 *
 * Provided that these terms and disclaimer and all copyright notices
 * are retained or reproduced in an accompanying document, permission
 * is granted to deal in this work without restriction, including un-
 * limited rights to use, publicly perform, distribute, sell, modify,
 * merge, give away, or sublicence.
 *
 * This work is provided "AS IS" and WITHOUT WARRANTY of any kind, to
 * the utmost extent permitted by applicable law, neither express nor
 * implied; without malicious intent or gross negligence. In no event
 * may a licensor, author or contributor be held liable for indirect,
 * direct, other damage, loss, or other issues arising in any way out
 * of dealing in the work, even if advised of the possibility of such
 * damage or existence of a defect, except proven that it results out
 * of said person's immediate fault when using the work as intended.
 */

#include <sys/types.h>
#include <stdlib.h>

#if defined(HAVE_STDINT_H) && HAVE_STDINT_H
#include <stdint.h>
#elif defined(USE_INTTYPES)
#include <inttypes.h>
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if !defined(__attribute__) && (!defined(__GNUC__) || (__GNUC__ < 1) || (__GNUC__ == 2 && __GNUC_MINOR__ < 5))
#define __attribute__(x)		/* nothing */
#endif

#if !defined(__RCSID) || !defined(__IDSTRING)
#undef __RCSID
#undef __IDSTRING
#undef __IDSTRING_CONCAT
#undef __IDSTRING_EXPAND
#define __IDSTRING_CONCAT(l,p)		__LINTED__ ## l ## _ ## p
#define __IDSTRING_EXPAND(l,p)		__IDSTRING_CONCAT(l,p)
#define __IDSTRING(prefix, string)				\
	static const char __IDSTRING_EXPAND(__LINE__,prefix) []	\
	    __attribute__((used)) = "@(""#)" #prefix ": " string
#define __RCSID(x)			__IDSTRING(rcsid,x)
#endif

__RCSID("$MirOS: contrib/hosted/tg/code/BSD::arc4random/arc4rnd_xs.c,v 1.5 2009/10/10 22:43:53 tg Exp $");

#ifdef REDEF_USCORETYPES
#define u_int32_t	uint32_t
#endif

#ifdef NEED_ARC4RANDOM_DECL
u_int32_t arc4random(void);
void arc4random_addrandom(u_char *, int);
#endif

XS(XS_BSD__arc4random_arc4random_xs);
XS(XS_BSD__arc4random_arc4random_xs)
{
	dXSARGS;
	dXSTARG;
	uint32_t rv;

	rv = arc4random();

	XSprePUSH;
	PUSHu((UV)rv);

	XSRETURN(1);
}

XS(XS_BSD__arc4random_stir_xs);
XS(XS_BSD__arc4random_stir_xs)
{
	dXSARGS;

	arc4random_stir();

	XSRETURN_EMPTY;
}

XS(XS_BSD__arc4random_arc4random_addrandom_xs);
XS(XS_BSD__arc4random_arc4random_addrandom_xs)
{
	dXSARGS;
	dXSTARG;
	SV *sv;
	char *buf;
	STRLEN len;
	uint32_t rv;

	sv = ST(0);
	buf = SvPV(sv, len);
	arc4random_addrandom((unsigned char *)buf, (int)len);
	rv = arc4random();
	XSprePUSH;
	PUSHu((UV)rv);

	XSRETURN(1);
}

#ifndef HAVE_ARC4RANDOM_PUSHB
#define HAVE_ARC4RANDOM_PUSHB	1
#endif

#if HAVE_ARC4RANDOM_PUSHB
XS(XS_BSD__arc4random_arc4random_pushb_xs);
XS(XS_BSD__arc4random_arc4random_pushb_xs)
{
	dXSARGS;
	dXSTARG;
	SV *sv;
	char *buf;
	STRLEN len;
	uint32_t rv;

	sv = ST(0);
	buf = SvPV(sv, len);
	rv = arc4random_pushb((void *)buf, (size_t)len);
	XSprePUSH;
	PUSHu((UV)rv);

	XSRETURN(1);
}
#elif defined(arc4random_pushk)
#define XS_BSD__arc4random_arc4random_pushb_xs \
	XS_BSD__arc4random_arc4random_pushk_xs
#else
#define XS_BSD__arc4random_arc4random_pushb_xs \
	XS_BSD__arc4random_arc4random_addrandom_xs
#endif

#if defined(arc4random_pushk)
XS(XS_BSD__arc4random_arc4random_pushk_xs);
XS(XS_BSD__arc4random_arc4random_pushk_xs)
{
	dXSARGS;
	dXSTARG;
	SV *sv;
	char *buf;
	STRLEN len;
	uint32_t rv;

	sv = ST(0);
	buf = SvPV(sv, len);
	rv = arc4random_pushk((void *)buf, (size_t)len);
	XSprePUSH;
	PUSHu((UV)rv);

	XSRETURN(1);
}
#elif HAVE_ARC4RANDOM_PUSHB
#define XS_BSD__arc4random_arc4random_pushk_xs \
	XS_BSD__arc4random_arc4random_pushb_xs
#else
#define XS_BSD__arc4random_arc4random_pushk_xs \
	XS_BSD__arc4random_arc4random_addrandom_xs
#endif

#undef HAVE_ARC4RANDOM_KINTF
#if HAVE_ARC4RANDOM_PUSHB || defined(arc4random_pushk)
#define HAVE_ARC4RANDOM_KINTF	1
#else
#define HAVE_ARC4RANDOM_KINTF	0
#endif


/*
 * These may be needed because praeprocessor commands inside a
 * macro's argument list may not work
 */

#if HAVE_ARC4RANDOM_PUSHB
#define IDT_ARC4RANDOM_PUSHB	" arc4random_pushb"
#else
#define IDT_ARC4RANDOM_PUSHB	""
#endif

#if defined(arc4random_pushk)
#define IDT_arc4random_pushk	" arc4random_pushk"
#else
#define IDT_arc4random_pushk	""
#endif

#if HAVE_ARC4RANDOM_KINTF
#define IDT_ARC4RANDOM_KINTF	" have_kintf:=1"
#else
#define IDT_ARC4RANDOM_KINTF	" have_kintf:=0"
#endif

__IDSTRING(api_text, "BSD::arc4random " XS_VERSION " with {"
    " arc4random"
    " arc4random_addrandom"
    IDT_ARC4RANDOM_PUSHB
    IDT_arc4random_pushk
    IDT_ARC4RANDOM_KINTF
    " }");


/* the Perl API is not const clean */
static char file[] = __FILE__;
static char func_a4r[] = "BSD::arc4random::arc4random_xs";
static char func_a4add[] = "BSD::arc4random::arc4random_addrandom_xs";
static char func_a4rpb[] = "BSD::arc4random::arc4random_pushb_xs";
static char func_a4rpk[] = "BSD::arc4random::arc4random_pushk_xs";
static char func_astir[] = "BSD::arc4random::arc4random_stir_xs";
static char func_kintf[] = "BSD::arc4random::have_kintf";

#ifdef __cplusplus
extern "C"
#endif
XS(boot_BSD__arc4random);
XS(boot_BSD__arc4random)
{
	dXSARGS;

	XS_VERSION_BOOTCHECK;

	newXS(func_a4r, XS_BSD__arc4random_arc4random_xs, file);
	newXS(func_a4add, XS_BSD__arc4random_arc4random_addrandom_xs, file);
	newXS(func_a4rpb, XS_BSD__arc4random_arc4random_pushb_xs, file);
	newXS(func_a4rpk, XS_BSD__arc4random_arc4random_pushk_xs, file);
	newXS(func_astir, XS_BSD__arc4random_stir_xs, file);

	newCONSTSUB(NULL, func_kintf, newSViv(HAVE_ARC4RANDOM_KINTF));

	XSRETURN_YES;
}
