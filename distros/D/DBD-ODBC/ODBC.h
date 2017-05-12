/*
 * $Id$
 * Copyright (c) 1994,1995,1996,1997  Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */
#include "dbdodbc.h"	/* Get SQL_* defs *before* loading DBIXS.h	*/

#define NEED_DBIXS_VERSION 9

#include <DBIXS.h>	/* from DBI. Load this after dbdodbc.h */

#include "dbivport.h" /* copied from DBI to maintain compatibility */

#include "dbdimp.h"

#include <dbd_xsh.h>	/* from DBI. Load this after dbdodbc.h */

SV      *odbc_get_info _((SV *dbh, int ftype));
int      odbc_get_type_info _((SV *dbh, SV *sth, int ftype));
SV	*odbc_col_attributes _((SV *sth, int colno, int desctype));
SV	*odbc_cancel _((SV *sth));
int	 odbc_describe_col _((SV *sth, int colno,
	    char *ColumnName, I16 BufferLength, I16 *NameLength,
	    I16 *DataType, U32 *ColumnSize,
	    I16 *DecimalDigits, I16 *Nullable));
int	 odbc_db_columns _((SV *dbh, SV *sth,
	    SV *catalog, SV *schema, SV *table, SV *column));

int  odbc_st_tables _((SV *dbh, SV *sth, SV *catalog, SV *schema, SV *table, SV *table_type));
int  odbc_st_primary_keys _((SV *dbh, SV *sth, char *catalog, char *schema, char *table));
int  odbc_get_statistics _((SV *dbh, SV *sth, char *CatalogName, char *SchemaName, char *TableName, int Unique));
int  odbc_get_special_columns _((SV *dbh, SV *sth, int Identifier, char *CatalogName, char *SchemaName, char *TableName, int Scope, int Nullable));
int  odbc_get_foreign_keys _((SV *dbh, SV *sth, char *PK_CatalogName, char *PK_SchemaName, char *PK_TableName, char *FK_CatalogName, char *FK_SchemaName, char *FK_TableName));
void dbd_error _((SV *h, RETCODE err_rc, char *what));
void dbd_error2 _((SV *h, RETCODE err_rc, char *what, HENV henv, HDBC hdbc, HSTMT hstmt));
SQLLEN dbd_db_execdirect _(( SV *dbh, SV *statement ));
IV odbc_st_lob_read(SV *sth, int colno, SV *data, UV length, IV type);
IV odbc_st_execute_for_fetch(SV *sth, SV *tuples, IV count, SV *tuple_status);
IV odbc_st_rowcount(SV *sth);
int dbd_st_statistics(SV *dbh, SV *sth, char *catalog, char *schema,
                      char *table, int unique, int quick);
int dbd_st_bind_col(SV *sth, imp_sth_t *imp_sth, SV *col, SV *ref,
                    IV type, SV *attribs);
AV* dbd_data_sources(SV *drh );

/* end of ODBC.h */
