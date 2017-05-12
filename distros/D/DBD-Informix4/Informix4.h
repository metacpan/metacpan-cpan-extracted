/*---------------------------------------------------------
 *
 * Portions Copyright (c) 1994,1995,1996,1997 Tim Bunce
 * Portions Copyright (c) 1997                Edmund Mergl
 * Portions Copyright (c) 1997                Göran Thyni
 *
 *---------------------------------------------------------
 */


#define NEED_DBIXS_VERSION 8

#include "dbdimp.h"

void dbd_init _((dbistate_t *dbistate));
int  dbd_error _((SV *h, int rc));

int  dbd_db_login _((SV *dbh, struct imp_dbh_st* imp_dbh, char *dbname, char *uid, char *pwd));
int  dbd_db_do _((SV *dbh, struct imp_dbh_st* imp_dbh, char *statement, SV *attribs));
int  dbd_db_commit _((SV *dbh, struct imp_dbh_st* imp_dbh));
int  dbd_db_rollback _((SV *dbh, struct imp_dbh_st* imp_dbh));
int  dbd_db_disconnect _((SV *dbh, struct imp_dbh_st* imp_dbh));
void dbd_db_destroy _((SV *dbh, struct imp_dbh_st* imp_dbh));
int  dbd_db_STORE _((SV *dbh, struct imp_dbh_st* imp_dbh, SV *keysv, SV *valuesv));
SV * dbd_db_FETCH _((SV *dbh, struct imp_dbh_st* imp_dbh, SV *keysv));
SV * dbd_db_FETCH_attrib _((SV *dbh, struct imp_dbh_st* imp_dbh, SV *keysv));

int  dbd_st_prepare _((SV *sth, struct imp_sth_st* imp_sth, char *statement, SV *attribs));
int  dbd_st_rows _((SV *sv, struct imp_sth_st* imp_sth));
int  dbd_bind_ph _((SV *sth, struct imp_sth_st* imp_sth, SV *param, SV *value, IV sql_type, SV *attribs, int is_inout, IV maxlen));
int  dbd_st_execute _((SV *sv, struct imp_sth_st* imp_sth));
AV  *dbd_st_fetch _((SV *sv, struct imp_sth_st* imp_sth));
int  dbd_st_finish _((SV *sth, struct imp_sth_st* imp_sth));
void dbd_st_destroy _((SV *sth, struct imp_sth_st* imp_sth));
int  dbd_st_STORE _((SV *sth, struct imp_sth_st* imp_sth, SV *keysv, SV *valuesv));
SV  *dbd_st_FETCH _((SV *sth, struct imp_sth_st* imp_sth, SV *keysv));
SV  *dbd_st_FETCH_attrib _((SV *sth, struct imp_sth_st* imp_sth, SV *keysv));


/* EOF */
