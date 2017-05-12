///////////////////////////////////////////////////////////////////////////////
//                                                         
// dbdimp.c
// --------
// Cego perl DBD database driver implementation
// 
// derived from SQLite driver implementation
//                                               
// Design and Implementation by Bjoern Lemke               
//                                                         
// (C)opyright 2007-2013 by Bjoern Lemke                        
//
///////////////////////////////////////////////////////////////////////////////

#include <lfcbase/Tokenizer.h>
#include <lfcbase/Net.h>
#include <lfcbase/NetHandler.h>

#include <cego/CegoTableObject.h>
#include <cego/CegoViewObject.h>
#include <cego/CegoKeyObject.h>
#include <cego/CegoProcObject.h>

#include "CegoXS.h"

#define NETMSG_BUFLEN 8192
#define NETMSG_SIZEBUFLEN 10 

DBISTATE_DECLARE;

STRLEN myPL_na;

void
cego_init(dbistate_t *dbistate)
{
    dTHR;
    DBIS = dbistate;
}

void
cego_error(SV *h, int rc, char *what)
{
    dTHR;
    D_imp_xxh(h);

    SV *errstr = DBIc_ERRSTR(imp_xxh);
    sv_setiv(DBIc_ERR(imp_xxh), (IV)rc);
    sv_setpv(errstr, what);
    // DBIh_SET_ERR_CHAR(h, imp_xxh, Nullch, rc, what, Nullch, Nullch);

    /*
    if (DBIc_TRACE_LEVEL(imp_xxh) >= 2)
	PerlIO_printf(DBIc_LOGPIO(imp_xxh), "%s : %s\n",
		      "CegoDBD", neatsvpv(errstr,0));
    */
}

int
cego_db_login(SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *user, char *pass)
{
    dTHR;
    char *errmsg = NULL;

    Chain serverName( imp_dbh->hostname );
    int portNo = imp_dbh->port;

    imp_dbh->activeTransaction = FALSE;
    imp_dbh->activeQuery = FALSE;
    imp_dbh->in_tran = FALSE;
    imp_dbh->no_utf8_flag = FALSE;
        
    Chain tableSet(dbname);
    Chain dbUser(user);
    Chain dbPWD(pass);

    Chain logFile(imp_dbh->logfile);
    Chain logMode(imp_dbh->logmode);
    Chain prot(imp_dbh->protocol);
    
    CegoDbHandler::ProtocolType protocol;
    if ( prot == Chain("serial"))
	protocol=CegoDbHandler::SERIAL;
    else if ( prot == Chain("xml"))
	protocol=CegoDbHandler::XML;
    else
    {
	cego_error(dbh, 1, (char*)"Invalid protocol" );	
	return FALSE;
    }

    imp_dbh->cgnet = new CegoNet( protocol, logFile, Chain(""), logMode );
    
    try
    {
	imp_dbh->cgnet->connect(serverName, portNo, tableSet, dbUser, dbPWD);
    }
    catch ( Exception e )
    {
	Chain msg;
	e.pop(msg);
	cego_error(dbh, 1, (char*)msg );	
	return FALSE;
    }

    DBIc_IMPSET_on(imp_dbh);
    DBIc_ACTIVE_on(imp_dbh);
    
    // AutoCommit is on default true
    DBIc_set(imp_dbh, DBIcf_AutoCommit, 1);

    return TRUE;
}

int
cego_db_disconnect (SV *dbh, imp_dbh_t *imp_dbh)
{
    dTHR;
    DBIc_ACTIVE_off(imp_dbh);


    if ( imp_dbh->cgnet == NULL )
    {
	Chain msg = Chain("Invalid database handle");
	cego_error(dbh, 1, (char*)msg);
	return -1;       
    }

    if (DBIc_is(imp_dbh, DBIcf_AutoCommit) == FALSE && imp_dbh->activeTransaction == true) {
        cego_db_rollback(dbh, imp_dbh);
    }

    try
    {
	imp_dbh->cgnet->disconnect();
    }
    catch ( Exception e )
    {
	Chain msg;
	e.pop(msg);
	cego_error(dbh, 1, (char*)msg );	
	return FALSE;
    }

    delete imp_dbh->cgnet;
    imp_dbh->cgnet=NULL;
    
    return TRUE;
}

void
cego_db_destroy (SV *dbh, imp_dbh_t *imp_dbh)
{
    dTHR;
    if (DBIc_ACTIVE(imp_dbh)) {
        cego_db_disconnect(dbh, imp_dbh);
    }
    DBIc_IMPSET_off(imp_dbh);
}

int
cego_db_rollback(SV *dbh, imp_dbh_t *imp_dbh)
{
    dTHR;
    int retval;
    char *errmsg;

    if ( imp_dbh->cgnet == NULL )
    {
	Chain msg = Chain("Invalid database handle");
	cego_error(dbh, 1, (char*)msg);
	return FALSE;       
    }


    if (DBIc_is(imp_dbh, DBIcf_AutoCommit)) {
        warn("Rollback ineffective with AutoCommit");
        return TRUE;
    }

    Chain stmt("rollback;");

    int res;
    try
    {
	res = imp_dbh->cgnet->doQuery(stmt);
    }
    catch ( Exception  e )
    {
	Chain msg;
	e.pop(msg);
	cego_error(dbh, 1, (char*)msg );	
	return FALSE;
    }

    imp_dbh->activeTransaction=false;

    return TRUE;
}



int
cego_db_begin(SV *dbh, imp_dbh_t *imp_dbh)
{
    dTHR;

    int retval;
    char *errmsg;

    if ( imp_dbh->cgnet == NULL )
    {
	Chain msg = Chain("Invalid database handle");
	cego_error(dbh, 1, (char*)msg);
	return FALSE;       
    }

    if (DBIc_is(imp_dbh, DBIcf_AutoCommit)) {
        warn("Commit ineffective with AutoCommit");
        return TRUE;
    }


    int res;
    Chain stmt("start transaction;");

    try
    {
	res = imp_dbh->cgnet->doQuery(stmt);
    }
    catch ( Exception e )
    {
	Chain msg;
	e.pop(msg);
	cego_error(dbh, 1, (char*)msg );	
	return FALSE;
    }

    imp_dbh->activeTransaction=true;
    return TRUE;
}


int
cego_db_commit(SV *dbh, imp_dbh_t *imp_dbh)
{
    dTHR;

    int retval;
    char *errmsg;

    if ( imp_dbh->cgnet == NULL )
    {
	Chain msg = Chain("Invalid database handle");
	cego_error(dbh, 1, (char*)msg);
	return FALSE;       
    }


    if (DBIc_is(imp_dbh, DBIcf_AutoCommit)) {
        warn("Commit ineffective with AutoCommit");
        return TRUE;
    }

    int res;
    Chain stmt("commit;");
    
    try
    {
	res = imp_dbh->cgnet->doQuery(stmt);
    }
    catch ( Exception e )
    {
	Chain msg;
	e.pop(msg);
	cego_error(dbh, 1, (char*)msg );	
	return FALSE;
    }

    imp_dbh->activeTransaction=false;
    return TRUE;
}

int
cego_discon_all(SV *drh, imp_drh_t *imp_drh)
{
    dTHR;
    /* no way to do this. Just return OK */
    return TRUE;
}

int
cego_st_prepare (SV *sth, imp_sth_t *imp_sth,
                char *statement, SV *attribs)
{

    dTHR;
    D_imp_dbh_from_sth;

    sv_setpv(DBIc_ERRSTR(imp_dbh), "");

    DBIc_IMPSET_on(imp_sth);

    int numParams=0;
    Chain c = Chain(statement).cutTrailing(" ");

    if ( c.subChain(1,1) == Chain("?") )
    {
	imp_sth->hasRetValue=true;
	numParams++;
    }
    else
    {
	imp_sth->hasRetValue=false;
    }

    if ( c.subChain(c.length()-1,c.length()-1) == Chain("?") )
	numParams++;

    Tokenizer tok(Chain(statement), "?");
    imp_sth->stmtChunks = new ListT<Chain>;

    Chain token;

    tok.nextToken(token);
    imp_sth->stmtChunks->Insert(token);
	
    while ( tok.nextToken(token) == true) 	
    {
	imp_sth->stmtChunks->Insert(token);
	numParams++;
    }

    if ( numParams > 0 )
	imp_sth->paramList = new ListT<CegoDBDParam>;

    DBIc_NUM_PARAMS(imp_sth) = numParams;
    
    return TRUE;
}

int
cego_st_execute (SV *sth, imp_sth_t *imp_sth)
{

    dTHR;
    D_imp_dbh_from_sth;

    SV *sql;
    I32 pos = 0;
    char *errmsg;
    int num_params = DBIc_NUM_PARAMS(imp_sth);
    I32 i;
    int retval;

    if ( imp_dbh->cgnet == NULL )
    {
	Chain msg = Chain("Invalid database handle");
	cego_error(sth, 1, (char*)msg);
	return -1;       
    }

    if ( imp_dbh->activeQuery == TRUE )
    {
	imp_dbh->cgnet->abortQuery();
    }
    
    Chain stmt;
    Chain param;
    if ( num_params == 0 )
    {
	stmt = *(imp_sth->stmtChunks->First());
    }
    else
    {

	pos=1;

	Chain* pChunk = imp_sth->stmtChunks->First();

	if ( imp_sth->hasRetValue )
	{
	    Chain id(pos);
	    CegoDBDParam* pParam = imp_sth->paramList->Find( CegoDBDParam(id) );
	    stmt = Chain(":p") + pParam->getId() + *pChunk;   
	    pos++;
	}
	else
	{
	    stmt = *pChunk;
	}
       
	pChunk = imp_sth->stmtChunks->Next();
	while ( pChunk )
	{
	    
	    Chain id(pos);

	    CegoDBDParam* pParam = imp_sth->paramList->Find( CegoDBDParam(id) );
	    if ( pParam )
	    {
		if ( pParam->getRef() == 0 )
		    stmt += pParam->getValue() + *pChunk; 
		else
		    stmt += Chain(":p") + pParam->getId() + *pChunk;	       
	    }
	    else
	    {
		
		// if parameter not set, we set null value

		stmt += Chain(" null ") + *pChunk;		

		/*
		Chain msg = Chain("Missing parameter at position ") + Chain(pos);
		cego_error(sth, 1, (char*)msg);
		return -1;
		*/
	    }

	    pChunk = imp_sth->stmtChunks->Next();

	    pos++;
	}
	
	

	// find trailing parameter 
	Chain id(pos);
	CegoDBDParam* pParam = imp_sth->paramList->Find( CegoDBDParam(id) );
	if ( pParam )
	{
	    if ( pParam->getRef() == 0 )
		stmt += pParam->getValue(); 
	    else
		stmt += Chain(":p") + pParam->getId();	       
	}
    }
    
    // normalize to plain statement
    stmt = stmt.cutTrailing(" ;");
    
    if (stmt == Chain("quit") )
	return 0;
    
    // cego parser expects trailing semicolon
    stmt = stmt + Chain(";");
    
    if (! DBIc_is(imp_dbh, DBIcf_AutoCommit) && imp_dbh->activeTransaction == false) {
	cego_db_begin(sth, imp_dbh);
    }

    int res;
    try
    {
	res = imp_dbh->cgnet->doQuery(stmt);
    }
    catch ( Exception e )
    {
	Chain execmsg;
	e.pop(execmsg);
	Chain msg = Chain("Query failed : ") + execmsg;
	cego_error(sth, 1, (char*)msg ); 
	return -1;
    }

    int retCode;

    if ( imp_dbh->cgnet->isFetchable() )
    {
	imp_sth->schema = new ListT<CegoField>;
	imp_dbh->cgnet->getSchema(*(imp_sth->schema));
	imp_dbh->activeQuery = TRUE;
	DBIc_NUM_FIELDS(imp_sth) = imp_sth->schema->Size();
	retCode = 1;
    }
    else
    {
	if ( imp_sth->paramList )
	{
	    ListT<CegoProcVar> outParamList;
	    CegoFieldValue retValue;
	    
	    imp_dbh->cgnet->getProcResult(outParamList, retValue);

	    CegoDBDParam* pParam = imp_sth->paramList->First();
	    while ( pParam )
	    {
		SV* pSV = pParam->getRef();
		if ( pSV )
		{	     		    
		    CegoProcVar* pVar = outParamList.Find(CegoProcVar(Chain("p") + pParam->getId()));
		    if ( pVar )
		    {
			sv_setpv(pSV, (char*)pVar->getValue().valAsChain()); 
		    }
		    else if ( pParam->getId() == 1 )
		    {
			
			sv_setpv(pSV, (char*)retValue.valAsChain()); 
		    }		    
		}	  
		pParam = imp_sth->paramList->Next();
	    }
	}
	Chain msg;
	msg = imp_dbh->cgnet->getMsg();
	imp_sth->msg = new char[ msg.length() ];
	strcpy(imp_sth->msg, (char*)msg);
	imp_sth->affected = imp_dbh->cgnet->getAffected();
	retCode = 0;
    }

    DBIc_ACTIVE_on(imp_sth);
    DBIc_IMPSET_on(imp_sth);
    
    return retCode;
}

int
cego_st_rows (SV *sth, imp_sth_t *imp_sth)
{
    // actually not implemented
    return 0;
}

int
cego_bind_ph (SV *sth, imp_sth_t *imp_sth,
	      SV *param, SV *value, IV sql_type, SV *attribs,
	      int is_inout, IV maxlen)
{

    dTHR;
    char *id = SvPV(param, myPL_na);
    char *pval = SvPV(value, myPL_na);

    Chain qVal;

    if ( *pval == 0 )
    {
	qVal = Chain("null");
    }
    else if ( sql_type == SQL_VARCHAR ) 
    {
	Chain rawVal(pval);
	Chain escVal;
	rawVal.replaceAll(Chain("'"), Chain("''"), escVal);
	qVal = Chain("'") + Chain(escVal) + Chain("'");
    }
    else
    {
	qVal = Chain(pval);
    }

    if ( imp_sth->paramList )
    {
	if ( is_inout )
	{
	    CegoDBDParam *pParam = imp_sth->paramList->Find( CegoDBDParam(id) );
	    if ( pParam )
	    {
		pParam->setValue(qVal);
		pParam->setRef(value);
	    }
	    else
	    {
		imp_sth->paramList->Insert( CegoDBDParam(id, qVal, value) );
	    }    
	}
	else
	{
	    CegoDBDParam *pParam;
	    if ( ( pParam = imp_sth->paramList->Find( CegoDBDParam(id) )) != 0 )
	    {
		pParam->setValue(qVal);
	    }
	    else
	    {
		imp_sth->paramList->Insert( CegoDBDParam(id, qVal) );
	    }
	}
    }
    return TRUE;
}

AV *
cego_st_fetch (SV *sth, imp_sth_t *imp_sth)
{
    AV *av;
    D_imp_dbh_from_sth;

    if ( imp_dbh->cgnet == NULL )
    {
	Chain msg = Chain("Invalid database handle");
	cego_error(sth, 1, (char*)msg);
	return Nullav;       
    }

    int numFields = DBIc_NUM_FIELDS(imp_sth);
    int chopBlanks = DBIc_is(imp_sth, DBIcf_ChopBlanks);
    int i;


    Chain msg;
    CegoDbHandler::ResultType res;
    
    ListT<CegoFieldValue> fvl;

    try
    {
	if ( imp_dbh->cgnet->fetchData(*(imp_sth->schema), fvl) )
	{
	    av = DBIS->get_fbav(imp_sth);
	    int pos=0;
	    CegoFieldValue *pFV = fvl.First();
	    while ( pFV )
	    {
		if ( pFV->isNull() )
		{
		    sv_setpvn(AvARRAY(av)[pos], 0, 0);
		}
		else
		{ 
		    sv_setpvn(AvARRAY(av)[pos], 
			      pFV->valAsChain(),
			      pFV->valAsChain().length() - 1 );
		} 
		pFV = fvl.Next();
		pos++;
	    }
	    fvl.Empty();    

	    // av = DBIS->get_fbav(imp_sth);
	}
	else
	{	    
	    imp_dbh->activeQuery = FALSE;
	    DBIc_ACTIVE_off(imp_sth);
	    // return Nullav;
	    av = Nullav;
	    
	}
    }
    catch ( Exception e )
    {
	Chain msg;
	e.pop(msg);
	cego_error(sth, 1, (char*)msg );	
	return Nullav;
    }

    return av;
}

int
cego_st_finish (SV *sth, imp_sth_t *imp_sth)
{
    D_imp_dbh_from_sth;

    if ( imp_dbh->activeQuery == TRUE )
    {
	if ( imp_dbh->cgnet != NULL )
	    imp_dbh->cgnet->abortQuery();
	imp_dbh->activeQuery = FALSE;
    }

    if (DBIc_ACTIVE(imp_sth)) {
        DBIc_ACTIVE_off(imp_sth);

	if ( imp_sth->schema )
	    delete imp_sth->schema;
	if ( imp_sth->stmtChunks )
	    delete imp_sth->stmtChunks;
	if ( imp_sth->msg )
	    delete imp_sth->msg;

	imp_sth->affected = 0;
	imp_sth->msg = NULL;
	imp_sth->schema = NULL;
	imp_sth->stmtChunks = NULL;
    }
   
    return TRUE;
}

void
cego_st_destroy (SV *sth, imp_sth_t *imp_sth)
{
    if (DBIc_ACTIVE(imp_sth)) {
        cego_st_finish(sth, imp_sth);
    }
    DBIc_IMPSET_off(imp_sth);
}

int
cego_st_blob_read (SV *sth, imp_sth_t *imp_sth,
                int field, long offset, long len, SV *destrv, long destoffset)
{
    croak("cego_st_blob_read not implemented");    
}

int
cego_db_STORE_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)
{
    dTHR;
    char *key = SvPV(keysv, myPL_na);
    char *val = SvPV(valuesv, myPL_na);
    char *errmsg;
    int retval;
    
    if (strncmp(key, "AutoCommit", 10) == 0) 
    {
        DBIc_set(imp_dbh, DBIcf_AutoCommit, SvTRUE(valuesv));
        return TRUE;
    }
    else if (strncmp(key, "NoUTF8Flag", 10) == 0) 
    {
        warn("NoUTF8Flag is deprecated due to perl unicode weirdness\n");
        if (SvTRUE(valuesv)) {
            imp_dbh->no_utf8_flag = TRUE;
        }
        else {
            imp_dbh->no_utf8_flag = FALSE;
        }
        return TRUE;
    }
    if (strncmp(key, "hostname", 8) == 0) 
    {
	strcpy(imp_dbh->hostname, val);
	return TRUE;       	
    }
    if (strncmp(key, "logfile", 7) == 0) 
    {
	strcpy(imp_dbh->logfile, val); 
	return TRUE;
    }
    if (strncmp(key, "logmode", 7) == 0) 
    {
	strcpy(imp_dbh->logmode, val); 
	return TRUE;
    }
    if (strncmp(key, "protocol", 8) == 0) 
    {
	strcpy(imp_dbh->protocol, val); 
	return TRUE;
    }
    if (strncmp(key, "port", 4) == 0) 
    {
        imp_dbh->port = atoi(val);
	return TRUE;
    }        
    return FALSE;
}

SV *
cego_db_FETCH_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)
{
    dTHR;
    char *key = SvPV(keysv, myPL_na);

    if (strncmp(key, "AutoCommit", 10) == 0) {
        return newSViv(DBIc_is(imp_dbh, DBIcf_AutoCommit));
    }
    if (strncmp(key, "NoUTF8Flag", 10) == 0) {
        return newSViv(imp_dbh->no_utf8_flag ? 1 : 0);
    }
    return NULL;
}

int
cego_db_STORE_attrib_k (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, int dbikey, SV *valuesv)
{
    dTHR;
    return FALSE;
}

SV *
cego_db_FETCH_attrib_k (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, int dbikey)
{
    dTHR;
    return NULL;
}

int
cego_st_STORE_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)
{
    
    char *key = SvPV(keysv, myPL_na);

    if (strEQ(key, "ChopBlanks")) {
        DBIc_set(imp_sth, DBIcf_ChopBlanks, SvIV(valuesv));
        return TRUE;
    }
    return FALSE;
}

SV *
cego_st_FETCH_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv)
{
    char *key = SvPV(keysv, myPL_na);
    SV *retsv = NULL;
    int i;
    
    if (strEQ(key, "AFFECTED")) 
    {
	retsv = sv_2mortal(newSViv(imp_sth->affected));
	return retsv;
    }

    if (strEQ(key, "MSG")) 
    {
	retsv = sv_2mortal(newSVpv((char*)imp_sth->msg, strlen(imp_sth->msg)));
	return retsv;
    }
    
    if ( imp_sth->schema->Size() == 0) {
        return retsv;
    }
   
    if (strEQ(key, "NAME")) {

	AV *av = newAV();
	retsv = sv_2mortal(newRV(sv_2mortal((SV*)av)));
	
	CegoField *pF = imp_sth->schema->First();
	i=0;
	while ( pF )
	{
	    av_store(av, i, newSVpv((char*)(pF->getAttrName()), pF->getAttrName().length() - 1));
	    pF = imp_sth->schema->Next();
	    i++;
	}
    }
    else if (strEQ(key, "NUM_OF_FIELDS")) {
        retsv = sv_2mortal(newSViv(imp_sth->schema->Size()));
    }
    else if (strEQ(key, "ChopBlanks")) {
        retsv = sv_2mortal(newSViv(DBIc_has(imp_sth, DBIcf_ChopBlanks)));
    }
    
    return retsv;
}

int
cego_st_STORE_attrib_k (SV *sth, imp_sth_t *imp_sth, SV *keysv, int dbikey, SV *valuesv)
{
    croak("cego_st_STORE_attrib_k not implemented");        
}

SV *
cego_st_FETCH_attrib_k (SV *sth, imp_sth_t *imp_sth, SV *keysv, int dbikey)
{
    croak("cego_st_FETCH_attrib_k not implemented");    
}
