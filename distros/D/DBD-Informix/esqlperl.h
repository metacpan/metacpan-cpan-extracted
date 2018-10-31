/*
@(#)Purpose:         ESQL/C Utility Functions for DBD::Informix
@(#)Author:          J Leffler
@(#)Copyright:       1996-98 Jonathan Leffler
@(#)Copyright:       2002    IBM
@(#)Copyright:       2004-07 Jonathan Leffler
@(#)Product:         Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)
*/

/*TABSTOP=4*/

#ifndef ESQLPERL_H
#define ESQLPERL_H

#ifdef MAIN_PROGRAM
#ifndef lint
/* Prevent over-aggressive optimizers from eliminating ID string */
extern const char jlss_id_esqlperl_h[];
const char jlss_id_esqlperl_h[] = "@(#)$Id: esqlperl.h,v 2007.2 2007/09/03 23:37:25 jleffler Exp $";
#endif /* lint */
#endif /* MAIN_PROGRAM */

#include <stdio.h>
#include "esqlc.h"
#include "ixblob.h"

enum Boolean
{
    False, True
};
typedef enum Boolean Boolean;

/*
** Under some circumstances, MSVC gets horrendously fussy and rejects
** valid C code.  This is a sop to MSVC and to other C++ compilers.
*/
#define DBD_IX_BOOLEAN(x)   ((x) ? True : False)

/*
** The sqltypename() routine assumes is has a buffer of at least
** SQLTYPENAME_BUFSIZ bytes in which too work.
** The return address is the start of the buffer.
*/
#define SQLTYPENAME_BUFSIZ sizeof("DISTINCT INTERVAL MINUTE(2) TO FRACTION(5)")

extern void dbd_ix_debug(int n, const char *fmt, ...);
extern void dbd_ix_setconnection(char *conn);

#if ESQLC_EFFVERSION >= 600
extern void dbd_ix_disconnect(char *connection);
extern Boolean dbd_ix_connect(char *conn, char *dbase, char *user, char *pass);
#else
extern void dbd_ix_closedatabase(char *dbase);
extern Boolean dbd_ix_opendatabase(char *dbase);
#endif /* ESQLC_EFFVERSION >= 600 */

/* Informix to ODBC mapping for type, precision and scale */
extern int map_type_ifmx_to_odbc(int coltype, int collen);
extern int map_prec_ifmx_to_odbc(int coltype, int collen);
extern int map_scale_ifmx_to_odbc(int coltype, int collen);

/* DBD::Informix module name - as a constant string (link.c) */
extern const char *dbd_ix_module(void);

#endif /* ESQLPERL_H */
