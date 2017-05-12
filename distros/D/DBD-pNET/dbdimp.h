/*
 *  DBD::pNET - DBI network driver
 *
 *  dbdimp.h - this is the main header file
 *
 *
 *  Author: Jochen Wiedmann
 *          Am Eisteich 9
 *          72555 Metzingen
 *          Germany
 *
 *          Email: wiedmann@neckar-alb.de
 *          Phone: +49 7123 14881
 *
 *
 *  $Id: dbdimp.h,v 1.1.1.1 1997/09/19 20:34:23 joe Exp $
 *
 */


#ifndef DBD_PNET_DBDIMP_H
#define DBD_PNET_DBDIMP_H 1

#include <DBIXS.h>


#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE (!FALSE)
#endif


/*
 *  Error codes
 */
#define DBD_PNET_ERR_IMPLEMENTATION             1
#define DBD_PNET_ERR_NET_ARGS                   2
#define DBD_PNET_ERR_SERVER                     3
#define DBD_PNET_ERR_ST_NOT_ACTIVE              4
#define DBD_PNET_ERR_ILLEGAL_PARAM_NUM          5
#define DBD_PNET_ERR_NOT_IMPLEMENTED            6


typedef struct imp_fbh_st imp_fbh_t;

struct imp_drh_st {
    dbih_drc_t com;		/* MUST be first element in structure	*/
};

/* Define dbh implementor data structure */
struct imp_dbh_st {
    dbih_dbc_t com;		/* MUST be first element in structure	*/

    SV* client;                 /* RPC::pClient object                  */
    SV* rdbh;                   /* Handle to the remote dbh             */
};


/*
 *  The bind_param method internally uses this structure for storing
 *  parameters.
 */
typedef struct imp_sth_ph_st {
    SV* value;
    int type;
} imp_sth_ph_t;


/* Define sth implementor data structure */
struct imp_sth_st {
    dbih_stc_t com;		/* MUST be first element in structure	*/

    SV* rsth;                   /* Handle to the remote sth             */

    int done_desc;
    int done_prepare;
    int num_rows;
    char* salloc;
    imp_sth_ph_t* params; /* Pointer to parameter array             */
};
#ifndef DBIc_NUM_ROWS
#define DBIc_NUM_ROWS(sth) ((sth)->num_rows)
#endif


/* These defines avoid name clashes for multiple statically linked DBD's	*/

#define dbd_init		pNET_init
#define dbd_db_login		pNET_db_login
#define dbd_db_do		pNET_db_do
#define dbd_db_commit		pNET_db_commit
#define dbd_db_rollback		pNET_db_rollback
#define dbd_db_disconnect	pNET_db_disconnect
#define dbd_db_destroy		pNET_db_destroy
#define dbd_db_STORE_attrib	pNET_db_STORE_attrib
#define dbd_db_FETCH_attrib	pNET_db_FETCH_attrib
#define dbd_st_prepare		pNET_st_prepare
#define dbd_st_rows		pNET_st_rows
#define dbd_st_execute		pNET_st_execute
#define dbd_st_fetch		pNET_st_fetch
#define dbd_st_finish		pNET_st_finish
#define dbd_st_destroy		pNET_st_destroy
#define dbd_st_blob_read	pNET_st_blob_read
#define dbd_st_STORE_attrib	pNET_st_STORE_attrib
#define dbd_st_FETCH_attrib	pNET_st_FETCH_attrib
#define dbd_describe		pNET_describe
#define dbd_bind_ph		pNET_bind_ph
#define dbd_preparse		pNET_preparse


/*
 *  Function prototypes
 */
void	pNET_error _((SV *h, int rc, char *what));
void	dbd_preparse _((imp_sth_t *imp_sth, char *statement));

#include <dbd_xsh.h>

#endif /* DBD_PNET_DBDIMP_H */
