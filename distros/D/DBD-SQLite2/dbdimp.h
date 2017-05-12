/* $Id: dbdimp.h,v 1.2 2004/08/09 13:17:59 matt Exp $ */

#ifndef _DBDIMP_H
#define _DBDIMP_H   1

#include "SQLiteXS.h"
#include "sqliteInt.h"

/* 30 second timeout by default */
#define SQL_TIMEOUT 30000
#define BUSY_PAUSE_USEC 500

/* Driver Handle */
struct imp_drh_st {
    dbih_drc_t com;
    /* sqlite specific bits */
};

/* Database Handle */
struct imp_dbh_st {
    dbih_dbc_t com;
    /* sqlite specific bits */
    struct sqlite *db;
    bool in_tran;
    bool no_utf8_flag;
    bool handle_binary_nulls;
    int timeout;
    AV *functions;
    AV *aggregates;
};

/* Statement Handle */
struct imp_sth_st {
    dbih_stc_t com;
    /* sqlite specific bits */
    AV *sql;
    sqlite_vm *vm;
    char **results;
    char **coldata;
    int retval;
    int nrow;
    int ncols;
    AV *params;
};

#define dbd_init                sqlite2_init
#define dbd_discon_all          sqlite2_discon_all
#define dbd_db_login            sqlite2_db_login
#define dbd_db_do               sqlite2_db_do
#define dbd_db_commit           sqlite2_db_commit
#define dbd_db_rollback         sqlite2_db_rollback
#define dbd_db_disconnect       sqlite2_db_disconnect
#define dbd_db_destroy          sqlite2_db_destroy
#define dbd_db_STORE_attrib     sqlite2_db_STORE_attrib
#define dbd_db_FETCH_attrib     sqlite2_db_FETCH_attrib
#define dbd_db_STORE_attrib_k   sqlite2_db_STORE_attrib_k
#define dbd_db_FETCH_attrib_k   sqlite2_db_FETCH_attrib_k
#define dbd_st_prepare          sqlite2_st_prepare
#define dbd_st_rows             sqlite2_st_rows
#define dbd_st_execute          sqlite2_st_execute
#define dbd_st_fetch            sqlite2_st_fetch
#define dbd_st_finish           sqlite2_st_finish
#define dbd_st_destroy          sqlite2_st_destroy
#define dbd_st_blob_read        sqlite2_st_blob_read
#define dbd_st_STORE_attrib     sqlite2_st_STORE_attrib
#define dbd_st_FETCH_attrib     sqlite2_st_FETCH_attrib
#define dbd_st_STORE_attrib_k   sqlite2_st_STORE_attrib_k
#define dbd_st_FETCH_attrib_k   sqlite2_st_FETCH_attrib_k
#define dbd_bind_ph             sqlite2_bind_ph

void sqlite2_db_create_function(SV *dbh, const char *name, int argc, SV *func);
void sqlite2_db_create_aggregate( SV *dbh, const char *name, int argc, SV *aggr );

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
