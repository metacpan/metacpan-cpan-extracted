/*
 *  DBD::mysqlx - DBI X Protocol driver for the MySQL database
 *
 *  Copyright (c) 2018 Daniël van Eeden
 *
 *  You may distribute this under the terms of either the GNU General Public
 *  License or the Artistic License, as specified in the Perl README file.
 */

#include <mysqlx/xapi.h>
#include <DBIXS.h>

struct imp_drh_st {
  dbih_drc_t com; /* MUST be first element in structure   */
};

struct imp_dbh_st {
  dbih_dbc_t com; /* MUST be first element in structure   */
  mysqlx_session_t *sess;
};

struct imp_sth_st {
  dbih_stc_t com; /* MUST be first element in structure   */
  mysqlx_stmt_t *stmt;
  mysqlx_result_t *result;
};

#define dbd_init mysqlx_dr_init
#define dbd_db_login6 mysqlx_db_login6
#define dbd_db_do mysqlx_db_do
#define dbd_db_commit mysqlx_db_commit
#define dbd_db_rollback mysqlx_db_rollback
#define dbd_db_disconnect mysqlx_db_disconnect
#define dbd_db_destroy mysqlx_db_destroy
#define dbd_db_STORE_attrib mysqlx_db_STORE_attrib
#define dbd_db_FETCH_attrib mysqlx_db_FETCH_attrib
#define dbd_st_prepare mysqlx_st_prepare
#define dbd_st_FETCH_attrib mysqlx_st_FETCH_attrib
#define dbd_st_STORE_attrib mysqlx_st_STORE_attrib
#define dbd_st_blob_read mysqlx_st_blob_read
#define dbd_st_fetch mysqlx_st_fetch
#define dbd_st_finish3 mysqlx_st_finish3
#define dbd_st_destroy mysqlx_st_destroy
#define dbd_st_execute mysqlx_st_execute
#define dbd_st_last_insert_id mysqlx_st_last_insert_id
#define dbd_bind_ph mysqlx_bind_ph
#define dbd_drv_error mysqlx_drv_error
