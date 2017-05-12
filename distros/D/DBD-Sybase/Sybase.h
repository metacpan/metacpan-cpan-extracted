/* $Id: Sybase.h,v 1.21 2011/10/02 14:53:49 mpeppler Exp $

   Copyright (c) 1997 - 2011 Michael Peppler

   You may distribute under the terms of either the GNU General Public
   License or the Artistic License, as specified in the Perl README file.

*/



#define NEED_DBIXS_VERSION 93

#define PERL_NO_GET_CONTEXT

#include <DBIXS.h>		/* installed by the DBI module	*/
#include "dbivport.h"

#include <ctpublic.h>
#include <bkpublic.h>

/* These defines avoid name clashes for multiple statically linked DBD's    */
 
#define dbd_init        syb_init
#define dbd_db_login6       syb_db_login
#define dbd_db_do       syb_db_do
#define dbd_db_commit       syb_db_commit
#define dbd_db_rollback     syb_db_rollback
#define dbd_db_disconnect   syb_db_disconnect
#define dbd_discon_all   syb_discon_all
#define dbd_db_destroy      syb_db_destroy
#define dbd_db_STORE_attrib syb_db_STORE_attrib
#define dbd_db_FETCH_attrib syb_db_FETCH_attrib
#define dbd_st_prepare      syb_st_prepare
#define dbd_st_rows     syb_st_rows
#define dbd_st_execute      syb_st_execute
#define dbd_st_fetch        syb_st_fetch
#define dbd_st_finish       syb_st_finish
#define dbd_st_destroy      syb_st_destroy
#define dbd_st_blob_read    syb_st_blob_read
#define dbd_st_STORE_attrib syb_st_STORE_attrib
#define dbd_st_FETCH_attrib syb_st_FETCH_attrib
#define dbd_describe        syb_describe
#define dbd_bind_ph     syb_bind_ph



/* read in our implementation details */

#include "dbdimp.h"

#if defined(CS_CURRENT_VERSION)
#define CTLIB_VERSION	CS_CURRENT_VERSION
#else
#if defined(CS_VERSION_157)
#define CTLIB_VERSION   CS_VERSION_157
#else 
#if defined(CS_VERSION_155)
#define CTLIB_VERSION   CS_VERSION_155
#else 
#if defined(CS_VERSION_150)
#define CTLIB_VERSION   CS_VERSION_150
#else 
#if defined(CS_VERSION_125)
#define CTLIB_VERSION   CS_VERSION_125
#else 
#if defined(CS_VERSION_120)
#define CTLIB_VERSION   CS_VERSION_120
#else 
#if defined(CS_VERSION_110)
#define CTLIB_VERSION   CS_VERSION_110
#else
#define CTLIB_VERSION	CS_VERSION_100
#endif
#endif
#endif
#endif
#endif
#endif
#endif

#if defined(CS_UNICHAR_TYPE) && defined(CS_VERSION_150)
#if defined (is_utf8_string)
#define DBD_CAN_HANDLE_UTF8
#endif
#endif

/*#define CTLIB_VERSION	CS_VERSION_100 */

#ifndef MAX
#define MAX(X,Y)	(((X) > (Y)) ? (X) : (Y))
#endif

#ifndef MIN
#define MIN(X,Y)	(((X) < (Y)) ? (X) : (Y))
#endif


#if !defined(Sybase_h)
#define Sybase_h 1

void     syb_init _((dbistate_t *dbistate));

int      syb_discon_all _((SV *drh, imp_drh_t *imp_drh));

int      syb_db_login _((SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *uid, char *pwd, SV *attribs));
int      syb_db_do _((SV *sv, char *statement));
int      syb_db_commit     _((SV *dbh, imp_dbh_t *imp_dbh));
int      syb_db_rollback   _((SV *dbh, imp_dbh_t *imp_dbh));
int      syb_db_disconnect _((SV *dbh, imp_dbh_t *imp_dbh));
void     syb_db_destroy    _((SV *dbh, imp_dbh_t *imp_dbh));
int      syb_db_STORE_attrib _((SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv));
SV      *syb_db_FETCH_attrib _((SV *dbh, imp_dbh_t *imp_dbh, SV *keysv));

int      syb_st_prepare _((SV *sth, imp_sth_t *imp_sth,
                char *statement, SV *attribs));
int      syb_st_rows    _((SV *sth, imp_sth_t *imp_sth));
int      syb_st_execute _((SV *sth, imp_sth_t *imp_sth));
AV      *syb_st_fetch   _((SV *sth, imp_sth_t *imp_sth));
int      syb_st_finish  _((SV *sth, imp_sth_t *imp_sth));
void     syb_st_destroy _((SV *sth, imp_sth_t *imp_sth));
int      syb_st_blob_read _((SV *sth, imp_sth_t *imp_sth,
                int field, long offset, long len, SV *destrv, long destoffset));
int      syb_ct_get_data _((SV *sth, imp_sth_t *imp_sth, 
			    int column, SV *bufrv, int buflen));
int      syb_ct_data_info _((SV *sth, imp_sth_t *imp_sth, int action, 
			     int column, SV *attr));
int      syb_ct_send_data _((SV *sth, imp_sth_t *imp_sth, char *buffer, 
			     int size));
int      syb_ct_prepare_send _((SV *sth, imp_sth_t *));
int      syb_ct_finish_send _((SV *sth, imp_sth_t *));
int      syb_st_STORE_attrib _((SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv));
SV      *syb_st_FETCH_attrib _((SV *sth, imp_sth_t *imp_sth, SV *keysv));
 
int      syb_describe _((SV *sth, imp_sth_t *imp_sth));
int      syb_bind_ph  _((SV *sth, imp_sth_t *imp_sth,
                SV *param, SV *value, IV sql_type, SV *attribs,
				int is_inout, IV maxlen));


/* prototypes for module-specific functions */
int      syb_thread_enabled _((void));
int      syb_set_timeout _((int timeout));
int      syb_db_date_fmt _((SV *, imp_dbh_t *, char *));

SV *     syb_set_cslib_cb ( SV *cb);


#endif /* defined Sybase_h */

/* end of Sybase.h */
