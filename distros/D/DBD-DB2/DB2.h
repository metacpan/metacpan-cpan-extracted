/*
   engn/perldb2/DB2.h, engn_perldb2, db2_v82fp9, 1.9 04/09/13 17:17:47

   Copyright (c) 1995-2004  International Business Machines Corp.


*/

#define NEED_DBIXS_VERSION 7

#include <sqlcli.h>
#ifndef AS400                                                    
#include <sqlcli1.h>
#include <sqlext.h>
#endif                                                           
#include <sqlstate.h>                                            

#include <DBIXS.h>              /* installed by the DBI module  */

#include "ppport.h"		/*Header file generated using Devel-PPPort module*/

/* read in our implementation details */

#include "dbdimp.h"

#include <dbd_xsh.h>            /* installed by the DBI module  */
#ifndef AS400                                                    
AV*  dbd_data_sources _((SV *drh));                              
#endif                                                           

#ifndef SQL_XML
#define SQL_XML -370
#endif

/* needed for backward compatibility (SQL_ATTR_ROWCOUNT_PREFETCH not defined prior to DB2 9.5.0.3) */
#ifndef SQL_ATTR_ROWCOUNT_PREFETCH
#define SQL_ATTR_ROWCOUNT_PREFETCH 2592
#define SQL_ROWCOUNT_PREFETCH_OFF   0
#define SQL_ROWCOUNT_PREFETCH_ON    1
#endif

#ifndef SQL_ATTR_USE_TRUSTED_CONTEXT
#define SQL_ATTR_USE_TRUSTED_CONTEXT 2561
#define SQL_ATTR_TRUSTED_CONTEXT_USERID 2562
#define SQL_ATTR_TRUSTED_CONTEXT_PASSWORD 2563
#endif

#ifndef SQL_ATTR_SET_SCHEMA
#define SQL_ATTR_SET_SCHEMA 2579
#endif

int  dbd_db_login2 _((SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *uid, char *pwd, SV *attr));
int  dbd_db_ping _((SV *dbh));                                    
int  dbd_st_table_info _((SV *sth, imp_sth_t *imp_sth, SV *attr));

int  dbd_db_do _(( SV *dbh, char *statement) );                  

int  dbd_st_primary_key_info _(( SV        *sth,
                                 imp_sth_t *imp_sth,
                                 char      *pszCatalog,
                                 char      *pszSchema,
                                 char      *pszTable ));         

int  dbd_st_foreign_key_info _(( SV        *sth,
                                 imp_sth_t *imp_sth,
                                 char      *pkCatalog,
                                 char      *pkSchema,
                                 char      *pkTable,
                                 char      *fkCatalog,
                                 char      *fkSchema,
                                 char      *fkTable ));          

int  dbd_st_column_info _(( SV        *sth,
                            imp_sth_t *imp_sth,
                            char      *pszCatalog,
                            char      *pszSchema,
                            char      *pszTable,
                            char      *pszColumn ));             

int  dbd_st_type_info_all _(( SV        *sth,
                              imp_sth_t *imp_sth ));             


SV*  dbd_db_get_info _(( SV        *dbh,
                         imp_dbh_t *imp_dth,
                         short     infoType ));                  


/* end of DB2.h */
