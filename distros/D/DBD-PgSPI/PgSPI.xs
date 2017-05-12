/*
   $Id: PgSPI.xs,v 1.20 1999/09/29 20:30:23 mergl Exp $

   Copyright (c) 2000,2001 Alex Pilosov
   Copyright (c) 1997,1998,1999 Edmund Mergl
   Portions Copyright (c) 1994,1995,1996,1997 Tim Bunce

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/


#include "PgSPI.h"


#ifdef _MSC_VER
#define strncasecmp(a,b,c) _strnicmp((a),(b),(c))
#endif



DBISTATE_DECLARE;


MODULE = DBD::PgSPI	PACKAGE = DBD::PgSPI

PROTOTYPES: DISABLE

BOOT:
    items = 0;  /* avoid 'unused variable' warning */
    DBISTATE_INIT;
    /* XXX this interface will change: */
    DBI_IMP_SIZE("DBD::PgSPI::dr::imp_data_size", sizeof(imp_drh_t));
    DBI_IMP_SIZE("DBD::PgSPI::db::imp_data_size", sizeof(imp_dbh_t));
    DBI_IMP_SIZE("DBD::PgSPI::st::imp_data_size", sizeof(imp_sth_t));
    dbd_init(DBIS);


# ------------------------------------------------------------
# database level interface
# ------------------------------------------------------------
MODULE = DBD::PgSPI	PACKAGE = DBD::PgSPI::db

void
_login(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    if ( DBIc_ACTIVE(imp_dbh) ) {
      warn("Attempt to open second connection in SPI, ignored");
    } else {
      dbd_db_login(dbh, imp_dbh, "", "", "");
    }
    ST(0) = &PL_sv_yes;


void
commit(dbh)
    SV *	dbh
    CODE:
    warn("commit ineffective in PgSPI");
    ST(0) = &PL_sv_yes;
    

void
rollback(dbh)
    SV *	dbh
    CODE:
    warn("rollback ineffective in PgSPI");
    ST(0) = &PL_sv_yes;


void
disconnect(dbh)
    SV *	dbh
    CODE:
    D_imp_dbh(dbh);
    if ( !DBIc_ACTIVE(imp_dbh) ) {
        XSRETURN_YES;
    }
    /* pre-disconnect checks and tidy-ups */
    if (DBIc_CACHED_KIDS(imp_dbh)) {
        SvREFCNT_dec(DBIc_CACHED_KIDS(imp_dbh));
        DBIc_CACHED_KIDS(imp_dbh) = Nullhv;
    }
    /* Check for disconnect() being called whilst refs to cursors	*/
    /* still exists. This possibly needs some more thought.		*/
    if (DBIc_ACTIVE_KIDS(imp_dbh) && DBIc_WARN(imp_dbh) && !PL_dirty) {
        char *plural = (DBIc_ACTIVE_KIDS(imp_dbh)==1) ? "" : "s";
        warn("disconnect(%s) invalidates %d active statement%s. %s",
            SvPV(dbh,PL_na), (int)DBIc_ACTIVE_KIDS(imp_dbh), plural,
            "Either destroy statement handles or call finish on them before disconnecting.");
    }
    ST(0) = dbd_db_disconnect(dbh, imp_dbh) ? &PL_sv_yes : &PL_sv_no;


void
STORE(dbh, keysv, valuesv)
    SV *	dbh
    SV *	keysv
    SV *	valuesv
    CODE:
    D_imp_dbh(dbh);
    ST(0) = &PL_sv_yes;
    if (!dbd_db_STORE_attrib(dbh, imp_dbh, keysv, valuesv)) {
        if (!DBIS->set_attr(dbh, keysv, valuesv)) {
            ST(0) = &PL_sv_no;
        }
    }


void
FETCH(dbh, keysv)
    SV *	dbh
    SV *	keysv
    CODE:
    D_imp_dbh(dbh);
    SV *valuesv = dbd_db_FETCH_attrib(dbh, imp_dbh, keysv);
    if (!valuesv) {
        valuesv = DBIS->get_attr(dbh, keysv);
    }
    ST(0) = valuesv;	/* dbd_db_FETCH_attrib did sv_2mortal	*/


void
DESTROY(dbh)
    SV *	dbh
    PPCODE:
    D_imp_dbh(dbh);
    ST(0) = &PL_sv_yes;
    if (!DBIc_IMPSET(imp_dbh)) {	/* was never fully set up	*/
        if (DBIc_WARN(imp_dbh) && !PL_dirty && dbis->debug >= 2) {
            warn("Database handle %s DESTROY ignored - never set up", SvPV(dbh,PL_na));
        }
    }
    else {
	/* pre-disconnect checks and tidy-ups */
        if (DBIc_CACHED_KIDS(imp_dbh)) {
            SvREFCNT_dec(DBIc_CACHED_KIDS(imp_dbh));
            DBIc_CACHED_KIDS(imp_dbh) = Nullhv;
        }
        if (DBIc_IADESTROY(imp_dbh)) { /* want's ineffective destroy    */
            DBIc_ACTIVE_off(imp_dbh);
        }
        if (DBIc_ACTIVE(imp_dbh)) {
            if (DBIc_WARN(imp_dbh) && (!PL_dirty || dbis->debug >= 3)) {
                warn("Database handle destroyed without explicit disconnect");
            }
            if (!DBIc_has(imp_dbh,DBIcf_AutoCommit)) {
                dbd_db_rollback(dbh, imp_dbh);	/* ROLLBACK! */
            }
            dbd_db_disconnect(dbh, imp_dbh);
        }
        dbd_db_destroy(dbh, imp_dbh);
    }


# -- end of DBD::PgSPI::db


# ------------------------------------------------------------
# statement interface
# ------------------------------------------------------------
MODULE = DBD::PgSPI	PACKAGE = DBD::PgSPI::st

void
_prepare(sth, statement, attribs=Nullsv)
    SV *	sth
    char *	statement
    SV *	attribs
    CODE:
    {
    D_imp_sth(sth);
    D_imp_dbh_from_sth;
    DBD_ATTRIBS_CHECK("_prepare", sth, attribs);
    if (!strncasecmp(statement, "begin",    5) ||
        !strncasecmp(statement, "end",      4) ||
        !strncasecmp(statement, "commit",   6) ||
        !strncasecmp(statement, "abort",    5) ||
        !strncasecmp(statement, "rollback", 8) ) {
        warn("please use DBI functions for transaction handling");
        ST(0) = &PL_sv_no;
    } else {
        ST(0) = dbd_st_prepare(sth, imp_sth, statement, attribs) ? &PL_sv_yes : &PL_sv_no;
    }
    }


void
rows(sth)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    XST_mIV(0, dbd_st_rows(sth, imp_sth));


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
    if (attribs) {
        if (SvNIOK(attribs)) {
            sql_type = SvIV(attribs);
            attribs = Nullsv;
        }
        else {
            SV **svp;
            DBD_ATTRIBS_CHECK("bind_param", sth, attribs);
	    /* XXX we should perhaps complain if TYPE is not SvNIOK */
            DBD_ATTRIB_GET_IV(attribs, "TYPE", 4, svp, sql_type);
        }
    }
    ST(0) = dbd_bind_ph(sth, imp_sth, param, value, sql_type, attribs, FALSE, 0) ? &PL_sv_yes : &PL_sv_no;
    }

void
execute(sth, ...)
    SV *	sth
    CODE:
    D_imp_sth(sth);
    int ret;
    if (items > 1) {
	/* Handle binding supplied values to placeholders	*/
        int i;
        SV *idx;
        imp_sth->all_params_len = 0; /* used for malloc of statement string in case we have placeholders */
        if (items-1 != DBIc_NUM_PARAMS(imp_sth)) {
            croak("execute called with %ld bind variables, %d needed", items-1, DBIc_NUM_PARAMS(imp_sth));
            XSRETURN_UNDEF;
        }
        idx = sv_2mortal(newSViv(0));
        for(i=1; i < items ; ++i) {
            sv_setiv(idx, i);
            if (!dbd_bind_ph(sth, imp_sth, idx, ST(i), 0, Nullsv, FALSE, 0)) {
		XSRETURN_UNDEF;	/* dbd_bind_ph already registered error	*/
            }
        }
    }
    ret = dbd_st_execute(sth, imp_sth);
    /* remember that dbd_st_execute must return <= -2 for error	*/
    if (ret == 0) {		/* ok with no rows affected	*/
        XST_mPV(0, "0E0");	/* (true but zero)		*/
    }
    else if (ret < -1) {	/* -1 == unknown number of rows	*/
        XST_mUNDEF(0);		/* <= -2 means error   		*/
    }
    else {
        XST_mIV(0, ret);	/* typically 1, rowcount or -1	*/
    }


void
fetchrow_arrayref(sth)
    SV *	sth
    ALIAS:
        fetch = 1
    CODE:
    D_imp_sth(sth);
    AV *av = dbd_st_fetch(sth, imp_sth);
    ST(0) = (av) ? sv_2mortal(newRV_inc((SV *)av)) : &PL_sv_undef;


void
fetchrow_array(sth)
    SV *	sth
    ALIAS:
        fetchrow = 1
    PPCODE:
    D_imp_sth(sth);
    AV *av;
    av = dbd_st_fetch(sth, imp_sth);
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
    ST(0) = dbd_st_finish(sth, imp_sth) ? &PL_sv_yes : &PL_sv_no;


void
STORE(sth, keysv, valuesv)
    SV *	sth
    SV *	keysv
    SV *	valuesv
    CODE:
    D_imp_sth(sth);
    ST(0) = &PL_sv_yes;
    if (!dbd_st_STORE_attrib(sth, imp_sth, keysv, valuesv)) {
        if (!DBIS->set_attr(sth, keysv, valuesv)) {
            ST(0) = &PL_sv_no;
        }
    }


# FETCH renamed and ALIAS'd to avoid case clash on VMS :-(
void
FETCH_attrib(sth, keysv)
    SV *	sth
    SV *	keysv
    ALIAS:
    FETCH = 1
    CODE:
    D_imp_sth(sth);
    SV *valuesv = dbd_st_FETCH_attrib(sth, imp_sth, keysv);
    if (!valuesv) {
        valuesv = DBIS->get_attr(sth, keysv);
    }
    ST(0) = valuesv;	/* dbd_st_FETCH_attrib did sv_2mortal	*/


void
DESTROY(sth)
    SV *	sth
    PPCODE:
    D_imp_sth(sth);
    ST(0) = &PL_sv_yes;
    if (!DBIc_IMPSET(imp_sth)) {	/* was never fully set up	*/
        if (DBIc_WARN(imp_sth) && !PL_dirty && dbis->debug >= 2) {
            warn("Statement handle %s DESTROY ignored - never set up", SvPV(sth,PL_na));
        }
    }
    else {
        if (DBIc_IADESTROY(imp_sth)) { /* want's ineffective destroy    */
            DBIc_ACTIVE_off(imp_sth);
        }
        if (DBIc_ACTIVE(imp_sth)) {
            dbd_st_finish(sth, imp_sth);
        }
        dbd_st_destroy(sth, imp_sth);
    }


# end of PgSPI.xs
