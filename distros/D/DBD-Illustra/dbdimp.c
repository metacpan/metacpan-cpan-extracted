/*##############################################################################
#
#   File name: dbdimp.c
#   Project: DBD::Illustra
#   Description: Main implementation file
#
#   Author: Peter Haworth
#   Date created: 17/07/1998
#
#   sccs version: 1.18    last changed: 10/13/99
#
#   Copyright (c) 1998 Institute of Physics Publishing
#   You may distribute under the terms of the Artistic License,
#   as distributed with Perl, with the exception that it cannot be placed
#   on a CD-ROM or similar media for commercial distribution without the
#   prior approval of the author.
#
##############################################################################*/


#include "Illustra.h"

DBISTATE_DECLARE;

/* Predeclare stuff defined at the bottom */
static int exec_query(SV *,imp_dbh_t *,const char *);
static void kill_query(imp_dbh_t *);

/* These variables are populated by the call back handler */
static char sqlcode[6];
static char errmsg[1024];

/* Store error codes and messages in either handle */
void do_error(SV* h, int rc, char* what){
  D_imp_xxh(h);
  SV* errstr=DBIc_ERRSTR(imp_xxh);

  sv_setiv(DBIc_ERR(imp_xxh),(IV)(rc ? rc : MI_ERROR)); /* set err early */
  sv_setpv(errstr,errmsg[0] ? errmsg : what);
  sv_setpv(DBIc_STATE(imp_xxh),sqlcode[0] ? sqlcode : "S1000");
  DBIh_EVENT2(h,ERROR_event,DBIc_ERR(imp_xxh),errstr);

  if(dbis->debug >= 2){
    fprintf(DBILOGFP,"%s error %d recorded: %s\n",
      what,rc,SvPV(errstr,na)
    );
  }
}

/* Callback handler */
static void MI_PROC_CALLBACK
all_callback(MI_EVENT_TYPE type,MI_CONNECTION *conn,void *cb_data,void *u_data){
  mi_integer elevel;
  char *levelstr;

  sqlcode[0]=0;

  switch(type){
  case MI_Exception:
    /* Some sort of server error */
    switch(elevel=mi_error_level(cb_data)){
    case MI_MESSAGE:
      levelstr="MI_MESSAGE";
      break;
    case MI_EXCEPTION:
      levelstr="MI_EXCEPTION";
      break;
    case MI_FATAL:
      levelstr="MI_FATAL";
      break;
    default:
      levelstr="unknown level";
    }
    mi_errmsg(cb_data,errmsg,1024);
    mi_error_sql_code(cb_data,sqlcode,5);
    if(dbis->debug >= 3)
      fprintf(DBILOGFP,"DBD::Illustra callback MI_Exception(%s): '%s' %s\n",
	levelstr,sqlcode,errmsg
      );
    break;
  case MI_Client_Library_Error:
    /* Internal library error */
    switch(elevel=mi_error_level(cb_data)){
    case MI_LIB_BADARG:
      levelstr="MI_LIB_BADARG";
      break;
    case MI_LIB_USAGE:
      levelstr="MI_LIB_USAGE";
      break;
    case MI_LIB_INTERR:
      levelstr="MI_LIB_INTERR";
      break;
    case MI_LIB_NOIMP:
      levelstr="MI_LIB_NOIMP";
      break;
    case MI_LIB_DROPCONN:
      levelstr="MI_LIB_DROPCONN";
      break;
    default:
      levelstr="unknown level";
    }
    mi_errmsg(cb_data,errmsg,1024);
    if(dbis->debug >= 3)
      fprintf(DBILOGFP,
	"DBD::Illustra callback MI_Client_Library_Error(%s): %s\n",
	levelstr,errmsg
      );
    break;
  case MI_Alerter_Fire_Msg:
    /* Alerter fired or dropped */
    levelstr=mi_alert_status(cb_data)==MI_ALERTER_DROPPED ? "dropped" : "fired";
    if(dbis->debug >= 3)
      fprintf(DBILOGFP,
	"DBD::Illustra callback MI_Alerter_Fire_Msg(%s): %s\n",
	levelstr,mi_alert_name(cb_data)
      );
    break;
  case MI_Xact_State_Change:{
    mi_integer oldlevel,newlevel;

    /* XXX; We might want to do something clever eventually... */
    switch(elevel=mi_xact_state(cb_data)){
    case MI_XACT_BEGIN:
      levelstr="Started";
      break;
    case MI_XACT_END:
      levelstr="Ended";
      break;
    case MI_XACT_ABORT:
      levelstr="Aborted";
      break;
    default:
      levelstr="unknown";
    }
    mi_xact_levels(cb_data,&oldlevel,&newlevel);
    if(dbis->debug >= 3)
      fprintf(DBILOGFP,
	"DBD::Illustra callback MI_Xact_State_Change(%s): Old: %d, New: %d\n",
	levelstr,oldlevel,newlevel
      );
  } break;
  case MI_Delivery_Status_Msg:
  case MI_Query_Interrupt_Ack:
  case MI_Print:
  case MI_Request:
  case MI_Tape_Request:
  default:
    Perl_warn("XXX Caught unknown callback: %d\n",type);
  }
}

/* Called when driver first loaded */
void dbd_init(dbistate_t* dbistate){
  DBIS=dbistate; /* Initialize the DBI macros */

  /* Register the global callback handler.
   * We have to call this before any other mi_ functions
   */
  mi_add_callback(MI_All_Events,all_callback,0);

  /* Disable pointer checks, because they don't seem to work */
  {
    MI_PARAMETER_INFO pinfo;

    mi_get_parameter_info(&pinfo);
    pinfo.callbacks_enabled=1;
    pinfo.pointer_checks_enabled=0;
    mi_set_parameter_info(&pinfo);
  }
}

int dbd_discon_all(SV* drh,imp_drh_t* imp_drh){
  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_discon_all called\n");
  /* XXX This is just copied from DBD::Oracle, like DBI::DBD says... */
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

/* Connect to a database */
int dbd_db_login(SV *dbh,imp_dbh_t *imp_dbh,char *dbname,char *uid,char *pwd){
  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_db_login called\n");

  /* Connect to database */
  if((imp_dbh->conn=mi_open(dbname,uid,pwd))==NULL){
    do_error(dbh,0,"Can't connect");
    return FALSE;
  }

  DBIc_IMPSET_on(imp_dbh);		/* imp_dbh is set up */
  DBIc_ACTIVE_on(imp_dbh);		/* call disconnect before freeing */
  DBIc_set(imp_dbh,DBIcf_AutoCommit,1); /* Default is AutoCommit on */

  imp_dbh->st_active=0;	/* No active statement */

  return TRUE;
}

/* $dbh->commit */
int dbd_db_commit(SV *dbh,imp_dbh_t *imp_dbh){
  if(dbis->debug>=2)
    fprintf(DBILOGFP,"DBD::Illustra::dbd_db_commit\n");

  return exec_query(dbh,imp_dbh,"commit work;");
}

/* $dbh->rollback */
int dbd_db_rollback(SV *dbh,imp_dbh_t *imp_dbh){
  if(dbis->debug>=2)
    fprintf(DBILOGFP,"DBD::Illustra::dbd_db_rollback\n");
  
  return exec_query(dbh,imp_dbh,"rollback work;");
}

/* Disconnect from database */
int dbd_db_disconnect(SV *dbh,imp_dbh_t *imp_dbh){
  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_db_disconnect called\n");

  /* Rollback uncommitted updates */
  if(!DBIc_has(imp_dbh,DBIcf_AutoCommit)){
    exec_query(dbh,imp_dbh,"rollback work;");
  }

  /* Tell DBI that we've disconnected */
  DBIc_ACTIVE_off(imp_dbh);

  /* Now actually disconnect */
  if(imp_dbh->conn){
    if(mi_close(imp_dbh->conn)){
      /* XXX Replace 0 here with some meaningful error code */
      do_error(dbh,0,"disconnect error");
      return 0;
    }
  }
  /* Clear the connection so dbd_st_finish won't use it */
  imp_dbh->conn=NULL;

  /* Don't free imp_dbh since a reference still exists */
  /* The DESTROY method will free memory */
  return 1;
}

/* Destroy a database handle */
void dbd_db_destroy(SV *dbh,imp_dbh_t *imp_dbh){
  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_db_destroy called\n");

  /* Make sure we have disconnected */
  if(DBIc_is(imp_dbh,DBIcf_ACTIVE))
    dbd_db_disconnect(dbh,imp_dbh);
  
  /* Tell DBI that there's nothing to free */
  DBIc_IMPSET_off(imp_dbh);
}

/* $dbh->STORE, approximately */
int dbd_db_STORE_attrib(SV *dbh,imp_dbh_t *imp_dbh,SV *keysv,SV *valuesv){
  STRLEN kl;
  char *key=SvPV(keysv,kl);
  SV *cachesv=NULL;
  int on=SvTRUE(valuesv);

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_db_STORE_attrib called\n");

  if(kl==10 && strEQ(key,"AutoCommit")){
    /* There is no API for setting autocommit, so we have to execute */

    if(!DBIc_has(imp_dbh,DBIcf_AutoCommit) != !on){
      exec_query(dbh,imp_dbh,on ? "set autocommit on;" : "set autocommit off;");
      DBIc_set(imp_dbh,DBIcf_AutoCommit,on);
    }
  }else{
    return FALSE;
  }
  return TRUE;
}

/* $dbh->FETCH, approximately */
SV *dbd_db_FETCH_attrib(SV *dbh,imp_dbh_t *imp_dbh,SV *keysv){
  STRLEN kl;
  char * key=SvPV(keysv,kl);
  SV *retsv=Nullsv;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_db_FETCH_attrib called\n");

  if(kl==10 && strEQ(key,"AutoCommit")){
    retsv=boolSV(DBIc_has(imp_dbh,DBIcf_AutoCommit));
  }else if(kl==10 && strEQ(key,"ChopBlanks")){
    /* XXX Since we can't tell which fields are "really" fixed width */
    return Nullsv;
  }

  if(!retsv)
    return Nullsv;
  if(retsv==&sv_undef || retsv==&sv_yes || retsv==&sv_no)
    return retsv;
  return sv_2mortal(retsv);
}


/* $sth->prepare */
int dbd_st_prepare(SV *sth,imp_sth_t *imp_sth,char *statement,SV *attribs){
  int num_params=0,i;
  char *ptr,*pstatement,last='\0';
  STRLEN len;
  D_imp_dbh_from_sth;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_st_prepare called\n");

  imp_sth->done_desc=0;

  /* Parse statement for placeholders */
  imp_sth->plen=len=strlen(statement);
  Newz(42,pstatement,len+1,char);
  strncpy(pstatement,statement,len);
  ptr=pstatement;
  while(*ptr){
    if(*ptr=='-'){
      if(last=='-'){
	/* Replace comments with whitespace to make life easier later on */
	while(*ptr && *ptr!='\n')*ptr++=' ';
	last=' ';
      }else{
	last='-';
      }
    }else{
      switch(last=*ptr){
      case '\'':
      case '\"':
	/* Move to end of string */
	/* SQL string escapes make this easy */
	do{ ++ptr; }while(*ptr && *ptr!=last);
	break;
      case '?':
	/* Mark placeholder with NUL */
	++num_params;
	*ptr++='\0';
	break;
      /* Ignore everything else */
      }
    }
    if(!*ptr++)break;
  }
  imp_sth->pstatement=pstatement;
  if(num_params){
    New(42,imp_sth->params,num_params,SV*);
  }else{
    imp_sth->params=0;
  }
  for(i=0;i<num_params;++i){
    imp_sth->params[i]=&sv_undef;
  }

  /* We don't do anything clever yet, so we don't know how many fields exist */
  DBIc_NUM_FIELDS(imp_sth)=0;
  DBIc_NUM_PARAMS(imp_sth)=num_params;

  /* XXX we might want to do something more sophisticated here */
  DBIc_IMPSET_on(imp_sth);

  return 1;
}


/* $sth->execute */
int dbd_st_execute(SV *sth,imp_sth_t *imp_sth){
  D_imp_dbh_from_sth;
  mi_integer res;
  int rows= -3,num_params=0;
  char *c_statement;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_st_execute called\n");

  if(dbis->debug >= 2)
    fprintf(DBILOGFP,"    -> dbd_st_execute for %p\n",sth);
  
  /* Build statement */
  if(num_params=DBIc_NUM_PARAMS(imp_sth)){
    int i;
    STRLEN len=imp_sth->plen;
    char *sptr,*dptr;

    /* Calculate length of string required */
    for(i=0;i<DBIc_NUM_PARAMS(imp_sth);++i){
      SV *val=imp_sth->params[i];

      if(SvOK(val)){
	STRLEN l;
	char *ptr=SvPV(val,l);

	for(len+=l+2;*ptr;++ptr){
	  if(*ptr=='\'')++len;
	}
      }else{
	len+=3;
      }
    }

    /* Build string */
    Newz(42,c_statement,len+1,char);
    for(i=0,sptr=imp_sth->pstatement,dptr=c_statement;i<DBIc_NUM_PARAMS(imp_sth);++i){
      STRLEN l=strlen(sptr);
      SV *val=imp_sth->params[i];

      strcpy(dptr,sptr);
      dptr+=l;
      sptr+=l+1;

      if(SvOK(val)){
	char *sptr=SvPV(val,na);
	*dptr++='\'';
	while(*sptr){
	  if((*dptr++=*sptr++)=='\'')*dptr++='\'';
	}
	*dptr++='\'';
      }else{
	strcpy(dptr,"NULL");
	dptr+=4;
      }
    }
    if(sptr-imp_sth->pstatement < imp_sth->plen)
      strcpy(dptr,sptr);
  }else{
    c_statement=imp_sth->pstatement;
  }

  /* Make sure there isn't an active query */
  kill_query(imp_dbh);

  /* Execute the statement */
  if(mi_exec(imp_dbh->conn,c_statement,0)){
    /* XXX Use useful rc instead of 0 */
    do_error(sth,0,"Can't execute statement");
    if(num_params){
      Safefree(c_statement);
    }
    return -2;
  }
  if(num_params){
    Safefree(c_statement);
  }

  /* Initialise the fetch loop */
  DBIc_NUM_FIELDS(imp_sth)=0;
  while(rows<-2 && (res=mi_get_result(imp_dbh->conn))!=MI_NO_MORE_RESULTS){
    switch(res){
    case MI_ERROR:
      /* XXX rc */
      do_error(sth,0,"Error fetching results");
      return -2;
    case MI_ROWS: {
      MI_ROW_DESC *rowdesc=mi_get_row_desc_without_row(imp_dbh->conn);
      if(rowdesc){
	DBIc_NUM_FIELDS(imp_sth)=mi_column_count(rowdesc);
	rows= -1;
      }else{
	do_error(sth,0,"Can't get rowdesc");
	rows= -2;
      }
    } break;
    case MI_DML: {
      /* DML statement completed. Find number of rows affected */
      rows=mi_result_row_count(imp_dbh->conn);

      if(rows<0){
	do_error(sth,0,"Can't get number of rows");
	rows= -2;
      }
    } break;
    case MI_DDL:
      /* DDL statement completed. Assume no rows affected */
      rows=0;

      break;
    default:
fprintf(DBILOGFP,"mi_get_result() -> %d\n",res);
      break;
    }
  }

  if(!DBIc_NUM_FIELDS(imp_sth)){
    /* This isn't a select, so pretend to have described the results */
    imp_sth->done_desc=1;
  }else if(!imp_sth->done_desc){
    /* Describe results if not already described */
    dbd_describe(sth,imp_sth);
  }
      
  DBIc_ACTIVE_on(imp_sth);
  imp_dbh->st_active=imp_sth;

  return rows<-2 ? -2 : rows;
}

/* dbd_bind_ph: Used by bind_param */
int dbd_bind_ph(SV *sth,imp_sth_t *imp_sth,SV *param,SV *value,IV sql_type,
  SV *attribs,int is_inout,IV maxlen
){
  int param_no;

  if(SvNIOK(param)){
    param_no=(int)SvIV(param);
  }else{
    croak("bind_param: parameter not a number");
  }

  if(dbis->debug>=2)
    fprintf(DBILOGFP,"DBD::Illustra::dbd_bind_ph(%d)\n",param_no);
  
  if(param_no<1 || param_no > DBIc_NUM_PARAMS(imp_sth))
    croak("Illustra(bind_param): parameter outside range 1..%d",
      DBIc_NUM_PARAMS(imp_sth));
  SvREFCNT_dec(imp_sth->params[param_no-1]);
  imp_sth->params[param_no-1]=value;
  SvREFCNT_inc(value);

  return 1;
}

/* INTERNAL function: Build meta data about select */
int dbd_describe(SV *h,imp_sth_t *imp_sth){
  D_imp_dbh_from_sth;
  int num=DBIc_NUM_FIELDS(imp_sth);
  int i;
  STRLEN buflen=0;
  char *buff,*p;
  MI_ROW_DESC *rowdesc;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_describe called\n");

  /* Only do it once! */
  if(imp_sth->done_desc)
    return 1;
  
  if(!(rowdesc=mi_get_row_desc_without_row(imp_dbh->conn))){
    do_error(h,0,"Can't get rowdesc in dbd_describe");
    return 0;
  }

  /* Allocate field buffers */
  Newz(42,imp_sth->fbh,num,imp_fbh_t);
  /* Illustra won't tell us how long the column names are, so we
     have to fetch them all first */
  for(i=0;i<num;++i){
    imp_fbh_t *fbh=&(imp_sth->fbh[i]);
    int type=SQL_VARCHAR; /* All types look like varchars */

    p=fbh->name=mi_column_name(rowdesc,i);
    buflen+=strlen(p)+1;
    p=fbh->type_name=mi_column_type_name(rowdesc,i);
    buflen+=strlen(p)+1;
    fbh->nullable=mi_column_nullable(rowdesc,i);
    fbh->precision=mi_column_bound(rowdesc,i);
    fbh->scale=mi_column_parameter(rowdesc,i);

    /* XXX This really is pathetic.
       Isn't there some way of finding this out properly? */
    if(mi_column_is_arrayof(rowdesc,i)
    || mi_column_is_ref(rowdesc,i)
    || mi_column_is_setof(rowdesc,i)
    ){
      /* Leave as SQL_VARCHAR */
      /* XXX Do stuff with mi_column_subtype_*() */
    }else if(mi_column_is_composite(rowdesc,i)){
      /* Leave as SQL_VARCHAR */
      /* XXX Is anything else possible? */
    }else{
      char *type_name=mi_column_type_name(rowdesc,i);
      if(strEQ(type_name,"char") || strEQ(type_name,"character")){
	type=SQL_CHAR;
      }else if(strEQ(type_name,"numeric")){
	type=SQL_NUMERIC;
      }else if(strEQ(type_name,"decimal")){
	type=SQL_DECIMAL;
      }else if(strEQ(type_name,"int") || strEQ(type_name,"integer")){
	type=SQL_INTEGER;
      }else if(strEQ(type_name,"real")){
	type=SQL_REAL;
      }else if(strEQ(type_name,"date")){
	type=SQL_DATE;
      }else if(strEQ(type_name,"time")){
	type=SQL_TIME;
      }else if(strEQ(type_name,"timestamp") || strEQ(type_name,"abstime")){
	type=SQL_TIMESTAMP;
      }else if(strEQ(type_name,"vchar") || strEQ(type_name,"varchar")){
	type=SQL_VARCHAR;
      }
    }
    fbh->type=type;
  }
  Newz(42,buff,buflen,char);
  p=buff;
  for(i=0;i<num;++i){
    char *q=imp_sth->fbh[i].name;
    STRLEN len=strlen(q);
    Copy(q,p,len,char);
    imp_sth->fbh[i].name=p;
    p+=len+1;

    q=imp_sth->fbh[i].type_name;
    len=strlen(q);
    Copy(q,p,len,char);
    imp_sth->fbh[i].type_name=p;
    p+=len+1;
  }

  imp_sth->name_data=buff;
  imp_sth->done_desc=1;

  return 1;
}

/* $sth->fetch */
AV *dbd_st_fetch(SV *sth,imp_sth_t *imp_sth){
  D_imp_dbh_from_sth;

  AV *av;
  mi_integer error;
  MI_ROW *row;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_st_fetch called\n");

  if(dbis->debug >= 2)
    fprintf(DBILOGFP,"    -> dbd_st_fetch for %p\n",sth);

  if(!imp_dbh->st_active){
warn("dbd_st_fetch() on non-active sth\n");
    return Nullav;
  }

  if((row=mi_next_row(imp_dbh->conn,&error))==NULL){
    if(error){
      /* XXX rc */
      do_error(sth,0,"Error fetching row");
    }else{
      if(mi_query_finish(imp_dbh->conn))
	do_error(sth,0,"Error finishing query");
    }
    DBIc_ACTIVE_off(imp_sth);
    imp_dbh->st_active=0;
    return Nullav;
  }else{
    int ChopBlanks=DBIc_is(imp_sth,DBIcf_ChopBlanks);
    int i,numfields=DBIc_NUM_FIELDS(imp_sth); /* XXX watch out for ragged rows! */
    imp_fbh_t *fbh=imp_sth->fbh;
    av=DBIS->get_fbav(imp_sth);

    for(i=0;i<numfields;i++){
      mi_integer collen;
      char *colval;
      SV *sv=AvARRAY(av)[i]; /* (re)use the SV in the AV */

      switch(mi_value(row,i,&colval,&collen)){
      case MI_ERROR:
      default: /* XXX What other types are there? */
	/* XXX rc */
	do_error(sth,0,"Can't fetch column of unknown type");
	/* fall through */
      case MI_NULL_VALUE:
	(void)SvOK_off(sv); /* Field is NULL, return undef */
	break;
      case MI_NORMAL_VALUE:
	if(ChopBlanks){
	  while(collen && isspace(colval[collen-1])){
	    --collen;
	  }
	}

	if(dbis->debug >= 2){
	  fprintf(DBILOGFP,"      Storing col %d (%s) in %p\n",i,colval,sv);
	}
	sv_setpvn(sv,colval,(STRLEN)collen);
	break;
      }
    }
  }

  return av;
}

int dbd_st_blob_read(SV *sth,imp_sth_t *imp_sth,int field,long offset,long len,
  SV *destrv,long destoffset
){
  die("DBD::Illustra: blob_read not implemented");
  return 0;
}

/* $sth->finish */
int dbd_st_finish(SV *sth,imp_sth_t *imp_sth){
  D_imp_dbh_from_sth;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_st_finish called\n");

  /* Finish the query (but only if it's "ours") */
  if(imp_dbh->conn && imp_dbh->st_active==imp_sth){
    imp_dbh->st_active=0;
    if(mi_query_finish(imp_dbh->conn)){
      do_error(sth,0,"Can't finish query");
      return 0;
    }
  }

  /* Tell DBI that the query is finished */
  DBIc_ACTIVE_off(imp_sth);

  return 1;
}

/* $sth->DESTROY, kind of */
void dbd_st_destroy(SV *sth,imp_sth_t *imp_sth){
  if(dbis->debug>=4)
    fprintf(DBILOGFP,"ill_st_destroy called\n");

  /* Make sure the statement is not still in use */
  if(DBIc_is(imp_sth,DBIcf_ACTIVE))
    dbd_st_finish(sth,imp_sth);
  
  if(imp_sth->pstatement)Safefree(imp_sth->pstatement);
  if(imp_sth->params){
    int i;
    for(i=0;i<DBIc_NUM_PARAMS(imp_sth);i++){
      SvREFCNT_dec(imp_sth->params[i]);
    }
    Safefree(imp_sth->params);
  }
  if(imp_sth->done_desc){
    Safefree(imp_sth->fbh);
    Safefree(imp_sth->name_data);
  }
  DBIc_IMPSET_off(imp_sth);
}

/* $sth->FETCH, approximately */
SV *dbd_st_FETCH_attrib(SV *sth,imp_sth_t *imp_sth,SV *keysv){
  STRLEN kl;
  char *key=SvPV(keysv,kl);
  int i=DBIc_NUM_FIELDS(imp_sth);
  AV *av;
  SV *retsv=NULL;

  if(dbis->debug>=3)
    fprintf(DBILOGFP,"DBD::Illustra::dbd_st_FETCH->{%s}\n",key);

  if(kl==4 && strEQ(key,"NAME")){
    av=newAV();
    retsv=newRV(sv_2mortal((SV*)av));
    while(--i>=0)
      av_store(av,i,newSVpv(imp_sth->fbh[i].name,0));
  }else if(kl==8 && strEQ(key,"NULLABLE")){
    av=newAV();
    retsv=newRV(sv_2mortal((SV*)av));
    while(--i>=0)
      av_store(av,i,newSViv(imp_sth->fbh[i].nullable));
  }else if(kl==9 && strEQ(key,"PRECISION")){
    av=newAV();
    retsv=newRV(sv_2mortal((SV*)av));
    while(--i>=0)
      av_store(av,i,newSViv(imp_sth->fbh[i].precision));
  }else if(kl==5 && strEQ(key,"SCALE")){
    av=newAV();
    retsv=newRV(sv_2mortal((SV*)av));
    while(--i>=0){
      int s=imp_sth->fbh[i].scale;

      av_store(av,i,s ? newSViv(s) : &sv_undef);
    }
  }else if(kl==4 && strEQ(key,"TYPE")){
    av=newAV();
    retsv=newRV(sv_2mortal((SV*)av));
    while(--i>=0)
      av_store(av,i,newSViv(imp_sth->fbh[i].type));
  }else if(kl==12 && strEQ(key,"ill_TypeName")){
    av=newAV();
    retsv=newRV(sv_2mortal((SV*)av));
    while(--i>=0)
      av_store(av,i,newSVpv(imp_sth->fbh[i].type_name,0));
  }else{
    return Nullsv;
  }

  return sv_2mortal(retsv);
}

/* $sth->STORE, approximately */
int dbd_st_STORE_attrib(SV *sth,imp_sth_t *imp_sth,SV *keysv,SV *valuesv){
  STRLEN kl;
  char *key=SvPV(keysv,kl);

  if(dbis->debug>=3)
    fprintf(DBILOGFP,"DBD::Illustra::dbd_st_STORE->{%s}\n",key);

  /* Nothing to store */
  return 0;
}

/* INTERNAL function to finish the currently active query if necessary */
static void kill_query(imp_dbh_t *imp_dbh){
  imp_sth_t *active=imp_dbh->st_active;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"kill_query called\n");

  if(active){
    mi_query_finish(imp_dbh->conn);
    DBIc_ACTIVE_off(active);
  }

  imp_dbh->st_active=0;
}

/* Quick and dirty execution of statements */
static int exec_query(SV *dbh,imp_dbh_t *imp_dbh,const char *st){
  MI_CONNECTION *conn=imp_dbh->conn;
  mi_integer res;
  int ok=1;

  if(dbis->debug>=4)
    fprintf(DBILOGFP,"exec_query(\"%s\") called\n",st);

  /* Make sure there's no active query */
  kill_query(imp_dbh);

  /* Execute the statement */
  if(mi_exec(conn,st,0)){
    do_error(dbh,0,"Can't exec_query");
    return 0;
  }
  while((res=mi_get_result(conn))!=MI_NO_MORE_RESULTS){
    if(res==MI_ERROR){
      do_error(dbh,0,"Error getting results of exec_query");
      ok=0;
      break;
    }
  }
  if(mi_query_finish(conn) && ok)
    do_error(dbh,0,"Error finishing query in exec_query");

  return ok;
}

