/*
 *  DBD::pNET - DBI network driver
 *
 *  dbdimp.c - this is the main implementation file
 *
 *
 *  Author: Jochen Wiedmann
 *          Am Eisteich 9
 *          72555 Metzingen
 *          Germany
 *
 *          Email: wiedmann@neckar-alb.de
 *          Phone: +49 7123 14881
 *
 *
 *  $Id: dbdimp.c,v 1.1.1.1 1997/09/19 20:34:23 joe Exp $
 *
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include "dbdimp.h"

#include "bindparam.h"


/***************************************************************************
 *
 *  The module is implemented as an RPC::pClient. This has obvious
 *  advantages, but some drawbacks. In particular it is tedious to
 *  check for errors, especially because we try to trust nothing.
 *  And we have to call Perl from within C code, which is error
 *  prone.
 *
 *  As a workaround we use some macros which tend to blow up code, but
 *  should make life easy.
 *
 *  A function calling a remote method looks like this:
 *
 *     int func(args) {
 *
 *         int result = FALSE;
 *         D_imp_dbh(dbh); 
 *         CALL_PREPARE(N, "method");
 *           \*  Push arguments 1..N on the stack
 *            *\
 *         PUSHs(arg2);
 *           ...
 *         PUSHs(argN);
 *         CALL_DO(dbh, errval) {
 *           \*  You may assume success here; however you should
 *            *  still check for sufficient result items, before
 *            *  you use them.
 *            *\
 *           result = okval;  \*  Do something here  *\
 *         } CALL_DONE;
 *         return result;
 *
 **************************************************************************/

#ifdef DBD_PNET_DEBUG
#define CALL_DEBUG                                                         \
    fprintf(stderr, "CheckCall: Calling method %s", SvPV(sp[-2], na));     \
    if (strnEQ("method", SvPV(sp[-2], na), 6)) {                           \
	fprintf(stderr, ", %s.\n", SvPV(sp[0], na));                       \
    } else {                                                               \
        fprintf(stderr, "\n");                                             \
    }
#else
#define CALL_DEBUG
#endif


/*  Prepare calling a remote method, send num arguments
 */
#define CALL_PREPARE(num, method)                                    \
    {dSP;                                                            \
    int count;                                                       \
    SV* methSV = newSVpv(method, strlen(method));                    \
    PUSHMARK(sp);                                                    \
    EXTEND(sp, (num)+2);                                             \
    PUSHs(imp_dbh->client);                                          \
    PUSHs(methSV)
#define METHOD_PREPARE(num, h, method)                               \
    {dSP;                                                            \
    int count;                                                       \
    SV* methSV = newSVpv(method, strlen(method));                    \
    PUSHMARK(sp);                                                    \
    EXTEND(sp, (num)+4);                                             \
    PUSHs(imp_dbh->client);                                          \
    PUSHs(svMethod);                                                 \
    PUSHs(h);                                                        \
    PUSHs(methSV)


/*  Perform calling the remote method
 */
#define CALL_DO(h, errval)                                           \
    PUTBACK;                                                         \
    CALL_DEBUG;                                                      \
    count = perl_call_method("CallInt", G_ARRAY);                    \
    SPAGAIN;                                                         \
    if (CheckCall(sp, count, h))

/*  Terminate the call
 */
#define CALL_DONE                                                    \
    PUTBACK;                                                         \
    sv_free(methSV);}

DBISTATE_DECLARE;


/***************************************************************************
 *
 *  Name:    dbd_init
 *
 *  Purpose: Called when the driver is installed by DBI
 *
 *  Input:   dbistate - pointer to the DBIS variable, used for some
 *               DBI internal things
 *
 *  Returns: Nothing
 *
 **************************************************************************/

static SV* svMethod;

void dbd_init(dbistate_t* dbistate) {
    svMethod = newSVpv("method", 6);
    DBIS = dbistate;
}


/***************************************************************************
 *
 *  Name:    pNET_error
 *
 *  Purpose: Called to associate an error code and an error message
 *           to some handle
 *
 *  Input:   h - the handle in error condition
 *           rc - the error code
 *           what - the error message
 *
 *  Returns: Nothing
 *
 *  Tim Bunce´s Note: Database specific error handling.
 *      This will be split up into specific routines for dbh and
 *      sth level. Also split into helper routine to set number &
 *      string. Err, many changes needed, ramble ...
 *
 **************************************************************************/

void pNET_error(SV* h, int rc, char* what) {
    D_imp_xxh(h);
    SV *errstr = DBIc_ERRSTR(imp_xxh);

    sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);	/* set err early	*/
    sv_setpv(errstr, what);
    DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), errstr);
    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "%s error %d recorded: %s\n",
		what, rc, SvPV(errstr,na));
}


/***************************************************************************
 *
 *  Name:    CheckCall
 *
 *  Purpose: Checks the results of the "CallInt" method
 *
 *  Inputs:  sp - Perl stack pointer
 *           count - number of items returned by agent
 *           h - a dbh or sth for storing error messages
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/

static int CheckCall(SV** sp, int count, SV* h) {
    if (count == 0) {
	pNET_error(h, DBD_PNET_ERR_NET_ARGS,
		   "pNET agent did not return any result");
    } else {
	int result = SvIV(sp[-count+1]);
	if (result) {
#ifdef DBD_PNET_DEBUG
            fprintf(stderr, "CheckCall: Call successfull, result %d.\n",
		    result);
#endif
	    return TRUE;
	}
	if (count > 1) {
	    char* err = SvPV(sp[-count+2], na);
#ifdef DBD_PNET_DEBUG
            fprintf(stderr, "CheckCall: Call failed, error message %s.\n",
		    err);
#endif
	    pNET_error(h, DBD_PNET_ERR_SERVER, err);
	} else {
	    pNET_error(h, DBD_PNET_ERR_NET_ARGS,
		       "pNET agent did not return an error message");
#ifdef DBD_PNET_DEBUG
            fprintf(stderr, "CheckCall: Call failed, no error message.\n");
#endif
	}
    }
    return FALSE;
}


/***************************************************************************
 *
 *  Name:    dbd_db_login
 *
 *  Purpose: Called for connecting to a database and logging in.
 *           Establishing the connection is already done by
 *           DBD::pNET::dr::connect. It remains to allocate a
 *           dbh on the remote machine and get a handle to it.
 *
 *  Input:   dbh - database handle being initialized
 *           imp_dbh - driver's private database handle data
 *           dbname - the data source name
 *           user - user name to connect as
 *           password - passwort to connect with
 *
 *  Returns: TRUE for success, FALSE otherwise; pNET_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_db_login(SV* dbh, imp_dbh_t* imp_dbh, char* dbname, char* uid,
		 char* pwd) {
    int result = FALSE;
    SV* svDbname = newSVpv(dbname, strlen(dbname));
    SV* svUid = newSVpv(uid, strlen(uid));
    SV* svPwd = newSVpv(pwd, strlen(pwd));
    SV** svp;

    if (!SvROK(dbh)) {
	croak("dbh is not a reference.\n");
    }
    if (SvTYPE(SvRV(dbh)) != SVt_PVHV) {
	croak("dbh has unexpected type %d.\n", SvTYPE(SvRV(dbh)));
    }
    svp = hv_fetch((HV*) SvRV(dbh), "client", 6, FALSE);
    imp_dbh->client = Nullsv;
    if (SvTRUE(*svp)) {
	if (SvROK(*svp)) {
	    if (SvTYPE(SvRV(*svp)) == SVt_PVHV) {
		imp_dbh->client = *svp;
		SvREFCNT_inc(imp_dbh->client);
	    }
	} else {
	    if (SvTYPE(*svp) == SVt_PVHV) {
		imp_dbh->client = newRV_inc(*svp);
	    }
	}
    }
    if (!imp_dbh->client) {
	croak("dbh has no or invalid 'client' attribute.\n");
    }

    DBIc_IMPSET_on(imp_dbh);  /*  Tell DBI to call our destructor  */

    /*
     *  Switch to user specific encryption mode, if desired.
     */
    svp = hv_fetch((HV*) SvRV(dbh), "userCipherRef", 13, FALSE);
    if (SvTRUE(*svp)) {
	SV* sv = SvROK(*svp) ? *svp : newRV_noinc(*svp);
	dSP;
	int count;

	PUSHMARK(sp);
	EXTEND(sp, 2);
	PUSHs(imp_dbh->client);
	PUSHs(sv);
	PUTBACK;
	count = perl_call_method("Encrypt", G_EVAL|G_ARRAY);
	SPAGAIN;
        /* Check the eval first */
	if (SvTRUE(GvSV(errgv))) {
	    croak("Error while changing encryption mode to %s: %s",
		  SvPV(*svp, na), SvPV(GvSV(errgv), na));
	} else if (count != 1) {
	    croak("Error while changing encryption mode to %s: No result",
		  SvPV(*svp, na));
	}
	PUTBACK;
    }

    CALL_PREPARE(3, "connect");
    PUSHs(svDbname);
    PUSHs(svUid);
    PUSHs(svPwd);
    CALL_DO(dbh, FALSE) {
	if (count < 2) {
	    pNET_error(dbh, DBD_PNET_ERR_NET_ARGS,
		       "Expected pNET agent to return dbh");
	} else {
	    imp_dbh->rdbh = newSVsv(POPs);
	    DBIc_ACTIVE_on(imp_dbh); 
	    result = TRUE;
	}
    } CALL_DONE;
    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_db_commit
 *           dbd_db_rollback
 *
 *  Purpose: You guess what they should do.
 *
 *  Input:   dbh - database handle being commited or rolled back
 *           imp_dbh - driver's private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; pNET_error has already
 *           been called in the latter case
 *
 **************************************************************************/

static int dbh_method(SV* dbh, imp_dbh_t* imp_dbh, char* method) {
    int result = FALSE;

    METHOD_PREPARE(0, imp_dbh->rdbh, method);
    CALL_DO(dbh, FALSE) {
	result = TRUE;
    } CALL_DONE;

    return result;
}

int dbd_db_commit(SV* dbh, imp_dbh_t* imp_dbh) {
    return dbh_method(dbh, imp_dbh, "commit");
}

int dbd_db_rollback(SV* dbh, imp_dbh_t* imp_dbh) {
    return dbh_method(dbh, imp_dbh, "rollback");
}


/***************************************************************************
 *
 *  Name:    dbd_discon_all
 *
 *  Purpose: Disconnect all database handles at shutdown time
 *
 *  Input:   dbh - database handle being disconnected
 *           imp_dbh - drivers private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; do_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_discon_all (SV *drh, imp_drh_t *imp_drh) {
    /* The disconnect_all concept is flawed and needs more work */
    if (!dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING",0))) {
	sv_setiv(DBIc_ERR(imp_drh), (IV)1);
	sv_setpv(DBIc_ERRSTR(imp_drh),
		(char*)"disconnect_all not implemented");
	DBIh_EVENT2(drh, ERROR_event,
		    DBIc_ERR(imp_drh), DBIc_ERRSTR(imp_drh));
	return FALSE;
    }
    if (perl_destruct_level)
	perl_destruct_level = 0;
    return FALSE;
}


/***************************************************************************
 *
 *  Name:    dbd_db_disconnect
 *
 *  Purpose: Disconnect a database handle from its database
 *
 *  Input:   dbh - database handle being disconnected
 *           imp_dbh - driver's private database handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; pNET_error has already
 *           been called in the latter case
 *
 **************************************************************************/

int dbd_db_disconnect(SV* dbh, imp_dbh_t* imp_dbh) {
    /* We assume that disconnect will always work	*/
    /* since most errors imply already disconnected.	*/
    DBIc_ACTIVE_off(imp_dbh);

    return dbh_method(dbh, imp_dbh, "disconnect");
}


/***************************************************************************
 *
 *  Name:    dbd_db_destroy
 *
 *  Purpose: Our part of the dbh destructor
 *
 *  Input:   dbh - database handle being destroyed
 *           imp_dbh - driver's private database handle data
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_db_destroy(SV* dbh, imp_dbh_t* imp_dbh) {
    if (DBIc_ACTIVE(imp_dbh)) {
	dbd_db_disconnect(dbh, imp_dbh);
    }
    if (imp_dbh->rdbh) {
	dbh_method(dbh, imp_dbh, "DESTROY");
    }
    if (imp_dbh->client) {
	SvREFCNT_dec(imp_dbh->client);
    }
    DBIc_IMPSET_off(imp_dbh);
}


/***************************************************************************
 *
 *  Name:    dbd_db_STORE_attrib
 *
 *  Purpose: Function for storing dbh attributes; we currently support
 *           just nothing. :-)
 *
 *  Input:   dbh - database handle being modified
 *           imp_dbh - driver's private database handle data
 *           keysv - the attribute name
 *           valuesv - the attribute value
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/

int dbd_db_STORE_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv, SV* valuesv) {
    int result = FALSE;

    METHOD_PREPARE(2, imp_dbh->rdbh, "STORE");
    PUSHs(keysv);
    PUSHs(valuesv);
    CALL_DO(dbh, FALSE) {
	result = TRUE;
    } CALL_DONE;
    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_db_FETCH_attrib
 *
 *  Purpose: Function for fetching dbh attributes; we currently support
 *           just nothing. :-)
 *
 *  Input:   dbh - database handle being queried
 *           imp_dbh - driver's private database handle data
 *           keysv - the attribute name
 *           valuesv - the attribute value
 *
 *  Returns: An SV*, if sucessfull; NULL otherwise
 *
 *  Notes:   Do not forget to call sv_2mortal in the former case!
 *
 **************************************************************************/

SV* dbd_db_FETCH_attrib(SV* dbh, imp_dbh_t* imp_dbh, SV* keysv) {
    SV* result = Nullsv;

    METHOD_PREPARE(1, imp_dbh->rdbh, "FETCH");
    PUSHs(keysv);
    CALL_DO(dbh, FALSE) {
        if (count < 2) {
	    pNET_error(dbh, DBD_PNET_ERR_NET_ARGS,
		       "pNET agent returning no attribute");
	} else {
	    result = newSVsv(POPs);
	}
    } CALL_DONE;
    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_st_prepare
 *
 *  Purpose: Called for preparing an SQL statement; our part of the
 *           statement handle constructor
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - driver's private statement handle data
 *           statement - pointer to string with SQL statement
 *           attribs - statement attributes, currently not in use
 *
 *  Returns: TRUE for success, FALSE otherwise; pNET_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_prepare(SV* sth, imp_sth_t* imp_sth, char* statement, SV* attribs) {
    /*
     *  We *could* send the statement being prepared immediately,
     *  but the DBI specification allows us to relay that until
     *  the first 'execute'.
     */

    /*
     *  Count the number of parameters
     */
    DBIc_NUM_PARAMS(imp_sth) = CountParam(statement);


    /*
     *  Allocate memory for parameters
     */
    imp_sth->params = AllocParam(DBIc_NUM_PARAMS(imp_sth));

    DBIc_NUM_ROWS(imp_sth) = -1;
    DBIc_IMPSET_on(imp_sth);
    return TRUE;
}


/***************************************************************************
 *
 *  Name:    dbd_describe
 *
 *  Purpose: Called from within the fetch method to describe the result
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - our part of the statement handle, there's no
 *               need for supplying both; Tim just doesn't remove it
 *
 *  Returns: TRUE for success, FALSE otherwise; pNET_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_describe(SV* h, imp_sth_t* imp_sth) {
    imp_sth->done_desc = 1;
    return TRUE;
}


/***************************************************************************
 *
 *  Name:    dbd_st_execute
 *
 *  Purpose: Called for preparing an SQL statement; our part of the
 *           statement handle constructor
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - driver's private statement handle data
 *           statement - pointer to string with SQL statement
 *           attribs - statement attributes, currently not in use
 *
 *  Returns:  -2: error, >=0: ok row count,  -1: unknown count
 *
 **************************************************************************/

int dbd_st_execute(SV* sth, imp_sth_t* imp_sth) {
    int result = -2;
    D_imp_dbh_from_sth;
    SV* statement;
    int i;

    /*  Fetch the 'statement' attribute from the sth attribute hash
     */
    if (!SvROK(sth)  ||  SvTYPE(SvRV(sth)) != SVt_PVHV) {
	croak("%s->execute: Object is not a hash ref", SvPV(sth, na));
    } else {
	HV* hv = (HV*) SvRV(sth);
	SV** svp = hv_fetch(hv, "Statement", 9, FALSE);
	if (!svp  ||  !*svp) {
	    croak("%s->execute: Object has no valid 'statement' attribute",
		  SvPV(sth, na));
	}
	statement = *svp;
    }

    DBIc_NUM_ROWS(imp_sth) = -1;

    if (!imp_sth->done_prepare) {
	/* This is the first time, that the statement is executed.
	 * We must ensure, that the client will prepare the statement
	 * and returns a statement handle.
	 */
	METHOD_PREPARE(1, imp_dbh->rdbh, "prepare");
	PUSHs(statement);
	for (i = 0;  i < DBIc_NUM_PARAMS(imp_sth);  i++) {
	    PUSHs(imp_sth->params[i].value);
	    PUSHs(sv_2mortal(newSViv(imp_sth->params[i].type)));
	}
	CALL_DO(sth, FALSE) {
	    if (count < 4) {
		pNET_error(sth, DBD_PNET_ERR_NET_ARGS,
			   "pNET agent returning no statement handle");
	    } else {
		imp_sth->rsth = newSVsv(sp[-count+2]);
		DBIc_ACTIVE_on(imp_sth);
		DBIc_NUM_FIELDS(imp_sth) = SvIV(sp[-count+3]);
		DBIc_NUM_ROWS(imp_sth) = result = SvIV(sp[-count+4]);
		imp_sth->done_prepare = 1;
	    }
	} CALL_DONE;
    } else {
	/* The statement has already been executed; reexecute it.
	 */
	METHOD_PREPARE(0, imp_sth->rsth, "execute");
	for (i = 0;  i < DBIc_NUM_PARAMS(imp_sth);  i++) {
	    PUSHs(imp_sth->params[i].value);
	    PUSHs(sv_2mortal(newSViv(imp_sth->params[i].type)));
	}
	CALL_DO(sth, -2) {
	    if (count < 2) {
		pNET_error(sth, DBD_PNET_ERR_NET_ARGS,
			   "pNET agent returning no statement data");
	    } else {
		DBIc_NUM_ROWS(imp_sth) = result = SvIV(sp[-count+2]);
	    }
	} CALL_DONE;
    }

    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_st_fetch
 *
 *  Purpose: Called for fetching a result row
 *
 *  Input:   sth - statement handle being initialized
 *           imp_sth - driver's private statement handle data
 *
 *  Returns: array of columns; the array is allocated by DBI via
 *           DBIS->get_fbav(imp_sth), even the values of the array
 *           are prepared, we just need to modify them appropriately
 *
 **************************************************************************/

AV *dbd_st_fetch(SV* sth, imp_sth_t* imp_sth) {
    D_imp_dbh_from_sth;
    AV* result = Nullav;
    SV* cb = DBIc_is(imp_sth, DBIcf_ChopBlanks) ? &sv_yes : &sv_no;

    METHOD_PREPARE(1, imp_sth->rsth, "fetch");
    PUSHs(cb);
    CALL_DO(sth, Nullav) {
	if (count > 1) {
	    int num_fields = DBIc_NUM_FIELDS(imp_sth);
	    if (count != num_fields+1) {
		pNET_error(sth, DBD_PNET_ERR_NET_ARGS,
			   "pNET agent returning wrong number of fields");
	    } else {
		int i;
		result = DBIS->get_fbav(imp_sth);
		for (i = 0;  i < num_fields;  i++) {
		    sv_setsv(AvARRAY(result)[i], sp[-count+2+i]);
		}
	    }
	}
    } CALL_DONE;
    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_st_blob_read
 *
 *  Purpose: Used for blob reads if the statement handles "LongTruncOk"
 *           attribute (currently not supported by DBD::mysql)
 *
 *  Input:   SV* - statement handle from which a blob will be fetched
 *           imp_sth - driver's private statement handle data
 *           field - field number of the blob (note, that a row may
 *               contain more than one blob)
 *           offset - the offset of the field, where to start reading
 *           len - maximum number of bytes to read
 *           destrv - RV* that tells us where to store
 *           destoffset - destination offset
 *
 *  Returns: TRUE for success, FALSE otrherwise; pNET_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field, long offset,
		      long len, SV *destrv, long destoffset) {
    pNET_error(sth, DBD_PNET_ERR_NOT_IMPLEMENTED, "Not implemented");
    return FALSE;
}


/***************************************************************************
 *
 *  Name:    dbd_st_rows
 *
 *  Purpose: Reads number of result rows
 *
 *  Input:   sth - statement handle
 *           imp_sth - driver's private statement handle data
 *
 *  Returns: Number of rows returned or affected by executing the
 *           statement
 *
 **************************************************************************/

int dbd_st_rows(SV* sth, imp_sth_t* imp_sth) {
    return DBIc_NUM_ROWS(imp_sth);
}


/***************************************************************************
 *
 *  Name:    dbd_st_finish
 *
 *  Purpose: Called for freeing a mysql result
 *
 *  Input:   sth - statement handle being finished
 *           imp_sth - driver's private statement handle data
 *
 *  Returns: TRUE for success, FALSE otherwise; pNET_error() will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_finish(SV* sth, imp_sth_t* imp_sth) {
    D_imp_dbh_from_sth;
    int result = FALSE;

    DBIc_ACTIVE_off(imp_sth);

    METHOD_PREPARE(0, imp_sth->rsth, "finish");
    CALL_DO(sth, FALSE) {
	result = TRUE;
    } CALL_DONE;
    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_st_destroy
 *
 *  Purpose: Our part of the statement handles destructor
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - driver's private statement handle data
 *
 *  Returns: Nothing
 *
 **************************************************************************/

void dbd_st_destroy(SV* sth, imp_sth_t* imp_sth) {
    D_imp_dbh_from_sth;

    DBIc_IMPSET_off(imp_sth);		/* let DBI know we've done it	*/

    /*
     *  Free values allocated by dbd_bind_ph
     */
    FreeParam(imp_sth->params, DBIc_NUM_PARAMS(imp_sth));
    imp_sth->params = NULL;

    if (imp_sth->rsth) {
	METHOD_PREPARE(0, imp_sth->rsth, "DESTROY");
	CALL_DO(sth, FALSE); {
	} CALL_DONE;
	imp_sth->rsth = NULL;
    }
}


/***************************************************************************
 *
 *  Name:    dbd_st_STORE_attrib
 *
 *  Purpose: Modifies a statement handles attributes; we currently
 *           support just nothing
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - driver's private statement handle data
 *           keysv - attribute name
 *           valuesv - attribute value
 *
 *  Returns: TRUE for success, FALSE otrherwise; pNET_error will
 *           be called in the latter case
 *
 **************************************************************************/

int dbd_st_STORE_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv, SV* valuesv) {
    int result = FALSE;
    D_imp_dbh_from_sth;
    STRLEN len;
    char* key = SvPV(keysv, len);

    if (len == 10 && strEQ(key, "ChopBlanks")) {
	if (SvTRUE(valuesv)) {
	    DBIc_on(imp_sth, DBIcf_ChopBlanks);
	} else {
	    DBIc_off(imp_sth, DBIcf_ChopBlanks);
	}
	return TRUE;
    }

    METHOD_PREPARE(2, imp_sth->rsth, "STORE");
    PUSHs(keysv);
    PUSHs(valuesv);
    CALL_DO(sth, FALSE) {
	result = TRUE;
    } CALL_DONE;
    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_st_FETCH_attrib
 *
 *  Purpose: Retrieves a statement handles attributes; we currently
 *           support just those required by DBI; this will change
 *           in the near future
 *
 *  Input:   sth - statement handle being destroyed
 *           imp_sth - driver's private statement handle data
 *           keysv - attribute name
 *
 *  Returns: TRUE for success, FALSE otrherwise; pNET_error will
 *           be called in the latter case
 *
 **************************************************************************/

SV* dbd_st_FETCH_attrib(SV* sth, imp_sth_t* imp_sth, SV* keysv) {
    SV* result = Nullsv;
    D_imp_dbh_from_sth;
    STRLEN len;
    char* key = SvPV(keysv, len);

    if (len == 10 && strEQ(key, "ChopBlanks")) {
	return DBIc_is(imp_sth, DBIcf_ChopBlanks) ? &sv_yes : &sv_no;
    }

    METHOD_PREPARE(1, imp_sth->rsth, "FETCH");
    PUSHs(keysv);
    CALL_DO(sth, FALSE) {
        if (count < 2) {
	    pNET_error(sth, DBD_PNET_ERR_NET_ARGS,
		       "pNET returning no attribute");
	} else {
	    result = sv_2mortal(newSVsv(sp[-count+2]));
	}
    } CALL_DONE;
    return result;
}


/***************************************************************************
 *
 *  Name:    dbd_bind_ph
 *
 *  Purpose: Binds a statement value to a parameter
 *
 *  Input:   sth - statement handle
 *           imp_sth - driver's private statement handle data
 *           param - parameter number, counting starts with 1
 *           value - value being inserted for parameter "param"
 *           sql_type - ANSI sql type
 *           attribs - bind parameter attributes, currently this must be
 *               one of the values SQL_CHAR, ...
 *           is_inout - TRUE, if parameter is an output variable (currently
 *               this is not supported)
 *           maxlen - ???
 *
 *  Returns: TRUE for success, FALSE otherwise
 *
 **************************************************************************/


int dbd_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,
		 IV sql_type, SV *attribs, int is_inout, IV maxlen) {
    int paramNum = SvIV(param);

    if (paramNum <= 0  ||  paramNum > DBIc_NUM_PARAMS(imp_sth)) {
        pNET_error(sth, DBD_PNET_ERR_ILLEGAL_PARAM_NUM,
		       "Illegal parameter number");
	return FALSE;
    }

    if (is_inout) {
        pNET_error(sth, DBD_PNET_ERR_NOT_IMPLEMENTED,
		       "Output parameters not implemented");
	return FALSE;
    }

    return BindParam(&imp_sth->params[paramNum - 1], value, sql_type);
}


