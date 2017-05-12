/*---------------------------------------------------------
 *
 * Portions Copyright (c) 1994,1995,1996,1997 Tim Bunce
 * Portions Copyright (c) 1997                Edmund Mergl
 * Portions Copyright (c) 1997                Göran Thyni
 *
 *---------------------------------------------------------
 */

#include "Informix4.h"

#include <string.h>


#define I4DEBUG 0

dbistate_t *dbis;

static SV *dbd_pad_empty;

static char* gDatabase;

#define MAXCURS 5
static _SQCURSOR _SQ[MAXCURS];
static struct sqlda *udesc[MAXCURS];
static int cursbusy[MAXCURS] = {0,0,0,0,0};

void
dbd_init(dbistate)
    dbistate_t *dbistate;
{
    DBIS = dbistate;
    sqlca.sqlcode = 0;
    if (getenv("DBD_PAD_EMPTY"))
	sv_setiv(dbd_pad_empty, atoi(getenv("DBD_PAD_EMPTY")));
}

int dbd_error(SV * h, int rc)
{
  D_imp_xxh(h);
  char errbuf[256], fmtbuf[256];
#if I4DEBUG
  fprintf(stderr, "dbd_error: %d, %s\n", error_num);
#endif
  if (rc < 0)
    {
      /* Format SQL (primary) error */
      if (rgetmsg(rc, errbuf, sizeof(errbuf)) != 0)
	strcpy(errbuf, "<<Failed to locate SQL error message>>");
      sprintf(fmtbuf, errbuf, sqlca.sqlerrm);
      sprintf(errbuf, "SQL: %ld: %s", rc, fmtbuf);
      sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);	/* set err early */
      sv_setpv(DBIc_ERRSTR(imp_xxh), errbuf);
      return 0;
    }
  return 1;
}

int dbd_error2(SV * h, int rc, char* sa)
{
  D_imp_xxh(h);
#if I4DEBUG
  fprintf(stderr, "dbd_error2: %d, %s\n", error_num);
#endif
  if (rc < 0)
    {
      sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);	/* set err early */
      sv_setpv(DBIc_ERRSTR(imp_xxh), sa);
      return 0;
    }
  return 1;
}


/* ================================================================== */

int
dbd_db_login(dbh, imp_dbh, dbname, uid, pwd)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
    char *dbname;
    char *uid;
    char *pwd;
{
    char *conn_str;
#if I4DEBUG
    fprintf(stderr, "dbd_db_login\n");
#endif
    /* make a connection to the database */
    {
      static struct sqlvar_struct _sqibind[] = 
      {
	{100, 0, NULL, NULL, NULL, NULL, 0, 0, NULL},
	
      };
      _sqibind[0].sqldata = (dbname);
      _iqdatabase("?", 0, 1, _sqibind);
    }
    /* check to see that the backend connection was successfully made */
    if (sqlca.sqlcode != 0)
      {
	return dbd_error(dbh, sqlca.sqlcode); 
      }
    gDatabase = dbname;
    DBIc_IMPSET_on(imp_dbh);	/* imp_dbh set up now			*/
    DBIc_ACTIVE_on(imp_dbh);	/* call disconnect before freeing	*/
    return 1;
}


int
dbd_db_do(dbh, imp_dbh, statement, attribs)
    SV * dbh;
    struct imp_dbh_st* imp_dbh;
    char * statement;
    SV * attribs;
{
#if I4DEBUG
  fprintf(stderr, "dbd_db_do\n");
#endif
  _iqeximm(statement);
  if (sqlca.sqlcode != 0)
    {
      return dbd_error(dbh, sqlca.sqlcode);
    }	
  return 1;
}


int
dbd_db_commit(dbh, imp_dbh)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
{
  _iqcommit();
  if (sqlca.sqlcode != 0)
    {
      return dbd_error(dbh, sqlca.sqlcode);
    }	
  return 1;
}

int
dbd_db_rollback(dbh, imp_dbh)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
{
  _iqrollback();
  if (sqlca.sqlcode != 0)
    {
      return dbd_error(dbh, sqlca.sqlcode);
    }	
  return 1;
}


int
dbd_db_disconnect(dbh, imp_dbh)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
{
  /* We assume that disconnect will always work	*/
  /* since most errors imply already disconnected.	*/
  DBIc_ACTIVE_off(imp_dbh);
  _iqdbclose();
  /* We don't free imp_dbh since a reference still exists	*/
  /* The DESTROY method is the only one to 'free' memory.	*/
  /* Note that statement objects may still exists for this dbh!	*/
  return 1;
}

int dbd_discon_all(drh, imp_drh)
{
  _iqdbclose();
  /* We don't free imp_dbh since a reference still exists	*/
  /* The DESTROY method is the only one to 'free' memory.	*/
  /* Note that statement objects may still exists for this dbh!	*/
  return 1;
}



void
dbd_db_destroy(dbh, imp_dbh)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
{
    if (DBIc_ACTIVE(imp_dbh)) {
	dbd_db_disconnect(dbh, imp_dbh);
    }

#if I4DEBUG
    fprintf(stderr, "destroy database handle\n");
#endif

    /* Nothing in imp_dbh to be freed	*/
    DBIc_IMPSET_off(imp_dbh);
}


int
dbd_db_STORE(dbh, imp_dbh, keysv, valuesv)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
    SV *keysv;
    SV *valuesv;
{
  return dbd_db_STORE_attrib(dbh, imp_dbh, keysv, valuesv);
}

int
dbd_db_STORE_attrib(dbh, imp_dbh, keysv, valuesv)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
    SV *keysv;
    SV *valuesv;
{
    return FALSE;
}


SV *
dbd_db_FETCH(dbh, imp_dbh, keysv)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
    SV *keysv;
{
    return dbd_db_FETCH_attrib(dbh, imp_dbh, keysv);
}

SV *
dbd_db_FETCH_attrib(dbh, imp_dbh, keysv)
    SV *dbh;
    struct imp_dbh_st* imp_dbh;
    SV *keysv;
{
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    SV *retsv = NULL;
    return Nullsv;
}

/* ================================================================== */


int
dbd_st_prepare(sth, imp_sth, statement, attribs)
    SV *sth;
    struct imp_sth_st* imp_sth;
    char *statement;
    SV *attribs;
{
#if I4DEBUG
    fprintf(stderr, "dbd_st_prepare\n");
#endif

    /* initialize new statement handle */

    imp_sth->execd    = 0;
    imp_sth->n_rows = 0;

    DBIc_IMPSET_on(imp_sth);
    return 1;
}


static int 
_dbd_rebind_ph(sth, imp_sth, phs) 
    SV *sth;
    imp_sth_t *imp_sth;
    phs_t *phs;
{
    STRLEN value_len;

/*	for strings, must be a PV first for ptr to be valid? */
/*    sv_insert +4	*/
/*    sv_chop(phs->sv, SvPV(phs->sv,na)+4);	XXX */

    if (dbis->debug >= 2) {
	char *text = neatsvpv(phs->sv,0);
	fprintf(DBILOGFP, "bind %s <== %s (size %d/%d/%ld, ptype %ld, otype %d)\n",
	    phs->name, text, SvCUR(phs->sv),SvLEN(phs->sv),phs->maxlen,
	    SvTYPE(phs->sv), phs->ftype);
    }

    /* At the moment we always do sv_setsv() and rebind.	*/
    /* Later we may optimise this so that more often we can	*/
    /* just copy the value & length over and not rebind.	*/

    if (phs->is_inout) {	/* XXX */
	if (SvREADONLY(phs->sv))
	    croak(no_modify);
	/* phs->sv _is_ the real live variable, it may 'mutate' later	*/
	/* pre-upgrade high to reduce risk of SvPVX realloc/move	*/
	(void)SvUPGRADE(phs->sv, SVt_PVNV);
	/* ensure room for result, 28 is magic number (see sv_2pv)	*/
	SvGROW(phs->sv, (phs->maxlen < 28) ? 28 : phs->maxlen+1);
	if (imp_sth->dbd_pad_empty)
	    croak("Can't use dbd_pad_empty with bind_param_inout");
    }
    else {
	/* phs->sv is copy of real variable, upgrade to at least string	*/
	(void)SvUPGRADE(phs->sv, SVt_PV);
    }

    /* At this point phs->sv must be at least a PV with a valid buffer,	*/
    /* even if it's undef (null)					*/
    /* Here we set phs->progv, phs->indp, and value_len.		*/
    if (SvOK(phs->sv)) {
	phs->progv = SvPV(phs->sv, value_len);
	phs->indp  = 0;
    }
    else {	/* it's null but point to buffer incase it's an out var	*/
	phs->progv = SvPVX(phs->sv);
	phs->indp  = -1;
	value_len  = 0;
    }
    if (imp_sth->dbd_pad_empty && value_len==0) {
	sv_setpv(phs->sv, " ");
	phs->progv = SvPV(phs->sv, value_len);
    }
    phs->sv_type = SvTYPE(phs->sv);	/* part of mutation check	*/
    phs->alen    = value_len + phs->alen_incnull;
    phs->maxlen  = SvLEN(phs->sv)-1;	/* avail buffer space	*/

    return 1;
}


int
dbd_bind_ph(sth, imp_sth, ph_namesv, newvalue, sql_type, 
	    attribs, is_inout, maxlen)
    SV *sth;
    struct imp_sth_st* imp_sth;
    SV *ph_namesv;
    SV *newvalue;
    IV sql_type;
    SV *attribs;
    int is_inout;
    IV maxlen;
{
    SV **phs_svp;
    STRLEN name_len;
    char *name;
    char namebuf[30];
    phs_t *phs;

    /* check if placeholder was passed as a number	*/
    if (SvNIOK(ph_namesv) || (SvPOK(ph_namesv) && isDIGIT(*SvPVX(ph_namesv)))) {
	name = namebuf;
	sprintf(name, ":p%d", (int)SvIV(ph_namesv));
	name_len = strlen(name);
    }
    else {		/* use the supplied placeholder name directly */
	name = SvPV(ph_namesv, name_len);
    }

    if (SvTYPE(newvalue) > SVt_PVMG)	/* hook for later array logic	*/
	croak("Can't bind non-scalar value (currently)");

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "bind %s <== %s (attribs: %s)\n",
		name, neatsvpv(newvalue,0), attribs ? SvPV(attribs,na) : "" );

    phs_svp = hv_fetch(imp_sth->all_params_hv, name, name_len, 0);
    if (phs_svp == NULL)
	croak("Can't bind unknown placeholder '%s'", name);
    phs = (phs_t*)(void*)SvPVX(*phs_svp);	/* placeholder struct	*/

    if (phs->sv == &sv_undef) {	/* first bind for this placeholder	*/
	phs->ftype    = 1;		/* our default type VARCHAR2	*/
	phs->maxlen   = maxlen;		/* 0 if not inout		*/
	phs->is_inout = is_inout;
	if (is_inout) {
	    phs->sv = SvREFCNT_inc(newvalue);	/* point to live var	*/
	    ++imp_sth->has_inout_params;
	    /* build array of phs's so we can deal with out vars fast	*/
	    if (!imp_sth->out_params_av)
		imp_sth->out_params_av = newAV();
	    av_push(imp_sth->out_params_av, SvREFCNT_inc(*phs_svp));
	}
    }
	/* check later rebinds for any changes */
    else if (is_inout || phs->is_inout) {
	croak("Can't rebind or change param %s in/out mode after first bind", phs->name);
    }
    else if (maxlen && maxlen != phs->maxlen) {
	croak("Can't change param %s maxlen (%ld->%ld) after first bind",
			phs->name, phs->maxlen, maxlen);
    }

    if (!is_inout) {	/* normal bind to take a (new) copy of current value	*/
	if (phs->sv == &sv_undef)	/* (first time bind) */
	    phs->sv = newSV(0);
	sv_setsv(phs->sv, newvalue);
    }

    return _dbd_rebind_ph(sth, imp_sth, phs);
}


/* <= -2:error, >=0:ok row count, (-1=unknown count) */

int
dbd_st_execute(sth, imp_sth)
    SV *sth;
    struct imp_sth_st* imp_sth;
{
  D_imp_dbh_from_sth;
  /*    ExecStatusType status = -1; */
  int i, pos;
  char* cp;
  struct sqlvar_struct *col;
  int ret = -2;
  SV** svp = hv_fetch((HV *)SvRV(sth), "Statement", 9, FALSE);
  char *statement = SvPV(*svp, na);
#if I4DEBUG
  fprintf(stderr, "dbd_st_execute\n");
#endif
  for (i = 0; i < MAXCURS; i++)
    if (!cursbusy[i])
      {
	cursbusy[i] = 1;
	imp_sth->index = i;
	break;
      }
  _iqprepare(&_SQ[imp_sth->index], statement);
  if (sqlca.sqlcode != 0)
    return dbd_error(sth, sqlca.sqlcode);
  _iqdscribe(&_SQ[imp_sth->index], &udesc[imp_sth->index]);
  if (sqlca.sqlcode != 0)
    return dbd_error(sth, sqlca.sqlcode);
#if I4DEBUG
  fprintf(stderr, "dbd_st_execute 2\n");
#endif
  /* STEP 1 */
  pos = 0;
  for (col = udesc[imp_sth->index]->sqlvar, i = 0;
       i < udesc[imp_sth->index]->sqld; col++, i++)
    {
      switch (col->sqltype)
	{
	case SQLCHAR:
	  col->sqltype = CCHARTYPE;
	  break;
	case SQLSMINT:
	  col->sqltype = CSHORTTYPE;
	  break;
	case SQLINT:
	  col->sqltype = CINTTYPE;
	  break;
	case SQLSMFLOAT:
	  col->sqltype = CFLOATTYPE;
	  break;
	case SQLFLOAT:
	  col->sqltype = CDOUBLETYPE;
	  break;
	case SQLMONEY:
	case SQLDECIMAL:
	  col->sqltype = CDECIMALTYPE;
	  break;
	default:
	  {
	    char str[100];
	    sprintf(str, "unknown type: %d\n", col->sqltype);
	    return dbd_error2(sth, -1, str);
	  }
	}
      col->sqllen = rtypmsize(col->sqltype, col->sqllen);
      pos = rtypalign(pos, col->sqltype) + col->sqllen;
      col->sqlind = NULL;
    }
  DBIc_NUM_FIELDS(imp_sth) = udesc[imp_sth->index]->sqld;
  /* STEP 3 */
  cp = malloc(pos);
  for (col = udesc[imp_sth->index]->sqlvar, i = 0; 
       i < udesc[imp_sth->index]->sqld; col++, i++)
    {
      cp = col->sqldata = rtypalign(cp, col->sqltype);
      cp += col->sqllen;
    }
  {
    char cstr[20];
    sprintf(cstr, "usqlcurs%d", imp_sth->index);
    _iqddclcur(_SQ[imp_sth->index], cstr, 0);
    if (sqlca.sqlcode != 0)
      return dbd_error(sth, sqlca.sqlcode);
  }
  _iqcopen(&_SQ[imp_sth->index], 0, NULL, NULL, NULL, 0);
  if (sqlca.sqlcode != 0)
    return dbd_error(sth, sqlca.sqlcode);
#if 0
  imp_sth->n_rows = sqlca.sqlerrd[2];
#endif
  imp_sth->execd = 1;
  DBIc_ACTIVE_on(imp_sth);
  return dbd_st_rows(sth, imp_sth);
}



#define FLDSIZE 40

AV *
dbd_st_fetch(sth, imp_sth)
    SV *	sth;
    struct imp_sth_st* imp_sth;
{
  D_imp_dbh_from_sth;
  int num_fields;
  int ChopBlanks;
  int i, j;
  AV *av;
  struct sqlvar_struct *col;
#if I4DEBUG
  fprintf(stderr, "dbd_st_fetch\n");
#endif
  /* Check that execute() was executed sucessfully */
  if ( !DBIc_ACTIVE(imp_sth) ) 
    {
      dbd_error2(sth, -1, "no statement executing\n");
      return Nullav;
    }
  ChopBlanks = DBIc_has(imp_sth, DBIcf_ChopBlanks);
  _iqnftch(&_SQ[imp_sth->index], 0, NULL, udesc[imp_sth->index],
	   1, 0L, 0, NULL, NULL, 0);
  if (sqlca.sqlcode != 0)
    {
      dbd_error(sth, sqlca.sqlcode);
      return Nullav;
    }
  av = DBIS->get_fbav(imp_sth);
  num_fields = AvFILL(av)+1;
  for(i = 0, col = udesc[imp_sth->index]->sqlvar; i < num_fields; ++i, col++) 
    {
      char field[FLDSIZE];
      SV *sv = AvARRAY(av)[i];
      switch (col->sqltype)
	{
	case CCHARTYPE:
	  sv_setpv(sv, col->sqldata);
	  if (ChopBlanks) 
	    {
	      char *p = SvEND(sv);
	      int len = SvCUR(sv);
	      while(len && *--p == ' ') --len;
	      if (len != SvCUR(sv)) 
		{
		  SvCUR_set(sv, len);
		  *SvEND(sv) = '\0';
		}
	    }
	  continue;
	case CSHORTTYPE:
	  sprintf(field, "%hd", *((short*) (col->sqldata)));
	  break;
	case CINTTYPE:
	  sprintf(field, "%d", *((int*) (col->sqldata)));
	  break;
	case CFLOATTYPE:
	  sprintf(field, "%f", (double) *((float*) (col->sqldata)));
	  break;
	case CDOUBLETYPE:
	  sprintf(field, "%f", *((double*) (col->sqldata)));
	  break;
	case CDECIMALTYPE:
	  dectoasc(col->sqldata, field, FLDSIZE, -1);
	  break;
	default:
	  printf("unknown type 2: %d\n", col->sqltype);
	  return;
	}
      sv_setpv(sv, field);
    }
  imp_sth->n_rows++;
  return av;
}


int
dbd_st_rows(sth, imp_sth)
    SV *sth;
    struct imp_sth_st* imp_sth;
{
  return imp_sth->n_rows ? imp_sth->n_rows : 1;
}


int
dbd_st_finish(sth, imp_sth)
    SV *sth;
    struct imp_sth_st* imp_sth;
{
#if I4DEBUG
  fprintf(stderr, "dbd_st_finish\n");
#endif
  if (cursbusy[imp_sth->index])
    {
      cursbusy[imp_sth->index] = 0;
      _iqclose(_SQ[imp_sth->index]);
      imp_sth->execd = 0;
    }
  DBIc_ACTIVE_off(imp_sth);
  return 1;
}


void
dbd_st_destroy(sth, imp_sth)
    SV *sth;
    struct imp_sth_st* imp_sth;
{
#if I4DEBUG
    fprintf(stderr, "dbd_st_destroy\n");
#endif

    /* Free off contents of imp_sth	*/

    if (imp_sth->out_params_av)
	sv_free((SV*)imp_sth->out_params_av);

    if (imp_sth->all_params_hv) {
	HV *hv = imp_sth->all_params_hv;
	SV *sv;
	char *key;
	I32 retlen;
	hv_iterinit(hv);
	while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
	    if (sv != &sv_undef) {
		phs_t *phs_tpl = (phs_t*)(void*)SvPVX(sv);
		sv_free(phs_tpl->sv);
	    }
	}
	sv_free((SV*)imp_sth->all_params_hv);
    }

    DBIc_IMPSET_off(imp_sth); /* let DBI know we've done it */
}


int
dbd_st_STORE(sth, imp_sth, keysv, valuesv)
    SV *sth;
    struct imp_sth_st* imp_sth;
    SV *keysv;
    SV *valuesv;
{
    return dbd_st_STORE_attrib(sth, imp_sth, keysv, valuesv);
}

int
dbd_st_STORE_attrib(sth, imp_sth, keysv, valuesv)
    SV *sth;
    struct imp_sth_st* imp_sth;
    SV *keysv;
    SV *valuesv;
{
    return FALSE;
}


SV *
dbd_st_FETCH(sth, imp_sth, keysv)
    SV *sth;
    struct imp_sth_st* imp_sth;
    SV *keysv;
{
  return dbd_st_FETCH_attrib(sth, imp_sth, keysv);
}

SV *
dbd_st_FETCH_attrib(sth, imp_sth, keysv)
    SV *sth;
    struct imp_sth_st* imp_sth;
    SV *keysv;
{
  struct sqlvar_struct *col;
  STRLEN kl;
  char *key = SvPV(keysv,kl);
  SV *retsv = NULL;
  int i;
  AV* av;
    if (kl==13 && strEQ(key, "NUM_OF_PARAMS")) { /* handled by DBI */
	return Nullsv;	
    }

    if (! imp_sth->execd) {
	return Nullsv;	
    }

    if (kl != 4) return Nullsv;
    if(strEQ(key, "NAME")) 
      {
	av = newAV();
	retsv = newRV(sv_2mortal((SV*)av));
	for (col = udesc[imp_sth->index]->sqlvar, i = 0;
	     i < udesc[imp_sth->index]->sqld; col++, i++)
	  {
	    av_store(av, i, newSVpv(col->sqlname,0));
	  }
      }
    else if (strEQ(key, "TYPE"))
      {
	av = newAV();
	retsv = newRV(sv_2mortal((SV*)av));
	for (col = udesc[imp_sth->index]->sqlvar, i = 0;
	     i < udesc[imp_sth->index]->sqld; col++, i++)
	  {
	    av_store(av, i, newSViv(col->sqltype));
	  }
    }
    else if (strEQ(key, "SIZE")) 
      {
	av = newAV();
	retsv = newRV(sv_2mortal((SV*)av));
	for (col = udesc[imp_sth->index]->sqlvar, i = 0;
	     i < udesc[imp_sth->index]->sqld; col++, i++)
	  {
	    av_store(av, i, newSViv(col->sqllen));
	  }
      }
    else
      return Nullsv;
    return sv_2mortal(retsv);
}



int dbd_st_blob_read()
{
  return 0;
}
