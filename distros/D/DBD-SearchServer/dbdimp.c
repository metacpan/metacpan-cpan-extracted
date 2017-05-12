/*

  Project	: DBD::SearchServer
  Module/Library: 
  Author	: $Author: shari $
  Revision	: $Revision: 2.19 $
  Check-in date	: $Date: 1999/03/04 14:56:43 $
  Locked by	: $Locker:  $

  $Log: dbdimp.c,v $
  Revision 2.19  1999/03/04 14:56:43  shari
  Nasty bug related to ss_mhic.

  Revision 2.18  1999/03/04 11:37:40  shari
  Removed a long-forgotten useless line.

  Revision 2.17  1999/03/03 15:51:19  shari
  Small details.

  Revision 2.16  1999/03/02 15:31:54  shari
  Ready for prime time?

  Revision 2.15  1999/03/02 15:13:49  shari
  Moved ss_maxhitsinternalcolumns to a db attribute.

  Revision 2.14  1999/03/02 14:04:48  shari
  Compatibility.

  Revision 2.13  1999/03/02 13:54:21  shari
  Global renaming.

  Revision 2.12  1998/12/04 09:57:18  shari
  0.19_03: now honors $sth->{CursorName}. NUM_OF_PARAMS unhandled, DBI takes care of it.

  Revision 2.11  1998/11/24 16:14:54  shari
  Now honors AutoCommit and table_info (for DBI::Shell)

  Revision 2.10  1998/11/23 14:00:21  shari
  Renamed Num_of_params to NUM_OF_PARAMS.

  Revision 2.9  1998/11/11 16:48:36  shari
  Multiple connects; release 0.19

  Revision 2.8  1998/11/11 11:50:38  shari
  Release 0.18.


*/

static char rcsid[]="$Id: dbdimp.c,v 2.19 1999/03/04 14:56:43 shari Exp $ (c) 1996-98, Davide Migliavacca, Milano IT";
#include <stdio.h>
#include "SearchServer.h"

#define EOI(x)  if (x < 0 || x == 100) return (0)
#define NHENV   SQL_NULL_HENV
#define NHDBC   SQL_NULL_HDBC
#define NHSTMT  SQL_NULL_HDBC
#define ERRTYPE(x)	((x < 0) && (x == SQL_ERROR))


DBISTATE_DECLARE;

static SQLCHAR ss_SQLSTATE[6];	       /* SQLSTATE */
static SQLINTEGER ss_SQLCODE;	       /* SQLCODE */

static SQLCHAR ss_data_truncated[6] = "01004";   /* data truncation is controlled via LongTruncOk */

void
dbd_init(dbistate_t *dbistate)
{
    DBIS = dbistate;
}

int
check_error(SV *h, IV rc, char *what)
{
  
  D_imp_xxh(h);
  imp_dbh_t *imp_dbh = NULL;
  imp_sth_t *imp_sth = NULL;
  SQLHENV h_env = SQL_NULL_HENV;
  SQLHDBC h_conn = SQL_NULL_HDBC;
  SQLHSTMT h_stmt = SQL_NULL_HSTMT;


  if (rc == SQL_SUCCESS && dbis->debug < 3)
    return rc;
  
  switch(DBIc_TYPE(imp_xxh)) {
  case DBIt_ST:
    imp_sth = (struct imp_sth_st *)(imp_xxh);
    imp_dbh = (struct imp_dbh_st *)(DBIc_PARENT_COM(imp_sth));
    h_stmt = imp_sth->phstmt;
    break;
  case DBIt_DB:
    imp_dbh = (struct imp_dbh_st *)(imp_xxh);
    break;
  default:
    croak("panic dbd_error on bad handle type");
  }
  h_conn = imp_dbh->hdbc;
  h_env = imp_dbh->henv;
  
  if (rc != SQL_SUCCESS && rc != SQL_NO_DATA_FOUND) {
    if (h_env == NHENV) {
      do_error(h,rc,NHENV,NHDBC,NHSTMT,what);
    }
    else {
      do_error(h,rc,(SQLHENV)h_env,(SQLHDBC)h_conn,(SQLHSTMT)h_stmt,what);
    }
  }
  /* fprintf(DBILOGFP, "<><><> CHECK_ERROR WILL RETURN %d with rc %d\n", (rc == SQL_SUCCESS_WITH_INFO ? SQL_SUCCESS : rc), rc); */
  return((rc == SQL_SUCCESS_WITH_INFO ? SQL_SUCCESS : rc));
}

void
do_error(SV *h, IV rc, SQLHENV h_env, SQLHDBC h_conn, SQLHSTMT h_stmt, 
	 SQLCHAR *what)
{
  D_imp_xxh(h);
  SV *errstr = DBIc_ERRSTR(imp_xxh);
  SV *state  = DBIc_STATE(imp_xxh);
  SQLSMALLINT length;
  SQLCHAR msg[SQL_MAX_MESSAGE_LENGTH+1];
  int msgsize = SQL_MAX_MESSAGE_LENGTH+1;
  
  msg[0]='\0';
  if (h_env != NHENV) {
    SQLError(h_env,h_conn,h_stmt, ss_SQLSTATE, &ss_SQLCODE, msg,
	     msgsize,&length);
    if (dbis->debug >= 3)
      fprintf(DBILOGFP,"SQLSTATE = %s\n",ss_SQLSTATE);
  }
  else {
    strcpy((char *)msg, (char *)what);
  }
  sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);
  sv_setpv(state, (char *)ss_SQLSTATE);
  sv_setpv(errstr, (char*)msg);
  if (what && (h_env == NHENV)) {
    sv_catpv(errstr, " (DBD: ");
    sv_catpv(errstr, (char *)what);
    sv_catpv(errstr, ")");
  }
  DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), errstr);
  if (dbis->debug >= 2)
    fprintf(DBILOGFP, "%s error %d recorded: %s\n",
	    what, rc, SvPV(errstr,na));
}


void
fbh_dump(imp_fbh_t *fbh, int i)
{
  FILE *fp = DBILOGFP;
  fprintf(fp, "fbh %d: '%s' %s, ",
	  i, fbh->cbuf, (fbh->nullok) ? "NULLable" : "");
  fprintf(fp, "type %d,  dbsize %ld, dsize %ld, p%d s%d\n",
	  fbh->dbtype, (long)fbh->dbsize, (long)fbh->dsize,
	  fbh->prec, fbh->scale);
  fprintf(fp, "   out: ftype %d, indp %d, bufl %d, rlen %d, rcode %d\n",
	  fbh->ftype, fbh->indp, fbh->bufl, fbh->rlen, fbh->rcode);
}

static int
dbtype_is_long(int dbtype)
{
  /* Is it a LONG, LONG RAW, LONG VARCHAR or LONG VARRAW type?	*/
  /* Return preferred type code to use if it's a long, else 0.	*/
#if 0
  /* not used by Fulcrum SearchServer */
  if (dbtype == SQL_CLOB || dbtype == SQL_BLOB)	/* LONG or LONG RAW		*/
    return dbtype;			/*		--> same	*/
#endif
  if (dbtype == SQL_LONGVARCHAR)			/* LONG VARCHAR			*/
    return dbtype;			/*		--> LONG	*/
  if (dbtype == SQL_LONGVARBINARY)			/* LONG VARRAW			*/
    return dbtype;			/*		--> LONG RAW	*/
  return 0;
}

static int
dbtype_is_string(int dbtype)	/* 'can we use SvPV to pass buffer?'	*/
{
  switch(dbtype) {
  case SQL_VARCHAR:		/* VARCHAR2	*/
  case SQL_INTEGER:			/* LONG		*/
  case SQL_CHAR:			/* RAW		*/
  case SQL_LONGVARBINARY:	/* LONG RAW	*/
  case SQL_LONGVARCHAR:	/* LONG VARCHAR*/
#if 0 /* not used by SearchServer */
  case SQL_CLOB:			/* Char blob */
#endif
    return 1;
  }
  return 0;
}


/* ================================================================== */


/* ================================================================== */

int
dbd_db_connect(SV *dbh,imp_dbh_t *imp_dbh,SQLCHAR *dbname,SQLCHAR *uid,SQLCHAR *pwd)
{
  D_imp_drh_from_dbh;
  char *msg;
  int ret;
  
  ret = SQLAllocConnect(imp_drh->henv,&imp_dbh->hdbc);
  msg = (ERRTYPE(ret) ? "Connect allocation failed" :
	 "Invalid Handle");
  ret = check_error(dbh,ret,msg);
  if (ret != SQL_SUCCESS) {
    if (imp_drh->connects == 0) {
      SQLFreeEnv(imp_drh->henv);
      imp_drh->henv = NHENV;
    }
  }
  EOI(ret);

  if (dbis->debug >= 2)
    fprintf(DBILOGFP, "connect '%s', '%s', '%s'", dbname, uid, pwd);

  
  ret = SQLConnect(imp_dbh->hdbc,dbname,SQL_NTS,uid,SQL_NTS,pwd,SQL_NTS);
  msg = ( ERRTYPE(ret) ? "Connect failed" : "Invalid handle");
  ret = check_error(dbh,ret,msg);
  if (ret != SQL_SUCCESS) {
    SQLFreeConnect (imp_dbh->hdbc);
    if (imp_drh->connects == 0) {
      SQLFreeEnv(imp_drh->henv);
      imp_drh->henv = NHENV;
    }
  }
  EOI(ret);

  return 1;
}

int
dbd_db_login(SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *user, char *pwd)
{
  D_imp_drh_from_dbh;
  int ret;
  
  char *msg;

  if (!imp_drh->connects) {
    ret = SQLAllocEnv(&imp_drh->henv);
    msg = (imp_drh->henv == NHENV ?
	   "Total Environment allocation failure!" :
	   "Environment allocation failed");
    ret = check_error(dbh,ret,msg);
    EOI(ret);
  }
  imp_dbh->henv = imp_drh->henv;
  ret = dbd_db_connect(dbh,imp_dbh,dbname, user, pwd);
  EOI(ret);
  imp_drh->connects++;
  
  DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now			*/
  DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing	*/
  return 1;
}


int
dbd_db_do(SV *dbh, char *statement)	/* return 1 else 0 on failure	     */
{
  D_imp_dbh(dbh);
  int ret;
  char *msg;
  SQLHSTMT stmt;
  
  ret = SQLAllocStmt(imp_dbh->hdbc,&stmt);
  msg = "Statement allocation error";
  ret = check_error(NULL,ret,msg);
  
  EOI(ret);
  
  ret = SQLExecDirect(stmt,statement,SQL_NTS);
  ret = check_error(NULL,ret,"Execute immediate failed");
  (void)check_error(NULL, SQLFreeStmt(stmt, SQL_DROP),
		    "Statement destruction error");
  EOI(ret);
  
  return 1;
}



int
dbd_db_commit(SV *dbh, imp_dbh_t *imp_dbh)
{
  int ret;
  char *msg;
  
  ret = SQLTransact(imp_dbh->henv,imp_dbh->hdbc,SQL_COMMIT);
  msg = (ERRTYPE(ret)  ? "Commit failed" : "Invalid handle");
  ret = check_error(dbh,ret,msg);
  EOI(ret);
  return 1;
}

int
dbd_db_rollback(SV *dbh, imp_dbh_t *imp_dbh)
{

  return 1; /* Fulcrum SearchServer does not support SQL_ROLLBACK */
  /*    int ret;
	char *msg;
	
	ret = SQLTransact(henv,imp_dbh->hdbc,SQL_ROLLBACK);
	msg = (ERRTYPE(ret)  ? "Rollback failed" : "Invalid handle");
	ret = check_error(dbh,ret,msg);
	EOI(ret);
	
	return 1;
  */
}


int
dbd_db_disconnect(SV *dbh, imp_dbh_t *imp_dbh)
{
  D_imp_drh_from_dbh;
  int ret;
  char *msg;
  
  /* We assume that disconnect will always work	*/
  /* since most errors imply already disconnected.	*/
  DBIc_ACTIVE_off(imp_dbh);
  
  ret = SQLDisconnect(imp_dbh->hdbc);
  msg = (ERRTYPE(ret)  ? "Disconnect failed" : "Invalid handle");
  ret = check_error(dbh,ret,msg);
  EOI(ret);
  
  SQLFreeConnect (imp_dbh->hdbc);
  msg = (ERRTYPE(ret)  ? "FreeConnect failed" : "Invalid handle");
  ret = check_error(dbh,ret,msg);
  EOI(ret);

  imp_dbh->hdbc = SQL_NULL_HDBC;
  imp_drh->connects--;
  if (imp_drh->connects == 0) {
    ret = SQLFreeEnv(imp_drh->henv);
    msg = (ERRTYPE(ret)  ? "FreeEnv failed" : "Invalid handle");
    ret = check_error(dbh,ret,msg);
    EOI(ret);
  }
  

  /* We don't free imp_dbh since a reference still exists	*/
  /* The DESTROY method is the only one to 'free' memory.	*/
  /* Note that statement objects may still exists for this dbh!	*/
  return 1;
}

int
dbd_discon_all(SV *drh, imp_drh_t *imp_drh)
{
  dTHR;
  
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


void
dbd_db_destroy(SV *dbh, imp_dbh_t *imp_dbh)
{
    if (DBIc_ACTIVE(imp_dbh))
      dbd_db_disconnect(dbh, imp_dbh);
    /* Nothing in imp_dbh to be freed	*/
    
    DBIc_IMPSET_off(imp_dbh);
}


int
dbd_db_STORE_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)
{
  STRLEN kl;
  char *key = SvPV(keysv,kl);
  SV *cachesv = NULL;
  int on = SvTRUE(valuesv);
  int ret;
  char *msg;
  
  if (kl==10 && strEQ(key, "AutoCommit")) {
    /* do nothing, not supported by SearchServer,
       BUT honor correct behaviour */
    if (on) {
      DBIc_set(imp_dbh,DBIcf_AutoCommit, on);
    }
    cachesv = &sv_yes;	/* cache new state */
  } else if ((kl == 25 && strEQ(key, "ss_maxhitsinternalcolumns")) ||
	     (kl == 26 && strEQ(key, "ful_maxhitsinternalcolumns"))) {
    imp_dbh->ss_mhic = SvIV(valuesv);
  }  else {
    return FALSE;
  }
  if (cachesv) /* cache value for later DBI 'quick' fetch? */
    hv_store((HV*)SvRV(dbh), key, kl, cachesv, 0);
  return TRUE;
}


SV *
dbd_db_FETCH_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)
{
  STRLEN kl;
  char *key = SvPV(keysv,kl);
  SV *retsv = NULL;
  /* Default to caching results for DBI dispatch quick_FETCH	*/
  int cacheit = TRUE;

  if (kl==10 && strEQ(key, "AutoCommit")) {
    retsv = boolSV(DBIc_has(imp_dbh,DBIcf_AutoCommit));
  } else if ((kl == 25 && strEQ(key, "ss_maxhitsinternalcolumns")) ||
	     (kl == 26 && strEQ(key, "ful_maxhitsinternalcolumns"))) {
    retsv = newSViv( imp_dbh->ss_mhic);
  }
  if (!retsv)
    return Nullsv;

  if (cacheit) {	/* cache for next time (via DBI quick_FETCH)	*/
    SV **svp = hv_fetch((HV*)SvRV(dbh), key, kl, 1);
    sv_free(*svp);
    *svp = retsv;
    (void)SvREFCNT_inc(retsv);	/* so sv_2mortal won't free it	*/
  }
  if (retsv == &sv_yes || retsv == &sv_no)
    return retsv; /* no need to mortalize yes or no */
  return sv_2mortal(retsv);
}



/* ================================================================== */


int
dbd_st_prepare(SV *sth, imp_sth_t *imp_sth, char *statement, SV *attribs)
{
  D_imp_dbh_from_sth;
  int ret =0;
  short params =0;
  char *msg;
  
  imp_sth->done_desc = 0;
  
  ret = SQLAllocStmt(imp_dbh->hdbc,&imp_sth->phstmt);
  msg = "SQLAllocStmt error";
  ret = check_error(sth,ret,msg);
  EOI(ret);
  
  ret = SQLPrepare(imp_sth->phstmt,statement,SQL_NTS);
  msg = "SQLPrepare error";
  ret = check_error(sth,ret,msg);
  
  EOI(ret);
  
  /* ret = SQLSetStmtOption(imp_sth->phstmt, SQL_SS_CAPABLE, SQL_SS_NOTIFYDOCSTAT);
     msg = "SQLSetStmtOption error";
     ret = check_error(sth,ret,msg);
     EOI(ret);
  */
  
  if (dbis->debug >= 5) {
    stmt_dump (imp_sth->phstmt);
  }
  
#if 0
  ret = SQLNumParams(imp_sth->phstmt,&params);
#else
  ret = 0;
  params = 0;
#endif
  
  msg = "Unable to determine number of parameters";
  ret = check_error(sth,ret,msg);
  EOI(ret);
  
  DBIc_NUM_PARAMS(imp_sth) = params;
  
  if (params > 0 ){
    /* scan statement for '?', ':1' and/or ':foo' style placeholders*/	
    dbd_preparse(imp_sth, statement); 
  } else {	/* assuming a parameterless select */
    dbd_describe(sth,imp_sth );
  }
  
  
  
  DBIc_IMPSET_on(imp_sth);
  return 1;
}


void
dbd_preparse(imp_sth_t *imp_sth, SQLCHAR *statement)
{
  bool in_literal = FALSE;
  SQLCHAR *src;
  SQLCHAR *start;
  SQLCHAR *dest;
  phs_t phs_tpl;
  SV *phs_sv;
  int idx=0, style=0, laststyle=0;
  
  /* allocate room for copy of statement with spare capacity	*/
  /* for editing ':1' into ':p1' so we can use obndrv.	*/
  imp_sth->statement = (char*)safemalloc(strlen(statement) + 
					 (DBIc_NUM_PARAMS(imp_sth)*4));
  
  /* initialise phs ready to be cloned per placeholder	*/
  memset(&phs_tpl, '\0',sizeof(phs_tpl));
  phs_tpl.ftype = 1;	/* VARCHAR2 */
  
  src  = statement;
  dest = imp_sth->statement;
  while(*src) {
    if (*src == '\'')
      in_literal = ~in_literal;
    if ((*src != ':' && *src != '?') || in_literal) {
      *dest++ = *src++;
      continue;
    }
    start = dest;			/* save name inc colon	*/ 
    *dest++ = *src++;
    if (*start == '?') {		/* X/Open standard	*/
      sprintf(start,":p%d", ++idx); /* '?' -> ':1' (etc)	*/
      dest = start+strlen(start);
      style = 3;
      
    } else if (isDIGIT(*src)) {	/* ':1'		*/
      idx = atoi(src);
      *dest++ = 'p';		/* ':1'->':p1'	*/
      if (idx > MAX_BIND_VARS || idx <= 0)
	croak("Placeholder :%d index out of range", idx);
      while(isDIGIT(*src))
	*dest++ = *src++;
      style = 1;
      
    } else if (isALNUM(*src)) {	/* ':foo'	*/
      while(isALNUM(*src))	/* includes '_'	*/
	*dest++ = *src++;
      style = 2;
    } else {			/* perhaps ':=' PL/SQL construct */
      continue;
    }
    *dest = '\0';			/* handy for debugging	*/
    if (laststyle && style != laststyle)
      croak("Can't mix placeholder styles (%d/%d)",style,laststyle);
    laststyle = style;
    if (imp_sth->bind_names == NULL)
      imp_sth->bind_names = newHV();
    phs_tpl.sv = &sv_undef;
    phs_sv = newSVpv((char*)&phs_tpl, sizeof(phs_tpl));
    hv_store(imp_sth->bind_names, start, (STRLEN)(dest-start), phs_sv, 0);
    /* warn("bind_names: '%s'\n", start);	*/
  }
  *dest = '\0';
  if (imp_sth->bind_names) {
    DBIc_NUM_PARAMS(imp_sth) = (int)HvKEYS(imp_sth->bind_names);
    if (dbis->debug >= 2)
      fprintf(DBILOGFP, "scanned %d distinct placeholders\n",
	      (int)DBIc_NUM_PARAMS(imp_sth));
  }
}

int
dbd_bind_ph(SV *sth,
	    imp_sth_t *imp_sth,
	    SV *ph_namesv,
	    SV *newvalue,
	    IV sql_type,
	    SV *attribs,
	    int is_inout,
	    IV maxlen)
{
  D_imp_dbh_from_sth;
  SV **svp;
  STRLEN name_len;
  char *name;
  phs_t *phs;
  
  STRLEN value_len;
  void  *value_ptr;
  int ret;
  char *msg;
  short param = SQL_PARAM_INPUT,
    ctype = SQL_C_DEFAULT, stype = SQL_CHAR, scale = 0;
  unsigned prec=0;
  int nullok = SQL_NTS;
  
  if (SvNIOK(ph_namesv) ) {	/* passed as a number	*/
    char buf[90];
    name = buf;
    sprintf(name, ":p%d", (int)SvIV(ph_namesv));
    name_len = strlen(name);
  } else {
    name = SvPV(ph_namesv, name_len);
  }
  
  if (dbis->debug >= 2)
    fprintf(DBILOGFP, "bind %s <== '%s' (attribs: %s)\n",
	    name, SvPV(newvalue,na), SvPV(attribs,na) );
  
  svp = hv_fetch(imp_sth->bind_names, name, name_len, 0);
  if (svp == NULL)
    croak("dbd_bind_ph placeholder '%s' unknown", name);
  phs = (phs_t*)((void*)SvPVX(*svp));		/* placeholder struct	*/
  
  if (phs->sv == &sv_undef) {	 /* first bind for this placeholder	*/
    phs->sv = newSV(0);
    phs->ftype = 1;
  }
  
  if (attribs) {
    /* Setup / Clear attributes as defined by attribs.		*/
    /* If attribs is EMPTY then reset attribs to default.		*/
    /* XXX */
    if ( (svp =hv_fetch((HV*)SvRV(attribs), "Stype",5, 0)) != NULL) 
      stype = phs->ftype = SvIV(*svp);
    if ( (svp=hv_fetch((HV*)SvRV(attribs), "Ctype",5, 0)) != NULL) 
      ctype = SvIV(*svp);
    if ( (svp=hv_fetch((HV*)SvRV(attribs), "Prec",4, 0)) != NULL) 
      prec = SvIV(*svp);
    if ( (svp=hv_fetch((HV*)SvRV(attribs), "Scale",5, 0)) != NULL) 
      scale = SvIV(*svp);
    if ( (svp=hv_fetch((HV*)SvRV(attribs), "Nullok",6, 0)) != NULL) 
      nullok = SvIV(*svp);
    
    
  }	/* else if NULL / UNDEF then don't alter attributes.	*/
  /* This approach allows maximum performance when	*/
  /* rebinding parameters often (for multiple executes).	*/
  
  /* At the moment we always do sv_setsv() and rebind.	*/
  /* Later we may optimise this so that more often we can	*/
  /* just copy the value & length over and not rebind.	*/
  
  if (SvOK(newvalue)) {
    /* XXX need to consider oraperl null vs space issues?	*/
    /* XXX need to consider taking reference to source var	*/
    sv_setsv(phs->sv, newvalue);
    value_ptr = SvPV(phs->sv, value_len);
    phs->indp = 0;
  } else {
    sv_setsv(phs->sv,0); 
    value_ptr = "";
    value_len = 0;
    phs->indp = SQL_NULL_DATA;
  }
  
  if (!nullok && !SvOK(phs->sv)) {
    fprintf(DBILOGFP,"phs->sv is not OK\n");
  }
#if 0
  ret = SQLBindParameter(imp_sth->phstmt,(int)SvIV(ph_namesv),
			 param,ctype,stype,prec,scale,SvPVX(phs->sv),0,(phs->indp != 0 && nullok)?&phs->indp:NULL);
#else
  ret = 0;
#endif
  msg = ( ERRTYPE(ret) ? "Bind failed" : "Invalid Handle");
  ret = check_error(sth,ret,msg);
  EOI(ret);
  
  return 1;
}


int
dbd_describe(SV *h, imp_sth_t *imp_sth)
{
  D_imp_dbh_from_sth;
  SQLCHAR *cbuf_ptr;
  int t_cbufl=0;
  short f_cbufl[MAX_COLS];
  short num_fields;
  int i, ret;
  char *msg;
  SV *svp;

  if (imp_sth->done_desc)
    return 1;	/* success, already done it */
  imp_sth->done_desc = 1;
  
  ret = SQLNumResultCols(imp_sth->phstmt,&num_fields);
  msg = ( ERRTYPE(ret) ? "SQLNumResultCols failed" : "Invalid Handle");
  ret = check_error(h,ret,msg);
  EOI(ret);
  DBIc_NUM_FIELDS(imp_sth) = num_fields;
  
  /* allocate field buffers				*/
  Newz(42, imp_sth->fbh,      num_fields, imp_fbh_t);
  /* allocate a buffer to hold all the column names	*/
  Newz(42, imp_sth->fbh_cbuf,(num_fields * (MAX_COL_NAME_LEN+1)), char);
  cbuf_ptr = (char *)imp_sth->fbh_cbuf;
  
    /* Get number of fields and space needed for field names	*/
  for(i=0; i < num_fields; ++i ) {
    char cbuf[MAX_COL_NAME_LEN];
    char dbtype;
    imp_fbh_t *fbh = &imp_sth->fbh[i];
    f_cbufl[i] = sizeof(cbuf);
    
    
    ret = SQLDescribeCol(imp_sth->phstmt,i+1,cbuf_ptr,MAX_COL_NAME_LEN,
			 &f_cbufl[i],&fbh->dbtype,&fbh->prec,&fbh->scale,&fbh->nullok);
    
    msg	= (ERRTYPE(ret) ? "DescribeCol failed" : "Invalid Handle");
    ret = check_error(h,ret,msg);
    EOI(ret);


    ret = SQLColAttributes(imp_sth->phstmt,
			   i+1,
			   SQL_COLUMN_LENGTH,
			   NULL,
			   0,
			   NULL ,
			   (SDWORD FAR *)&fbh->dbsize);
    msg	= (ERRTYPE(ret) ? "ColAttributes failed" : "Invalid Handle");
    ret = check_error(h,ret,msg);
    EOI(ret);
    
    ret = SQLColAttributes(imp_sth->phstmt,i+1,SQL_COLUMN_DISPLAY_SIZE,
			   NULL, 0, NULL ,(SDWORD FAR *)&fbh->dsize);
    msg	= (ERRTYPE(ret) ? "ColAttributes failed" : "Invalid Handle");
    ret = check_error(h,ret,msg);
    EOI(ret);
    
    /* SHARI 
       fprintf(DBILOGFP, "Describe: \"%s\" of size %i\n", cbuf_ptr, fbh->dbsize);
       SHARI */
    
    fbh->imp_sth = imp_sth;
    fbh->cbuf    = cbuf_ptr;
    fbh->cbufl   = f_cbufl[i];
    fbh->cbuf[fbh->cbufl] = '\0';	 /* ensure null terminated	*/
    cbuf_ptr += fbh->cbufl + 1;	 /* increment name pointer	*/
    
    /* Now define the storage for this field data.			*/
    
    fbh->ftype = SQL_C_CHAR ;
    fbh->rlen = fbh->bufl  = fbh->dsize+1;/* +1: STRING null terminator	*/
    /* If DBD::SearchServer::ss_maxhitsinternalcolumns is set, add space for 7 * 2 * its value bytes
       to account for match start/end codes */
    /* if fbh->bufl is 0 we should keep the value (apvarchar columns) */
    if (imp_dbh->ss_mhic > 0) {
      int newlen = (fbh->bufl ? (fbh->bufl + (imp_dbh->ss_mhic * 14)) : 0);
      if (dbis->debug > 7)
	fprintf(DBILOGFP, "[ss_mhic expanding buffer from %d to %d]",
		fbh->bufl,
		newlen
		);
      fbh->rlen = fbh->bufl = newlen;
    }

    /* currently we use an sv, later we'll use an array	*/
    fbh->sv = newSV((STRLEN)fbh->bufl);
    (void)SvUPGRADE(fbh->sv, SVt_PV);
    SvREADONLY_on(fbh->sv);
    (void)SvPOK_only(fbh->sv);
    fbh->buf = (char *)SvPVX(fbh->sv);
    
    /* BIND */
    ret = SQLBindCol(imp_sth->phstmt,
		     i+1,
		     SQL_C_CHAR,
		     fbh->buf,
		     fbh->bufl,
		     (SDWORD FAR *)&fbh->rlen);
    if (ret == SQL_SUCCESS_WITH_INFO ) {
      warn("BindCol error on %s: %d", fbh->cbuf);
    } else {
      msg = (ERRTYPE(ret) ? "BindCol failed" : "Invalid Handle");
      ret = check_error(h,ret,msg);
      EOI(ret);
    }
    
    if (dbis->debug >= 2)
      fbh_dump(fbh, i);
  }
  return 1;
}

int
dbd_st_execute(SV *sth, imp_sth_t *imp_sth)
{
  D_imp_dbh_from_sth;
  char *msg;
  int ret ;
 
  /* describe and allocate storage for results		*/
  if (!imp_sth->done_desc && !dbd_describe(sth, imp_sth)) {
    /* dbd_describe has already called check_error()		*/
    return 0;
  }
  ret = SQLExecute(imp_sth->phstmt);
  msg = "SQLExecute failed";
  ret = check_error(sth,ret,msg);
  EOI(ret);
  
  if (DBIc_NUM_FIELDS(imp_sth) > 0) {  	/* is a SELECT	*/
    DBIc_ACTIVE_on(imp_sth);
  }
  else {
    /* assume CRUD, get last row's FT_CID */
    SQLGetStmtOption (imp_sth->phstmt, SQL_SS_ROW_ID, (PTR *)&imp_sth->ss_last_row_id);
  }
  
  return 1;
}



AV *
dbd_st_fetch(SV *sth, imp_sth_t *imp_sth)
{
  D_imp_dbh_from_sth;
  int debug = dbis->debug;
  int num_fields;
  int i,ret;
  AV *av;
  char *msg;
  int data_truncated_detected = 0;
  int data_truncated = 0;
  
  
  /* Check that execute() was executed sucessfuly. This also implies	*/
  /* that dbd_describe() executed sucessfuly so the memory buffers	*/
  /* are allocated and bound.						*/
  if ( !DBIc_ACTIVE(imp_sth) ) {
    check_error(sth, -3 , "no statement executing (perhaps you need to call execute first)");
    return Nullav;
  }
  
  if ((ret = SQLFetch(imp_sth->phstmt)) != SQL_SUCCESS ) {
    if (ret != SQL_NO_DATA_FOUND) {	/* was not just end-of-fetch	*/
      msg = (ERRTYPE(ret) ? "Fetch failed" : "Invalid Handle");
      ret = check_error(sth,ret,msg);
      if (ret == SQL_SUCCESS && strEQ(SvPV(DBIc_STATE(imp_sth),na), ss_data_truncated)) {
	/* check_error transforms SQL_SUCCESS_WITH_INFO in SQL_SUCCESS */
	data_truncated_detected = 1;
      }
      else {
	return Nullav;
      }
      
      if (debug >= 3)
	fprintf(DBILOGFP, "    dbd_st_fetch failed, rc=%d,",ret);
    }
    else
      return Nullav;
  }
  
  av = DBIS->get_fbav(imp_sth);
  num_fields = AvFILL(av)+1;
  
  if (debug >= 3)
    fprintf(DBILOGFP, "    dbd_st_fetch %d fields\n", num_fields);
  
  for(i=0; i < num_fields; ++i) {
    imp_fbh_t *fbh = &imp_sth->fbh[i];
    SV *sv = AvARRAY(av)[i]; /* Note: we reuse the supplied SV	*/

    data_truncated = 0;

    if (fbh->rlen > -1) {	/* normal case - column is not null */
      if (fbh->rlen > fbh->bufl) {
	data_truncated = 1; /* should the previous check miss... pg 2-9 C Dev Ref */
	sv_setpvn(sv, fbh->buf, fbh->bufl); /* not null-terminated when trunc! */
      }
      else {
	/*SvCUR_set(fbh->sv, fbh->rlen);*/
	sv_setpvn(sv,fbh->buf, fbh->rlen);
      }
    }
    else {				/*  column contains a null value */
      /* fbh->indp = fbh->rlen; 
      fbh->rlen = 0; */
      (void)SvOK_off(sv);
    } 
    if (debug >= 2)
      fprintf(DBILOGFP, "\t%d: rc=%d '%s' (bufl: %d rlen: %d trunc: %d)\n", i, ret, SvPV(sv,na), fbh->bufl, fbh->rlen, data_truncated);
  }
  if (debug >= 2 && (data_truncated ^ data_truncated_detected))
    fprintf(DBILOGFP, "\tWarning: no truncated field detected but 01004\n");
    
  return av;
}

int
dbd_st_blob_read(SV *sth,
		 imp_sth_t *imp_sth,
		 int field,
		 long offset,
		 long len,
		 SV *destrv,
		 long destoffset)
{
  D_imp_dbh_from_sth;
  int retl=0;
  SV *bufsv;
  int rtval=0;
  char *msg;
  
  bufsv = SvRV(destrv);
  sv_setpvn(bufsv,"",0);	/* ensure it's writable string	*/
  SvGROW(bufsv, len+destoffset+1);	/* SvGROW doesn't do +1	*/
  
  rtval = SQLGetData(imp_sth->phstmt,
		     field,
		     SQL_C_DEFAULT,
		     SvPVX(bufsv),
		     len+destoffset,
		     (SDWORD FAR *)&retl);
  msg = (ERRTYPE(rtval) ? "GetData failed to read blob":"Invalid Handle");
  rtval = check_error(sth,rtval,msg);
  EOI(rtval);
  
  SvCUR_set(bufsv, len );
  *SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc	*/
  
  return 1;
}


int
dbd_st_rows(SV *sth,imp_sth_t *imp_sth)
{
    D_imp_dbh_from_sth;
    int rows, ret;
    char *msg;
    
    ret = SQLRowCount(imp_sth->phstmt,(SDWORD FAR *)&rows);
    msg = (ERRTYPE(ret) ? "SQLRowCount failed" : "Invalid Handle");
    ret = check_error(sth,ret,msg);
    EOI(ret);
    return(rows);
}


int
dbd_st_finish(SV *sth, imp_sth_t *imp_sth)
{
  D_imp_dbh_from_sth;
  int ret;
  char *msg;

  if (DBIc_ACTIVE(imp_sth)) {
    /*ret = SQLCancel(imp_sth->phstmt);*/
    ret = SQLFreeStmt(imp_sth->phstmt, SQL_CLOSE);
    msg = (ERRTYPE(ret) ? "SQLCancel failed" : "Invalid Handle");
  }
  DBIc_ACTIVE_off(imp_sth);
  return 1;
}


void
dbd_st_destroy(SV *sth, imp_sth_t *imp_sth)
{
  D_imp_dbh_from_sth;
  int i;
  /* Check if an explicit disconnect() or global destruction has	*/
  /* disconnected us from the database before attempting to close.	*/

  if (DBIc_ACTIVE(imp_dbh)) {
    
  }
  /* Free off contents of imp_sth	*/
  
  for(i=0; i < DBIc_NUM_FIELDS(imp_sth); ++i) {
    imp_fbh_t *fbh = &imp_sth->fbh[i];
    sv_free(fbh->sv);
  }
  Safefree(imp_sth->fbh);
  Safefree(imp_sth->fbh_cbuf);
  Safefree(imp_sth->statement);
  
  if (imp_sth->bind_names) {
    HV *hv = imp_sth->bind_names;
    SV *sv;
    char *key;
    I32 retlen;
    hv_iterinit(hv);
    while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
      phs_t *phs_tpl;
      if (sv != &sv_undef) {
	phs_tpl = (phs_t*)SvPVX(sv);
	sv_free(phs_tpl->sv);
      }
    }
    sv_free((SV*)imp_sth->bind_names);
  }
  i = SQLFreeStmt (imp_sth->phstmt, SQL_DROP);
  if (i != SQL_SUCCESS && i != SQL_INVALID_HANDLE) {
    check_error(NULL,i, "Statement destruction error");
  }
  /* End Chet */
  DBIc_IMPSET_off(imp_sth);		/* let DBI know we've done it	*/
}


int
dbd_st_STORE_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)
{
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    SV *cachesv = NULL;
    int on = SvTRUE(valuesv);
    
    if (kl==4 && strEQ(key, "long")) {
      imp_sth->long_buflen = SvIV(valuesv);
      
    } else if (kl==5 && strEQ(key, "trunc")) {
      imp_sth->long_trunc_ok = on;
      
    } else {
      return FALSE;
    }
    if (cachesv) /* cache value for later DBI 'quick' fetch? */
      hv_store((HV*)SvRV(sth), key, kl, cachesv, 0);
    return TRUE;
}


SV *
dbd_st_FETCH_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv)
{
  STRLEN kl;
  char *key = SvPV(keysv,kl);
  int i;
  SV *retsv = NULL;
  /* Default to caching results for DBI dispatch quick_FETCH	*/
  int cacheit = TRUE;

  if (kl==13 && strEQ(key, "NUM_OF_PARAMS")) {
    return Nullsv;	/* handled by DBI */
  } 
  
  if (!imp_sth->done_desc && !dbd_describe(sth, imp_sth)) {
    /* dbd_describe has already called ora_error()		*/
    return Nullsv;	/* XXX not quite the right thing to do?	*/
  }
  
  i = DBIc_NUM_FIELDS(imp_sth);
  
  if (kl == 7 && strEQ(key, "lengths")) {
    AV *av = newAV();
    retsv = newRV(sv_2mortal((SV*)av));
    while(--i >= 0)
      av_store(av, i, newSViv((IV)imp_sth->fbh[i].dsize));
  } else if (kl == 4 && strEQ(key, "TYPE")) {
    AV *av = newAV();
    retsv = newRV(sv_2mortal((SV*)av));
    while(--i >= 0)
      av_store(av, i, newSViv(imp_sth->fbh[i].dbtype));
  } else if (kl == 5 && strEQ(key, "SCALE")) {
    AV *av = newAV();
    retsv = newRV(sv_2mortal((SV*)av));
    while(--i >= 0)
      av_store(av, i, newSViv(imp_sth->fbh[i].scale));
  } else if (kl == 9 && strEQ(key, "PRECISION")) {
    AV *av = newAV();
    retsv = newRV(sv_2mortal((SV*)av));
    while(--i >= 0)
      av_store(av, i, newSViv(imp_sth->fbh[i].prec));
  } else if (kl==8 && strEQ(key, "NULLABLE")) {
    AV *av = newAV();
    retsv = newRV(sv_2mortal((SV*)av));
    while(--i >= 0)
      av_store(av, i, boolSV(imp_sth->fbh[i].nullok));
  } else if ((kl == 14 && strEQ(key, "ss_last_row_id")) ||
	     (kl == 15 && strEQ(key, "ful_last_row_id"))
	     ) {  /* compatibility with DBD::Fulcrum */
    /* thanks to Loic Dachary for this... */
    retsv = newSViv( imp_sth->ss_last_row_id );
    cacheit = FALSE; /* don't let row ids be cached... */
  } else if (kl == 4 && strEQ(key, "NAME")) {
    AV *av = newAV();
    retsv = newRV((SV*)av);
    while(--i >= 0)
      av_store(av, i, newSVpv((char*)imp_sth->fbh[i].cbuf,0));
    
  } else if (kl == 10 && strEQ(key, "CursorName")) {
    /* Thanks to Peter Wyngaard for this ... */
    char cursor_name[SQL_MAX_CURSOR_NAME_LEN + 1];
    if (SQLGetCursorName (imp_sth->phstmt,
			  cursor_name,
			  SQL_MAX_CURSOR_NAME_LEN,
			  NULL)
	== SQL_SUCCESS)
      retsv = newSVpv (cursor_name, 0);
    else
      retsv = Nullsv;
  }
  else {
    return Nullsv;
  }

  if (cacheit) { /* cache for next time (via DBI quick_FETCH)	*/
    SV **svp = hv_fetch((HV*)SvRV(sth), key, kl, 1);
    sv_free(*svp);
    *svp = retsv;
    (void)SvREFCNT_inc(retsv);	/* so sv_2mortal won't free it	*/
  }
  return sv_2mortal(retsv);
}



void
stmt_dump(SQLHSTMT hstmt)
{
  FILE *fp = DBILOGFP;
  I32 outopt;
  
  
  
  fprintf(fp, "SearchServer-specific Options for stmt hndl: '%x'\n\t", hstmt);
  
  SQLGetStmtOption(hstmt, SQL_CONCURRENCY, &outopt);
  fprintf(fp, "SQL_CONCURRENCY: %x, ", outopt);
  SQLGetStmtOption(hstmt, SQL_CURSOR_TYPE, &outopt);
  fprintf(fp, "SQL_CURSOR_TYPE: %x, ", outopt);
  SQLGetStmtOption(hstmt, SQL_MAX_ROWS, &outopt);
  fprintf(fp, "SQL_MAX_ROWS: %x, ", outopt);
  SQLGetStmtOption(hstmt, SQL_QUERY_TIMEOUT, &outopt);
  fprintf(fp, "SQL_QUERY_TIMEOUT: %x, ", outopt);
  SQLGetStmtOption(hstmt, SQL_ROWSET_SIZE, &outopt);
  fprintf(fp, "SQL_ROWSET_SIZE: %x, ", outopt);
  SQLGetStmtOption(hstmt, SQL_SS_CAPABLE, &outopt);
  fprintf(fp, "\n\tSQL_SS_CAPABLE: %x ", outopt);
  if (outopt & SQL_SS_KEEPRESULT) fprintf(fp, "keepresult, ");
  if (outopt & SQL_SS_NOTIFYMAXROWS) fprintf(fp, "notifymaxrows, ");
  if (outopt & SQL_SS_NOTIFYTIMEOUT) fprintf(fp, "notifytimeout, ");
  if (outopt & SQL_SS_NOTIFYNOROWS) fprintf(fp, "notifynorows, ");
  if (outopt & SQL_SS_NOTIFYDOCSTAT) fprintf(fp, "notifydocstat, ");
  SQLGetStmtOption(hstmt, SQL_SS_SHOW_MATCHES, &outopt);
  fprintf(fp,"\n\tSQL_SS_SHOW_MATCHES: %x, ", outopt);
  SQLGetStmtOption(hstmt, SQL_SS_SHOW_SGR, &outopt);
  fprintf(fp,"SQL_SS_SHOW_SGR: %x", outopt);
  SQLGetStmtOption(hstmt, SQL_SS_ROW_ID, &outopt);
  fprintf(fp, "\n\tSQL_SS_ROW_ID: %x ", outopt);
  
  fprintf(fp,"\n");
  
  
}



/* --------------------------------------- */

