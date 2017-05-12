/*
 * $Id: NET.xs,v 1.1 1996/04/14 16:21:36 descarte Exp descarte $
 *
 * Copyright (c) 1994,1995  Tim Bunce
 *           (c)1995, 1996 Alligator Descartes
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 * $Log: NET.xs,v $
 * Revision 1.1  1996/04/14 16:21:36  descarte
 * Initial revision
 *
 */

#include "NET.h"


/* --- Variables --- */


DBISTATE_DECLARE;

/* see dbd_init for initialisation */
SV *dbd_errnum = NULL;
SV *dbd_errstr = NULL;


MODULE = DBD::NET	PACKAGE = DBD::NET

BOOT:
	items = 0;	/* avoid 'unused variable' warning */
	DBISTATE_INIT;
#    fprintf( stderr, "Bootstrapping NET-0.60pl1 ** Disney release\n(c)1995 Alligator Descartes <descarte@mcqueen.com>\n(c)1994-1995 Portions by Tim Bunce <Tim.Bunce@ig.co.uk>\nMuch thanks to Andreas Koenig <k@anna.mind.de>\n\n" );
	/* XXX tis interface will change: */
	DBI_IMP_SIZE("DBD::NET::dr::imp_data_size", sizeof(imp_drh_t));
	DBI_IMP_SIZE("DBD::NET::db::imp_data_size", sizeof(imp_dbh_t));
	DBI_IMP_SIZE("DBD::NET::st::imp_data_size", sizeof(imp_sth_t));
	dbd_init(DBIS);

void
errstr(h)
	SV *	h
	CODE:
	h = 0;	/* avoid 'unused variable' warning */
	ST(0) = sv_mortalcopy(dbd_errstr);


MODULE = DBD::NET	PACKAGE = DBD::NET::dr

void
disconnect_all(drh)
	SV *        drh
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

void
_ListDBs( drh )
	SV *    drh
	PPCODE:
#define MAXDBS 100
#define FASIZE ( MAXDBS * 19 )
	int sqlcode;
	int ndbs;
	int i;
	char *dbsname[MAXDBS + 1];
	char dbsarea[FASIZE];
	if ( ( sqlcode = sql_getdbs(dbsname, &ndbs) ) != 0
) {
		do_error( sqlcode );
	  } else {
		for ( i = 0 ; i < ndbs ; ++i ) {
			EXTEND( sp, 1 );
			PUSHs( sv_2mortal((SV*)newSVpv(dbsname[i], strlen(dbsname[i]))));
		  }
	  }


MODULE = DBD::NET    PACKAGE = DBD::NET::db

void
_login(dbh, host, dbname, user, pass)
	SV *	dbh
	char *	host
	char *	dbname
	char *	user
	char *	pass
	CODE:
	ST(0) = dbd_db_login(dbh, host, dbname, user, pass) ? &sv_yes : &sv_no;


void
commit(dbh)
	SV *        dbh
	CODE:
	ST(0) = dbd_db_commit(dbh) ? &sv_yes : &sv_no;

void
rollback(dbh)
	SV *        dbh
	CODE:
	ST(0) = dbd_db_rollback(dbh) ? &sv_yes : &sv_no;

void
STORE(dbh, keysv, valuesv)
	SV *        dbh
	SV *        keysv
	SV *        valuesv
	CODE:
	if (!dbd_db_STORE(dbh, keysv, valuesv)) {
		/* XXX hand-off to DBI for possible processing */
		croak("Can't set %s->{%s}: unrecognised attribute",
				SvPV(dbh,na), SvPV(keysv,na));
	}
	ST(0) = &sv_undef;  /* discarded anyway */

void
FETCH(dbh, keysv)
	SV *        dbh
	SV *        keysv
	CODE:
	SV *valuesv = dbd_db_FETCH(dbh, keysv);
	if (!valuesv) {
		/* XXX hand-off to DBI for possible processing  */
		croak("Can't get %s->{%s}: unrecognised attribute",
				SvPV(dbh,na), SvPV(keysv,na));
	}
	ST(0) = valuesv;    /* dbd_db_FETCH did sv_2mortal  */

void
disconnect(dbh)
	SV *        dbh
	CODE:
	D_imp_dbh(dbh);
	if ( !DBIc_ACTIVE(imp_dbh) ) {
		if (DBIc_WARN(imp_dbh) && !dirty)
			warn("disconnect: already logged off!");
		XSRETURN_YES;
	}
	/* Check for disconnect() being called whilst refs to cursors       */
	/* still exists. This needs some more thought.                      */
	/* XXX We need to track DBIc_ACTIVE children not just all children  */
	if (DBIc_KIDS(imp_dbh) && DBIc_WARN(imp_dbh) && !dirty) {
		warn("disconnect(%s) invalidates %d associated cursor(s)",
			SvPV(dbh,na), DBIc_KIDS(imp_dbh));
	}
	ST(0) = dbd_db_disconnect(dbh) ? &sv_yes : &sv_no;


void
DESTROY(dbh)
	SV *        dbh
	CODE:
	D_imp_dbh(dbh);
	ST(0) = &sv_yes;
	if (!DBIc_IMPSET(imp_dbh)) {        /* was never fully set up       */
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


MODULE = DBD::NET    PACKAGE = DBD::NET::st

void
_prepare(sth, statement)
	SV *        sth
	char *      statement
	CODE:
	ST(0) = dbd_st_prepare(sth, statement) ? &sv_yes : &sv_no;


void
rows(sth)
	SV *        sth
	CODE:
	D_imp_sth(sth);
#    XST_mIV(0, (IV)imp_sth->cda->rpc);


void
execute(sth, ...)
	SV *        sth
	CODE:
	D_imp_sth(sth);
	/* Handle binding any supplied values to placeholders */
	if (items > 1) {
		char name[16];
		int i, error;
		if (items-1 != HvKEYS(imp_sth->bind_names)) {
			do_error(0);
			XSRETURN_UNDEF;
		}
		for(i=1, error=0; i < items ; ++i) {
			sprintf(name, ":p%d", i);
			if (dbd_bind_ph(sth, imp_sth, name, ST(i)))
				++error;
		}
		if (error) {
			XSRETURN_UNDEF;     /* dbd_bind_ph called ora_error */
		}
	} else if (imp_sth->bind_names) {
		/* oracle will tell us if values have not been bound    */
		warn("execute assuming binds done elsewhere\n");
	}

	/* describe and allocate storage for results */
/*    if (!imp_sth->done_desc && dbd_describe(sth, imp_sth)) {
		XSRETURN_UNDEF;
	} */

	/* Trigger execution of the statement */
/*    if (oexec(imp_sth->cda)) { */ /* will change to oexfet later */
/*        ora_error(sth, imp_sth->cda, imp_sth->cda->rc, "oexec error");
		XSRETURN_UNDEF;
	}*/
	DBIc_ACTIVE_on(imp_sth);
	XST_mYES(0);


void
fetchrow(sth)
	SV *	sth
	PPCODE:
	D_imp_sth(sth);
	int i;
	SV *sv;
	imp_sth->done_desc = 0;
	if ( dbd_describe( sth, imp_sth ) != 0 ) {
		if ( dbis->debug >= 2 )
			warn( "Returning from fetchrow\n" );
		XSRETURN(0);
	  }
	/* Check that execute() was executed sucessfuly. This also implies	*/
	/* that dbd_describe() executed sucessfuly so the memory buffers	*/
	/* are allocated and bound.						*/
#    pif ( !(imp_sth->flags & IMP_STH_EXECUTING) ) {
#	do_error( 1, "no statement executing");
#	XSRETURN(0);
#      }

	/* Fetch each row from the database */

	EXTEND(sp,imp_sth->fbh_num);
	for ( i = 1 ; i <= imp_sth->fbh_num ; i++ ) {
		imp_fbh_t *fbh = &imp_sth->fbh[i];
		if ( dbis->debug >=2 ) {
			printf( "In: DBD::NET::fetchrow'FieldBufferDump: %d\n", i );
			printf( "In: DBD::NET::fetchrow'FieldBufferDump->cbuf: %s\n",
					fbh->cbuf );
			printf( "In: DBD::NET::fetchrow'FieldBufferDump->rlen: %i\n",
					fbh->rlen );
		  }
		SvCUR( fbh->sv ) = fbh->rlen;
/*        sv = sv_mortalcopy( fbh->sv ); */
		sv = sv_2mortal( newSVpv( (char *)fbh->cbuf, fbh->rlen ) );
		PUSHs(sv);
	  }

void
readblob(sth, field, offset, len, destsv=Nullsv)
	SV *        sth
	int field
	long        offset
	long        len
	SV *        destsv
	CODE:
	ST(0) = dbd_st_readblob(sth, field, offset, len, destsv);


void
STORE(dbh, keysv, valuesv)
	SV *        dbh
	SV *        keysv
	SV *        valuesv
	CODE:
	if (!dbd_st_STORE(dbh, keysv, valuesv)) {
		/* XXX hand-off to DBI for possible processing  */
		croak("Can't set %s->{%s}: unrecognised attribute",
				SvPV(dbh,na), SvPV(keysv,na));
	}
	ST(0) = &sv_undef;  /* discarded anyway */


void
FETCH(sth, keysv)
	SV *        sth
	SV *        keysv
	CODE:
	SV *valuesv = dbd_st_FETCH(sth, keysv);
	if (!valuesv) {
		/* XXX hand-off to DBI for possible processing  */
		croak("Can't get %s->{%s}: unrecognised attribute",
				SvPV(sth,na), SvPV(keysv,na));
	}
	ST(0) = valuesv;    /* dbd_st_FETCH did sv_2mortal  */

void
finish(sth)
	SV *        sth
	CODE:
	D_imp_sth(sth);
	D_imp_dbh_from_sth;
	if (!DBIc_ACTIVE(imp_dbh)) {
		/* Either an explicit disconnect() or global destruction        */
		/* has disconnected us from the database. Finish is meaningless */
		/* XXX warn */
		XSRETURN_YES;
	}
	if (!DBIc_ACTIVE(imp_sth)) {
		/* No active statement to finish        */
		/* XXX warn */
		XSRETURN_YES;
	}
	ST(0) = dbd_st_finish(sth) ? &sv_yes : &sv_no;

void
DESTROY(sth)
	SV *        sth
	CODE:
	D_imp_sth(sth);
	ST(0) = &sv_yes;
	if (!DBIc_IMPSET(imp_sth)) {        /* was never fully set up       */
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

# end of NET.xs
