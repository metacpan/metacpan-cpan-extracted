/*
@(#)File:            $RCSfile: esqlperl.h,v $
@(#)Version:         $Revision: 58.1 $
@(#)Last changed:    $Date: 1998/01/06 02:53:23 $
@(#)Purpose:         ESQL/C Utility Functions for DBD::Sqlflex
@(#)Author:          J Leffler
@(#)Copyright:       (C) Jonathan Leffler 1996-98
@(#)Product:         $Product: DBD::Sqlflex Version 0.58 (1998-01-15) $
*/

/*TABSTOP=4*/

#ifndef ESQLPERL_H
#define ESQLPERL_H

#ifdef MAIN_PROGRAM
#ifndef lint
static const char esqlperl_h[] = "@(#)$Id: esqlperl.h,v 58.1 1998/01/06 02:53:23 johnl Exp $";
#endif	/* lint */
#endif	/* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"

enum Boolean
{
	False, True
};
typedef enum Boolean Boolean;

/*
** The sqltypename() routine assumes is has a buffer of at least
** SQLTYPENAME_BUFSIZ bytes in which too work.
** The return address is the start of the buffer.
*/
#define SQLTYPENAME_BUFSIZ sizeof("INTERVAL MINUTE(2) TO FRACTION(5)")
extern char *sqltypename(int coltype, int collen, char *buffer);

extern void dbd_ix_debug(int n, char *fmt, const char *arg);
extern void dbd_ix_debug_l(int n, char *fmt, long arg);
extern void dbd_ix_setconnection(char *conn);

#if ESQLC_VERSION >= 600
extern void dbd_ix_disconnect(char *connection);
extern Boolean dbd_ix_connect(char *conn, char *dbase, char *user, char *pass);
#else
extern void dbd_ix_closedatabase(char *dbase);
extern Boolean dbd_ix_opendatabase(char *dbase);
#endif	/* ESQLC_VERSION >= 600 */

/* Sqlflex to ODBC mapping for type, precision and scale */
extern int map_type_ifmx_to_odbc(int coltype, int collen);
extern int map_prec_ifmx_to_odbc(int coltype, int collen);
extern int map_scale_ifmx_to_odbc(int coltype, int collen);

#endif	/* ESQLPERL_H */
