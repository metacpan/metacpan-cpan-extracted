/*
@(#)File:           $RCSfile: kludge.h,v $
@(#)Version:        $Revision: 1.15 $
@(#)Last changed:   $Date: 2015/02/17 04:47:49 $
@(#)Purpose:        Provide support for KLUDGE macro
@(#)Author:         J Leffler
@(#)Copyright:      (C) JLSS 1995,1997-2000,2003,2005,2008,2015
@(#)Product:        Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
*/

/*TABSTOP=4*/

#ifndef KLUDGE_H
#define KLUDGE_H

#ifdef MAIN_PROGRAM
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
extern const char jlss_id_kludge_h[];
const char jlss_id_kludge_h[] = "@(#)$Id: kludge.h,v 1.15 2015/02/17 04:47:49 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

/*
 * The KLUDGE macro is enabled by default.
 * It can be disabled by specifying -DKLUDGE_DISABLE
 */

#ifdef KLUDGE_DISABLE

#define KLUDGE(x)   ((void)0)
#define FEATURE(x)  ((void)0)

#else

/*
** The Solaris C compiler without either -O or -g removes unreferenced
** strings, which defeats the purpose of the KLUDGE macro.
** If your compiler is lenient enough, you can use -DKLUDGE_NO_FORCE,
** but most modern compilers make KLUDGE_FORCE preferable.
**
** The GNU C Compiler will complain about unused variables if told to
** do so.  Setting KLUDGE_FORCE ensures that it doesn't complain about
** any kludges.
*/

#undef KLUDGE_FORCE
#ifndef KLUDGE_NO_FORCE
#define KLUDGE_FORCE
#endif /* KLUDGE_NO_FORCE */

#ifdef KLUDGE_FORCE
#define KLUDGE_USE(x)   kludge_use(x)
#else
#define KLUDGE_USE(x)   ((void)0)
#endif /* KLUDGE_FORCE */

/*
** Example use: KLUDGE("Fix macro to accept arguments with commas");
** Note that the argument is now a string.  An alternative (and
** previously used) design is to have the argument as a non-string:
**              KLUDGE(Fix macro to accept arguments with commas);
** This allows it to work with traditional compilers but runs foul of
** the absence of string concatenation, and you have to avoid commas
** in the reason string, etc.
*/

#define KLUDGE_DEC  static const char kludge[]
#define FEATURE_DEC static const char feature[]

#define KLUDGE(x)   { KLUDGE_DEC = "@(#)KLUDGE: " x; KLUDGE_USE(kludge); }
#define FEATURE(x)  { FEATURE_DEC = "@(#)Feature: " x; KLUDGE_USE(feature); }

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

extern void kludge_use(const char *str);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* KLUDGE_DISABLE */

#endif /* KLUDGE_H */
