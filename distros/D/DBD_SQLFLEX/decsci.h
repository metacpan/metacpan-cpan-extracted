/*
@(#)File:            $RCSfile: decsci.h,v $
@(#)Version:         $Revision: 1.4 $
@(#)Last changed:    $Date: 1997/07/08 19:47:10 $
@(#)Purpose:         JLSS Functions to manipulate DECIMAL values
@(#)Author:          J Leffler
@(#)Copyright:       (C) JLSS 1996-97
@(#)Product:         $Product: DBD::Sqlflex Version 0.58 (1998-01-15) $
*/

/*TABSTOP=4*/

#ifndef DECSCI_H
#define DECSCI_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char decsci_h[] = "@(#)$Id: decsci.h,v 1.4 1997/07/08 19:47:10 johnl Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include "decimal.h"

extern int decabs(const dec_t *x, dec_t *r1);
extern int decneg(const dec_t *x, dec_t *r1);
extern int decpower(const dec_t *x, int n, dec_t *r1);
extern int decsqrt(const dec_t *x, dec_t *r1);

/* NB: these routines are not thread-safe and share common return storage */
extern char *decfix(const dec_t *d, int ndigit, int plus);
extern char *decsci(const dec_t *d, int ndigit, int plus);
extern char *deceng(const dec_t *d, int ndigit, int plus, int cw);

#endif	/* DECSCI_H */
