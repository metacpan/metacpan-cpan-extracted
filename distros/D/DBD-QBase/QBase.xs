/*
	QuickBase Drivers for DBI
	Copyrighed (c) 1995 by What Software, INC
	Programed by: Ben Lindstrom

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.
   

*/

#include "QBase.h" 


/* --- Variables --- */


DBISTATE_DECLARE;


MODULE = DBD::QBase	PACKAGE = DBD::QBase

BOOT:
    items = 0;	/* avoid 'unused variable' warning */
    DBISTATE_INIT;
    /* XXX this interface will change: */
    DBI_IMP_SIZE("DBD::QBase::dr::imp_data_size", sizeof(imp_drh_t));
    DBI_IMP_SIZE("DBD::QBase::db::imp_data_size", sizeof(imp_dbh_t));
    DBI_IMP_SIZE("DBD::QBase::st::imp_data_size", sizeof(imp_sth_t));
    dbd_init(DBIS);


void
errstr(h)
    SV *	h
    CODE:
    /* called from DBI::var TIESCALAR code for $DBI::errstr	*/
    D_imp_xxh(h);
    ST(0) = sv_mortalcopy(DBIc_ERRSTR(imp_xxh));


MODULE = DBD::QBase	PACKAGE = DBD::QBase::dr

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
    XST_mIV(0, 1);



MODULE = DBD::QBase    PACKAGE = DBD::QBase::db

void
_login(dbh, dbname, uid, pwd)
    SV *	dbh
    char *	dbname
    char *	uid
    char *	pwd
    CODE:
    ST(0) = dbd_db_login(dbh, dbname, uid, pwd) ? &sv_yes : &sv_no;


void
_XXX_do(dbh, statement)
    SV *	dbh
    char *	statement
    CODE:
    I32 rows;
    /* XXX currently implemented as execute(prepare()) in DBI.pm	*/
    rows = dbd_db_do(dbh, statement);
    if      (rows == 0) {	XST_mPV(0, "OK");	}
    else if (rows >  0) {	XST_mIV(0, rows);	}
    else {			ST(0) = &sv_undef;	}


void
commit(dbh)
    SV *	dbh
    CODE:
    ST(0) = dbd_db_commit(dbh) ? &sv_yes : &sv_no;

void
rollback(dbh)
    SV *	dbh
    CODE:
    ST(0) = dbd_db_rollback(dbh) ? &sv_yes : &sv_no;


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
disconnect(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    if ( !DBIc_ACTIVE(imp_dbh) ) {
	if (DBIc_WARN(imp_dbh) && !dirty)
	    warn("disconnect: already logged off!");
	XSRETURN_YES;
    }
    /* Check for disconnect() being called whilst refs to cursors	*/
    /* still exists. This needs some more thought.			*/
    /* XXX We need to track DBIc_ACTIVE children not just all children	*/
    if (DBIc_KIDS(imp_dbh) && DBIc_WARN(imp_dbh) && !dirty) {
	warn("disconnect(%s) invalidates %d associated cursor(s)",
	    SvPV(dbh,na), (int)DBIc_KIDS(imp_dbh));
    }
    ST(0) = dbd_db_disconnect(dbh) ? &sv_yes : &sv_no;


void
DESTROY(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    ST(0) = &sv_yes;
    if (!DBIc_IMPSET(imp_dbh)) {	/* was never fully set up	*/
	if (DBIc_WARN(imp_dbh) && !dirty)
	     warn("Database handle %s DESTROY ignored - never set up",
		SvPV(dbh,na));
	return;
    }
    if (DBIc_ACTIVE(imp_dbh)) {
	if (DBIc_WARN(imp_dbh) && !dirty)
	     warn("Database handle destroyed without explicit disconnect");
	dbd_db_disconnect(dbh);
    }
    dbd_db_destroy(dbh);



MODULE = DBD::QBase    PACKAGE = DBD::QBase::st


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
    DBD_ATTRIBS_CHECK("bind_param", sth, attribs);
    ST(0) = dbd_bind_ph(sth, param, value, attribs) ? &sv_yes : &sv_no;


void
execute(sth, ...)
    SV *	sth
    CODE:
    D_imp_sth(sth);
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
	    if (!dbd_bind_ph(sth, idx, ST(i), Nullsv))
		++error;
	}
	if (error) {
	    XSRETURN_UNDEF;	/* dbd_bind_ph already registered error	*/
	}
    }
    ST(0) = dbd_st_execute(sth) ? &sv_yes : &sv_no;


void
fetch(sth)
    SV *	sth
    CODE:
    ST(0) = (SV*)dbd_st_fetch(sth);


void
fetchrow(sth)
    SV *	sth
    PPCODE:
    D_imp_sth(sth);
    AV *av;
    if (GIMME == G_SCALAR && DBIc_COMPAT(imp_sth)) {	/* XXX Oraperl	*/
	/* This non-standard behaviour added only to increase the	*/
	/* performance of the oraperl emulation layer (Oraperl.pm)	*/
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
readblob(sth, field, offset, len, destrv=Nullsv, destoffset=0)
    SV *	sth
    int	field
    long	offset
    long	len
    SV *	destrv
    long	destoffset
    CODE:
    if (!destrv)
	destrv = sv_2mortal(newRV(newSV(0)));
    if (dbd_st_readblob(sth, field, offset, len, destrv, destoffset))
	 ST(0) = destrv;
    else ST(0) = &sv_undef;


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
FETCH(sth, keysv)
    SV *	sth
    SV *	keysv
    CODE:
    SV *valuesv = dbd_st_FETCH(sth, keysv);
    if (!valuesv)
	valuesv = DBIS->get_attr(sth, keysv);
    ST(0) = valuesv;	/* dbd_st_FETCH did sv_2mortal	*/


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
    CODE:
    D_imp_sth(sth);
    ST(0) = &sv_yes;
    if (!DBIc_IMPSET(imp_sth)) {	/* was never fully set up	*/
	if (DBIc_WARN(imp_sth) && !dirty)
	     warn("Statement handle %s DESTROY ignored - never set up",
		SvPV(sth,na));
	return;
    }
    if (DBIc_ACTIVE(imp_sth)) {
	if (DBIc_WARN(imp_sth) && !dirty)
	    warn("Statement handle %s destroyed without finish()",
		SvPV(sth,na));
	dbd_st_finish(sth);
    }
    dbd_st_destroy(sth);



# end of QBase.xs
