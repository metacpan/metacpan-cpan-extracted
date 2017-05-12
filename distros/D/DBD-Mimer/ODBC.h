/*
 * $Id: ODBC.h,v 1.8 1998/08/08 16:58:30 timbo Exp $
 * Copyright (c) 1994,1995,1996,1997  Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#include "dbdmimer.h"	/* Get SQL_* defs *before* loading DBIXS.h	*/

#define NEED_DBIXS_VERSION 9

#include <DBIXS.h>	/* from DBI. Load this after dbdodbc.h */

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
	    char *catalog, char *schema, char *table, char *column));

/* end of ODBC.h */
