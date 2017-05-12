/*
   $Id: dbdimp.c,v 1.2 1995/10/25 22:21:12 gj Exp $
	
   Copyright (c) 1995 What Software, INC (Changes copywrighted)
   Copyright (c) 1995 Filoli Information Systems, INC (Changes copyrighed)
   Copyright (c) 1994,1995  Tim Bunce
  
   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.
  
*/

#import <remote/NXProxy.h>
#import <appkit/appkit.h>
#import "/LocalLibrary/QuickBase/Headers/QuickBase.h"
#define NEED_DBIXS_VERSION 7
#include "DBIXS.h"
#include "dbdimp.h"

DBISTATE_DECLARE;

static SV          *qb_long;
static SV          *qb_trunc;
id                  qb;		/* Should be moved to correct structure in
				 * dbdimp.h for multi connects */

boot_QBase()
/*
 * For staticly built systems...Currently a hack
 */
{
}


void
dbd_init(dbistate)
    dbistate_t         *dbistate;

/*
 * Initialize the database object so we can get some work done.
 */
{
    DBIS = dbistate;
    qb_long = perl_get_sv("QBase::qb_long", GV_ADDMULTI);
    qb_trunc = perl_get_sv("QBase::qb_trunc", GV_ADDMULTI);
}


/* Database specific error handling.
	This will be split up into specific routines
	for dbh and sth level.
	Also split into helper routine to set number & string.
	Err, many changes needed, ramble ...
*/

void
qb_error(h, what)
    SV                 *h;
    char               *what;

 /*
  * Currently we just warn, but we should print out more information and we
  * really should send it to standard Error out so it does not get lost in
  * the pipe stream. 
  */
{
    printf("Warning: %s\n", what);
}


void
fbh_dump(fbh, i)
    imp_fbh_t          *fbh;
    int                 i;

/*
 * Dump information about imp_fbh_t. Currently not used since cursors is
 * not working
 */
{
}

/* ================================================================== */


static void
dump_error_status(cda)
 /* struct cda_def *cda; */
    int                *cda;

/*
 * Dump error status, currently not used.
 */
{
}


/* ================================================================== */

int
dbd_db_login(dbh, dbname, uid, pwd)
    SV                 *dbh;
    char               *dbname;
    char               *uid;
    char               *pwd;

/*
 * Login in routines.  Currently does support softwareIDs nor network
 * database request
 */
{
    D_imp_dbh(dbh);
    int                 ret;

    qb = [QuickBase alloc];
    [qb init];
    [qb initDatabase:dbname software:NULL login:uid
     password:pwd return:&ret];

    switch (ret) {
    case ERR_SFTUSRLIM:
	qb_error(dbh, "No more software licenses left.");
	return 0;
    case ERR_DBSUSRLIM:
	qb_error(dbh, "No more database license left.");
	return 0;
    case ERR_NOSERVER:
	qb_error(dbh, "Can't find server!");
	return 0;
    case ERR_INCORRECT_LOGIN:
	qb_error(dbh, "login failed");
	return 0;
    }
    DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now			 */
    DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing	 */
    return 1;
}


int
dbd_db_do(dbh, statement)	/* return 1 else 0 on failure		 */
    SV                 *dbh;
    char               *statement;
{
 /* not implemented yet, may never be - use do method in DBI.pm	 */
    return -1;
}


int
dbd_db_commit(dbh)
    SV                 *dbh;

 /*
  * Commiting information to the database.  Currently not supported, but will
  * be supported soon 
  */
{
    return -1;
}

int
dbd_db_rollback(dbh)
    SV                 *dbh;

 /*
  * Rolling Back a database, currently not support, but will be supported
  * soon. 
  */
{
 /* Not implemented because of lack of QuickBase direct support commands */
    return -1;
}


int
dbd_db_disconnect(dbh)
    SV                 *dbh;

 /*
  * disconnect from database 
  */
{
    D_imp_dbh(dbh);
 /* We assume that disconnect will always work	 */
 /* since most errors imply already disconnected.	 */
    DBIc_ACTIVE_off(imp_dbh);
    [qb free];
 /* We don't free imp_dbh since a reference still exists	 */
 /* The DESTROY method is the only one to 'free' memory.	 */
 /* Note that statement objects may still exists for this dbh!	 */
    return 1;
}


void
dbd_db_destroy(dbh)
    SV                 *dbh;
{
    D_imp_dbh(dbh);

    if (DBIc_ACTIVE(imp_dbh))
	dbd_db_disconnect(dbh);
 /* Nothing in imp_dbh to be freed	 */
    DBIc_IMPSET_off(imp_dbh);
}


int
dbd_db_STORE(dbh, keysv, valuesv)
    SV                 *dbh;
    SV                 *keysv;
    SV                 *valuesv;
{
    D_imp_dbh(dbh);
    STRLEN              kl;
    char               *key = SvPV(keysv, kl);
    SV                 *cachesv = NULL;
    int                 on = SvTRUE(valuesv);

    if (kl == 10 && strEQ(key, "AutoCommit")) {
/* EEK! Oracle Code! 
	if ( (on) ? ocon(&imp_dbh->lda) : ocof(&imp_dbh->lda) ) {
	    ora_error(dbh, &imp_dbh->lda, imp_dbh->lda.rc, "ocon/ocof failed");
	} else cachesv = (on) ? &sv_yes : &sv_no;
*/
    } else {
	return FALSE;
    }
    if (cachesv)		/* cache value for later DBI 'quick' fetch? */
	hv_store((HV *) SvRV(dbh), key, kl, cachesv, 0);
    return TRUE;

}


SV                 *
dbd_db_FETCH(dbh, keysv)
    SV                 *dbh;
    SV                 *keysv;
{
 /* D_imp_dbh(dbh); */
    STRLEN              kl;
    char               *key = SvPV(keysv, kl);
    SV                 *retsv = NULL;

 /* Default to caching results for DBI dispatch quick_FETCH	 */
    int                 cacheit = TRUE;

    if (1) {			/* no attribs defined yet	 */
	return Nullsv;
    }
    if (cacheit) {		/* cache for next time (via DBI quick_FETCH)	 */
	hv_store((HV *) SvRV(dbh), key, kl, retsv, 0);
	(void)SvREFCNT_inc(retsv);	/* so sv_2mortal won't free it	 */
    }
    return sv_2mortal(retsv);

}



/* ================================================================== */
int
dbd_st_prepare(sth, statement, attribs)
    SV                 *sth;
    char               *statement;
    SV                 *attribs;
{
    D_imp_sth(sth);
    DBIc_NUM_FIELDS(imp_sth) = 0;
    DBIc_IMPSET_on(imp_sth);
    [qb makeCommand:statement];
    return 1;
}


void
dbd_preparse(imp_sth, statement)
    imp_sth_t          *imp_sth;
    char               *statement;
{
    [qb makeCommand:statement];
}


int
dbd_bind_ph(sth, ph_namesv, newvalue, attribs)
    SV                 *sth;
    SV                 *ph_namesv;
    SV                 *newvalue;
    SV                 *attribs;
{
    return -1;
}



int
dbd_describe(h, imp_sth)
    SV                 *h;
    imp_sth_t          *imp_sth;
{
    return -1;
}

#define QBMAXCOLS 20

static char         czCols[QBMAXCOLS][256];

/* 
Here is the heart of the perl/DBI/DBD/C/Objective-C interface to QuickBase via
SQL.  The first problem why fetch didn't work according to the QuickBase docs 
is that getresult needs to be called. GJ 
  
This code had one entry many happy returns which can cause grief so I added 
<shudder> structure to it.
*/
int
dbd_st_execute(sth)
    SV                 *sth;
{
    int                 command, result, myrc;
    int                 count, i;
    AV                 *mycols = Nullav;
    SV                 *mysv = Nullsv;
    char               *location;
    STRLEN              trash;

    D_imp_sth(sth);

    command = [qb executeCommand:NULL];
    if (!command) {
	qb_error(NULL,[qb getSQLMessage]);
	DBIc_ACTIVE_off(imp_sth);
	myrc = 0;
    } else {			/* command was successfully parsed and sent */
	result = [qb getResult];
	if (-1 == result) {	/* command was not successfully executed */
	    qb_error(NULL,[qb getSQLMessage]);
	    DBIc_ACTIVE_off(imp_sth);
	    myrc = 0;
	} else {		/* command was successfully executed */
	    DBIc_ACTIVE_on(imp_sth);
	    count = DBIc_NUM_FIELDS(imp_sth) = [qb getNumCols];
	    if (count > QBMAXCOLS)
		count = QBMAXCOLS;	/* Make sure we can't get into
					 * trouble here */
	    for (i = 0; i < count; ++i) {
		[qb bindStr:czCols[i] location:i + 1];
	    }


	    myrc = 1;
	}
    }

    return myrc;
}



AV                 *
dbd_st_fetch(sth)
    SV                 *sth;

{
    AV                 *results;
    SV                 *temp;
    int                 i, count;

    D_imp_sth(sth);
    count = DBIc_NUM_FIELDS(imp_sth);

    if ([qb getRow] == 0) {
	results = newAV();
	for (i = 0; i < count; ++i) {
	    czCols[i][255] = '\0';
	    temp = newSVpv(czCols[i], strlen(czCols[i]));
	    av_push(results, temp);
	}

    } else {
	if (DBIc_ACTIVE(imp_sth)) {
	    results = Nullav;
	    DBIc_ACTIVE_off(imp_sth);
	    DBIc_NUM_FIELDS(imp_sth) = 0;
	} else {
	    qb_error(NULL, "No fetch in progress!");
	    results = Nullav;
	}
    }

    return results;
}




int
dbd_st_readblob(sth, field, offset, len, destrv, destoffset)
    SV                 *sth;
    int                 field;
    long                offset;
    long                len;
    SV                 *destrv;
    long                destoffset;
{
    return -1;
}


int
dbd_st_rows(sth)
    SV                 *sth;
{
    return[qb rowsAffected];
}


int
dbd_st_finish(sth)
    SV                 *sth;
{
    D_imp_sth(sth);
    DBIc_ACTIVE_off(imp_sth);

    return 1;
}


void
dbd_st_destroy(sth)
    SV                 *sth;
{
    D_imp_sth(sth);
    if (DBIc_ACTIVE(imp_sth))
	dbd_st_finish(sth);
    DBIc_IMPSET_off(imp_sth);
}


int
dbd_st_STORE(sth, keysv, valuesv)
    SV                 *sth;
    SV                 *keysv;
    SV                 *valuesv;
{
    return FALSE;
}


SV                 *
dbd_st_FETCH(sth, keysv)
    SV                 *sth;
    SV                 *keysv;
{
    return Nullsv;
}

/* --------------------------------------- */
