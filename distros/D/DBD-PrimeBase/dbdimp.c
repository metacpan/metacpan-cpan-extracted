/* $Id: dbdimp.c,v 1.4001 2001/07/30
 * 
 * portions Copyright (c) 1994,1995,1996,1997  Tim Bunce
 * portions Copyright (c) 1997 Thomas K. Wenrich
 * portions Copyright (c) 1997 Jeff Urlwin
 * portions Copyright (c) 2001 SNAP Innovation
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 *
 */

#include "PrimeBase.h"
#include "pbapi.h"		/* The PrimeBase API functions. */

/* These just make it clear what is global and what isn't. */
#define PUBLIC
#define PRIVATE static
#define FAILED	0
#define OK		1

DBISTATE_DECLARE;

#define MAX_SMALL_BIND	64

typedef struct {
	char name[32];
	short pb_type;
	short odbc_type;
	long length;
	long display_size; /* C string length. */
	
	long precision;
	long scale;	
	
	char *type_name;
	
	/* Bind info. */
	unsigned int 	b_info;	/* After fetch this will contain the actual data size. */
	unsigned int 	b_size;	/* The size of the bound buffer. */
	char 			*bind;	/* A pointer to the bound buffer. */
	char			small_bind[MAX_SMALL_BIND];	/* A bind buffer for small values. */
} ColInfo, *ColInfoPtr;

PRIVATE FILE *trace_f;
PRIVATE unsigned long total_time;
PRIVATE struct timeval start_time, end_time;

/*#define DO_TRACE */
/*#define DO_TIMING */
/*#define DEBUG_IT */


#ifdef DO_TIMING
#define START_TIMER {memset(&start_time, 0, sizeof(start_time));memset(&end_time, 0, sizeof(end_time)); gettimeofday(&start_time, NULL);}
#define END_TIMER {\
gettimeofday(&end_time, NULL); \
if (start_time.tv_sec != end_time.tv_sec) \
	total_time += (end_time.tv_sec - start_time.tv_sec) * 1000000 - start_time.tv_usec + end_time.tv_usec;\
else\
	total_time += end_time.tv_usec - start_time.tv_usec;\
}
#else
#define START_TIMER 
#define END_TIMER 
#endif

/*################################################################################# */
/* Some usefull PBT functions. (Always debug these as a script before hard coding them.) */
static char *NewPerlDatabase = "\n\
procedure NewPerlDatabase(dbname)\n\
argument varchar dbname;\n\
{\n\
boolean found = $FALSE;\n\
\n\
	describe databases;\n\
	for each {\n\
		if (->name = dbname)\n\
			found = $TRUE;\n\
	}\n\
	\n\
	if ( NOT found ) {\n\
		create database :dbname;\n\
	}\n\
	\n\
	open database :dbname;\n\
}\n\
end procedure NewPerlDatabase;\n\
";


static char *table_info = "\n\
procedure table_info()\n\
returns cursor;\n\
{\n\
varchar tname;\n\
cursor c;\n\
\n\
describe tables;\n\
\n\
select varchar[32]'' as TABLE_CAT, \n\
varchar[32]'' as TABLE_SCHEMA, \n\
varchar[32]'' as TABLE_NAME, \n\
varchar[32]'' as TABLE_TYPE, \n\
varchar[120]'' as REMARKS where $false into c;\n\
\n\
for each {\n\
	if (->type = 'T') \n\
		tname = 'TABLE';\n\
	else\n\
		tname = 'VIEW';\n\
\n\
	$insertrow(c, $NULL, ->owner, ->name, tname, $NULL);\n\
}\n\
\n\
fetch first of c;\n\
fetch previous of c;\n\
\n\
return c;\n\
}\n\
end procedure table_info;\n\
";


/*################################################################################# */
PRIVATE void do_warn(SV* h, int rc, char* what) {
    D_imp_xxh(h);
    STRLEN lna;

    SV *errstr = DBIc_ERRSTR(imp_xxh);
    sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);        /* set err early        */
    sv_setpv(errstr, what);
    DBIh_EVENT2(h, WARN_event, DBIc_ERR(imp_xxh), errstr);
    if (dbis->debug >= 2)
        PerlIO_printf(DBILOGFP, "%s warning %d recorded: %s\n", what, rc, SvPV(errstr,lna));
    warn("%s", what);
}


/*----------------------------------------------------*/
PRIVATE void  dbi_error(SV *h, int rc, char *what)
{
D_imp_xxh(h);
SV *errstr = DBIc_ERRSTR(imp_xxh);

#ifdef DEBUG_IT
	PerlIO_printf(DBILOGFP, "PrimeBase DBD Error: \"%s\"\n", what);
#else
	if (DBIS->debug > 2) 
		PerlIO_printf(DBILOGFP, "PrimeBase DBD Error: \"%s\"\n", what);
#endif

	sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);
 
	sv_setpv(errstr, what);
    DBIh_EVENT2(h, ERROR_event, DBIc_ERR(imp_xxh), errstr);
}

/*----------------------------------------------------*/
PRIVATE void  pb_error(SV *h, imp_dbh_t *imp_dbh)
{
long perr, serr;
char msg[256];


	PBIGetError(imp_dbh->sessid, &perr, &serr, msg, 256);
	if (!imp_dbh->auto_commit) /* Restart the transaction. */
		PBIExecute(imp_dbh->sessid, "begin;", PB_NTS, PB_EXECUTE_LATER, NULL, NULL, NULL);/* Delay the begin until the next statement. */

	dbi_error(h, perr, msg);
}

/*----------------------------------------------------*/
PRIVATE void  * my_malloc(SV *h, unsigned long size)
{
void *ptr;

	ptr = safemalloc(size);
	if (!ptr)
		dbi_error(h, -1, "Out Of Memory");
		
	return ptr; 
}

/*----------------------------------------------------*/
PRIVATE int my_realloc(SV *h, void **old_ptr, unsigned long size)
{
void *ptr;

	ptr = saferealloc(*old_ptr, size);
	if (!ptr)
		dbi_error(h, -1, "Out Of Memory");
	else
		*old_ptr = ptr;
				
	return (ptr != NULL); 
}

/*----------------------------------------------------*/
PRIVATE void  my_free(void *ptr)
{
	if (ptr)
		safefree(ptr);
}


/*-----------------------------------------------------------------------------------------*/
PRIVATE void ODBC_fixup(ColInfoPtr info, imp_sth_t *imp_sth)
{
	switch ( info->pb_type)
	{
	   case PB_BOOLEAN:
			info->odbc_type = SQL_BIT;
			info->type_name = "BOOLEAN";
			info->precision = 1;
			info->scale = 0;
			info->length = 1;
			break;
	   case PB_SMINT:
			info->odbc_type = 5;
			info->type_name = "SMINT";
			info->precision = 5;
			info->scale = 0;
			info->length = 2;
			break;
	   case PB_INTEGER:
			info->odbc_type = 4;
			info->type_name = "INT";
			info->precision = 10;
			info->scale = 0;
			info->length = 4;
			break;
	   case PB_SMFLOAT:
			info->odbc_type = 7;
			info->type_name = "SMFLOAT";
			info->precision = 7;
			info->scale = 0;
			info->length = 4;
			break;
	   case PB_FLOAT:
			info->odbc_type = 8;
			info->type_name = "DOUBLE";
			info->precision = 15;
			info->scale = 0;
			info->length = 8;
			break;
	   case PB_DATE:
			info->odbc_type = 9;
			info->type_name = "DATE";
			info->precision = 10;
			info->scale = 0;
			info->length = 6;
			break;
	   case PB_TIME:
			info->odbc_type = 10;
			info->type_name = "TIME";
			info->precision = 8;
			info->scale = 0;
			info->length = 6;
			break;
	   case PB_TIMESTAMP:
			info->odbc_type = 11;
			info->type_name = "TIMESTAMP";
			info->precision = 22;
			info->scale = 2;
			info->length = 16;
			break;
	   case PB_CHAR:
			info->odbc_type = 1;
			info->type_name = "CHAR";
			info->length = info->precision;
			break;
	   case PB_DECIMAL:
			info->odbc_type = 3;
			info->type_name = "DECIMAL";
			info->length = info->precision + 2;
			break;
	   case PB_MONEY:
			info->odbc_type = -81;
			info->type_name = "MONEY";
			info->length = info->precision + 2;
			break;
	   case PB_VCHAR:
			info->odbc_type = 12;
			info->type_name = "VARCHAR";
			info->length = info->precision;
			break;
	   case PB_VBIN:
			info->odbc_type = -3;
			info->type_name = "VARBIN";
			info->length = info->precision;
			break;
	   case PB_LCHAR:
			info->odbc_type = -1;
			info->type_name = "LONGCHAR";
			info->length = -4;		/* -4 SQL_NO_TOTAL */
			info->precision = -4;		/* -4 SQL_NO_TOTAL */
			info->display_size = imp_sth->max_blob;
			break;
	   case PB_LBIN:
			info->odbc_type = -4;
			info->type_name = "LONGBIN";
			info->length = -4;		/* -4 SQL_NO_TOTAL */
			info->precision = -4;		/* -4 SQL_NO_TOTAL */
			info->display_size = imp_sth->max_blob;
			break;
	   case PB_UINT2:
			info->odbc_type = 5;
			info->type_name = "SMINT";
			info->precision = 5;
			info->scale = 0;
			info->length = 2;
			break;
	   case PB_BIN:
			info->odbc_type = 1;
			info->type_name = "BINARY";
			info->length = info->precision;
			break;
			
	   case PB_UNICODE:
			info->odbc_type = -8;
			info->type_name = "UNICODE";
			info->length = info->precision;
			break;
	}
	
}

/*----------------------------------------------------*/
PRIVATE void free_column_info(long sessid, unsigned long cursor_id, ColInfoPtr col_ptr, long num_columns)
{
ColInfoPtr ptr = col_ptr;

	/*PBISetCursorState(sessid, cursor_id, PB_CURSOR_FREE); */
	
	if (!col_ptr)
		return;
		
	while (num_columns) {
		if (ptr->bind) {
			
			if (ptr->bind != ptr->small_bind)
				my_free(ptr->bind);
		}
		ptr++;
		num_columns--;			
	}
		
	my_free(col_ptr);
}

/*----------------------------------------------------*/
PRIVATE ColInfoPtr  get_column_info(SV *sth, imp_sth_t *imp_sth, long sessid, unsigned long cursor_id, long num_columns)
{
ColInfoPtr info_list, ptr;
PBColumnInfo info;
PBDataFmt pbtype;
int i, rtc;

	info_list = my_malloc(sth, num_columns * sizeof(ColInfo));
	if (!info_list)
		return NULL;
		
	ptr = info_list;
	for (i = 1; i <= num_columns; i++, ptr++) {
		rtc = PBIColumnInfo(sessid, cursor_id, i, &pbtype, &info);
		if (rtc != PB_OK) {
			D_imp_dbh_from_sth;
			if (DBIS->debug >= 2)
				PerlIO_printf(DBILOGFP, "get_column_info:PBIColumnInfo() Failed\n");
				
			free_column_info(sessid, cursor_id, info_list, num_columns);
			pb_error(sth, imp_dbh);
			return NULL;
		}
		
		strcpy(ptr->name, info.name);
		ptr->display_size = info.width;
		
		
		ptr->pb_type = pbtype.type;
		ptr->length = pbtype.len;
		ptr->precision = pbtype.precision;
		ptr->scale = pbtype.scale;

		ODBC_fixup(ptr, imp_sth);
		
		/* Bind the column. */
		ptr->b_size = ptr->display_size +1; /* Add 1 for NULL terminator. */
		ptr->bind = NULL;
		if (ptr->b_size) { /* Blobs may have a size of 0 if they are not to be bound. */
			if (ptr->b_size > MAX_SMALL_BIND) {
				ptr->bind = my_malloc(sth, ptr->b_size);
				if (!ptr->bind) {
					free_column_info(sessid, cursor_id, info_list, num_columns);
					return NULL;
				}
			} else 
				ptr->bind = ptr->small_bind;
				
			pbtype.type = PB_CSTRING;
			pbtype.len = ptr->b_size;
			
			rtc = PBIBindColumn(sessid, cursor_id, i, &pbtype, ptr->bind, 0, &(ptr->b_info), sizeof(ptr->b_info), 0);
			if (rtc != PB_OK) {
				D_imp_dbh_from_sth;
				if (DBIS->debug >= 2)
					PerlIO_printf(DBILOGFP, "get_column_info:PBIBindColumn() Failed inffo = %d\n", ptr->b_info);
					
				free_column_info(sessid, cursor_id, info_list, num_columns);
				pb_error(sth, imp_dbh);
				return NULL;
			}
		}
	}
	
	return 	info_list;
}


/*----------------------------------------------------*/
PUBLIC void dbd_init(dbistate_t *dbistate)
{
    DBIS = dbistate;
    PBIInit(FALSE);		/* Initialize the PrimeBase API: FALSE -> Debug tracing off. */
#ifdef  DO_TRACE
 trace_f =  fopen("DBDTrace.log", "a");
#endif
	total_time = 0;
}


/*----------------------------------------------------*/
PUBLIC int dbd_discon_all(SV *drh, imp_drh_t *imp_drh)
{
    PBIDeinit();	/* This will disconnect everybody. */
    PBIInit(FALSE);
     
	if (total_time) {
		printf("\nTotal time taken: %d Seconds, %d msec\n\n", total_time/ 1000000, total_time% 1000000);
		total_time = 0;
	}
    return OK;
}


/*----------------------------------------------------*/
PUBLIC void dbd_db_destroy(SV *dbh, imp_dbh_t *imp_dbh)
{
    if (trace_f) {fprintf(trace_f, " dbd_db_destroy: PBIDisconnect() \n"); trace_f = freopen("DBDTrace.log", "a", trace_f);}
	PBIDisconnect(imp_dbh->sessid);
/*
    if (DBIc_ACTIVE(imp_dbh)) {
    	if (trace_f) {fprintf(trace_f, " PBIDisconnect() called\n"); trace_f = freopen("DBDTrace.log", "a", trace_f);}
		PBIDisconnect(imp_dbh->sessid);
 	}
 	
*/
    DBIc_IMPSET_off(imp_dbh);
}


/*------------------------------------------------------------
connecting to a data source.
Allocates henv and hdbc.
------------------------------------------------------------*/

/*----------------------------------------------------*/
PUBLIC int dbd_db_login(SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *uid, char *pwd)
{
char *server = NULL, *database = NULL, *ip_address = NULL, *ptr, *p1 = NULL, *p2 = NULL;
int rtc = FAILED;

	server = dbname;
	
	ptr = dbname;
	
	if (DBIS->debug > 3) 
		PerlIO_printf(DBILOGFP, "dbd_db_login(\"%s\", \"%s\", \"%s\" \n", (dbname)?dbname:"NULL", (uid)?uid:"NULL", (pwd)?pwd:"NULL");
	
	while (*ptr && (*ptr != ';'))ptr++;
	if (*ptr) {
		p1 = ptr;
		*ptr = 0;
		ptr++;
		ip_address = ptr;
	}
	
	while (*ptr && (*ptr != ';'))ptr++;
	if (*ptr) {
		p2 = ptr;
		*ptr = 0;
		ptr++;
		database = ptr;
	}
	
	if ( (!server) || (!*server) || (!database) || (!*database)) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_db_login failed: Missing server and/or database name: \"%s\"\n", dbname);
		
		dbi_error(dbh, -1, "Bad dbname");
		goto error;
	}
	
	if (!ip_address || (!*ip_address))
		ip_address = "localhost";
	
    if (trace_f) {
		fprintf(trace_f, "PBIConnect : server = \"%s\",  ip_address = \"%s\",  uid = \"%s\",  pwd = \"%s\",  database = \"%s\"\n", server, ip_address, uid, pwd, database);
		trace_f = freopen("DBDTrace.log", "a", trace_f);
	}

	rtc = PBIConnect(&(imp_dbh->sessid), server, PB_DATA_SERVER, PB_TCP, ip_address, uid, pwd, database);
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "PBIConnect failed: server = \"%s\",  ip_address = \"%s\",  uid = \"%s\",  pwd = \"%s\",  database = \"%s\"\n", server, ip_address, uid, pwd, database);
		pb_error(dbh, imp_dbh);
		rtc =  FAILED;
		goto error;
	}

	DBIc_IMPSET_on(imp_dbh); /* Cleanup required after this. */
	
	if (DBIS->debug > 3) 
				PBITrace(imp_dbh->sessid, TRUE);
		
	/* Compile the table_info() procedure. */
	rtc = PBIExecute(imp_dbh->sessid, table_info, PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_db_login:PBIExecute failed. Could not execute table_info procedure.\n");
		pb_error(dbh, imp_dbh);
		rtc =  FAILED;
	} else
		rtc = OK;
  
	/* Compile the NewPerlDatabase() procedure. */
  	rtc = PBIExecute(imp_dbh->sessid, NewPerlDatabase, PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_db_login:PBIExecute failed. Could not execute NewPerlDatabase  procedure.\n");
		pb_error(dbh, imp_dbh);
		rtc =  FAILED;
	} else
		rtc = OK;
  
	
   error:
   	if (p1) *p1 = ';';
   	if (p2) *p2 = ';';
   	
   	return rtc;
}

/*----------------------------------------------------*/
PUBLIC int dbd_db_disconnect(SV *dbh, imp_dbh_t *imp_dbh)
{
    if (trace_f) {fprintf(trace_f, " dbd_db_disconnect: PBIDisconnect() called\n"); trace_f = freopen("DBDTrace.log", "a", trace_f);}

	PBIDisconnect(imp_dbh->sessid);
/*
    if (DBIc_ACTIVE(imp_dbh)) {
    	if (trace_f) {fprintf(trace_f, " PBIDisconnect() called\n"); trace_f = freopen("DBDTrace.log", "a", trace_f);}
		PBIDisconnect(imp_dbh->sessid);
 	}
*/
 	
    DBIc_IMPSET_off(imp_dbh);
    return OK;
}


/*----------------------------------------------------*/
PUBLIC int dbd_db_commit(SV *dbh, imp_dbh_t *imp_dbh)
{
short rtc;
dTHR;

	if (imp_dbh->auto_commit) {
    		do_warn(dbh, TX_ERR_AUTOCOMMIT, "Commmit ineffective while AutoCommit is on");
		return OK;
	}
		

	if ((rtc = PBIExecute(imp_dbh->sessid, "commit;", PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL)) == PB_OK)
		rtc = PBIExecute(imp_dbh->sessid, "begin;", PB_NTS, PB_EXECUTE_LATER, NULL, NULL, NULL);/* Delay the begin until the next statement. */
    if (trace_f) fprintf(trace_f,"commit;begin;\n");
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_db_commit:PBIExecute failed.\n");
		pb_error(dbh, imp_dbh);
		return FAILED;
	}
	
    return OK;
}

/*----------------------------------------------------*/
PUBLIC int dbd_db_rollback(SV *dbh, imp_dbh_t *imp_dbh)
{
short rtc;
dTHR;

	if (imp_dbh->auto_commit) {
    		do_warn(dbh, TX_ERR_AUTOCOMMIT, "Rollback ineffective while AutoCommit is on");
		return OK;
	}
		

	if ((rtc = PBIExecute(imp_dbh->sessid, "rollback;", PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL)) == PB_OK)
		rtc = PBIExecute(imp_dbh->sessid, "begin;", PB_NTS, PB_EXECUTE_LATER, NULL, NULL, NULL);/* Delay the begin until the next statement. */
	if (trace_f) fprintf(trace_f,"rollback;begin;\n");
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_db_rollback:PBIExecute failed.\n");
		pb_error(dbh, imp_dbh);
		return FAILED;
	}
	
    return OK;
}

/*----------------------------------------------------*/
PRIVATE void init_statement(imp_sth_t *imp_sth, char *statement)
{
char *ptr = statement, *s = "SELECT";
int cnt = 0, sqcnt = 0, dqcnt = 0;

	while (*ptr && isspace(*ptr)) ptr++; /* Skip leading white space. */
	
	while (*ptr && (toupper(*ptr) == *s)) {s++, ptr++;}
	
	if ( (!*s) && isspace(*ptr)) {
		imp_sth->is_select = TRUE;
		sprintf(imp_sth->cursor_name, "%sC", imp_sth->tag);
	}
	
	/* Count the paramater markers. */
	while (*ptr) {
		if ((*ptr == '\'') && !dqcnt){
			sqcnt = !sqcnt;
		} else if ((*ptr == '"')  && !sqcnt){
			dqcnt = !dqcnt;
		} else if ((*ptr == '?') && (!sqcnt) && (!dqcnt))
			cnt++;
		
		ptr++;	
	}
	
	imp_sth->parm_cnt = cnt;
}

/*----------------------------------------------------*/
#define SET_PARAM_NAME(b, t, n)		sprintf(b,"%sP%d", t,n)

/*----------------------------------------------------*/
PRIVATE int statement_vars(SV *sth, imp_sth_t *imp_sth, char declare)
{
char *ptr, parm[20];
int cnt = 0;
short rtc;

	ptr = imp_sth->stmt_text; /* The statement buffer is used a scratch buffer. */
	if (!ptr)
		return FAILED;
		
	*ptr = 0;
	
	if (imp_sth->parm_cnt) {
		if (declare)
			strcpy(ptr,"Declare Generic ");
		else
			strcpy(ptr,"Undeclare  ");
		
		/* Declare paramater variables. */
		for (cnt = 0; cnt < imp_sth->parm_cnt;) {
			cnt++;
			SET_PARAM_NAME(parm, imp_sth->tag, cnt);
			
			if (cnt > 1)
				strcat(ptr, ", ");
			
			strcat(ptr, parm);
		}
		
		strcat(ptr, ";");
			imp_sth->delayed_execution = 1;
	    rtc = PBIExecute(imp_sth->sessid, ptr, PB_NTS, PB_EXECUTE_LATER, NULL, NULL, NULL);
				if (trace_f) fprintf(trace_f,"%s\n", ptr);
	if (rtc != PB_OK) {
			if (DBIS->debug > 3) 
				PerlIO_printf(DBILOGFP, "statement_vars:PBIExecute 1 failed.\n");
			if (declare) {	
				D_imp_dbh_from_sth;
				pb_error(sth, imp_dbh);
				return FAILED;
			}
		}
	}
	
	memset(ptr, 0, strlen(ptr));

	if (imp_sth->is_select && !declare) { /* Cursors are declared automaticly in the select. */
		char dec[40];
		
		sprintf(dec, "Undeclare %s ;", imp_sth->cursor_name);
			
		imp_sth->delayed_execution = 1;
	    rtc = PBIExecute(imp_sth->sessid, dec, PB_NTS, PB_EXECUTE_LATER, NULL, NULL, NULL);
		if (trace_f) fprintf(trace_f,"%s\n", dec);
		if (rtc != PB_OK) {
			if (DBIS->debug > 3) 
				PerlIO_printf(DBILOGFP, "statement_vars:PBIExecute 2 failed.\n");
			if (declare) {	
				D_imp_dbh_from_sth;
				pb_error(sth, imp_dbh);
				return FAILED;
			}
		}
		
	}
	
	return OK;
	
}
 
/*----------------------------------------------------*/
PRIVATE int preprocess_statement(SV *sth, imp_sth_t *imp_sth, char *statement)
{
char *ptr = statement,  *b, parm[20];
int cnt = 0, sqcnt = 0, dqcnt = 0;
short rtc;

	if (!statement_vars(sth, imp_sth, TRUE))
		return FAILED;
		
	if (imp_sth->parm_cnt) {
		b = imp_sth->stmt_text;
		
		/* Replace the paramater markers. */
		while (*ptr) {
			if ((*ptr == '\'') && !dqcnt){
				sqcnt = !sqcnt;
			} else if ((*ptr == '"')  && !sqcnt){
				dqcnt = !dqcnt;
			}
			
			if ((*ptr == '?') && (!sqcnt) && (!dqcnt)) {
				cnt++;
				SET_PARAM_NAME(parm, imp_sth->tag, cnt);
				sprintf(b, " :%s ", parm);
				b += strlen(b);			
			} else {
				*b = *ptr;
				b++;
			}
			
			ptr++;	
		}
	} else {
		strcpy(imp_sth->stmt_text, statement);
		b = imp_sth->stmt_text + strlen(statement);
	}
	
	/* Tollerate statements ending with ';' */
	b--;
	while ((b > imp_sth->stmt_text) && isspace(*b)) b--;
	if ( *b != ';')
		b++;
		
	if (imp_sth->is_select) {		
		sprintf(b, " INTO %s FOR EXTRACT;", imp_sth->cursor_name);
	} else
		*b = ';';
		
	return OK;
}

/*----------------------------------------------------*/
PUBLIC int dbd_st_prepare(SV *sth, imp_sth_t *imp_sth, char *statement, SV *attribs)
{
dTHR;
D_imp_dbh_from_sth; /* <= "imp_dbh_t *imp_dbh = the_stmt_db_handle;" */
long size;
int rtc;
START_TIMER


	if (trace_f) fprintf(trace_f,"dbd_st_prepare(\"%s\"), max_blob = %d \n", statement,  DBIc_LongReadLen(imp_dbh));
	imp_sth->sessid =  imp_dbh->sessid;
	sprintf(imp_sth->tag,"S%d", imp_dbh->seq_cnt);
	
	imp_dbh->seq_cnt++;
	imp_sth->max_blob =  DBIc_LongReadLen(imp_dbh);
	init_statement(imp_sth, statement);
	
    DBIc_NUM_PARAMS(imp_sth) = imp_sth->parm_cnt;
	/* Give it lots of space. */
	size = strlen(statement) + 30 + (imp_sth->parm_cnt * (strlen(imp_sth->tag) + 8)) +100/*******/;
	
	imp_sth->stmt_text = my_malloc(sth, size);
	if (!imp_sth->stmt_text)
		return FAILED;
		
	DBIc_IMPSET_on(imp_sth); /* Cleanup required after this. */
		
	memset(imp_sth->stmt_text, 0, size);
		
	rtc = preprocess_statement(sth, imp_sth, statement);



END_TIMER

	return rtc;
}

/*----------------------------------------------------*/
PUBLIC void dbd_st_destroy(SV *sth, imp_sth_t *imp_sth)
{
dTHR;
START_TIMER

	/* Undeclare and PrimeBase-Talk  variables. */
	statement_vars(sth, imp_sth, FALSE);

    my_free(imp_sth->stmt_text);
    free_column_info(imp_sth->sessid, imp_sth->cursor_id, imp_sth->column_info, imp_sth->columns);

    DBIc_IMPSET_off(imp_sth);		/* let DBI know we've done it	*/
END_TIMER
}

/*------------------------------------------------------------
 * bind placeholder.
 *  ph_namesv	: index of execute() parameter 1..n 
 *  SV *attribs	: may be set by Solid.xs bind_param call 
 *  int is_inout: inout for procedure calls only 
 *  IV maxlen	: ??? 
 */
PUBLIC int dbd_bind_ph(SV *sth, imp_sth_t *imp_sth, SV *ph_namesv, SV *newvalue, IV sql_type,
						SV *attribs, int is_inout, IV maxlen)
{
dTHR;
short rtc;
char parm[20];
unsigned int pnum = 0;
PBDataFmt pbtype = {0};
int idata;
void *data = NULL;

	if (is_inout) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "bind_param_inout is not supported.\n");
			
		dbi_error(sth, -1, "bind_param_inout is not supported.");
		return FAILED;
	}
	
	pnum = SvIV(ph_namesv);
	if ((pnum > imp_sth->parm_cnt) || ! pnum){
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "Paramater number %d is out of range: (1 -> %d).", pnum, imp_sth->parm_cnt);
		dbi_error(sth, -1, "dbd_bind_ph: Paramater number is out of range.");
		return FAILED;
	}
		
	SET_PARAM_NAME(parm, imp_sth->tag, pnum);


	if (!SvOK(newvalue)) {
		pbtype.type = PB_CHAR;
		pbtype.len = 0;
		data = NULL;
	} else if (SvIOK(newvalue)) {
		pbtype.type = PB_INTEGER;
		pbtype.len = 4;
		
		idata = SvIV(newvalue);
		data = &idata;
/*PerlIO_printf(DBILOGFP, "dbd_bind_ph: parm: \"%s\", int value %d.\n", parm, idata); */
	} else  if (SvPOK(newvalue)) {
		STRLEN len;
		data = SvPV(newvalue, len);
		pbtype.type = PB_CHAR;
		pbtype.len = len;
/*PerlIO_printf(DBILOGFP, "dbd_bind_ph: parm: \"%s\", len = %d string value \"%s\".\n", parm, len, data); */
	} else {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_bind_ph; new value must be an int or a string.\n");
		dbi_error(sth, -1, "dbd_bind_ph; new value must be an int or a string.");
		return FAILED;
	}

	if (imp_sth->delayed_execution) {
		rtc = PBIExecute(imp_sth->sessid, "", PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
		if (rtc != PB_OK) {
			D_imp_dbh_from_sth;
			if (DBIS->debug > 3) 
				PerlIO_printf(DBILOGFP, "dbd_bind_ph:PBIExecute  failed.\n");
			pb_error(sth, imp_dbh);
			return FAILED;
		}
		imp_sth->delayed_execution = 0;
	}

	rtc = PBIPutValue(imp_sth->sessid, parm ,&pbtype, data);
	if (rtc != PB_OK) {
		D_imp_dbh_from_sth;
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_bind_ph:PBIPutValue  failed.\n");
		pb_error(sth, imp_dbh);
		return FAILED;
	}
#ifdef TEST_JUNK
{	
	char buf[80];
	pbtype.type = PB_CSTRING;
	pbtype.len = 80;
	rtc = PBIGetValue(imp_sth->sessid, parm ,&pbtype, buf, NULL, NULL);
	if (rtc != PB_OK) {
		D_imp_dbh_from_sth;
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_bind_ph:PBIPutValue  failed.\n");
		pb_error(sth, imp_dbh);
		return FAILED;
	}
PerlIO_printf(DBILOGFP, "dbd_bind_ph: Set parm: \"%s\"\n", buf);
}	
#endif

	return OK;
}

/*----------------------------------------------------*/
PUBLIC int dbd_st_execute(SV *sth, imp_sth_t *imp_sth)
{
dTHR;
short rtc;
PBCursorInfo info;
char *pb_error_str;

START_TIMER
	/*printf("%s\n", imp_sth->stmt_text); */

    rtc = PBIExecute(imp_sth->sessid, imp_sth->stmt_text, PB_NTS, PB_EXECUTE_NOW, &(imp_sth->rows_effected), NULL, NULL);
	if (trace_f) fprintf(trace_f,"%s\n", imp_sth->stmt_text);
	if (rtc != PB_OK) {
		pb_error_str = "statement_vars:PBIExecute  failed.\n";
#ifdef DEBUG_IT
	PerlIO_printf(DBILOGFP, "Execution Failed: \"%s\"\n", imp_sth->stmt_text);
#endif
		goto x_error;
	}
	imp_sth->delayed_execution = 0;

	if (imp_sth->is_select) {
		rtc = PBIGetCursorID(imp_sth->sessid, imp_sth->cursor_name, &(imp_sth->cursor_id));
		if (rtc != PB_OK) {
			pb_error_str = "statement_vars:PBIGetCursorID  failed.\n";
			goto x_error;
		}
		
		rtc = PBICursorInfo(imp_sth->sessid, imp_sth->cursor_id ,&info);
		if (rtc != PB_OK) {
			pb_error_str = "statement_vars:PBICursorInfo  failed.\n";
			goto x_error;
		}

		
		DBIc_NUM_FIELDS(imp_sth) = info.columns;
		imp_sth->rows_effected = info.rows;
		imp_sth->columns = info.columns;
		imp_sth->column_info = get_column_info(sth, imp_sth, imp_sth->sessid, imp_sth->cursor_id, imp_sth->columns);
		if (!imp_sth->column_info)
			return FAILED;
			
		DBIc_ACTIVE_on(imp_sth);
	}
END_TIMER
/*dbd_st_finish(sth, imp_sth); */

   return OK;
    
x_error:

	{
	D_imp_dbh_from_sth;
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, pb_error_str);
		pb_error(sth, imp_dbh);
	}
	return FAILED;
}

/*----------------------------------------------------*/
PUBLIC int dbd_st_just_doit(SV *dbh, imp_dbh_t *imp_dbh, SV *sv_statement) 
{
short rtc;
long rows_effected = -1;
STRLEN len;
char *ptr, *statement = SvPV(sv_statement,len);

	if (trace_f) fprintf(trace_f,"dbd_st_just_doit(\"%s\")\n", statement);

	for (ptr = statement + strlen(statement) -1; (ptr > statement) && (*ptr == ' '); ptr--);
	
    rtc = PBIExecute(imp_dbh->sessid, statement, PB_NTS, (*ptr == ';')?PB_EXECUTE_NOW:PB_EXECUTE_LATER, NULL, NULL, NULL);
    if ((rtc == PB_OK) && (*ptr != ';'))
		rtc = PBIExecute(imp_dbh->sessid, ";", PB_NTS, PB_EXECUTE_NOW, &rows_effected, NULL, NULL);
    if (rtc == PB_OK) 
    	return (int)rows_effected;
    	
	if (DBIS->debug > 3) 
		PerlIO_printf(DBILOGFP, "dbd_st_just_doit FAILED\n");
		
	pb_error(dbh, imp_dbh);
	return -2;
    

}

/*----------------------------------------------------*/
PUBLIC int dbd_st_internal_execute(SV *dbh, imp_dbh_t *imp_dbh, char* statement, int numParams, SV **params) 
{
	dbi_error(dbh, 1, "dbd_st_internal_execute() is not implemented");
    return FAILED;
}


/*----------------------------------------------------*/
PUBLIC int dbd_st_rows(SV *sth, imp_sth_t *imp_sth)
{
    return imp_sth->rows_effected;
}


/*----------------------------------------------------*/
PUBLIC int dbd_st_finish(SV *sth, imp_sth_t *imp_sth)
{
dTHR;
	if (imp_sth->is_select && DBIc_ACTIVE(imp_sth)) {
		PBISetCursorState(imp_sth->sessid, imp_sth->cursor_id, PB_CURSOR_FREE);
		/*PBISetCursorPosition(imp_sth->sessid, imp_sth->cursor_id, PB_FETCH_FIRST); */
    }
    DBIc_ACTIVE_off(imp_sth);
    return 1;
}


/*----------------------------------------------------*/
PUBLIC AV *dbd_st_fetch(SV *sth, imp_sth_t *imp_sth)
{
dTHR;
AV *av;
ColInfoPtr col_info = imp_sth->column_info;
short rtc, truncated;
long rows = 1, size;
int chop_blanks, truncate_blob, i, num_fields;
START_TIMER

	/* test-wisconsin calls dbd_st_fetch() after doing inserts and updates! */
    if ( !DBIc_ACTIVE(imp_sth) ) {
		/*dbi_error(sth, -1, "no select statement currently executing"); */
    	goto error;
    }

    rtc = PBIFetchRow(imp_sth->sessid, imp_sth->cursor_id, &rows, PB_FETCH_NEXT, &truncated, NULL, NULL);
	if (rtc == PB_ERROR) {
		D_imp_dbh_from_sth;
		
		if (DBIS->debug > 2) 
			PerlIO_printf(DBILOGFP, "dbd_st_fetch:PBIFetchRow  failed.\n");
			
		pb_error(sth, imp_dbh);
		goto error;
	}

	if (rtc == PB_NODATA) {
    	goto error; /* Don't report any error since this isn't an error. */
	}
	
	chop_blanks = DBIc_has(imp_sth, DBIcf_ChopBlanks);
	if (trace_f) fprintf(trace_f,"dbd_st_fetch()chop_blanks = %d.\n", chop_blanks);
	
	truncate_blob = DBIc_has(imp_sth,DBIcf_LongTruncOk);

    av = DBIS->get_fbav(imp_sth);
    if (av == Nullav) {
		dbi_error(sth, -1, "DBIS->get_fbav(imp_sth) Failed ");
    	goto error;
    }
  
	num_fields = AvFILL(av)+1;
	if (num_fields > imp_sth->columns) /* Maybe this should be treated as an error. */
		num_fields = imp_sth->columns;
		
	for (i = 0; i < num_fields; i++, col_info++) {
	
		
		if ((col_info->b_info == PB_NULL_DATA) || !col_info->bind)
			SvOK_off(AvARRAY(av)[i]);
		else {
			if (truncated && (col_info->b_info > col_info->b_size)) {
				if (((col_info->pb_type != PB_LCHAR) && (col_info->pb_type != PB_LBIN)) || !truncate_blob) {
					char buffer[80];
					
					sprintf(buffer, "Data truncated in column number %d, data size: %d, buffer size: %d", i+1, col_info->b_info, col_info->b_size);
					dbi_error(sth, -1, buffer);
					goto error;
				}
			}
			
			size = (col_info->b_info > col_info->b_size)? col_info->b_size: col_info->b_info ;
			
			if (size && chop_blanks && (col_info->pb_type == PB_VCHAR) || (col_info->pb_type == PB_CHAR)) {
				char *ptr = col_info->bind + size -1;
				
				if (trace_f) fprintf(trace_f,"dbd_st_fetch() chopping blanks. %d\n", chop_blanks);

				while ((ptr > col_info->bind) && (*ptr == ' ')) ptr--;
				
				if (*ptr != ' ') ptr++;
				
				*ptr = 0;
				size = ptr - col_info->bind;
			}
				
			sv_setpvn(AvARRAY(av)[i], col_info->bind, size);
		}
		
		
	}
END_TIMER

	return av;
	
error:
	dbd_st_finish(sth, imp_sth);
END_TIMER
	return Nullav;

}



/*----------------------------------------------------*/
PUBLIC int dbd_st_prep_call(SV *sth, imp_sth_t *imp_sth, char *statement)
{
 dTHR;
D_imp_dbh_from_sth; /* <= "imp_dbh_t *imp_dbh = the_stmt_db_handle;" */

	/* The statement is assumed to be a procedure call that returns */
	/* a cursor. */
	imp_sth->sessid =  imp_dbh->sessid;
	sprintf(imp_sth->tag,"S%d", imp_dbh->seq_cnt);
	
	imp_dbh->seq_cnt++;
	imp_sth->max_blob =  0;

	imp_sth->is_select = TRUE;
	sprintf(imp_sth->cursor_name, "%sC", imp_sth->tag);

	imp_sth->stmt_text = my_malloc(sth, strlen(statement) + 40);
	if (!imp_sth->stmt_text)
		return FAILED;

	DBIc_IMPSET_on(imp_sth); /* Cleanup required after this. */


	sprintf (imp_sth->stmt_text, "cursor %s; %s = %s", imp_sth->cursor_name, imp_sth->cursor_name, statement);
	
   return OK;
}


/* ----------------------------------------------------------------	*/
PUBLIC int dbd_st_blob_read(SV *sth, imp_sth_t *imp_sth, int field, long offset, long len, SV *destrv, long destoffset)
{
dTHR;
SV *bufsv;
PBBlobRec blob_id;
short rtc;
char *pb_error_str;
unsigned long size = len;
ColInfoPtr info = imp_sth->column_info;

	info += field-1;
	
	if ((field < 1) || (field > imp_sth->columns) || 
		((info->pb_type != PB_LBIN) && (info->pb_type != PB_LCHAR))) {
		dbi_error(sth, -1, "Invalid field for dbd_st_blob_read()");
		return FAILED;
	}
	
	/* This should probably be cached. */
    rtc = PBIGetColumnData(imp_sth->sessid, imp_sth->cursor_id, field, NULL, &blob_id, NULL, NULL);
	if (rtc == PB_ERROR) {
		pb_error_str = "dbd_st_blob_read:PBIGetColumnData  failed.\n";
		goto x_error;
	}

	bufsv = SvRV(destrv);
	sv_setpvn(bufsv,"",0);      /* ensure it's writable string  */
	SvGROW(bufsv, len+destoffset+1);    /* SvGROW doesn't do +1 */
	
	/* Get the data. */
    rtc = PBIGetBlobData(imp_sth->sessid, &blob_id, offset, ((char *)SvPVX(bufsv)) + destoffset, &size, NULL, NULL);
	if (rtc == PB_ERROR) {
		pb_error_str = "dbd_st_blob_read:PBIGetBlobData  failed.\n";
		goto x_error;
	}

	if (size < len)
		len = size;
		
    SvCUR_set(bufsv, destoffset+len);
    *SvEND(bufsv) = '\0'; /* consistent with perl sv_setpvn etc */

    return OK;
    
x_error:
{
	D_imp_dbh_from_sth;

	if (DBIS->debug > 3) 
		PerlIO_printf(DBILOGFP, pb_error_str);
	pb_error(sth, imp_dbh);
}
   return FAILED;
}

/* ----------------------------------------------------------------	*/
PUBLIC int dbd_db_STORE_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)
{
dTHR;
STRLEN kl;
char *key = SvPV(keysv,kl), **ptr, *strval, buff[80];
enum 				{ AutoCommit,   pb_datefmt,   pb_timefmt,   pb_datetimefmt, pb_tracing, pb_tracelog, pb_dbd_tracing};
char *my_atts[] = 	{"AutoCommit", "pb_datefmt", "pb_timefmt", "pb_datetimefmt", "pb_tracing", "pb_tracelog", "pb_dbd_tracing", NULL };
int on, i, rtv = FALSE;
short rtc;

START_TIMER
    for (ptr = my_atts, i = 0; (*ptr && strcmp(key, *ptr)); ptr++, i++);

    if (!*ptr)
		goto the_end;
		
	*buff = 0;
	rtv = TRUE;	
	switch (i) {
		case AutoCommit:
		
			on = SvTRUE(valuesv);
			if (on && !imp_dbh->auto_commit)  { /* Commit any running transaction */
			    rtc = PBIExecute(imp_dbh->sessid, "commit;", PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
				if (trace_f) fprintf(trace_f,"%s\n", "commit;");
				if (rtc != PB_OK) {
					if (DBIS->debug > 3) 
						PerlIO_printf(DBILOGFP, "dbd_db_STORE_attrib:PBIExecute failed.\n");
					pb_error(dbh, imp_dbh);
					croak("dbd_db_STORE_attrib:PBIExecute failed.");
				}
			}		
			imp_dbh->auto_commit = on;
			
			if (!on) { /* Start a transaction now. */
			    rtc = PBIExecute(imp_dbh->sessid, "begin;", PB_NTS, PB_EXECUTE_LATER, NULL, NULL, NULL);
				if (trace_f) fprintf(trace_f,"%s\n", "begin;");
				if (rtc != PB_OK) {
					if (DBIS->debug > 3) 
						PerlIO_printf(DBILOGFP, "dbd_db_STORE_attrib:PBIExecute failed.\n");
					pb_error(dbh, imp_dbh);
					croak("dbd_db_STORE_attrib:PBIExecute failed.");
				}
			}
			break;
			
		case pb_tracing:
		
			on = SvTRUE(valuesv);
			PBITrace(imp_dbh->sessid, on);
			break;
			
		case pb_dbd_tracing:
		
			if (SvTRUE(valuesv)) {
 				trace_f =  fopen("DBDTrace.log", "w");
			} else {
				if (trace_f) fclose(trace_f);
				trace_f = NULL;
			}
			break;
			
		case pb_tracelog:
		
			strval = SvPV(valuesv,kl);
			PBISetLogName(strval);
			break;
			
		case pb_datefmt:
			strcpy(buff, "$datefmt = \"");
			
		case pb_timefmt:
			if (!*buff) strcpy(buff, "$timefmt = \"");
			
		case pb_datetimefmt:
			if (!*buff) strcpy(buff, "$tsfmt = \"");
			
			strval = SvPV(valuesv,kl);
			if ((kl > 60) || !strval)
				return FALSE;
				
			strcat(buff, strval);
			strcat(buff, "\";");
		    rtc = PBIExecute(imp_dbh->sessid, buff, PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
				if (trace_f) fprintf(trace_f,"%s\n", buff);
			if (rtc != PB_OK) {
				if (DBIS->debug > 3) 
					PerlIO_printf(DBILOGFP, "dbd_db_STORE_attrib:PBIExecute failed.\n");
				pb_error(dbh, imp_dbh);
				return FALSE;
			}
			
			break;
			
			
	}
the_end:	
END_TIMER
	return rtv;
		
}


/* ----------------------------------------------------------------	*/
PUBLIC SV *dbd_db_FETCH_attrib(SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)
{
dTHR;
STRLEN kl;
char *key = SvPV(keysv,kl);
int on;
SV *retsv = NULL;

	if (!strcmp(key, "AutoCommit")) {
		retsv = newSViv(imp_dbh->auto_commit);
		return sv_2mortal(retsv);
	}

	return Nullsv;

}


/* ----------------------------------------------------------------	*/
PUBLIC SV *dbd_st_FETCH_attrib(SV *sth, imp_sth_t *imp_sth, SV *keysv)
{
dTHR;
STRLEN kl;
char *key = SvPV(keysv,kl), **ptr;
enum 				{ NUM_OF_FIELDS,   NUM_OF_PARAMS,   CursorName,   NAME,   TYPE,   PRECISION,   SCALE,   NULLABLE};
char *my_atts[] = 	{"NUM_OF_FIELDS", "NUM_OF_PARAMS", "CursorName", "NAME", "TYPE", "PRECISION", "SCALE", "NULLABLE", NULL };
int i;
SV *retsv = NULL;
AV *av;
ColInfoPtr info;

START_TIMER

    if (!DBIc_ACTIVE(imp_sth)) /* None of these attribute can be set for inactive statements. */
		goto the_end;

    for (ptr = my_atts, i = 0; (*ptr && strcmp(key, *ptr)); ptr++, i++);

    if (!*ptr)
		goto the_end;
		
	info = imp_sth->column_info;

	if ((i > CursorName) && !info) 
		goto the_end;



	
    switch (i) {

		case NUM_OF_FIELDS:			
		    retsv = newSViv(imp_sth->columns);
		    break;
		    
		case NUM_OF_PARAMS:			
		    retsv = newSViv(imp_sth->parm_cnt);
		    break;
		    
		case CursorName:			
		    retsv = newSVpv(imp_sth->cursor_name, 0);
		    break;
		    
		case NAME: 			
		    av = newAV();
		    retsv = newRV(sv_2mortal((SV*)av));
		    for (i=0; i < imp_sth->columns; i++, info++)
				av_store(av, i, newSVpv(info->name, 0));
				
		    break;
		    
		case TYPE:			
		    av = newAV();
		    retsv = newRV(sv_2mortal((SV*)av));
		    for (i=0; i < imp_sth->columns; i++, info++)
				av_store(av, i, newSViv(info->odbc_type));
				
		    break;
		    
		case PRECISION:		
		    av = newAV();
		    retsv = newRV(sv_2mortal((SV*)av));
		    for (i=0; i < imp_sth->columns; i++, info++)
				av_store(av, i, newSViv(info->precision));
				
		    break;
		    
		case SCALE:			
		    av = newAV();
		    retsv = newRV(sv_2mortal((SV*)av));
		    for (i=0; i < imp_sth->columns; i++, info++)
				av_store(av, i, newSViv(info->scale));
				
		    break;
		    
		case NULLABLE:			
		    av = newAV();
		    retsv = newRV(sv_2mortal((SV*)av));
		    for (i=0; i < imp_sth->columns; i++, info++)
				av_store(av, i, newSViv(2)); /* This information isn't currently available in the cursor. Maybe in the future. */
				
		    break;
		    
    }

the_end:	
END_TIMER
	if (!retsv)
		return Nullsv;
    return sv_2mortal(retsv);
}


/* ----------------------------------------------------------------	*/
PUBLIC int dbd_st_STORE_attrib(SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)
{
    return FALSE;
}

/* Some usefull functions for admin.
/*----------------------------------------------------*/
PRIVATE void admin_error(SV *dbh, int sessid)
{
long perr, serr;
char msg[256];
int rtc = FAILED;

	PBIGetError(sessid, &perr, &serr, msg, 256);
	dbi_error(dbh, perr, msg);
}

/*----------------------------------------------------*/
PUBLIC unsigned long PrimeBase_dr_connect(SV *dbh, char *host, char *server, char *user, char *passwd) 
{
long sessid;
int rtc = FAILED;

	rtc = PBIConnect(&sessid, server, PB_DATA_SERVER, PB_TCP, host, user, passwd, NULL);
	if (rtc != PB_OK) {
		admin_error(dbh, sessid);
		PBIDisconnect(sessid);
		return 0;
	}

	/* Compile the table_info() procedure. */
	rtc = PBIExecute(sessid, table_info, PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_db_login:PBIExecute failed. Could not execute table_info procedure.\n");
		admin_error(dbh, sessid);
		rtc =  FAILED;
	} else
		rtc = OK;
  
	/* Compile the NewPerlDatabase() procedure. */
  	rtc = PBIExecute(sessid, NewPerlDatabase, PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "dbd_db_login:PBIExecute failed. Could not execute NewPerlDatabase  procedure.\n");
		admin_error(dbh, sessid);
		rtc =  FAILED;
	} else
		rtc = OK;
  

	return sessid;
}
/*----------------------------------------------------*/
PUBLIC void PrimeBase_dr_disconnect(unsigned long sessid) 
{
	PBIDisconnect(sessid);
}

/*----------------------------------------------------*/
PUBLIC int PrimeBase_create_db(SV *dbh, unsigned long sessid, char *database) 
{
char buf[80];
int rtc = FAILED;

  	sprintf(buf,"NewPerlDatabase(\"%s\");", database);
  		
	rtc = PBIExecute(sessid, buf, PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "PrimeBase_create_db:PBIExecute failed. Could not create database: \"%s\".\n", database);
		admin_error(dbh, sessid);
		rtc =  FAILED;
	} else
		rtc = OK;

    return rtc;
}

/*----------------------------------------------------*/
PUBLIC int PrimeBase_drop_db(SV *dbh, unsigned long sessid, char *database) 
{
char buf[80];
int rtc = FAILED;

  	sprintf(buf,"drop database %s;", database);
  		
	rtc = PBIExecute(sessid, buf, PB_NTS, PB_EXECUTE_NOW, NULL, NULL, NULL);
	if (rtc != PB_OK) {
		if (DBIS->debug > 3) 
			PerlIO_printf(DBILOGFP, "PrimeBase_drop_db:PBIExecute failed. Could not drop database: \"%s\".\n", database);
		admin_error(dbh, sessid);
		rtc =  FAILED;
	} else
		rtc = OK;

    return rtc;
}



