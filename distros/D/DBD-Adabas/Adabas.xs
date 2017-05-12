#include "Adabas.h"

DBISTATE_DECLARE;

MODULE = DBD::Adabas    PACKAGE = DBD::Adabas

INCLUDE: Adabas.xsi

MODULE = DBD::Adabas    PACKAGE = DBD::Adabas::st

void 
_ColAttributes(sth, colno, ftype)
	SV *	sth
	int		colno
	int		ftype
	CODE:
	ST(0) = adabas_col_attributes(sth, colno, ftype);

void
_tables(dbh, sth, qualifier)
	SV *	dbh
	SV *	sth
	char *	qualifier
	CODE:
	ST(0) = dbd_st_tables(dbh, sth, qualifier, "TABLE") ? &sv_yes : &sv_no;

MODULE = DBD::Adabas    PACKAGE = DBD::Adabas::st

void
DescribeCol(sth, colno)
	SV *sth
	int colno

	PPCODE:

	char ColumnName[SQL_MAX_COLUMN_NAME_LEN];
	I16 NameLength;
	I16 DataType;
	U32 ColumnSize;
	I16 DecimalDigits;
	I16 Nullable;
	int rc;

	rc = adabas_describe_col(sth, colno, ColumnName, sizeof(ColumnName), &NameLength,
			&DataType, &ColumnSize, &DecimalDigits, &Nullable);
	if (rc) {
		XPUSHs(newSVpv(ColumnName, 0));
		XPUSHs(newSViv(DataType));
		XPUSHs(newSViv(ColumnSize));
		XPUSHs(newSViv(DecimalDigits));
		XPUSHs(newSViv(Nullable));
	}

# ------------------------------------------------------------
# database level interface
# ------------------------------------------------------------
MODULE = DBD::Adabas    PACKAGE = DBD::Adabas::db

void
_columns(dbh, sth, catalog, schema, table, column)
	SV *	dbh
	SV *	sth
	char *	catalog
	char *	schema
	char *	table
	char *	column
	CODE:
	ST(0) = adabas_db_columns(dbh, sth, catalog, schema, table, column) ? &sv_yes : &sv_no;

void 
_GetInfo(dbh, ftype)
	SV *	dbh
	int		ftype
	CODE:
	ST(0) = adabas_get_info(dbh, ftype);

void
_GetTypeInfo(dbh, sth, ftype=NULL)
	SV *	dbh
	SV *	sth
	SV *	ftype
	CODE:
	ST(0) = adabas_get_type_info(dbh, sth,
				     (ftype && SvOK(ftype)) ? SvIV(ftype)
							    : SQL_ALL_TYPES)
	     		? &sv_yes : &sv_no;

#
# Corresponds to ODBC 2.0.  3.0's SQL_API_ODBC3_ALL_FUNCTIONS will break this
# scheme
void
GetFunctions(dbh, func)
	SV *	dbh
	int		func
	PPCODE:
	UWORD pfExists[100];
	RETCODE rc;
	int i;
	D_imp_dbh(dbh);
	rc = SQLGetFunctions(imp_dbh->hdbc, func, pfExists);
	if (SQL_ok(rc)) {
            if (func == SQL_API_ALL_FUNCTIONS) {
                for (i = 0; (i < sizeof(pfExists)/sizeof(pfExists[0])); i++) {
                    XPUSHs(pfExists[i] ? &sv_yes : &sv_no);
                }
            } else {
		XPUSHs(pfExists[0] ? &sv_yes : &sv_no);
	    }
	}

MODULE = DBD::Adabas    PACKAGE = DBD::Adabas::dr

void
data_sources(drh, attr = NULL)
    SV* drh;
    SV* attr;
  PROTOTYPE: $;$
  PPCODE:
    {
	int numDataSources = 0;
	UWORD fDirection = SQL_FETCH_FIRST;
	RETCODE rc;
        UCHAR dsn[SQL_MAX_DSN_LENGTH+1+11 /* strlen("DBI:Adabas:") */];
        SWORD dsn_length;
        UCHAR description[256];
        SWORD description_length;
	D_imp_drh(drh);
	HENV henv;

	if (!imp_drh->connects) {
	    rc = SQLAllocEnv(&imp_drh->henv);
	    if (!SQL_ok(rc)) {
		imp_drh->henv = SQL_NULL_HENV;
		adabas_error(drh, rc, "data_sources/SQLAllocEnv");
		XSRETURN(0);
	    }
	}
        strcpy(dsn, "DBI:Adabas:");
	while (1) {
            rc = SQLDataSources(imp_drh->henv, fDirection,
                                dsn+11, /* strlen("DBI:Adabas:") */
                                sizeof(dsn), &dsn_length,
                                description, sizeof(description),
                                &description_length);
       	    if (!SQL_ok(rc)) {
                if (rc != SQL_NO_DATA_FOUND) {
		    /*
		     *  Temporarily increment imp_drh->connects, so
		     *  that adabas_error uses our henv.
		     */
		    imp_drh->connects++;
		    adabas_error(drh, rc, "data_sources/SQLDataSources");
		    imp_drh->connects--;
                }
                break;
            }
            ST(numDataSources++) = newSVpv(dsn, dsn_length);
	    fDirection = SQL_FETCH_NEXT;
	}
	if (!imp_drh->connects) {
	    SQLFreeEnv(imp_drh->henv);
	    imp_drh->henv = SQL_NULL_HENV;
	}
	XSRETURN(numDataSources);
    }

