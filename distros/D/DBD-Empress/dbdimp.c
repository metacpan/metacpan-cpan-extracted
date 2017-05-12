#include	"Empress.h"
#include	"se.h"
#include	<stdlib.h>
#include	<stdio.h>

/* Local Functions */
static	void	clear_error (	SV *h);
static	void	set_error (	SV *h, 	char* errmsg);
static	void	set_msg   (	SV *h, 	char* msg);
static	void	dbd_preparse (imp_sth_t *imp_sth, char *statement);
static 	int _dbd_rebind_ph (SV *sth, imp_sth_t *imp_sth, phs_t *phs);
static int      dyn_sql_word (char*	  s);
static int      isquote (char*	  str);
static int      iscomment_std (char*    str);
static int      iscomment_ansi (char*   str);
static int      iscomment (char*	str);
static int      isitem (char*	   str);
static int      isnumber (char*	 str);
static int      isany (char*	    str);
static int      next_token 	(char *str, 
				char *token, 
				int *len,
				int *status);

#ifndef TRUE
#define TRUE  (1)
#define FALSE (0)
#endif

typedef struct keyitem
{
	char	key[32];
} keyitem;

static keyitem		keytab[] =
{
	{	"!="		},
	{	"!match"	},
	{	"!smatch"	},
	{	"abs"		},
	{	"add"		},
	{	"alias"		},
	{	"all"		},
	{	"alter"		},
	{	"and"		},
	{	"any"		},
	{	"as"		},
	{	"asc"		},
	{	"ascending"	},
	{	"at"		},
	{	"attr"		},
	{	"attribute"	},
	{	"avg"		},
	{	"before"	},
	{	"between"	},
	{	"by"		},
	{	"bypass"	},
	{	"bypass_lock"	},
	{	"byte_length"	},
	{	"ceiling"	},
	{	"center"	},
	{	"centre"	},
	{	"change"	},
	{	"check"		},
	{	"comment"	},
	{	"concat"	},
	{	"constraint"	},
	{	"convert"	},
	{	"count"		},
	{	"create"	},
	{	"current"	},
	{	"database"	},
	{	"datenext"	},
	{	"day"		},
	{	"dayname"	},
	{	"dayof"		},
	{	"dayofweek"	},
	{	"dayofyear"	},
	{	"days"		},
	{	"delete"	},
	{	"desc"		},
	{	"descending"	},
	{	"direct_from"	},
	{	"direct_into"	},
	{	"direct_onto"	},
	{	"display"	},
	{	"display_length"},
	{	"distinct"	},
	{	"do"		},
	{	"double"	},
	{	"drop"		},
	{	"dump"		},
	{	"edit"		},
	{	"empty"		},
	{	"end"		},
	{	"escape"	},
	{	"excl"		},
	{	"exclusive"	},
	{	"exists"	},
	{	"exit"		},
	{	"floor"		},
	{	"for"		},
	{	"from"		},
	{	"generic"	},
	{	"grant"		},
	{	"group"		},
	{	"having"	},
	{	"hour"		},
	{	"hourof"	},
	{	"hours"		},
	{	"in"		},
	{	"incl"		},
	{	"inclusive"	},
	{	"index"		},
	{	"input"		},
	{	"insert"	},
	{	"into"		},
	{	"is"		},
	{	"is_decimal"	},
	{	"is_integer"	},
	{	"is_white"	},
	{	"left"		},
	{	"leftright"	},
	{	"length"	},
	{	"level"		},
	{	"like"		},
	{	"list"		},
	{	"locate"	},
	{	"lock"		},
	{	"lpad"		},
	{	"lscan"		},
	{	"ltrim"		},
	{	"match"		},
	{	"max"		},
	{	"min"		},
	{	"minute"	},
	{	"minuteof"	},
	{	"minutes"	},
	{	"mode"		},
	{	"month"		},
	{	"monthof"	},
	{	"months"	},
	{	"move"		},
	{	"not"		},
	{	"now"		},
	{	"null"		},
	{	"nullval"	},
	{	"of"		},
	{	"on"		},
	{	"onto"		},
	{	"option"	},
	{	"or"		},
	{	"order"		},
	{	"outer"		},
	{	"picture"	},
	{	"precision"	},
	{	"print"		},
	{	"priv"		},
	{	"privilege"	},
	{	"range"		},
	{	"refer"		},
	{	"referential"	},
	{	"rename"	},
	{	"report"	},
	{	"revoke"	},
	{	"right"		},
	{	"round"		},
	{	"rpad"		},
	{	"rscan"		},
	{	"rstrindex"	},
	{	"rtrim"		},
	{	"run"		},
	{	"second"	},
	{	"secondof"	},
	{	"seconds"	},
	{	"select"	},
	{	"set"		},
	{	"share"		},
	{	"sign"		},
	{	"smatch"	},
	{	"some"		},
	{	"sort"		},
	{	"stddayname"	},
	{	"stop"		},
	{	"strdel"	},
	{	"strindex"	},
	{	"strins"	},
	{	"substr"	},
	{	"sum"		},
	{	"table"		},
	{	"to"		},
	{	"today"		},
	{	"tolower"	},
	{	"toupper"	},
	{	"trunc"		},
	{	"unique"	},
	{	"unset"		},
	{	"update"	},
	{	"user"		},
	{	"values"	},
	{	"view"		},
	{	"week"		},
	{	"weekofyear"	},
	{	"weeks"		},
	{	"where"		},
	{	"width"		},
	{	"with"		},
	{	"wrapmargin"	},
	{	"year"		},
	{	"yearof"	},
	{	"years"		},
	{	"~="		},
	{	"~match"	},
	{	"~smatc"	},
	{	"~smatch"	},
};
static int	keyztab = sizeof (keytab) / sizeof (keyitem);


DBISTATE_DECLARE;

/********************************************************************/
/* Interface to Empress.c (.xsi) */

void	dbd_init (
	dbistate_t *dbistate)
{
	DBIS = dbistate;
	if (dbis->debug > 1)
		se_Debug (dbis->debug - 1);
	(void) se_Init ();
}

int	dbd_db_login (
	SV 		*dbh,
	imp_dbh_t 	*imp_dbh,
	char 		*dbname,
	char 		*uid,
	char 		*pwd)
{
	se_return	retval;

	clear_error (dbh);

	if (uid && *uid)
		retval = se_ConnectUser (dbname, uid, pwd, &(imp_dbh->c_num));
	else
		retval = se_Connect (dbname, &(imp_dbh->c_num));

	if (retval != SE_OK)
	{
		set_error (dbh, "Connect Failed");
		return DBD_ERROR;
	}

/****************
	if (se_Autocommit (SE_TRUE, imp_dbh->c_num) != SE_OK)
	{	
		imp_dbh->autocommit = 0;	
		DBIc_set(imp_dbh,DBIcf_AutoCommit, 0);
		return DBD_ERROR;
	}
*****************/
	/* Autocommit is the default start with  Empress */

	imp_dbh->autocommit = 1;	
	DBIc_set(imp_dbh,DBIcf_AutoCommit, 1);
	DBIc_IMPSET_on(imp_dbh);
	DBIc_ACTIVE_on(imp_dbh); 
	return DBD_SUCCESS;
}

int	dbd_db_commit (
	SV 		*dbh,
	imp_dbh_t	*imp_dbh)
{
	clear_error (dbh);

	if (se_Commit (imp_dbh->c_num) != SE_OK)
	{
		set_error (dbh, "Commit Failed");
		return DBD_ERROR;
	}
	return DBD_SUCCESS;
}

int	dbd_db_rollback (
	SV 		*dbh,
	imp_dbh_t 	*imp_dbh)
{
	clear_error (dbh);

	if (se_Rollback (imp_dbh->c_num) != SE_OK)
	{
		set_error (dbh, "Rollback Failed");
		return DBD_ERROR;
	}
	return DBD_SUCCESS;
}

int	dbd_db_disconnect (
	SV 		*dbh,
	imp_dbh_t 	*imp_dbh)
{
        /* We assume that disconnect will always work   */
        /* since most errors imply already disconnected. */
        DBIc_ACTIVE_off(imp_dbh);
 
        if (se_Disconnect (imp_dbh->c_num) != SE_OK )
        {
                set_error (dbh, "Disconnect error");
                return DBD_ERROR;
        }
 
        /* We don't free imp_dbh since a reference still exists */
        /* The DESTROY method is the only one to 'free' memory. */
        /* Note that statement objects may still exist for this dbh */
 
        return DBD_SUCCESS;
}

void	dbd_db_destroy (
	SV 		*dbh,
	imp_dbh_t 	*imp_dbh)
{
        clear_error(dbh);
 
        /* if database handle is active, then we need to disconnect */
        /* from the DB first */
        if ( DBIc_ACTIVE(imp_dbh) )
		(void) dbd_db_disconnect (dbh, imp_dbh);
 
        /* Free anything in imp_dbh that needs it. */
/****
	se_Exit ();
*****/

	DBIc_IMPSET_off(imp_dbh);

        return;

}

int	dbd_db_STORE_attrib (
	SV 		*dbh,
	imp_dbh_t 	*imp_dbh,
	SV 		*keysv,
	SV 		*valuesv)
{
	STRLEN	kl;
	char *key = SvPV(keysv,kl);

	clear_error (dbh);

	/* for the moment we just have autocommit */
	if (!strcmp (key, "AutoCommit"))
	{
		if (se_Autocommit (SvTRUE(valuesv), imp_dbh->c_num) != SE_OK)
		{
			set_error (dbh, "STORE db attribute");
			return FALSE;
		}
		imp_dbh->autocommit = SvTRUE(valuesv);
		DBIc_set(imp_dbh, DBIcf_AutoCommit, SvTRUE(valuesv));
		return TRUE;
	}
	return FALSE;	
}


SV*	dbd_db_FETCH_attrib (
	SV 		*dbh,
	imp_dbh_t 	*imp_dbh,
	SV 		*keysv)
{
	STRLEN	kl;
	char 	*key = SvPV(keysv,kl);
	SV*	returnsv;
	char*	version;

	clear_error (dbh);

	/* for the moment we just have autocommit */
	if (!strcmp (key, "AutoCommit"))
	{
		returnsv = newSViv (imp_dbh->autocommit);
		return sv_2mortal (returnsv);
	}
	/* and version */
	else if (!strcmp (key, "Version"))
	{
		version = se_Version ();
		returnsv = newSVpv (version, strlen (version));
		return sv_2mortal (returnsv);
	}
	return Nullsv;	

}


int	dbd_st_prepare (
	SV 		*sth,
	imp_sth_t 	*imp_sth,
	char 		*statement,
	SV 		*attribs)
{
	int	st_num;
        D_imp_dbh_from_sth; /* generates imp_dbh */

	clear_error (sth);

        /* Describe and allocate storage for results.  */
        /* for now, 'attribs' is ignored */

	imp_sth->nrows = 0;

	/* preparse the SQL for parameters, record the parameters */
	/* and convert to '?' syntax if required */
	dbd_preparse (imp_sth, statement);

	st_num = se_Prepare (imp_dbh->c_num, imp_sth->statement, 
					DBIc_LongReadLen(imp_sth));
	if (st_num < 0)
	{
		set_error (sth, "Prepare Error");
		return DBD_ERROR;
	}
	imp_sth->st_num = st_num;
	DBIc_IMPSET_on(imp_sth);
	
	return DBD_SUCCESS;
}

int	dbd_st_rows (
	SV 		*sth,
	imp_sth_t 	*imp_sth)
{
	return imp_sth->nrows;
}

/* for execute DBI return values are <=-2:error, -1:unknown count, */
/*                                   >=0: rows affected */
int	dbd_st_execute (
	SV 		*sth,
	imp_sth_t 	*imp_sth)
{
	int		nfields;
	int		nrows;
	se_return	retval;

	clear_error (sth);

	if (se_Execute (imp_sth->st_num, DBIc_LongReadLen(imp_sth),
				&nfields, &nrows) == SE_FAIL)
	{
		set_error (sth, "SQL Statement Execution Failed");
		return -2;
	}
	imp_sth->nrows = nrows;
	DBIc_NUM_FIELDS(imp_sth) = nfields;

	/* DBI::ODBC indicates this MAY only be valid for SELECT */
	/* I agree so I've implemented that way */	
	/* -1 is UNLIKELY to be returned by anything other than */
	/* a select statement */
	if (nrows == -1)
		DBIc_ACTIVE_on(imp_sth);
	
	return nrows;
}

AV*	dbd_st_fetch (
	SV 		*sth,
	imp_sth_t 	*imp_sth)
{
	AV		*av;
	int		chop_blanks;
	SeRecord*	field;
	int		index;
	int		num_fields;
	unsigned char*	ptr;
	unsigned char*	ptr2;
	SeRecord*	record;
	se_return	retval;
	SV		*sv;

	clear_error (sth);

	if (!DBIc_ACTIVE(imp_sth)) 	
	{
		set_error(sth, "No Statement Active");
		return Nullav;
	}

	retval = se_Fetch (imp_sth->st_num, &record, &num_fields);

	/* se_Fetch may return SE_OK, SE_FAIL, SE_NOREC, or SE_LOCKEDREC */
	/* all but SE_OK should set a message and return a NULL AV */
	if (retval != SE_OK)
	{
		switch (retval)
		{
       			case SE_NOREC:
				dbd_st_finish (sth, imp_sth);
                                break;
           		case SE_LOCKEDREC:
                       		set_error (sth, "Fetch: record locked");
     				break;
     			default:
      				set_error(sth, "Fetch: error");
     				break;
     		}
		return Nullav;
	}

	DBIc_NUM_FIELDS(imp_sth) = num_fields;

	/* lets start counting the rows as they are fetched! */
	if (imp_sth->nrows == -1)
		imp_sth->nrows = 0;
	imp_sth->nrows++;

	/* get the AV structure */
	av = DBIS->get_fbav(imp_sth);

	chop_blanks = DBIc_has(imp_sth, DBIcf_ChopBlanks);
	
	index = 0;
	for (field = record, index = 0; 
			field && index < num_fields; 
			field = field->next, index++)
	{
		sv = AvARRAY(av)[index];

		/* NULL Data */
		if (field->length == 0)
		{
			SvOK_off(sv);
		}

		/* if we want to chop blanks from none binary data we can */
		/* do it here */	
		else if (chop_blanks && field->attr_type != SE_BINARY)
		{
			for (ptr = field->value; *ptr == ' '; ptr++);
			for (ptr2 = &(field->value[field->length -1]);
				*ptr2 == ' '; ptr2--);
			if (ptr2 > ptr)
				sv_setpvn (sv, (char*)ptr, ptr2-ptr+1);
			else
				SvOK_off(sv);
		}

		/* otherwise place the data in the output */
		else
		{
			sv_setpvn(sv, (char*)field->value, field->length);
		}		
	}

	return av;
}

int	dbd_st_finish (
	SV 		*sth,
	imp_sth_t 	*imp_sth)
{
	clear_error (sth);

	if (DBIc_ACTIVE(imp_sth))
	{
		DBIc_ACTIVE_off(imp_sth);
		if (se_Finish (imp_sth->st_num) != SE_OK)
		{
			set_error (sth, "Finish Failed");
			return DBD_ERROR;
		}
	}
	return DBD_SUCCESS;
}

void	dbd_st_destroy (
	SV 		*sth,
	imp_sth_t 	*imp_sth)
{
	(void) dbd_st_finish (sth, imp_sth);
	se_DestroyStatement (imp_sth->st_num);
	Safefree(imp_sth->statement);

	DBIc_IMPSET_off(imp_sth);
	return;
}

int	dbd_st_blob_read (
	SV 		*sth,
	imp_sth_t 	*imp_sth,
	int 		field,
	long 		offset,
	long 		len,
	SV 		*destrv,
	long 		destoffset)
{
/***********************************************************************
**Not Implemented Yet
	if (se_FetchChunk (sth->stname, field+1, offset, len, attribute)
					!= SE_OK)
	{
		set_error (sth, "Blob Read Failed");
		return DBD_ERROR;
	}
************************************************************************/
	return DBD_SUCCESS;
}

int	dbd_st_STORE_attrib (
	SV 		*sth,
	imp_sth_t 	*imp_sth,
	SV 		*keysv,
	SV 		*valuesv)
{
	/* as far as I know there is nothing we can set here */
	/* so do nothing */

	return 0;
}

SV*	dbd_st_FETCH_attrib (
	SV 		*sth,
	imp_sth_t 	*imp_sth,
	SV 		*keysv)
{
	const	char*	options [] = {
		"NUM_PARAMS",
		"NUM_FIELDS",
		"CursorName",
		"NAME",
		"NULLABLE",
		"TYPE",
		"PRECISION",
		"SCALE"};
	int	nopts = 8;

	AV*		av;
	char*		cname;
	int		i;
	int		index;	
	STRLEN		kl;
	char 		*key 		= SvPV(keysv,kl);
	int		num_fields 	= DBIc_NUM_FIELDS(imp_sth);
	SeRecord*	ptr;
	SeRecord*	record;
	SV*		returnsv	= NULL;

	for (index = 0; index < nopts; index++)
	{
		if (!strcmp (options [index], key))
			break;
	}
	if (index >= nopts)
		return Nullsv;

	/* First Three are statement info */
	if (index < 3)
	{
	    	switch (index)
	    	{
			case 0:	
				/* according to DBI::ODBC this is handled */
				/* by DBI therefore ignore it! */
				return Nullsv;
				break;
			case 1:
				returnsv = newSViv (num_fields);
				break;
			case 2:
				cname = se_GetCursorName (imp_sth->st_num);
				if (cname)
					returnsv = newSVpv (cname, 
								strlen (cname));
				else
					return Nullsv;	
				break;
		}
	}
	/* rest are attribute info */
	else 
	{
		record = se_GetAttributeInfo (imp_sth->st_num);
		if (!record)
			return Nullsv;
		
		av = newAV ();
		returnsv = newRV(sv_2mortal((SV*)av));
		
		switch (index)
		{
			case 3:
				for (i = 0, ptr = record; i < num_fields && ptr; 
						i++, ptr = ptr->next)
				    av_store (av, i, newSVpv(ptr->attr_name,0));
				break;
			case 4:
				for (i = 0, ptr = record; i < num_fields && ptr; 
						i++, ptr = ptr->next)
				    av_store (av, i, newSViv(ptr->nullable));
				break;
			case 5:
				for (i = 0, ptr = record; i < num_fields && ptr; 
						i++, ptr = ptr->next)
				    av_store (av, i, newSViv(ptr->attr_type));
				break;
			case 6:
				for (i = 0, ptr = record; i < num_fields && ptr; 
						i++, ptr = ptr->next)
				    av_store (av, i, newSViv(ptr->precision));
				break;
			case 7:
				for (i = 0, ptr = record; i < num_fields && ptr; 
						i++, ptr = ptr->next)
				    av_store (av, i, newSViv(ptr->scale));
				break;
		}
	}
	return sv_2mortal(returnsv);
}

int	dbd_describe (
	SV 		*h,
	imp_sth_t 	*imp_sth)
{
	int	num_fields;

	if (se_BindAttributes (imp_sth->st_num, DBIc_LongReadLen(imp_sth),
						&num_fields) != SE_OK)
	{
		set_error (h, "Describe Error");
		return DBD_ERROR;
	}
	DBIc_NUM_FIELDS (imp_sth) = num_fields;
}

int	dbd_discon_all (
	SV		*drh,
	imp_drh_t	*imp_drh)
{
/***********************************
	(void) se_DisconnectAll ();
*********************************/
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


/*------------------------------------------------------------------------
* Local Functions */
static	void	clear_error (
	SV	*h)
{
        D_imp_xxh(h);
/*** 
        sv_setiv (DBIc_ERR(imp_xxh),(IV)0);
        sv_setpv (DBIc_ERRSTR(imp_xxh),(char *)"");
        sv_setpv (DBIc_STATE(imp_xxh),(char *)"");
***/
 
        return;
}
 
static	void	set_error (
	SV	*h,
	char*	errmsg)
{
        D_imp_xxh(h);
	
	set_msg (h, errmsg);
        
	sv_setiv (DBIc_ERR(imp_xxh), 	(IV) se_errcode);
        sv_setpv (DBIc_STATE(imp_xxh), (char *) se_state);
 
        DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), DBIc_ERRSTR(imp_xxh));
 
        return;
}


static	void	set_msg (
	SV	*h,
	char*	errmsg)
{
        D_imp_xxh(h);
 
        sv_setpv (DBIc_ERRSTR(imp_xxh), (char *) errmsg);
 
        if ( se_errmsg != (char *)0 )
        {
                sv_catpv (DBIc_ERRSTR(imp_xxh), ": ");
                sv_catpv (DBIc_ERRSTR(imp_xxh), se_errmsg);
        }
 
        return;
}

#define OTHER   0
#define STRING  1
#define ALPHA   2
#define NUMBER  3
#define COLON   4

/*------------------------------------------------------------------------
Straight Copy from DBI::ODBC v0.16
-------------------------------------------------------------------------*/
static	void	dbd_preparse(
    imp_sth_t 	*imp_sth,
    char 	*statement)
{
    char 	*src;
    phs_t 	phs_tpl, *phs;
    SV 		*phs_sv;
    int 	idx=0, style=0, laststyle=0;
    int 	param = 0;
    int 	namelen;
    char 	name[256];
    SV 		**svpp;
    char 	ch;

    int		status[10];
    int		pos[10];
    int		curstatus;
    int		count;
    bool	flag;

    /* allocate room for copy of statement with spare capacity	*/
    imp_sth->statement = (char*)safemalloc(strlen(statement)+1);
    count = 0;

    /* initialize phs ready to be cloned per placeholder	*/
    memset(&phs_tpl, 0, sizeof(phs_tpl));
    phs_tpl.ftype = 1;	/* VARCHAR2 */
    phs_tpl.sv = &sv_undef;

    src  = statement;
    *imp_sth->statement = '\0';

    /* skip the space and tab key */
    while (*src == ' ' || *src == '\t')
    	src++;

    while( next_token (src, name, &namelen, &curstatus)) {
	status [count%10] = curstatus;
	pos [count%10] = strlen (imp_sth->statement);
	flag = 0;

	if ((curstatus == ALPHA || curstatus == NUMBER) &&
	    count > 0 && status[(count-1)%10] == COLON)
	{
	    if (curstatus == ALPHA && 
	    	count > 1 && 
		(status[(count-2)%10] == ALPHA || 
		 status[(count-2)%10] == STRING))
	    {
	    	count++;
		if (namelen >= 255)
			strncat (imp_sth->statement, src, namelen);
		else
			strcat (imp_sth->statement, name);
	    }
	    else
	    {
	    	strcpy (imp_sth->statement+pos[(count-1)%10], "?");
		status[(count-1)%10] = OTHER;
		if (curstatus == NUMBER)
		{
		    idx = atoi(name);
		    style = 1;
		}	
		else
		    style = 2;

		flag = 1;
	    }
	}
	else
	{
	    count++;
	    if (namelen >= 255)
		strncat (imp_sth->statement, src, namelen);
	    else
	    	strcat (imp_sth->statement, name);

	    if (strcmp (name, "?") == 0)	/* X/Open standard	*/ 
	    {
	    	idx++;
		sprintf (name, "%d", idx);
		style = 3;
		flag = 1;
	    }
	}

	src = src + namelen;
	if (*src == ' ' || *src == '\t')
		strcat (imp_sth->statement, " ");

	while (*src == ' ' || *src == '\t')
		src++;
	
	if (!flag)
		continue;

	if (laststyle && style != laststyle)
	    croak("Can't mix placeholder styles (%d/%d)",style,laststyle);
	laststyle = style;

	if (imp_sth->all_params_hv == NULL)
	    imp_sth->all_params_hv = newHV();
	namelen = strlen(name);

	svpp = hv_fetch(imp_sth->all_params_hv, name, namelen, 0);
	if (svpp == NULL) {
	    /* create SV holding the placeholder */
	    phs_sv = newSVpv((char*)&phs_tpl, sizeof(phs_tpl)+namelen+1);
	    phs = (phs_t*)SvPVX(phs_sv);
	    strcpy(phs->name, name);
	    phs->idx = idx;

	    /* store placeholder to all_params_hv */
	    svpp = hv_store(imp_sth->all_params_hv, name, namelen, phs_sv, 0);
	}
    }

    if (imp_sth->all_params_hv) {
	DBIc_NUM_PARAMS(imp_sth) = (int)HvKEYS(imp_sth->all_params_hv);
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP, "    dbd_preparse scanned %d distinct placeholders\n",
		(int)DBIc_NUM_PARAMS(imp_sth));
    }
}


/*------------------------------------------------------------
 * bind placeholder.
 *  Is called from ODBC.xs execute()
 *  AND from ODBC.xs bind_param()
 */
int dbd_bind_ph (
	SV 		*sth,
	imp_sth_t 	*imp_sth,
	SV 		*ph_namesv,  /* index of execute() parameter 1..n */
	SV 		*newvalue,
	IV 		sql_type,
	SV 		*attribs,    /* may be set by Solid.xs bind_param call */
	int 		is_inout,    /* inout for procedure calls only */
	IV 		maxlen)	     /* ??? */
{
    SV **phs_svp;
    STRLEN name_len;
    char *name;
    char namebuf[30];
    phs_t *phs;

    if (SvNIOK(ph_namesv) ) {	/* passed as a number	*/
	name = namebuf;
	sprintf(name, "%d", (int)SvIV(ph_namesv));
	name_len = strlen(name);
    } 
    else {
	name = SvPV(ph_namesv, name_len);
    }

    if (SvTYPE(newvalue) > SVt_PVMG)    /* hook for later array logic   */
        croak("Can't bind non-scalar value (currently)");

    if (dbis->debug >= 2)
	fprintf(DBILOGFP, "bind %s <== '%.200s' (attribs: %s)\n",
		name, SvPV(newvalue,na), attribs ? SvPV(attribs,na) : "" );

    phs_svp = hv_fetch(imp_sth->all_params_hv, name, name_len, 0);
    if (phs_svp == NULL)
	croak("Can't bind unknown placeholder '%s'", name);
    phs = (phs_t*)SvPVX(*phs_svp);	/* placeholder struct	*/

    if (phs->sv == &sv_undef) { /* first bind for this placeholder      */
        phs->ftype    = 0;     /* our default type VARCHAR2    */
	phs->sql_type = (sql_type) ? sql_type : SQL_VARCHAR;
        phs->maxlen   = maxlen;         /* 0 if not inout               */
        phs->is_inout = is_inout;
        if (is_inout) {
            phs->sv = SvREFCNT_inc(newvalue);   /* point to live var    */
            ++imp_sth->has_inout_params;
            /* build array of phs's so we can deal with out vars fast   */
            if (!imp_sth->out_params_av)
                imp_sth->out_params_av = newAV();
            av_push(imp_sth->out_params_av, SvREFCNT_inc(*phs_svp));
        }
 
        /* some types require the trailing null included in the length. */
        phs->alen_incnull = 0; /*Oracle:(phs->ftype==SQLT_STR || phs->ftype==SQLT_AVC);*/
 
    }
        /* check later rebinds for any changes */
    else if (is_inout || phs->is_inout) {
        croak("Can't rebind or change param %s in/out mode after first bind", phs->name);
    }
    else if (maxlen && maxlen != phs->maxlen) {
        croak("Can't change param %s maxlen (%ld->%ld) after first bind",
                        phs->name, phs->maxlen, maxlen);
    }
 
    if (!is_inout) {    /* normal bind to take a (new) copy of current value    */
        if (phs->sv == &sv_undef)       /* (first time bind) */
            phs->sv = newSV(0);
        sv_setsv(phs->sv, newvalue);
    }
 
    return _dbd_rebind_ph(sth, imp_sth, phs);
}

static int _dbd_rebind_ph( 
	SV 		*sth,
	imp_sth_t 	*imp_sth,
	phs_t 		*phs)
{
	long		count;
    	STRLEN 		value_len;
	unsigned char*	rgbValue;
	int		type;

    if (dbis->debug >= 2) {
        char *text = neatsvpv(phs->sv,0);
        fprintf(DBILOGFP, "bind %s <== %s (size %d/%d/%ld, ptype %ld, otype %d)\n",
            phs->name, text, SvCUR(phs->sv),SvLEN(phs->sv),phs->maxlen,
            SvTYPE(phs->sv), phs->ftype);
    }
 
    /* At the moment we always do sv_setsv() and rebind.        */
    /* Later we may optimise this so that more often we can     */
    /* just copy the value & length over and not rebind.        */
 
    if (phs->is_inout) {        /* XXX */
        if (SvREADONLY(phs->sv))
            croak(no_modify);
        /* phs->sv _is_ the real live variable, it may 'mutate' later   */
        /* pre-upgrade high to reduce risk of SvPVX realloc/move        */
        (void)SvUPGRADE(phs->sv, SVt_PVNV);
        /* ensure room for result, 28 is magic number (see sv_2pv)      */
        SvGROW(phs->sv, (phs->maxlen < 28) ? 28 : phs->maxlen+1);
    }
    else {
        /* phs->sv is copy of real variable, upgrade to at least string */
        (void)SvUPGRADE(phs->sv, SVt_PV);
    }
 
    /* At this point phs->sv must be at least a PV with a valid buffer, */
    /* even if it's undef (null)                                        */
    /* Here we set phs->sv_buf, and value_len.                */
    if (SvOK(phs->sv)) {
        phs->sv_buf = SvPV(phs->sv, value_len);
    }
    else {      /* it's null but point to buffer incase it's an out var */
        phs->sv_buf = SvPVX(phs->sv);
        value_len   = 0;
    }
    phs->sv_type = SvTYPE(phs->sv);     /* part of mutation check       */
    phs->maxlen  = SvLEN(phs->sv)-1;    /* avail buffer space   */
    /* value_len has current value length */

    if (dbis->debug >= 3) {
        fprintf(DBILOGFP, "bind %s <== '%.100s' (size %d, ok %d)\n",
            phs->name, phs->sv_buf, (long)phs->maxlen, SvOK(phs->sv)?1:0);
    }

    	if (!SvOK(phs->sv)) {
		rgbValue = NULL;
   	 }
    	else {
		STRLEN len;
		rgbValue = (unsigned char*)phs->sv_buf;
		phs->cbValue = (long)value_len;
    	}

	/* This is a guessing game; but it will have to do for now! */
	type = SE_CHAR;
	if (rgbValue && value_len > 0)
	{
		if (rgbValue [value_len] != 0x00)
		{
			type = SE_BINARY;
		}
		else
		{
			for (count = 0; count < value_len; count++)
			{
				if (rgbValue [count] == 0x00)
				{
					type = SE_BINARY;
					break;
				}			
			}
		}
	}
	if (se_BindParameter (imp_sth->st_num, phs->idx, 
					type,
					rgbValue, value_len,
					&phs->cbValue)
									!= SE_OK)
	{
		set_error (sth, "_rebind_ph/BindParameter");
		return DBD_ERROR;
	}
	return DBD_SUCCESS;
}


/**** end of dbdimp.c****/


static int	dyn_sql_word (char*		s)
{
	int	i;
	int	comp;
	int	high;
	int	low;

	low = 0;
	high = keyztab;

	while (low <= high)
	{
		i = (low+high)/2;
		comp = strcasecmp(s, keytab[i].key);
		if (comp == 0)
			return (1);
		else if (comp < 0)
			high = i - 1;
		else
			low = i + 1;
	}

	return (0);
}

static int	isquote (char*		str)
{
	int	i;

	if (*str != '\'')
		return (0);

	i = 1;
	while (*(str+i) != '\0' && *(str+i) != '\'')
		i++;
	
	if (*(str+i) == '\'')
		return (i+1);
	
	return (0);
}

static int	iscomment_std (char*	str)
{
	int	i;

	if (*str != '/')
		return (0);
	
	if (*(str+1) != '*')
		return (0);

	i = 2;

	while (*(str+i) != '\0')  
	{
		if (*(str+i) == '*' &&
		    *(str+i+1) == '/')
		    	return (i+2);

		i++;
	}

	return (0);
}

static int	iscomment_ansi (char*	str)
{
	if (*str != '-')
		return (0);
	
	if (*(str+1) != '-')
		return (0);
	
	return (strlen(str));
}

static int	iscomment (char*	str)
{
	int	i;

	if ((i = iscomment_std (str)) > 0)
		return (i);
	else if ((i = iscomment_ansi (str)) > 0)
		return (i);
	
	return (0);
}

static int	isitem (char*		str)
{
	char*	s;
	
	if (*str == '~' || *str == '!')
	{
		if (*(str+1) == '=')
			return (1);

		s = str+1;
	}
	else
		s = str;

	if (! isalpha(*s) && *s != '_')
		return (0);
	
	s++;

	while (isalpha(*s) || isdigit(*s) || *s == '_')
		s++;
	
	return (s - str);
}

static int	isnumber (char*		str)
{
	int	i;

	i = 0;
	while (isdigit(*(str+i)))
		i++;
	
	return (i);
}

static int	isany (char*		str)
{
	int	i;

	i = 1;
	switch (*(str+i))
	{
	case '<':
		if (*(str+1) == '>' ||
		    *(str+1) == '=')
			i = 2;
		break;
	case '>':
		if (*(str+1) == '=')
			i = 2;
		break;
	}

	return (i);
}

static int 	next_token (char *str, char *token, int *len,int *status)
{
    	int  	i;
	int	j;

	
	if (*str == '\0')
	{
		*len = 0;
		return (0);
	}

	i = isquote (str); 
	if (i > 0)
	{
		*len = i;
		if (i >= 255)
			i = 255;

		strncpy (token, str, i);
		*(token+i) = '\0';
    		*status = STRING;
		return (1);
	}

	i = iscomment (str);
	if (i > 0)
	{
		*len = i;
		if (i >= 255)
			i = 255;

		strncpy (token, str, i);
		*(token+i) = '\0';
    		*status = OTHER;
		return (1);
	}

	i = isitem (str);
	if (i > 0)
	{
		*len = i;
		if (i >= 255)
			i = 255;

		strncpy (token, str, i);
		*(token+i) = '\0';

		if (dyn_sql_word (token))
			*status = OTHER;
		else
			*status = ALPHA;

		return (1);
	}

	i = isnumber (str);
	if (i > 0)
	{
		if ( (*(str+i) == '.') &&
		     ((j = isnumber(str+i+1)) > 0))
		{
			*len = i = i+j+1;
			if (i >= 255)
				i = 255;
			strncpy(token, str, i);
			*(token+i) = '\0';
			*status = OTHER;
		}
		else
		{
			*len = i;
			if (i >= 255)
				i = 255;
			strncpy (token, str, i);
			*(token+i) = '\0';
			*status = NUMBER;
		}
	
		return (1);
	}

	i = isany (str);
	*len = i;
	if (i >= 255)
		i = 255;

	strncpy (token, str, i);
	*(token+i) = '\0';

	if (strcmp (token, ":") == 0)
		*status = COLON;
	else
		*status = OTHER;

	return (1);
}
