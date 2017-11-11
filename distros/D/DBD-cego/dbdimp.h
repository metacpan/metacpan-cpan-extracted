#ifndef _DBDIMP_H
#define _DBDIMP_H   1
///////////////////////////////////////////////////////////////////////////////
//                                                         
// dbdimp.h
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


#include <lfcbase/NetHandler.h>
#include <lfcbase/ListT.h>

#include <cego/CegoNet.h>
#include <cego/CegoField.h>
#include "CegoXS.h"

#define MAXLOGFILE 100
#define MAXLOGMODE 10
#define MAXPROTSTRING 10

class CegoDBDParam {

public:
    

    CegoDBDParam()
    {
	_pRef = 0;
    }

    CegoDBDParam(const Chain& id) 
    {
	_id = id;
	_pRef = 0;
    }

    CegoDBDParam(const Chain& id, const Chain& val) 
    {
	_id = id;
	_val = val;
	_pRef = 0;
    }
    CegoDBDParam(const Chain& id, const Chain& val, SV* pRef) 
    {
	_id = id;
	_val = val;
	_pRef = pRef;
    }
    
    ~CegoDBDParam() {}

    void setRef(SV* pRef)
    {
	_pRef = pRef;
    }
    
    void setValue(const Chain& val)
    {
	_val = val;
    }

    const Chain& getId() const
    {
	return _id;
    }

    const Chain& getValue() const
    {
	return _val;
    }

    SV* getRef() const
    {
	return _pRef;
    }
 
    CegoDBDParam& operator = ( const CegoDBDParam& p)
    {
	_id = p._id;
	_val = p._val;
	_pRef = p._pRef;
	return *this;
    }
    bool operator == ( const CegoDBDParam& p) const
    {
	return _id == p._id;
    }
    
private:

	Chain _id;
	Chain _val;
	SV* _pRef;
};

/* Driver Handle */
struct imp_drh_st {
    dbih_drc_t com;
    /* cego specific bits */
};

/* Database Handle */
struct imp_dbh_st {
    dbih_dbc_t com;
    /* cego specific bits */
    CegoNet* cgnet;
    /* NetHandler* net;
    CegoDbHandler *db; */
    char hostname[MAXHOSTNAMELEN];
    int port;
    int maxsendlen;
    char logfile[MAXLOGFILE];
    char logmode[MAXLOGMODE];
    char protocol[MAXPROTSTRING];
    bool activeTransaction;
    bool activeQuery;
    
    bool in_tran;
    bool no_utf8_flag;
};

/* Statement Handle */
struct imp_sth_st {
    dbih_stc_t com;
    /* cego specific bits */
    bool hasRetValue;
    ListT<Chain> *stmtChunks;
    ListT<CegoDBDParam> *paramList;
    ListT<CegoField>* schema;
    long affected;
    char* msg;
};

#define dbd_init                cego_init
#define dbd_discon_all          cego_discon_all
#define dbd_db_login            cego_db_login
#define dbd_db_do               cego_db_do
#define dbd_db_commit           cego_db_commit
#define dbd_db_rollback         cego_db_rollback
#define dbd_db_disconnect       cego_db_disconnect
#define dbd_db_destroy          cego_db_destroy
#define dbd_db_STORE_attrib     cego_db_STORE_attrib
#define dbd_db_FETCH_attrib     cego_db_FETCH_attrib
#define dbd_db_STORE_attrib_k   cego_db_STORE_attrib_k
#define dbd_db_FETCH_attrib_k   cego_db_FETCH_attrib_k
#define dbd_st_prepare          cego_st_prepare
#define dbd_st_rows             cego_st_rows
#define dbd_st_execute          cego_st_execute
#define dbd_st_fetch            cego_st_fetch
#define dbd_st_finish           cego_st_finish
#define dbd_st_destroy          cego_st_destroy
#define dbd_st_blob_read        cego_st_blob_read
#define dbd_st_STORE_attrib     cego_st_STORE_attrib
#define dbd_st_FETCH_attrib     cego_st_FETCH_attrib
#define dbd_st_STORE_attrib_k   cego_st_STORE_attrib_k
#define dbd_st_FETCH_attrib_k   cego_st_FETCH_attrib_k
#define dbd_bind_ph             cego_bind_ph

#ifdef SvUTF8_on

static SV *
newUTF8SVpv(char *s, STRLEN len) {
  register SV *sv;

  sv = newSVpv(s, len);
  SvUTF8_on(sv);
  return sv;
}  /* End new UTF8SVpv */

static SV *
newUTF8SVpvn(char *s, STRLEN len) {
  register SV *sv;

  sv = newSV(0);
  sv_setpvn(sv, s, len);
  SvUTF8_on(sv);
  return sv;
}

#else  /* SvUTF8_on not defined */

#define newUTF8SVpv newSVpv
#define newUTF8SVpvn newSVpvn
#define SvUTF8_on(a) (a)
#define sv_utf8_upgrade(a) (a)

#endif

#endif /* _DBDIMP_H */
