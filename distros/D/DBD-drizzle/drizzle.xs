/*
  vim:ts=2 sts=2 sw=2:et ai:

   Copyright (c) 2008   Patrick Galbraith
   Copyright (c) 2009   Clint Byrum <clint@fewbar.com>

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/

#include <stdlib.h>
#include <libdrizzle/drizzle_client.h>
#include "dbdimp.h"
#include "constants.h"


DBISTATE_DECLARE;


MODULE = DBD::drizzle	PACKAGE = DBD::drizzle

INCLUDE: drizzle.xsi

MODULE = DBD::drizzle	PACKAGE = DBD::drizzle

double
constant(name, arg)
    char* name
    char* arg
  CODE:
    RETVAL = drizzle_constant(name, arg);
  OUTPUT:
    RETVAL

MODULE = DBD::drizzle	PACKAGE = DBD::drizzle::dr

void
_ListDBs(drh, host=NULL, port=NULL, user=NULL, password=NULL)
    SV *        drh
    char *	host
    char *      port
    char *      user
    char *      password
  PPCODE:
{
  drizzle_return_t ret;
  drizzle_st drizzle;
  drizzle_con_st con;

  (void)drizzle_create(&drizzle);
  (void)drizzle_con_create(&drizzle, &con);

  (void)drizzle_con_add_tcp(&drizzle, &con, host, atoi(port), user, password, NULL, DRIZZLE_CON_NONE);
  ret = drizzle_con_connect(&con);

  if (ret != DRIZZLE_RETURN_OK)
  {
    do_error(drh, drizzle_errno(&drizzle), drizzle_error(&drizzle), NULL);
  }
  else
  {
    drizzle_row_t cur;
    drizzle_result_st res;

    (void) drizzle_result_create(&con, &res);

    (void) drizzle_query_str(&con, &res, "SHOW DATABASES", &ret);
    if(ret != DRIZZLE_RETURN_OK) {
      do_error(drh, drizzle_result_error_code(&res), drizzle_result_error(&res), drizzle_result_sqlstate(&res));
    }
    else
    {
      ret = drizzle_result_buffer(&res);
      EXTEND(sp, drizzle_result_row_count(&res));
      while ((cur = drizzle_row_next(&res)))
      {
        PUSHs(sv_2mortal((SV*)newSVpv(cur[0], strlen(cur[0]))));
      }
      drizzle_result_free(&res);
    }
    drizzle_con_close(&con);
  }
}


void _admin_internal(drh,dbh,command,dbname=NULL,host=NULL,port=NULL,user=NULL,password=NULL)
  SV* drh
  SV* dbh
  char* command
  char* dbname
  char* host
  char* port
  char* user
  char* password
  PPCODE:
{
  drizzle_return_t retval;
  drizzle_st *drizzle;
  drizzle_con_st *con = NULL;
  drizzle_result_st res;

  /*
   *  Connect to the database, if required.
 */

  if (SvOK(dbh)) {
    D_imp_dbh(dbh);
    drizzle = imp_dbh->drizzle;
    con = imp_dbh->con;
  }
  else
  {
    if (drizzle == NULL)
    {
      do_error(drh, -1, "error allocating memory for core drizzle structure", NULL);
      XSRETURN_NO;
    }
    con = drizzle_con_add_tcp(drizzle, con, host, atoi(port), user, password, NULL, DRIZZLE_CON_NONE);
    if (con == NULL)
    {
      do_error(drh, drizzle_errno(drizzle), drizzle_error(drizzle), NULL);
      XSRETURN_NO;
    }
    retval = drizzle_con_connect(con);
    if (retval != DRIZZLE_RETURN_OK)
    {
      do_error(drh, drizzle_con_errno(con), drizzle_con_error(con), NULL);
      XSRETURN_NO;
    }
  }

  (void) drizzle_result_create(con, &res);

  if (strEQ(command, "shutdown"))
  {
    (void) drizzle_shutdown(con, &res, DRIZZLE_SHUTDOWN_DEFAULT, &retval);
  }
  /*
  else if (strEQ(command, "createdb"))
  {
      D_imp_dbh(dbh);
      (void) create_schema(imp_dbh, &res, dbname);
  }
  else if (strEQ(command, "dropdb"))
  {
      D_imp_dbh(dbh);
      (void) drop_schema(imp_dbh, &res, dbname);
  }
    */
  else
  {
    croak("Unknown command: %s", command);
  }
  if (retval != DRIZZLE_RETURN_OK)
  {
    do_error(SvOK(dbh) ? dbh : drh, drizzle_con_errno(con),
             drizzle_con_error(con) ,drizzle_con_sqlstate(con));
  }

  if (SvOK(dbh))
  {
    (void) drizzle_con_close(con);
  }
  if (retval)
    XSRETURN_NO;
  else 
    XSRETURN_YES;
}


MODULE = DBD::drizzle    PACKAGE = DBD::drizzle::db


void
type_info_all(dbh)
  SV* dbh
  PPCODE:
{
  /* 	static AV* types = NULL; */
  /* 	if (!types) { */
  /* 	    D_imp_dbh(dbh); */
  /* 	    if (!(types = dbd_db_type_info_all(dbh, imp_dbh))) { */
  /* 	        croak("Cannot create types array (out of memory?)"); */
  /* 	    } */
  /* 	} */
  /* 	ST(0) = sv_2mortal(newRV_inc((SV*) types)); */
  D_imp_dbh(dbh);
  ST(0) = sv_2mortal(newRV_noinc((SV*) dbd_db_type_info_all(dbh,
                                                            imp_dbh)));
  XSRETURN(1);
}


void
_ListDBs(dbh)
  SV*	dbh
  PPCODE:
{
  drizzle_result_st res;
  drizzle_row_t cur;
  drizzle_return_t ret;

  D_imp_dbh(dbh);

  (void) drizzle_result_create(imp_dbh->con, &res);
  (void) drizzle_query_str(imp_dbh->con, &res,"SHOW DATABASES", &ret);
  if (ret != DRIZZLE_RETURN_OK)
    do_error(dbh,
            drizzle_con_errno(imp_dbh->con),
            drizzle_con_error(imp_dbh->con),
            drizzle_con_sqlstate(imp_dbh->con));
  ret= drizzle_result_buffer(&res);
  if (ret != DRIZZLE_RETURN_OK)
  {
    do_error(dbh, drizzle_result_error_code(&res),
    drizzle_result_error(&res), drizzle_result_sqlstate(&res));
  }
  else
  {
    EXTEND(sp, drizzle_result_row_count(&res));
    while ((cur = drizzle_row_next(&res)))
    {
      PUSHs(sv_2mortal((SV*)newSVpv(cur[0], strlen(cur[0]))));
    }
  }
  drizzle_result_free(&res);
}


void
do(dbh, statement, attr=Nullsv, ...)
  SV *        dbh
  SV *	statement
  SV *        attr
  PROTOTYPE: $$;$@
  CODE:
{
  D_imp_dbh(dbh);
  int num_params= 0;
  int retval;
  struct imp_sth_ph_st* params= NULL;
  drizzle_result_st _result;
  drizzle_result_st *result;
  if (items > 3)
  {
    /*  Handle binding supplied values to placeholders	   */
    /*  Assume user has passed the correct number of parameters  */
    int i;
    num_params= items-3;
    Newz(0, params, sizeof(*params)*num_params, struct imp_sth_ph_st);
    for (i= 0;  i < num_params;  i++)
    {
      params[i].value= ST(i+3);
      params[i].type= SQL_VARCHAR;
    }
  }
  retval = drizzle_st_internal_execute(dbh, statement, attr, num_params,
                                       params, &result, imp_dbh->con, 0);
  if (params)
    Safefree(params);

  drizzle_result_free(result);

  /* remember that dbd_st_execute must return <= -2 for error	*/
  if (retval == 0)		/* ok with no rows affected	*/
    XST_mPV(0, "0E0");	/* (true but zero)		*/
  else if (retval < -1)	/* -1 == unknown number of rows	*/
    XST_mUNDEF(0);		/* <= -2 means error   		*/
  else
    XST_mIV(0, retval);	/* typically 1, rowcount or -1	*/
}


SV*
ping(dbh)
    SV* dbh;
  PROTOTYPE: $
  CODE:
    {
      int retval;
      drizzle_return_t ret;
      drizzle_result_st res;
      D_imp_dbh(dbh);
      drizzle_ping(imp_dbh->con, &res, &ret);
      retval = (ret == DRIZZLE_RETURN_OK);
      if (!retval) {
        if (drizzle_db_reconnect(dbh)) {
          drizzle_ping(imp_dbh->con, &res, &ret);
          retval = (ret == DRIZZLE_RETURN_OK);
        }
      }
      drizzle_result_free(&res);
      RETVAL = boolSV(retval);
    }
  OUTPUT:
    RETVAL



void
quote(dbh, str, type=NULL)
    SV* dbh
    SV* str
    SV* type
  PROTOTYPE: $$;$
  PPCODE:
    {
        SV* quoted = dbd_db_quote(dbh, str, type);
	ST(0) = quoted ? sv_2mortal(quoted) : str;
	XSRETURN(1);
    }


MODULE = DBD::drizzle    PACKAGE = DBD::drizzle::st

int
more_results(sth)
    SV *	sth
    CODE:
{
  D_imp_sth(sth);
  int retval;
  if (dbd_st_more_results(sth, imp_sth))
  {
    RETVAL=1;
  }
  else
  {
    RETVAL=0;
  }
}
    OUTPUT:
      RETVAL

int
dataseek(sth, pos)
    SV* sth
    int pos
  PROTOTYPE: $$
  CODE:
{
  drizzle_return_t ret;
  D_imp_sth(sth);
  if (imp_sth->result) {
    drizzle_row_seek(imp_sth->result, pos);
    if (ret != DRIZZLE_RETURN_OK) {
      RETVAL = 0;
      do_error(sth, drizzle_result_error_code(imp_sth->result), drizzle_result_error(imp_sth->result), drizzle_result_sqlstate(imp_sth->result));
    } else { 
      RETVAL = 1;
    }  
  } else {
    RETVAL = 0;
    do_error(sth, JW_ERR_NOT_ACTIVE, "Statement not active" ,NULL);
  }
}
  OUTPUT:
    RETVAL

void
rows(sth)
    SV* sth
  CODE:
    D_imp_sth(sth);
    char buf[64];
  /* fix to make rows able to handle errors and handle max value from 
     affected rows.
     XXX check to see if this is still a reality -cb
     if drizzleclient_affected_row returns an error, it's value is 18446744073709551614,
     while a (uint64_t)-1 is  18446744073709551615, so we have to add 1 to
     imp_sth->row_num to know if there's an error
  */
  if (imp_sth->row_num+1 ==  (uint64_t) -1)
    sprintf(buf, "%d", -1);
  else
    sprintf(buf, "%lu", imp_sth->row_num);

  ST(0) = sv_2mortal(newSVpvn(buf, strlen(buf)));



MODULE = DBD::drizzle    PACKAGE = DBD::drizzle::GetInfo

# This probably should be grabed out of some ODBC types header file
#define SQL_CATALOG_NAME_SEPARATOR 41
#define SQL_CATALOG_TERM 42
#define SQL_DBMS_VER 18
#define SQL_IDENTIFIER_QUOTE_CHAR 29
#define SQL_MAXIMUM_STATEMENT_LENGTH 105
#define SQL_MAXIMUM_TABLES_IN_SELECT 106
#define SQL_MAX_TABLE_NAME_LEN 35
#define SQL_SERVER_NAME 13


#  dbd_drizzle_getinfo()
#  Return ODBC get_info() information that must needs be accessed from C
#  This is an undocumented function that should only
#  be used by DBD::drizzle::GetInfo.

void
dbd_drizzle_get_info(dbh, sql_info_type)
    SV* dbh
    SV* sql_info_type
  CODE:
    D_imp_dbh(dbh);
    IV type = 0;
    SV* retsv=NULL;
    bool using_322=0;

    if (SvMAGICAL(sql_info_type))
        mg_get(sql_info_type);

    if (SvOK(sql_info_type))
    	type = SvIV(sql_info_type);
    else
    	croak("get_info called with an invalied parameter");
    
    switch(type) {
    	case SQL_CATALOG_NAME_SEPARATOR:
	    /* (dbc->flag & FLAG_NO_CATALOG) ? WTF is in flag ? */
	    retsv = newSVpv(".",1);
	    break;
	case SQL_CATALOG_TERM:
	    /* (dbc->flag & FLAG_NO_CATALOG) ? WTF is in flag ? */
	    retsv = newSVpv("database",8);
	    break;
	case SQL_DBMS_VER:
	    retsv = newSVpv(
	        drizzle_con_server_version(imp_dbh->con),
		strlen(drizzle_con_server_version(imp_dbh->con))
	    );
	    break;
	case SQL_IDENTIFIER_QUOTE_CHAR:
	    /*XXX What about a DB started in ANSI mode? */
	    /* Swiped from MyODBC's get_info.c */
	    retsv = newSVpv("`", 1);
	    break;
	case SQL_MAXIMUM_STATEMENT_LENGTH:
	    retsv = newSViv(8192);
	    break;
	case SQL_MAXIMUM_TABLES_IN_SELECT:
	    /* newSViv((sizeof(int) > 32) ? sizeof(int)-1 : 31 ); in general? */
	    retsv= newSViv((sizeof(int) == 64 ) ? 63 : 31 );
	    break;
	case SQL_MAX_TABLE_NAME_LEN:
      // XXX need to look this up
	    retsv= newSViv(254);
	    break;
	case SQL_SERVER_NAME:
	    retsv= newSVpv(drizzle_con_host(imp_dbh->con),strlen(drizzle_con_host(imp_dbh->con)));
	    break;
    	default:
 		croak("Unknown SQL Info type");
    }
    ST(0) = sv_2mortal(retsv);

