/*

   Copyright (c) 2001 Alex Pilosov
   Copyright (c) 1997,1998,1999 Edmund Mergl
   Portions Copyright (c) 1994,1995,1996,1997 Tim Bunce

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/


/* 
   hard-coded OIDs used in function pgtype_bind_ok()
  XXX: these should all be replaced by XXXOID 
*/

#include "PgSPI.h"

/* XXX DBI should provide a better version of this */
#define IS_DBI_HANDLE(h)  (SvROK(h) && SvTYPE(SvRV(h)) == SVt_PVHV && SvRMAGICAL(SvRV(h)) && (SvMAGIC(SvRV(h)))->mg_type == 'P')

DBISTATE_DECLARE;


static void dbd_preparse  (imp_sth_t *imp_sth, char *statement, SV *attribs);
char * pgspi_err_desc (int err);
char * pgspi_status_desc (int ret);


void
dbd_init (dbistate)
    dbistate_t *dbistate;
{
    DBIS = dbistate;
}


int
dbd_discon_all (drh, imp_drh)
    SV *drh;
    imp_drh_t *imp_drh;
{
    dTHR;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_discon_all\n"); }

    /* The disconnect_all concept is flawed and needs more work */
    if (!PL_dirty && !SvTRUE(perl_get_sv("DBI::PERL_ENDING",0))) {
	sv_setiv(DBIc_ERR(imp_drh), (IV)1);
	sv_setpv(DBIc_ERRSTR(imp_drh),
		(char*)"disconnect_all not implemented");
	DBIh_EVENT2(drh, ERROR_event,
		DBIc_ERR(imp_drh), DBIc_ERRSTR(imp_drh));
	return FALSE;
    }
    if (PL_perl_destruct_level) {
        PL_perl_destruct_level = 0;
    }
    return FALSE;
}


/* Database specific error handling. */

void
pg_error (h, error_num, error_msg)
    SV *h;
    int error_num;
    char *error_msg;
{
    D_imp_xxh(h);

    sv_setiv(DBIc_ERR(imp_xxh), (IV)error_num);		/* set err early */
    sv_setpv(DBIc_ERRSTR(imp_xxh), (char*)error_msg);
    DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), DBIc_ERRSTR(imp_xxh));
    if (1 || dbis->debug >= 2) { elog(ERROR, "DBD::PgSPI %s error %d recorded: %s\n", error_msg, error_num, SvPV(DBIc_ERRSTR(imp_xxh),PL_na)); } 
}

/* XXX: do we really care? shouldn't we able to bind everything, and
 *      let xxx_in functions deal with conversion?
 */
static int
pgtype_bind_ok (dbtype)
    int dbtype;
{
    /* basically we support types that can be returned as strings */
    switch(dbtype) {
    case   16:	/* bool		*/
    case   18:	/* char		*/
    case   20:	/* int8		*/
    case   21:	/* int2		*/
    case   23:	/* int4		*/
    case   25:	/* text		*/
    case   26:	/* oid		*/
    case  700:	/* float4	*/
    case  701:	/* float8	*/
    case  702:	/* abstime	*/
    case  703:	/* reltime	*/
    case  704:	/* tinterval	*/
    case 1042:	/* bpchar	*/
    case 1043:	/* varchar	*/
    case 1082:	/* date		*/
    case 1083:	/* time		*/
    case 1184:	/* datetime	*/
    case 1186:	/* timespan	*/
    case 1296:	/* timestamp	*/
        return 1;
    }
    return 0;
}


/* ================================================================== */

int
dbd_db_login (dbh, imp_dbh, dummy1, dummy2, dummy3)
    SV *dbh;
    imp_dbh_t *imp_dbh;
    char *dummy1;
    char *dummy2;
    char *dummy3;
{
    dTHR;
    D_imp_drh_from_dbh;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "pg_db_login\n"); }

    /* our life is easy. we actually never call SPI_connect/finish, 
       since its the responsibility of plperl_func_handler */

    imp_dbh->pg_auto_escape = 1;		/* initialize pg_auto_escape */

/* init autocommit to 1 */
    DBIc_set(imp_dbh, DBIcf_AutoCommit, &PL_sv_yes);

    DBIc_IMPSET_on(imp_dbh);			/* imp_dbh set up now */
    DBIc_ACTIVE_on(imp_dbh);			/* call disconnect before freeing */
    return 1;
}

int
dbd_db_disconnect (dbh, imp_dbh)
    SV *dbh;
    imp_dbh_t *imp_dbh;
{
    dTHR;
    D_imp_drh_from_dbh;

    /* We assume that disconnect will always work	*/
    DBIc_ACTIVE_off(imp_dbh);

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "pg_db_disconnect\n"); }

    /* our life is easy. we actually never call SPI_connect/finish, 
       since its the responsibility of plperl_func_handler */

    /* We don't free imp_dbh since a reference still exists	*/
    /* The DESTROY method is the only one to 'free' memory.	*/
    /* Note that statement objects may still exists for this dbh!	*/
    return 1;
}


void
dbd_db_destroy (dbh, imp_dbh)
    SV *dbh;
    imp_dbh_t *imp_dbh;
{
    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_db_destroy\n"); }

    if (DBIc_ACTIVE(imp_dbh)) {
        dbd_db_disconnect(dbh, imp_dbh);
    }

    /* Nothing in imp_dbh to be freed	*/
    DBIc_IMPSET_off(imp_dbh);
}


int
dbd_db_STORE_attrib (dbh, imp_dbh, keysv, valuesv)
    SV *dbh;
    imp_dbh_t *imp_dbh;
    SV *keysv;
    SV *valuesv;
{
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    int newval = SvTRUE(valuesv);

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_db_STORE\n"); }

    if (kl==10 && strEQ(key, "AutoCommit") ) {
      if ( newval == FALSE ) {
        pg_error(dbh, -1, "Can't turn off Autocommit\n");
        return 0;
      }
      return 1;
    } else if (kl==14 && strEQ(key, "pg_auto_escape")) {
        imp_dbh->pg_auto_escape = newval;
    } else {
        return 0;
    }
}


SV *
dbd_db_FETCH_attrib (dbh, imp_dbh, keysv)
    SV *dbh;
    imp_dbh_t *imp_dbh;
    SV *keysv;
{
    STRLEN kl;
    char *key = SvPV(keysv,kl);
    SV *retsv = Nullsv;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_db_FETCH\n"); }

    if (kl==10 && strEQ(key, "AutoCommit") ) {
        retsv = boolSV(DBIc_has(imp_dbh, DBIcf_AutoCommit));
    } else if (kl==14 && strEQ(key, "pg_auto_escape")) {
        retsv = newSViv((IV)imp_dbh->pg_auto_escape);
    }

    if (!retsv) {
	return Nullsv;
    }
    if (retsv == &PL_sv_yes || retsv == &PL_sv_no) {
        return retsv; /* no need to mortalize yes or no */
    }
    return sv_2mortal(retsv);
}


/* driver specific functins */

/* ================================================================== */


int
dbd_st_prepare (sth, imp_sth, statement, attribs)
    SV *sth;
    imp_sth_t *imp_sth;
    char *statement;
    SV *attribs;
{
    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_prepare: statement = >%s<\n", statement); }

    /* scan statement for '?', ':1' and/or ':foo' style placeholders */
    dbd_preparse(imp_sth, statement, attribs);

    /* if all argtypes have been specified to us, we can 
     * use SPI_prepare with correct nparams/argtypes. (not implemented yet)
     *
     * if not, we must not do a SPI_prepare until the sth is executed,
     * and fill in the args there.
     */
/*    SPI_prepare(statement, imp_sth->nparams,  */

    /* initialize new statement handle */
    imp_sth->cur_tuple = 0; 

    DBIc_IMPSET_on(imp_sth);
    return 1;
}


static void
dbd_preparse (imp_sth, statement, attribs)
    imp_sth_t *imp_sth;
    char *statement;
    SV *attribs;
{
    bool in_literal = FALSE;
    char in_comment = '\0';
    char *src, *start, *dest;
    phs_t phs_tpl;
    SV *phs_sv;
    int idx=0;
    char *style="", *laststyle=Nullch;
    STRLEN namelen;
  
    void *res;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_preparse: statement = >%s<\n", statement); }

    /* allocate room for copy of statement with spare capacity	*/
    /* for editing '?' or ':1' into ':p1'.			*/
    imp_sth->statement = (char*)safemalloc(strlen(statement) * 3);

    /* initialise phs ready to be cloned per placeholder	*/
    memset(&phs_tpl, 0, sizeof(phs_tpl));
    phs_tpl.ftype = 1043;	/* VARCHAR */

    src  = statement;
    dest = imp_sth->statement;
    while(*src) {

	if (in_comment) {
	    /* SQL-style and C++-style */ 
	    if ((in_comment == '-' || in_comment == '/') && *src == '\n') {
		in_comment = '\0';
	    }
            /* C-style */
	    else if (in_comment == '*' && *src == '*' && *(src+1) == '/') {
		*dest++ = *src++; /* avoids asterisk-slash-asterisk issues */
		in_comment = '\0';
	    }
	    *dest++ = *src++;
	    continue;
	}

	if (in_literal) {
	    /* check if literal ends but keep quotes in literal */
	    if (*src == in_literal && *(src-1) != '\\') {
	        in_literal = 0;
            }
	    *dest++ = *src++;
	    continue;
	}

	/* Look for comments: SQL-style or C++-style or C-style	*/
	if ((*src == '-' && *(src+1) == '-') ||
            (*src == '/' && *(src+1) == '/') ||
	    (*src == '/' && *(src+1) == '*'))
	{
	    in_comment = *(src+1);
	    /* We know *src & the next char are to be copied, so do */
	    /* it. In the case of C-style comments, it happens to */
	    /* help us avoid slash-asterisk-slash oddities. */
	    *dest++ = *src++;
	    *dest++ = *src++;
	    continue;
	}

        /* check if no placeholders */
        if (*src != ':' && *src != '?') {
	    if (*src == '\'' || *src == '"') {
		in_literal = *src;
	    }
	    *dest++ = *src++;
	    continue;
	}

        /* check for cast operator */
        if (*src == ':' && (*(src-1) == ':' || *(src+1) == ':')) {
	    *dest++ = *src++;
	    continue;
	}

	/* only here for : or ? outside of a comment or literal	and no cast */

        start = dest;			/* save name inc colon	*/ 
        *dest++ = *src++;
        if (*start == '?') {		/* X/Open standard	*/
            sprintf(start,":p%d", ++idx); /* '?' -> ':p1' (etc)	*/
            dest = start+strlen(start);
            style = "?";

        } else if (isDIGIT(*src)) {	/* ':1'		*/
            idx = atoi(src);
            *dest++ = 'p';		/* ':1'->':p1'	*/
            if (idx <= 0) {
                croak("Placeholder :%d invalid, placeholders must be >= 1", idx);
            }
            while(isDIGIT(*src)) {
                *dest++ = *src++;
            }
            style = ":1";

        } else if (isALNUM(*src)) {	/* ':foo'	*/
            while(isALNUM(*src)) {	/* includes '_'	*/
                *dest++ = *src++;
            }
            style = ":foo";
        } else {			/* perhaps ':=' PL/SQL construct */
            continue;
        }
        *dest = '\0';			/* handy for debugging	*/
        namelen = (dest-start);
        if (laststyle && style != laststyle) {
            croak("Can't mix placeholder styles (%s/%s)",style,laststyle);
        }
        laststyle = style;
        if (imp_sth->all_params_hv == NULL) {
            imp_sth->all_params_hv = newHV();
        }
        phs_tpl.sv = &PL_sv_undef;
        phs_sv = newSVpv((char*)&phs_tpl, sizeof(phs_tpl)+namelen+1);
        hv_store(imp_sth->all_params_hv, start, namelen, phs_sv, 0);
        strcpy( ((phs_t*)(void*)SvPVX(phs_sv))->name, start);
    }
    *dest = '\0';
    if (imp_sth->all_params_hv) {
        DBIc_NUM_PARAMS(imp_sth) = (int)HvKEYS(imp_sth->all_params_hv);
        if (dbis->debug >= 2) { PerlIO_printf(DBILOGFP, "    dbd_preparse scanned %d distinct placeholders\n", (int)DBIc_NUM_PARAMS(imp_sth)); }
/*	argtypes = malloc(sizeof(Oid *) * (expr->nparams + 1)); */

    } else {
/*XXX	imp_sth->argtypes=NULL; */
    }
/*    SPI_prepare(statement, DBIc_NUM_PARAMS(imp_sth), imp_sth->argtypes); */
}


static int
pg_sql_type (imp_sth, name, sql_type)
    imp_sth_t *imp_sth;
    char *name;
    int sql_type;
{
    switch (sql_type) {
        case SQL_CHAR:
            return BPCHAROID;	/* bpchar */
        case SQL_NUMERIC:
            return FLOAT4OID;		/* float4 */
        case SQL_DECIMAL:
            return FLOAT4OID;		/* float4 */
        case SQL_INTEGER:
            return INT4OID;		/* int4	*/
        case SQL_SMALLINT:
            return INT2OID;		/* int2	*/
        case SQL_FLOAT:
            return FLOAT4OID;		/* float4 */
        case SQL_REAL:
            return FLOAT8OID;		/* float8 */
        case SQL_DOUBLE:
            return FLOAT8OID;		/* it was INT4 in DBD::Pg */
        case SQL_VARCHAR:
            return VARCHAROID;	/* varchar */
        default:
            if (DBIc_WARN(imp_sth) && imp_sth && name) {
                warn("SQL type %d for '%s' is not fully supported, bound as VARCHAR instead");
            }
            return pg_sql_type(imp_sth, name, SQL_VARCHAR);
    }
}


static int
dbd_rebind_ph (sth, imp_sth, phs)
    SV *sth;
    imp_sth_t *imp_sth;
    phs_t *phs;
{
    STRLEN value_len;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_rebind\n"); }

    /* convert to a string ASAP */
    if (!SvPOK(phs->sv) && SvOK(phs->sv)) {
	sv_2pv(phs->sv, &PL_na);
    }

    if (dbis->debug >= 2) {
	char *val = neatsvpv(phs->sv,0);
 	PerlIO_printf(DBILOGFP, "       bind %s <== %.1000s (", phs->name, val);
 	if (SvOK(phs->sv)) {
 	     PerlIO_printf(DBILOGFP, "size %ld/%ld/%ld, ", (long)SvCUR(phs->sv),(long)SvLEN(phs->sv),phs->maxlen);
	} else {
            PerlIO_printf(DBILOGFP, "NULL, ");
        }
 	PerlIO_printf(DBILOGFP, "ptype %d, otype %d%s)\n", (int)SvTYPE(phs->sv), phs->ftype);
    }

    /* At the moment we always do sv_setsv() and rebind.        */
    /* Later we may optimise this so that more often we can     */
    /* just copy the value & length over and not rebind.        */

    /* phs->sv is copy of real variable, upgrade to at least string */
    (void)SvUPGRADE(phs->sv, SVt_PV);

    /* At this point phs->sv must be at least a PV with a valid buffer, */
    /* even if it's undef (null)                                        */
    /* Here we set phs->progv, phs->indp, and value_len.                */
    if (SvOK(phs->sv)) {
        phs->progv = SvPV(phs->sv, value_len);
        phs->indp  = 0;
    }
    else {        /* it's null but point to buffer in case it's an out var */
        phs->progv = SvPVX(phs->sv);
        phs->indp  = -1;
        value_len  = 0;
    }
    phs->sv_type = SvTYPE(phs->sv);        /* part of mutation check    */
    phs->maxlen  = SvLEN(phs->sv)-1;       /* avail buffer space        */
    if (phs->maxlen < 0) {                 /* can happen with nulls     */
	phs->maxlen = 0;
    }

    phs->alen = value_len + phs->alen_incnull;

    imp_sth->all_params_len += phs->alen;

    if (dbis->debug >= 3) {
	PerlIO_printf(DBILOGFP, "       bind %s <== '%.*s' (size %ld/%ld, otype %d, indp %d)\n",
 	    phs->name,
	    (int)(phs->alen>SvIV(DBIS->neatsvpvlen) ? SvIV(DBIS->neatsvpvlen) : phs->alen),
	    (phs->progv) ? phs->progv : "",
 	    (long)phs->alen, (long)phs->maxlen, phs->ftype, phs->indp);
    }

    return 1;
}


int
dbd_bind_ph (sth, imp_sth, ph_namesv, newvalue, sql_type, attribs, is_inout, maxlen)
    SV *sth;
    imp_sth_t *imp_sth;
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

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_bind_ph\n"); }

    /* check if placeholder was passed as a number        */

    if (SvGMAGICAL(ph_namesv)) { /* eg if from tainted expression */
	mg_get(ph_namesv);
    }
    if (!SvNIOKp(ph_namesv)) {
	name = SvPV(ph_namesv, name_len);
    }
    if (SvNIOKp(ph_namesv) || (name && isDIGIT(name[0]))) {
	sprintf(namebuf, ":p%d", (int)SvIV(ph_namesv));
	name = namebuf;
	name_len = strlen(name);
    }
    assert(name != Nullch);

    if (SvTYPE(newvalue) > SVt_PVLV) { /* hook for later array logic	*/
	croak("Can't bind a non-scalar value (%s)", neatsvpv(newvalue,0));
    }
    if (SvROK(newvalue) && !IS_DBI_HANDLE(newvalue)) {
	/* dbi handle allowed for cursor variables */
	croak("Can't bind a reference (%s)", neatsvpv(newvalue,0));
    }
    if (is_inout) {	/* may allow later */
        croak("inout parameters not supported");
    }

   if (dbis->debug >= 2) {
        PerlIO_printf(DBILOGFP, "         bind %s <== %s (type %ld", name, neatsvpv(newvalue,0), (long)sql_type);
        if (attribs) {
            PerlIO_printf(DBILOGFP, ", attribs: %s", neatsvpv(attribs,0));
        }
        PerlIO_printf(DBILOGFP, ")\n");
    }

    phs_svp = hv_fetch(imp_sth->all_params_hv, name, name_len, 0);
    if (phs_svp == NULL) {
        croak("Can't bind unknown placeholder '%s' (%s)", name, neatsvpv(ph_namesv,0));
    }
    phs = (phs_t*)(void*)SvPVX(*phs_svp);	/* placeholder struct	*/

    if (phs->sv == &PL_sv_undef) { /* first bind for this placeholder	*/
        phs->ftype    = 1043;		 /* our default type VARCHAR	*/

        if (attribs) {	/* only look for pg_type on first bind of var	*/
            SV **svp;
	    /* Setup / Clear attributes as defined by attribs.		*/
	    /* XXX If attribs is EMPTY then reset attribs to default?	*/
            if ( (svp = hv_fetch((HV*)SvRV(attribs), "pg_type", 7,  0)) != NULL) {
                int pg_type = SvIV(*svp);
                if (!pgtype_bind_ok(pg_type)) {
                    croak("Can't bind %s, pg_type %d not supported by DBD::Pg", phs->name, pg_type);
                }
                if (sql_type) {
                    croak("Can't specify both TYPE (%d) and pg_type (%d) for %s", sql_type, pg_type, phs->name);
                }
                phs->ftype = pg_type;
            }
        }
        if (sql_type) {
            phs->ftype = pg_sql_type(imp_sth, phs->name, sql_type);
        }
    }   /* was first bind for this placeholder  */

    else if (sql_type && phs->ftype != pg_sql_type(imp_sth, phs->name, sql_type)) {
        croak("Can't change TYPE of param %s to %d after initial bind", phs->name, sql_type);
    }

    phs->maxlen = maxlen;		/* 0 if not inout		*/

    if (phs->sv == &PL_sv_undef) {     /* (first time bind) */
        phs->sv = newSV(0);
    }
    sv_setsv(phs->sv, newvalue);

    return dbd_rebind_ph(sth, imp_sth, phs);
}


int
dbd_st_execute (sth, imp_sth)   /* <= -2:error, >=0:ok row count, (-1=unknown count) */
    SV *sth;
    imp_sth_t *imp_sth;
{
    dTHR;

    D_imp_dbh_from_sth;

    char *statement;
    int spi_ret;

    int ret = -2;
    int num_fields;
    int i;
    int len;
    bool in_literal = FALSE;
    char in_comment = '\0';
    char *src;
    char *dest;
    char *val;
    char namebuf[30];
    phs_t *phs;
    SV **svp;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_execute\n"); }

    /*
    here we get the statement from the statement handle where
    it has been stored when creating a blank sth during prepare
    svp = hv_fetch((HV *)SvRV(sth), "Statement", 9, FALSE);
    statement = SvPV(*svp, PL_na);
    */

    statement = imp_sth->statement;
    if (! statement) {
        /* are we prepared ? */
        pg_error(sth, -1, "statement not prepared\n");
        return -2;
    }

    /* do we have input parameters ? */
    if ((int)DBIc_NUM_PARAMS(imp_sth) > 0) {
        /* we have to allocate some additional memory for possible escaping quotes and backslashes */
        statement = (char*)safemalloc(strlen(imp_sth->statement) + 2 * imp_sth->all_params_len);
        dest = statement;
        src  = imp_sth->statement;
        /* scan statement for ':p1' style placeholders */
        while(*src) {

            if (in_comment) {
	        /* SQL-style and C++-style */ 
	        if ((in_comment == '-' || in_comment == '/') && *src == '\n') {
		    in_comment = '\0';
	        }
                /* C-style */
	        else if (in_comment == '*' && *src == '*' && *(src+1) == '/') {
		    *dest++ = *src++; /* avoids asterisk-slash-asterisk issues */
		    in_comment = '\0';
	        }
	        *dest++ = *src++;
	        continue;
	    }

	    if (in_literal) {
	        /* check if literal ends but keep quotes in literal */
	        if (*src == in_literal && *(src-1) != '\\') {
	            in_literal = 0;
                }
	        *dest++ = *src++;
	        continue;
	    }

	    /* Look for comments: SQL-style or C++-style or C-style	*/
	    if ((*src == '-' && *(src+1) == '-') ||
                (*src == '/' && *(src+1) == '/') ||
	        (*src == '/' && *(src+1) == '*'))
	    {
	        in_comment = *(src+1);
	        /* We know *src & the next char are to be copied, so do */
	        /* it. In the case of C-style comments, it happens to */
	        /* help us avoid slash-asterisk-slash oddities. */
	        *dest++ = *src++;
	        *dest++ = *src++;
	        continue;
	    }

            /* check if no placeholders */
            if (*src != ':' && *src != '?') {
	        if (*src == '\'' || *src == '"') {
		    in_literal = *src;
	        }
	        *dest++ = *src++;
	        continue;
	    }

            /* check for cast operator */
            if (*src == ':' && (*(src-1) == ':' || *(src+1) == ':')) {
	        *dest++ = *src++;
	        continue;
	    }


            i = 0;
            namebuf[i++] = *src++; /* ':' */
            namebuf[i++] = *src++; /* 'p' */
            while (isDIGIT(*src)) {
                namebuf[i++] = *src++;
            }
            namebuf[i] = '\0';
            svp = hv_fetch(imp_sth->all_params_hv, namebuf, i, 0);
            if (svp == NULL) {
                pg_error(sth, -1, "parameter unknown\n");
                return -2;
            }
            /* get attribute */
            phs = (phs_t*)(void*)SvPVX(*svp);
            /* replace undef with NULL */
            if(!SvOK(phs->sv)) {
                val = "NULL";
                len = 4;
            } else {
                val = SvPV(phs->sv, len);
            }
            /* quote string attribute */
            if(!SvNIOK(phs->sv) && SvOK(phs->sv) && phs->ftype > 1000) { /* avoid quoting NULL, tpf: bind_param as numeric  */
	        *dest++ = '\''; 
            }
            while (len--) {
                if (imp_dbh->pg_auto_escape) {
		    /* escape quote */
                    if (*val == '\'') {
                        *dest++ = '\'';
                    }
	            /* escape backslash except for octal presentation */
                    if (*val == '\\' && !isdigit(*(val+1)) && !isdigit(*(val+2)) && !isdigit(*(val+3)) ) {
                        *dest++ = '\\';
                    }
                }
                /* copy attribute to statement */
                *dest++ = *val++;
            }
            /* quote string attribute */
            if(!SvNIOK(phs->sv) && SvOK(phs->sv) && phs->ftype > 1000) { /* avoid quoting NULL,  tpf: bind_param as numeric */
                *dest++ = '\''; 
            }
        }
        *dest = '\0';
    }

    if (dbis->debug >= 2) { PerlIO_printf(DBILOGFP, "dbd_st_execute: statement = >%s<\n", statement); }

    spi_ret = SPI_exec(statement, 0);

    if (dbis->debug >= 2) { PerlIO_printf(DBILOGFP, "(retcode %d)\n",spi_ret); }

    /* free statement string in case of input parameters */
    if ((int)DBIc_NUM_PARAMS(imp_sth) > 0) {
        Safefree(statement);
    }

    imp_sth->status=pgspi_status_desc(spi_ret);

    switch (spi_ret)
    {
      case SPI_OK_UTILITY:
        ret = -1;
        break;
      case SPI_OK_INSERT: /* fall through */
        imp_sth->lastoid=SPI_lastoid;
      case SPI_OK_SELINTO:
      case SPI_OK_DELETE:
      case SPI_OK_UPDATE:
        ret = SPI_processed;
        if (dbis->debug >= 2) { PerlIO_printf(DBILOGFP, "(UPDATE OK,got %d tuples)\n",ret); }
        break;
      case SPI_OK_SELECT:
        ret = SPI_processed;

        if (ret) {
/* snarf result some information into our private array */
          imp_sth->tupdesc = SPI_tuptable->tupdesc;
          imp_sth->tuples = SPI_tuptable->vals;
          num_fields = SPI_tuptable->tupdesc->natts;
          imp_sth->cur_tuple = 0;
        } else { /* ouch, no data whatsover? */
        }
        DBIc_NUM_FIELDS(imp_sth) = num_fields;
        DBIc_ACTIVE_on(imp_sth);
        if (dbis->debug >= 2) { PerlIO_printf(DBILOGFP, "(SELECT OK,got %d tuples, %d fields wide)\n",ret, num_fields); }
        break;
      case SPI_ERROR_ARGUMENT:
      case SPI_ERROR_UNCONNECTED:
      case SPI_ERROR_COPY:
      case SPI_ERROR_CURSOR:
      case SPI_ERROR_TRANSACTION:
      case SPI_ERROR_OPUNKNOWN:
      default: 
        pg_error(sth, ret, pgspi_err_desc(spi_ret));
        ret = -2;
        break;
    }

    /* store the number of affected rows */
    imp_sth->rows = ret;

    return ret;
}

char * pgspi_status_desc (int ret) {
    switch(ret) {
      case SPI_OK_UTILITY:
	return "UTILITY"; break;
      case SPI_OK_INSERT: 
	return "INSERT"; break;
      case SPI_OK_SELINTO:
	return "SELECT"; break; /* or is it SELINTO? */
      case SPI_OK_DELETE:
	return "DELETE"; break;
      case SPI_OK_UPDATE:
	return "UPDATE"; break;
      case SPI_OK_SELECT:
	return "SELECT"; break;
      default:
        return "UNKNOWN";
    }
}

char * pgspi_err_desc (int err) {
    switch(err) {
      case SPI_ERROR_ARGUMENT:
        return "SPI_ERROR_ARGUMENT";
      case SPI_ERROR_UNCONNECTED:
        return "SPI_ERROR_UNCONNECTED";
      case SPI_ERROR_COPY:
        return "SPI_ERROR_COPY";
      case SPI_ERROR_CURSOR:
        return "SPI_ERROR_CURSOR";
      case SPI_ERROR_TRANSACTION:
        return "SPI_ERROR_TRANSACTION";
      case SPI_ERROR_OPUNKNOWN:
        return "SPI_ERROR_OPUNKNOWN";
      default:
        return "UNKNOWN SPI ERROR";
    }
}

AV *
dbd_st_fetch (sth, imp_sth)
    SV *sth;
    imp_sth_t *imp_sth;
{
    int num_fields;
    HeapTuple tup;
    HeapTuple       typeTup;
    TupleDesc tupdesc;
    Form_pg_attribute attdesc;
    int i;
    AV *av;
    SV *sv;
    Oid typoutput;
    Oid typioparam;
    char * attname;
    Datum attr;
    char * val;
    int len;
    bool isnull;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_fetch\n"); }

    /* Check that execute() was executed sucessfully */
    if ( !DBIc_ACTIVE(imp_sth) ) {
        pg_error(sth, 1, "no statement executing\n");
        return Nullav;
    }


    if ( imp_sth->cur_tuple == imp_sth->rows )  {
        imp_sth->cur_tuple = 0; 
/* XXX: probably we should consider sth closed here. check latest DBD::Pg */
        return Nullav; /* we reached the last tuple */
    }
    tup = imp_sth->tuples[imp_sth->cur_tuple];
    tupdesc = imp_sth->tupdesc;

    av = DBIS->get_fbav(imp_sth);
    num_fields = AvFILL(av)+1;

/* maybe we should use portals and cursor here? maybe later */

    for(i = 0; i < num_fields; ++i) {
        attdesc = imp_sth->tupdesc->attrs[i];
        attname = NameStr(imp_sth->tupdesc->attrs[i]->attname);
        attr = heap_getattr(tup, i +1, tupdesc, &isnull);

        sv  = AvARRAY(av)[i];
        if (isnull) { 
            sv_setsv(sv, &PL_sv_undef);
        } else  {
/* we have the value, now lets extract it correctly. We need to be aware 
   of boolean types to convert them to 0/1, but anything else we can get 
   as a CSTRING */
            typeTup = SearchSysCache(TYPEOID, ObjectIdGetDatum(attdesc->atttypid), 0, 0, 0);
            if (!HeapTupleIsValid(typeTup)) {
                elog(ERROR, "plperl: Cache lookup for attribute '%s' type %u failed", attname, tupdesc->attrs[i]->atttypid);
            }
            typoutput = (Oid) (((Form_pg_type) GETSTRUCT(typeTup))->typoutput);
            typioparam = getTypeIOParam(typeTup);

            ReleaseSysCache(typeTup);

            if (OidIsValid(typoutput)) {
/* fetch quickly for things that we know, 
   rely on GetCString for anything else */
 	      switch (attdesc->atttypid) {
	        case BOOLOID:
	   	  sv_setiv(sv, DatumGetBool(attr)?1:0 );
                  break;
	        case INT2OID:
	   	  sv_setiv(sv, DatumGetInt16(attr) );
                  break;
	        case INT4OID: 
	   	  sv_setiv(sv, DatumGetInt32(attr) );
                  break;
/* its a bit special
	        case INT8OID: 
	   	  sv_setnv(sv, DatumGetInt64(attr) );
                  break;
*/
  		default:
                  val = DatumGetCString(OidFunctionCall3(typoutput, attr,
                          ObjectIdGetDatum(typioparam),
                          Int32GetDatum(tupdesc->attrs[i]->atttypmod)
                        ));
 		  switch (attdesc->atttypid) {
/* chopblanks won't quite work 
                    case CHAROID:
                    case TEXTOID:
                    case NAMEOID:
                    case BPCHAROID:
                      if ( DBIc_has(imp_sth,DBIcf_ChopBlanks) ) {
                        len = strlen(val);
                        char *str = val;
                        while((len > 0) && (str[len-1] == ' ')) {
                            len--;
                        }
                        sv_setpvn(sv, val, len);
                      } else {
                        sv_setpv(sv, val);
                      }
*/
                    default:
                      sv_setpv(sv, val);
 		  }
                  pfree(val);
                  break;
              }
            }
        }
    }

    imp_sth->cur_tuple += 1;

    return av;
}


int
dbd_st_rows (sth, imp_sth)
    SV *sth;
    imp_sth_t *imp_sth;
{
    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_rows\n"); }

    return imp_sth->rows;
}


int
dbd_st_finish (sth, imp_sth)
    SV *sth;
    imp_sth_t *imp_sth;
{
    dTHR;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_finish\n"); }

/* XXX: close portal when we use portals
    if (DBIc_ACTIVE(imp_sth)) {
    }
*/

    DBIc_ACTIVE_off(imp_sth);
    return 1;
}


void
dbd_st_destroy (sth, imp_sth)
    SV *sth;
    imp_sth_t *imp_sth;
{
    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_destroy\n"); }

    /* Free off contents of imp_sth */

    Safefree(imp_sth->statement);

/* XY: result check was here */

    if (imp_sth->all_params_hv) {
        HV *hv = imp_sth->all_params_hv;
        SV *sv;
        char *key;
        I32 retlen;
        hv_iterinit(hv);
        while( (sv = hv_iternextsv(hv, &key, &retlen)) != NULL ) {
            if (sv != &PL_sv_undef) {
                phs_t *phs_tpl = (phs_t*)(void*)SvPVX(sv);
                sv_free(phs_tpl->sv);
            }
        }
        sv_free((SV*)imp_sth->all_params_hv);
    }

    DBIc_IMPSET_off(imp_sth); /* let DBI know we've done it */
}


int
dbd_st_STORE_attrib (sth, imp_sth, keysv, valuesv)
    SV *sth;
    imp_sth_t *imp_sth;
    SV *keysv;
    SV *valuesv;
{
    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_STORE\n"); }

    return FALSE;
}


SV *
dbd_st_FETCH_attrib (sth, imp_sth, keysv)
    SV *sth;
    imp_sth_t *imp_sth;
    SV *keysv;
{
    Form_pg_attribute attdesc;
    HeapTuple       typeTup;
    char *typname;

    STRLEN kl;
    char *key = SvPV(keysv,kl);
    int i;
    SV *retsv = Nullsv;

    if (dbis->debug >= 1) { PerlIO_printf(DBILOGFP, "dbd_st_FETCH\n"); }

/* XY: result check was here */

    i = DBIc_NUM_FIELDS(imp_sth);

    if (kl == 4 && strEQ(key, "NAME")) {
        AV *av = newAV();
        retsv = newRV(sv_2mortal((SV*)av));
	while(--i >= 0) {
            av_store(av, i, newSVpv(
              NameStr(imp_sth->tupdesc->attrs[i]->attname),
              0 ) 
            );
        }
    }  else if ( kl== 4 && strEQ(key, "TYPE")) {
        AV *av = newAV();
        retsv = newRV(sv_2mortal((SV*)av));
	while(--i >= 0) {
            av_store(av, i, newSViv(imp_sth->tupdesc->attrs[i]->atttypid));
        }
    }  else if (kl==9 && strEQ(key, "PRECISION")) {
        AV *av = newAV();
        retsv = newRV(sv_2mortal((SV*)av));
	while(--i >= 0) {
            av_store(av, i, &PL_sv_undef);
        }
    } else if (kl==5 && strEQ(key, "SCALE")) {
        AV *av = newAV();
        retsv = newRV(sv_2mortal((SV*)av));
	while(--i >= 0) {
            av_store(av, i, &PL_sv_undef);
        }
    } else if (kl==8 && strEQ(key, "NULLABLE")) {
        AV *av = newAV();
        retsv = newRV(sv_2mortal((SV*)av));
	while(--i >= 0) {
            av_store(av, i, newSViv(2));
        }
    } else if (kl==10 && strEQ(key, "CursorName")) {
        retsv = &PL_sv_undef;
    } else if (kl==7 && strEQ(key, "pg_size")) {
        AV *av = newAV();
        retsv = newRV(sv_2mortal((SV*)av));
	while(--i >= 0) {
            av_store(av, i, newSViv(imp_sth->tupdesc->attrs[i]->attlen));
        }
    } else if (kl==7 && strEQ(key, "pg_type")) {
        AV *av = newAV();
        char *type_nam;
        retsv = newRV(sv_2mortal((SV*)av));
	while(--i >= 0) {
            attdesc = imp_sth->tupdesc->attrs[i];
            typeTup = SearchSysCache(TYPEOID, 
                ObjectIdGetDatum(attdesc->atttypid), 
                0, 0, 0
            );
            if (!HeapTupleIsValid(typeTup)) {
                elog(ERROR, "plperl: Cache lookup for attribute '%s' type %u failed", NameStr(attdesc->attname), attdesc->atttypid);
            }
	    typname = (char *) NameStr(((Form_pg_type) GETSTRUCT(typeTup))->typname);
            av_store(av, i, newSVpv( typname , 0));
            ReleaseSysCache(typeTup);
        }
    } 
    else if (kl==13 && strEQ(key, "pg_oid_status")) {
        retsv = newSViv(imp_sth->lastoid);
    } 
    else if (kl==13 && strEQ(key, "pg_cmd_status")) {
        retsv = newSVpv(imp_sth->status,0);
    } else {
        return Nullsv;
    }

    return sv_2mortal(retsv);
}


/* end of dbdimp.c */
