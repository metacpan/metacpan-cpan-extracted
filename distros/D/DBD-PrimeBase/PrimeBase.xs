/*
 $Id: PrimeBase.pm,v 1.4001 2001/07/30 19:29:50
 Copyright (c) 2001  Snap Innovation

 You may distribute under the terms of either the GNU General Public
 License or the Artoistic License, as specified in the Perl README file.
*/

#include "PrimeBase.h"

DBISTATE_DECLARE;

MODULE = DBD::PrimeBase    PACKAGE = DBD::PrimeBase

INCLUDE: PrimeBase.xsi

MODULE = DBD::PrimeBase	PACKAGE = DBD::PrimeBase::dr

void
_admin_internal(drh,dbh,command,dbname=NULL,host=NULL,server=NULL,user=NULL,password=NULL)
    SV* drh
    SV* dbh
    char* command
    char* dbname
    char* host
    char* server
    char* user
    char* password
  PPCODE:
{
	int result;
	int sessid;
	SV* the_handle;
	
	/*
	 *  Connect to the database, if required.
	 */
	if (SvOK(dbh)) {
	    D_imp_dbh(dbh);
	    sessid = imp_dbh->sessid;
	    the_handle = dbh;
	} else {
	  sessid = PrimeBase_dr_connect(drh, host, server, user, password);
	    the_handle = drh;
	  if (!sessid) {
	    XSRETURN_NO;
	  }
    }
 
	if (strEQ(command, "createdb")) {
		result = PrimeBase_create_db(the_handle, sessid, dbname);
	} else if (strEQ(command, "dropdb")) {
		result = PrimeBase_drop_db(the_handle, sessid, dbname);
	} else {
		croak("Unknown command: %s", command);
	}
       
	if (!SvOK(dbh)) {
	   PrimeBase_dr_disconnect(sessid);
	}

	if (result) { XSRETURN_NO; } else { XSRETURN_YES; }
}


MODULE = DBD::PrimeBase    PACKAGE = DBD::PrimeBase::db


void
do(dbh, statement, attr=Nullsv, ...)
    SV *        dbh
    SV *	statement
    SV *        attr
  PROTOTYPE: $$;$@      
  CODE:
{
    D_imp_dbh(dbh);
    SV **params = NULL;
    int numParams = 0;
    int retval;

    if (items > 3) {
	    /*  Handle binding supplied values to placeholders	     */
		/*  Assume user has passed the correct number of parameters  */
		int i;
		numParams = items-3;
		Newz(0, params, numParams, SV *);
		for (i = 0;  i < numParams;  i++) {
		    params[i] = ST(i+3);
		}
    }
    
    if (numParams) {
    	retval = dbd_st_internal_execute(dbh, imp_dbh, statement, attr, numParams, params);
    } else
    	retval = dbd_st_just_doit(dbh, imp_dbh, statement);
    	
    Safefree(params);
    /* remember that dbd_st_execute must return <= -2 for error	*/
    if (retval == 0)		/* ok with no rows affected	*/
		XST_mPV(0, "0E0");	/* (true but zero)		*/
    else if (retval < -1)	/* -1 == unknown number of rows	*/
		XST_mUNDEF(0);		/* <= -2 means error   		*/
    else
		XST_mIV(0, retval);	/* typically 1, rowcount or -1	*/
}


MODULE = DBD::PrimeBase    PACKAGE = DBD::PrimeBase::st


void
_proc_call(sth, statement)
    SV *	sth
    char *	statement
    CODE:

    D_imp_sth(sth);
    int retval;
    if (dbd_st_prep_call(sth, imp_sth, statement) )
    	retval = dbd_st_execute(sth, imp_sth);
    else
    	retval = -2;
    	
    /* remember that dbd_st_execute must return <= -2 for error	*/
    if (retval == 0)		/* ok with no rows affected	*/
	XST_mPV(0, "0E0");	/* (true but zero)		*/
    else if (retval < -1)	/* -1 == unknown number of rows	*/
	XST_mUNDEF(0);		/* <= -2 means error   		*/
    else
	XST_mIV(0, retval);	/* typically 1, rowcount or -1	*/


