/* ======================================================================
* $Id: Solid.h, v 2.0 2001-01-??
* $Id: Solid.h,v 1.1 2001/10/13 21:08:47 joe Exp $
* Copyright (c) 1997  Thomas K. Wenrich
* portions Copyright (c) 1994,1995,1996  Tim Bunce
*
* You may distribute under the terms of either the GNU General Public
* License or the Artistic License, as specified in the Perl README file.
*
* ======================================================================= */

#define NEED_DBIXS_VERSION 7

/* I added these ODBC 3.x error code mappings. --mms */
#define S_SQL_ST_DATA_TRUNC     "01004"
#define S_SQL_ST_ATTR_VIOL      "07006"

/* SOLID extensions -- I added these from cli0defs.h  --mms */
/* SQL_TRANSLATE_OPTION values (SOLID Specific) */
#define SQL_SOLID_XLATOPT_DEFAULT        0
#define SQL_SOLID_XLATOPT_NOCNV          1
#define SQL_SOLID_XLATOPT_ANSI           2
#define SQL_SOLID_XLATOPT_PCOEM          3
#define SQL_SOLID_XLATOPT_7BITSCAND      4

#include <DBIXS.h>		/* installed by the DBI module	*/

/* I removed these. --mms
#include <cli0cli.h>
#include <cli0defs.h>
#include <cli0env.h>
*/

/* Type WORD is new in ODBC 3.51 and collides with type WORD in perl
* (defined in perly.h).  So we get rid of the existing def'n (if any) 
* and let sqlunix.h define WORD as unsigned long.  --mms */
#ifdef WORD
#undef WORD
#endif

/* Similarly, DBI/dbi_sql.h (line 46) defines SQL_NO_DATA_FOUND to 
* be 100, and sqlext.h then redefines it (in line 41) to the same 
* value.  Hence this hack.  --mms */
#ifdef SQL_NO_DATA_FOUND
#undef SQL_NO_DATA_FOUND
#endif

/* Micro$loth says in sql.h that windows.h must come first.
* sqlunix.h is the equivalent of windows.h. --mms */
/* #ifdef SS_UNIX */
#include <sqlunix.h>
/* #endif */

/* sqlext.h includes sql.h which includes sqltypes.h  --mms */
#include <sql.h>
#include <sqltypes.h> 
#include <sqlext.h>
#include <sqlucode.h>

#include "dbdimp.h"

#ifndef DBIc_IADESTROY		/* IADESTROY added after DBI-0.87 */
#define DBIc_IADESTROY(x) 0
#endif

void dbd_init _((dbistate_t* dbistate));
int  dbd_db_login _((SV* dbh, char* dbname, char* uid, char* pwd));
int  dbd_db_do _((SV* sv, char* statement));
int  dbd_db_commit _((SV* dbh));
int  dbd_db_rollback _((SV* dbh));
int  dbd_db_disconnect _((SV* dbh));
void dbd_db_destroy _((SV* dbh));
int  dbd_db_STORE _((SV* dbh, SV* keysv, SV* valuesv));
SV*  dbd_db_FETCH _((SV* dbh, SV* keysv));
int  dbd_st_prepare _((SV* sth, char* statement, SV* attribs));
int  dbd_st_rows _((SV* sv));
int  dbd_bind_ph _((SV* h, SV* param, SV* value, SV* attribs, 
                    int is_inout, IV maxlen));

int  dbd_st_execute _((SV* sv));
AV*  dbd_st_fetch _((SV* sv));
int  dbd_st_finish _((SV* sth));
void dbd_st_destroy _((SV* sth));
int  dbd_st_readblob _((SV* sth, int field, long offset, long len,
               			SV* destrv, long destoffset));

int  dbd_st_STORE _((SV* dbh, SV* keysv, SV* valuesv));
SV*  dbd_st_FETCH _((SV* dbh, SV* keysv));


/* end of Solid.h */
