/*
 * $Id: DBMaker.h,v 0.11 1999/01/29 00:34:39 $
 *
 * Copyright (c) 1999 DBMaker team
 * portions Copyright (c) 1997  Thomas K. Wenrich
 * portions Copyright (c) 1994,1995,1996,1997  Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */
#define NEED_DBIXS_VERSION 7

#include <DBIXS.h>		/* installed by the DBI module	*/

#if defined(MSWin32)
 #include <windows.h>
#else
 #include <sqlunix.h>
#endif
#include <sql.h>
#include <sqlext.h>
#include "sqlopt.h"
#include "dbdimp.h"
#include <sys/stat.h>

#ifndef DBIc_IADESTROY		/* IADESTROY added after DBI-0.87 */
#define DBIc_IADESTROY(x) 0
#endif


void dbd_init _((dbistate_t *dbistate));

int  dbd_db_login _((SV *dbh, char *dbname, char *uid, char *pwd));
int  dbd_db_do _((SV *sv, char *statement));
int  dbd_db_commit _((SV *dbh));
int  dbd_db_rollback _((SV *dbh));
int  dbd_db_disconnect _((SV *dbh));
void dbd_db_destroy _((SV *dbh));
int  dbd_db_STORE _((SV *dbh, SV *keysv, SV *valuesv));
SV  *dbd_db_FETCH _((SV *dbh, SV *keysv));


int  dbd_st_prepare _((SV *sth, char *statement, SV *attribs));
int  dbd_st_rows _((SV *sv));
int  dbd_st_execute _((SV *sv));
AV  *dbd_st_fetch _((SV *sv));
int  dbd_st_finish _((SV *sth));
void dbd_st_destroy _((SV *sth));
int  dbd_st_readblob _((SV *sth, int field, long offset, long len,
			SV *destrv, long destoffset));
int  dbd_st_STORE _((SV *dbh, SV *keysv, SV *valuesv));
SV  *dbd_st_FETCH _((SV *dbh, SV *keysv));
int dbd_bind_ph(SV *sth,imp_sth_t *imp_sth,SV *ph_namesv,
   SV *newvalue,IV sql_type,SV *attribs,int is_inout,IV maxlen);



SV   *dbmaker_get_info _((SV *dbh, int ftype));
int  dbmaker_get_type_info _((SV *dbh, SV *sth, int ftype));
SV  *dbmaker_col_attributes _((SV *sth, int colno, int desctype));
int  dbmaker_describe_col _((SV *sth, int colno,
        char *ColumnName, I16 BufferLength, I16 *NameLength,
        I16 *DataType, U32 *ColumnSize,
        I16 *DecimalDigits, I16 *Nullable));
int  dbmaker_db_columns _((SV *dbh, SV *sth,   
        char *catalog, char *schema, char *table, char *column));



/* end of DBMaker.h */
