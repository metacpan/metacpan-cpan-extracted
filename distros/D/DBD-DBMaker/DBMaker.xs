/* $Id: DBMaker.xs,v 0.13 1999/08/30 00:34:39 $				   */
/*                                                             */
/* Copyright (c) 1999 DBMaker team                             */
/* portions Copyright (c) 1994,1995,1996,1997,1998  Tim Bunce  */
/* portions Copyright (c) 1997  Thomas K. Wenrich			   */
/* portions Copyright (c) 1994,1995,1996  Tim Bunce			   */
/*									                           */
/* You may distribute under the terms of either the GNU General Public	  */
/* License or the Artistic License, as specified in the Perl README file. */

#include "DBMaker.h"


/* --- Variables --- */

DBISTATE_DECLARE;


MODULE = DBD::DBMaker	PACKAGE = DBD::DBMaker

REQUIRE:    1.929
PROTOTYPES: DISABLE

BOOT:
    items = 0;  /* avoid 'unused variable' warning */
    DBISTATE_INIT;
    /* XXX this interface will change: */
    DBI_IMP_SIZE("DBD::DBMaker::dr::imp_data_size", sizeof(imp_drh_t));
    DBI_IMP_SIZE("DBD::DBMaker::db::imp_data_size", sizeof(imp_dbh_t));
    DBI_IMP_SIZE("DBD::DBMaker::st::imp_data_size", sizeof(imp_sth_t));
    dbd_init(DBIS);

void
errstr(h)
    SV *	h
    CODE:
    /* called from DBI::var TIESCALAR code for $DBI::errstr	*/
    D_imp_xxh(h);
    ST(0) = sv_mortalcopy(DBIc_ERRSTR(imp_xxh));

MODULE = DBD::DBMaker	PACKAGE = DBD::DBMaker::dr

void
disconnect_all(drh)
    SV *	drh
    CODE:
    if (!dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING",0))) {
	D_imp_drh(drh);
	sv_setiv(DBIc_ERR(imp_drh), (IV)1);
	sv_setpv(DBIc_ERRSTR(imp_drh),
		(char*)"disconnect_all not implemented");
	DBIh_EVENT2(drh, ERROR_event,
		DBIc_ERR(imp_drh), DBIc_ERRSTR(imp_drh));
	XSRETURN(0);
    }
    /* perl_destruct with perl_destruct_level and $SIG{__WARN__} set	*/
    /* to a code ref core dumps when sv_2cv triggers warn loop.		*/
    if (perl_destruct_level)
	perl_destruct_level = 0;
    XST_mIV(0, 1);



# -----------------------------------------------------------
# database level interface
# ------------------------------------------------------------
MODULE = DBD::DBMaker    PACKAGE = DBD::DBMaker::db

void
_login(dbh, dbname, uid, pwd)
    SV *	dbh
    char *	dbname
    char *	uid
    char *	pwd
    CODE:
    ST(0) = dbd_db_login(dbh, dbname, uid, pwd) ? &sv_yes : &sv_no;


void
commit(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    if (DBIc_has(imp_dbh,DBIcf_AutoCommit))
       warn("commit ineffective with AutoCommit enabled");
    ST(0) = dbd_db_commit(dbh) ? &sv_yes : &sv_no;

void
rollback(dbh)
    SV *	dbh
    CODE:
    ST(0) = dbd_db_rollback(dbh) ? &sv_yes : &sv_no;

void
disconnect(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    if ( !DBIc_ACTIVE(imp_dbh) ) {
	XSRETURN_YES;
    }
    /* Check for disconnect() being called whilst refs to cursors	*/
    /* still exists. This needs some more thought.			*/
    if (DBIc_ACTIVE_KIDS(imp_dbh) && DBIc_WARN(imp_dbh) && !dirty) {
	warn("disconnect(%s) invalidates %d active cursor(s)",
	    SvPV(dbh,na), (int)DBIc_ACTIVE_KIDS(imp_dbh));
    }
    ST(0) = dbd_db_disconnect(dbh) ? &sv_yes : &sv_no;


void
DESTROY(dbh)
    SV *	dbh
    PPCODE:
    D_imp_dbh(dbh);
    ST(0) = &sv_yes;
    if (!DBIc_IMPSET(imp_dbh)) {	/* was never fully set up	*/
	if (DBIc_WARN(imp_dbh) && !dirty && dbis->debug >= 2)
	     warn("Database handle %s DESTROY ignored - never set up",
		SvPV(dbh,na));
    }
    else {
        if (DBIc_IADESTROY(imp_dbh)) { /* want's ineffective destroy    */
            DBIc_ACTIVE_off(imp_dbh);
        }
	if (DBIc_ACTIVE(imp_dbh)) {
	    if (DBIc_WARN(imp_dbh) && !dirty)
		 warn("Database handle destroyed without explicit disconnect");
	    dbd_db_disconnect(dbh);
	}
	dbd_db_destroy(dbh);
    }

void
STORE(dbh, keysv, valuesv)
    SV *	dbh
    SV *	keysv
    SV *	valuesv
    CODE:
    ST(0) = &sv_yes;
    if (!dbd_db_STORE(dbh, keysv, valuesv))
	if (!DBIS->set_attr(dbh, keysv, valuesv))
	    ST(0) = &sv_no;

void
FETCH(dbh, keysv)
    SV *	dbh
    SV *	keysv
    CODE:
    SV *valuesv = dbd_db_FETCH(dbh, keysv);
    if (!valuesv)
	valuesv = DBIS->get_attr(dbh, keysv);
    ST(0) = valuesv;	/* dbd_db_FETCH did sv_2mortal	*/

void                      
_table_info(dbh, sth, qualifier)
	SV *	dbh
	SV *	sth
	char *	qualifier
	CODE:
	ST(0) = dbd_st_table_info(dbh, sth, qualifier, "TABLE,VIEW") ? &sv_yes : &sv_no;

void
_get_type_info(dbh, sth, ftype)
	SV *	dbh
	SV *	sth
	int		ftype
	CODE:
	ST(0) = dbd_st_get_type_info(dbh, sth, ftype) ? &sv_yes : &sv_no;

void
_columns(dbh, sth, catalog, schema, table, column)
	SV *	dbh
	SV *	sth
	char *	catalog
	char *	schema
	char *	table
	char *	column
	CODE:
	ST(0) = dbmaker_db_columns(dbh, sth, catalog, schema, table, column) ? &sv_yes : &sv_no;

void 
_GetInfo(dbh, ftype)
	SV *	dbh
	int		ftype
	CODE:
	ST(0) = dbmaker_get_info(dbh, ftype);

void 
_GetStatistics(dbh, sth, CatalogName, SchemaName, TableName, Unique)
	SV *	dbh
	SV *	sth
	char *	CatalogName
	char *	SchemaName
	char *	TableName
	int		Unique
	CODE:
	ST(0) = dbmaker_get_statistics(dbh, sth, CatalogName, SchemaName, TableName, Unique) ? &sv_yes : &sv_no;

void 
_GetPrimaryKeys(dbh, sth, CatalogName, SchemaName, TableName)
	SV *	dbh
	SV *	sth
	char *	CatalogName
	char *	SchemaName
	char *	TableName
	CODE:
	ST(0) = dbmaker_get_primary_keys(dbh, sth, CatalogName, SchemaName, TableName) ? &sv_yes : &sv_no;

void 
_GetForeignKeys(dbh, sth, PK_CatalogName, PK_SchemaName, PK_TableName, FK_CatalogName, FK_SchemaName, FK_TableName)
	SV *	dbh
	SV *	sth
	char *	PK_CatalogName
	char *	PK_SchemaName
	char *	PK_TableName
	char *	FK_CatalogName
	char *	FK_SchemaName
	char *	FK_TableName
	CODE:
	ST(0) = dbmaker_get_foreign_keys(dbh, sth, PK_CatalogName, PK_SchemaName, PK_TableName, FK_CatalogName, FK_SchemaName, FK_TableName) ? &sv_yes : &sv_no;

#
# Corresponds to ODBC 2.0.  3.0's SQL_API_ODBC3_ALL_FUNCTIONS will break this
# scheme
void
_GetFunctions(dbh, func)
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

# -- end of DBD::DBMaker::db


# ------------------------------------------------------------
# statement interface
# ------------------------------------------------------------
MODULE = DBD::DBMaker    PACKAGE = DBD::DBMaker::st

void
_prepare(sth, statement, attribs=Nullsv)
    SV *	sth
    char *	statement
    SV *	attribs
    CODE:
    DBD_ATTRIBS_CHECK("_prepare", sth, attribs);
    ST(0) = dbd_st_prepare(sth, statement, attribs) ? &sv_yes : &sv_no;


void
rows(sth)
    SV *	sth
    CODE:
    XST_mIV(0, dbd_st_rows(sth));


void
bind_param(sth, param, value, attribs=Nullsv)
    SV *	sth
    SV *	param
    SV *	value
    SV *	attribs
    CODE:
    {
    IV sql_type = 0;
    D_imp_sth(sth);
    if (SvGMAGICAL(value))
	mg_get(value);
    if (attribs) {
	if (SvNIOK(attribs)) {
	    sql_type = SvIV(attribs);
	    attribs = Nullsv;
	}
	else {
	    SV **svp;
	    DBD_ATTRIBS_CHECK("bind_param", sth, attribs);
	    /* XXX we should perhaps complain if TYPE is not SvNIOK */
	    DBD_ATTRIB_GET_IV(attribs, "TYPE",4, svp, sql_type);
	}
    }
    ST(0) = dbd_bind_ph(sth, imp_sth, param, value, sql_type, attribs, FALSE, 0)
		? &sv_yes : &sv_no;
    }


void
bind_param_inout(sth, param, value_ref, maxlen, attribs=Nullsv)
    SV *	sth
    SV *	param
    SV *	value_ref
    IV 		maxlen
    SV *	attribs
    CODE:
    {
    IV sql_type = 0;
    D_imp_sth(sth);
    SV *value;
    if (!SvROK(value_ref) || SvTYPE(SvRV(value_ref)) > SVt_PVMG)
	croak("bind_param_inout needs a reference to a scalar value");
    value = SvRV(value_ref);
    if (SvREADONLY(value))
	croak("Modification of a read-only value attempted");
    if (SvGMAGICAL(value))
	mg_get(value);
    if (attribs) {
	if (SvNIOK(attribs)) {
	    sql_type = SvIV(attribs);
	    attribs = Nullsv;
	}
	else {
	    SV **svp;
	    DBD_ATTRIBS_CHECK("bind_param", sth, attribs);
	    DBD_ATTRIB_GET_IV(attribs, "TYPE",4, svp, sql_type);
	}
    }
    ST(0) = dbd_bind_ph(sth, imp_sth, param, value, sql_type, attribs, TRUE, maxlen)
		? &sv_yes : &sv_no;
    }


void
execute(sth, ...)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    int retval;
    if (items > 1) {
	/* Handle binding supplied values to placeholders	*/
	int i, error = 0;
        SV *idx;
	if (items-1 != DBIc_NUM_PARAMS(imp_sth)) {
	    croak("execute called with %ld bind variables, %d needed",
		    items-1, DBIc_NUM_PARAMS(imp_sth));
	    XSRETURN_UNDEF;
	}
        idx = sv_2mortal(newSViv(0));
	for(i=1; i < items ; ++i) {
	    sv_setiv(idx, i);
#if 0 /* #NEW merge from ODBC */
	    if (!dbd_bind_ph(sth, idx, ST(i), Nullsv, FALSE, 0))
#else
	    if (!dbd_bind_ph(sth, imp_sth, idx, ST(i), 0, Nullsv, FALSE, 0))
#endif
		++error;
	}
	if (error) {
	    XSRETURN_UNDEF;	/* dbd_bind_ph already registered error	*/
	}
    }
    retval = dbd_st_execute(sth);
    if (retval < 0)
	XST_mUNDEF(0);		/* error        		*/
    else 
	{
	/* DBI SPEC 0.82: return rows affected  */
	retval = dbd_st_rows(sth);
        if (retval == 0)
	    XST_mPV(0, "0E0");	/* true but zero		*/
        else
	    XST_mIV(0, retval);	/* typically 1 or rowcount	*/
	}

void
fetch(sth)
    SV *	sth
    CODE:
    AV *av = dbd_st_fetch(sth);
    ST(0) = (av) ? sv_2mortal(newRV((SV *)av)) : &sv_undef;


void
fetchrow(sth)
    SV *	sth
    PPCODE:
    D_imp_sth(sth);
    AV *av;
    if (DBIc_COMPAT(imp_sth) && GIMME == G_SCALAR) {	/* XXX Oraperl	*/
	/* This non-standard behaviour added only to increase the	*/
	/* performance of the oraperl emulation layer (Oraperl.pm)	*/
	if (!imp_sth->done_desc && !dbd_describe(sth, imp_sth))
		XSRETURN_UNDEF;
	XSRETURN_IV(DBIc_NUM_FIELDS(imp_sth));
    }
    av = dbd_st_fetch(sth);
    if (av) {
	int num_fields = AvFILL(av)+1;
	int i;
	EXTEND(sp, num_fields);
	for(i=0; i < num_fields; ++i) {
	    PUSHs(AvARRAY(av)[i]);
	}
    }

void
finish(sth)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    if (!DBIc_ACTIVE(imp_dbh)) {
	/* Either an explicit disconnect() or global destruction	*/
	/* has disconnected us from the database. Finish is meaningless	*/
	/* XXX warn */
	XSRETURN_YES;
    }
    if (!DBIc_ACTIVE(imp_sth)) {
	/* No active statement to finish	*/
	XSRETURN_YES;
    }
    ST(0) = dbd_st_finish(sth) ? &sv_yes : &sv_no;


void
DESTROY(sth)
    SV *	sth
    PPCODE:
    D_imp_sth(sth);
    ST(0) = &sv_yes;
    if (!DBIc_IMPSET(imp_sth)) {	/* was never fully set up	*/
	if (DBIc_WARN(imp_sth) && !dirty && dbis->debug >= 2)
	     warn("Statement handle %s DESTROY ignored - never set up",
		SvPV(sth,na));
    }
    else {
        if (DBIc_IADESTROY(imp_sth)) { /* want's ineffective destroy    */
            DBIc_ACTIVE_off(imp_sth);
        }
	if (DBIc_ACTIVE(imp_sth))
	    dbd_st_finish(sth);
	dbd_st_destroy(sth);
    }

void
STORE(sth, keysv, valuesv)
    SV *	sth
    SV *	keysv
    SV *	valuesv
    CODE:
    ST(0) = &sv_yes;
    if (!dbd_st_STORE(sth, keysv, valuesv))
	if (!DBIS->set_attr(sth, keysv, valuesv))
	    ST(0) = &sv_no;


void
myFETCH(sth, keysv)
    SV *	sth
    SV *	keysv
	ALIAS:
	FETCH = 1
    CODE:
    SV *valuesv = dbd_st_FETCH(sth, keysv);
    if (!valuesv)
	valuesv = DBIS->get_attr(sth, keysv);
    ST(0) = valuesv;	/* dbd_st_FETCH did sv_2mortal	*/

int
blob_read(sth, field, offset, len, destrv=Nullsv, destoffset=0)
    SV *        sth
    int field
    long        offset
    long        len
    SV *        destrv
    long        destoffset
    CODE:
    if (!destrv)
        destrv = sv_2mortal(newRV(sv_2mortal(newSV(0))));
    if (dbd_st_blob_read(sth, field, offset, len, destrv, destoffset))
         ST(0) = SvRV(destrv);
    else ST(0) = &sv_undef;

void 
_ColAttributes(sth, colno, ftype)
	SV *	sth
	int		colno
	int		ftype
	CODE:
	ST(0) = dbmaker_col_attributes(sth, colno, ftype);


void 
_BindColToFile(sth, colno, file_prefix, fgOverwrite)
	SV *	sth
	int	colno
	char *  file_prefix
        int     fgOverwrite
	CODE:
	ST(0) = dbmaker_bind_col_to_file(sth, colno, file_prefix,fgOverwrite) ? &sv_yes : &sv_no;

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

	rc = dbmaker_describe_col(sth, colno, ColumnName, sizeof(ColumnName), &NameLength,
			&DataType, &ColumnSize, &DecimalDigits, &Nullable);
	if (rc) {
		XPUSHs(newSVpv(ColumnName, 0));
		XPUSHs(newSViv(DataType));
		XPUSHs(newSViv(ColumnSize));
		XPUSHs(newSViv(DecimalDigits));
		XPUSHs(newSViv(Nullable));
	}

# --- end of DBD::DBMaker::st

# end of DBMaker.xs
